DK = DK or {}

DK.GetOrCreateProfile = function(citizenid)
    if not citizenid then return nil end

    local profile = MySQL.single.await(
        'SELECT * FROM dk_spedition_profiles WHERE citizenid = ? LIMIT 1',
        { citizenid }
    )

    if profile then
        local calculatedLevel = DKLevels.GetLevelFromXP(profile.xp)

        if tonumber(profile.level) ~= calculatedLevel then
            MySQL.update.await(
                'UPDATE dk_spedition_profiles SET level = ? WHERE citizenid = ?',
                { calculatedLevel, citizenid }
            )

            profile.level = calculatedLevel
        end

        return profile
    end

    MySQL.insert.await(
        [[
            INSERT INTO dk_spedition_profiles
            (
                citizenid,
                xp,
                level,
                completed_jobs,
                failed_jobs,
                adr_license,
                heavy_license,
                coolchain_license,
                adr_exam_attempts,
                hazmat_completed,
                total_distance
            )
            VALUES (?, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0)
        ]],
        { citizenid }
    )

    return MySQL.single.await(
        'SELECT * FROM dk_spedition_profiles WHERE citizenid = ? LIMIT 1',
        { citizenid }
    )
end

DK.BuildProfilePayload = function(profile)
    if not profile then return nil end

    local progress = DKLevels.GetProgress(profile.xp)
    local levelData = DKLevels.GetData(profile.level)

    local adrLicense = tonumber(profile.adr_license) == 1
        or tostring(profile.adr_license) == '1'
        or profile.adr_license == true

    local heavyLicense = tonumber(profile.heavy_license) == 1
        or tostring(profile.heavy_license) == '1'
        or profile.heavy_license == true

    local coolchainLicense = tonumber(profile.coolchain_license) == 1
        or tostring(profile.coolchain_license) == '1'
        or profile.coolchain_license == true

    print(('[dk-spedition] BuildProfilePayload | citizenid: %s | raw adr_license: %s | parsed: %s'):format(
        tostring(profile.citizenid),
        tostring(profile.adr_license),
        tostring(adrLicense)
    ))

    return {
        citizenid = profile.citizenid,

        xp = tonumber(profile.xp) or 0,
        level = tonumber(profile.level) or 1,
        levelLabel = levelData.label,

        progress = progress.progress,
        nextLevelXp = progress.nextLevelXp,
        currentLevelXp = progress.currentLevelXp,
        isMaxLevel = progress.isMaxLevel,

        completedJobs = tonumber(profile.completed_jobs) or 0,
        failedJobs = tonumber(profile.failed_jobs) or 0,
        hazmatCompleted = tonumber(profile.hazmat_completed) or 0,
        totalDistance = tonumber(profile.total_distance) or 0,

        licenses = {
            adr = adrLicense,
            heavy = heavyLicense,
            coolchain = coolchainLicense
        },

        adr = {
            license = adrLicense,
            attempts = tonumber(profile.adr_exam_attempts) or 0,
            passedAt = profile.adr_exam_passed_at,
            failedAt = profile.adr_exam_failed_at
        }
    }
end

DK.AddProfileXP = function(citizenid, amount)
    amount = tonumber(amount) or 0

    if amount <= 0 then
        return nil
    end

    local profile = DK.GetOrCreateProfile(citizenid)
    if not profile then return nil end

    local oldLevel = tonumber(profile.level) or 1
    local newXp = (tonumber(profile.xp) or 0) + amount
    local newLevel = DKLevels.GetLevelFromXP(newXp)

    MySQL.update.await(
        'UPDATE dk_spedition_profiles SET xp = ?, level = ? WHERE citizenid = ?',
        { newXp, newLevel, citizenid }
    )

    profile.xp = newXp
    profile.level = newLevel

    return {
        profile = profile,
        oldLevel = oldLevel,
        newLevel = newLevel,
        leveledUp = newLevel > oldLevel
    }
end

DK.MarkRunCompletedInProfile = function(citizenid, xp, distance, category)
    local xpResult = DK.AddProfileXP(citizenid, xp)

    MySQL.update.await(
        [[
            UPDATE dk_spedition_profiles
            SET
                completed_jobs = completed_jobs + 1,
                total_distance = total_distance + ?,
                hazmat_completed = hazmat_completed + ?,
                last_job_at = CURRENT_TIMESTAMP
            WHERE citizenid = ?
        ]],
        {
            tonumber(distance) or 0,
            category == 'hazmat' and 1 or 0,
            citizenid
        }
    )

    return xpResult
end

DK.MarkRunFailedInProfile = function(citizenid)
    MySQL.update.await(
        [[
            UPDATE dk_spedition_profiles
            SET
                failed_jobs = failed_jobs + 1,
                last_job_at = CURRENT_TIMESTAMP
            WHERE citizenid = ?
        ]],
        { citizenid }
    )
end

DK.SetAdrLicense = function(citizenid, enabled)
    if not citizenid then return false end

    local value = enabled and 1 or 0

    local changed = MySQL.update.await(
        [[
            UPDATE dk_spedition_profiles
            SET
                adr_license = ?,
                adr_exam_passed_at = CASE WHEN ? = 1 THEN CURRENT_TIMESTAMP ELSE adr_exam_passed_at END
            WHERE citizenid = ?
        ]],
        {
            value,
            value,
            citizenid
        }
    )

    print(('[dk-spedition] SetAdrLicense | citizenid: %s | value: %s | changed: %s'):format(
        tostring(citizenid),
        tostring(value),
        tostring(changed)
    ))

    return changed and changed > 0
end

DK.MarkAdrExamFailed = function(citizenid)
    MySQL.update.await(
        [[
            UPDATE dk_spedition_profiles
            SET
                adr_exam_attempts = adr_exam_attempts + 1,
                adr_exam_failed_at = CURRENT_TIMESTAMP
            WHERE citizenid = ?
        ]],
        { citizenid }
    )
end

DK.MarkAdrExamAttempt = function(citizenid)
    MySQL.update.await(
        [[
            UPDATE dk_spedition_profiles
            SET adr_exam_attempts = adr_exam_attempts + 1
            WHERE citizenid = ?
        ]],
        { citizenid }
    )
end
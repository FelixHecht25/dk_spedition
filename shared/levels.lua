DKLevels = {}

DKLevels.List = {
    [1] = {
        label = 'Bote',
        xp = 0,
        unlocks = {
            'courier'
        }
    },

    [2] = {
        label = 'Kurierfahrer',
        xp = 350,
        unlocks = {
            'courier',
            'city_transport'
        }
    },

    [3] = {
        label = 'Nahverkehrsfahrer',
        xp = 900,
        unlocks = {
            'standard',
            'pallets'
        }
    },

    [4] = {
        label = 'LKW-Fahrer',
        xp = 1800,
        unlocks = {
            'standard',
            'bulk'
        }
    },

    [5] = {
        label = 'Sattelzugfahrer',
        xp = 3000,
        unlocks = {
            'trailer',
            'container'
        }
    },

    [6] = {
        label = 'Erfahrener Fahrer',
        xp = 5000,
        unlocks = {
            'construction',
            'refrigerated'
        }
    },

    [7] = {
        label = 'ADR-Anwärter',
        xp = 7000,
        unlocks = {
            'adr_exam'
        }
    },

    [8] = {
        label = 'ADR-Fahrer',
        xp = 10000,
        unlocks = {
            'hazmat'
        }
    },

    [9] = {
        label = 'Spezialfahrer',
        xp = 13000,
        unlocks = {
            'oversize'
        }
    },

    [10] = {
        label = 'Meisterfahrer',
        xp = 17000,
        unlocks = {
            'premium'
        }
    }
}

DKLevels.GetLevelFromXP = function(xp)
    xp = tonumber(xp) or 0

    local currentLevel = 1

    for level, data in pairs(DKLevels.List) do
        if xp >= data.xp and level > currentLevel then
            currentLevel = level
        end
    end

    return currentLevel
end

DKLevels.GetData = function(level)
    return DKLevels.List[level] or DKLevels.List[1]
end

DKLevels.GetNextLevelData = function(level)
    return DKLevels.List[level + 1]
end

DKLevels.GetProgress = function(xp)
    xp = tonumber(xp) or 0

    local level = DKLevels.GetLevelFromXP(xp)
    local current = DKLevels.GetData(level)
    local nextLevel = DKLevels.GetNextLevelData(level)

    if not nextLevel then
        return {
            level = level,
            currentXp = xp,
            currentLevelXp = current.xp,
            nextLevelXp = current.xp,
            progress = 100,
            isMaxLevel = true
        }
    end

    local currentBase = current.xp
    local nextBase = nextLevel.xp
    local span = nextBase - currentBase
    local earned = xp - currentBase

    local progress = 0

    if span > 0 then
        progress = math.floor((earned / span) * 100)
    end

    if progress < 0 then progress = 0 end
    if progress > 100 then progress = 100 end

    return {
        level = level,
        currentXp = xp,
        currentLevelXp = currentBase,
        nextLevelXp = nextBase,
        progress = progress,
        isMaxLevel = false
    }
end

DKLevels.GetUnlockList = function(profile)
    local level = tonumber(profile.level) or 1

    local adrLicense = tonumber(profile.adr_license) == 1
        or tostring(profile.adr_license) == '1'
        or profile.adr_license == true

    local heavyLicense = tonumber(profile.heavy_license) == 1
        or tostring(profile.heavy_license) == '1'
        or profile.heavy_license == true

    local coolchainLicense = tonumber(profile.coolchain_license) == 1
        or tostring(profile.coolchain_license) == '1'
        or profile.coolchain_license == true

    local unlocks = {
        {
            id = 'courier',
            label = 'Botendienst',
            requiredLevel = 1,
            unlocked = level >= 1
        },
        {
            id = 'city_transport',
            label = 'Stadttransporte',
            requiredLevel = 2,
            unlocked = level >= 2
        },
        {
            id = 'standard',
            label = 'Standardlieferungen',
            requiredLevel = 3,
            unlocked = level >= 3
        },
        {
            id = 'bulk',
            label = 'Schüttgut',
            requiredLevel = 4,
            unlocked = level >= 4
        },
        {
            id = 'container',
            label = 'Container',
            requiredLevel = 5,
            unlocked = level >= 5
        },
        {
            id = 'construction',
            label = 'Baustoffe',
            requiredLevel = 6,
            unlocked = level >= 6
        },
        {
            id = 'adr',
            label = 'ADR / Gefahrgut',
            requiredLevel = Config.ADR.requiredLevel,
            unlocked = level >= Config.ADR.requiredLevel and adrLicense,
            examRequired = true
        },
        {
            id = 'oversize',
            label = 'Sondertransport',
            requiredLevel = 9,
            unlocked = level >= 9 and heavyLicense,
            licenseRequired = true
        }
    }

    return unlocks
end
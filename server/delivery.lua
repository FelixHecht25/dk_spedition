DK = DK or {}
DK.PendingSettlements = DK.PendingSettlements or {}

local function GetPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end

    return GetEntityCoords(ped)
end

local function IsNearVector4(src, coords, distance)
    local playerCoords = GetPlayerCoords(src)
    if not playerCoords then return false end

    return #(playerCoords - vector3(coords.x, coords.y, coords.z)) <= distance
end

local function IsNearUnloadCoords(src, run, distance)
    if not run.unload_x or not run.unload_y or not run.unload_z then
        return false
    end

    local playerCoords = GetPlayerCoords(src)
    if not playerCoords then return false end

    local unloadCoords = vector3(
        tonumber(run.unload_x),
        tonumber(run.unload_y),
        tonumber(run.unload_z)
    )

    return #(playerCoords - unloadCoords) <= distance
end

local function IsNearReturnPoint(src)
    if not Config.Depot.returnPoint or not Config.Depot.returnPoint.coords then
        return false
    end

    local playerCoords = GetPlayerCoords(src)
    if not playerCoords then return false end

    local returnCoords = Config.Depot.returnPoint.coords
    local radius = Config.Depot.returnPoint.radius or 5.0

    return #(playerCoords - vector3(returnCoords.x, returnCoords.y, returnCoords.z)) <= radius
end

local function GetVehicleDamagePercentFromClient(data)
    data = data or {}

    local damagePercent = tonumber(data.vehicleDamagePercent) or 0

    if damagePercent < 0 then damagePercent = 0 end
    if damagePercent > 100 then damagePercent = 100 end

    return damagePercent
end

local function BuildFallbackSettlement(run)
    return {
        runId = run.id,

        basePayout = tonumber(run.base_payout) or 0,
        finalPayout = tonumber(run.final_payout) or tonumber(run.base_payout) or 0,

        baseXp = tonumber(run.base_xp) or 0,
        finalXp = tonumber(run.final_xp) or tonumber(run.base_xp) or 0,

        expectedCargo = tonumber(run.cargo_amount) or 0,
        deliveredCargo = tonumber(run.cargo_amount) or 0,
        missingCargo = 0,
        missingPercent = 0,

        sealBroken = tonumber(run.seal_broken) == 1,
        adrRun = false,

        bonuses = {},
        penalties = {},
        bossMessages = {}
    }
end

DK.SelectUnloadSpot = function(receiver)
    if not receiver or not receiver.unloadSpots or #receiver.unloadSpots < 1 then
        return nil
    end

    return receiver.unloadSpots[math.random(1, #receiver.unloadSpots)]
end

DK.IsAtDeliveryReceiver = function(src, run)
    if not run then return false end

    local receiver = Config.DeliveryReceivers[run.receiver_id]
    if not receiver then return false end

    return IsNearVector4(src, receiver.coords, 5.0)
end

RegisterNetEvent('dk-spedition:server:arriveAtReceiver', function()
    local src = source

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    local run = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)

    if not run then
        DK.Notify(src, 'Du hast keinen aktiven Auftrag.', 'error')
        return
    end

    if run.state ~= 'LOADED' and run.state ~= 'EN_ROUTE' then
        DK.Notify(src, 'Diese Lieferung ist noch nicht bereit zur Warenannahme.', 'error')
        return
    end

    if not DK.IsAtDeliveryReceiver(src, run) then
        DK.Notify(src, 'Du bist nicht beim richtigen Empfänger.', 'error')
        return
    end

    DK.UpdateRunState(run.id, 'EN_ROUTE')

    DK.Notify(src, 'Empfänger gefunden. Übergib jetzt die Lieferpapiere.', 'primary')
end)

RegisterNetEvent('dk-spedition:server:handoverToReceiver', function()
    local src = source

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    local run = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)

    if not run then
        DK.Notify(src, 'Du hast keinen aktiven Auftrag.', 'error')
        return
    end

    if run.state ~= 'LOADED' and run.state ~= 'EN_ROUTE' then
        DK.Notify(src, 'Dieser Auftrag ist noch nicht bereit zur Übergabe.', 'error')
        return
    end

    if not DK.IsAtDeliveryReceiver(src, run) then
        DK.Notify(src, 'Du bist nicht beim richtigen Empfänger.', 'error')
        return
    end

    local plateOk, plateReason = DK.ValidateRunVehiclePlates(run)
    if not plateOk then
        DK.Notify(src, plateReason, 'error')
        return
    end

    local docsOk, docsReason = DK.ValidateRequiredDeliveryDocuments(Player, run)
    if not docsOk then
        DK.Notify(src, docsReason or 'Lieferpapiere unvollständig.', 'error')
        return
    end

    local receiver = Config.DeliveryReceivers[run.receiver_id]
    local unloadSpot = DK.SelectUnloadSpot(receiver)

    if not unloadSpot then
        DK.Notify(src, 'Kein Abladeplatz verfügbar.', 'error')
        return
    end

    DK.RemoveDeliveryDocuments(Player, run)

    DK.UpdateRunState(run.id, 'PAPERS_ACCEPTED', {
        papersAccepted = true,
        unloadCoords = unloadSpot
    })

    TriggerClientEvent('dk-spedition:client:setUnloadSpot', src, {
        runId = run.id,
        coords = unloadSpot,
        label = 'Abladeplatz'
    })

    DK.Notify(src, 'Papiere akzeptiert. Fahre zum markierten Abladeplatz.', 'success')
end)

RegisterNetEvent('dk-spedition:server:startUnloading', function()
    local src = source

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    local run = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)

    if not run then
        DK.Notify(src, 'Du hast keinen aktiven Auftrag.', 'error')
        return
    end

    if run.state ~= 'PAPERS_ACCEPTED' then
        DK.Notify(src, 'Die Papiere wurden noch nicht vom Empfänger akzeptiert.', 'error')
        return
    end

    if Config.Unloading.requireVehicleAtUnloadSpot and not IsNearUnloadCoords(src, run, 12.0) then
        DK.Notify(src, 'Du bist nicht am zugewiesenen Abladeplatz.', 'error')
        return
    end

    local plateOk, plateReason = DK.ValidateRunVehiclePlates(run)
    if not plateOk then
        DK.Notify(src, plateReason, 'error')
        return
    end

    local loadedAmount = DK.CountMatchingCargo(run)
    local expectedAmount = tonumber(run.cargo_amount) or 1

    if loadedAmount < expectedAmount and not Config.Unloading.partialDeliveryAllowed then
        DK.FailRun(run.id, Player, 'cargo_incomplete')
        DK.Notify(src, 'Die Lieferung ist unvollständig. Auftrag fehlgeschlagen.', 'error')
        return
    end

    if loadedAmount <= 0 then
        DK.Notify(src, 'Der Empfänger dokumentiert die Lieferung, aber es wurde keine Ware gefunden.', 'error', 8000)
    end

    DK.UpdateRunState(run.id, 'UNLOADING')

    local unloadTime = math.random(Config.Unloading.minSeconds, Config.Unloading.maxSeconds)

    TriggerClientEvent('dk-spedition:client:unloadingStarted', src, {
        runId = run.id,
        seconds = unloadTime
    })

    DK.Notify(src, ('Entladung gestartet. Dauer: ca. %s Sekunden.'):format(unloadTime), 'primary', 5000)

    SetTimeout(unloadTime * 1000, function()
        local freshRun = DK.GetRunById(run.id)

        if not freshRun or freshRun.state ~= 'UNLOADING' then
            return
        end

        local freshPlayer = DK.GetPlayer(src)

        if not freshPlayer then
            return
        end

        local finalLoadedAmount = DK.CountMatchingCargo(freshRun)

        local settlement = nil

        if DK.CalculateRunSettlement then
            settlement = DK.CalculateRunSettlement(freshRun, finalLoadedAmount)
        elseif DK.CalculateFinalRewards then
            local finalPayout, finalXp, rewardDetails = DK.CalculateFinalRewards(freshRun, finalLoadedAmount)

            settlement = {
                runId = freshRun.id,

                basePayout = tonumber(freshRun.base_payout) or 0,
                finalPayout = finalPayout or 0,

                baseXp = tonumber(freshRun.base_xp) or 0,
                finalXp = finalXp or 0,

                expectedCargo = tonumber(freshRun.cargo_amount) or 0,
                deliveredCargo = tonumber(finalLoadedAmount) or 0,
                missingCargo = math.max((tonumber(freshRun.cargo_amount) or 0) - (tonumber(finalLoadedAmount) or 0), 0),
                missingPercent = 0,

                sealBroken = tonumber(freshRun.seal_broken) == 1,
                adrRun = false,

                bonuses = {},
                penalties = {},
                bossMessages = {},

                legacyRewardDetails = rewardDetails
            }
        end

        if not settlement then
            DK.FailRun(freshRun.id, freshPlayer, 'settlement_failed')
            DK.Notify(src, 'Abrechnung konnte nicht erstellt werden.', 'error')
            return
        end

        DK.PendingSettlements = DK.PendingSettlements or {}
        DK.PendingSettlements[tonumber(freshRun.id)] = settlement

        if finalLoadedAmount > 0 then
            DK.RemoveMatchingCargo(freshRun, finalLoadedAmount)
        end

        MySQL.update.await(
            [[
                UPDATE dk_spedition_runs
                SET
                    state = 'RETURN_TO_DEPOT',
                    final_payout = ?,
                    final_xp = ?
                WHERE id = ?
            ]],
            {
                settlement.finalPayout,
                settlement.finalXp,
                freshRun.id
            }
        )

        TriggerClientEvent('dk-spedition:client:returnVehicleToDepot', src, {
            runId = freshRun.id,
            returnPoint = Config.Depot.returnPoint,
            payout = settlement.finalPayout,
            xp = settlement.finalXp,
            rewardDetails = settlement,
            settlement = settlement
        })

        DK.Notify(src, 'Entladung abgeschlossen. Bringe den LKW zur Fahrzeugrückgabe zurück.', 'primary', 8000)
    end)
end)

DK.CompleteRun = function(src, Player, run, finalPayout, finalXp, rewardDetails)
    if not Player or not run then return end

    finalPayout = tonumber(finalPayout) or tonumber(run.final_payout) or tonumber(run.base_payout) or 0
    finalXp = tonumber(finalXp) or tonumber(run.final_xp) or tonumber(run.base_xp) or 0
    rewardDetails = rewardDetails or {}

    if finalPayout > 0 then
        if Config.BankPayout then
            Player.Functions.AddMoney('bank', finalPayout, 'dk-spedition-delivery')
        else
            Player.Functions.AddMoney('cash', finalPayout, 'dk-spedition-delivery')
        end
    end

    DK.UpdateRunState(run.id, 'COMPLETED')

    local template = DKCargo.GetTemplate(run.template_id)
    local distance = 0

    local xpResult = DK.MarkRunCompletedInProfile(
        run.citizenid,
        finalXp,
        distance,
        template and template.category or 'unknown'
    )

    DK.RemoveRunKeys(src, Player, run)

    DK.ActiveRuns[run.citizenid] = nil

    TriggerClientEvent('dk-spedition:client:runCompleted', src, {
        runId = run.id,
        payout = finalPayout,
        xp = finalXp,
        rewardDetails = rewardDetails,
        settlement = rewardDetails.settlement or rewardDetails,
        leveledUp = xpResult and xpResult.leveledUp or false,
        newLevel = xpResult and xpResult.newLevel or nil
    })

    if xpResult and xpResult.leveledUp then
        DK.Notify(
            src,
            ('Auftrag abgeschlossen. Auszahlung: $%s | XP: %s | Neues Level: %s'):format(finalPayout, finalXp, xpResult.newLevel),
            finalPayout > 0 and 'success' or 'error',
            9000
        )
    else
        DK.Notify(
            src,
            ('Auftrag abgeschlossen. Auszahlung: $%s | XP: %s'):format(finalPayout, finalXp),
            finalPayout > 0 and 'success' or 'error',
            9000
        )
    end
end

RegisterNetEvent('dk-spedition:server:returnVehicle', function(data)
    local src = source
    data = data or {}

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    local run = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)

    if not run then
        DK.Notify(src, 'Du hast keinen aktiven Auftrag.', 'error')
        return
    end

    if run.state ~= 'RETURN_TO_DEPOT' then
        DK.Notify(src, ('Dieser Auftrag ist nicht bereit für die Fahrzeugrückgabe. Status: %s'):format(tostring(run.state)), 'error')
        return
    end

    if not IsNearReturnPoint(src) then
        DK.Notify(src, 'Du bist nicht an der Fahrzeugrückgabe.', 'error')
        return
    end

    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not vehicle or vehicle == 0 then
        DK.Notify(src, 'Du musst den Speditions-LKW zur Rückgabe bringen.', 'error')
        return
    end

    local plate = Bridge.Utils.TrimPlate(GetVehicleNumberPlateText(vehicle))

    if plate ~= run.truck_plate then
        DK.Notify(src, 'Das ist nicht der zugewiesene Speditions-LKW.', 'error')
        return
    end

    DK.PendingSettlements = DK.PendingSettlements or {}

    local settlement = DK.PendingSettlements[tonumber(run.id)]

    if not settlement then
        settlement = BuildFallbackSettlement(run)
    end

    local damagePercent = GetVehicleDamagePercentFromClient(data)

    if DK.ApplyVehicleDamageToSettlement then
        settlement = DK.ApplyVehicleDamageToSettlement(settlement, damagePercent)
    else
        settlement.vehicleDamagePercent = damagePercent
    end

    MySQL.update.await(
        [[
            UPDATE dk_spedition_runs
            SET final_payout = ?, final_xp = ?
            WHERE id = ?
        ]],
        {
            settlement.finalPayout or 0,
            settlement.finalXp or 0,
            run.id
        }
    )

    local freshRun = DK.GetRunById(run.id)

    if not freshRun then
        DK.Notify(src, 'Auftrag konnte nicht abgeschlossen werden.', 'error')
        return
    end

    local finalSummary = nil

    if DK.FormatFinalSettlementSummary then
        finalSummary = DK.FormatFinalSettlementSummary(settlement)
    elseif DK.FormatSettlementSummary then
        finalSummary = DK.FormatSettlementSummary(settlement)
    end

    if finalSummary then
        DK.Notify(src, finalSummary, settlement.finalPayout > 0 and 'primary' or 'error', 15000)
    end

    DK.PendingSettlements[tonumber(run.id)] = nil

    DK.CompleteRun(src, Player, freshRun, settlement.finalPayout, settlement.finalXp, {
        returnedVehicle = true,
        settlement = settlement
    })

    if vehicle and DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end

    local trailer = nil

    if DK.GetRunTrailerEntity then
        trailer = DK.GetRunTrailerEntity(run)
    end

    if trailer and DoesEntityExist(trailer) then
        DeleteEntity(trailer)
    end
end)
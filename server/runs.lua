DK = DK or {}

DK.GetActiveRunByCitizenId = function(citizenid)
    if not citizenid then return nil end

    return MySQL.single.await(
        [[
            SELECT *
            FROM dk_spedition_runs
            WHERE citizenid = ?
            AND state NOT IN ('COMPLETED', 'FAILED', 'CANCELLED')
            ORDER BY id DESC
            LIMIT 1
        ]],
        { citizenid }
    )
end

DK.GetRunById = function(runId)
    return MySQL.single.await(
        'SELECT * FROM dk_spedition_runs WHERE id = ? LIMIT 1',
        { runId }
    )
end

DK.UpdateRunState = function(runId, state, extra)
    extra = extra or {}

    local fields = { 'state = ?' }
    local params = { state }

    if extra.loadingEndsAt then
        fields[#fields + 1] = 'loading_ends_at = ?'
        params[#params + 1] = extra.loadingEndsAt
    end

    if extra.documentsCollected ~= nil then
        fields[#fields + 1] = 'documents_collected = ?'
        params[#params + 1] = extra.documentsCollected and 1 or 0
    end

    if extra.papersAccepted ~= nil then
        fields[#fields + 1] = 'papers_accepted = ?'
        params[#params + 1] = extra.papersAccepted and 1 or 0
    end

    if extra.unloadCoords then
        fields[#fields + 1] = 'unload_x = ?'
        fields[#fields + 1] = 'unload_y = ?'
        fields[#fields + 1] = 'unload_z = ?'
        fields[#fields + 1] = 'unload_w = ?'

        params[#params + 1] = extra.unloadCoords.x
        params[#params + 1] = extra.unloadCoords.y
        params[#params + 1] = extra.unloadCoords.z
        params[#params + 1] = extra.unloadCoords.w or 0.0
    end

    if state == 'COMPLETED' then
        fields[#fields + 1] = 'completed_at = CURRENT_TIMESTAMP'
    end

    if state == 'CANCELLED' then
        fields[#fields + 1] = 'cancelled_at = CURRENT_TIMESTAMP'
    end

    if state == 'FAILED' then
        fields[#fields + 1] = 'failed_at = CURRENT_TIMESTAMP'
    end

    params[#params + 1] = runId

    MySQL.update.await(
        ('UPDATE dk_spedition_runs SET %s WHERE id = ?'):format(table.concat(fields, ', ')),
        params
    )
end

DK.UpdateRunEntityData = function(runId, truckNetId, trailerNetId)
    MySQL.update.await(
        [[
            UPDATE dk_spedition_runs
            SET truck_net_id = ?, trailer_net_id = ?, started_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ]],
        {
            truckNetId,
            trailerNetId,
            runId
        }
    )
end

DK.UpdateRunSealBroken = function(runId, broken)
    MySQL.update.await(
        'UPDATE dk_spedition_runs SET seal_broken = ? WHERE id = ?',
        {
            broken and 1 or 0,
            runId
        }
    )
end

local function ApplyRunEntityStateFromNetId(netId, run)
    if not netId or not run then
        return
    end

    local entity = NetworkGetEntityFromNetworkId(tonumber(netId))

    if not entity or entity == 0 or not DoesEntityExist(entity) then
        print(('[dk-spedition] Entity-State konnte nicht gesetzt werden. NetId ungültig: %s'):format(tostring(netId)))
        return
    end

    Entity(entity).state:set('dkSpeditionRunId', tonumber(run.id), true)
    Entity(entity).state:set('dkSpeditionCargoInventoryId', run.cargo_inventory_id, true)
    Entity(entity).state:set('dkSpeditionTruckPlate', run.truck_plate, true)
    Entity(entity).state:set('dkSpeditionTrailerPlate', run.trailer_plate, true)

    if run.seal_number and tostring(run.seal_number) ~= '' then
        Entity(entity).state:set('dkSpeditionSealNumber', run.seal_number, true)
        Entity(entity).state:set('dkSpeditionSealBroken', tonumber(run.seal_broken) == 1, true)
    else
        Entity(entity).state:set('dkSpeditionSealNumber', nil, true)
        Entity(entity).state:set('dkSpeditionSealBroken', false, true)
    end

    print(('[dk-spedition] Entity-State gesetzt | runId: %s | netId: %s | seal: %s'):format(
        tostring(run.id),
        tostring(netId),
        tostring(run.seal_number)
    ))
end

DK.StartRunFromOffer = function(src, Player, offerId)
    local citizenid = Player.PlayerData.citizenid

    if not Config.AllowMultipleActiveRuns then
        local activeRun = DK.GetActiveRunByCitizenId(citizenid)

        if activeRun then
            DK.Notify(src, 'Du hast bereits einen aktiven Auftrag.', 'error')
            return
        end
    end

    local offer = DK.GetOfferById(citizenid, offerId)

    if not offer then
        DK.Notify(src, 'Dieser Auftrag ist nicht mehr verfügbar.', 'error')
        return
    end

    local profile = DK.GetOrCreateProfile(citizenid)
    local template = DKCargo.GetTemplate(offer.id)

    if not template then
        DK.Notify(src, 'Auftragsvorlage nicht gefunden.', 'error')
        return
    end

    if not DKCargo.PlayerCanSeeTemplate(profile, template) then
        DK.Notify(src, 'Du erfüllst die Voraussetzungen für diesen Auftrag nicht.', 'error')
        return
    end

    local cargo = DKCargo.GetItem(template.cargoItem)

    if not cargo then
        DK.Notify(src, 'Frachttyp nicht gefunden.', 'error')
        return
    end
    local cargoAmount = DKCargo.GetTemplateCargoAmount(template)

    local requiresSeal = template.requiresSeal == true or cargo.requiresSeal == true
    local requiresAdr = template.requiresAdr == true or cargo.requiresAdr == true

    local pickup = Config.PickupLocations[template.pickupId]
    local receiver = Config.DeliveryReceivers[template.receiverId]

    if not pickup or not receiver then
        DK.Notify(src, 'Auftrag ist fehlerhaft konfiguriert.', 'error')
        return
    end

    local truckParking = DK.GetFreeVehicleParking()
    local trailerParking = nil

    if not truckParking then
        DK.Notify(src, 'Aktuell ist kein Fahrzeugparkplatz frei.', 'error')
        return
    end

    if template.trailer then
        trailerParking = DK.GetFreeTrailerParking()

        if not trailerParking then
            DK.Notify(src, 'Aktuell ist kein Trailerparkplatz frei.', 'error')
            return
        end
    end

    local truckPlate = Bridge.Utils.GeneratePlate('DK')
    local trailerPlate = template.trailer and Bridge.Utils.GeneratePlate('DKT') or nil

    local basePayout = DK.RandomBetween(template.payout)
    local baseXp = DK.RandomBetween(template.xp)

    local cargoId = Bridge.Utils.GenerateSerial('CARGO', os.time())
    local cargoInventoryId = template.trailer
        and ('dk_spedition_trailer_%s_%s'):format(trailerPlate, os.time())
        or ('dk_spedition_vehicle_%s_%s'):format(truckPlate, os.time())

    local sealNumber = nil

    if requiresSeal then
    sealNumber = Bridge.Utils.GenerateSerial('DK-SEAL', os.time())
    end

    local runId = MySQL.insert.await(
        [[
            INSERT INTO dk_spedition_runs
            (
                citizenid,
                template_id,
                state,
                truck_model,
                trailer_model,
                truck_plate,
                trailer_plate,
                cargo_inventory_id,
                cargo_id,
                cargo_item,
                cargo_label,
                cargo_amount,
                origin_label,
                destination_label,
                pickup_id,
                receiver_id,
                seal_number,
                seal_broken,
                documents_collected,
                papers_accepted,
                base_payout,
                base_xp
            )
            VALUES (?, ?, 'VEHICLE_ASSIGNED', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, ?, ?)
        ]],
        {
            citizenid,
            template.id,
            template.vehicle,
            template.trailer,
            truckPlate,
            trailerPlate,
            cargoInventoryId,
            cargoId,
            template.cargoItem,
            cargo.label,
            cargoAmount,
            pickup.label,
            receiver.label,
            template.pickupId,
            template.receiverId,
            sealNumber,
            basePayout,
            baseXp
        }
    )

    if not runId then
        DK.Notify(src, 'Auftrag konnte nicht erstellt werden.', 'error')
        return
    end

    Bridge.Inventory.CreateInventory(cargoInventoryId, {
        label = ('Laderaum %s'):format(trailerPlate or truckPlate),
        maxweight = (cargo.weight or 1000) * cargoAmount,
        slots = 20
    })

    local spawnResult = DK.SpawnRunVehicles(runId, src, template, truckPlate, trailerPlate, truckParking, trailerParking)

    if not spawnResult or not spawnResult.truckNetId then
        DK.FailRun(runId, Player, 'vehicle_spawn_failed')
        DK.Notify(src, 'Fahrzeug konnte nicht bereitgestellt werden.', 'error')
        return
    end

    DK.UpdateRunEntityData(runId, spawnResult.truckNetId, spawnResult.trailerNetId)

local run = DK.GetRunById(runId)

ApplyRunEntityStateFromNetId(spawnResult.truckNetId, run)

if spawnResult.trailerNetId then
    ApplyRunEntityStateFromNetId(spawnResult.trailerNetId, run)
end

DK.GiveRunKeys(src, Player, run)

    DK.UpdateRunState(runId, 'KEYS_ISSUED')

    run = DK.GetRunById(runId)

    DK.ClearOfferCache(citizenid)

    DK.ActiveRuns[citizenid] = runId

    local pickupRouteCoords = nil

    if pickup.gateNpc and pickup.gateNpc.coords then
        pickupRouteCoords = pickup.gateNpc.coords
    elseif pickup.loadingDock then
        pickupRouteCoords = pickup.loadingDock
    end

    TriggerClientEvent('dk-spedition:client:runAssigned', src, {
        runId = runId,
        state = 'VEHICLE_ASSIGNED',

        truck = {
            model = template.vehicle,
            plate = truckPlate,
            netId = spawnResult.truckNetId,
            parking = truckParking
        },

        trailer = template.trailer and {
            model = template.trailer,
            plate = trailerPlate,
            netId = spawnResult.trailerNetId,
            parking = trailerParking
        } or nil,

        pickupId = template.pickupId,
receiverId = template.receiverId,

pickupRouteCoords = pickupRouteCoords,

pickup = {
    id = template.pickupId,
    label = pickup.label,
    gateNpc = pickup.gateNpc,
    loadingDock = pickup.loadingDock,
    documentOffice = pickup.documentOffice
},

receiver = {
    id = template.receiverId,
    label = receiver.label,
    coords = receiver.coords
},

        cargo = {
            item = template.cargoItem,
            label = cargo.label,
            amount = cargoAmount
        },

        requiresSeal = requiresSeal,
        sealNumber = sealNumber,

        payout = basePayout,
        xp = baseXp
    })

    DK.Notify(src, 'Auftrag angenommen. Dein Fahrzeug wurde bereitgestellt. Die Route zum Abholort wurde gesetzt.', 'success')
end

DK.CancelActiveRun = function(src, Player, reason)
    local citizenid = Player.PlayerData.citizenid
    local run = DK.GetActiveRunByCitizenId(citizenid)

    if not run then
        DK.Notify(src, 'Du hast keinen aktiven Auftrag.', 'error')
        return
    end

    DK.UpdateRunState(run.id, 'CANCELLED')

    if Config.RemoveKeysOnCancel then
        DK.RemoveRunKeys(src, Player, run)
    end

    if Config.RemoveDocumentsOnCancel then
        DK.RevokeDocumentsForRun(run.id)
    end

    if Config.SpawnCleanupOnCancel then
        DK.DeleteRunEntities(run)
    end

    DK.ActiveRuns[citizenid] = nil

    DK.Notify(src, 'Auftrag abgebrochen.', 'error')
end

DK.FailRun = function(runId, Player, reason)
    local run = DK.GetRunById(runId)

    if not run then return end

    DK.UpdateRunState(runId, 'FAILED')
    DK.MarkRunFailedInProfile(run.citizenid)
    DK.RevokeDocumentsForRun(runId)

    if Player then
        DK.Notify(Player.PlayerData.source, 'Auftrag fehlgeschlagen.', 'error')
    end
end

DK.BuildActiveRunPayload = function(run)
    if not run then return nil end

    local template = DKCargo.GetTemplate(run.template_id)
    local cargo = DKCargo.GetItem(run.cargo_item)

    local pickup = Config.PickupLocations and Config.PickupLocations[run.pickup_id] or nil
    local receiver = Config.DeliveryReceivers and Config.DeliveryReceivers[run.receiver_id] or nil

    return {
        id = run.id,
        templateId = run.template_id,
        state = run.state,

        label = template and template.label or run.template_id,
        description = template and template.description or '',

        category = template and template.category or '-',

        vehicle = run.truck_model,
        trailer = run.trailer_model,

        truckPlate = run.truck_plate,
        trailerPlate = run.trailer_plate,

        cargoItem = run.cargo_item,
        cargoLabel = run.cargo_label,
        cargoAmount = tonumber(run.cargo_amount) or 0,
        cargoUnit = cargo and cargo.unit or 'Stk.',

        originLabel = run.origin_label,
        destinationLabel = run.destination_label,

        pickupId = run.pickup_id,
        pickupLabel = pickup and pickup.label or run.origin_label,

        receiverId = run.receiver_id,
        receiverLabel = receiver and receiver.label or run.destination_label,

        sealNumber = run.seal_number,
        sealBroken = tonumber(run.seal_broken) == 1,

        documentsCollected = tonumber(run.documents_collected) == 1,
        papersAccepted = tonumber(run.papers_accepted) == 1,

        basePayout = tonumber(run.base_payout) or 0,
        baseXp = tonumber(run.base_xp) or 0,

        cancelXpPenalty = tonumber(run.base_xp) or 0
    }
end

DK.ApplyCancelXpPenalty = function(Player, run)
    if not Player or not run then
        return 0
    end

    local citizenid = Player.PlayerData.citizenid
    local penalty = tonumber(run.base_xp) or 0

    if penalty <= 0 then
        return 0
    end

    local profile = DK.GetOrCreateProfile(citizenid)

    if not profile then
        return 0
    end

    local oldXp = tonumber(profile.xp) or 0
    local newXp = oldXp - penalty

    if newXp < 0 then
        newXp = 0
    end

    local newLevel = tonumber(profile.level) or 1

    if DKLevels and DKLevels.GetLevelFromXp then
        newLevel = DKLevels.GetLevelFromXp(newXp)
    elseif DKLevels and DKLevels.CalculateLevel then
        newLevel = DKLevels.CalculateLevel(newXp)
    elseif DK.GetLevelFromXp then
        newLevel = DK.GetLevelFromXp(newXp)
    end

    if not newLevel or newLevel < 1 then
        newLevel = 1
    end

    MySQL.update.await(
        [[
            UPDATE dk_spedition_profiles
            SET xp = ?, level = ?
            WHERE citizenid = ?
        ]],
        {
            newXp,
            newLevel,
            citizenid
        }
    )

    return penalty
end
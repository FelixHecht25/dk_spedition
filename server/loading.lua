DK = DK or {}

local function GetPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end

    return GetEntityCoords(ped)
end

local function IsNearVector3(src, coords, distance)
    local playerCoords = GetPlayerCoords(src)
    if not playerCoords then return false end

    return #(playerCoords - vector3(coords.x, coords.y, coords.z)) <= distance
end

local function IsNearVector4(src, coords, distance)
    local playerCoords = GetPlayerCoords(src)
    if not playerCoords then return false end

    return #(playerCoords - vector3(coords.x, coords.y, coords.z)) <= distance
end

DK.IsRunAtPickupGate = function(src, run)
    if not run then return false end

    local pickup = Config.PickupLocations[run.pickup_id]
    if not pickup or not pickup.gateNpc then return false end

    return IsNearVector4(src, pickup.gateNpc.coords, 5.0)
end

DK.IsRunAtLoadingDock = function(src, run)
    if not run then return false end

    local pickup = Config.PickupLocations[run.pickup_id]
    if not pickup or not pickup.loadingDock then return false end

    return IsNearVector4(src, pickup.loadingDock, 12.0)
end

DK.IsRunAtDocumentOffice = function(src, run)
    if not run then return false end

    local pickup = Config.PickupLocations[run.pickup_id]
    if not pickup or not pickup.documentOffice then return false end

    local office = pickup.documentOffice
    local coords = office.coords or office

    return IsNearVector4(src, coords, 5.0)
end

RegisterNetEvent('dk-spedition:server:arriveAtPickup', function()
    local src = source

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    local run = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)

    if not run then
        DK.Notify(src, 'Du hast keinen aktiven Auftrag.', 'error')
        return
    end

    if run.state ~= 'VEHICLE_ASSIGNED' and run.state ~= 'KEYS_ISSUED' and run.state ~= 'EN_ROUTE_PICKUP' then
        DK.Notify(src, 'Dieser Auftrag ist aktuell nicht für die Abholung bereit.', 'error')
        return
    end

    if not DK.IsRunAtPickupGate(src, run) then
        DK.Notify(src, 'Du bist nicht am richtigen Abholort.', 'error')
        return
    end

    local plateOk, plateReason = DK.ValidateRunVehiclePlates(run)
    if not plateOk then
        DK.Notify(src, plateReason, 'error')
        return
    end

    DK.UpdateRunState(run.id, 'AT_PICKUP')

    local pickup = Config.PickupLocations[run.pickup_id]

    TriggerClientEvent('dk-spedition:client:pickupAccepted', src, {
        runId = run.id,
        loadingDock = pickup.loadingDock,
        documentOffice = pickup.documentOffice
    })

    DK.Notify(src, 'Anmeldung bestätigt. Fahre zur markierten Laderampe.', 'success')
end)

RegisterNetEvent('dk-spedition:server:beginLoading', function()
    local src = source

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    local run = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)

    if not run then
        DK.Notify(src, 'Du hast keinen aktiven Auftrag.', 'error')
        return
    end

    if run.state ~= 'AT_PICKUP' then
        DK.Notify(src, ('Du musst dich zuerst beim Abholort anmelden. Aktueller Status: %s'):format(tostring(run.state)), 'error')
        return
    end

    if Config.Loading.requireVehicleAtDock and not DK.IsRunAtLoadingDock(src, run) then
        DK.Notify(src, 'Der LKW oder Trailer steht nicht korrekt an der Laderampe.', 'error')
        return
    end

    local plateOk, plateReason = DK.ValidateRunVehiclePlates(run)
    if not plateOk then
        DK.Notify(src, plateReason, 'error')
        return
    end

    local loadTime = math.random(Config.Loading.minSeconds, Config.Loading.maxSeconds)
    local loadingEndsAt = os.time() + loadTime

    local changed = MySQL.update.await(
        'UPDATE dk_spedition_runs SET state = ?, loading_ends_at = ? WHERE id = ?',
        {
            'LOADING_STARTED',
            loadingEndsAt,
            run.id
        }
    )

    print(('[dk-spedition] beginLoading | runId: %s | changed: %s | state: LOADING_STARTED | loadingEndsAt: %s'):format(
        tostring(run.id),
        tostring(changed),
        tostring(loadingEndsAt)
    ))

    local pickup = Config.PickupLocations[run.pickup_id]

    TriggerClientEvent('dk-spedition:client:loadingStarted', src, {
        runId = run.id,
        loadingSeconds = loadTime,
        loadingEndsAt = loadingEndsAt,
        documentOffice = pickup.documentOffice
    })

    DK.Notify(src, 'Beladung gestartet. Hole währenddessen die Ladungspapiere im Büro ab.', 'primary')
end)

RegisterNetEvent('dk-spedition:server:collectPickupDocuments', function()
    local src = source

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    local run = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)

    if not run then
        DK.Notify(src, 'Du hast keinen aktiven Auftrag.', 'error')
        return
    end

    if run.state ~= 'LOADING_STARTED' then
        DK.Notify(src, 'Die Beladung wurde noch nicht gestartet.', 'error')
        return
    end

    if not DK.IsRunAtDocumentOffice(src, run) then
        DK.Notify(src, 'Du bist nicht im richtigen Büro für die Ladungspapiere.', 'error')
        return
    end

    if tonumber(run.documents_collected) == 1 then
        DK.Notify(src, 'Du hast die Papiere bereits abgeholt.', 'error')
        return
    end

    local success, reason = DK.GiveRunDocuments(src, Player, run)

    if not success then
        DK.Notify(src, reason or 'Papiere konnten nicht ausgegeben werden.', 'error')
        return
    end

    MySQL.update.await(
    'UPDATE dk_spedition_runs SET documents_collected = 1 WHERE id = ?',
    { run.id }
)

    TriggerClientEvent('dk-spedition:client:documentsCollected', src, {
        runId = run.id
    })

    DK.Notify(src, 'Ladungspapiere erhalten. Kehre nach Abschluss der Beladung zur Rampe zurück.', 'success')
end)

RegisterNetEvent('dk-spedition:server:finishLoading', function()
    local src = source

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    local run = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)

    if not run then
        DK.Notify(src, 'Du hast keinen aktiven Auftrag.', 'error')
        return
    end

    if run.state ~= 'LOADING_STARTED' then
        DK.Notify(src, 'Die Beladung läuft aktuell nicht.', 'error')
        return
    end

    if Config.Loading.requireVehicleAtDock and not DK.IsRunAtLoadingDock(src, run) then
        DK.Notify(src, 'Du bist nicht an der Laderampe.', 'error')
        return
    end

    if tonumber(run.loading_ends_at or 0) > os.time() then
        local remaining = tonumber(run.loading_ends_at) - os.time()
        DK.Notify(src, ('Die Beladung läuft noch %s Sekunden.'):format(remaining), 'error')
        return
    end

    if Config.Loading.requireDocumentsDuringLoading and tonumber(run.documents_collected) ~= 1 then
    local docsOk, docsReason = DK.PlayerHasRequiredRunDocuments(Player, run)

    if not docsOk then
        DK.Notify(src, docsReason or 'Du musst zuerst die Ladungspapiere im Büro abholen.', 'error')
        return
    end

    MySQL.update.await(
        'UPDATE dk_spedition_runs SET documents_collected = 1 WHERE id = ?',
        { run.id }
    )
    end

    local plateOk, plateReason = DK.ValidateRunVehiclePlates(run)
    if not plateOk then
        DK.Notify(src, plateReason, 'error')
        return
    end

    local success, reason = DK.LoadCargoIntoRunInventory(run)

    if not success then
        DK.Notify(src, reason or 'Die Ware konnte nicht geladen werden.', 'error')
        return
    end

    DK.UpdateRunState(run.id, 'LOADED')

    TriggerClientEvent('dk-spedition:client:cargoLoaded', src, {
        runId = run.id,
        receiverId = run.receiver_id,
        cargoInventoryId = run.cargo_inventory_id,
        requiresSeal = run.seal_number ~= nil,
        sealNumber = run.seal_number
    })

    if run.seal_number then
        DK.Notify(src, ('Ware geladen. Trailer/Fahrzeug wurde mit Plombe %s versiegelt.'):format(run.seal_number), 'success')
    else
        DK.Notify(src, 'Ware geladen. Fahre jetzt zum Empfänger.', 'success')
    end
end)
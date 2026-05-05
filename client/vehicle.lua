DK = DK or {}

local pickupRouteSet = false
local activeRunToken = 0

local function GetEntityFromNetId(netId)
    if not netId then return nil end

    local entity = NetworkGetEntityFromNetworkId(tonumber(netId))

    if entity and entity ~= 0 and DoesEntityExist(entity) then
        return entity
    end

    return nil
end

local function TrimPlate(plate)
    if not plate then return nil end
    return string.gsub(plate, '^%s*(.-)%s*$', '%1')
end

local function GetCurrentVehiclePlate()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not vehicle or vehicle == 0 then
        return nil, nil
    end

    return TrimPlate(GetVehicleNumberPlateText(vehicle)), vehicle
end

local function RemoveBlipHandle(key)
    local blip = DK[key]

    if blip and DoesBlipExist(blip) then
        SetBlipRoute(blip, false)
        RemoveBlip(blip)
    end

    DK[key] = nil
end

local function HardClearGpsAndRoutes()
    SetWaypointOff()

    if ClearGpsMultiRoute then
        ClearGpsMultiRoute()
    end

    if SetGpsMultiRouteRender then
        SetGpsMultiRouteRender(false)
    end

    if ClearAllBlipRoutes then
        ClearAllBlipRoutes()
    end

    if DK.ClearManagedBlips then
        DK.ClearManagedBlips()
    elseif DK.ClearRouteBlip then
        DK.ClearRouteBlip()
    end

    local blips = {
        'CurrentBlip',
        'RouteBlip',

        'PickupBlip',
        'PickupGateBlip',
        'PickupOfficeBlip',
        'PickupLocationBlip',
        'PickupRouteBlip',
        'WarehouseBlip',
        'CityWarehouseBlip',
        'GateBlip',

        'LoadingBlip',
        'LoadingDockBlip',
        'DocumentBlip',
        'DocumentOfficeBlip',

        'DeliveryBlip',
        'ReceiverBlip',
        'UnloadBlip',
        'UnloadSpotBlip',

        'ReturnBlip',
        'ReturnPointBlip',

        'VehicleBlip',
        'TruckBlip',
        'TrailerBlip',
        'SpawnedVehicleBlip',
        'SpawnedTruckBlip',
        'SpawnedTrailerBlip',
        'RunVehicleBlip',
        'RunTruckBlip',
        'RunTrailerBlip'
    }

    for _, key in pairs(blips) do
        RemoveBlipHandle(key)
    end
end

local function GetPickupFromRun()
    if not DK.CurrentRun then return nil end

    if DK.CurrentRun.pickup then
        return DK.CurrentRun.pickup
    end

    local pickupId =
        DK.CurrentRun.pickupId or
        DK.CurrentRun.pickup_id or
        DK.CurrentRun.pickup

    if pickupId and Config.PickupLocations and Config.PickupLocations[pickupId] then
        return Config.PickupLocations[pickupId]
    end

    return nil
end

local function GetPickupRouteCoords()
    if not DK.CurrentRun then
        return nil
    end

    if DK.CurrentRun.pickupRouteCoords then
        return DK.CurrentRun.pickupRouteCoords
    end

    local pickup = GetPickupFromRun()

    if not pickup then
        return nil
    end

    if pickup.gateNpc and pickup.gateNpc.coords then
        return pickup.gateNpc.coords
    end

    if pickup.loadingDock then
        return pickup.loadingDock
    end

    if pickup.coords then
        return pickup.coords
    end

    return nil
end

local function SetPickupRoute(force, token)
    if token and token ~= activeRunToken then
        return false
    end

    if not DK.CurrentRun then
        return false
    end

    if pickupRouteSet and not force then
        return true
    end

    local pickup = GetPickupFromRun()

    if not pickup then
        print('[dk-spedition/client] SetPickupRoute fehlgeschlagen: pickup fehlt im CurrentRun.')
        DK.Notify('Abholort konnte nicht geladen werden.', 'error')
        return false
    end

    local routeCoords = GetPickupRouteCoords()

    if not routeCoords then
        print('[dk-spedition/client] SetPickupRoute fehlgeschlagen: keine Koordinaten gefunden.')
        DK.Notify('Abholort konnte nicht markiert werden.', 'error')
        return false
    end

    if DK.RemoveManagedBlip then
        DK.RemoveManagedBlip('pickup')
        DK.RemoveManagedBlip('route')
        DK.RemoveManagedBlip('waypoint')
    end

    RemoveBlipHandle('PickupBlip')
    RemoveBlipHandle('PickupRouteBlip')
    RemoveBlipHandle('RouteBlip')
    RemoveBlipHandle('CurrentBlip')

    local pickupLabel = pickup.label or 'Abholort'

    if DK.CreatePickupBlip then
        DK.PickupBlip = DK.CreatePickupBlip(
            routeCoords,
            pickupLabel,
            true
        )
    elseif DK.CreateTemporaryBlip then
        DK.PickupBlip = DK.CreateTemporaryBlip(
            routeCoords,
            pickupLabel,
            473,
            5,
            true,
            'pickup'
        )
    elseif DK.SetWaypointBlip then
        DK.PickupBlip = DK.SetWaypointBlip(
            routeCoords,
            pickupLabel,
            473,
            5
        )
    else
        local blip = AddBlipForCoord(routeCoords.x, routeCoords.y, routeCoords.z)

        SetBlipSprite(blip, 473)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.85)
        SetBlipColour(blip, 5)
        SetBlipAsShortRange(blip, false)
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, 5)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(pickupLabel)
        EndTextCommandSetBlipName(blip)

        DK.PickupBlip = blip
    end

    SetNewWaypoint(routeCoords.x, routeCoords.y)

    pickupRouteSet = true

    DK.Notify(('Route gesetzt: %s'):format(pickupLabel), 'primary')

    return true
end

local function RemoveOldVehicleBlips()
    if DK.RemoveManagedBlip then
        DK.RemoveManagedBlip('run_vehicle_parking')
        DK.RemoveManagedBlip('vehicle')
        DK.RemoveManagedBlip('trailer')
    end

    RemoveBlipHandle('RunVehicleBlip')
    RemoveBlipHandle('VehicleBlip')
    RemoveBlipHandle('TruckBlip')
    RemoveBlipHandle('TrailerBlip')
    RemoveBlipHandle('SpawnedVehicleBlip')
    RemoveBlipHandle('SpawnedTruckBlip')
    RemoveBlipHandle('SpawnedTrailerBlip')
    RemoveBlipHandle('RunTruckBlip')
    RemoveBlipHandle('RunTrailerBlip')
end

RegisterNetEvent('dk-spedition:client:runAssigned', function(data)
    activeRunToken = activeRunToken + 1
    local myToken = activeRunToken

    DK.DispatcherOpen = false
    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })

    HardClearGpsAndRoutes()
    RemoveOldVehicleBlips()

    DK.CurrentRun = data
    pickupRouteSet = false

    print(('[dk-spedition/client] runAssigned | runId: %s | pickupRouteCoords: %s'):format(
    tostring(data.runId),
    data.pickupRouteCoords and ('%.2f %.2f %.2f'):format(
        data.pickupRouteCoords.x,
        data.pickupRouteCoords.y,
        data.pickupRouteCoords.z
    ) or 'nil'
))

    LocalPlayer.state:set('dkSpeditionRunId', data.runId, true)

    RemoveOldVehicleBlips()

    local routeOk = SetPickupRoute(true, myToken)

    if routeOk then
        DK.Notify('Auftrag angenommen. Hole dein Fahrzeug und fahre direkt zum markierten Abholort.', 'success')
    else
        DK.Notify('Auftrag angenommen. Abholort konnte nicht automatisch markiert werden.', 'error')
    end

    CreateThread(function()
        Wait(1500)

        if myToken ~= activeRunToken or not DK.CurrentRun then
            return
        end

        if data.truck and data.truck.netId then
            local truck = GetEntityFromNetId(data.truck.netId)

            if truck then
                DK.SetupVehicleTargets(truck)

            end
        end

        if data.trailer and data.trailer.netId then
            local trailer = GetEntityFromNetId(data.trailer.netId)

            if trailer then
                DK.SetupVehicleTargets(trailer)

            end
        end
    end)

    if data.pickup then
        data.pickup.id = data.pickup.id or data.pickup.label
        DK.SetupPickupTargets(data.pickup)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        if DK.CurrentRun and not pickupRouteSet and DK.CurrentRun.truck and DK.CurrentRun.truck.plate then
            local currentPlate = GetCurrentVehiclePlate()

            if currentPlate and currentPlate == TrimPlate(DK.CurrentRun.truck.plate) then
                SetPickupRoute(true, activeRunToken)
            end
        end
    end
end)

RegisterCommand('dkroutepickup', function()
    SetPickupRoute(true, activeRunToken)
end, false)

RegisterNetEvent('dk-spedition:client:runCompleted', function(data)
    activeRunToken = activeRunToken + 1

    DK.CurrentRun = nil
    DK.ActiveRun = nil
    pickupRouteSet = false

    LocalPlayer.state:set('dkSpeditionRunId', nil, true)

    HardClearGpsAndRoutes()
    RemoveOldVehicleBlips()

    SendNUIMessage({
        action = 'runCompleted',
        data = data
    })
end)

RegisterNetEvent('dk-spedition:client:runCancelled', function(data)
    print('[dk-spedition/client] runCancelled empfangen. Hard cleanup startet.')

    activeRunToken = activeRunToken + 1

    DK.CurrentRun = nil
    DK.ActiveRun = nil
    pickupRouteSet = false

    LocalPlayer.state:set('dkSpeditionRunId', nil, true)

    HardClearGpsAndRoutes()
    RemoveOldVehicleBlips()

    CreateThread(function()
        for i = 1, 30 do
            Wait(250)
            HardClearGpsAndRoutes()
            RemoveOldVehicleBlips()
        end
    end)

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })

    if DK.Notify then
        DK.Notify('Auftrag abgebrochen. Navigation wurde entfernt.', 'error', 6000)
    end
end)
DK = DK or {}

DK.ManagedBlips = DK.ManagedBlips or {}

DK.RegisterBlip = function(name, blip)
    if not blip then return blip end

    DK.ManagedBlips = DK.ManagedBlips or {}

    if name then
        local oldBlip = DK.ManagedBlips[name]

        if oldBlip and DoesBlipExist(oldBlip) then
            SetBlipRoute(oldBlip, false)
            RemoveBlip(oldBlip)
        end

        DK.ManagedBlips[name] = blip
    else
        DK.ManagedBlips[#DK.ManagedBlips + 1] = blip
    end

    return blip
end

DK.RemoveManagedBlip = function(name)
    if not DK.ManagedBlips then return end

    local blip = DK.ManagedBlips[name]

    if blip and DoesBlipExist(blip) then
        SetBlipRoute(blip, false)
        RemoveBlip(blip)
    end

    DK.ManagedBlips[name] = nil
end

DK.ClearManagedBlips = function()
    if not DK.ManagedBlips then
        DK.ManagedBlips = {}
    end

    for key, blip in pairs(DK.ManagedBlips) do
        if blip and DoesBlipExist(blip) then
            SetBlipRoute(blip, false)
            RemoveBlip(blip)
        end

        DK.ManagedBlips[key] = nil
    end

    local directBlips = {
        'CurrentBlip',
        'RouteBlip',

        -- Pickup / Lager / Abholung
        'PickupBlip',
        'PickupGateBlip',
        'PickupOfficeBlip',
        'PickupLocationBlip',
        'PickupRouteBlip',
        'WarehouseBlip',
        'CityWarehouseBlip',
        'GateBlip',

        -- Loading / Dokumente
        'LoadingBlip',
        'LoadingDockBlip',
        'DocumentBlip',
        'DocumentOfficeBlip',

        -- Delivery / Empfänger / Entladung
        'DeliveryBlip',
        'ReceiverBlip',
        'UnloadBlip',
        'UnloadSpotBlip',

        -- Rückgabe
        'ReturnBlip',
        'ReturnPointBlip',

        -- Fahrzeug-/Trailerblips
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

    for _, key in pairs(directBlips) do
        local blip = DK[key]

        if blip and DoesBlipExist(blip) then
            SetBlipRoute(blip, false)
            RemoveBlip(blip)
        end

        DK[key] = nil
    end

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
end

DK.CreateDepotBlip = function()
    if not Config then
        print('[dk-spedition/client] Config ist nil in blips.lua. Prüfe fxmanifest.lua shared_scripts.')
        return
    end

    if not Config.Depot or not Config.Depot.blip or not Config.Depot.blip.enabled then
        return
    end

    if DK.DepotBlip and DoesBlipExist(DK.DepotBlip) then
        RemoveBlip(DK.DepotBlip)
    end

    local blipData = Config.Depot.blip

    DK.DepotBlip = AddBlipForCoord(
        blipData.coords.x,
        blipData.coords.y,
        blipData.coords.z
    )

    SetBlipSprite(DK.DepotBlip, blipData.sprite or 477)
    SetBlipDisplay(DK.DepotBlip, 4)
    SetBlipScale(DK.DepotBlip, blipData.scale or 0.75)
    SetBlipColour(DK.DepotBlip, blipData.color or 5)
    SetBlipAsShortRange(DK.DepotBlip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blipData.label or Config.CompanyName or 'DK Spedition')
    EndTextCommandSetBlipName(DK.DepotBlip)

end

DK.CreateTemporaryBlip = function(coords, label, sprite, color, route, registerName)
    if not coords then return nil end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, sprite or 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.85)
    SetBlipColour(blip, color or 5)
    SetBlipAsShortRange(blip, false)

    local blipName = registerName or label or ('temporary_' .. tostring(GetGameTimer()))

    if route then
        if DK.RouteBlip and DoesBlipExist(DK.RouteBlip) then
            SetBlipRoute(DK.RouteBlip, false)
            RemoveBlip(DK.RouteBlip)
            DK.RouteBlip = nil
        end

        DK.RouteBlip = blip
        DK.CurrentBlip = blip

        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, color or 5)
    else
        DK.CurrentBlip = blip
    end

    DK.RegisterBlip(blipName, blip)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label or 'DK Spedition')
    EndTextCommandSetBlipName(blip)

    return blip
end

DK.CreatePickupBlip = function(coords, label, route)
    DK.PickupBlip = DK.CreateTemporaryBlip(
        coords,
        label or 'Abholort',
        473,
        5,
        route == true,
        'pickup'
    )

    return DK.PickupBlip
end

DK.CreateLoadingBlip = function(coords, label, route)
    DK.LoadingBlip = DK.CreateTemporaryBlip(
        coords,
        label or 'Laderampe',
        473,
        5,
        route == true,
        'loading'
    )

    return DK.LoadingBlip
end

DK.CreateDocumentBlip = function(coords, label, route)
    DK.DocumentBlip = DK.CreateTemporaryBlip(
        coords,
        label or 'Ladungspapiere',
        525,
        5,
        route == true,
        'documents'
    )

    return DK.DocumentBlip
end

DK.CreateDeliveryBlip = function(coords, label, route)
    DK.DeliveryBlip = DK.CreateTemporaryBlip(
        coords,
        label or 'Empfänger',
        280,
        5,
        route == true,
        'delivery'
    )

    return DK.DeliveryBlip
end

DK.CreateReturnBlip = function(coords, label, route)
    DK.ReturnBlip = DK.CreateTemporaryBlip(
        coords,
        label or 'Fahrzeugrückgabe',
        357,
        5,
        route == true,
        'return'
    )

    return DK.ReturnBlip
end

DK.CreateVehicleBlip = function(vehicle, label)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    if DK.VehicleBlip and DoesBlipExist(DK.VehicleBlip) then
        SetBlipRoute(DK.VehicleBlip, false)
        RemoveBlip(DK.VehicleBlip)
        DK.VehicleBlip = nil
    end

    DK.VehicleBlip = AddBlipForEntity(vehicle)

    SetBlipSprite(DK.VehicleBlip, 477)
    SetBlipDisplay(DK.VehicleBlip, 4)
    SetBlipScale(DK.VehicleBlip, 0.75)
    SetBlipColour(DK.VehicleBlip, 5)
    SetBlipAsShortRange(DK.VehicleBlip, false)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label or 'Speditionsfahrzeug')
    EndTextCommandSetBlipName(DK.VehicleBlip)

    DK.RegisterBlip('vehicle', DK.VehicleBlip)

    return DK.VehicleBlip
end

DK.CreateTrailerBlip = function(trailer, label)
    if not trailer or trailer == 0 or not DoesEntityExist(trailer) then
        return nil
    end

    if DK.TrailerBlip and DoesBlipExist(DK.TrailerBlip) then
        SetBlipRoute(DK.TrailerBlip, false)
        RemoveBlip(DK.TrailerBlip)
        DK.TrailerBlip = nil
    end

    DK.TrailerBlip = AddBlipForEntity(trailer)

    SetBlipSprite(DK.TrailerBlip, 479)
    SetBlipDisplay(DK.TrailerBlip, 4)
    SetBlipScale(DK.TrailerBlip, 0.75)
    SetBlipColour(DK.TrailerBlip, 5)
    SetBlipAsShortRange(DK.TrailerBlip, false)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label or 'Speditionstrailer')
    EndTextCommandSetBlipName(DK.TrailerBlip)

    DK.RegisterBlip('trailer', DK.TrailerBlip)

    return DK.TrailerBlip
end

DK.ClearRouteBlip = function()
    DK.ClearManagedBlips()
end

DK.SetWaypointBlip = function(coords, label, sprite, color)
    if not coords then return nil end

    return DK.CreateTemporaryBlip(
        coords,
        label or 'Ziel',
        sprite or 1,
        color or 5,
        true,
        label or 'waypoint'
    )
end

DK.CreateVehicleBlip = function(vehicle, label)
    return nil
end

DK.CreateTrailerBlip = function(trailer, label)
    return nil
end
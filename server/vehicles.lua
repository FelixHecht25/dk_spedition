DK = DK or {}

local reservedVehicleParking = {}
local reservedTrailerParking = {}

DK.GetFreeVehicleParking = function()
    for index, coords in pairs(Config.Depot.vehicleParking) do
        if not reservedVehicleParking[index] then
            reservedVehicleParking[index] = true
            return coords
        end
    end

    return nil
end

DK.GetFreeTrailerParking = function()
    for index, coords in pairs(Config.Depot.trailerParking) do
        if not reservedTrailerParking[index] then
            reservedTrailerParking[index] = true
            return coords
        end
    end

    return nil
end

DK.SpawnServerVehicle = function(model, coords, plate)
    local hash = joaat(model)

    local vehicle = CreateVehicle(
        hash,
        coords.x,
        coords.y,
        coords.z,
        coords.w or 0.0,
        true,
        true
    )

    if not vehicle or vehicle == 0 then
        return nil, nil
    end

    local timeout = 0

    while not DoesEntityExist(vehicle) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end

    if not DoesEntityExist(vehicle) then
        return nil, nil
    end

    SetVehicleNumberPlateText(vehicle, plate)
    SetEntityRoutingBucket(vehicle, 0)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    return vehicle, netId
end

DK.SpawnRunVehicles = function(runId, src, template, truckPlate, trailerPlate, truckParking, trailerParking)
    local truckEntity, truckNetId = DK.SpawnServerVehicle(template.vehicle, truckParking, truckPlate)

    if not truckEntity then
        return nil
    end

    DK.SpawnedVehicles[runId] = truckEntity

    local trailerEntity = nil
    local trailerNetId = nil

    if template.trailer then
        trailerEntity, trailerNetId = DK.SpawnServerVehicle(template.trailer, trailerParking, trailerPlate)

        if trailerEntity then
            DK.SpawnedTrailers[runId] = trailerEntity
        end
    end

    if truckEntity then
        Entity(truckEntity).state.dkSpeditionRunId = runId
        Entity(truckEntity).state.dkSpeditionPlate = truckPlate
    end

    if trailerEntity then
        Entity(trailerEntity).state.dkSpeditionRunId = runId
        Entity(trailerEntity).state.dkSpeditionPlate = trailerPlate
        Entity(trailerEntity).state.dkSpeditionTrailer = true
    end

    return {
        truckEntity = truckEntity,
        truckNetId = truckNetId,
        trailerEntity = trailerEntity,
        trailerNetId = trailerNetId
    }
end

DK.DeleteRunEntities = function(run)
    if not run then return end

    local runId = tonumber(run.id)

    local truckEntity = DK.SpawnedVehicles[runId]

    if truckEntity and DoesEntityExist(truckEntity) then
        DeleteEntity(truckEntity)
    end

    DK.SpawnedVehicles[runId] = nil

    local trailerEntity = DK.SpawnedTrailers[runId]

    if trailerEntity and DoesEntityExist(trailerEntity) then
        DeleteEntity(trailerEntity)
    end

    DK.SpawnedTrailers[runId] = nil
end

DK.GetRunTruckEntity = function(run)
    if not run then return nil end

    local runId = tonumber(run.id)

    if DK.SpawnedVehicles[runId] and DoesEntityExist(DK.SpawnedVehicles[runId]) then
        return DK.SpawnedVehicles[runId]
    end

    if run.truck_net_id then
        local entity = NetworkGetEntityFromNetworkId(tonumber(run.truck_net_id))

        if entity and entity ~= 0 and DoesEntityExist(entity) then
            return entity
        end
    end

    return nil
end

DK.GetRunTrailerEntity = function(run)
    if not run then return nil end

    local runId = tonumber(run.id)

    if DK.SpawnedTrailers[runId] and DoesEntityExist(DK.SpawnedTrailers[runId]) then
        return DK.SpawnedTrailers[runId]
    end

    if run.trailer_net_id then
        local entity = NetworkGetEntityFromNetworkId(tonumber(run.trailer_net_id))

        if entity and entity ~= 0 and DoesEntityExist(entity) then
            return entity
        end
    end

    return nil
end

DK.ValidateRunVehiclePlates = function(run)
    if not run then
        return false, 'Kein Auftrag gefunden.'
    end

    local truckEntity = DK.GetRunTruckEntity(run)

    if not truckEntity then
        return false, 'Der zugewiesene LKW wurde nicht gefunden.'
    end

    local truckPlate = Bridge.Utils.TrimPlate(GetVehicleNumberPlateText(truckEntity))

    if truckPlate ~= run.truck_plate then
        return false, 'Das LKW-Kennzeichen stimmt nicht mit dem Auftrag überein.'
    end

    if run.trailer_model then
        local trailerEntity = DK.GetRunTrailerEntity(run)

        if not trailerEntity then
            return false, 'Der zugewiesene Trailer wurde nicht gefunden.'
        end

        local trailerPlate = Bridge.Utils.TrimPlate(GetVehicleNumberPlateText(trailerEntity))

        if trailerPlate ~= run.trailer_plate then
            return false, 'Das Trailer-Kennzeichen stimmt nicht mit dem Auftrag überein.'
        end
    end

    return true, nil
end
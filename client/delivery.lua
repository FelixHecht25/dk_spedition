DK = DK or {}

RegisterNetEvent('dk-spedition:client:setUnloadSpot', function(data)
    if not DK.CurrentRun then return end

    DK.CurrentRun.unloadSpot = data.coords
    DK.CurrentRun.papersAccepted = true

    DK.SetWaypointBlip(data.coords, data.label or 'Abladeplatz', 473, 5)

    DK.Notify('Abladeplatz wurde markiert.', 'success')
end)

RegisterNetEvent('dk-spedition:client:unloadingStarted', function(data)
    DK.Notify('Entladung läuft...', 'primary')

    SendNUIMessage({
        action = 'unloadingStarted',
        data = data
    })
end)

CreateThread(function()
    while true do
        Wait(0)

        if DK.CurrentRun and DK.CurrentRun.unloadSpot then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local spot = DK.CurrentRun.unloadSpot
            local distance = #(coords - vector3(spot.x, spot.y, spot.z))

            if distance < 25.0 then
                DrawMarker(
                    1,
                    spot.x,
                    spot.y,
                    spot.z - 1.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    5.0,
                    5.0,
                    0.7,
                    80,
                    180,
                    255,
                    120,
                    false,
                    true,
                    2,
                    nil,
                    nil,
                    false
                )

                if distance < 5.0 then
                    DK.DrawText3D(vector3(spot.x, spot.y, spot.z + 1.0), '[E] Entladung starten')

                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('dk-spedition:server:startUnloading')
                        Wait(1000)
                    end
                end
            end
        end

        if DK.CurrentRun and DK.CurrentRun.returnToDepot and DK.CurrentRun.returnPoint then
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local spot = DK.CurrentRun.returnPoint
    local distance = #(coords - vector3(spot.x, spot.y, spot.z))

    if distance < 25.0 then
        DrawMarker(
            1,
            spot.x,
            spot.y,
            spot.z - 1.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            5.0,
            5.0,
            0.7,
            80,
            255,
            120,
            120,
            false,
            true,
            2,
            nil,
            nil,
            false
        )

        if distance < 5.0 then
            DK.DrawText3D(vector3(spot.x, spot.y, spot.z + 1.0), '[E] Fahrzeug zurückgeben')

            if IsControlJustPressed(0, 38) then
                local vehicleDamagePercent = 0

local ped = PlayerPedId()
local vehicle = GetVehiclePedIsIn(ped, false)

if vehicle and vehicle ~= 0 then
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)

    local bodyDamage = 100 - math.floor((bodyHealth / 1000.0) * 100)
    local engineDamage = 100 - math.floor((engineHealth / 1000.0) * 100)

    vehicleDamagePercent = math.max(bodyDamage, engineDamage)

    if vehicleDamagePercent < 0 then vehicleDamagePercent = 0 end
    if vehicleDamagePercent > 100 then vehicleDamagePercent = 100 end
end

TriggerServerEvent('dk-spedition:server:returnVehicle', {
    vehicleDamagePercent = vehicleDamagePercent
})
                Wait(1000)
            end
        end
    end
end
    end
end)

RegisterNetEvent('dk-spedition:client:returnVehicleToDepot', function(data)
    if not DK.CurrentRun then return end

    DK.CurrentRun.returnToDepot = true
    DK.CurrentRun.returnPoint = data.returnPoint and data.returnPoint.coords or nil
    DK.CurrentRun.pendingPayout = data.payout
    DK.CurrentRun.pendingXp = data.xp
    DK.CurrentRun.unloadSpot = nil

    if DK.CurrentRun.returnPoint then
        DK.SetWaypointBlip(DK.CurrentRun.returnPoint, 'Fahrzeugrückgabe', 357, 5)
        SetNewWaypoint(DK.CurrentRun.returnPoint.x, DK.CurrentRun.returnPoint.y)
    end

    DK.Notify('Bringe den Speditions-LKW zur markierten Fahrzeugrückgabe.', 'primary', 8000)
end)


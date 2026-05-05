local QBCore = exports['qb-core']:GetCoreObject()

DK = DK or {}

local function GetCoordsFromConfigEntry(entry)
    if not entry then return nil end

    if type(entry) == 'table' and entry.coords then
        return entry.coords
    end

    return entry
end

RegisterNetEvent('dk-spedition:client:pickupAccepted', function(data)
    if not DK.CurrentRun then return end

    DK.CurrentRun.loadingDock = data.loadingDock
    DK.CurrentRun.documentOffice = data.documentOffice
    DK.CurrentRun.loadingStarted = false

    if DK.RemoveManagedBlip then
        DK.RemoveManagedBlip('pickup')
        DK.RemoveManagedBlip('route')
    end

    if DK.PickupBlip and DoesBlipExist(DK.PickupBlip) then
        SetBlipRoute(DK.PickupBlip, false)
        RemoveBlip(DK.PickupBlip)
        DK.PickupBlip = nil
    end

    if DK.CreateLoadingBlip then
        DK.LoadingBlip = DK.CreateLoadingBlip(data.loadingDock, 'Laderampe', true)
    elseif DK.CreateTemporaryBlip then
        DK.LoadingBlip = DK.CreateTemporaryBlip(data.loadingDock, 'Laderampe', 473, 5, true, 'loading')
    elseif DK.SetWaypointBlip then
        DK.LoadingBlip = DK.SetWaypointBlip(data.loadingDock, 'Laderampe', 473, 5)
    end

    SetNewWaypoint(data.loadingDock.x, data.loadingDock.y)

    DK.Notify('Fahre zur markierten Laderampe.', 'primary')
end)

RegisterNetEvent('dk-spedition:client:loadingStarted', function(data)
    if not DK.CurrentRun then return end

    DK.CurrentRun.loadingStarted = true
    DK.CurrentRun.loadingEndsAt = data.loadingEndsAt
    DK.CurrentRun.documentOffice = data.documentOffice

    local officeCoords = GetCoordsFromConfigEntry(data.documentOffice)

    if officeCoords then
        if DK.RemoveManagedBlip then
            DK.RemoveManagedBlip('loading')
            DK.RemoveManagedBlip('route')
        end

        if DK.LoadingBlip and DoesBlipExist(DK.LoadingBlip) then
            SetBlipRoute(DK.LoadingBlip, false)
            RemoveBlip(DK.LoadingBlip)
            DK.LoadingBlip = nil
        end

        if DK.CreateDocumentBlip then
            DK.DocumentBlip = DK.CreateDocumentBlip(officeCoords, 'Büro für Ladungspapiere', true)
        elseif DK.CreateTemporaryBlip then
            DK.DocumentBlip = DK.CreateTemporaryBlip(officeCoords, 'Büro für Ladungspapiere', 525, 5, true, 'documents')
        elseif DK.SetWaypointBlip then
            DK.DocumentBlip = DK.SetWaypointBlip(officeCoords, 'Büro für Ladungspapiere', 525, 5)
        end

        SetNewWaypoint(officeCoords.x, officeCoords.y)
    end

    DK.Notify('Beladung läuft. Hole jetzt die Ladungspapiere.', 'primary')
end)

RegisterNetEvent('dk-spedition:client:documentsCollected', function(data)
    if not DK.CurrentRun then return end

    DK.CurrentRun.documentsCollected = true

    if DK.CurrentRun.loadingDock then
        if DK.RemoveManagedBlip then
            DK.RemoveManagedBlip('documents')
            DK.RemoveManagedBlip('route')
        end

        if DK.DocumentBlip and DoesBlipExist(DK.DocumentBlip) then
            SetBlipRoute(DK.DocumentBlip, false)
            RemoveBlip(DK.DocumentBlip)
            DK.DocumentBlip = nil
        end

        if DK.CreateLoadingBlip then
            DK.LoadingBlip = DK.CreateLoadingBlip(DK.CurrentRun.loadingDock, 'Zurück zur Laderampe', true)
        elseif DK.CreateTemporaryBlip then
            DK.LoadingBlip = DK.CreateTemporaryBlip(DK.CurrentRun.loadingDock, 'Zurück zur Laderampe', 473, 5, true, 'loading')
        elseif DK.SetWaypointBlip then
            DK.LoadingBlip = DK.SetWaypointBlip(DK.CurrentRun.loadingDock, 'Zurück zur Laderampe', 473, 5)
        end

        SetNewWaypoint(DK.CurrentRun.loadingDock.x, DK.CurrentRun.loadingDock.y)
    end
end)

RegisterNetEvent('dk-spedition:client:cargoLoaded', function(data)
    if not DK.CurrentRun then return end

    DK.CurrentRun.cargoLoaded = true
    DK.CurrentRun.cargoInventoryId = data.cargoInventoryId
    DK.CurrentRun.requiresSeal = data.requiresSeal
    DK.CurrentRun.sealNumber = data.sealNumber
    DK.CurrentRun.receiverId = data.receiverId

    local receiver = Config.DeliveryReceivers[data.receiverId]

    if receiver then
        DK.SetupReceiverTarget(data.receiverId, receiver)

        if DK.RemoveManagedBlip then
            DK.RemoveManagedBlip('loading')
            DK.RemoveManagedBlip('route')
        end

        if DK.LoadingBlip and DoesBlipExist(DK.LoadingBlip) then
            SetBlipRoute(DK.LoadingBlip, false)
            RemoveBlip(DK.LoadingBlip)
            DK.LoadingBlip = nil
        end

        if DK.CreateDeliveryBlip then
            DK.DeliveryBlip = DK.CreateDeliveryBlip(receiver.coords, receiver.label or 'Empfänger', true)
        elseif DK.CreateTemporaryBlip then
            DK.DeliveryBlip = DK.CreateTemporaryBlip(receiver.coords, receiver.label or 'Empfänger', 280, 5, true, 'delivery')
        elseif DK.SetWaypointBlip then
            DK.DeliveryBlip = DK.SetWaypointBlip(receiver.coords, receiver.label or 'Empfänger', 280, 5)
        end

        SetNewWaypoint(receiver.coords.x, receiver.coords.y)
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if DK.CurrentRun and DK.CurrentRun.loadingDock and not DK.CurrentRun.loadingStarted then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dock = DK.CurrentRun.loadingDock
            local distance = #(coords - vector3(dock.x, dock.y, dock.z))

            if distance < 18.0 then
                DrawMarker(
                    1,
                    dock.x,
                    dock.y,
                    dock.z - 1.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    4.0,
                    4.0,
                    0.6,
                    255,
                    180,
                    0,
                    120,
                    false,
                    true,
                    2,
                    nil,
                    nil,
                    false
                )

                if distance < 4.5 then
                    DK.DrawText3D(vector3(dock.x, dock.y, dock.z + 1.0), '[E] Beladung starten')

                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('dk-spedition:server:beginLoading')
                        Wait(1000)
                    end
                end
            end
        end

        if DK.CurrentRun and DK.CurrentRun.loadingStarted and DK.CurrentRun.loadingDock then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dock = DK.CurrentRun.loadingDock
            local distance = #(coords - vector3(dock.x, dock.y, dock.z))

            if distance < 5.0 then
                DK.DrawText3D(vector3(dock.x, dock.y, dock.z + 1.0), '[E] Beladung abschließen')

                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent('dk-spedition:server:finishLoading')
                    Wait(1000)
                end
            end
        end
    end
end)
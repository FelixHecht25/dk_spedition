local QBCore = exports['qb-core']:GetCoreObject()

DK = DK or {}

DK.PlayerData = {}
DK.CurrentRun = nil
DK.CurrentBlip = nil
DK.CurrentRouteBlip = nil
DK.SpawnedPeds = DK.SpawnedPeds or {}
DK.DispatcherOpen = false
DK.AdrExamOpen = false

DK.Debug = function(message)
    if Config.Debug then
        print(('[dk-spedition/client] %s'):format(message))
    end
end

DK.Notify = function(message, notifyType, length)
    QBCore.Functions.Notify(message, notifyType or 'primary', length or 5000)
end

DK.LoadModel = function(model)
    local hash = type(model) == 'number' and model or joaat(model)

    if not IsModelInCdimage(hash) then
        return false
    end

    RequestModel(hash)

    local timeout = 0

    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end

    return HasModelLoaded(hash), hash
end

DK.CreatePed = function(key, pedModel, coords, scenario)
    if DK.SpawnedPeds[key] and DoesEntityExist(DK.SpawnedPeds[key]) then
        return DK.SpawnedPeds[key]
    end

    local loaded, hash = DK.LoadModel(pedModel)
    if not loaded then return nil end

    local ped = CreatePed(
        0,
        hash,
        coords.x,
        coords.y,
        coords.z - 1.0,
        coords.w or 0.0,
        false,
        true
    )

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    if scenario then
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    end

    DK.SpawnedPeds[key] = ped

    return ped
end

DK.SetWaypointBlip = function(coords, label, sprite, color)
    if DK.CurrentRouteBlip and DoesBlipExist(DK.CurrentRouteBlip) then
        RemoveBlip(DK.CurrentRouteBlip)
    end

    DK.CurrentRouteBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(DK.CurrentRouteBlip, sprite or 1)
    SetBlipColour(DK.CurrentRouteBlip, color or 5)
    SetBlipScale(DK.CurrentRouteBlip, 0.85)
    SetBlipRoute(DK.CurrentRouteBlip, true)
    SetBlipRouteColour(DK.CurrentRouteBlip, color or 5)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label or 'Ziel')
    EndTextCommandSetBlipName(DK.CurrentRouteBlip)
end

DK.ClearRouteBlip = function()
    if DK.CurrentRouteBlip and DoesBlipExist(DK.CurrentRouteBlip) then
        RemoveBlip(DK.CurrentRouteBlip)
    end

    DK.CurrentRouteBlip = nil
end

DK.DrawText3D = function(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)

    if not onScreen then return end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(x, y)

    local factor = string.len(text) / 370
    DrawRect(x, y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 120)
end

CreateThread(function()
    Wait(1500)

    DK.PlayerData = QBCore.Functions.GetPlayerData() or {}

    DK.CreateDepotBlip()
    DK.SetupTargets()

    DK.Debug('Client initialisiert. Targets wurden gesetzt.')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)

    DK.PlayerData = QBCore.Functions.GetPlayerData() or {}

    DK.CreateDepotBlip()
    DK.SetupTargets()

    DK.Debug('Spieler geladen. Targets wurden gesetzt.')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    DK.PlayerData = {}
    DK.CurrentRun = nil
    DK.ClearRouteBlip()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    DK.PlayerData = data or {}
end)

RegisterNetEvent('dk-spedition:client:progress', function(data)
    data = data or {}

    QBCore.Functions.Progressbar(
        data.name or 'dk_spedition_progress',
        data.label or 'Arbeit läuft...',
        data.duration or 5000,
        false,
        data.canCancel ~= false,
        {
            disableMovement = data.disableMovement ~= false,
            disableCarMovement = data.disableCarMovement ~= false,
            disableMouse = false,
            disableCombat = true
        },
        data.animation or {},
        {},
        {},
        function()
            if data.successEvent then
                TriggerServerEvent(data.successEvent, data.args)
            end
        end,
        function()
            if data.cancelMessage then
                DK.Notify(data.cancelMessage, 'error')
            end
        end
    )
end)

RegisterNetEvent('dk-spedition:client:runCancelled', function(data)
    print('[dk-spedition/client] Auftrag abgebrochen. Client-Cleanup wird ausgeführt.')

    DK.CurrentRun = nil

    LocalPlayer.state:set('dkSpeditionRunId', nil, true)

    if DK.ClearRouteBlip then
        DK.ClearRouteBlip()
    end

    if DK.CurrentBlip and DoesBlipExist(DK.CurrentBlip) then
        RemoveBlip(DK.CurrentBlip)
        DK.CurrentBlip = nil
    end

    if DK.RouteBlip and DoesBlipExist(DK.RouteBlip) then
        RemoveBlip(DK.RouteBlip)
        DK.RouteBlip = nil
    end

    if DK.PickupBlip and DoesBlipExist(DK.PickupBlip) then
        RemoveBlip(DK.PickupBlip)
        DK.PickupBlip = nil
    end

    if DK.LoadingBlip and DoesBlipExist(DK.LoadingBlip) then
        RemoveBlip(DK.LoadingBlip)
        DK.LoadingBlip = nil
    end

    if DK.DocumentBlip and DoesBlipExist(DK.DocumentBlip) then
        RemoveBlip(DK.DocumentBlip)
        DK.DocumentBlip = nil
    end

    if DK.DeliveryBlip and DoesBlipExist(DK.DeliveryBlip) then
        RemoveBlip(DK.DeliveryBlip)
        DK.DeliveryBlip = nil
    end

    if DK.ReturnBlip and DoesBlipExist(DK.ReturnBlip) then
        RemoveBlip(DK.ReturnBlip)
        DK.ReturnBlip = nil
    end

    SetWaypointOff()

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })

    DK.Notify('Auftrag abgebrochen. Navigation wurde entfernt.', 'error', 6000)
end)

RegisterCommand('dkdispatch', function()
    TriggerServerEvent('dk-spedition:server:requestDispatcherData')
end, false)

RegisterCommand('dkspeditionreinit', function()
    DK.TargetsCreated = false

    DK.PlayerData = QBCore.Functions.GetPlayerData() or {}

    DK.CreateDepotBlip()
    DK.SetupTargets()

    DK.Notify('DK Spedition Targets neu initialisiert.', 'success')
end, false)
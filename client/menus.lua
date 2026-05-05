DK = DK or {}

RegisterNetEvent('dk-spedition:client:openDispatcher', function(data)
    DK.DispatcherOpen = true

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openDispatcher',
        data = data
    })
end)

RegisterNetEvent('dk-spedition:client:updateDispatcherOffers', function(data)
    SendNUIMessage({
        action = 'updateDispatcher',
        data = data
    })
end)

RegisterNUICallback('close', function(_, cb)
    DK.DispatcherOpen = false
    DK.AdrExamOpen = false

    SetNuiFocus(false, false)

    cb({ ok = true })
end)

RegisterNUICallback('refreshOffers', function(_, cb)
    TriggerServerEvent('dk-spedition:server:refreshDispatcherOffers')

    cb({ ok = true })
end)

RegisterNUICallback('acceptOffer', function(data, cb)
    if not data or not data.offerId then
        cb({ ok = false })
        return
    end

    TriggerServerEvent('dk-spedition:server:acceptOffer', data.offerId)

    DK.DispatcherOpen = false
    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })

    cb({ ok = true })
end)

RegisterNUICallback('cancelActiveRun', function(_, cb)
    print('[dk-spedition/client] NUI cancelActiveRun empfangen')

    TriggerServerEvent('dk-spedition:server:cancelActiveRun')

    cb({
        ok = true
    })
end)

RegisterCommand('dkcloseui', function()
    DK.DispatcherOpen = false
    DK.AdrExamOpen = false

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })
end, false)
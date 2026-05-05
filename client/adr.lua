DK = DK or {}

RegisterNetEvent('dk-spedition:client:openAdrExam', function(data)
    DK.AdrExamOpen = true

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openAdrExam',
        data = data
    })
end)

RegisterNetEvent('dk-spedition:client:adrExamResult', function(data)
    DK.AdrExamOpen = false

    SendNUIMessage({
        action = 'adrExamResult',
        data = data
    })

    if data and data.passed then
        Wait(500)

        TriggerServerEvent('dk-spedition:server:requestDispatcherData')
    end
end)

RegisterNUICallback('submitAdrExam', function(data, cb)
    TriggerServerEvent('dk-spedition:server:submitAdrExam', data.answers or {})

    cb({ ok = true })
end)
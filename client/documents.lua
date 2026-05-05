DK = DK or {}

RegisterNetEvent('dk-spedition:client:showDocument', function(info)
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'showDocument',
        data = info
    })
end)

RegisterNetEvent('dk-spedition:client:policeDocumentResult', function(result)
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'showPoliceDocumentResult',
        data = result
    })
end)

RegisterNetEvent('dk-spedition:client:policeRunResult', function(result)
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'showPoliceRunResult',
        data = result
    })
end)

RegisterCommand('dkcheckdoc', function(_, args)
    local serial = args[1]

    if not serial then
        DK.Notify('Nutzung: /dkcheckdoc <Seriennummer>', 'error')
        return
    end

    TriggerServerEvent('dk-spedition:server:policeValidateDocument', serial)
end, false)

RegisterCommand('dkcheckplate', function(_, args)
    local plate = table.concat(args, ' ')

    if not plate or plate == '' then
        DK.Notify('Nutzung: /dkcheckplate <Kennzeichen>', 'error')
        return
    end

    TriggerServerEvent('dk-spedition:server:policeInspectRunByPlate', plate)
end, false)

RegisterCommand('dkopencargo', function(_, args)
    local plate = table.concat(args, ' ')

    if not plate or plate == '' then
        DK.Notify('Nutzung: /dkopencargo <Kennzeichen>', 'error')
        return
    end

    TriggerServerEvent('dk-spedition:server:policeOpenCargoByPlate', plate)
end, false)
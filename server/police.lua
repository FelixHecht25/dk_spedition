DK = DK or {}

local function IsPolice(Player)
    if not Player or not Player.PlayerData.job then return false end

    return Player.PlayerData.job.name == 'police'
end

local function BuildPoliceDocumentPayload(dbDocument)
    if not dbDocument then return nil end

    local data = DK.JsonDecode(dbDocument.data)

    return {
        id = dbDocument.id,
        runId = dbDocument.run_id,
        citizenid = dbDocument.citizenid,
        serial = dbDocument.serial,
        docType = dbDocument.doc_type,
        status = dbDocument.status,
        issuedAt = dbDocument.issued_at,
        expiresAt = dbDocument.expires_at,
        data = data
    }
end

RegisterNetEvent('dk-spedition:server:policeValidateDocument', function(serial)
    local src = source
    local Officer = DK.GetPlayer(src)

    if not IsPolice(Officer) then
        DK.Notify(src, 'Keine Berechtigung.', 'error')
        return
    end

    if not serial or serial == '' then
        DK.Notify(src, 'Keine Seriennummer angegeben.', 'error')
        return
    end

    local dbDocument = DK.GetDocumentBySerial(serial)

    if not dbDocument then
        TriggerClientEvent('dk-spedition:client:policeDocumentResult', src, {
            valid = false,
            reason = 'Dokument ist nicht registriert. Verdacht auf Fälschung.',
            serial = serial
        })

        return
    end

    local run = DK.GetRunById(dbDocument.run_id)

    local result = {
        valid = true,
        serial = serial,
        document = BuildPoliceDocumentPayload(dbDocument),
        run = run and {
            id = run.id,
            state = run.state,
            truckPlate = run.truck_plate,
            trailerPlate = run.trailer_plate,
            cargoLabel = run.cargo_label,
            cargoAmount = run.cargo_amount,
            origin = run.origin_label,
            destination = run.destination_label,
            sealNumber = run.seal_number,
            sealBroken = tonumber(run.seal_broken) == 1
        } or nil,
        warnings = {}
    }

    if dbDocument.status ~= 'active' then
        result.valid = false
        result.warnings[#result.warnings + 1] = 'Dokumentstatus ist nicht aktiv: ' .. tostring(dbDocument.status)
    end

    if not run then
        result.valid = false
        result.warnings[#result.warnings + 1] = 'Zugehöriger Auftrag nicht gefunden.'
    elseif run.state == 'COMPLETED' or run.state == 'FAILED' or run.state == 'CANCELLED' then
        result.warnings[#result.warnings + 1] = 'Auftrag ist nicht mehr aktiv: ' .. tostring(run.state)
    end

    TriggerClientEvent('dk-spedition:client:policeDocumentResult', src, result)
end)

RegisterNetEvent('dk-spedition:server:policeInspectRunByPlate', function(plate)
    local src = source
    local Officer = DK.GetPlayer(src)

    if not IsPolice(Officer) then
        DK.Notify(src, 'Keine Berechtigung.', 'error')
        return
    end

    plate = Bridge.Utils.TrimPlate(plate)

    if not plate or plate == '' then
        DK.Notify(src, 'Kein Kennzeichen angegeben.', 'error')
        return
    end

    local run = MySQL.single.await(
        [[
            SELECT *
            FROM dk_spedition_runs
            WHERE truck_plate = ?
            OR trailer_plate = ?
            ORDER BY id DESC
            LIMIT 1
        ]],
        {
            plate,
            plate
        }
    )

    if not run then
        TriggerClientEvent('dk-spedition:client:policeRunResult', src, {
            found = false,
            plate = plate,
            reason = 'Kein Speditionsauftrag zu diesem Kennzeichen gefunden.'
        })

        return
    end

    local documents = MySQL.query.await(
        [[
            SELECT *
            FROM dk_spedition_documents
            WHERE run_id = ?
            ORDER BY id ASC
        ]],
        { run.id }
    )

    local documentPayload = {}

    for _, document in pairs(documents or {}) do
        documentPayload[#documentPayload + 1] = BuildPoliceDocumentPayload(document)
    end

    TriggerClientEvent('dk-spedition:client:policeRunResult', src, {
        found = true,
        plate = plate,
        run = {
            id = run.id,
            citizenid = run.citizenid,
            state = run.state,
            templateId = run.template_id,
            truckPlate = run.truck_plate,
            trailerPlate = run.trailer_plate,
            cargoLabel = run.cargo_label,
            cargoAmount = run.cargo_amount,
            origin = run.origin_label,
            destination = run.destination_label,
            sealNumber = run.seal_number,
            sealBroken = tonumber(run.seal_broken) == 1,
            documentsCollected = tonumber(run.documents_collected) == 1,
            papersAccepted = tonumber(run.papers_accepted) == 1
        },
        documents = documentPayload
    })
end)

RegisterNetEvent('dk-spedition:server:policeOpenCargoByPlate', function(plate)
    local src = source
    local Officer = DK.GetPlayer(src)

    if not IsPolice(Officer) then
        DK.Notify(src, 'Keine Berechtigung.', 'error')
        return
    end

    plate = Bridge.Utils.TrimPlate(plate)

    local run = MySQL.single.await(
        [[
            SELECT *
            FROM dk_spedition_runs
            WHERE truck_plate = ?
            OR trailer_plate = ?
            ORDER BY id DESC
            LIMIT 1
        ]],
        {
            plate,
            plate
        }
    )

    if not run then
        DK.Notify(src, 'Kein Speditionsladeraum zu diesem Kennzeichen gefunden.', 'error')
        return
    end

    DK.OpenCargoInventory(src, run)
end)
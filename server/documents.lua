local QBCore = exports['qb-core']:GetCoreObject()

DK = DK or {}

local function GetDocumentConfig(docType)
    if Config.DocumentTypes and Config.DocumentTypes[docType] then
        return Config.DocumentTypes[docType]
    end

    return {
        label = docType,
        template = docType,
        adrOnly = false
    }
end

local function GetSerialPrefix(docType)
    if docType == 'cargo_manifest' then return 'DK-FB' end
    if docType == 'delivery_note' then return 'DK-LS' end
    if docType == 'hazmat_permit' then return 'DK-GTG' end
    if docType == 'adr_transport_paper' then return 'DK-ADR' end
    if docType == 'adr_transport_sheet' then return 'DK-ADR-BG' end

    return 'DK-DOC'
end

local function GetPlayerFullName(Player)
    if not Player then return 'Unbekannter Fahrer' end

    local name = Bridge.Core.GetFullName(Player)

    if name and name ~= '' then
        return name
    end

    local charinfo = Player.PlayerData and Player.PlayerData.charinfo or {}

    return ('%s %s'):format(
        charinfo.firstname or '',
        charinfo.lastname or ''
    )
end

local function GetDisplayCargoAmount(run, cargo)
    local rawAmount = tonumber(run.cargo_amount) or 1
    local unit = cargo and cargo.unit or 'Stk.'
    local displayAmount = rawAmount

    if cargo and cargo.hazard and cargo.hazard.litersPerInventoryItem then
        displayAmount = rawAmount * tonumber(cargo.hazard.litersPerInventoryItem)
        unit = 'L'
    end

    return displayAmount, unit, rawAmount
end

local function GetAddressBlock(location, fallbackLabel)
    if not location then
        return {
            label = fallbackLabel or '-',
            address = Config.Documents and (Config.Documents.city .. ', ' .. Config.Documents.country) or '-'
        }
    end

    return {
        label = location.label or fallbackLabel or '-',
        address = location.address or ((Config.Documents and (Config.Documents.city .. ', ' .. Config.Documents.country)) or '-')
    }
end

DK.BuildDocumentDescription = function(docType, run, serial, Player)
    local driverName = GetPlayerFullName(Player)
    local cargo = DKCargo.GetItem(run.cargo_item)
    local hazard = cargo and cargo.hazard or {}
    local displayAmount, displayUnit = GetDisplayCargoAmount(run, cargo)

    if docType == 'cargo_manifest' then
        return (
            'Frachtbrief Nr. %s\n' ..
            'Fahrer: %s\n' ..
            'Ladung: %s\n' ..
            'Menge: %s %s\n' ..
            'Von: %s\n' ..
            'Nach: %s\n' ..
            'LKW: %s\n' ..
            'Trailer: %s\n' ..
            'Plombe: %s'
        ):format(
            serial,
            driverName,
            run.cargo_label,
            displayAmount,
            displayUnit,
            run.origin_label,
            run.destination_label,
            run.truck_plate or '-',
            run.trailer_plate or '-',
            run.seal_number or '-'
        )
    end

    if docType == 'delivery_note' then
        return (
            'Lieferschein Nr. %s\n' ..
            'Empfänger: %s\n' ..
            'Ladung: %s\n' ..
            'Menge: %s %s\n' ..
            'Kennzeichen: %s\n' ..
            'Trailer: %s'
        ):format(
            serial,
            run.destination_label,
            run.cargo_label,
            displayAmount,
            displayUnit,
            run.truck_plate or '-',
            run.trailer_plate or '-'
        )
    end

    if docType == 'hazmat_permit' then
        return (
            'Gefahrgut-Transportgenehmigung Nr. %s\n' ..
            'Fahrer: %s\n' ..
            'Ladung: %s\n' ..
            'UN-Nummer: %s\n' ..
            'Stoffbezeichnung: %s\n' ..
            'ADR-Klasse: %s\n' ..
            'Verpackungsgruppe: %s\n' ..
            'Transportart: %s\n' ..
            'Menge: %s %s\n' ..
            'LKW: %s\n' ..
            'Trailer: %s'
        ):format(
            serial,
            driverName,
            run.cargo_label,
            hazard.unNumber or '-',
            hazard.substanceName or run.cargo_label,
            hazard.adrClass or hazard.class or '-',
            hazard.packingGroup or hazard.packageGroup or '-',
            hazard.packagingDescription or hazard.packagingType or '-',
            displayAmount,
            displayUnit,
            run.truck_plate or '-',
            run.trailer_plate or '-'
        )
    end

    if docType == 'adr_transport_paper' or docType == 'adr_transport_sheet' then
        return (
            'Beförderungspapier gem. Kapitel 5.4 ADR Nr. %s\n' ..
            'UN-Nummer: %s\n' ..
            'Stoffbezeichnung: %s\n' ..
            'Menge: %s %s\n' ..
            'Art: %s\n' ..
            'Route: %s -> %s\n' ..
            'Plombe: %s\n' ..
            'Notfallhinweis: %s'
        ):format(
            serial,
            hazard.unNumber or '-',
            hazard.substanceName or run.cargo_label,
            displayAmount,
            displayUnit,
            hazard.packagingDescription or hazard.packagingType or '-',
            run.origin_label,
            run.destination_label,
            run.seal_number or '-',
            hazard.emergencyNote or 'Keine Angaben'
        )
    end

    return ('Dokument Nr. %s für Auftrag #%s'):format(serial, run.id)
end

DK.BuildDocumentInfo = function(docType, run, Player)
    local documentConfig = GetDocumentConfig(docType)
    local serialPrefix = GetSerialPrefix(docType)
    local serial = Bridge.Utils.GenerateSerial(serialPrefix, run.id)

    local template = DKCargo.GetTemplate(run.template_id)
    local cargo = DKCargo.GetItem(run.cargo_item)
    local hazard = cargo and cargo.hazard or {}

    local pickup = Config.PickupLocations and Config.PickupLocations[run.pickup_id] or nil
    local receiver = Config.DeliveryReceivers and Config.DeliveryReceivers[run.receiver_id] or nil

    local driverName = GetPlayerFullName(Player)
    local displayAmount, displayUnit, inventoryAmount = GetDisplayCargoAmount(run, cargo)

    local sender = Config.Documents and Config.Documents.defaultSender or {
        name = Config.CompanyName or 'Spedition',
        street = '-',
        zipCity = '-',
        country = '-',
        phone = '-',
        email = '-'
    }

    local loader = Config.Documents and Config.Documents.defaultLoader or sender

    local pickupAddress = GetAddressBlock(pickup, run.origin_label)
    local receiverAddress = GetAddressBlock(receiver, run.destination_label)

    local isAdr = false

    if template and template.requiresAdr == true then
        isAdr = true
    end

    if cargo and cargo.requiresAdr == true then
        isAdr = true
    end

    local isTankTrailer = false

    if template and template.trailer == 'tanker' then
        isTankTrailer = true
    end

    if hazard.packagingType == 'Tankauflieger' then
        isTankTrailer = true
    end

    local info = {
        runId = run.id,
        serial = serial,
        documentType = docType,
        documentLabel = documentConfig.label or docType,

        company = Config.Documents and Config.Documents.companyName or Config.CompanyName,
        companySubtitle = Config.Documents and Config.Documents.companySubtitle or nil,

        driver = driverName,
        citizenid = Player.PlayerData.citizenid,

        cargo = run.cargo_label,
        cargoItem = run.cargo_item,
        cargoAmount = displayAmount,
        cargoUnit = displayUnit,
        inventoryAmount = inventoryAmount,

        origin = run.origin_label,
        destination = run.destination_label,

        truckPlate = run.truck_plate,
        trailerPlate = run.trailer_plate,

        sealNumber = run.seal_number,

        issuedAt = DK.GetDisplayDateTime(0),
        validUntil = DK.GetDisplayDateTime(Config.DocumentValiditySeconds),

        document = {
            type = docType,
            label = documentConfig.label or docType,
            template = documentConfig.template or docType,
            serial = serial,
            issuedAt = DK.GetDisplayDateTime(0),
            validUntil = DK.GetDisplayDateTime(Config.DocumentValiditySeconds),
            orderId = tostring(run.id),
            tourNumber = ('DK-T-%s'):format(run.id)
        },

        companyData = {
            name = Config.Documents and Config.Documents.companyName or Config.CompanyName,
            subtitle = Config.Documents and Config.Documents.companySubtitle or '',
            city = Config.Documents and Config.Documents.city or 'Wien',
            country = Config.Documents and Config.Documents.country or 'Österreich',
            useLogo = Config.Documents and Config.Documents.useLogo == true
        },

        driverData = {
            name = driverName,
            citizenid = Player.PlayerData.citizenid,
            truckPlate = run.truck_plate,
            trailerPlate = run.trailer_plate,
            sealNumber = run.seal_number
        },

        senderData = sender,
        loaderData = loader,

        pickupData = {
            label = pickupAddress.label,
            address = pickupAddress.address
        },

        receiverData = {
            label = receiverAddress.label,
            address = receiverAddress.address
        },

        cargoData = {
            item = run.cargo_item,
            label = run.cargo_label,
            amount = displayAmount,
            unit = displayUnit,
            inventoryAmount = inventoryAmount,
            inventoryUnit = cargo and cargo.unit or 'Stk.',
            category = cargo and cargo.category or (template and template.category) or '-',
            requiresAdr = isAdr,
            requiresSeal = run.seal_number ~= nil
        },

        hazardData = {
            unNumber = hazard.unNumber,
            substanceName = hazard.substanceName or run.cargo_label,
            adrClass = hazard.adrClass or hazard.class,
            hazardMain = hazard.hazardMain,
            hazardSub = hazard.hazardSub or '-',
            packingGroup = hazard.packingGroup or hazard.packageGroup,
            tunnelCode = hazard.tunnelCode,
            transportCategory = hazard.transportCategory,
            kemler = hazard.kemler,

            packageCountLabel = hazard.packageCountLabel,
            packagingType = hazard.packagingType,
            packagingDescription = hazard.packagingDescription,

            limitedQuantity = hazard.limitedQuantity,
            exemptedQuantity = hazard.exemptedQuantity,

            litersPerInventoryItem = hazard.litersPerInventoryItem,
            emergencyNote = hazard.emergencyNote
        },

        meta = {
            isAdr = isAdr,
            isTankTrailer = isTankTrailer,
            templateId = run.template_id,
            pickupId = run.pickup_id,
            receiverId = run.receiver_id
        }
    }

    if cargo and cargo.hazard then
        info.hazardClass = hazard.adrClass or hazard.class
        info.unNumber = hazard.unNumber
        info.packageGroup = hazard.packingGroup or hazard.packageGroup
        info.emergencyNote = hazard.emergencyNote
    end

    info.description = DK.BuildDocumentDescription(docType, run, serial, Player)

    return info
end

DK.SaveDocument = function(run, Player, docType, info)
    local expiresAt = DK.GetDateTime(Config.DocumentValiditySeconds)

    local documentId = MySQL.insert.await(
        [[
            INSERT INTO dk_spedition_documents
            (
                run_id,
                citizenid,
                serial,
                doc_type,
                data,
                status,
                expires_at
            )
            VALUES (?, ?, ?, ?, ?, 'active', ?)
        ]],
        {
            run.id,
            Player.PlayerData.citizenid,
            info.serial,
            docType,
            DK.JsonEncode(info),
            expiresAt
        }
    )

    info.documentId = documentId

    return documentId, info
end

DK.GiveRunDocument = function(src, Player, run, docType)
    local info = DK.BuildDocumentInfo(docType, run, Player)
    local documentId

    documentId, info = DK.SaveDocument(run, Player, docType, info)

    if not QBCore.Shared.Items[docType] then
    print(('[dk-spedition] FEHLER: Dokument-Item existiert nicht in QBCore.Shared.Items: %s'):format(docType))
    return false, info
end

local success = Bridge.Inventory.AddItem(
    src,
    docType,
    1,
    false,
    info,
    'dk-spedition-issued-document'
)

if not success then
    print(('[dk-spedition] FEHLER: Inventory AddItem fehlgeschlagen für Dokument: %s | runId: %s | serial: %s'):format(
        tostring(docType),
        tostring(run.id),
        tostring(info.serial)
    ))
end

    if success and QBCore.Shared.Items[docType] then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[docType], 'add')
    end

    return success, info
end

DK.GiveRunDocuments = function(src, Player, run)
    local template = DKCargo.GetTemplate(run.template_id)

    if not template then
        return false, 'Auftragsvorlage nicht gefunden.'
    end

    for _, docType in pairs(template.documents or {}) do
        local ok = DK.GiveRunDocument(src, Player, run, docType)

        if not ok then
            return false, ('Dokument konnte nicht ausgestellt werden: %s'):format(docType)
        end
    end

    return true, nil
end

DK.GetDocumentBySerial = function(serial)
    if not serial then return nil end

    return MySQL.single.await(
        'SELECT * FROM dk_spedition_documents WHERE serial = ? LIMIT 1',
        { serial }
    )
end

DK.RevokeDocumentsForRun = function(runId)
    MySQL.update.await(
        [[
            UPDATE dk_spedition_documents
            SET status = 'revoked'
            WHERE run_id = ?
            AND status = 'active'
        ]],
        { runId }
    )
end

DK.MarkDocumentsDeliveredForRun = function(runId)
    MySQL.update.await(
        [[
            UPDATE dk_spedition_documents
            SET status = 'delivered'
            WHERE run_id = ?
            AND status = 'active'
        ]],
        { runId }
    )
end

DK.ValidateDocumentItem = function(Player, run, itemName)
    if not Player or not run then
        return false, 'Kein Spieler oder Auftrag gefunden.'
    end

    local hasItem, item = Bridge.Inventory.HasItemWithInfo(Player, itemName, function(info)
        return tonumber(info.runId) == tonumber(run.id)
    end)

    if not hasItem or not item then
        return false, ('Dokument fehlt: %s'):format(itemName)
    end

    local info = item.info or {}

    if not info.serial then
        return false, 'Dokument hat keine Seriennummer.'
    end

    local dbDocument = DK.GetDocumentBySerial(info.serial)

    if not dbDocument then
        return false, 'Dokument ist nicht registriert.'
    end

    if dbDocument.status ~= 'active' then
        return false, 'Dokument ist nicht mehr gültig.'
    end

    if tonumber(dbDocument.run_id) ~= tonumber(run.id) then
        return false, 'Dokument gehört nicht zu diesem Auftrag.'
    end

    if dbDocument.citizenid ~= Player.PlayerData.citizenid then
        return false, 'Dokument gehört nicht zu diesem Fahrer.'
    end

    if info.truckPlate ~= run.truck_plate then
        return false, 'LKW-Kennzeichen im Dokument stimmt nicht.'
    end

    if run.trailer_plate and info.trailerPlate ~= run.trailer_plate then
        return false, 'Trailer-Kennzeichen im Dokument stimmt nicht.'
    end

    return true, item
end

DK.ValidateRequiredDeliveryDocuments = function(Player, run)
    local template = DKCargo.GetTemplate(run.template_id)

    if not template then
        return false, 'Auftragsvorlage nicht gefunden.'
    end

    for _, docType in pairs(template.documents or {}) do
        local ok, reasonOrItem = DK.ValidateDocumentItem(Player, run, docType)

        if not ok then
            return false, reasonOrItem
        end
    end

    return true, nil
end

DK.PlayerHasRequiredRunDocuments = function(Player, run)
    local template = DKCargo.GetTemplate(run.template_id)

    if not template then
        return false, 'Auftragsvorlage nicht gefunden.'
    end

    for _, docType in pairs(template.documents or {}) do
        local ok, reasonOrItem = DK.ValidateDocumentItem(Player, run, docType)

        if not ok then
            return false, reasonOrItem
        end
    end

    return true, nil
end

DK.RemoveDeliveryDocuments = function(Player, run)
    if not Player or not run then return end

    local template = DKCargo.GetTemplate(run.template_id)
    if not template then return end

    local src = Player.PlayerData.source
    local items = Player.PlayerData.items or {}

    for _, docType in pairs(template.documents or {}) do
        for slot, item in pairs(items) do
            if item and item.name == docType then
                local info = item.info or {}

                if tonumber(info.runId) == tonumber(run.id) then
                    Bridge.Inventory.RemoveItem(
                        src,
                        docType,
                        1,
                        item.slot or slot,
                        'dk-spedition-deliver-document'
                    )
                end
            end
        end
    end

    DK.MarkDocumentsDeliveredForRun(run.id)
end

local function RegisterDocumentUsableItem(itemName)
    if not QBCore.Shared.Items[itemName] then
        print(('[dk-spedition] Dokument-Item fehlt in QBCore.Shared.Items: %s'):format(itemName))
        return
    end

    QBCore.Functions.CreateUseableItem(itemName, function(source, item)
        if not item or not item.info then return end

        TriggerClientEvent('dk-spedition:client:showDocument', source, item.info)
    end)
end

CreateThread(function()
    Wait(1000)

    RegisterDocumentUsableItem('cargo_manifest')
    RegisterDocumentUsableItem('delivery_note')
    RegisterDocumentUsableItem('hazmat_permit')
    RegisterDocumentUsableItem('adr_transport_paper')

    RegisterDocumentUsableItem('adr_transport_sheet')

    RegisterDocumentUsableItem('seal_tag')
    RegisterDocumentUsableItem('spedition_keys')
end)
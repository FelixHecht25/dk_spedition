DK = DK or {}

local function IsTruthy(value)
    return value == true
        or value == 1
        or value == '1'
        or value == 'true'
        or value == 'TRUE'
end

local function RefreshRun(run)
    if not run or not run.id then
        return run
    end

    return DK.GetRunById(run.id) or run
end

local function GetEntityFromNetId(netId)
    if not netId then return nil end

    local entity = NetworkGetEntityFromNetworkId(tonumber(netId))

    if entity and entity ~= 0 and DoesEntityExist(entity) then
        return entity
    end

    return nil
end

local function SetSealBrokenStatebags(run, broken)
    if not run then return end

    local truck = GetEntityFromNetId(run.truck_net_id)
    local trailer = GetEntityFromNetId(run.trailer_net_id)

    if truck then
        Entity(truck).state:set('dkSpeditionSealBroken', broken == true, true)
    end

    if trailer then
        Entity(trailer).state:set('dkSpeditionSealBroken', broken == true, true)
    end
end

DK.BuildCargoInfo = function(run)
    if not run then return {} end

    local template = DKCargo.GetTemplate(run.template_id)
    local cargo = DKCargo.GetItem(run.cargo_item)

    local info = {
        runId = run.id,
        cargoId = run.cargo_id,

        cargoLabel = run.cargo_label,
        cargoItem = run.cargo_item,
        cargoAmount = run.cargo_amount,

        origin = run.origin_label,
        destination = run.destination_label,

        legalOwner = Config.CompanyName,

        truckPlate = run.truck_plate,
        trailerPlate = run.trailer_plate,

        sealed = run.seal_number ~= nil,
        sealNumber = run.seal_number,

        stolenValue = cargo and cargo.illegalValue or 0,

        description = ('%sx %s | Von: %s | Nach: %s'):format(
            run.cargo_amount,
            run.cargo_label,
            run.origin_label,
            run.destination_label
        )
    }

    if cargo and cargo.hazard then
        info.hazard = cargo.hazard
        info.hazardClass = cargo.hazard.adrClass or cargo.hazard.class
        info.unNumber = cargo.hazard.unNumber
        info.packageGroup = cargo.hazard.packingGroup or cargo.hazard.packageGroup
        info.emergencyNote = cargo.hazard.emergencyNote
    end

    if template then
        info.requiresAdr = template.requiresAdr == true
        info.requiresSeal = template.requiresSeal == true
        info.category = template.category
    end

    return info
end

DK.LoadCargoIntoRunInventory = function(run)
    if not run then return false, 'Kein Auftrag gefunden.' end

    local cargoInfo = DK.BuildCargoInfo(run)

    local success = Bridge.Inventory.AddItem(
        run.cargo_inventory_id,
        run.cargo_item,
        tonumber(run.cargo_amount) or 1,
        false,
        cargoInfo,
        'dk-spedition-load-cargo'
    )

    if not success then
        return false, 'Ladung konnte nicht in den Laderaum gelegt werden.'
    end

    return true, nil
end

DK.OpenCargoInventory = function(src, run)
    if not run then
        DK.Notify(src, 'Kein Laderaum gefunden.', 'error')
        return
    end

    Bridge.Inventory.OpenInventory(src, run.cargo_inventory_id)
end

RegisterNetEvent('dk-spedition:server:openCargoInventory', function(runId)
    local src = source

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    local run = nil

    if runId then
        run = DK.GetRunById(runId)
    else
        run = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)
    end

    if not run then
        DK.Notify(src, 'Kein aktiver Laderaum gefunden.', 'error')
        return
    end

    run = RefreshRun(run)

    local hasKeys = DK.PlayerHasRunKeys(Player, run)

    if not hasKeys then
        DK.Notify(src, 'Du hast keine passenden Schlüssel für diesen Laderaum.', 'error')
        return
    end

    if run.seal_number
        and tostring(run.seal_number) ~= ''
        and not IsTruthy(run.seal_broken)
    then
        DK.Notify(
            src,
            ('Der Laderaum ist verplombt. Plombe %s muss zuerst gebrochen werden.'):format(run.seal_number),
            'error',
            7000
        )
        return
    end

    DK.OpenCargoInventory(src, run)
end)

DK.CountMatchingCargo = function(run)
    if not run then return 0 end

    local items = Bridge.Inventory.GetItems(run.cargo_inventory_id)
    local count = 0

    for _, item in pairs(items or {}) do
        if item and item.name == run.cargo_item then
            local info = item.info or {}

            if tonumber(info.runId) == tonumber(run.id) and info.cargoId == run.cargo_id then
                count = count + (tonumber(item.amount) or 1)
            end
        end
    end

    return count
end

DK.RemoveMatchingCargo = function(run, amount)
    if not run then return false end

    amount = tonumber(amount) or tonumber(run.cargo_amount) or 1

    local items = Bridge.Inventory.GetItems(run.cargo_inventory_id)
    local remaining = amount

    for slot, item in pairs(items or {}) do
        if remaining <= 0 then break end

        if item and item.name == run.cargo_item then
            local info = item.info or {}

            if tonumber(info.runId) == tonumber(run.id) and info.cargoId == run.cargo_id then
                local removeAmount = math.min(remaining, tonumber(item.amount) or 1)

                Bridge.Inventory.RemoveItem(
                    run.cargo_inventory_id,
                    run.cargo_item,
                    removeAmount,
                    item.slot or slot,
                    'dk-spedition-unload-cargo'
                )

                remaining = remaining - removeAmount
            end
        end
    end

    return remaining <= 0
end

DK.BreakRunSeal = function(src, runId)
    local Player = DK.GetPlayer(src)
    if not Player then return end

    local run = nil

    if runId then
        run = DK.GetRunById(runId)
    else
        run = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)
    end

    if not run then
        DK.Notify(src, 'Kein Auftrag gefunden.', 'error')
        return
    end

    run = RefreshRun(run)

    if not run.seal_number or tostring(run.seal_number) == '' then
        DK.Notify(src, 'Dieser Auftrag ist nicht verplombt.', 'error')
        return
    end

    if IsTruthy(run.seal_broken) then
        DK.Notify(src, 'Die Plombe ist bereits gebrochen.', 'error')
        return
    end

    DK.UpdateRunSealBroken(run.id, true)

    run = RefreshRun(run)

    SetSealBrokenStatebags(run, true)

    DK.Notify(
        src,
        ('Plombe %s wurde gebrochen. Der Laderaum kann jetzt geöffnet werden.'):format(run.seal_number),
        'error',
        7000
    )
end

RegisterNetEvent('dk-spedition:server:breakSeal', function(runId)
    local src = source

    DK.BreakRunSeal(src, runId)
end)
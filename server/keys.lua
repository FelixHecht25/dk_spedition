local QBCore = exports['qb-core']:GetCoreObject()

DK = DK or {}

DK = DK or {}

DK.GiveRunKeys = function(src, Player, run)
    if not Player or not run then return false end

    local keyInfo = {
        runId = run.id,
        truckPlate = run.truck_plate,
        trailerPlate = run.trailer_plate,
        company = Config.CompanyName,
        issuedTo = Bridge.Core.GetFullName(Player),
        citizenid = Player.PlayerData.citizenid,
        issuedAt = DK.GetDisplayDateTime(0),
        description = ('Schlüssel für LKW %s%s'):format(
            run.truck_plate,
            run.trailer_plate and (' / Trailer ' .. run.trailer_plate) or ''
        )
    }

    Bridge.Inventory.AddItem(
        src,
        'spedition_keys',
        1,
        false,
        keyInfo,
        'dk-spedition-issued-keys'
    )

    Bridge.Keys.Give(src, run.truck_plate, run.truck_net_id)

    if run.trailer_plate then
        Bridge.Keys.Give(src, run.trailer_plate, run.trailer_net_id)
    end

    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['spedition_keys'], 'add')

    return true
end

DK.RemoveRunKeys = function(src, Player, run)
    if not Player or not run then return false end

    local items = Player.PlayerData.items or {}

    for slot, item in pairs(items) do
        if item and item.name == 'spedition_keys' then
            local info = item.info or {}

            if tonumber(info.runId) == tonumber(run.id) then
                Bridge.Inventory.RemoveItem(
                    src,
                    'spedition_keys',
                    1,
                    item.slot or slot,
                    'dk-spedition-remove-keys'
                )
            end
        end
    end

    Bridge.Keys.Remove(src, run.truck_plate)

    if run.trailer_plate then
        Bridge.Keys.Remove(src, run.trailer_plate)
    end

    return true
end

DK.PlayerHasRunKeys = function(Player, run)
    if not Player or not run then return false end

    local hasKey = Bridge.Inventory.HasItemWithInfo(Player, 'spedition_keys', function(info)
        return tonumber(info.runId) == tonumber(run.id)
    end)

    return hasKey
end
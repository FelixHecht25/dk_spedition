Bridge = Bridge or {}

local QBCore = exports['qb-core']:GetCoreObject()

Bridge.Core = {}

Bridge.Core.GetPlayer = function(src)
    return QBCore.Functions.GetPlayer(src)
end

Bridge.Core.Notify = function(src, message, notifyType, length)
    TriggerClientEvent('QBCore:Notify', src, message, notifyType or 'primary', length or 5000)
end

Bridge.Core.GetIdentifier = function(Player)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

Bridge.Core.GetFullName = function(Player)
    if not Player then return 'Unbekannt' end

    local charinfo = Player.PlayerData.charinfo or {}

    local first = charinfo.firstname or 'Unbekannt'
    local last = charinfo.lastname or ''

    return (first .. ' ' .. last):gsub('%s+', ' ')
end

Bridge.Core.HasJob = function(Player, jobName)
    if not Player then return false end
    if not Player.PlayerData.job then return false end

    return Player.PlayerData.job.name == jobName
end

Bridge.Money = {}

Bridge.Money.Remove = function(Player, account, amount, reason)
    if not Player then return false end
    return Player.Functions.RemoveMoney(account, amount, reason or 'dk-spedition-money-remove')
end

Bridge.Money.Add = function(Player, account, amount, reason)
    if not Player then return false end
    return Player.Functions.AddMoney(account, amount, reason or 'dk-spedition-money-add')
end

Bridge.Money.CanPay = function(Player, amount)
    if not Player then return false, nil end

    if Player.PlayerData.money.bank >= amount then
        return true, 'bank'
    end

    if Player.PlayerData.money.cash >= amount then
        return true, 'cash'
    end

    return false, nil
end

Bridge.Inventory = {}

Bridge.Inventory.AddItem = function(target, item, amount, slot, info, reason)
    return exports[Config.InventoryResource]:AddItem(
        target,
        item,
        amount,
        slot or false,
        info or {},
        reason or 'dk-spedition-add-item'
    )
end

Bridge.Inventory.RemoveItem = function(target, item, amount, slot, reason)
    return exports[Config.InventoryResource]:RemoveItem(
        target,
        item,
        amount,
        slot,
        reason or 'dk-spedition-remove-item'
    )
end

Bridge.Inventory.CreateInventory = function(inventoryId, data)
    if exports[Config.InventoryResource].CreateInventory then
        return exports[Config.InventoryResource]:CreateInventory(inventoryId, data)
    end

    return true
end

Bridge.Inventory.OpenInventory = function(src, inventoryId)
    if exports[Config.InventoryResource].OpenInventory then
        return exports[Config.InventoryResource]:OpenInventory(src, inventoryId)
    end

    TriggerClientEvent('qb-inventory:client:openInventory', src, inventoryId)
end

Bridge.Inventory.GetItems = function(inventoryId)
    if exports[Config.InventoryResource].GetInventory then
        local inventory = exports[Config.InventoryResource]:GetInventory(inventoryId)
        if inventory and inventory.items then
            return inventory.items
        end
    end

    if exports[Config.InventoryResource].GetItemsByName then
        return {}
    end

    return {}
end

Bridge.Inventory.HasItemWithInfo = function(Player, itemName, matcher)
    if not Player then return false, nil end

    local items = Player.PlayerData.items or {}

    for _, item in pairs(items) do
        if item and item.name == itemName then
            local info = item.info or {}

            if matcher(info, item) then
                return true, item
            end
        end
    end

    return false, nil
end

Bridge.Keys = {}

Bridge.Keys.Give = function(src, plate, vehicleNetId)
    TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)

    return true
end

Bridge.Keys.Remove = function(src, plate)
    return true
end

Bridge.Fuel = {}

Bridge.Fuel.SetFuel = function(vehicle, amount)
    if not vehicle or vehicle == 0 then return end

    Entity(vehicle).state.fuel = amount or 100.0
end

Bridge.Dispatch = {}

Bridge.Dispatch.CargoTheft = function(coords, plate)
end

Bridge.Progress = {}

Bridge.Progress.Client = function(src, data)
    TriggerClientEvent('dk-spedition:client:progress', src, data)
end

Bridge.Utils = {}

Bridge.Utils.TrimPlate = function(plate)
    if not plate then return nil end
    return string.gsub(plate, '^%s*(.-)%s*$', '%1')
end

Bridge.Utils.GenerateSerial = function(prefix, runId)
    return ('%s-%s-%s'):format(prefix, runId or '0', math.random(10000, 99999))
end

Bridge.Utils.GeneratePlate = function(prefix)
    prefix = prefix or 'DKL'

    local number = math.random(100, 999)
    local letters = string.char(math.random(65, 90)) .. string.char(math.random(65, 90))

    return string.upper(('%s%s%s'):format(prefix, number, letters))
end

Bridge.Utils.Distance = function(a, b)
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end
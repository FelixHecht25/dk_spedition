DKCargo = DKCargo or {}

local function IsLicenseActive(profile, license)
    if not profile then return false end

    if license == 'adr' then
        return tonumber(profile.adr_license) == 1
            or tostring(profile.adr_license) == '1'
            or profile.adr_license == true
    end

    if license == 'heavy' then
        return tonumber(profile.heavy_license) == 1
            or tostring(profile.heavy_license) == '1'
            or profile.heavy_license == true
    end

    if license == 'coolchain' then
        return tonumber(profile.coolchain_license) == 1
            or tostring(profile.coolchain_license) == '1'
            or profile.coolchain_license == true
    end

    return false
end

local function RandomRange(value)
    if type(value) == 'table' then
        local min = tonumber(value.min) or 1
        local max = tonumber(value.max) or min

        if max < min then
            max = min
        end

        return math.random(min, max)
    end

    return tonumber(value) or 1
end

DKCargo.GetItem = function(itemName)
    if not Config.CargoItems then
        print('[dk-spedition] Config.CargoItems fehlt.')
        return nil
    end

    return Config.CargoItems[itemName]
end

DKCargo.GetTemplate = function(templateId)
    for _, template in pairs(Config.JobTemplates or {}) do
        if template.id == templateId then
            return template
        end
    end

    return nil
end

DKCargo.GetTemplateCargoAmount = function(template)
    if not template then return 1 end

    if template.cargoAmount then
        return RandomRange(template.cargoAmount)
    end

    local cargo = DKCargo.GetItem(template.cargoItem)

    if cargo and cargo.amount then
        return RandomRange(cargo.amount)
    end

    return 1
end

DKCargo.PlayerCanSeeTemplate = function(profile, template)
    if not profile or not template then
        return false
    end

    local level = tonumber(profile.level) or 1

    if level < tonumber(template.requiredLevel or 1) then
        return false
    end

    for _, license in pairs(template.requiredLicenses or {}) do
        if not IsLicenseActive(profile, license) then
            return false
        end
    end

    return true
end

DKCargo.GetAvailableTemplates = function(profile)
    local available = {}

    for _, template in pairs(Config.JobTemplates or {}) do
        if DKCargo.PlayerCanSeeTemplate(profile, template) then
            available[#available + 1] = template
        end
    end

    print(('[dk-spedition] AvailableTemplates | level: %s | adr: %s | count: %s'):format(
        tostring(profile and profile.level),
        tostring(profile and profile.adr_license),
        tostring(#available)
    ))

    return available
end

DKCargo.GetRandomOffers = function(profile, count)
    count = count or Config.OfferCount or 3

    local available = DKCargo.GetAvailableTemplates(profile)
    local offers = {}
    local pool = {}

    local level = tonumber(profile.level) or 1
    local hasAdr = IsLicenseActive(profile, 'adr')

    if Config.ADR and level >= Config.ADR.requiredLevel and hasAdr then
        local hazmatPool = {}

        for _, template in pairs(available) do
            if template.category == 'hazmat' or template.requiresAdr == true then
                hazmatPool[#hazmatPool + 1] = template
            end
        end

        if #hazmatPool > 0 and #offers < count then
            local index = math.random(1, #hazmatPool)
            offers[#offers + 1] = hazmatPool[index]
        end
    end

    for _, template in pairs(available) do
        local alreadyAdded = false

        for _, selected in pairs(offers) do
            if selected.id == template.id then
                alreadyAdded = true
                break
            end
        end

        if not alreadyAdded then
            pool[#pool + 1] = template
        end
    end

    while #offers < count and #pool > 0 do
        local index = math.random(1, #pool)
        offers[#offers + 1] = pool[index]
        table.remove(pool, index)
    end

    print(('[dk-spedition] RandomOffers generated: %s'):format(#offers))

    for _, offer in pairs(offers) do
        print(('[dk-spedition] Offer: %s | category: %s | level: %s | adr: %s'):format(
            tostring(offer.id),
            tostring(offer.category),
            tostring(offer.requiredLevel),
            tostring(offer.requiresAdr)
        ))
    end

    return offers
end

DKCargo.BuildOfferPayload = function(template)
    local cargo = DKCargo.GetItem(template.cargoItem)
    local pickup = Config.PickupLocations and Config.PickupLocations[template.pickupId] or nil
    local receiver = Config.DeliveryReceivers and Config.DeliveryReceivers[template.receiverId] or nil

    local minPayout = 0
    local maxPayout = 0
    local minXp = 0
    local maxXp = 0

    if template.payout then
        minPayout = tonumber(template.payout.min) or 0
        maxPayout = tonumber(template.payout.max) or minPayout
    end

    if template.xp then
        minXp = tonumber(template.xp.min) or 0
        maxXp = tonumber(template.xp.max) or minXp
    end

    local amountPreview = nil

    if type(template.cargoAmount) == 'table' then
        amountPreview = {
            min = tonumber(template.cargoAmount.min) or 1,
            max = tonumber(template.cargoAmount.max) or tonumber(template.cargoAmount.min) or 1
        }
    else
        amountPreview = {
            min = tonumber(template.cargoAmount) or 1,
            max = tonumber(template.cargoAmount) or 1
        }
    end

    return {
        id = template.id,
        label = template.label,
        description = template.description,
        category = template.category,

        requiredLevel = tonumber(template.requiredLevel) or 1,
        requiredLicenses = template.requiredLicenses or {},

        vehicle = template.vehicle,
        trailer = template.trailer,

        cargoItem = template.cargoItem,
        cargoLabel = cargo and cargo.label or template.cargoItem,
        cargoAmount = amountPreview,

        requiresSeal = template.requiresSeal == true or (cargo and cargo.requiresSeal == true),
        requiresAdr = template.requiresAdr == true or (cargo and cargo.requiresAdr == true),

        payout = {
            min = minPayout,
            max = maxPayout
        },

        xp = {
            min = minXp,
            max = maxXp
        },

        documents = template.documents or {},

        pickupId = template.pickupId,
        pickupLabel = pickup and pickup.label or template.pickupId,

        receiverId = template.receiverId,
        receiverLabel = receiver and receiver.label or template.receiverId
    }
end
DK = DK or {}

DK.GenerateOffersForPlayer = function(Player, profile)
    if not Player or not profile then return {} end

    local citizenid = Player.PlayerData.citizenid
    local rawOffers = DKCargo.GetRandomOffers(profile, Config.OfferCount)
    local offers = {}

    for _, template in pairs(rawOffers) do
        offers[#offers + 1] = DKCargo.BuildOfferPayload(template)
    end

    DK.ActiveOffers[citizenid] = {
        createdAt = os.time(),
        offers = offers
    }

    MySQL.insert.await(
        [[
            INSERT INTO dk_spedition_offer_cache (citizenid, offers, created_at)
            VALUES (?, ?, CURRENT_TIMESTAMP)
            ON DUPLICATE KEY UPDATE
                offers = VALUES(offers),
                created_at = CURRENT_TIMESTAMP
        ]],
        {
            citizenid,
            DK.JsonEncode(offers)
        }
    )

    return offers
end

DK.GetCachedOffers = function(citizenid)
    if DK.ActiveOffers[citizenid] then
        return DK.ActiveOffers[citizenid].offers or {}
    end

    local row = MySQL.single.await(
        'SELECT offers FROM dk_spedition_offer_cache WHERE citizenid = ? LIMIT 1',
        { citizenid }
    )

    if not row then
        return {}
    end

    local offers = DK.JsonDecode(row.offers)

    DK.ActiveOffers[citizenid] = {
        createdAt = os.time(),
        offers = offers
    }

    return offers
end

DK.GetOfferById = function(citizenid, offerId)
    local offers = DK.GetCachedOffers(citizenid)

    for _, offer in pairs(offers) do
        if offer.id == offerId then
            return offer
        end
    end

    return nil
end

DK.ClearOfferCache = function(citizenid)
    DK.ActiveOffers[citizenid] = nil

    MySQL.update.await(
        'DELETE FROM dk_spedition_offer_cache WHERE citizenid = ?',
        { citizenid }
    )
end

DK.BuildRunPreview = function(profile, template)
    local cargo = DKCargo.GetItem(template.cargoItem)

    return {
        templateId = template.id,
        label = template.label,
        category = template.category,

        vehicle = template.vehicle,
        trailer = template.trailer,

        cargoLabel = cargo and cargo.label or template.cargoItem,
        cargoAmount = template.cargoAmount,

        requiresSeal = template.requiresSeal == true,
        requiresAdr = template.requiresAdr == true,

        payout = template.payout,
        xp = template.xp,

        canAccept = DKCargo.PlayerCanSeeTemplate(profile, template)
    }
end
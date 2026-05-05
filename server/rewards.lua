DK = DK or {}

DK.CalculateFinalRewards = function(run, deliveredAmount)
    deliveredAmount = tonumber(deliveredAmount) or 0

    local expectedAmount = tonumber(run.cargo_amount) or 1
    local basePayout = tonumber(run.base_payout) or 0
    local baseXp = tonumber(run.base_xp) or 0

    local payout = basePayout
    local xp = baseXp

    local details = {
        basePayout = basePayout,
        baseXp = baseXp,

        deliveredAmount = deliveredAmount,
        expectedAmount = expectedAmount,

        bonuses = {},
        penalties = {}
    }

    local missing = expectedAmount - deliveredAmount

    if missing < 0 then
        missing = 0
    end

    if missing == 0 then
        payout = payout + Config.Rewards.cleanDeliveryBonus
        xp = xp + math.floor(Config.Rewards.cleanDeliveryBonus / 10)

        details.bonuses[#details.bonuses + 1] = {
            label = 'Vollständige Lieferung',
            payout = Config.Rewards.cleanDeliveryBonus,
            xp = math.floor(Config.Rewards.cleanDeliveryBonus / 10)
        }
    else
        local missingRatio = missing / expectedAmount
        local penalty = math.floor(basePayout * missingRatio * (Config.Rewards.missingCargoPenaltyPercent / 100))

        payout = payout - penalty
        xp = math.floor(xp * (1.0 - missingRatio))

        details.penalties[#details.penalties + 1] = {
            label = 'Fehlende Ware',
            payout = penalty,
            xp = 0,
            missing = missing
        }
    end

    if run.seal_number and tonumber(run.seal_broken) ~= 1 then
        payout = payout + Config.Rewards.sealedDeliveryBonus
        xp = xp + math.floor(Config.Rewards.sealedDeliveryBonus / 10)

        details.bonuses[#details.bonuses + 1] = {
            label = 'Plombe intakt',
            payout = Config.Rewards.sealedDeliveryBonus,
            xp = math.floor(Config.Rewards.sealedDeliveryBonus / 10)
        }
    elseif run.seal_number and tonumber(run.seal_broken) == 1 then
        local penalty = math.floor(basePayout * (Config.Rewards.brokenSealPenaltyPercent / 100))

        payout = payout - penalty

        details.penalties[#details.penalties + 1] = {
            label = 'Plombe beschädigt',
            payout = penalty,
            xp = 0
        }
    end

    local minimumPayout = math.floor(basePayout * (Config.Rewards.minimumPartialPayoutPercent / 100))

    if deliveredAmount > 0 and payout < minimumPayout then
        payout = minimumPayout
    end

    if payout < 0 then payout = 0 end
    if xp < 0 then xp = 0 end

    details.finalPayout = payout
    details.finalXp = xp

    return payout, xp, details
end
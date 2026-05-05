DK = DK or {}

local function Clamp(value, min, max)
    value = tonumber(value) or 0

    if value < min then return min end
    if value > max then return max end

    return value
end

local function RandomBossMessage(category)
    local messages = Config.Settlement
        and Config.Settlement.bossMessages
        and Config.Settlement.bossMessages[category]

    if not messages or #messages == 0 then
        return nil
    end

    return messages[math.random(1, #messages)]
end

local function IsAdrRun(run)
    local template = DKCargo.GetTemplate(run.template_id)
    local cargo = DKCargo.GetItem(run.cargo_item)

    if template and template.requiresAdr == true then
        return true
    end

    if cargo and cargo.requiresAdr == true then
        return true
    end

    return false
end

local function AddBossMessage(list, category)
    local message = RandomBossMessage(category)

    if message then
        list[#list + 1] = {
            category = category,
            message = message
        }
    end
end

DK.CalculateRunSettlement = function(run, deliveredCargoAmount)
    if not run then
        return nil
    end

    local basePayout = tonumber(run.base_payout) or 0
    local baseXp = tonumber(run.base_xp) or 0

    local expectedCargo = tonumber(run.cargo_amount) or 0
    local deliveredCargo = tonumber(deliveredCargoAmount) or 0

    deliveredCargo = Clamp(deliveredCargo, 0, expectedCargo)

    local missingCargo = expectedCargo - deliveredCargo
    local missingPercent = 0

    if expectedCargo > 0 then
        missingPercent = math.floor((missingCargo / expectedCargo) * 100)
    end

    local sealBroken = tonumber(run.seal_broken) == 1
    local adrRun = IsAdrRun(run)

    local payout = basePayout
    local xp = baseXp

    local bonuses = {}
    local penalties = {}
    local bossMessages = {}

    if deliveredCargo <= 0 and Config.Settlement and Config.Settlement.noPayoutIfCargoEmpty then
        payout = 0

        penalties[#penalties + 1] = {
            label = 'Keine Ware geliefert',
            type = 'fixed',
            amount = basePayout
        }

        AddBossMessage(bossMessages, 'cargoEmpty')
    else
        if missingCargo > 0 then
            local percentPenalty = tonumber(Config.Rewards.missingCargoPenaltyPercent) or 35
            local amount = math.floor(basePayout * (percentPenalty / 100))

            payout = payout - amount

            penalties[#penalties + 1] = {
                label = ('Fehlende Ware (%s/%s)'):format(missingCargo, expectedCargo),
                type = 'percent',
                percent = percentPenalty,
                amount = amount
            }

            if missingPercent >= 50 then
                AddBossMessage(bossMessages, 'missingCargoLarge')
            else
                AddBossMessage(bossMessages, 'missingCargoSmall')
            end
        else
            local cleanBonus = tonumber(Config.Rewards.cleanDeliveryBonus) or 0

            if cleanBonus > 0 then
                payout = payout + cleanBonus

                bonuses[#bonuses + 1] = {
                    label = 'Saubere Lieferung',
                    amount = cleanBonus
                }
            end

            AddBossMessage(bossMessages, 'clean')
        end

        if sealBroken then
            local percentPenalty = tonumber(Config.Rewards.brokenSealPenaltyPercent) or 20
            local amount = math.floor(basePayout * (percentPenalty / 100))

            payout = payout - amount

            penalties[#penalties + 1] = {
                label = 'Plombe gebrochen',
                type = 'percent',
                percent = percentPenalty,
                amount = amount
            }

            AddBossMessage(bossMessages, 'sealBroken')
        elseif run.seal_number then
            local sealBonus = tonumber(Config.Rewards.sealedDeliveryBonus) or 0

            if sealBonus > 0 then
                payout = payout + sealBonus

                bonuses[#bonuses + 1] = {
                    label = 'Plombe intakt',
                    amount = sealBonus
                }
            end
        end
    end

    if adrRun and (missingCargo > 0 or sealBroken) then
        AddBossMessage(bossMessages, 'adrIssue')
    end

    local minPercent = tonumber(Config.Rewards.minimumPartialPayoutPercent) or 25
    local minimumPayout = math.floor(basePayout * (minPercent / 100))

    if deliveredCargo > 0 and payout > 0 and payout < minimumPayout then
        payout = minimumPayout
    end

    if payout < 0 then
        payout = 0
    end

    return {
        runId = run.id,

        basePayout = basePayout,
        finalPayout = payout,

        baseXp = baseXp,
        finalXp = xp,

        expectedCargo = expectedCargo,
        deliveredCargo = deliveredCargo,
        missingCargo = missingCargo,
        missingPercent = missingPercent,

        sealBroken = sealBroken,
        adrRun = adrRun,

        bonuses = bonuses,
        penalties = penalties,
        bossMessages = bossMessages
    }
end

DK.FormatSettlementSummary = function(settlement)
    if not settlement then
        return 'Keine Abrechnungsdaten verfügbar.'
    end

    local lines = {}

    lines[#lines + 1] = 'Abrechnung DK Spedition'
    lines[#lines + 1] = ('Grundvergütung: $%s'):format(settlement.basePayout)
    lines[#lines + 1] = ('Ware geliefert: %s/%s'):format(settlement.deliveredCargo, settlement.expectedCargo)

    for _, bonus in pairs(settlement.bonuses or {}) do
        lines[#lines + 1] = ('Bonus - %s: +$%s'):format(bonus.label, bonus.amount)
    end

    for _, penalty in pairs(settlement.penalties or {}) do
        lines[#lines + 1] = ('Abzug - %s: -$%s'):format(penalty.label, penalty.amount)
    end

    lines[#lines + 1] = ('Endbetrag: $%s'):format(settlement.finalPayout)
    lines[#lines + 1] = ('XP: %s'):format(settlement.finalXp)

    if settlement.bossMessages and #settlement.bossMessages > 0 then
        lines[#lines + 1] = ''
        lines[#lines + 1] = ('Chef: %s'):format(settlement.bossMessages[1].message)
    end

    return table.concat(lines, '\n')
end

DK.ApplyVehicleDamageToSettlement = function(settlement, damagePercent)
    if not settlement then
        return nil
    end

    damagePercent = tonumber(damagePercent) or 0

    if damagePercent < 0 then damagePercent = 0 end
    if damagePercent > 100 then damagePercent = 100 end

    settlement.vehicleDamagePercent = damagePercent

    if damagePercent <= 10 then
        return settlement
    end

    local basePayout = tonumber(settlement.basePayout) or 0
    local percentPenalty = tonumber(Config.Rewards.vehicleDamagePenaltyPercent) or 15
    local amount = math.floor(basePayout * (percentPenalty / 100))

    if amount > 0 then
        settlement.finalPayout = tonumber(settlement.finalPayout) or 0
        settlement.finalPayout = settlement.finalPayout - amount

        if settlement.finalPayout < 0 then
            settlement.finalPayout = 0
        end

        settlement.penalties = settlement.penalties or {}
        settlement.penalties[#settlement.penalties + 1] = {
            label = ('Fahrzeugschaden (%s%%)'):format(damagePercent),
            type = 'percent',
            percent = percentPenalty,
            amount = amount
        }
    end

    settlement.bossMessages = settlement.bossMessages or {}

    local messages = Config.Settlement
        and Config.Settlement.bossMessages
        and Config.Settlement.bossMessages.vehicleDamaged

    if messages and #messages > 0 then
        settlement.bossMessages[#settlement.bossMessages + 1] = {
            category = 'vehicleDamaged',
            message = messages[math.random(1, #messages)]
        }
    else
        settlement.bossMessages[#settlement.bossMessages + 1] = {
            category = 'vehicleDamaged',
            message = 'Das Fahrzeug ist beschädigt zurückgekommen. Das geht von deiner Abrechnung runter.'
        }
    end

    return settlement
end

DK.GetBossMessageText = function(settlement)
    if not settlement or not settlement.bossMessages or #settlement.bossMessages <= 0 then
        return nil
    end

    local lines = {}

    for _, entry in pairs(settlement.bossMessages) do
        if type(entry) == 'table' and entry.message then
            lines[#lines + 1] = entry.message
        elseif type(entry) == 'string' then
            lines[#lines + 1] = entry
        end
    end

    if #lines <= 0 then
        return nil
    end

    return table.concat(lines, '\n')
end

DK.FormatFinalSettlementSummary = function(settlement)
    if not settlement then
        return 'Keine Abrechnungsdaten verfügbar.'
    end

    local lines = {}

    lines[#lines + 1] = 'Abschlussabrechnung DK Spedition'
    lines[#lines + 1] = ('Grundvergütung: $%s'):format(settlement.basePayout or 0)
    lines[#lines + 1] = ('Ware geliefert: %s/%s'):format(
        settlement.deliveredCargo or 0,
        settlement.expectedCargo or 0
    )

    if settlement.vehicleDamagePercent and settlement.vehicleDamagePercent > 0 then
        lines[#lines + 1] = ('Fahrzeugschaden: %s%%'):format(settlement.vehicleDamagePercent)
    end

    for _, bonus in pairs(settlement.bonuses or {}) do
        lines[#lines + 1] = ('Bonus - %s: +$%s'):format(bonus.label, bonus.amount)
    end

    for _, penalty in pairs(settlement.penalties or {}) do
        lines[#lines + 1] = ('Abzug - %s: -$%s'):format(penalty.label, penalty.amount)
    end

    lines[#lines + 1] = ('Endbetrag: $%s'):format(settlement.finalPayout or 0)
    lines[#lines + 1] = ('XP: %s'):format(settlement.finalXp or 0)

    local bossText = DK.GetBossMessageText(settlement)

    if bossText then
        lines[#lines + 1] = ''
        lines[#lines + 1] = 'Chef:'
        lines[#lines + 1] = bossText
    end

    return table.concat(lines, '\n')
end
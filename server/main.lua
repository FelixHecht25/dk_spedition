local QBCore = exports['qb-core']:GetCoreObject()

DK = DK or {}
DK.ActiveRuns = DK.ActiveRuns or {}
DK.ActiveOffers = DK.ActiveOffers or {}
DK.SpawnedVehicles = DK.SpawnedVehicles or {}
DK.SpawnedTrailers = DK.SpawnedTrailers or {}

local function DebugPrint(message)
    if Config and Config.Debug then
        print(('[dk-spedition] %s'):format(message))
    end
end

DK.Debug = DebugPrint

DK.Notify = function(src, message, notifyType, length)
    Bridge.Core.Notify(src, message, notifyType or 'primary', length or 5000)
end

DK.GetPlayer = function(src)
    return QBCore.Functions.GetPlayer(src)
end

DK.RequireSpeditionJob = function(src)
    local Player = DK.GetPlayer(src)

    if not Player then
        return false, nil
    end

    if not Bridge.Core.HasJob(Player, Config.JobName) then
        DK.Notify(src, 'Du arbeitest nicht bei der Spedition.', 'error')
        return false, Player
    end

    return true, Player
end

DK.JsonEncode = function(data)
    return json.encode(data or {})
end

DK.JsonDecode = function(data)
    if not data or data == '' then
        return {}
    end

    local ok, decoded = pcall(json.decode, data)

    if not ok then
        return {}
    end

    return decoded or {}
end

DK.RandomBetween = function(range)
    if not range then return 0 end

    local min = tonumber(range.min) or 0
    local max = tonumber(range.max) or min

    if max < min then
        max = min
    end

    return math.random(min, max)
end

DK.GetUnix = function()
    return os.time()
end

DK.GetDateTime = function(secondsFromNow)
    local timestamp = os.time() + (secondsFromNow or 0)
    return os.date('%Y-%m-%d %H:%M:%S', timestamp)
end

DK.GetDisplayDateTime = function(secondsFromNow)
    local timestamp = os.time() + (secondsFromNow or 0)
    return os.date('%d.%m.%Y %H:%M', timestamp)
end

DK.GetVector3FromVector4 = function(coords)
    return vector3(coords.x, coords.y, coords.z)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    math.randomseed(os.time())

    DK.Debug('Resource gestartet.')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    DK.Debug('Resource stoppt. Temporäre Entities werden bereinigt.')

    for _, entity in pairs(DK.SpawnedVehicles or {}) do
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    for _, entity in pairs(DK.SpawnedTrailers or {}) do
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
end)

RegisterNetEvent('dk-spedition:server:requestDispatcherData', function()
    local src = source

    print(('[dk-spedition] requestDispatcherData von Source %s'):format(src))

    local ok, err = pcall(function()
        local jobOk, Player = DK.RequireSpeditionJob(src)

        if not jobOk then
            print('[dk-spedition] Spieler hat nicht den Speditionsjob oder Player ist nil.')
            return
        end

        print(('[dk-spedition] Spieler erkannt: %s | Job: %s'):format(
            Player.PlayerData.citizenid,
            Player.PlayerData.job.name
        ))

        local profile = DK.GetOrCreateProfile(Player.PlayerData.citizenid)
        print(('[dk-spedition] Dispatcher Profil | citizenid: %s | level: %s | adr_license: %s'):format(
        tostring(profile.citizenid),
        tostring(profile.level),
        tostring(profile.adr_license)
        ))

        if not profile then
            print('[dk-spedition] Profil konnte nicht geladen/erstellt werden.')
            DK.Notify(src, 'Speditionsprofil konnte nicht geladen werden.', 'error')
            return
        end

        print(('[dk-spedition] Profil geladen: Level %s | XP %s'):format(
            tostring(profile.level),
            tostring(profile.xp)
        ))

        local activeRun = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)
local activeRunPayload = nil
local offers = {}

if activeRun then
    activeRunPayload = DK.BuildActiveRunPayload(activeRun)

    print(('[dk-spedition] Aktiver Auftrag gefunden: %s | Status: %s'):format(
        tostring(activeRun.template_id),
        tostring(activeRun.state)
    ))
else
    offers = DK.GenerateOffersForPlayer(Player, profile)

    if not offers then
        offers = {}
    end

    print(('[dk-spedition] Angebote generiert: %s'):format(#offers))
end

local payload = {
    companyName = Config.CompanyName,
    title = Config.MenuTitle,
    subtitle = Config.MenuSubtitle,
    profile = DK.BuildProfilePayload(profile),
    offers = offers,
    activeRun = activeRunPayload,
    unlocks = DKLevels.GetUnlockList(profile)
}

        TriggerClientEvent('dk-spedition:client:openDispatcher', src, payload)

        print('[dk-spedition] openDispatcher an Client gesendet.')
    end)

    if not ok then
        print('[dk-spedition] FEHLER in requestDispatcherData:')
        print(err)

        DK.Notify(src, 'Fehler beim Öffnen der Auftragstafel. Siehe Serverconsole.', 'error')
    end
end)

RegisterNetEvent('dk-spedition:server:refreshDispatcherOffers', function()
    local src = source

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    local profile = DK.GetOrCreateProfile(Player.PlayerData.citizenid)

    if not profile then
        DK.Notify(src, 'Speditionsprofil konnte nicht geladen werden.', 'error')
        return
    end

    local activeRun = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)
    local activeRunPayload = nil
    local offers = {}

    if activeRun then
        activeRunPayload = DK.BuildActiveRunPayload(activeRun)

        print(('[dk-spedition] refreshDispatcherOffers: Aktiver Auftrag gefunden: %s | Status: %s'):format(
            tostring(activeRun.template_id),
            tostring(activeRun.state)
        ))
    else
        offers = DK.GenerateOffersForPlayer(Player, profile) or {}

        print(('[dk-spedition] refreshDispatcherOffers: Angebote generiert: %s'):format(#offers))
    end

    TriggerClientEvent('dk-spedition:client:updateDispatcherOffers', src, {
        profile = DK.BuildProfilePayload(profile),
        offers = offers,
        activeRun = activeRunPayload,
        unlocks = DKLevels.GetUnlockList(profile)
    })
end)

RegisterNetEvent('dk-spedition:server:acceptOffer', function(offerId)
    local src = source

    print(('[dk-spedition] acceptOffer von Source %s | offerId: %s'):format(
        src,
        tostring(offerId)
    ))

    local success, err = pcall(function()
        local ok, Player = DK.RequireSpeditionJob(src)

        if not ok then
            print('[dk-spedition] acceptOffer abgebrochen: Spieler hat keinen Speditionsjob.')
            return
        end

        if not offerId or offerId == '' then
            print('[dk-spedition] acceptOffer abgebrochen: offerId fehlt.')
            DK.Notify(src, 'Kein Auftrag ausgewählt.', 'error')
            return
        end

        DK.StartRunFromOffer(src, Player, offerId)
    end)

    if not success then
        print('[dk-spedition] FEHLER in acceptOffer:')
        print(err)

        DK.Notify(src, 'Fehler beim Annehmen des Auftrags. Siehe Serverconsole.', 'error')
    end
end)

RegisterNetEvent('dk-spedition:server:cancelActiveRun', function()
    local src = source

    print(('[dk-spedition] cancelActiveRun von Source %s'):format(src))

    local success, err = pcall(function()
        local ok, Player = DK.RequireSpeditionJob(src)

        if not ok then
            print('[dk-spedition] cancelActiveRun abgebrochen: Spieler hat keinen Speditionsjob.')
            return
        end

        local run = DK.GetActiveRunByCitizenId(Player.PlayerData.citizenid)

        if not run then
            print(('[dk-spedition] cancelActiveRun: Kein aktiver Auftrag für %s gefunden.'):format(
                tostring(Player.PlayerData.citizenid)
            ))

            DK.Notify(src, 'Du hast keinen aktiven Auftrag.', 'error')
            return
        end

        print(('[dk-spedition] cancelActiveRun: Auftrag gefunden | runId: %s | template: %s | state: %s | base_xp: %s'):format(
            tostring(run.id),
            tostring(run.template_id),
            tostring(run.state),
            tostring(run.base_xp)
        ))

        local penalty = 0

        if DK.ApplyCancelXpPenalty then
            penalty = DK.ApplyCancelXpPenalty(Player, run)
        else
            print('[dk-spedition] WARNUNG: DK.ApplyCancelXpPenalty fehlt. Keine XP-Strafe angewendet.')
        end

        DK.CancelActiveRun(src, Player, 'player_cancelled')

        TriggerClientEvent('dk-spedition:client:runCancelled', src, {
            reason = 'player_cancelled'
        })

        print(('[dk-spedition] cancelActiveRun: Auftrag abgebrochen | XP-Strafe: %s'):format(
            tostring(penalty)
        ))

        if penalty and penalty > 0 then
            DK.Notify(
                src,
                ('Auftrag abgebrochen. Dir wurden %s XP abgezogen.'):format(penalty),
                'error',
                8000
            )
        else
            DK.Notify(src, 'Auftrag abgebrochen.', 'error', 6000)
        end
    end)

    if not success then
        print('[dk-spedition] FEHLER in cancelActiveRun:')
        print(err)

        DK.Notify(src, 'Fehler beim Abbrechen des Auftrags. Siehe Serverconsole.', 'error')
    end
end)

QBCore.Commands.Add('dkspeditiondebugprofile', 'DK Spedition Profil anzeigen', {}, false, function(source)
    local src = source
    local Player = DK.GetPlayer(src)
    if not Player then return end

    local profile = DK.GetOrCreateProfile(Player.PlayerData.citizenid)

    TriggerClientEvent('chat:addMessage', src, {
        color = { 80, 180, 255 },
        multiline = true,
        args = {
            'DK Spedition',
            ('Level: %s | XP: %s | ADR: %s'):format(
                profile.level,
                profile.xp,
                tonumber(profile.adr_license) == 1 and 'Ja' or 'Nein'
            )
        }
    })
end, 'user')
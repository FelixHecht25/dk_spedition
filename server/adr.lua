DK = DK or {}
DK.ActiveAdrExams = DK.ActiveAdrExams or {}

Config.ADRQuestions = Config.ADRQuestions or {
    {
        question = 'Was bedeutet eine orangefarbene Warntafel an einem Gefahrguttransport?',
        answers = {
            'Das Fahrzeug transportiert gefährliche Güter',
            'Das Fahrzeug ist privat unterwegs',
            'Das Fahrzeug ist leer',
            'Das Fahrzeug darf schneller fahren'
        },
        correct = 1
    },
    {
        question = 'Was ist bei beschädigter Gefahrgutladung zuerst zu tun?',
        answers = {
            'Weiterfahren bis zum Zielort',
            'Abstand halten und Einsatzkräfte informieren',
            'Ladung selbst umladen',
            'Papiere vernichten'
        },
        correct = 2
    },
    {
        question = 'Was muss bei einer Polizeikontrolle für ADR-Transporte vorgelegt werden?',
        answers = {
            'Nur der Führerschein',
            'Frachtbrief und Gefahrgutpapiere',
            'Nur der Fahrzeugbrief',
            'Keine Dokumente'
        },
        correct = 2
    },
    {
        question = 'Was sollte bei Gefahrguttransporten vermieden werden?',
        answers = {
            'Rauchen und offenes Feuer in der Nähe der Ladung',
            'Langsames Fahren',
            'Das Mitführen von Papieren',
            'Das Einhalten der Route'
        },
        correct = 1
    },
    {
        question = 'Was bedeutet die UN-Nummer auf Gefahrgutpapieren?',
        answers = {
            'Eine individuelle Stoffnummer für gefährliche Güter',
            'Die Telefonnummer des Empfängers',
            'Das Kennzeichen des Trailers',
            'Die Nummer des Fahrers'
        },
        correct = 1
    },
    {
        question = 'Was ist bei einem Gefahrgutunfall besonders wichtig?',
        answers = {
            'Den Bereich sichern und Einsatzkräfte informieren',
            'Die Ladung eigenständig abladen',
            'Die Fahrt ohne Meldung fortsetzen',
            'Das Kennzeichen entfernen'
        },
        correct = 1
    },
    {
        question = 'Welche Unterlagen sind bei ADR-Fahrten besonders relevant?',
        answers = {
            'Frachtbrief, Gefahrgut-Genehmigung und ADR-Begleitblatt',
            'Nur ein Parkschein',
            'Nur der Arbeitsvertrag',
            'Keine Unterlagen'
        },
        correct = 1
    },
    {
        question = 'Warum ist die Plombe bei sensibler oder gefährlicher Fracht wichtig?',
        answers = {
            'Sie zeigt, ob der Laderaum unbefugt geöffnet wurde',
            'Sie erhöht die Motorleistung',
            'Sie ersetzt den Frachtbrief',
            'Sie erlaubt schnelleres Fahren'
        },
        correct = 1
    },
    {
        question = 'Was sollte bei ADR-Ladung nicht in direkter Nähe stattfinden?',
        answers = {
            'Rauchen, offenes Feuer oder Funkenbildung',
            'Fahrzeugkontrolle',
            'Dokumentenprüfung',
            'Routenplanung'
        },
        correct = 1
    },
    {
        question = 'Was ist bei einer Leckage von Gefahrgut zu tun?',
        answers = {
            'Abstand halten, Bereich meiden und Feuerwehr/Polizei informieren',
            'Die Flüssigkeit selbst wegwischen',
            'Schnell weiterfahren',
            'Die Papiere wegwerfen'
        },
        correct = 1
    }
}

local function IsAdrCooldownActive(profile)
    if not profile or not profile.adr_exam_failed_at then
        return false, 0
    end

    local failedAt = profile.adr_exam_failed_at

    if type(failedAt) ~= 'string' then
        return false, 0
    end

    local year, month, day, hour, min, sec = failedAt:match('(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)')

    if not year then
        return false, 0
    end

    local failedTimestamp = os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec)
    })

    local cooldownSeconds = (Config.ADR.failCooldownMinutes or 60) * 60
    local availableAt = failedTimestamp + cooldownSeconds
    local now = os.time()

    if availableAt > now then
        return true, availableAt - now
    end

    return false, 0
end

local function ShuffleList(list)
    local shuffled = {}

    for index, value in ipairs(list) do
        shuffled[index] = value
    end

    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    return shuffled
end

local function BuildAdrExam()
    local questionPool = ShuffleList(Config.ADRQuestions)
    local count = math.min(Config.ADR.questionCount, #questionPool)

    local questions = {}

    for i = 1, count do
        questions[#questions + 1] = questionPool[i]
    end

    return questions
end

local function BuildClientExamPayload(questions)
    local payload = {}

    for index, question in ipairs(questions) do
        payload[#payload + 1] = {
            index = index,
            question = question.question,
            answers = question.answers
        }
    end

    return payload
end

RegisterNetEvent('dk-spedition:server:startAdrExam', function()
    local src = source

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    if not Config.ADR.enabled then
        DK.Notify(src, 'ADR-Prüfungen sind aktuell deaktiviert.', 'error')
        return
    end

    local profile = DK.GetOrCreateProfile(Player.PlayerData.citizenid)

    if tonumber(profile.level) < Config.ADR.requiredLevel then
        DK.Notify(src, ('Du benötigst Level %s für die ADR-Prüfung.'):format(Config.ADR.requiredLevel), 'error')
        return
    end

    if tonumber(profile.adr_license) == 1 then
        DK.Notify(src, 'Du besitzt bereits eine ADR-Berechtigung.', 'error')
        return
    end

    local cooldownActive, remaining = IsAdrCooldownActive(profile)

    if cooldownActive then
        DK.Notify(src, ('Du kannst die ADR-Prüfung erst in %s Minuten wiederholen.'):format(math.ceil(remaining / 60)), 'error')
        return
    end

    local canPay, account = Bridge.Money.CanPay(Player, Config.ADR.examFee)

    if not canPay then
        DK.Notify(src, ('Du benötigst $%s für die ADR-Prüfung.'):format(Config.ADR.examFee), 'error')
        return
    end

    Bridge.Money.Remove(
        Player,
        account,
        Config.ADR.examFee,
        'dk-spedition-adr-exam-fee'
    )

    local questions = BuildAdrExam()

    DK.ActiveAdrExams[src] = {
        citizenid = Player.PlayerData.citizenid,
        startedAt = os.time(),
        questions = questions
    }

    TriggerClientEvent('dk-spedition:client:openAdrExam', src, {
        fee = Config.ADR.examFee,
        passPercent = Config.ADR.passPercent,
        questions = BuildClientExamPayload(questions)
    })

    DK.Notify(src, 'ADR-Prüfung gestartet. Die Gebühr wurde bezahlt.', 'primary')
end)

RegisterNetEvent('dk-spedition:server:submitAdrExam', function(answers)
    local src = source

    local ok, Player = DK.RequireSpeditionJob(src)
    if not ok then return end

    local exam = DK.ActiveAdrExams[src]

    if not exam then
        DK.Notify(src, 'Keine aktive ADR-Prüfung gefunden.', 'error')
        return
    end

    answers = answers or {}

    local correct = 0
    local total = #exam.questions

    for index, question in ipairs(exam.questions) do
    local selected = nil

    if answers[index] ~= nil then
        selected = tonumber(answers[index])
    elseif answers[tostring(index)] ~= nil then
        selected = tonumber(answers[tostring(index)])
    end

    print(('[dk-spedition] ADR answer | Frage %s | selected: %s | correct: %s'):format(
        tostring(index),
        tostring(selected),
        tostring(question.correct)
    ))

    if selected == tonumber(question.correct) then
        correct = correct + 1
    end
end

    local percent = 0

    if total > 0 then
        percent = math.floor((correct / total) * 100)
    end

    if percent >= Config.ADR.passPercent then
    local licenseSet = DK.SetAdrLicense(Player.PlayerData.citizenid, true)
    DK.MarkAdrExamAttempt(Player.PlayerData.citizenid)

    local updatedProfile = DK.GetOrCreateProfile(Player.PlayerData.citizenid)

    print(('[dk-spedition] ADR bestanden | citizenid: %s | licenseSet: %s | adr_license DB: %s'):format(
        tostring(Player.PlayerData.citizenid),
        tostring(licenseSet),
        tostring(updatedProfile and updatedProfile.adr_license)
    ))

    DK.Notify(src, ('ADR-Prüfung bestanden: %s%%. Gefahrguttransporte freigeschaltet.'):format(percent), 'success', 8000)

    TriggerClientEvent('dk-spedition:client:adrExamResult', src, {
        passed = true,
        percent = percent,
        correct = correct,
        total = total,
        profile = updatedProfile and DK.BuildProfilePayload(updatedProfile) or nil,
        unlocks = updatedProfile and DKLevels.GetUnlockList(updatedProfile) or nil
    })
    else
        DK.MarkAdrExamFailed(Player.PlayerData.citizenid)

        DK.Notify(src, ('ADR-Prüfung nicht bestanden: %s%%.'):format(percent), 'error', 8000)

        TriggerClientEvent('dk-spedition:client:adrExamResult', src, {
            passed = false,
            percent = percent,
            correct = correct,
            total = total
        })
    end

    DK.ActiveAdrExams[src] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source

    if DK.ActiveAdrExams[src] then
        DK.ActiveAdrExams[src] = nil
    end
end)
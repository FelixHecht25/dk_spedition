local QBCore = exports['qb-core']:GetCoreObject()

DK = DK or {}

DK.TargetsCreated = false

local function PlayerHasSpeditionJob()
    local PlayerData = QBCore.Functions.GetPlayerData()

    return PlayerData
        and PlayerData.job
        and PlayerData.job.name == Config.JobName
end

local function HasTargetResource()
    return Config
        and Config.TargetResource
        and GetResourceState(Config.TargetResource) == 'started'
end

local function AddBoxZone(name, coords, length, width, options, targetOptions)
    if not HasTargetResource() then
        print('[dk-spedition/client] TargetResource nicht gestartet.')
        return
    end

    exports[Config.TargetResource]:AddBoxZone(
        name,
        vector3(coords.x, coords.y, coords.z),
        length,
        width,
        options,
        targetOptions
    )
end

local function AddPedTarget(key, data, options)
    if not HasTargetResource() then
        print('[dk-spedition/client] TargetResource nicht gestartet.')
        return nil
    end

    if not data or not data.enabled then return nil end
    if not data.ped or not data.coords then return nil end

    local ped = DK.CreatePed(
        key,
        data.ped,
        data.coords,
        data.scenario
    )

    if not ped then
        DK.Debug(('Ped konnte nicht erstellt werden: %s'):format(key))
        return nil
    end

    exports[Config.TargetResource]:AddTargetEntity(ped, {
        options = options,
        distance = 2.5
    })

    return ped
end

local function GetEntityRunId(entity)
    if not entity or entity == 0 then return nil end

    local state = Entity(entity).state

    return state and state.dkSpeditionRunId or nil
end

local function EntityHasSeal(entity)
    if not entity or entity == 0 then return false end

    local state = Entity(entity).state

    if not state then return false end

    return state.dkSpeditionSealNumber ~= nil
        and tostring(state.dkSpeditionSealNumber) ~= ''
end

local function EntitySealBroken(entity)
    if not entity or entity == 0 then return false end

    local state = Entity(entity).state

    if not state then return false end

    return state.dkSpeditionSealBroken == true
        or state.dkSpeditionSealBroken == 1
        or tostring(state.dkSpeditionSealBroken) == '1'
end

DK.StartSealBreakProgress = function(runId)
    if not runId then
        DK.Notify('Kein Auftrag am Fahrzeug erkannt.', 'error')
        return
    end

    local ped = PlayerPedId()

    QBCore.Functions.Progressbar(
        'dk_spedition_break_seal',
        'Plombe wird gebrochen...',
        8000,
        false,
        true,
        {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        },
        {
            animDict = 'mini@repair',
            anim = 'fixing_a_ped',
            flags = 49
        },
        {},
        {},
        function()
            ClearPedTasks(ped)
            TriggerServerEvent('dk-spedition:server:breakSeal', runId)
        end,
        function()
            ClearPedTasks(ped)
            DK.Notify('Plombenbruch abgebrochen.', 'error')
        end
    )
end

DK.SetupTargets = function()
    if DK.TargetsCreated then
        DK.Debug('Targets wurden bereits erstellt.')
        return
    end

    if not HasTargetResource() then
        print('[dk-spedition/client] Targets konnten nicht erstellt werden. TargetResource fehlt.')
        return
    end

    DK.TargetsCreated = true

    DK.Debug('Erstelle DK Spedition Targets...')

    if Config.Depot.offerBoard and Config.Depot.offerBoard.enabled then
        AddPedTarget('dk_spedition_offer_board_ped', Config.Depot.offerBoard, {
            {
                icon = 'fas fa-clipboard-list',
                label = 'Auftragstafel öffnen',
                action = function()
                    DK.Notify('Auftragstafel wird geöffnet...', 'primary', 1500)
                    TriggerServerEvent('dk-spedition:server:requestDispatcherData')
                end,
                canInteract = function()
                    return PlayerHasSpeditionJob()
                end
            }
        })
    end

    if Config.Depot.keyDesk and Config.Depot.keyDesk.enabled then
        AddPedTarget('dk_spedition_key_desk_ped', Config.Depot.keyDesk, {
            {
                icon = 'fas fa-key',
                label = Config.Depot.keyDesk.label or 'Schlüsselablage',
                action = function()
                    DK.Notify('Schlüssel werden nach Auftragsannahme automatisch ausgegeben.', 'primary')
                end,
                canInteract = function()
                    return PlayerHasSpeditionJob()
                end
            }
        })
    end

    if Config.Depot.adrNpc and Config.Depot.adrNpc.enabled then
        AddPedTarget('dk_spedition_adr_npc', Config.Depot.adrNpc, {
            {
                icon = 'fas fa-triangle-exclamation',
                label = 'ADR-Prüfung starten',
                action = function()
                    TriggerServerEvent('dk-spedition:server:startAdrExam')
                end,
                canInteract = function()
                    return PlayerHasSpeditionJob()
                end
            }
        })
    end

    DK.Debug('DK Spedition Targets erstellt.')
end

DK.SetupPickupTargets = function(pickup)
    if not pickup then return end
    if not HasTargetResource() then return end

    if pickup.gateNpc then
        local ped = DK.CreatePed(
            'dk_pickup_gate_' .. tostring(pickup.id or pickup.label),
            pickup.gateNpc.ped,
            pickup.gateNpc.coords,
            pickup.gateNpc.scenario
        )

        if ped then
            exports[Config.TargetResource]:AddTargetEntity(ped, {
                options = {
                    {
                        icon = 'fas fa-warehouse',
                        label = 'Abholung anmelden',
                        action = function()
                            TriggerServerEvent('dk-spedition:server:arriveAtPickup')
                        end,
                        canInteract = function()
                            return PlayerHasSpeditionJob()
                        end
                    }
                },
                distance = 2.5
            })
        end
    end

    if pickup.documentOffice then
        local office = pickup.documentOffice
        local zoneCoords = office.coords or office
        local zoneName = 'dk_spedition_document_office_' .. tostring(pickup.id or pickup.label)

        if office.ped and office.coords then
            local ped = DK.CreatePed(
                zoneName .. '_ped',
                office.ped,
                office.coords,
                office.scenario
            )

            if ped then
                exports[Config.TargetResource]:AddTargetEntity(ped, {
                    options = {
                        {
                            icon = 'fas fa-file-signature',
                            label = 'Ladungspapiere abholen',
                            action = function()
                                TriggerServerEvent('dk-spedition:server:collectPickupDocuments')
                            end,
                            canInteract = function()
                                return PlayerHasSpeditionJob()
                            end
                        }
                    },
                    distance = 2.5
                })
            end
        elseif zoneCoords then
            AddBoxZone(
                zoneName,
                zoneCoords,
                1.8,
                1.8,
                {
                    name = zoneName,
                    heading = zoneCoords.w or 0.0,
                    debugPoly = Config.Debug == true,
                    minZ = zoneCoords.z - 1.0,
                    maxZ = zoneCoords.z + 2.0
                },
                {
                    options = {
                        {
                            icon = 'fas fa-file-signature',
                            label = 'Ladungspapiere abholen',
                            action = function()
                                TriggerServerEvent('dk-spedition:server:collectPickupDocuments')
                            end,
                            canInteract = function()
                                return PlayerHasSpeditionJob()
                            end
                        }
                    },
                    distance = 2.5
                }
            )
        end
    end
end

DK.SetupReceiverTarget = function(receiverId, receiver)
    if not receiver then return end
    if not HasTargetResource() then return end

    local ped = DK.CreatePed(
        'dk_receiver_' .. tostring(receiverId),
        receiver.ped,
        receiver.coords,
        receiver.scenario
    )

    if not ped then return end

    exports[Config.TargetResource]:AddTargetEntity(ped, {
        options = {
            {
                icon = 'fas fa-file-invoice',
                label = 'Lieferpapiere übergeben',
                action = function()
                    TriggerServerEvent('dk-spedition:server:handoverToReceiver')
                end,
                canInteract = function()
                    return PlayerHasSpeditionJob()
                end
            }
        },
        distance = 2.5
    })
end

DK.SetupVehicleTargets = function(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    if not HasTargetResource() then return end

    exports[Config.TargetResource]:AddTargetEntity(vehicle, {
        options = {
            {
                icon = 'fas fa-lock-open',
                label = 'Plombe brechen',
                action = function(entity)
                    local runId = GetEntityRunId(entity)

                    if DK.StartSealBreakProgress then
                        DK.StartSealBreakProgress(runId)
                    else
                        TriggerServerEvent('dk-spedition:server:breakSeal', runId)
                    end
                end,
                canInteract = function(entity)
                    return GetEntityRunId(entity) ~= nil
                        and EntityHasSeal(entity)
                        and not EntitySealBroken(entity)
                end
            },
            {
                icon = 'fas fa-boxes-stacked',
                label = 'Laderaum öffnen',
                action = function(entity)
                    local runId = GetEntityRunId(entity)

                    TriggerServerEvent('dk-spedition:server:openCargoInventory', runId)
                end,
                canInteract = function(entity)
                    return GetEntityRunId(entity) ~= nil
                end
            }
        },
        distance = 2.5
    })
end
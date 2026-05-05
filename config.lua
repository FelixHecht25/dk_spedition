Config = {}

Config.Debug = true

Config.JobName = 'spedition'
Config.CompanyName = 'DK Spedition'
Config.MenuTitle = 'Auftragsverwaltung'
Config.MenuSubtitle = 'DK Logistics Center'

Config.OfferCount = 4

Config.DocumentValiditySeconds = 7200

Config.AllowMultipleActiveRuns = false

Config.UseTarget = true
Config.TargetResource = 'qb-target'

Config.InventoryResource = 'qb-inventory'
Config.KeysResource = 'qb-vehiclekeys'

Config.SpawnCleanupOnCancel = true
Config.RemoveDocumentsOnCancel = true
Config.RemoveKeysOnCancel = true

Config.BankPayout = true

Config.Depot = {
    label = 'DK Spedition Depot',

    blip = {
        enabled = true,
        coords = vector3(918.8, -1263.2, 25.5),
        sprite = 477,
        color = 5,
        scale = 0.75,
        label = 'DK Spedition'
    },

    offerBoard = {
        enabled = true,
        label = 'Auftragstafel',
        ped = 's_m_m_autoshop_02',
        coords = vector4(904.9571, -1262.6956, 25.7806, 317.0052),
        scenario = 'WORLD_HUMAN_CLIPBOARD'
    },


    adrNpc = {
        enabled = true,
        label = 'ADR-Ausbilder',
        ped = 's_m_m_gardener_0',
        coords = vector4(909.0217, -1265.6437, 25.5935, 314.6814),
        scenario = 'WORLD_HUMAN_CLIPBOARD'
    },

    vehicleParking = {
        vector4(896.4444, -1249.0822, 25.7173, 34.1490),
        vector4(891.6025, -1252.8467, 25.9017, 38.3138),
        vector4(887.3718, -1250.6945, 26.0370, 299.2012),
        vector4(888.8343, -1254.7380, 26.0186, 290.6721)
    },

    trailerParking = {
        vector4(907.6732, -1230.6738, 25.4962, 182.4516),
        vector4(913.9262, -1230.2832, 25.5221, 182.4620),
        vector4(884.2, -1236.2, 25.4, 90.0)
    },

    returnPoint = {
        enabled = true,
        label = 'Fahrzeugrückgabe',
        coords = vector4(915.1136, -1259.8414, 25.5639, 214.5410),
        radius = 5.0
    }
}

Config.Loading = {
    minSeconds = 10,
    maxSeconds = 15,

    requireDocumentsDuringLoading = true,
    requireVehicleAtDock = true
}

Config.Unloading = {
    minSeconds = 10,
    maxSeconds = 15,

    requirePapersAccepted = true,
    requireVehicleAtUnloadSpot = true,
    partialDeliveryAllowed = true
}

Config.Rewards = {
    cleanDeliveryBonus = 50,
    sealedDeliveryBonus = 75,

    missingCargoPenaltyPercent = 35,
    brokenSealPenaltyPercent = 20,
    vehicleDamagePenaltyPercent = 15,

    minimumPartialPayoutPercent = 25
}

Config.ADR = {
    enabled = true,

    requiredLevel = 7,
    examFee = 2500,

    passPercent = 80,
    questionCount = 10,

    failCooldownMinutes = 60
}

Config.DispatchMenu = {
    showLevel = true,
    showXP = true,
    showNextLevel = true,
    showStats = true,
    showLicenses = true,
    showUnlocks = true,
    showOfferDetails = true,
    offerCount = 3
}

Config.Documents = {
    companyName = 'DK Spedition',
    companySubtitle = 'Transport & Logistik Wien',

    city = 'Wien',
    country = 'Österreich',

    useLogo = false,

    defaultSender = {
        name = 'DK Spedition',
        street = 'Logistikstraße 12',
        zipCity = '1230 Wien',
        country = 'Österreich',
        phone = '+43 1 555 010',
        email = 'dispo@dk-spedition.at'
    },

    defaultLoader = {
        name = 'Zentrallager Wien',
        street = 'Industriezentrum Süd 4',
        zipCity = '1230 Wien',
        country = 'Österreich',
        phone = '+43 1 555 020',
        email = 'verladung@dk-spedition.at'
    }
}

Config.DocumentTypes = {
    cargo_manifest = {
        label = 'Frachtbrief / Ladungsmanifest',
        template = 'cargo_manifest',
        adrOnly = false
    },

    delivery_note = {
        label = 'Lieferschein / Empfangsbestätigung',
        template = 'delivery_note',
        adrOnly = false
    },

    adr_transport_paper = {
        label = 'Beförderungspapier gem. Kapitel 5.4 ADR',
        template = 'adr_transport_paper',
        adrOnly = true
    },

    hazmat_permit = {
        label = 'Gefahrgut-Transportgenehmigung',
        template = 'hazmat_permit',
        adrOnly = true
    }
}

Config.CargoItems = {
    ['beer'] = {
        label = 'Bier',
        category = 'food',
        weight = 500,
        amount = { min = 25, max = 110 },
        requiresAdr = false,
        requiresSeal = false,
        illegalValue = 150
    },

    ['water_bottle'] = {
        label = 'Wasserkisten',
        category = 'food',
        weight = 500,
        amount = { min = 20, max = 80 },
        requiresAdr = false,
        requiresSeal = false,
        illegalValue = 80
    },

    ['sandwich'] = {
        label = 'Lebensmittelpakete',
        category = 'food',
        weight = 500,
        amount = { min = 15, max = 60 },
        requiresAdr = false,
        requiresSeal = false,
        illegalValue = 100
    },

    ['coffee'] = {
        label = 'Kaffeelieferung',
        category = 'retail',
        weight = 500,
        amount = { min = 10, max = 40 },
        requiresAdr = false,
        requiresSeal = false,
        illegalValue = 120
    },

    ['phone'] = {
        label = 'Elektronikware',
        category = 'electronics',
        weight = 1000,
        amount = { min = 5, max = 20 },
        requiresAdr = false,
        requiresSeal = true,
        illegalValue = 900
    },

    ['laptop'] = {
        label = 'Laptop-Lieferung',
        category = 'electronics',
        weight = 2500,
        amount = { min = 3, max = 12 },
        requiresAdr = false,
        requiresSeal = true,
        illegalValue = 1200
    },

    ['metalscrap'] = {
        label = 'Metallschrott',
        category = 'industrial',
        weight = 2500,
        amount = { min = 20, max = 80 },
        requiresAdr = false,
        requiresSeal = false,
        illegalValue = 250
    },

    ['plastic'] = {
        label = 'Kunststoffmaterial',
        category = 'industrial',
        weight = 1500,
        amount = { min = 20, max = 80 },
        requiresAdr = false,
        requiresSeal = false,
        illegalValue = 200
    },

    ['weapon_petrolcan'] = {
    label = 'Dieselkraftstoff',
    category = 'hazmat',
    weight = 5000,


    amount = { min = 6, max = 18 },
    unit = 'Stk.',

    requiresAdr = true,
    requiresSeal = true,
    illegalValue = 1200,

    hazard = {
        unNumber = 'UN 1202',
        substanceName = 'DIESELKRAFTSTOFF',
        adrClass = '3',

        hazardMain = '3',
        hazardSub = '-',

        packingGroup = 'III',
        tunnelCode = '(D/E)',
        transportCategory = '3',
        kemler = '30',

        litersPerInventoryItem = 500,

        packageCountLabel = '1',
        packagingType = 'Tankauflieger',
        packagingDescription = 'Tankauflieger / Tankkammer',

        limitedQuantity = 'nicht anwendbar',
        exemptedQuantity = 'nicht anwendbar',

        emergencyNote = 'Entzündbarer flüssiger Stoff. Zündquellen fernhalten. Bei Austritt Bereich absichern und Einsatzkräfte informieren.'
    }
    },
    
    ['chemical_barrel'] = {
    label = 'Chemikalienfass',
    category = 'hazmat',
    weight = 8000,

    amount = { min = 4, max = 12 },
    unit = 'Fass',

    requiresAdr = true,
    requiresSeal = true,
    illegalValue = 1500,

    hazard = {
        unNumber = 'UN 1993',
        substanceName = 'ENTZÜNDBARER FLÜSSIGER STOFF, N.A.G.',
        adrClass = '3',

        hazardMain = '3',
        hazardSub = '-',

        packingGroup = 'II',
        tunnelCode = '(D/E)',
        transportCategory = '2',
        kemler = '33',

        packageCountLabel = nil,
        packagingType = 'Fass',
        packagingDescription = 'Fässer auf Palette / gesichert',

        limitedQuantity = 'nicht anwendbar',
        exemptedQuantity = 'E2',

        emergencyNote = 'Entzündbarer flüssiger Stoff. Kontakt vermeiden. Bei Austritt Schutzausrüstung tragen und Einsatzkräfte informieren.'
    }
}
}

Config.DeliveryReceivers = {
    ['sandy_industrial_receiver'] = {
        label = 'Warenannahme Sandy Shores',
        ped = 's_m_m_dockwork_01',
        coords = vector4(1732.42, 3323.15, 41.22, 190.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(1725.12, 3316.88, 41.22, 100.0),
            vector4(1721.40, 3310.55, 41.22, 100.0)
        }
    },

    ['elburro_lab_receiver'] = {
        label = 'Labor-Warenannahme',
        ped = 's_m_m_chemsec_01',
        coords = vector4(3494.2351, 3674.3440, 33.8884, 81.1774),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(3504.9331, 3677.4868, 33.8816, 260.2293)
        }
    },

    ['harbor_receiver'] = {
        label = 'Hafen Warenannahme',
        ped = 's_m_m_dockwork_01',
        coords = vector4(1197.2866, -3108.2058, 6.0280, 12.1451),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(1198.3231, -3096.5154, 5.8118, 356.8025),
            vector4(1189.6869, -3096.0598, 5.8048, 90.2482)
        }
    },

    ['billa_davis'] = {
        label = 'Billa Davis',
        ped = 's_m_m_linecook',
        coords = vector4(26.8826, -1350.5897, 29.3311, 183.9520),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(17.2153, -1332.7556, 29.2766, 178.6994)
        }
    },

    ['billa_mirrorpark'] = {
        label = 'Billa Mirror Park',
        ped = 's_m_m_linecook',
        coords = vector4(1142.3804, -979.7267, 46.2555, 268.9034),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(1117.2944, -983.7615, 46.3115, 189.2079)
        }
    },

    ['billa_vinewood'] = {
        label = 'Billa Vinewood',
        ped = 's_m_m_linecook',
        coords = vector4(374.7484, 323.1939, 103.4706, 177.0222),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(368.1547, 340.9008, 103.2113, 350.2682)
        }
    },

    ['tankstelle_capital'] = {
        label = 'Tankstelle Capital Boulevard',
        ped = 's_m_m_autoshop_01',
        coords = vector4(1211.6187, -1389.8441, 35.3769, 184.5974),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(1208.0092, -1402.8522, 35.2240, 315.2302)
        }
    },

    ['tankstelle_clinton'] = {
        label = 'Tankstelle Clinton Avenue',
        ped = 's_m_m_autoshop_01',
        coords = vector4(647.5161, 271.6240, 103.2953, 49.9957),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(616.8448, 268.6353, 103.0894, 4.3968)
        }
    },

    ['tankstelle_chumash'] = {
        label = 'Tankstelle Chumash',
        ped = 's_m_m_autoshop_01',
        coords = vector4(-2074.2388, -325.1034, 13.3160, 78.1080),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(-2083.8071, -322.8178, 12.9806, 351.3085)
        }
    },

['billa_grove'] = {
    label = 'Billa Grove Street',
    ped = 's_m_m_linecook',
    coords = vector4(-58.6087, -1747.6571, 29.3203, 38.0825),
    scenario = 'WORLD_HUMAN_CLIPBOARD',

    unloadSpots = {
        vector4(-39.7275, -1746.1475, 29.2070, 229.7627)
    }
},

['tankstelle_grove'] = {
    label = 'Tankstelle Grove Street',
    ped = 's_m_m_autoshop_01',
    coords = vector4(-58.6087, -1747.6571, 29.3203, 38.0825),
    scenario = 'WORLD_HUMAN_CLIPBOARD',

    unloadSpots = {
        vector4(-74.3463, -1759.0653, 29.5368, 157.5314)
    }
},

['billa_mirrorpark_station'] = {
    label = 'Billa Mirror Park Tankstelle',
    ped = 's_m_m_linecook',
    coords = vector4(1161.5944, -327.2542, 69.2113, 191.7938),
    scenario = 'WORLD_HUMAN_CLIPBOARD',

    unloadSpots = {
        vector4(1170.7106, -316.5166, 69.1786, 197.3550)
    }
},

['tankstelle_mirrorpark'] = {
    label = 'Tankstelle Mirror Park',
    ped = 's_m_m_autoshop_01',
    coords = vector4(1161.5944, -327.2542, 69.2113, 191.7938),
    scenario = 'WORLD_HUMAN_CLIPBOARD',

    unloadSpots = {
        vector4(1179.5648, -326.1183, 69.1743, 280.3331)
    }
},

    ['kleidung_davis'] = {
        label = 'Kleidungsladen Davis',
        ped = 's_f_y_shop_low',
        coords = vector4(83.5353, -1390.1058, 29.4173, 258.3235),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(65.6959, -1399.5377, 29.3602, 272.0031)
        }
    },

    ['kleidung_missionrow'] = {
        label = 'Kleidungsladen Mission Row',
        ped = 's_f_y_shop_low',
        coords = vector4(417.9662, -805.9351, 29.4076, 108.0854),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(414.6708, -806.8795, 29.3387, 270.3686)
        }
    },

    ['autohaus_premium_deluxe'] = {
        label = 'Premium Deluxe Motorsport',
        ped = 's_m_m_autoshop_02',
        coords = vector4(-37.2542, -1110.5303, 26.4562, 119.5491),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(-26.5600, -1083.5342, 26.5967, 138.7955)
        }
    },

    ['baustelle_little_seoul'] = {
        label = 'Baustelle Little Seoul',
        ped = 's_m_y_construct_01',
        coords = vector4(-97.3461, -1014.5562, 27.2752, 176.8262),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(-124.6802, -1040.2673, 27.2735, 338.3156)
        }
    },

    ['burgerladen_vespucci'] = {
        label = 'Burgerladen Vespucci',
        ped = 's_m_y_chef_01',
        coords = vector4(-1181.9218, -884.4020, 13.7756, 315.6342),
        scenario = 'WORLD_HUMAN_CLIPBOARD',

        unloadSpots = {
            vector4(-1176.0286, -890.6002, 13.8284, 30.0235)
        }
    }
}

Config.PickupLocations = {
    ['city_warehouse'] = {
        label = 'Stadtlager Los Santos',

        gateNpc = {
            ped = 's_m_m_warehouse_01',
            coords = vector4(947.25, -1697.70, 30.08, 85.0),
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        },

        loadingDock = vector4(956.18, -1702.55, 30.08, 175.0),

        documentOffice = {
            ped = 's_m_m_warehouse_01',
            coords = vector4(956.4335, -1693.3636, 29.2882, 169.9871),
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        }
    },

    ['harbor_depot'] = {
        label = 'Hafen Depot',

        gateNpc = {
            ped = 's_m_m_dockwork_01',
            coords = vector4(1177.6738, -3257.8997, 6.0288, 91.6046),
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        },

        loadingDock = vector4(1040.8896, -2936.4873, 5.9008, 88.2341),

        documentOffice = {
            ped = 's_m_m_dockwork_01',
            coords = vector4(1000.4526, -2934.6152, 5.9012, 186.8725),
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        }
    },

    ['chemical_storage'] = {
        label = 'Chemielager El Burro Heights',

        gateNpc = {
            ped = 's_m_m_chemsec_01',
            coords = vector4(1374.12, -2078.23, 52.00, 95.0),
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        },

        loadingDock = vector4(1396.9380, -2051.8147, 51.9985, 83.8111),

        documentOffice = {
            ped = 's_m_m_chemsec_01',
            coords = vector4(1369.30, -2074.15, 52.00, 95.0),
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        }
    }
}

Config.JobTemplates = {
    {
        id = 'beer_to_billa_davis',
        label = 'Getränkelieferung: Bier zum Billa Davis',
        description = 'Bierlieferung vom Stadtlager zum Billa Davis.',
        category = 'food',

        requiredLevel = 1,
        requiredLicenses = {},

        pickupId = 'city_warehouse',
        receiverId = 'billa_davis',

        vehicle = 'speedo',
        trailer = nil,

        cargoItem = 'beer',
        cargoAmount = { min = 25, max = 110 },

        requiresSeal = false,
        requiresAdr = false,

        payout = { min = 250, max = 420 },
        xp = { min = 45, max = 75 },

        documents = {
            'delivery_note'
        }
    },

    {
        id = 'beer_to_billa_mirrorpark',
        label = 'Getränkelieferung: Bier zum Billa Mirror Park',
        description = 'Bierlieferung vom Stadtlager zum Billa Mirror Park.',
        category = 'food',

        requiredLevel = 1,
        requiredLicenses = {},

        pickupId = 'city_warehouse',
        receiverId = 'billa_mirrorpark',

        vehicle = 'speedo',
        trailer = nil,

        cargoItem = 'beer',
        cargoAmount = { min = 25, max = 90 },

        requiresSeal = false,
        requiresAdr = false,

        payout = { min = 280, max = 460 },
        xp = { min = 50, max = 85 },

        documents = {
            'delivery_note'
        }
    },

    {
        id = 'beer_to_billa_vinewood',
        label = 'Getränkelieferung: Bier zum Billa Vinewood',
        description = 'Bierlieferung vom Stadtlager zum Billa Vinewood.',
        category = 'food',

        requiredLevel = 2,
        requiredLicenses = {},

        pickupId = 'city_warehouse',
        receiverId = 'billa_vinewood',

        vehicle = 'speedo',
        trailer = nil,

        cargoItem = 'beer',
        cargoAmount = { min = 25, max = 80 },

        requiresSeal = false,
        requiresAdr = false,

        payout = { min = 320, max = 520 },
        xp = { min = 55, max = 90 },

        documents = {
            'delivery_note'
        }
    },

    {
        id = 'food_to_burgerladen_vespucci',
        label = 'Lebensmittellieferung: Burgerladen Vespucci',
        description = 'Lebensmittelpakete zum Burgerladen Vespucci liefern.',
        category = 'food',

        requiredLevel = 2,
        requiredLicenses = {},

        pickupId = 'city_warehouse',
        receiverId = 'burgerladen_vespucci',

        vehicle = 'speedo',
        trailer = nil,

        cargoItem = 'sandwich',
        cargoAmount = { min = 15, max = 55 },

        requiresSeal = false,
        requiresAdr = false,

        payout = { min = 350, max = 580 },
        xp = { min = 60, max = 95 },

        documents = {
            'delivery_note'
        }
    },

    {
        id = 'water_to_tankstelle_grove',
        label = 'Getränkelieferung: Wasser zur Tankstelle Groovestreet',
        description = 'Wasserkisten zur Billa/Tankstelle Grove Street liefern.',
        category = 'food',

        requiredLevel = 2,
        requiredLicenses = {},

        pickupId = 'city_warehouse',
        receiverId = 'billa_grove',
        vehicle = 'speedo',
        trailer = nil,

        cargoItem = 'water_bottle',
        cargoAmount = { min = 20, max = 75 },

        requiresSeal = false,
        requiresAdr = false,

        payout = { min = 380, max = 620 },
        xp = { min = 65, max = 100 },

        documents = {
            'delivery_note'
        }
    },

    {
        id = 'coffee_to_tankstelle_mirrorpark',
        label = 'Einzelhandel: Kaffee zur Billa/Tankstelle Mirror Park',
        description = 'Kaffee und Handelsware zur Mirror Park Filiale liefern.',
        category = 'retail',

        requiredLevel = 3,
        requiredLicenses = {},

        pickupId = 'city_warehouse',
        receiverId = 'billa_mirrorpark_station',

        vehicle = 'mule3',
        trailer = nil,

        cargoItem = 'coffee',
        cargoAmount = { min = 10, max = 40 },

        requiresSeal = false,
        requiresAdr = false,

        payout = { min = 450, max = 700 },
        xp = { min = 85, max = 130 },

        documents = {
            'cargo_manifest',
            'delivery_note'
        }
    },

    {
        id = 'electronics_to_digital_or_clothing',
        label = 'Wertlieferung: Elektronik zum Kleidungsladen Davis',
        description = 'Elektronikware mit verplombtem Laderaum zustellen.',
        category = 'electronics',

        requiredLevel = 5,
        requiredLicenses = {},

        pickupId = 'city_warehouse',
        receiverId = 'kleidung_davis',

        vehicle = 'mule3',
        trailer = nil,

        cargoItem = 'phone',
        cargoAmount = { min = 5, max = 20 },

        requiresSeal = true,
        requiresAdr = false,

        payout = { min = 650, max = 950 },
        xp = { min = 150, max = 220 },

        documents = {
            'cargo_manifest',
            'delivery_note'
        }
    },

    {
        id = 'laptops_to_kleidung_missionrow',
        label = 'Wertlieferung: Laptops zur Filiale Mission Row',
        description = 'Verplombte Lieferung mit hochwertigen Laptops.',
        category = 'electronics',

        requiredLevel = 5,
        requiredLicenses = {},

        pickupId = 'city_warehouse',
        receiverId = 'kleidung_missionrow',

        vehicle = 'mule3',
        trailer = nil,

        cargoItem = 'laptop',
        cargoAmount = { min = 3, max = 12 },

        requiresSeal = true,
        requiresAdr = false,

        payout = { min = 700, max = 1000 },
        xp = { min = 170, max = 250 },

        documents = {
            'cargo_manifest',
            'delivery_note'
        }
    },

    {
        id = 'scrap_to_autohaus',
        label = 'Ersatzteillieferung: Premium Deluxe Motorsport',
        description = 'Material und Ersatzteile zum Autohaus liefern.',
        category = 'automotive',

        requiredLevel = 4,
        requiredLicenses = {},

        pickupId = 'harbor_depot',
        receiverId = 'autohaus_premium_deluxe',

        vehicle = 'mule3',
        trailer = nil,

        cargoItem = 'metalscrap',
        cargoAmount = { min = 20, max = 60 },

        requiresSeal = false,
        requiresAdr = false,

        payout = { min = 520, max = 780 },
        xp = { min = 100, max = 165 },

        documents = {
            'cargo_manifest',
            'delivery_note'
        }
    },

    {
        id = 'building_material_to_baustelle',
        label = 'Baustofflieferung: Baustelle Little Seoul',
        description = 'Baumaterial zur Baustelle Little Seoul liefern.',
        category = 'construction',

        requiredLevel = 6,
        requiredLicenses = {},

        pickupId = 'harbor_depot',
        receiverId = 'baustelle_little_seoul',

        vehicle = 'mule3',
        trailer = nil,

        cargoItem = 'metalscrap',
        cargoAmount = { min = 30, max = 90 },

        requiresSeal = false,
        requiresAdr = false,

        payout = { min = 650, max = 900 },
        xp = { min = 140, max = 210 },

        documents = {
            'cargo_manifest',
            'delivery_note'
        }
    },

    {
        id = 'plastic_to_sandy_industrial',
        label = 'Industrieauftrag: Kunststoff nach Sandy Shores',
        description = 'Kunststoffmaterial zum Industrieempfänger Sandy Shores liefern.',
        category = 'industrial',

        requiredLevel = 4,
        requiredLicenses = {},

        pickupId = 'harbor_depot',
        receiverId = 'sandy_industrial_receiver',

        vehicle = 'mule3',
        trailer = nil,

        cargoItem = 'plastic',
        cargoAmount = { min = 20, max = 80 },

        requiresSeal = false,
        requiresAdr = false,

        payout = { min = 550, max = 820 },
        xp = { min = 115, max = 170 },

        documents = {
            'cargo_manifest',
            'delivery_note'
        }
    },

    {
    id = 'adr_diesel_to_tankstelle_capital',
    label = 'ADR-Lieferung: Diesel zur Tankstelle Capital',
    description = 'Dieselkraftstoff im Tankauflieger zur Tankstelle Capital Boulevard liefern.',
    category = 'hazmat',

    requiredLevel = 7,
    requiredLicenses = {
        'adr'
    },

    pickupId = 'chemical_storage',
    receiverId = 'tankstelle_capital',

    vehicle = 'phantom',
    trailer = 'tanker',

    cargoItem = 'weapon_petrolcan',
    cargoAmount = { min = 6, max = 18 },

    requiresSeal = true,
    requiresAdr = true,

    payout = { min = 800, max = 1050 },
    xp = { min = 260, max = 390 },

    documents = {
        'cargo_manifest',
        'delivery_note',
        'adr_transport_paper',
        'hazmat_permit'
    }
},

    {
    id = 'adr_diesel_to_tankstelle_clinton',
    label = 'ADR-Lieferung: Diesel zur Tankstelle Clinton',
    description = 'Dieselkraftstoff im Tankauflieger zur Tankstelle Clinton Avenue liefern.',
    category = 'hazmat',

    requiredLevel = 7,
    requiredLicenses = {
        'adr'
    },

    pickupId = 'chemical_storage',
    receiverId = 'tankstelle_clinton',

    vehicle = 'phantom',
    trailer = 'tanker',

    cargoItem = 'weapon_petrolcan',
    cargoAmount = { min = 6, max = 18 },

    requiresSeal = true,
    requiresAdr = true,

    payout = { min = 780, max = 1030 },
    xp = { min = 250, max = 380 },

    documents = {
        'cargo_manifest',
        'delivery_note',
        'adr_transport_paper',
        'hazmat_permit'
    }
},

    {
    id = 'adr_diesel_to_tankstelle_chumash',
    label = 'ADR-Lieferung: Diesel zur Tankstelle Chumash',
    description = 'Dieselkraftstoff im Tankauflieger zur Tankstelle Chumash liefern.',
    category = 'hazmat',

    requiredLevel = 7,
    requiredLicenses = {
        'adr'
    },

    pickupId = 'chemical_storage',
    receiverId = 'tankstelle_chumash',

    vehicle = 'phantom',
    trailer = 'tanker',

    cargoItem = 'weapon_petrolcan',
    cargoAmount = { min = 6, max = 18 },

    requiresSeal = true,
    requiresAdr = true,

    payout = { min = 850, max = 1100 },
    xp = { min = 300, max = 440 },

    documents = {
        'cargo_manifest',
        'delivery_note',
        'adr_transport_paper',
        'hazmat_permit'
    }
},

    {
    id = 'adr_chemicals_to_labor',
    label = 'ADR-Transport: Chemikalien zum Labor',
    description = 'Chemikalienfässer zum Labor liefern. ADR-Papiere und verplombter Laderaum erforderlich.',
    category = 'hazmat',

    requiredLevel = 7,
    requiredLicenses = {
        'adr'
    },

    pickupId = 'chemical_storage',
    receiverId = 'elburro_lab_receiver',

    vehicle = 'boxville',
    trailer = nil,

    cargoItem = 'chemical_barrel',
    cargoAmount = { min = 4, max = 12 },

    requiresSeal = true,
    requiresAdr = true,

    payout = { min = 820, max = 1080 },
    xp = { min = 280, max = 420 },

    documents = {
        'cargo_manifest',
        'delivery_note',
        'adr_transport_paper',
        'hazmat_permit'
    }
}
}

Config.Settlement = {
    enabled = true,

    allowPartialPayout = true,

    noPayoutIfCargoEmpty = true,

    bossMessages = {
        clean = {
            'Saubere Arbeit. Kunde zufrieden, Papiere passen, Fahrzeug zurück. Genau so soll das laufen.',
            'Guter Auftrag. Keine Beanstandung vom Empfänger.'
        },

        missingCargoSmall = {
            'Beim Empfänger fehlt Ware. Das ist kein Weltuntergang, aber sauber ist das nicht.',
            'Da fehlt etwas Ladung. Beim nächsten Mal kontrollierst du besser, was hinten drin ist.'
        },

        missingCargoLarge = {
            'Das ist deutlich zu wenig Ware. So kann ich dich nicht auf gute Touren setzen.',
            'Der Kunde meldet erhebliche Fehlmenge. Das gibt noch Konsequenzen.'
        },

        cargoEmpty = {
            'Du kommst ohne Ware zurück und erwartest eine Auszahlung? Sicher nicht.',
            'Komplette Ladung weg. Das ist ein Totalschaden für den Auftrag.'
        },

        sealBroken = {
            'Die Plombe ist gebrochen. Damit ist die Lieferung nur noch unter Vorbehalt akzeptiert.',
            'Gebrochene Plombe bedeutet Ärger mit Kunde und Kontrolle. Das geht auf deine Abrechnung.'
        },

        vehicleDamaged = {
            'Das Fahrzeug sieht aus, als wärst du durch halb Wien gerammt. Reparatur geht von der Abrechnung runter.',
            'Fahrzeugschaden wurde gemeldet. Das reduziert deine Auszahlung.'
        },

        adrIssue = {
            'Bei ADR-Fahrten hört der Spaß auf. Fehlmenge oder Plombenbruch wird intern dokumentiert.',
            'Gefahrgut ist kein Spaß! Solche Fehler dürfen nicht passieren!'
        }
    }
}
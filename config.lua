Config = {}

-- Framework Detection (auto, qbx, qbcore, esx)
Config.Framework = 'auto' -- Set to 'auto' for automatic detection, 'qbx', 'qbcore' or 'esx' for manual

-- Inventory System (auto, qb-inventory, ps-inventory, qs-inventory, ox_inventory, esx_default)
Config.Inventory = 'auto' -- Set to 'auto' for automatic detection or specify manually

-- General Settings
Config.Debug = false
Config.Locale = 'en'

-- Replacement License Cost
Config.ReplacementCost = 250 -- Cost to replace a lost license

-- License Item Names (configurable for different frameworks/inventories)
Config.LicenseItems = {
    regular = 'driver_license', -- Use whatever the license is in your items file
    cdl = 'cdl_license',
    motorcycle = 'motorcycle_license'
}

-- Inventory System Settings
Config.InventorySettings = {
    -- For ox_inventory
    ox_inventory = {
        useMetadata = true,
        metadataKeys = {
            firstname = 'firstname',
            lastname = 'lastname',
            birthdate = 'birthdate',
            type = 'type',
            issued = 'issued',
            expires = 'expires'
        }
    },
    -- For ESX default inventory
    esx_default = {
        useDatabase = true,
        tableName = 'user_licenses_items' -- Custom table for ESX license items
    },
    -- For QBCore based inventories
    qbcore_based = {
        useMetadata = true,
        metadataKeys = {
            firstname = 'firstname',
            lastname = 'lastname',
            birthdate = 'birthdate',
            type = 'type',
            issued = 'issued',
            expires = 'expires'
        }
    }
}

-- License Types Configuration
Config.Licenses = {
    regular = {
        enabled = true,
        name = 'Regular Driver\'s License',
        price = 1500,
        drivingTest = true,  -- Enable/disable driving portion
        writtenTest = true,  -- Enable/disable written portion
        vehicle = 'blista',
        spawnLocation = vector4(-1037.58, -2738.84, 20.17, 240.0),
        testRoute = {
            vector3(-1037.58, -2738.84, 20.17),
            vector3(-1100.0, -2800.0, 20.0),
            vector3(-1200.0, -2850.0, 20.0),
            vector3(-1037.58, -2738.84, 20.17)
        },
        requiredScore = 80, -- Minimum score to pass
        timeLimit = 300 -- 5 minutes in seconds
    },
    cdl = {
        enabled = true,
        name = 'Commercial Driver\'s License',
        price = 5000,
        drivingTest = true,
        writtenTest = true,
        vehicle = 'phantom',
        spawnLocation = vector4(-1050.0, -2750.0, 20.17, 240.0),
        testRoute = {
            vector3(-1050.0, -2750.0, 20.17),
            vector3(-1150.0, -2820.0, 20.0),
            vector3(-1250.0, -2900.0, 20.0),
            vector3(-1050.0, -2750.0, 20.17)
        },
        requiredScore = 85,
        timeLimit = 600 -- 10 minutes
    },
    motorcycle = {
        enabled = true,
        name = 'Motorcycle License',
        price = 800,
        drivingTest = true,
        writtenTest = true,
        vehicle = 'sanchez',
        spawnLocation = vector4(-1025.0, -2725.0, 20.17, 240.0),
        testRoute = {
            vector3(-1025.0, -2725.0, 20.17),
            vector3(-1080.0, -2780.0, 20.0),
            vector3(-1180.0, -2830.0, 20.0),
            vector3(-1025.0, -2725.0, 20.17)
        },
        requiredScore = 75,
        timeLimit = 240 -- 4 minutes
    }
}

-- Driving School Location
Config.DrivingSchool = {
    coords = vector3(-1040.0, -2730.0, 20.17),
    blip = {
        enabled = true,
        sprite = 225,
        color = 3,
        scale = 0.8,
        name = 'Driving School'
    },
    ped = {
        enabled = true,
        model = 'a_m_m_business_01',
        coords = vector4(-1040.0, -2730.0, 20.17, 240.0)
    }
}

-- Written Test Questions
Config.WrittenQuestions = {
    regular = {
        {
            question = "What is the speed limit in residential areas?",
            answers = {"25 mph", "35 mph", "45 mph", "55 mph"},
            correct = 1
        },
        {
            question = "When should you use your turn signal?",
            answers = {"Only when turning left", "Only when turning right", "When changing lanes or turning", "Never"},
            correct = 3
        },
        {
            question = "What should you do at a red light?",
            answers = {"Speed up", "Come to a complete stop", "Slow down", "Honk your horn"},
            correct = 2
        },
        {
            question = "How far should you stay behind another vehicle?",
            answers = {"1 second", "2 seconds", "3 seconds", "5 seconds"},
            correct = 3
        },
        {
            question = "What does a yellow traffic light mean?",
            answers = {"Speed up", "Stop if safe to do so", "Go faster", "Honk"},
            correct = 2
        }
    },
    cdl = {
        {
            question = "What is the maximum speed for commercial vehicles on highways?",
            answers = {"55 mph", "65 mph", "70 mph", "75 mph"},
            correct = 1
        },
        {
            question = "How often should you check your mirrors while driving a commercial vehicle?",
            answers = {"Every 30 seconds", "Every 5-8 seconds", "Every minute", "Only when changing lanes"},
            correct = 2
        },
        {
            question = "What is the minimum following distance for commercial vehicles?",
            answers = {"3 seconds", "4 seconds", "6 seconds", "8 seconds"},
            correct = 3
        }
    },
    motorcycle = {
        {
            question = "What protective gear is required when riding a motorcycle?",
            answers = {"Helmet only", "Helmet and gloves", "Helmet and jacket", "Helmet, gloves, and protective clothing"},
            correct = 4
        },
        {
            question = "When should you use both brakes on a motorcycle?",
            answers = {"Never", "Only in emergencies", "Most of the time", "Only when going fast"},
            correct = 3
        }
    }
}

-- Driving Test Scoring
Config.DrivingScoring = {
    speedingPenalty = 5,      -- Points deducted for speeding
    crashPenalty = 15,        -- Points deducted for crashes
    trafficViolation = 10,    -- Points deducted for traffic violations
    offRoadPenalty = 8,       -- Points deducted for going off road
    maxSpeed = 50,            -- Maximum allowed speed during test
    startingScore = 100       -- Starting score for driving test
}
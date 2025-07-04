# SD-DrivingSchool

A comprehensive driving school resource for FiveM servers supporting QBX (QBox), QBCore, and ESX frameworks. This resource allows players to obtain various types of driving licenses through written and practical driving tests.

## 🌟 Features

- 🚗 **Multiple License Types**: Regular, CDL, and Motorcycle licenses
- 📝 **Written Tests**: Customizable questions for each license type
- 🛣️ **Driving Tests**: Practical driving tests with checkpoints and scoring
- 💰 **Replacement Licenses**: Players can purchase replacement licenses
- 🎯 **Interactive NPC**: Driving instructor with qb-target integration
- 📍 **Map Blip**: Configurable blip for the driving school location
- 🔧 **Framework Support**: Compatible with QBX (QBox), QBCore, and ESX
- 📦 **Inventory Integration**: Supports multiple inventory systems (ox_inventory, qs-inventory, ps-inventory, qb-inventory, esx_default)
- 🎯 **Target Integration**: Compatible with both ox_target and qb-target
- 🔗 **Bridge System**: Modular framework bridges for easy maintenance and updates
- 👮 **Admin Commands**: License management commands for administrators

## 📋 Requirements

- **QBX (QBox)**, **QBCore**, or **ESX** framework
- **qb-target** or **ox_target** (for NPC interaction)
- **qb-menu** or **esx_menu_default** (for menus)
- **MySQL** (for ESX license storage)
- One of the supported inventory systems:
  - **ox_inventory** (recommended)
  - **qs-inventory**
  - **ps-inventory** 
  - **qb-inventory**
  - **esx_default** (ESX only)
- One of the supported target systems:
  - **ox_target** (recommended)
  - **qb-target**

## 📥 Installation

### Step 1: Download and Extract
1. Download the `sd-drivingschool` resource
2. Extract the folder to your server's `resources` directory
3. Ensure the folder is named `sd-drivingschool`

### Step 2: Add to Server Configuration
1. Open your `server.cfg` file
2. Add the following line:
```cfg
ensure sd-drivingschool
```

### Step 3: Configure the Resource
1. Open `config.lua` in the resource folder
2. Set your framework (or leave as 'auto' for automatic detection):
```lua
Config.Framework = 'auto' -- 'auto', 'qbx', 'qbcore', or 'esx'
```
3. Configure your inventory system (or leave as 'auto' for automatic detection):
```lua
Config.Inventory = 'auto' -- 'auto', 'ox_inventory', 'qs-inventory', 'ps-inventory', 'qb-inventory', or 'esx_default'
```
4. Configure your target system (or leave as 'auto' for automatic detection):
```lua
Config.Target = 'auto' -- 'auto', 'ox_target', or 'qb-target'
```

> **Note**: The resource automatically detects your framework, inventory, and target systems. Manual configuration is only needed if auto-detection fails.

### Step 4: Add License Items to Your Inventory
Add these items to your inventory system's items file:

**For QBX/QBCore (`qbx_core/shared/items.lua` or `qb-core/shared/items.lua`):**
```lua
-- Add these items to your items table
driver_license = {
    name = 'driver_license',
    label = 'Driver License',
    weight = 0,
    type = 'item',
    image = 'driver_license.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Official Driver License'
},
cdl_license = {
    name = 'cdl_license',
    label = 'CDL License',
    weight = 0,
    type = 'item',
    image = 'cdl_license.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Commercial Driver License'
},
motorcycle_license = {
    name = 'motorcycle_license',
    label = 'Motorcycle License',
    weight = 0,
    type = 'item',
    image = 'motorcycle_license.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Official Motorcycle License'
}
```

**For ESX (`es_extended/config.lua` or your inventory resource):**
> **Note**: If using ox_inventory with ESX, add items to `ox_inventory/data/items.lua` instead.
```lua
-- Add to your items configuration
['driver_license'] = {
    label = 'Driver License',
    weight = 0,
    stack = false,
    close = true,
    description = 'Official Driver License'
},
['cdl_license'] = {
    label = 'CDL License',
    weight = 0,
    stack = false,
    close = true,
    description = 'Commercial Driver License'
},
['motorcycle_license'] = {
    label = 'Motorcycle License',
    weight = 0,
    stack = false,
    close = true,
    description = 'Official Motorcycle License'
}
```

### Step 5: Restart Your Server
1. Save all configuration files
2. Restart your FiveM server
3. Check console for any errors

## ⚙️ Configuration

### Basic Configuration
Open `config.lua` and modify these settings:

```lua
Config = {}

-- Framework Settings
Config.Framework = 'auto' -- 'auto', 'qbx', 'qbcore', or 'esx'
Config.Inventory = 'auto' -- 'auto', 'ox_inventory', 'qs-inventory', 'ps-inventory', 'qb-inventory', or 'esx_default'
Config.Target = 'auto' -- 'auto', 'ox_target', or 'qb-target'
Config.ReplacementCost = 500 -- Cost for replacement licenses
Config.Debug = false -- Enable debug prints

-- Driving School Location
Config.DrivingSchool = {
    coords = vector3(-1037.58, -2738.84, 20.17),
    blip = {
        enabled = true,
        sprite = 225,
        color = 3,
        scale = 0.8,
        name = "Driving School"
    },
    ped = {
        enabled = true,
        model = 'a_m_y_business_01',
        coords = vector4(-1037.58, -2738.84, 20.17, 240.0)
    }
}
```

### Scoring System Configuration
```lua
Config.DrivingScoring = {
    startingScore = 100,
    speedingPenalty = 5,
    crashPenalty = 15,
    maxSpeed = 35 -- MPH
}
```

## 🆕 Adding New Licenses

Follow these steps to add a new license type:

### Step 1: Add License Configuration
Open `config.lua` and add your new license to the `Config.Licenses` table:

```lua
Config.Licenses = {
    -- Existing licenses (regular, cdl, motorcycle)...
    
    -- Add your new license here
    pilot = {
        enabled = true,
        name = 'Pilot License',
        price = 10000,
        drivingTest = true,  -- Enable practical test
        writtenTest = true,  -- Enable written test
        vehicle = 'luxor',   -- Vehicle for driving test
        spawnLocation = vector4(-1266.0, -3013.0, 13.9, 329.0), -- Airport location
        testRoute = {
            vector3(-1266.0, -3013.0, 13.9),
            vector3(-1400.0, -3100.0, 13.9),
            vector3(-1500.0, -3000.0, 13.9),
            vector3(-1266.0, -3013.0, 13.9)
        },
        requiredScore = 85,  -- Higher requirement for pilot
        timeLimit = 600      -- 10 minutes
    }
}
```

### Step 2: Add License Item Mapping
In the same `config.lua` file, add your license item:

```lua
Config.LicenseItems = {
    regular = 'driver_license',
    cdl = 'cdl_license',
    motorcycle = 'motorcycle_license',
    pilot = 'pilot_license' -- Add your new license item
}
```

### Step 3: Create Written Test Questions
Add questions for your new license:

```lua
Config.WrittenQuestions = {
    -- Existing questions...
    
    pilot = {
        {
            question = "What is the minimum altitude for VFR flight over congested areas?",
            answers = {
                "500 feet",
                "1000 feet", 
                "1500 feet",
                "2000 feet"
            },
            correct = 2 -- Index of correct answer (1000 feet)
        },
        {
            question = "What does VFR stand for?",
            answers = {
                "Visual Flight Rules",
                "Very Fast Rules", 
                "Vertical Flight Rules",
                "Variable Flight Rules"
            },
            correct = 1 -- Visual Flight Rules
        },
        {
            question = "What is the standard traffic pattern altitude?",
            answers = {
                "500 feet AGL",
                "1000 feet AGL",
                "1500 feet AGL", 
                "2000 feet AGL"
            },
            correct = 2 -- 1000 feet AGL
        }
        -- Add more questions as needed (minimum 5-10 recommended)
    }
}
```

### Step 4: Update License Mapping (QBX/QBCore Only)
If using QBX or QBCore, update the license mapping in the bridge files:

**In `shared/qb.lua` and `shared/qbx.lua` - Find the license mapping and update:**
```lua
local licenseMap = {
    regular = 'driver',
    cdl = 'cdl', 
    motorcycle = 'motorcycle',
    pilot = 'pilot' -- Add your mapping
}
```

> **Note**: The bridge system automatically handles framework differences. You only need to update the mapping in the relevant bridge file(s).

### Step 5: Add Item to Inventory System
Add the new license item to your inventory:

**For QBX/QBCore (`qbx_core/shared/items.lua` or `qb-core/shared/items.lua`):**
```lua
pilot_license = {
    name = 'pilot_license',
    label = 'Pilot License',
    weight = 0,
    type = 'item',
    image = 'pilot_license.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Official Pilot License - Allows operation of aircraft'
}
```

**For ESX:**
```lua
['pilot_license'] = {
    label = 'Pilot License',
    weight = 0,
    stack = false,
    close = true,
    description = 'Official Pilot License - Allows operation of aircraft'
}
```

### Step 6: Test Your New License
1. Restart your server
2. Go to the driving school location
3. Check if your new license appears in the menu
4. Test both written and driving portions

## 🎮 How to Use

### For Players
1. **Visit the Driving School**: Go to the marked location on the map
2. **Interact with NPC**: Use your interaction key (default: E) on the driving instructor
3. **Choose License Type**: Select which license you want to obtain
4. **Take Tests**: Complete written and/or driving tests as required
5. **Receive License**: Upon passing, receive your license item

### Test Types
- **Written Test**: Answer multiple choice questions
- **Driving Test**: Follow checkpoints while maintaining good driving
- **Replacement**: Purchase a new copy if you lose your license

## 👨‍💼 Admin Commands

### QBX/QBCore Commands
```
/givelicense [player_id] [license_type]
```
- **Example**: `/givelicense 1 regular`
- **Description**: Give a player a specific license

```
/removelicense [player_id] [license_type] 
```
- **Example**: `/removelicense 1 motorcycle`
- **Description**: Remove a player's license

```
/givereplacement [player_id] [license_type]
```
- **Example**: `/givereplacement 1 cdl`
- **Description**: Give a replacement license item

### License Types
- `regular` - Standard driver's license
- `cdl` - Commercial driver's license  
- `motorcycle` - Motorcycle license
- `pilot` - Pilot license (if added)

## 🔧 Advanced Configuration

### Framework Bridge System
The resource uses a modular bridge system with separate files for each framework:
- `shared/qbx.lua` - QBX (QBox) bridge
- `shared/qb.lua` - QBCore bridge  
- `shared/esx.lua` - ESX bridge

This design allows for easy maintenance and framework-specific optimizations.

### Custom Inventory Integration
To integrate with a custom inventory system, modify the bridge files or add support to `shared/framework.lua`:

```lua
Config.Inventory = 'custom_inventory'

-- Add your custom inventory functions
Config.InventorySettings = {
    custom_inventory = {
        AddItem = function(source, Player, item, amount, metadata)
            -- Your custom add item function
            exports['custom_inventory']:AddItem(source, item, amount, metadata)
        end,
        RemoveItem = function(source, Player, item, amount)
            -- Your custom remove item function  
            exports['custom_inventory']:RemoveItem(source, item, amount)
        end
    }
}
```

### Custom Test Routes
Create custom driving test routes by modifying the `testRoute` in license configuration:

```lua
testRoute = {
    vector3(-1037.58, -2738.84, 20.17), -- Start point
    vector3(-1100.0, -2800.0, 20.0),    -- Checkpoint 1
    vector3(-1200.0, -2850.0, 20.0),    -- Checkpoint 2  
    vector3(-1150.0, -2900.0, 20.0),    -- Checkpoint 3
    vector3(-1037.58, -2738.84, 20.17)  -- End point (back to start)
}
```

## 🐛 Troubleshooting

### Common Issues

**Framework not detected:**
- Ensure your framework resource is started before sd-drivingschool
- Check console for framework detection messages
- Try setting `Config.Framework` manually instead of 'auto'

**License not appearing in menu:**
- Check if `enabled = true` in license configuration
- Verify license type spelling matches exactly
- Ensure server restarted after configuration changes

**Items not being given:**
- Verify item exists in your inventory system
- Check item name matches in `Config.LicenseItems`
- Ensure inventory system is properly configured
- Check if the correct bridge is loaded

**NPC not spawning:**
- Check if `ped.enabled = true` in configuration
- Verify coordinates are correct for your server
- Ensure qb-target or ox_target is installed and working

**Target interaction not working:**
- Verify you have qb-target or ox_target installed
- Check that the target system is detected correctly in console
- Try setting `Config.Target` manually instead of 'auto'

**Tests not starting:**
- Check player has enough money
- Verify player doesn't already have the license
- Check console for error messages
- Verify framework bridge is working correctly

### Debug Mode
Enable debug mode in config to see detailed console output:
```lua
Config.Debug = true
```

## 📞 Support

For support and updates, contact **Shawns Developments**.

## 📄 License

This resource is created by **Shawns Developments**. Please respect the terms of use and licensing agreements.

---

**⚠️ Important**: Always test new configurations on a development server before deploying to production!
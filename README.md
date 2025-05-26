# SD Driving School 🚗

A comprehensive driving school system for FiveM servers supporting both QBCore and ESX frameworks with multiple inventory system compatibility.

## Features ✨

- **Multi-Framework Support**: Automatic detection and support for QBCore and ESX
- **Multi-Inventory Support**: Compatible with qb-inventory, ps-inventory, qs-inventory, ox_inventory, and ESX default
- **Multiple License Types**: Regular, CDL, and Motorcycle licenses
- **Comprehensive Testing System**: Both written and practical driving tests
- **License Replacement**: Players can purchase replacement licenses
- **Configurable Scoring**: Customizable test requirements and scoring system
- **Admin Commands**: Full administrative control over licenses
- **Physical License Items**: Gives actual license items with metadata
- **Interactive NPC**: Driving instructor with qb-target integration
- **Map Blips**: Configurable map markers for the driving school

## Supported Inventory Systems 📦

### QBCore Compatible
- **qb-inventory** (Default QBCore inventory)
- **ps-inventory** (Project Sloth inventory)
- **qs-inventory** (Quasar inventory)
- **ox_inventory** (Overextended inventory)

### ESX Compatible
- **ESX Default** (Built-in ESX inventory)
- **ox_inventory** (Overextended inventory for ESX)

## Installation 📦

### Prerequisites
- QBCore or ESX framework
- mysql-async
- One of the supported inventory systems
- qb-target (optional but recommended for QBCore)
- qb-menu (for QBCore menus)

### Steps

1. **Download and Extract**
   ```bash
   cd resources
   git clone https://github.com/SpazTBC/sd-drivingschool.git
   ```

2. **Database Setup**
   
   **For ESX users**, run the provided SQL:
   ```bash
   mysql -u username -p database_name < sd-drivingschool/install.sql
   ```

3. **Configure Items**
   
   **For QBCore**, add these items to your `qb-core/shared/items.lua`:
   ```lua
   ['drivers_license'] = {
       ['name'] = 'drivers_license',
       ['label'] = 'Driver License',
       ['weight'] = 0,
       ['type'] = 'item',
       ['image'] = 'driver_license.png',
       ['unique'] = true,
       ['useable'] = true,
       ['shouldClose'] = false,
       ['combinable'] = nil,
       ['description'] = 'Permit to show you can drive a vehicle'
   },
   ['cdl_license'] = {
       ['name'] = 'cdl_license',
       ['label'] = 'Commercial Driver License',
       ['weight'] = 0,
       ['type'] = 'item',
       ['image'] = 'cdl_license.png',
       ['unique'] = true,
       ['useable'] = true,
       ['shouldClose'] = false,
       ['combinable'] = nil,
       ['description'] = 'Permit to drive commercial vehicles'
   },
   ['motorcycle_license'] = {
       ['name'] = 'motorcycle_license',
       ['label'] = 'Motorcycle License',
       ['weight'] = 0,
       ['type'] = 'item',
       ['image'] = 'motorcycle_license.png',
       ['unique'] = true,
       ['useable'] = true,
       ['shouldClose'] = false,
       ['combinable'] = nil,
       ['description'] = 'Permit to drive motorcycles'
   },
   ```

   **For ox_inventory**, add to your `ox_inventory/data/items.lua`:
   ```lua
   ['drivers_license'] = {
       label = 'Driver License',
       weight = 0,
       stack = false,
       close = false,
       description = 'Permit to show you can drive a vehicle'
   },
   ['cdl_license'] = {
       label = 'Commercial Driver License',
       weight = 0,
       stack = false,
       close = false,
       description = 'Permit to drive commercial vehicles'
   },
   ['motorcycle_license'] = {
       label = 'Motorcycle License',
       weight = 0,
       stack = false,
       close = false,
       description = 'Permit to drive motorcycles'
   },
   ```

   **For ESX**, add to your database items table or items.lua depending on your setup.

4. **Add to server.cfg**
   ```cfg
   ensure sd-drivingschool
   ```

5. **Restart Server**
   ```bash
   restart sd-drivingschool
   ```

## Configuration ⚙️

### Framework and Inventory Settings
```lua
-- Automatic detection (recommended)
Config.Framework = 'auto' -- 'auto', 'qbcore', or 'esx'
Config.Inventory = 'auto'  -- 'auto', 'qb-inventory', 'ps-inventory', 'qs-inventory', 'ox_inventory', 'esx_default'

-- Manual configuration example
Config.Framework = 'qbcore'
Config.Inventory = 'ps-inventory'
```

### License Item Names
```lua
-- Customize these to match your server's item names
Config.LicenseItems = {
    regular = 'drivers_license',
    cdl = 'cdl_license',
    motorcycle = 'motorcycle_license'
}
```

### Inventory-Specific Settings
```lua
Config.InventorySettings = {
    -- ox_inventory specific settings
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
    -- ESX default inventory settings
    esx_default = {
        useDatabase = true,
        tableName = 'user_licenses_items'
    }
}
```

## Inventory System Features 🎯

### Metadata Support
The script automatically detects your inventory system and applies the appropriate metadata format:

- **QBCore inventories**: Uses `info` table for metadata
- **ox_inventory**: Uses `metadata` table
- **ESX default**: Stores metadata in custom database table

### License Information
Each license item contains:
- **First Name** and **Last Name**
- **Date of Birth**
- **License Type**
- **Issue Date**
- **Expiration Date** (1 year from issue)

## Troubleshooting 🔧

### Inventory-Related Issues

1. **Items not appearing in inventory**
   - Verify items are added to your inventory system's items file
   - Check item names match `Config.LicenseItems`
   - Ensure inventory system is started before this resource

2. **Metadata not showing**
   - Check if your inventory supports metadata/info
   - Verify `Config.Inventory` is set correctly
   - For ox_inventory, ensure items are properly configured

3. **ESX inventory issues**
   - Run the provided SQL file
   - Check MySQL connection
   - Verify ESX inventory is working properly

### Debug Mode
Enable debug mode to see detailed logs:
```lua
Config.Debug = true
```

### Console Output
The script will show which systems it detected on startup:
```
[SD-DrivingSchool] Successfully loaded with framework: qbcore
[SD-DrivingSchool] Using inventory system: ps-inventory
```

## API Functions 🔧

### Inventory Functions
```lua
-- Add item with metadata
Inventory.AddItem(source, Player, itemName, amount, metadata)

-- Remove item
Inventory.RemoveItem(source, Player, itemName, amount)

-- Check if player has item
Inventory.HasItem(source, Player, itemName, callback)

-- Get item metadata
Inventory.GetItemMetadata(source, Player, itemName, callback)
```

## Supported Versions 📋

### Framework Versions
- **QBCore**: All recent versions
- **ESX**: 1.2+ and Legacy

### Inventory Versions
- **qb-inventory**: All versions
- **ps-inventory**: v2.0+
- **qs-inventory**: All versions
- **ox_inventory**: v2.0+
- **ESX default**: All versions

## Migration Guide 🔄

### From v1.0 to v2.0
1. Update your `config.lua` with new inventory settings
2. Add inventory items to your inventory system
3. For ESX users, run the new SQL file
4. Restart the resource

### Switching Inventory Systems
1. Update `Config.Inventory` in config.lua
2. Add items to your new inventory system
3. Restart the resource

The script will automatically detect and adapt to your new inventory system.

## Credits 👏

- **Author**: Shawns Developments
- **Framework Support**: QBCore & ESX
- **Inventory Support**: Multiple systems
- **Special Thanks**: FiveM community

## Changelog 📝

### Version 2.0.0
- Added multi-inventory support
- Added ox_inventory compatibility
- Added ps-inventory compatibility
- Added qs-inventory compatibility
- Improved ESX inventory support
- Enhanced metadata handling
- Better error handling and debugging

### Version 1.0.0
- Initial release
- QBCore support
- Basic ESX support
- License system implementation

---

**Made with ❤️ by Shawns Developments**
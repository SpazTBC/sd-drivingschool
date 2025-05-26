-- Add these items to your qb-core/shared/items.lua file
-- Or include this file in your server.cfg after qb-core

-- Note: 'drivers' should already exist in QBCore by default for regular driver's license

-- Old QBCore

-- CDL License
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
    ['description'] = 'A valid commercial driver license'
},

-- Motorcycle License
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
    ['description'] = 'A valid motorcycle license'
},


-- New QBCore


-- Add these items to your qb-core/shared/items.lua file

-- CDL License
cdl_license = {name = "cdl_license", label = "Commercial Driver License", weight = 0, type = "item", image = "cdl_license.png", unique = true, useable = true, shouldClose = false, combinable = nil, description = "A valid commercial driver license"},

-- Motorcycle License
motorcycle_license = {name = "motorcycle_license", label = "Motorcycle License", weight = 0, type = "item", image = "motorcycle_license.png", unique = true, useable = true, shouldClose = false, combinable = nil, description = "A valid motorcycle license"},
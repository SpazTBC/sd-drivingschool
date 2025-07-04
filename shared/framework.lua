Framework = {}
Inventory = {}

-- Framework Detection
if Config.Framework == 'auto' then
    if GetResourceState('qbx_core') == 'started' then
        Config.Framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        Config.Framework = 'qbcore'
    elseif GetResourceState('es_extended') == 'started' then
        Config.Framework = 'esx'
    else
        print('^1[SD-DrivingSchool] No supported framework detected!^0')
    end
end

-- Inventory Detection
if Config.Inventory == 'auto' then
    if GetResourceState('ox_inventory') == 'started' then
        Config.Inventory = 'ox_inventory'
    elseif GetResourceState('ps-inventory') == 'started' then
        Config.Inventory = 'ps-inventory'
    elseif GetResourceState('qs-inventory') == 'started' then
        Config.Inventory = 'qs-inventory'
    elseif GetResourceState('qb-inventory') == 'started' then
        Config.Inventory = 'qb-inventory'
    elseif Config.Framework == 'esx' then
        Config.Inventory = 'esx_default'
    elseif Config.Framework == 'qbcore' then
        Config.Inventory = 'qb-inventory' -- Default to qb-inventory for QBCore
    else
        print('^1[SD-DrivingSchool] No supported inventory detected!^0')
    end
end

-- Target System Detection
if Config.Target == 'auto' then
    if GetResourceState('ox_target') == 'started' then
        Config.Target = 'ox_target'
    elseif GetResourceState('qb-target') == 'started' then
        Config.Target = 'qb-target'
    else
        print('^1[SD-DrivingSchool] No supported target system detected!^0')
        Config.Target = 'none'
    end
end

-- Load appropriate bridge based on framework
if Config.Framework == 'qbx' then
    require 'shared.qbx'
elseif Config.Framework == 'qbcore' then
    require 'shared.qb'
elseif Config.Framework == 'esx' then
    require 'shared.esx'
end

-- Framework Functions
function Framework.GetFramework()
    if Config.Framework == 'qbx' then
        return exports.qbx_core:GetCoreObject()
    elseif Config.Framework == 'qbcore' then
        return exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'esx' then
        return exports['es_extended']:getSharedObject()
    end
    return nil
end

function Framework.ShowNotification(message, type)
    if Config.Framework == 'qbx' then
        TriggerEvent('QBCore:Notify', message, type or 'primary')
    elseif Config.Framework == 'qbcore' then
        TriggerEvent('QBCore:Notify', message, type or 'primary')
    elseif Config.Framework == 'esx' then
        TriggerEvent('esx:showNotification', message)
    end
end

function Framework.GetPlayerData()
    if Config.Framework == 'qbx' then
        local QBCore = Framework.GetFramework()
        return QBCore.Functions.GetPlayerData()
    elseif Config.Framework == 'qbcore' then
        local QBCore = Framework.GetFramework()
        return QBCore.Functions.GetPlayerData()
    elseif Config.Framework == 'esx' then
        local ESX = Framework.GetFramework()
        return ESX.GetPlayerData()
    end
    return nil
end

-- Target System Functions
function Framework.AddTargetEntity(entity, options)
    if Config.Target == 'ox_target' then
        exports.ox_target:addLocalEntity(entity, options)
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(entity, options)
    end
end

function Framework.RemoveTargetEntity(entity)
    if Config.Target == 'ox_target' then
        exports.ox_target:removeLocalEntity(entity)
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:RemoveTargetEntity(entity)
    end
end

-- Inventory Functions
function Inventory.AddItem(source, Player, itemName, amount, metadata)
    if Config.Inventory == 'ox_inventory' then
        return exports.ox_inventory:AddItem(source, itemName, amount, metadata)
    elseif Config.Inventory == 'ps-inventory' then
        return Player.Functions.AddItem(itemName, amount, false, metadata)
    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:AddItem(source, itemName, amount, false, metadata)
    elseif Config.Inventory == 'qb-inventory' then
        return Player.Functions.AddItem(itemName, amount, false, metadata)
    elseif Config.Inventory == 'esx_default' then
        -- For ESX, we'll store in database and give a basic item
        if Config.InventorySettings.esx_default.useDatabase then
            -- Store detailed info in custom table
            MySQL.Async.execute('INSERT INTO user_licenses_items (identifier, item_name, metadata) VALUES (@identifier, @item_name, @metadata) ON DUPLICATE KEY UPDATE metadata = @metadata', {
                ['@identifier'] = Player.identifier,
                ['@item_name'] = itemName,
                ['@metadata'] = json.encode(metadata)
            })
        end
        -- Give basic item
        Player.addInventoryItem(itemName, amount)
        return true
    end
    return false
end

function Inventory.RemoveItem(source, Player, itemName, amount)
    if Config.Inventory == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(source, itemName, amount)
    elseif Config.Inventory == 'ps-inventory' then
        return Player.Functions.RemoveItem(itemName, amount)
    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:RemoveItem(source, itemName, amount)
    elseif Config.Inventory == 'qb-inventory' then
        return Player.Functions.RemoveItem(itemName, amount)
    elseif Config.Inventory == 'esx_default' then
        Player.removeInventoryItem(itemName, amount)
        -- Also remove from custom table
        if Config.InventorySettings.esx_default.useDatabase then
            MySQL.Async.execute('DELETE FROM user_licenses_items WHERE identifier = @identifier AND item_name = @item_name', {
                ['@identifier'] = Player.identifier,
                ['@item_name'] = itemName
            })
        end
        return true
    end
    return false
end

function Inventory.HasItem(source, Player, itemName, cb)
    if Config.Inventory == 'ox_inventory' then
        local item = exports.ox_inventory:GetItem(source, itemName, nil, true)
        cb(item and item.count > 0)
    elseif Config.Inventory == 'ps-inventory' then
        local item = Player.Functions.GetItemByName(itemName)
        cb(item ~= nil and item.amount > 0)
    elseif Config.Inventory == 'qs-inventory' then
        local item = exports['qs-inventory']:GetItemByName(source, itemName)
        cb(item ~= nil and item.amount > 0)
    elseif Config.Inventory == 'qb-inventory' then
        local item = Player.Functions.GetItemByName(itemName)
        cb(item ~= nil and item.amount > 0)
    elseif Config.Inventory == 'esx_default' then
        local item = Player.getInventoryItem(itemName)
        cb(item ~= nil and item.count > 0)
    else
        cb(false)
    end
end

-- Get item metadata (for viewing license details)
function Inventory.GetItemMetadata(source, Player, itemName, cb)
    if Config.Inventory == 'ox_inventory' then
        local item = exports.ox_inventory:GetItem(source, itemName, nil, true)
        cb(item and item.metadata or {})
    elseif Config.Inventory == 'ps-inventory' or Config.Inventory == 'qb-inventory' then
        local item = Player.Functions.GetItemByName(itemName)
        cb(item and item.info or {})
    elseif Config.Inventory == 'qs-inventory' then
        local item = exports['qs-inventory']:GetItemByName(source, itemName)
        cb(item and item.info or {})
    elseif Config.Inventory == 'esx_default' then
        if Config.InventorySettings.esx_default.useDatabase then
            MySQL.Async.fetchAll('SELECT metadata FROM user_licenses_items WHERE identifier = @identifier AND item_name = @item_name', {
                ['@identifier'] = Player.identifier,
                ['@item_name'] = itemName
            }, function(result)
                if result[1] then
                    cb(json.decode(result[1].metadata) or {})
                else
                    cb({})
                end
            end)
        else
            cb({})
        end
    else
        cb({})
    end
end
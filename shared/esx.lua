-- ESX Framework Bridge
if Config.Framework == 'esx' then
    ESX = {}

    -- ESX Framework Functions
    function ESX.GetFramework()
        return exports['es_extended']:getSharedObject()
    end

function ESX.ShowNotification(source, message, type)
    TriggerClientEvent('esx:showNotification', source, message)
end

function ESX.GetPlayerData()
    return ESX.GetPlayerData()
end

-- ESX Player Functions
function ESX.GetPlayer(source)
    local ESXCore = ESX.GetFramework()
    return ESXCore.GetPlayerFromId(source)
end

function ESX.GetPlayerMoney(Player, moneyType)
    return Player.getMoney()
end

function ESX.RemovePlayerMoney(Player, amount, moneyType)
    Player.removeMoney(amount)
    return true
end

function ESX.GetPlayerIdentifier(Player)
    return Player.identifier
end

function ESX.GetPlayerCharInfo(Player)
    return {
        firstname = Player.get('firstName') or 'John',
        lastname = Player.get('lastName') or 'Doe',
        birthdate = Player.get('dateofbirth') or '01/01/1990'
    }
end

function ESX.GetPlayerSource(Player)
    return Player.source
end

-- ESX License Functions
function ESX.AddLicense(Player, licenseType)
    local source = ESX.GetPlayerSource(Player)
    
    -- Add to ESX license system
    MySQL.Async.execute('INSERT INTO user_licenses (type, owner) VALUES (@type, @owner) ON DUPLICATE KEY UPDATE type = @type', {
        ['@type'] = licenseType,
        ['@owner'] = Player.identifier
    })
    
    -- Give physical item using inventory system
    local itemName = Config.LicenseItems[licenseType]
    if itemName then
        local charInfo = ESX.GetPlayerCharInfo(Player)
        local licenseData = {
            firstname = charInfo.firstname,
            lastname = charInfo.lastname,
            birthdate = charInfo.birthdate,
            type = licenseType,
            issued = os.date('%m-%d-%Y'),
            expires = os.date('%m-%d-%Y', os.time() + (365 * 24 * 60 * 60))
        }
        
        ESX.AddItem(source, Player, itemName, 1, licenseData)
    end
end

function ESX.HasLicense(Player, licenseType, cb)
    MySQL.Async.fetchAll('SELECT * FROM user_licenses WHERE type = @type AND owner = @owner', {
        ['@type'] = licenseType,
        ['@owner'] = Player.identifier
    }, function(result)
        cb(#result > 0)
    end)
end

function ESX.RemoveLicense(Player, licenseType)
    local source = ESX.GetPlayerSource(Player)
    
    -- Remove from ESX license system
    MySQL.Async.execute('DELETE FROM user_licenses WHERE type = @type AND owner = @owner', {
        ['@type'] = licenseType,
        ['@owner'] = Player.identifier
    })
    
    -- Remove physical item
    local itemName = Config.LicenseItems[licenseType]
    if itemName then
        ESX.RemoveItem(source, Player, itemName, 1)
    end
end

-- ESX Inventory Functions
function ESX.AddItem(source, Player, itemName, amount, metadata)
    if Config.Inventory == 'ox_inventory' then
        return exports.ox_inventory:AddItem(source, itemName, amount, metadata)
    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:AddItem(source, itemName, amount, false, metadata)
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

function ESX.RemoveItem(source, Player, itemName, amount)
    if Config.Inventory == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(source, itemName, amount)
    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:RemoveItem(source, itemName, amount)
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

function ESX.HasItem(source, Player, itemName, cb)
    if Config.Inventory == 'ox_inventory' then
        local item = exports.ox_inventory:GetItem(source, itemName, nil, true)
        cb(item and item.count > 0)
    elseif Config.Inventory == 'qs-inventory' then
        local item = exports['qs-inventory']:GetItemByName(source, itemName)
        cb(item ~= nil and item.amount > 0)
    elseif Config.Inventory == 'esx_default' then
        local item = Player.getInventoryItem(itemName)
        cb(item ~= nil and item.count > 0)
    else
        cb(false)
    end
end

function ESX.GetItemMetadata(source, Player, itemName, cb)
    if Config.Inventory == 'ox_inventory' then
        local item = exports.ox_inventory:GetItem(source, itemName, nil, true)
        cb(item and item.metadata or {})
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

-- ESX Menu Functions
function ESX.ShowMenu(menuData)
    -- Convert to ESX menu format if needed
    TriggerEvent('esx:showMenu', menuData)
end

function ESX.CloseMenu()
    TriggerEvent('esx:closeMenu')
end

-- ESX Admin Commands
function ESX.RegisterAdminCommands()
    local ESXCore = ESX.GetFramework()
    
    ESXCore.RegisterCommand('givelicense', 'admin', function(xPlayer, args, showError)
        local targetId = tonumber(args.id)
        local licenseType = args.type
        
        if not targetId or not licenseType then
            xPlayer.showNotification('Invalid arguments!')
            return
        end
        
        if not Config.Licenses[licenseType] then
            xPlayer.showNotification('Invalid license type!')
            return
        end
        
        local targetPlayer = ESXCore.GetPlayerFromId(targetId)
        if not targetPlayer then
            xPlayer.showNotification('Player not found!')
            return
        end
        
        ESX.AddLicense(targetPlayer, licenseType)
        xPlayer.showNotification('License given successfully!')
        targetPlayer.showNotification('You have been given a ' .. Config.Licenses[licenseType].name .. '!')
    end, true, {help = 'Give a player a driving license', validate = true, arguments = {
        {name = 'id', help = 'Player ID', type = 'number'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)', type = 'string'}
    }})
    
    ESXCore.RegisterCommand('removelicense', 'admin', function(xPlayer, args, showError)
        local targetId = tonumber(args.id)
        local licenseType = args.type
        
        if not targetId or not licenseType then
            xPlayer.showNotification('Invalid arguments!')
            return
        end
        
        local targetPlayer = ESXCore.GetPlayerFromId(targetId)
        if not targetPlayer then
            xPlayer.showNotification('Player not found!')
            return
        end
        
        ESX.RemoveLicense(targetPlayer, licenseType)
        xPlayer.showNotification('License removed successfully!')
        targetPlayer.showNotification('Your ' .. Config.Licenses[licenseType].name .. ' has been removed!')
    end, true, {help = 'Remove a player\'s driving license', validate = true, arguments = {
        {name = 'id', help = 'Player ID', type = 'number'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)', type = 'string'}
    }})
end

-- ESX Database Setup
function ESX.SetupDatabase()
    if Config.Inventory == 'esx_default' and Config.InventorySettings.esx_default.useDatabase then
        MySQL.ready(function()
            MySQL.Async.execute([[
                CREATE TABLE IF NOT EXISTS `user_licenses_items` (
                    `identifier` varchar(60) NOT NULL,
                    `item_name` varchar(50) NOT NULL,
                    `metadata` longtext,
                    PRIMARY KEY (`identifier`, `item_name`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            ]], {})
        end)
    end
end

end

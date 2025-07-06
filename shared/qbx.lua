-- QBox Framework Bridge
if Config.Framework == 'qbx' then
    QBX = {}

    -- QBox Framework Functions
    function QBX.GetFramework()
        return exports.qbx_core:GetCoreObject()
    end

    function QBX.ShowNotification(source, message, type)
        TriggerClientEvent('QBCore:Notify', source, message, type or 'primary')
    end

    function QBX.GetPlayerData()
        local QBCore = QBX.GetFramework()
        return QBCore.Functions.GetPlayerData()
    end

    -- QBox Player Functions
    function QBX.GetPlayer(source)
        local QBCore = QBX.GetFramework()
        return QBCore.Functions.GetPlayer(source)
    end

    function QBX.GetPlayerMoney(Player, moneyType)
        return Player.Functions.GetMoney(moneyType or 'cash')
    end

    function QBX.RemovePlayerMoney(Player, amount, moneyType)
        return Player.Functions.RemoveMoney(moneyType or 'cash', amount)
    end

    function QBX.GetPlayerIdentifier(Player)
        return Player.PlayerData.citizenid
    end

    function QBX.GetPlayerCharInfo(Player)
        return {
            firstname = Player.PlayerData.charinfo.firstname,
            lastname = Player.PlayerData.charinfo.lastname,
            birthdate = Player.PlayerData.charinfo.birthdate
        }
    end

    function QBX.GetPlayerSource(Player)
        return Player.PlayerData.source
    end

-- QBox License Functions
function QBX.AddLicense(Player, licenseType)
    local source = QBX.GetPlayerSource(Player)
    
    -- Map license types to QBox license names
    local licenseMap = {
        regular = 'driver',
        cdl = 'cdl',
        motorcycle = 'motorcycle'
    }
    
    local qbxLicenseType = licenseMap[licenseType]
    if qbxLicenseType then
        -- Set the license to true in player metadata
        local licences = Player.PlayerData.metadata.licences or {}
        licences[qbxLicenseType] = true
        Player.Functions.SetMetaData('licences', licences)
        
        -- Force save player data to database immediately
        Player.Functions.Save()
    end
    
    -- Give physical item using inventory system
    local itemName = Config.LicenseItems[licenseType]
    if itemName then
        local charInfo = QBX.GetPlayerCharInfo(Player)
        local licenseData = {
            firstname = charInfo.firstname,
            lastname = charInfo.lastname,
            birthdate = charInfo.birthdate,
            type = licenseType,
            issued = os.date('%m-%d-%Y'),
            expires = os.date('%m-%d-%Y', os.time() + (365 * 24 * 60 * 60))
        }
        
        QBX.AddItem(source, Player, itemName, 1, licenseData)
    end
end

function QBX.HasLicense(Player, licenseType, cb)
    -- Map license types to QBox license names
    local licenseMap = {
        regular = 'driver',
        cdl = 'cdl',
        motorcycle = 'motorcycle'
    }
    
    local qbxLicenseType = licenseMap[licenseType]
    local hasLicense = false
    
    if qbxLicenseType and Player.PlayerData.metadata.licences then
        hasLicense = Player.PlayerData.metadata.licences[qbxLicenseType] == true
    end
    
    cb(hasLicense)
end

function QBX.RemoveLicense(Player, licenseType)
    local source = QBX.GetPlayerSource(Player)
    
    -- Map license types to QBox license names
    local licenseMap = {
        regular = 'driver',
        cdl = 'cdl',
        motorcycle = 'motorcycle'
    }
    
    local qbxLicenseType = licenseMap[licenseType]
    if qbxLicenseType then
        -- Set the license to false in player metadata
        local licences = Player.PlayerData.metadata.licences or {}
        licences[qbxLicenseType] = false
        Player.Functions.SetMetaData('licences', licences)
        
        -- Force save player data to database immediately
        Player.Functions.Save()
    end
    
    -- Remove physical item
    local itemName = Config.LicenseItems[licenseType]
    if itemName then
        QBX.RemoveItem(source, Player, itemName, 1)
    end
end

-- QBox Inventory Functions
function QBX.AddItem(source, Player, itemName, amount, metadata)
    if Config.Inventory == 'ox_inventory' then
        return exports.ox_inventory:AddItem(source, itemName, amount, metadata)
    elseif Config.Inventory == 'ps-inventory' then
        return Player.Functions.AddItem(itemName, amount, false, metadata)
    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:AddItem(source, itemName, amount, false, metadata)
    elseif Config.Inventory == 'qb-inventory' then
        return Player.Functions.AddItem(itemName, amount, false, metadata)
    end
    return false
end

function QBX.RemoveItem(source, Player, itemName, amount)
    if Config.Inventory == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(source, itemName, amount)
    elseif Config.Inventory == 'ps-inventory' then
        return Player.Functions.RemoveItem(itemName, amount)
    elseif Config.Inventory == 'qs-inventory' then
        return exports['qs-inventory']:RemoveItem(source, itemName, amount)
    elseif Config.Inventory == 'qb-inventory' then
        return Player.Functions.RemoveItem(itemName, amount)
    end
    return false
end

function QBX.HasItem(source, Player, itemName, cb)
    if Config.Inventory == 'ox_inventory' then
        local item = exports.ox_inventory:GetItem(source, itemName, nil, true)
        cb(item and item.count > 0)
    elseif Config.Inventory == 'ps-inventory' or Config.Inventory == 'qb-inventory' then
        local item = Player.Functions.GetItemByName(itemName)
        cb(item ~= nil and item.amount > 0)
    elseif Config.Inventory == 'qs-inventory' then
        local item = exports['qs-inventory']:GetItemByName(source, itemName)
        cb(item ~= nil and item.amount > 0)
    else
        cb(false)
    end
end

function QBX.GetItemMetadata(source, Player, itemName, cb)
    if Config.Inventory == 'ox_inventory' then
        local item = exports.ox_inventory:GetItem(source, itemName, nil, true)
        cb(item and item.metadata or {})
    elseif Config.Inventory == 'ps-inventory' or Config.Inventory == 'qb-inventory' then
        local item = Player.Functions.GetItemByName(itemName)
        cb(item and item.info or {})
    elseif Config.Inventory == 'qs-inventory' then
        local item = exports['qs-inventory']:GetItemByName(source, itemName)
        cb(item and item.info or {})
    else
        cb({})
    end
end

-- QBox Menu Functions
function QBX.ShowMenu(menuData)
    exports['qb-menu']:openMenu(menuData)
end

function QBX.CloseMenu()
    exports['qb-menu']:closeMenu()
end

-- QBox Spawn Vehicle Function
function QBX.SpawnVehicle(vehicle, cb, coords, warp)
    local QBCore = QBX.GetFramework()
    QBCore.Functions.SpawnVehicle(vehicle, cb, coords, warp)
end

-- QBox Admin Commands
function QBX.RegisterAdminCommands()
    local QBCore = QBX.GetFramework()
    
    QBCore.Commands.Add('givelicense', 'Give a player a driving license (Admin Only)', {
        {name = 'id', help = 'Player ID'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)'}
    }, true, function(source, args)
        local targetId = tonumber(args[1])
        local licenseType = args[2]
        
        if not targetId or not licenseType then
            QBX.ShowNotification(source, 'Invalid arguments!', 'error')
            return
        end
        
        if not Config.Licenses[licenseType] then
            QBX.ShowNotification(source, 'Invalid license type!', 'error')
            return
        end
        
        local targetPlayer = QBX.GetPlayer(targetId)
        if not targetPlayer then
            QBX.ShowNotification(source, 'Player not found!', 'error')
            return
        end
        
        QBX.AddLicense(targetPlayer, licenseType)
        QBX.ShowNotification(source, 'License given successfully!', 'success')
        QBX.ShowNotification(targetId, 'You have been given a ' .. Config.Licenses[licenseType].name .. '!', 'success')
    end, 'admin')
    
    QBCore.Commands.Add('removelicense', 'Remove a player\'s driving license (Admin Only)', {
        {name = 'id', help = 'Player ID'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)'}
    }, true, function(source, args)
        local targetId = tonumber(args[1])
        local licenseType = args[2]
        
        if not targetId or not licenseType then
            QBX.ShowNotification(source, 'Invalid arguments!', 'error')
            return
        end
        
        local targetPlayer = QBX.GetPlayer(targetId)
        if not targetPlayer then
            QBX.ShowNotification(source, 'Player not found!', 'error')
            return
        end
        
        QBX.RemoveLicense(targetPlayer, licenseType)
        QBX.ShowNotification(source, 'License removed successfully!', 'success')
        QBX.ShowNotification(targetId, 'Your ' .. Config.Licenses[licenseType].name .. ' has been removed!', 'error')
    end, 'admin')
    
    QBCore.Commands.Add('givereplacement', 'Give a player a replacement license (Admin Only)', {
        {name = 'id', help = 'Player ID'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)'}
    }, true, function(source, args)
        local targetId = tonumber(args[1])
        local licenseType = args[2]
        
        if not targetId or not licenseType then
            QBX.ShowNotification(source, 'Invalid arguments!', 'error')
            return
        end
        
        if not Config.Licenses[licenseType] then
            QBX.ShowNotification(source, 'Invalid license type!', 'error')
            return
        end
        
        local targetPlayer = QBX.GetPlayer(targetId)
        if not targetPlayer then
            QBX.ShowNotification(source, 'Player not found!', 'error')
            return
        end
        
        QBX.HasLicense(targetPlayer, licenseType, function(hasLicense)
            if not hasLicense then
                QBX.ShowNotification(source, 'Player doesn\'t have this license to replace!', 'error')
                return
            end
            
            local itemName = Config.LicenseItems[licenseType]
            if itemName then
                local charInfo = QBX.GetPlayerCharInfo(targetPlayer)
                local licenseData = {
                    firstname = charInfo.firstname,
                    lastname = charInfo.lastname,
                    birthdate = charInfo.birthdate,
                    type = licenseType,
                    issued = os.date('%m-%d-%Y'),
                    expires = os.date('%m-%d-%Y', os.time() + (365 * 24 * 60 * 60))
                }
                
                QBX.AddItem(targetId, targetPlayer, itemName, 1, licenseData)
                QBX.ShowNotification(source, 'Replacement license given successfully!', 'success')
                QBX.ShowNotification(targetId, 'You have been given a replacement ' .. Config.Licenses[licenseType].name .. '!', 'success')
            end
        end)
    end, 'admin')
end

end

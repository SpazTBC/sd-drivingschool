QB = {}

-- QBCore Framework Functions
function QB.GetFramework()
    return exports['qb-core']:GetCoreObject()
end

function QB.ShowNotification(source, message, type)
    TriggerClientEvent('QBCore:Notify', source, message, type or 'primary')
end

function QB.GetPlayerData()
    local QBCore = QB.GetFramework()
    return QBCore.Functions.GetPlayerData()
end

-- QBCore Player Functions
function QB.GetPlayer(source)
    local QBCore = QB.GetFramework()
    return QBCore.Functions.GetPlayer(source)
end

function QB.GetPlayerMoney(Player, moneyType)
    return Player.Functions.GetMoney(moneyType or 'cash')
end

function QB.RemovePlayerMoney(Player, amount, moneyType)
    return Player.Functions.RemoveMoney(moneyType or 'cash', amount)
end

function QB.GetPlayerIdentifier(Player)
    return Player.PlayerData.citizenid
end

function QB.GetPlayerCharInfo(Player)
    return {
        firstname = Player.PlayerData.charinfo.firstname,
        lastname = Player.PlayerData.charinfo.lastname,
        birthdate = Player.PlayerData.charinfo.birthdate
    }
end

function QB.GetPlayerSource(Player)
    return Player.PlayerData.source
end

-- QBCore License Functions
function QB.AddLicense(Player, licenseType)
    local source = QB.GetPlayerSource(Player)
    
    -- Map license types to QBCore license names
    local licenseMap = {
        regular = 'driver',
        cdl = 'cdl',
        motorcycle = 'motorcycle'
    }
    
    local qbLicenseType = licenseMap[licenseType]
    if qbLicenseType then
        -- Set the license to true in player metadata
        local licences = Player.PlayerData.metadata.licences or {}
        licences[qbLicenseType] = true
        Player.Functions.SetMetaData('licences', licences)
        
        -- Force save player data to database immediately
        Player.Functions.Save()
    end
    
    -- Give physical item using inventory system
    local itemName = Config.LicenseItems[licenseType]
    if itemName then
        local charInfo = QB.GetPlayerCharInfo(Player)
        local licenseData = {
            firstname = charInfo.firstname,
            lastname = charInfo.lastname,
            birthdate = charInfo.birthdate,
            type = licenseType,
            issued = os.date('%m-%d-%Y'),
            expires = os.date('%m-%d-%Y', os.time() + (365 * 24 * 60 * 60))
        }
        
        QB.AddItem(source, Player, itemName, 1, licenseData)
    end
end

function QB.HasLicense(Player, licenseType, cb)
    -- Map license types to QBCore license names
    local licenseMap = {
        regular = 'driver',
        cdl = 'cdl',
        motorcycle = 'motorcycle'
    }
    
    local qbLicenseType = licenseMap[licenseType]
    local hasLicense = false
    
    if qbLicenseType and Player.PlayerData.metadata.licences then
        hasLicense = Player.PlayerData.metadata.licences[qbLicenseType] == true
    end
    
    cb(hasLicense)
end

function QB.RemoveLicense(Player, licenseType)
    local source = QB.GetPlayerSource(Player)
    
    -- Map license types to QBCore license names
    local licenseMap = {
        regular = 'driver',
        cdl = 'cdl',
        motorcycle = 'motorcycle'
    }
    
    local qbLicenseType = licenseMap[licenseType]
    if qbLicenseType then
        -- Set the license to false in player metadata
        local licences = Player.PlayerData.metadata.licences or {}
        licences[qbLicenseType] = false
        Player.Functions.SetMetaData('licences', licences)
        
        -- Force save player data to database immediately
        Player.Functions.Save()
    end
    
    -- Remove physical item
    local itemName = Config.LicenseItems[licenseType]
    if itemName then
        QB.RemoveItem(source, Player, itemName, 1)
    end
end

-- QBCore Inventory Functions
function QB.AddItem(source, Player, itemName, amount, metadata)
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

function QB.RemoveItem(source, Player, itemName, amount)
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

function QB.HasItem(source, Player, itemName, cb)
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

function QB.GetItemMetadata(source, Player, itemName, cb)
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

-- QBCore Menu Functions
function QB.ShowMenu(menuData)
    exports['qb-menu']:openMenu(menuData)
end

function QB.CloseMenu()
    exports['qb-menu']:closeMenu()
end

-- QBCore Spawn Vehicle Function
function QB.SpawnVehicle(vehicle, cb, coords, warp)
    local QBCore = QB.GetFramework()
    QBCore.Functions.SpawnVehicle(vehicle, cb, coords, warp)
end

-- QBCore Admin Commands
function QB.RegisterAdminCommands()
    local QBCore = QB.GetFramework()
    
    QBCore.Commands.Add('givelicense', 'Give a player a driving license (Admin Only)', {
        {name = 'id', help = 'Player ID'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)'}
    }, true, function(source, args)
        local targetId = tonumber(args[1])
        local licenseType = args[2]
        
        if not targetId or not licenseType then
            QB.ShowNotification(source, 'Invalid arguments!', 'error')
            return
        end
        
        if not Config.Licenses[licenseType] then
            QB.ShowNotification(source, 'Invalid license type!', 'error')
            return
        end
        
        local targetPlayer = QB.GetPlayer(targetId)
        if not targetPlayer then
            QB.ShowNotification(source, 'Player not found!', 'error')
            return
        end
        
        QB.AddLicense(targetPlayer, licenseType)
        QB.ShowNotification(source, 'License given successfully!', 'success')
        QB.ShowNotification(targetId, 'You have been given a ' .. Config.Licenses[licenseType].name .. '!', 'success')
    end, 'admin')
    
    QBCore.Commands.Add('removelicense', 'Remove a player\'s driving license (Admin Only)', {
        {name = 'id', help = 'Player ID'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)'}
    }, true, function(source, args)
        local targetId = tonumber(args[1])
        local licenseType = args[2]
        
        if not targetId or not licenseType then
            QB.ShowNotification(source, 'Invalid arguments!', 'error')
            return
        end
        
        local targetPlayer = QB.GetPlayer(targetId)
        if not targetPlayer then
            QB.ShowNotification(source, 'Player not found!', 'error')
            return
        end
        
        QB.RemoveLicense(targetPlayer, licenseType)
        QB.ShowNotification(source, 'License removed successfully!', 'success')
        QB.ShowNotification(targetId, 'Your ' .. Config.Licenses[licenseType].name .. ' has been removed!', 'error')
    end, 'admin')
    
    QBCore.Commands.Add('givereplacement', 'Give a player a replacement license (Admin Only)', {
        {name = 'id', help = 'Player ID'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)'}
    }, true, function(source, args)
        local targetId = tonumber(args[1])
        local licenseType = args[2]
        
        if not targetId or not licenseType then
            QB.ShowNotification(source, 'Invalid arguments!', 'error')
            return
        end
        
        if not Config.Licenses[licenseType] then
            QB.ShowNotification(source, 'Invalid license type!', 'error')
            return
        end
        
        local targetPlayer = QB.GetPlayer(targetId)
        if not targetPlayer then
            QB.ShowNotification(source, 'Player not found!', 'error')
            return
        end
        
        QB.HasLicense(targetPlayer, licenseType, function(hasLicense)
            if not hasLicense then
                QB.ShowNotification(source, 'Player doesn\'t have this license to replace!', 'error')
                return
            end
            
            local itemName = Config.LicenseItems[licenseType]
            if itemName then
                local charInfo = QB.GetPlayerCharInfo(targetPlayer)
                local licenseData = {
                    firstname = charInfo.firstname,
                    lastname = charInfo.lastname,
                    birthdate = charInfo.birthdate,
                    type = licenseType,
                    issued = os.date('%m-%d-%Y'),
                    expires = os.date('%m-%d-%Y', os.time() + (365 * 24 * 60 * 60))
                }
                
                QB.AddItem(targetId, targetPlayer, itemName, 1, licenseData)
                QB.ShowNotification(source, 'Replacement license given successfully!', 'success')
                QB.ShowNotification(targetId, 'You have been given a replacement ' .. Config.Licenses[licenseType].name .. '!', 'success')
            end
        end)
    end, 'admin')
end

return QB

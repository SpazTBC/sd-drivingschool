local QBCore, ESX = nil, nil

-- Initialize Framework
if Config.Framework == 'qbcore' then
    QBCore = Framework.GetFramework()
elseif Config.Framework == 'esx' then
    ESX = Framework.GetFramework()
end

-- Helper Functions
function GetPlayer(source)
    if Config.Framework == 'qbcore' then
        return QBCore.Functions.GetPlayer(source)
    elseif Config.Framework == 'esx' then
        return ESX.GetPlayerFromId(source)
    end
end

function GetPlayerMoney(Player, moneyType)
    if Config.Framework == 'qbcore' then
        return Player.Functions.GetMoney(moneyType or 'cash')
    elseif Config.Framework == 'esx' then
        return Player.getMoney()
    end
end

function RemovePlayerMoney(Player, amount, moneyType)
    if Config.Framework == 'qbcore' then
        return Player.Functions.RemoveMoney(moneyType or 'cash', amount)
    elseif Config.Framework == 'esx' then
        Player.removeMoney(amount)
        return true
    end
end

function GetPlayerIdentifier(Player)
    if Config.Framework == 'qbcore' then
        return Player.PlayerData.citizenid
    elseif Config.Framework == 'esx' then
        return Player.identifier
    end
end

function GetPlayerCharInfo(Player)
    if Config.Framework == 'qbcore' then
        return {
            firstname = Player.PlayerData.charinfo.firstname,
            lastname = Player.PlayerData.charinfo.lastname,
            birthdate = Player.PlayerData.charinfo.birthdate
        }
    elseif Config.Framework == 'esx' then
        return {
            firstname = Player.get('firstName') or 'John',
            lastname = Player.get('lastName') or 'Doe',
            birthdate = Player.get('dateofbirth') or '01/01/1990'
        }
    end
end

function GetPlayerSource(Player)
    if Config.Framework == 'qbcore' then
        return Player.PlayerData.source
    elseif Config.Framework == 'esx' then
        return Player.source
    end
end

function AddLicense(Player, licenseType)
    local source = GetPlayerSource(Player)
    
    if Config.Framework == 'qbcore' then
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
    elseif Config.Framework == 'esx' then
        -- ESX license system
        MySQL.Async.execute('INSERT INTO user_licenses (type, owner) VALUES (@type, @owner) ON DUPLICATE KEY UPDATE type = @type', {
            ['@type'] = licenseType,
            ['@owner'] = Player.identifier
        })
    end
    
    -- Give physical item using inventory system
    local itemName = Config.LicenseItems[licenseType]
    if itemName then
        local charInfo = GetPlayerCharInfo(Player)
        local licenseData = {
            firstname = charInfo.firstname,
            lastname = charInfo.lastname,
            birthdate = charInfo.birthdate,
            type = licenseType,
            issued = os.date('%m-%d-%Y'),
            expires = os.date('%m-%d-%Y', os.time() + (365 * 24 * 60 * 60))
        }
        
        Inventory.AddItem(source, Player, itemName, 1, licenseData)
    end
end

function HasLicense(Player, licenseType, cb)
    if Config.Framework == 'qbcore' then
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
    elseif Config.Framework == 'esx' then
        MySQL.Async.fetchAll('SELECT * FROM user_licenses WHERE type = @type AND owner = @owner', {
            ['@type'] = licenseType,
            ['@owner'] = Player.identifier
        }, function(result)
            cb(#result > 0)
        end)
    end
end

function RemoveLicense(Player, licenseType)
    local source = GetPlayerSource(Player)
    
    if Config.Framework == 'qbcore' then
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
    elseif Config.Framework == 'esx' then
        MySQL.Async.execute('DELETE FROM user_licenses WHERE type = @type AND owner = @owner', {
            ['@type'] = licenseType,
            ['@owner'] = Player.identifier
        })
    end
    
    -- Remove physical item
    local itemName = Config.LicenseItems[licenseType]
    if itemName then
        Inventory.RemoveItem(source, Player, itemName, 1)
    end
end

function ShowNotification(source, message, type)
    if Config.Framework == 'qbcore' then
        TriggerClientEvent('QBCore:Notify', source, message, type or 'primary')
    elseif Config.Framework == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
    end
end

-- Track test states to prevent multiple notifications
local testStates = {}

-- Events
RegisterNetEvent('sd-drivingschool:server:startWrittenTest', function(licenseType)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is already in a test
    if testStates[src] then
        ShowNotification(src, 'You are already taking a test!', 'error')
        return
    end
    
    local licenseData = Config.Licenses[licenseType]
    if not licenseData or not licenseData.enabled or not licenseData.writtenTest then
        ShowNotification(src, 'This test is not available!', 'error')
        return
    end
    
    -- Check if player has enough money
    local playerMoney = GetPlayerMoney(Player, 'cash')
    if playerMoney < licenseData.price then
        ShowNotification(src, 'You don\'t have enough money! You need $' .. licenseData.price, 'error')
        return
    end
    
    -- Check if player already has license
    HasLicense(Player, licenseType, function(hasLicense)
        if hasLicense then
            ShowNotification(src, 'You already have this license!', 'error')
            return
        end
        
        -- Remove money and start test
        if RemovePlayerMoney(Player, licenseData.price, 'cash') then
            testStates[src] = { type = 'written', licenseType = licenseType }
            local questions = Config.WrittenQuestions[licenseType]
            TriggerClientEvent('sd-drivingschool:client:displayWrittenTest', src, licenseType, questions)
            ShowNotification(src, 'Written test started! You paid $' .. licenseData.price, 'success')
        else
            ShowNotification(src, 'Payment failed!', 'error')
        end
    end)
end)

RegisterNetEvent('sd-drivingschool:server:finishWrittenTest', function(licenseType, passed, score)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player was actually taking this test
    if not testStates[src] or testStates[src].type ~= 'written' or testStates[src].licenseType ~= licenseType then
        return
    end
    
    -- Clear test state
    testStates[src] = nil
    
    if passed then
        ShowNotification(src, 'Congratulations! You passed the written test with a score of ' .. math.floor(score) .. '%!', 'success')
        
        -- If driving test is disabled, give license immediately
        local licenseData = Config.Licenses[licenseType]
        if not licenseData.drivingTest then
            AddLicense(Player, licenseType)
            ShowNotification(src, 'You have received your ' .. licenseData.name .. '!', 'success')
        else
            ShowNotification(src, 'You can now take the driving test!', 'primary')
        end
    else
        ShowNotification(src, 'You failed the written test with a score of ' .. math.floor(score) .. '%. Try again!', 'error')
    end
end)

RegisterNetEvent('sd-drivingschool:server:startDrivingTest', function(licenseType)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is already in a test
    if testStates[src] then
        ShowNotification(src, 'You are already taking a test!', 'error')
        return
    end
    
    local licenseData = Config.Licenses[licenseType]
    if not licenseData or not licenseData.enabled or not licenseData.drivingTest then
        ShowNotification(src, 'This test is not available!', 'error')
        return
    end
    
    -- Check if player already has license
    HasLicense(Player, licenseType, function(hasLicense)
        if hasLicense then
            ShowNotification(src, 'You already have this license!', 'error')
            return
        end
        
        -- If written test is required, check if they need to pay again
        if not licenseData.writtenTest then
            local playerMoney = GetPlayerMoney(Player, 'cash')
            if playerMoney < licenseData.price then
                ShowNotification(src, 'You don\'t have enough money! You need $' .. licenseData.price, 'error')
                return
            end
            
            if not RemovePlayerMoney(Player, licenseData.price, 'cash') then
                ShowNotification(src, 'Payment failed!', 'error')
                return
            end
            
            ShowNotification(src, 'Driving test started! You paid $' .. licenseData.price, 'success')
        end
        
        testStates[src] = { type = 'driving', licenseType = licenseType }
        TriggerClientEvent('sd-drivingschool:client:beginDrivingTest', src, licenseType)
    end)
end)

RegisterNetEvent('sd-drivingschool:server:finishDrivingTest', function(licenseType, passed, score)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player was actually taking this test
    if not testStates[src] or testStates[src].type ~= 'driving' or testStates[src].licenseType ~= licenseType then
        return
    end
    
    -- Clear test state
    testStates[src] = nil
    
    if passed then
        AddLicense(Player, licenseType)
        local licenseData = Config.Licenses[licenseType]
        ShowNotification(src, 'Congratulations! You passed the driving test with a score of ' .. math.floor(score) .. '% and received your ' .. licenseData.name .. '!', 'success')
        
        -- Log the license acquisition
        if Config.Debug then
            print('^2[SD-DrivingSchool]^0 Player ' .. GetPlayerName(src) .. ' obtained ' .. licenseType .. ' license')
        end
    else
        ShowNotification(src, 'You failed the driving test with a score of ' .. math.floor(score) .. '%. Try again!', 'error')
    end
end)

RegisterNetEvent('sd-drivingschool:server:buyReplacement', function(licenseType)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    local licenseData = Config.Licenses[licenseType]
    if not licenseData or not licenseData.enabled then
        ShowNotification(src, 'This license type is not available!', 'error')
        return
    end
    
    -- Check if player has enough money
    local playerMoney = GetPlayerMoney(Player, 'cash')
    if playerMoney < Config.ReplacementCost then
        ShowNotification(src, 'You don\'t have enough money! You need $' .. Config.ReplacementCost, 'error')
        return
    end
    
    -- Check if player actually has the license
    HasLicense(Player, licenseType, function(hasLicense)
        if not hasLicense then
            ShowNotification(src, 'You don\'t have this license to replace!', 'error')
            return
        end
        
        -- Remove money and give replacement item
        if RemovePlayerMoney(Player, Config.ReplacementCost, 'cash') then
            local itemName = Config.LicenseItems[licenseType]
            
            if itemName then
                local charInfo = GetPlayerCharInfo(Player)
                local licenseData = {
                    firstname = charInfo.firstname,
                    lastname = charInfo.lastname,
                    birthdate = charInfo.birthdate,
                    type = licenseType,
                    issued = os.date('%m-%d-%Y'),
                    expires = os.date('%m-%d-%Y', os.time() + (365 * 24 * 60 * 60))
                }
                
                Inventory.AddItem(src, Player, itemName, 1, licenseData)
                ShowNotification(src, 'Replacement ' .. Config.Licenses[licenseType].name .. ' purchased for $' .. Config.ReplacementCost .. '!', 'success')
                
                -- Log the replacement
                if Config.Debug then
                    print('^2[SD-DrivingSchool]^0 Player ' .. GetPlayerName(src) .. ' bought replacement ' .. licenseType .. ' license')
                end
            else
                ShowNotification(src, 'Error processing replacement license!', 'error')
            end
        else
            ShowNotification(src, 'Payment failed!', 'error')
        end
    end)
end)

-- Clean up test states when player disconnects
AddEventHandler('playerDropped', function()
    local src = source
    if testStates[src] then
        testStates[src] = nil
    end
end)

-- Admin Commands
if Config.Framework == 'qbcore' then
    QBCore.Commands.Add('givelicense', 'Give a player a driving license (Admin Only)', {
        {name = 'id', help = 'Player ID'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)'}
    }, true, function(source, args)
        local targetId = tonumber(args[1])
        local licenseType = args[2]
        
        if not targetId or not licenseType then
            ShowNotification(source, 'Invalid arguments!', 'error')
            return
        end
        
        if not Config.Licenses[licenseType] then
            ShowNotification(source, 'Invalid license type!', 'error')
            return
        end
        
        local targetPlayer = GetPlayer(targetId)
        if not targetPlayer then
            ShowNotification(source, 'Player not found!', 'error')
            return
        end
        
        AddLicense(targetPlayer, licenseType)
        ShowNotification(source, 'License given successfully!', 'success')
        ShowNotification(targetId, 'You have been given a ' .. Config.Licenses[licenseType].name .. '!', 'success')
    end, 'admin')
    
    QBCore.Commands.Add('removelicense', 'Remove a player\'s driving license (Admin Only)', {
        {name = 'id', help = 'Player ID'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)'}
    }, true, function(source, args)
        local targetId = tonumber(args[1])
        local licenseType = args[2]
        
        if not targetId or not licenseType then
            ShowNotification(source, 'Invalid arguments!', 'error')
            return
        end
        
        local targetPlayer = GetPlayer(targetId)
        if not targetPlayer then
            ShowNotification(source, 'Player not found!', 'error')
            return
        end
        
        RemoveLicense(targetPlayer, licenseType)
        ShowNotification(source, 'License removed successfully!', 'success')
        ShowNotification(targetId, 'Your ' .. Config.Licenses[licenseType].name .. ' has been removed!', 'error')
    end, 'admin')
    
    QBCore.Commands.Add('givereplacement', 'Give a player a replacement license (Admin Only)', {
        {name = 'id', help = 'Player ID'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)'}
    }, true, function(source, args)
        local targetId = tonumber(args[1])
        local licenseType = args[2]
        
        if not targetId or not licenseType then
            ShowNotification(source, 'Invalid arguments!', 'error')
            return
        end
        
        if not Config.Licenses[licenseType] then
            ShowNotification(source, 'Invalid license type!', 'error')
            return
        end
        
        local targetPlayer = GetPlayer(targetId)
        if not targetPlayer then
            ShowNotification(source, 'Player not found!', 'error')
            return
        end
        
        HasLicense(targetPlayer, licenseType, function(hasLicense)
            if not hasLicense then
                ShowNotification(source, 'Player doesn\'t have this license to replace!', 'error')
                return
            end
            
            local itemName = Config.LicenseItems[licenseType]
            if itemName then
                local charInfo = GetPlayerCharInfo(targetPlayer)
                local licenseData = {
                    firstname = charInfo.firstname,
                    lastname = charInfo.lastname,
                    birthdate = charInfo.birthdate,
                    type = licenseType,
                    issued = os.date('%m-%d-%Y'),
                    expires = os.date('%m-%d-%Y', os.time() + (365 * 24 * 60 * 60))
                }
                
                Inventory.AddItem(targetId, targetPlayer, itemName, 1, licenseData)
                ShowNotification(source, 'Replacement license given successfully!', 'success')
                ShowNotification(targetId, 'You have been given a replacement ' .. Config.Licenses[licenseType].name .. '!', 'success')
            end
        end)
    end, 'admin')
elseif Config.Framework == 'esx' then
    ESX.RegisterCommand('givelicense', 'admin', function(xPlayer, args, showError)
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
        
        local targetPlayer = ESX.GetPlayerFromId(targetId)
        if not targetPlayer then
            xPlayer.showNotification('Player not found!')
            return
        end
        
        AddLicense(targetPlayer, licenseType)
        xPlayer.showNotification('License given successfully!')
        targetPlayer.showNotification('You have been given a ' .. Config.Licenses[licenseType].name .. '!')
    end, true, {help = 'Give a player a driving license', validate = true, arguments = {
        {name = 'id', help = 'Player ID', type = 'number'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)', type = 'string'}
    }})
    
    ESX.RegisterCommand('removelicense', 'admin', function(xPlayer, args, showError)
        local targetId = tonumber(args.id)
        local licenseType = args.type
        
        if not targetId or not licenseType then
            xPlayer.showNotification('Invalid arguments!')
            return
        end
        
        local targetPlayer = ESX.GetPlayerFromId(targetId)
        if not targetPlayer then
            xPlayer.showNotification('Player not found!')
            return
        end
        
        RemoveLicense(targetPlayer, licenseType)
        xPlayer.showNotification('License removed successfully!')
        targetPlayer.showNotification('Your ' .. Config.Licenses[licenseType].name .. ' has been removed!')
    end, true, {help = 'Remove a player\'s driving license', validate = true, arguments = {
        {name = 'id', help = 'Player ID', type = 'number'},
        {name = 'type', help = 'License type (regular/cdl/motorcycle)', type = 'string'}
    }})
end

-- Database setup for ESX
if Config.Framework == 'esx' and Config.Inventory == 'esx_default' and Config.InventorySettings.esx_default.useDatabase then
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

-- Startup message
Citizen.CreateThread(function()
    Wait(1000)
    print('^2[SD-DrivingSchool]^0 Successfully loaded with framework: ^3' .. Config.Framework .. '^0')
    print('^2[SD-DrivingSchool]^0 Using inventory system: ^3' .. Config.Inventory .. '^0')
    print('^2[SD-DrivingSchool]^0 Replacement cost: $' .. Config.ReplacementCost)
    print('^2[SD-DrivingSchool]^0 Created by Shawns Developments')
end)
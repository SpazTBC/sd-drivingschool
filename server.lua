-- Framework Bridge
local FrameworkBridge = {}

if Config.Framework == 'qbx' then
    FrameworkBridge = QBX
elseif Config.Framework == 'qbcore' then
    FrameworkBridge = QB
elseif Config.Framework == 'esx' then
    FrameworkBridge = ESX
end

-- Helper Functions
function GetPlayer(source)
    return FrameworkBridge.GetPlayer(source)
end

function GetPlayerMoney(Player, moneyType)
    return FrameworkBridge.GetPlayerMoney(Player, moneyType)
end

function RemovePlayerMoney(Player, amount, moneyType)
    return FrameworkBridge.RemovePlayerMoney(Player, amount, moneyType)
end

function GetPlayerIdentifier(Player)
    return FrameworkBridge.GetPlayerIdentifier(Player)
end

function GetPlayerCharInfo(Player)
    return FrameworkBridge.GetPlayerCharInfo(Player)
end

function GetPlayerSource(Player)
    return FrameworkBridge.GetPlayerSource(Player)
end

function AddLicense(Player, licenseType)
    FrameworkBridge.AddLicense(Player, licenseType)
end

function HasLicense(Player, licenseType, cb)
    FrameworkBridge.HasLicense(Player, licenseType, cb)
end

function RemoveLicense(Player, licenseType)
    FrameworkBridge.RemoveLicense(Player, licenseType)
end

function ShowNotification(source, message, type)
    FrameworkBridge.ShowNotification(source, message, type)
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
FrameworkBridge.RegisterAdminCommands()

-- Database setup for ESX
if Config.Framework == 'esx' then
    FrameworkBridge.SetupDatabase()
end

-- Startup message
Citizen.CreateThread(function()
    Wait(1000)
    print('^2[SD-DrivingSchool]^0 Successfully loaded with framework: ^3' .. Config.Framework .. '^0')
    print('^2[SD-DrivingSchool]^0 Using inventory system: ^3' .. Config.Inventory .. '^0')
    print('^2[SD-DrivingSchool]^0 Replacement cost: $' .. Config.ReplacementCost)
    print('^2[SD-DrivingSchool]^0 Created by Shawns Developments')
end)
Framework = {}

if Config.Framework == 'auto' then
    if GetResourceState('qb-core') == 'started' then
        Config.Framework = 'qbcore'
    elseif GetResourceState('es_extended') == 'started' then
        Config.Framework = 'esx'
    else
        print('^1[SD-DrivingSchool] No supported framework detected!^0')
    end
end

function Framework.GetFramework()
    if Config.Framework == 'qbcore' then
        return exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'esx' then
        return exports['es_extended']:getSharedObject()
    end
    return nil
end

function Framework.ShowNotification(message, type)
    if Config.Framework == 'qbcore' then
        TriggerEvent('QBCore:Notify', message, type or 'primary')
    elseif Config.Framework == 'esx' then
        TriggerEvent('esx:showNotification', message)
    end
end

function Framework.GetPlayerData()
    if Config.Framework == 'qbcore' then
        local QBCore = Framework.GetFramework()
        return QBCore.Functions.GetPlayerData()
    elseif Config.Framework == 'esx' then
        local ESX = Framework.GetFramework()
        return ESX.GetPlayerData()
    end
    return nil
end
local currentTest = nil
local testVehicle = nil
local testBlips = {}
local testState = {
    score = 100,
    currentCheckpoint = 1,
    startTime = 0
}

-- Framework Bridge
local FrameworkBridge = {}

if Config.Framework == 'qbx' then
    FrameworkBridge = QBX
elseif Config.Framework == 'qbcore' then
    FrameworkBridge = QB
elseif Config.Framework == 'esx' then
    FrameworkBridge = ESX
end

-- Check if player has license
function HasLicense(licenseType, cb)
    if Config.Framework == 'qbx' or Config.Framework == 'qbcore' then
        local PlayerData = FrameworkBridge.GetPlayerData()
        local licenseMap = {
            regular = 'driver',
            cdl = 'cdl',
            motorcycle = 'motorcycle'
        }
        
        local qbLicenseType = licenseMap[licenseType]
        local hasLicense = false
        
        if qbLicenseType and PlayerData.metadata and PlayerData.metadata.licences then
            hasLicense = PlayerData.metadata.licences[qbLicenseType] == true
        end
        
        cb(hasLicense)
    else
        -- For ESX, check via server event
        TriggerServerEvent('sd-drivingschool:server:checkLicense', licenseType, cb)
    end
end

-- Open Driving School Menu
function OpenDrivingSchoolMenu()
    local menuItems = {}
    local licensesToCheck = {'regular', 'cdl', 'motorcycle'}
    local checkedCount = 0
    
    -- Check each license type
    for _, licenseType in ipairs(licensesToCheck) do
        HasLicense(licenseType, function(hasLicense)
            checkedCount = checkedCount + 1
            
            local licenseData = Config.Licenses[licenseType]
            if licenseData and licenseData.enabled then
                if hasLicense then
                    -- Player has license - show replacement option
                    table.insert(menuItems, {
                        header = "🔄 Get Replacement " .. licenseData.name,
                        txt = "Cost: $" .. Config.ReplacementCost .. " | You already have this license",
                        params = {
                            event = "sd-drivingschool:client:buyReplacement",
                            args = {
                                licenseType = licenseType
                            }
                        }
                    })
                else
                    -- Player doesn't have license - show test options
                    local subMenu = {}
                    
                    if licenseData.writtenTest then
                        table.insert(subMenu, {
                            header = "📝 Written Test",
                            txt = "Take the written portion of the test",
                            params = {
                                event = "sd-drivingschool:client:startWrittenTest",
                                args = {
                                    licenseType = licenseType
                                }
                            }
                        })
                    end
                    
                    if licenseData.drivingTest then
                        table.insert(subMenu, {
                            header = "🚗 Driving Test", 
                            txt = "Take the practical driving test",
                            params = {
                                event = "sd-drivingschool:client:startDrivingTest",
                                args = {
                                    licenseType = licenseType
                                }
                            }
                        })
                    end
                    
                    table.insert(subMenu, {
                        header = "⬅️ Back",
                        params = {
                            event = "sd-drivingschool:client:openMenu"
                        }
                    })
                    
                    table.insert(menuItems, {
                        header = "📋 " .. licenseData.name,
                        txt = "Cost: $" .. licenseData.price .. " | Required Score: " .. licenseData.requiredScore .. "%",
                        params = {
                            event = "sd-drivingschool:client:openSubMenu",
                            args = {
                                licenseType = licenseType,
                                subMenu = subMenu,
                                title = licenseData.name
                            }
                        }
                    })
                end
            end
            
            -- When all licenses have been checked, show the menu
            if checkedCount == #licensesToCheck then
                table.insert(menuItems, {
                    header = "❌ Close",
                    params = {
                        event = "qb-menu:client:closeMenu"
                    }
                })
                
                FrameworkBridge.ShowMenu({
                    {
                        header = "🏫 Driving School",
                        isMenuHeader = true,
                        txt = "Welcome to the Driving School!"
                    },
                    table.unpack(menuItems)
                })
            end
        end)
    end
end

-- Open Sub Menu
RegisterNetEvent('sd-drivingschool:client:openSubMenu', function(data)
    local subMenuItems = {
        {
            header = "🏫 " .. data.title,
            isMenuHeader = true,
            txt = "Choose your test type"
        }
    }
    
    for _, item in ipairs(data.subMenu) do
        table.insert(subMenuItems, item)
    end
    
    FrameworkBridge.ShowMenu(subMenuItems)
end)

-- Buy Replacement License
RegisterNetEvent('sd-drivingschool:client:buyReplacement', function(data)
    local licenseType = data.licenseType
    local licenseData = Config.Licenses[licenseType]
    
    FrameworkBridge.CloseMenu()
    
    -- Confirm purchase
    local confirmMenu = {
        {
            header = "🔄 Replacement " .. licenseData.name,
            isMenuHeader = true,
            txt = "Confirm your replacement license purchase"
        },
        {
            header = "✅ Confirm Purchase",
            txt = "Cost: $" .. Config.ReplacementCost,
            params = {
                event = "sd-drivingschool:client:confirmReplacement",
                args = {
                    licenseType = licenseType
                }
            }
        },
        {
            header = "❌ Cancel",
            params = {
                event = "sd-drivingschool:client:openMenu"
            }
        }
    }
    
    FrameworkBridge.ShowMenu(confirmMenu)
end)

-- Confirm Replacement Purchase
RegisterNetEvent('sd-drivingschool:client:confirmReplacement', function(data)
    FrameworkBridge.CloseMenu()
    TriggerServerEvent('sd-drivingschool:server:buyReplacement', data.licenseType)
end)

-- Open Main Menu
RegisterNetEvent('sd-drivingschool:client:openMenu', function()
    OpenDrivingSchoolMenu()
end)

-- Start Written Test
RegisterNetEvent('sd-drivingschool:client:startWrittenTest', function(data)
    FrameworkBridge.CloseMenu()
    TriggerServerEvent('sd-drivingschool:server:startWrittenTest', data.licenseType)
end)

-- Start Driving Test  
RegisterNetEvent('sd-drivingschool:client:startDrivingTest', function(data)
    FrameworkBridge.CloseMenu()
    TriggerServerEvent('sd-drivingschool:server:startDrivingTest', data.licenseType)
end)

-- Display Written Test
RegisterNetEvent('sd-drivingschool:client:displayWrittenTest', function(licenseType, questions)
    currentTest = {
        type = 'written',
        licenseType = licenseType,
        questions = questions,
        currentQuestion = 1,
        correctAnswers = 0,
        totalQuestions = #questions
    }
    
    ShowWrittenQuestion()
end)

-- Show Written Question
function ShowWrittenQuestion()
    if not currentTest or currentTest.currentQuestion > currentTest.totalQuestions then
        return
    end
    
    local question = currentTest.questions[currentTest.currentQuestion]
    local menuItems = {
        {
            header = "📝 Written Test - Question " .. currentTest.currentQuestion .. "/" .. currentTest.totalQuestions,
            isMenuHeader = true,
            txt = question.question
        }
    }
    
    for i, answer in ipairs(question.answers) do
        table.insert(menuItems, {
            header = string.char(64 + i) .. ") " .. answer,
            params = {
                event = "sd-drivingschool:client:answerQuestion",
                args = {
                    questionIndex = currentTest.currentQuestion,
                    answerIndex = i,
                    correct = (i == question.correct)
                }
            }
        })
    end
    
    FrameworkBridge.ShowMenu(menuItems)
end

-- Answer Question
RegisterNetEvent('sd-drivingschool:client:answerQuestion', function(data)
    if not currentTest then return end
    
    if data.correct then
        currentTest.correctAnswers = currentTest.correctAnswers + 1
    end
    
    currentTest.currentQuestion = currentTest.currentQuestion + 1
    
    if currentTest.currentQuestion > currentTest.totalQuestions then
        -- Test finished
        local score = (currentTest.correctAnswers / currentTest.totalQuestions) * 100
        local licenseData = Config.Licenses[currentTest.licenseType]
        local passed = score >= licenseData.requiredScore
        
        FrameworkBridge.CloseMenu()
        TriggerServerEvent('sd-drivingschool:server:finishWrittenTest', currentTest.licenseType, passed, score)
        currentTest = nil
    else
        -- Next question
        ShowWrittenQuestion()
    end
end)

-- Begin Driving Test
RegisterNetEvent('sd-drivingschool:client:beginDrivingTest', function(licenseType)
    local licenseData = Config.Licenses[licenseType]
    if not licenseData then return end
    
    currentTest = {
        type = 'driving',
        licenseType = licenseType,
        data = licenseData
    }
    
    StartDrivingTest()
end)

-- Start Driving Test
function StartDrivingTest()
    if not currentTest then return end
    
    local licenseData = currentTest.data
    local spawnCoords = licenseData.spawnLocation
    
    -- Reset test state
    testState.score = Config.DrivingScoring.startingScore
    testState.currentCheckpoint = 1
    testState.startTime = GetGameTimer()
    
    -- Spawn vehicle
    if Config.Framework == 'qbx' or Config.Framework == 'qbcore' then
        FrameworkBridge.SpawnVehicle(licenseData.vehicle, function(veh)
            testVehicle = veh
            SetPedIntoVehicle(PlayerPedId(), veh, -1)
            SetEntityHeading(veh, spawnCoords.w)
            SetVehicleEngineOn(veh, true, true, false)
            SetVehicleOnGroundProperly(veh)
            
            -- Create route blips
            CreateRouteBlips(licenseData.testRoute)
            
            -- Start monitoring
            StartDrivingTestMonitoring()
            
            TriggerEvent('QBCore:Notify', 'Driving test started! Follow the checkpoints and drive safely.', 'success')
        end, spawnCoords, true)
    else
        -- For ESX, use different spawn method
        TriggerServerEvent('sd-drivingschool:server:spawnVehicle', licenseData.vehicle, spawnCoords)
    end
end

-- Create Route Blips
function CreateRouteBlips(route)
    for i, checkpoint in ipairs(route) do
        local blip = AddBlipForCoord(checkpoint.x, checkpoint.y, checkpoint.z)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, i == 1 and 2 or 5)
        SetBlipScale(blip, 0.8)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Checkpoint " .. i)
        EndTextCommandSetBlipName(blip)
        table.insert(testBlips, blip)
    end
end

-- Start Driving Test Monitoring
function StartDrivingTestMonitoring()
    Citizen.CreateThread(function()
        while currentTest and currentTest.type == 'driving' do
            if testVehicle and DoesEntityExist(testVehicle) then
                local playerPed = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                
                if vehicle == testVehicle then
                    -- Check speed
                    local speed = GetEntitySpeed(vehicle) * 2.237 -- Convert to MPH
                    if speed > Config.DrivingScoring.maxSpeed then
                        testState.score = testState.score - Config.DrivingScoring.speedingPenalty
                        Framework.ShowNotification('Speeding! Points deducted.', 'error')
                        Citizen.Wait(2000) -- Prevent spam
                    end
                    
                    -- Check for crashes
                    if HasEntityCollidedWithAnything(vehicle) then
                        testState.score = testState.score - Config.DrivingScoring.crashPenalty
                        Framework.ShowNotification('Collision! Points deducted.', 'error')
                        Citizen.Wait(1000)
                    end
                    
                    -- Check checkpoints
                    CheckTestCheckpoints()
                    
                    -- Check time limit
                    local timeElapsed = (GetGameTimer() - testState.startTime) / 1000
                    if timeElapsed > currentTest.data.timeLimit then
                        EndDrivingTest(false, 'Time limit exceeded!')
                        break
                    end
                else
                    EndDrivingTest(false, 'You left the test vehicle!')
                    break
                end
            else
                EndDrivingTest(false, 'Test vehicle was destroyed!')
                break
            end
            
            Citizen.Wait(500)
        end
    end)
end

-- Check Test Checkpoints
function CheckTestCheckpoints()
    if not currentTest or testState.currentCheckpoint > #currentTest.data.testRoute then
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local checkpoint = currentTest.data.testRoute[testState.currentCheckpoint]
    local distance = #(playerCoords - vector3(checkpoint.x, checkpoint.y, checkpoint.z))
    
    if distance < 15.0 then
        -- Remove current checkpoint blip
        if testBlips[testState.currentCheckpoint] then
            RemoveBlip(testBlips[testState.currentCheckpoint])
        end
        
        testState.currentCheckpoint = testState.currentCheckpoint + 1
        
        if testState.currentCheckpoint > #currentTest.data.testRoute then
            -- Test completed
            local passed = testState.score >= currentTest.data.requiredScore
            EndDrivingTest(passed, passed and 'Test completed successfully!' or 'Test completed but score too low.')
        else
            Framework.ShowNotification('Checkpoint reached! Go to the next one.', 'success')
        end
    end
end

-- End Driving Test
function EndDrivingTest(passed, reason)
    if not currentTest then return end
    
    -- Clean up
    if testVehicle and DoesEntityExist(testVehicle) then
        DeleteEntity(testVehicle)
    end
    
    for _, blip in ipairs(testBlips) do
        RemoveBlip(blip)
    end
    testBlips = {}
    
    -- Send result to server
    TriggerServerEvent('sd-drivingschool:server:finishDrivingTest', currentTest.licenseType, passed, testState.score)
    
    Framework.ShowNotification(reason, passed and 'success' or 'error')
    
    currentTest = nil
    testVehicle = nil
end

-- Ped Interaction
Citizen.CreateThread(function()
    if Config.DrivingSchool.ped.enabled then
        local pedModel = Config.DrivingSchool.ped.model
        local pedCoords = Config.DrivingSchool.ped.coords
        
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Wait(1)
        end
        
        local ped = CreatePed(4, pedModel, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, true)
        SetEntityHeading(ped, pedCoords.w)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        -- Add interaction
        if Config.Target == 'ox_target' then
            Framework.AddTargetEntity(ped, {
                {
                    event = "sd-drivingschool:client:openMenu",
                    icon = "fas fa-car",
                    label = "Talk to Driving Instructor",
                }
            })
        elseif Config.Target == 'qb-target' then
            Framework.AddTargetEntity(ped, {
                options = {
                    {
                        type = "client",
                        event = "sd-drivingschool:client:openMenu",
                        icon = "fas fa-car",
                        label = "Talk to Driving Instructor",
                    },
                },
                distance = 3.0
            })
        end
    end
end)

-- Blip Creation
Citizen.CreateThread(function()
    if Config.DrivingSchool.blip.enabled then
        local blip = AddBlipForCoord(Config.DrivingSchool.coords.x, Config.DrivingSchool.coords.y, Config.DrivingSchool.coords.z)
        SetBlipSprite(blip, Config.DrivingSchool.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.DrivingSchool.blip.scale)
        SetBlipColour(blip, Config.DrivingSchool.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.DrivingSchool.blip.name)
        EndTextCommandSetBlipName(blip)
    end
end)
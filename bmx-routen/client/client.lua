ESX = nil
local isProcessing = false
local spawnedNPCs = {}
local esxLoaded = false

local actions = {
    washing = false,
    collecting = false,
    processing = false,
    selling = false
}

local currentRoute = nil
local currentProp = nil

function IsPlayerInVehicle()
    return IsPedInAnyVehicle(PlayerPedId(), false)
end

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end

    while not ESX.IsPlayerLoaded() do
        Citizen.Wait(100)
    end

    esxLoaded = true

    Citizen.Wait(2000)

    SpawnAllNPCs()

    CreateAllBlips()
end)

Citizen.CreateThread(function()
    Citizen.Wait(30000)

    if esxLoaded and GetTableLength(spawnedNPCs) == 0 then
        SpawnAllNPCs()
    end
end)

function SpawnAllNPCs()
    if Config.MoneyWash.Enabled then
        SpawnNPC(Config.MoneyWash.NPC, 'moneywash', 'Geldwäscher')
    end

    for routeName, routeData in pairs(Config.Routes) do
        if routeData.Enabled then
            if routeData.Seller and routeData.Seller.NPC then
                SpawnNPC(routeData.Seller.NPC, routeName .. '_seller', routeData.Seller.Label)
            end
        end
    end
end

function SpawnNPC(npcConfig, id, label)
    Citizen.CreateThread(function()
        local pedModel = GetHashKey(npcConfig.model)

        RequestModel(pedModel)

        local waitCount = 0
        while not HasModelLoaded(pedModel) and waitCount < 100 do
            Citizen.Wait(10)
            waitCount = waitCount + 1
        end

        if not HasModelLoaded(pedModel) then
            return
        end

        if not npcConfig.coords or not npcConfig.coords.x then
            return
        end

        local npcPed = CreatePed(4, pedModel, npcConfig.coords.x, npcConfig.coords.y, npcConfig.coords.z - 1.0, npcConfig.heading, false, true)

        if not DoesEntityExist(npcPed) then
            return
        end

        SetEntityAsMissionEntity(npcPed, true, true)
        SetPedFleeAttributes(npcPed, 0, 0)
        SetBlockingOfNonTemporaryEvents(npcPed, true)
        SetPedCanPlayAmbientAnims(npcPed, true)
        SetPedCanRagdollFromPlayerImpact(npcPed, false)
        SetEntityInvincible(npcPed, true)
        FreezeEntityPosition(npcPed, true)

        TaskStartScenarioInPlace(npcPed, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

        spawnedNPCs[id] = npcPed

        SetModelAsNoLongerNeeded(pedModel)
    end)
end

function GetTableLength(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

function CreateAllBlips()
    for routeName, routeData in pairs(Config.Routes) do
        if routeData.Enabled then
            if routeData.Collector and routeData.Collector.Blip.Enabled then
                local cfg = routeData.Collector.Blip
                CreateBlip(routeData.Collector.Location.coords, cfg.Sprite, cfg.Color, cfg.Scale, routeData.Collector.Label)
            end

            if routeData.Processor and routeData.Processor.Blip.Enabled then
                local cfg = routeData.Processor.Blip
                CreateBlip(routeData.Processor.Location.coords, cfg.Sprite, cfg.Color, cfg.Scale, routeData.Processor.Label)
            end

            if routeData.Seller and routeData.Seller.Blip.Enabled then
                local cfg = routeData.Seller.Blip
                CreateBlip(routeData.Seller.NPC.coords, cfg.Sprite, cfg.Color, cfg.Scale, routeData.Seller.Label)
            end
        end
    end
end

function CreateBlip(coords, sprite, color, scale, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
end

function CheckBlackMoney()
    if not ESX or not ESX.PlayerData then
        return 0
    end

    if not ESX.PlayerData.accounts or #ESX.PlayerData.accounts == 0 then
        ESX.PlayerData = ESX.GetPlayerData()
    end

    if ESX.PlayerData.accounts then
        for i = 1, #ESX.PlayerData.accounts do
            if ESX.PlayerData.accounts[i].name == 'black_money' then
                return ESX.PlayerData.accounts[i].money
            end
        end
    end

    return 0
end

function StartAnimation(dict, anim, flag)
    local playerPed = PlayerPedId()
    RequestAnimDict(dict)

    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 1000 do
        Citizen.Wait(10)
        timeout = timeout + 10
    end

    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, -1, flag or 1, 0, false, false, false)
    end
end

function StartScenario(scenario)
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    Citizen.Wait(100)
    TaskStartScenarioInPlace(playerPed, scenario, 0, true)
end

function StopAnimation()
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    ClearPedSecondaryTask(playerPed)
    DeleteProp()
end

function KeepAnimationActive(dict, anim, flag)
    local playerPed = PlayerPedId()
    if not IsEntityPlayingAnim(playerPed, dict, anim, 3) then
        TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, -1, flag or 1, 0, false, false, false)
    end
end

function KeepScenarioActive(scenario)
    local playerPed = PlayerPedId()
    if not IsPedUsingAnyScenario(playerPed) then
        ClearPedTasks(playerPed)
        Citizen.Wait(50)
        TaskStartScenarioInPlace(playerPed, scenario, 0, true)
    end
end

function SpawnProp(propName, bone, placement)
    local playerPed = PlayerPedId()
    local x, y, z, xRot, yRot, zRot = table.unpack(placement)

    local propHash = GetHashKey(propName)
    RequestModel(propHash)

    local timeout = 0
    while not HasModelLoaded(propHash) and timeout < 1000 do
        Citizen.Wait(10)
        timeout = timeout + 10
    end

    if HasModelLoaded(propHash) then
        local prop = CreateObject(propHash, 0.0, 0.0, 0.0, true, true, true)
        AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, bone), x, y, z, xRot, yRot, zRot, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(propHash)
        return prop
    end

    return nil
end

function DeleteProp()
    if currentProp then
        DeleteEntity(currentProp)
        currentProp = nil
    end
end

-- Money Washing
function StartMoneyWashing()
    if actions.washing then return end
    if isProcessing then return end
    if IsPlayerInVehicle() then return end

    local currentBlackMoney = CheckBlackMoney()
    if currentBlackMoney <= 0 then
        ESX.ShowNotification("Du hast kein Schwarzgeld zum waschen!")
        return
    end

    actions.washing = true
    ESX.ShowNotification("Geldwäsche gestartet")

    Citizen.CreateThread(function()
        StartAnimation("mp_common", "givetake1_a", 16)

        while actions.washing do
            local blackMoney = CheckBlackMoney()
            if blackMoney <= 0 then
                ESX.ShowNotification("Kein Schwarzgeld mehr übrig!")
                actions.washing = false
                break
            end

            local washAmount = math.min(Config.MoneyWash.WashAmount, blackMoney)
            local cleanMoney = math.floor(washAmount * Config.MoneyWash.WashRate)

            isProcessing = true
            FreezeEntityPosition(PlayerPedId(), true)
            FreezeEntityPosition(PlayerPedId(), false)

            TriggerServerEvent('routes:washMoney', washAmount, cleanMoney)
            isProcessing = false

            if not actions.washing then
                break
            end

            KeepAnimationActive("mp_common", "givetake1_a", 16)
            Citizen.Wait(500)
        end

        FreezeEntityPosition(PlayerPedId(), false)
        StopAnimation()
        ESX.ShowNotification("Geldwäsche abgebrochen")
    end)
end

function StopMoneyWashing()
    actions.washing = false
    if not isProcessing then
        FreezeEntityPosition(PlayerPedId(), false)
        StopAnimation()
        ESX.ShowNotification("Geldwäsche abgebrochen")
    else
        ESX.ShowNotification("Geldwäsche wird nach diesem Vorgang abgebrochen...")
    end
end

-- Collecting
function StartCollecting(routeName, routeData)
    if actions.collecting then return end
    if isProcessing then return end
    if IsPlayerInVehicle() then return end

    if routeData.Collector.RequiredItem then
        local hasItem = false
        ESX.TriggerServerCallback('routes:checkRequiredItem', function(result)
            hasItem = result
        end, routeData.Collector.RequiredItem.name)

        local waitCount = 0
        while hasItem == false and waitCount < 50 do
            Citizen.Wait(10)
            waitCount = waitCount + 1
        end

        if not hasItem then
            ESX.ShowNotification(('Du benötigst: %s'):format(routeData.Collector.RequiredItem.label))
            return
        end
    end

    local inventoryChecked = false
    local canCarry = false

    ESX.TriggerServerCallback('routes:canCarryItems', function(result)
        canCarry = result
        inventoryChecked = true
    end, routeData.Collector.Items)

    while not inventoryChecked do
        Citizen.Wait(10)
    end

    if not canCarry then
        ESX.ShowNotification('Nicht genug Platz im Inventar!')
        return
    end

    actions.collecting = true
    currentRoute = routeName

    ESX.ShowNotification("Beginne zu Sammeln.")

    if routeData.Collector.Animation then
        if routeData.Collector.Animation.type == "scenario" then
            StartScenario(routeData.Collector.Animation.name)
        else
            StartAnimation(routeData.Collector.Animation.dict, routeData.Collector.Animation.anim, routeData.Collector.Animation.flag or 1)

            if routeName == 'mining' and routeData.Collector.Animation.prop then
                currentProp = SpawnProp(
                    routeData.Collector.Animation.prop,
                    routeData.Collector.Animation.propBone,
                    routeData.Collector.Animation.propPlacement
                )
            end
        end
    end

    Citizen.CreateThread(function()
        while actions.collecting do
            local stillHasSpace = false
            ESX.TriggerServerCallback('routes:canCarryItems', function(result)
                stillHasSpace = result
            end, routeData.Collector.Items)

            local checkWait = 0
            while stillHasSpace == false and checkWait < 50 do
                Citizen.Wait(10)
                checkWait = checkWait + 1
            end

            if not stillHasSpace then
                ESX.ShowNotification('Inventar voll! Sammeln wird gestoppt.')
                actions.collecting = false
                break
            end

            isProcessing = true
            FreezeEntityPosition(PlayerPedId(), true)
            FreezeEntityPosition(PlayerPedId(), false)

            TriggerServerEvent('routes:collectItem', routeName)
            isProcessing = false

            if not actions.collecting then
                break
            end

            if routeData.Collector.Animation then
                if routeData.Collector.Animation.type == "scenario" then
                    KeepScenarioActive(routeData.Collector.Animation.name)
                else
                    KeepAnimationActive(routeData.Collector.Animation.dict, routeData.Collector.Animation.anim, routeData.Collector.Animation.flag or 1)
                end
            end

            Citizen.Wait(500)
        end

        FreezeEntityPosition(PlayerPedId(), false)
        StopAnimation()
        currentRoute = nil
    end)
end

function StopCollecting()
    actions.collecting = false
    if not isProcessing then
        FreezeEntityPosition(PlayerPedId(), false)
        StopAnimation()
        currentRoute = nil
    else
        ESX.ShowNotification("Sammeln wird nach diesem Vorgang gestoppt...")
    end
end

-- Processing
function StartProcessing(routeName, routeData)
    if actions.processing then return end
    if isProcessing then return end
    if IsPlayerInVehicle() then return end

    local required = routeData.Processor.RequiredItem

    local inventoryChecked = false
    local canCarry = false

    ESX.TriggerServerCallback('routes:canCarryItem', function(result)
        canCarry = result
        inventoryChecked = true
    end, routeData.Processor.OutputItem.name, routeData.Processor.OutputItem.amount)

    while not inventoryChecked do
        Citizen.Wait(10)
    end

    if not canCarry then
        ESX.ShowNotification('Nicht genug Platz im Inventar!')
        return
    end

    actions.processing = true
    currentRoute = routeName

    ESX.ShowNotification("Verarbeitung gestartet")

    Citizen.CreateThread(function()
        if routeData.Processor.Animation then
            if routeData.Processor.Animation.type == "scenario" then
                StartScenario(routeData.Processor.Animation.name)
            else
                StartAnimation(routeData.Processor.Animation.dict, routeData.Processor.Animation.anim, routeData.Processor.Animation.flag or 1)
            end
        end

        while actions.processing do
            local hasItem = false
            ESX.TriggerServerCallback('routes:checkItem', function(result)
                hasItem = result
            end, required.name, required.amount)

            local waitCount = 0
            while hasItem == false and waitCount < 50 do
                Citizen.Wait(10)
                waitCount = waitCount + 1
            end

            if not hasItem then
                ESX.ShowNotification(('Nicht genug %s übrig!'):format(required.label))
                break
            end

            local stillHasSpace = false
            ESX.TriggerServerCallback('routes:canCarryItem', function(result)
                stillHasSpace = result
            end, routeData.Processor.OutputItem.name, routeData.Processor.OutputItem.amount)

            local checkWait = 0
            while stillHasSpace == false and checkWait < 50 do
                Citizen.Wait(10)
                checkWait = checkWait + 1
            end

            if not stillHasSpace then
                ESX.ShowNotification('Inventar voll! Verarbeitung wird gestoppt.')
                actions.processing = false
                break
            end

            isProcessing = true
            FreezeEntityPosition(PlayerPedId(), true)

            local startTime = GetGameTimer()
            local wasStopped = false

            while GetGameTimer() - startTime < routeData.Processor.ProcessTime do
                Citizen.Wait(100)

                if routeData.Processor.Animation then
                    if routeData.Processor.Animation.type == "scenario" then
                        KeepScenarioActive(routeData.Processor.Animation.name)
                    else
                        KeepAnimationActive(routeData.Processor.Animation.dict, routeData.Processor.Animation.anim, routeData.Processor.Animation.flag or 1)
                    end
                end

                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - routeData.Processor.Location.coords)
                if distance > routeData.Processor.Location.radius then
                    ESX.ShowNotification("Du hast das Verarbeitungsgebiet verlassen!")
                    wasStopped = true
                    break
                end
            end

            if not wasStopped and (GetGameTimer() - startTime) >= routeData.Processor.ProcessTime then
                TriggerServerEvent('routes:processItem', routeName)
            end

            FreezeEntityPosition(PlayerPedId(), false)
            isProcessing = false

            if not actions.processing then
                break
            end

            Citizen.Wait(500)
        end

        FreezeEntityPosition(PlayerPedId(), false)
        StopAnimation()
        actions.processing = false
        currentRoute = nil
        ESX.ShowNotification("Verarbeitung gestoppt")
    end)
end

function StopProcessing()
    actions.processing = false
    if not isProcessing then
        FreezeEntityPosition(PlayerPedId(), false)
        StopAnimation()
        currentRoute = nil
    else
        ESX.ShowNotification("Verarbeitung wird nach diesem Vorgang gestoppt...")
    end
end

-- Selling
function StartSelling(routeName, routeData)
    if actions.selling then return end
    if isProcessing then return end
    if IsPlayerInVehicle() then return end

    actions.selling = true
    currentRoute = routeName

    ESX.ShowNotification("Verkauf gestartet")

    Citizen.CreateThread(function()
        if routeData.Seller.Animation then
            if routeData.Seller.Animation.type == "scenario" then
                StartScenario(routeData.Seller.Animation.name)
            else
                StartAnimation(routeData.Seller.Animation.dict, routeData.Seller.Animation.anim, routeData.Seller.Animation.flag or 16)
            end
        end

        while actions.selling do
            local hasItem = false
            ESX.TriggerServerCallback('routes:checkAnyItem', function(result)
                hasItem = result
            end, routeData.Seller.Items)

            local waitCount = 0
            while hasItem == false and waitCount < 50 do
                Citizen.Wait(10)
                waitCount = waitCount + 1
            end

            if not hasItem then
                ESX.ShowNotification('Keine verkaufbaren Items mehr übrig!')
                break
            end

            isProcessing = true
            FreezeEntityPosition(PlayerPedId(), true)

            local startTime = GetGameTimer()
            local wasStopped = false

            while GetGameTimer() - startTime < routeData.Seller.ProcessTime do
                Citizen.Wait(100)

                if routeData.Seller.Animation then
                    if routeData.Seller.Animation.type == "scenario" then
                        KeepScenarioActive(routeData.Seller.Animation.name)
                    else
                        KeepAnimationActive(routeData.Seller.Animation.dict, routeData.Seller.Animation.anim, routeData.Seller.Animation.flag or 16)
                    end
                end

                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - routeData.Seller.NPC.coords)
                if distance > Config.MaxDistance then
                    ESX.ShowNotification("Du hast dich zu weit entfernt!")
                    wasStopped = true
                    break
                end
            end

            if not wasStopped and (GetGameTimer() - startTime) >= routeData.Seller.ProcessTime then
                TriggerServerEvent('routes:sellItem', routeName)
            end

            FreezeEntityPosition(PlayerPedId(), false)
            isProcessing = false

            if not actions.selling then
                break
            end

            Citizen.Wait(500)
        end

        FreezeEntityPosition(PlayerPedId(), false)
        StopAnimation()
        actions.selling = false
        currentRoute = nil
        ESX.ShowNotification("Verkauf gestoppt")
    end)
end

function StopSelling()
    actions.selling = false
    if not isProcessing then
        FreezeEntityPosition(PlayerPedId(), false)
        StopAnimation()
        currentRoute = nil
    else
        ESX.ShowNotification("Verkauf wird nach diesem Vorgang gestoppt...")
    end
end

-- Main Loop
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearAction = false

        if Config.MoneyWash.Enabled then
            local distance = #(playerCoords - Config.MoneyWash.NPC.coords)

            if distance < 15.0 then
                sleep = 0

                if distance < Config.MoneyWash.InteractionDistance then
                    nearAction = true

                    if not actions.washing then
                        ESX.ShowHelpNotification("Drücke ~INPUT_CONTEXT~ um Geld zu waschen")
                    else
                        ESX.ShowHelpNotification("Drücke ~INPUT_CONTEXT~ um die Geldwäsche zu stoppen")
                    end

                    if IsControlJustReleased(0, 38) then
                        if not actions.washing then
                            StartMoneyWashing()
                        else
                            StopMoneyWashing()
                        end
                    end
                elseif distance < Config.MaxDistance and actions.washing then
                    StopMoneyWashing()
                    ESX.ShowNotification("Du hast dich zu weit entfernt!")
                end
            end
        end

        for routeName, routeData in pairs(Config.Routes) do
            if routeData.Enabled then
                if routeData.Collector then
                    local distance = #(playerCoords - routeData.Collector.Location.coords)

                    if distance < routeData.Collector.Location.radius + 10.0 then
                        sleep = 0

                        if distance < routeData.Collector.Location.radius then
                            nearAction = true

                            if not actions.collecting or currentRoute ~= routeName then
                                ESX.ShowHelpNotification('Drücke ~INPUT_CONTEXT~ um Items zu sammeln')
                            else
                                ESX.ShowHelpNotification('Drücke ~INPUT_CONTEXT~ um das Sammeln zu stoppen')
                            end

                            if IsControlJustReleased(0, 38) then
                                if not actions.collecting then
                                    StartCollecting(routeName, routeData)
                                elseif currentRoute == routeName then
                                    StopCollecting()
                                end
                            end
                        elseif actions.collecting and currentRoute == routeName then
                            if distance > routeData.Collector.Location.radius + 5.0 then
                                StopCollecting()
                                ESX.ShowNotification("Du hast das Sammelgebiet verlassen!")
                            end
                        end
                    end
                end

                if routeData.Processor then
                    local distance = #(playerCoords - routeData.Processor.Location.coords)

                    if distance < routeData.Processor.Location.radius + 10.0 then
                        sleep = 0

                        if distance < routeData.Processor.Location.radius then
                            nearAction = true

                            if not actions.processing or currentRoute ~= routeName then
                                ESX.ShowHelpNotification(('Drücke ~INPUT_CONTEXT~ um %s zu verarbeiten'):format(routeData.Processor.RequiredItem.label))
                            else
                                ESX.ShowHelpNotification('Drücke ~INPUT_CONTEXT~ um die Verarbeitung zu stoppen')
                            end

                            if IsControlJustReleased(0, 38) then
                                if not actions.processing then
                                    StartProcessing(routeName, routeData)
                                elseif currentRoute == routeName then
                                    StopProcessing()
                                end
                            end
                        elseif actions.processing and currentRoute == routeName then
                            if distance > routeData.Processor.Location.radius + 5.0 then
                                StopProcessing()
                                ESX.ShowNotification("Du hast das Verarbeitungsgebiet verlassen!")
                            end
                        end
                    end
                end

                if routeData.Seller then
                    local distance = #(playerCoords - routeData.Seller.NPC.coords)

                    if distance < 15.0 then
                        sleep = 0

                        if distance < routeData.Seller.InteractionDistance then
                            nearAction = true

                            if not actions.selling or currentRoute ~= routeName then
                                ESX.ShowHelpNotification('Drücke ~INPUT_CONTEXT~ um Items zu verkaufen')
                            else
                                ESX.ShowHelpNotification('Drücke ~INPUT_CONTEXT~ um den Verkauf zu stoppen')
                            end

                            if IsControlJustReleased(0, 38) then
                                if not actions.selling then
                                    StartSelling(routeName, routeData)
                                elseif currentRoute == routeName then
                                    StopSelling()
                                end
                            end
                        elseif distance < Config.MaxDistance and actions.selling and currentRoute == routeName then
                            StopSelling()
                            ESX.ShowNotification("Du hast dich zu weit entfernt!")
                        end
                    end
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- Events
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
    if ESX.PlayerData.accounts then
        for i = 1, #ESX.PlayerData.accounts do
            if ESX.PlayerData.accounts[i].name == account.name then
                ESX.PlayerData.accounts[i] = account
                break
            end
        end
    end
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
    actions.washing = false
    actions.collecting = false
    actions.processing = false
    actions.selling = false
    FreezeEntityPosition(PlayerPedId(), false)
    StopAnimation()
end)

RegisterNetEvent('routes:notify')
AddEventHandler('routes:notify', function(msg, type)
    if type == 'error' then
        ESX.ShowNotification('' .. msg)
    elseif type == 'success' then
        ESX.ShowNotification('' .. msg)
    else
        ESX.ShowNotification(msg)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    actions.washing = false
    actions.collecting = false
    actions.processing = false
    actions.selling = false

    FreezeEntityPosition(PlayerPedId(), false)
    StopAnimation()

    for _, npc in pairs(spawnedNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
end)
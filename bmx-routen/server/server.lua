ESX = nil
TriggerEvent('esx:getSharedObject', function(obj)
    ESX = obj
end)

local playerCooldowns = {}

local function IsOnCooldown(source, action, cooldownTime)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return true end

    local identifier = xPlayer.identifier
    if not playerCooldowns[identifier] then
        playerCooldowns[identifier] = {}
    end

    local lastAction = playerCooldowns[identifier][action] or 0
    local currentTime = os.time()

    if currentTime - lastAction < cooldownTime then
        return true
    end

    playerCooldowns[identifier][action] = currentTime
    return false
end

-- Webhooks
local Webhooks = {
    Collect = "", -- Your Webhook here
    Process = "", -- Your Webhook here
    Sell    = "", -- Your Webhook here
    Wash    = ""  -- Your Webhook here
}

function SendLog(webhook, title, message, source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifiers = xPlayer.identifier or "N/A"
    local name = xPlayer.getName() or "Unknown"
    local discord = "N/A"

    for _, v in pairs(GetPlayerIdentifiers(source)) do
        if string.find(v, "discord:") then
            discord = v
        end
    end

    if webhook == nil or webhook == "" then return end

    local embed = {
        username = "Routen System",
        embeds = {{
            color = 0x1A73E8,
            author = {
                name = "" .. title,
                icon_url = ""
            },
            description = "**Aktion:**\n```lua\n" .. message .. "\n```",
            fields = {
                {
                    name = "Spieler",
                    value = "**Name:** " .. name .. "\n**Discord:** " .. discord,
                    inline = true
                },
                {
                    name = "Identifier",
                    value = "```\n" .. identifiers .. "\n```",
                    inline = true
                }
            },
            footer = {
                text = "Routen System • " .. os.date("%d.%m.%Y %H:%M:%S"),
                icon_url = ""
            }
        }}
    }

    PerformHttpRequest(webhook, function() end, "POST", json.encode(embed), {
        ["Content-Type"] = "application/json"
    })
end

-- Geldwäsche
RegisterServerEvent('routes:washMoney')
AddEventHandler('routes:washMoney', function(washAmount, cleanAmount)
    local src = source

    if IsOnCooldown(src, 'wash', 3) then
        TriggerClientEvent('routes:notify', src, 'Zu schnell! Warte kurz.', 'error')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local blackMoneyAccount = xPlayer.getAccount('black_money')
    if not blackMoneyAccount then
        TriggerClientEvent('routes:notify', src, 'Schwarzgeld Konto nicht gefunden!', 'error')
        return
    end

    if blackMoneyAccount.money < washAmount then
        TriggerClientEvent('routes:notify', src, 'Nicht genug Schwarzgeld!', 'error')
        return
    end

    if washAmount <= 0 or washAmount > 100000 then
        TriggerClientEvent('routes:notify', src, 'Ungültiger Betrag!', 'error')
        print(('[Routen-System] CHEAT-VERDACHT: %s versucht ungültigen Betrag zu waschen: $%d'):format(xPlayer.identifier, washAmount))
        return
    end

    xPlayer.removeAccountMoney('black_money', washAmount)
    xPlayer.addMoney(cleanAmount)

    TriggerClientEvent('routes:notify', src, ('Du hast $%d sauberes Geld erhalten!'):format(cleanAmount), 'success')
    SendLog(Webhooks.Wash, "Geldwäsche", ('$%d gewaschen -> $%d sauber'):format(washAmount, cleanAmount), src)

    if Config.Debug then
        print(('[Routen-System] %s wäscht $%d -> $%d'):format(xPlayer.identifier, washAmount, cleanAmount))
    end
end)

-- Sammeln
RegisterServerEvent('routes:collectItem')
AddEventHandler('routes:collectItem', function(routeName)
    local src = source

    if IsOnCooldown(src, 'collect', 2) then
        TriggerClientEvent('routes:notify', src, 'Zu schnell! Warte kurz.', 'error')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local routeData = Config.Routes[routeName]
    if not routeData or not routeData.Enabled then
        TriggerClientEvent('routes:notify', src, 'Route nicht verfügbar!', 'error')
        return
    end

    if routeData.Collector.RequiredItem then
        local toolItem = xPlayer.getInventoryItem(routeData.Collector.RequiredItem.name)
        if not toolItem or toolItem.count < 1 then
            TriggerClientEvent('routes:notify', src, ('Du benötigst: %s'):format(routeData.Collector.RequiredItem.label), 'error')
            return
        end
    end

    local foundItem = nil
    for _, itemData in pairs(routeData.Collector.Items) do
        local roll = math.random(1, 100)
        if roll <= itemData.chance then
            foundItem = itemData
            break
        end
    end

    if foundItem then
        local amount = math.random(foundItem.amountMin, foundItem.amountMax)

        if not xPlayer.canCarryItem(foundItem.name, amount) then
            TriggerClientEvent('routes:notify', src, 'Nicht genug Platz im Inventar!', 'error')
            return
        end

        xPlayer.addInventoryItem(foundItem.name, amount)
        TriggerClientEvent('routes:notify', src, ('Du hast %dx %s gesammelt!'):format(amount, foundItem.label), 'success')
        SendLog(Webhooks.Collect, "Sammeln", ('%dx %s gesammelt'):format(amount, foundItem.label), src)

        if Config.Debug then
            print(('[Routen-System] %s sammelt %dx %s'):format(xPlayer.identifier, amount, foundItem.label))
        end
    else
        TriggerClientEvent('routes:notify', src, 'Du hast nichts gefunden!', 'error')
    end
end)

-- Verarbeiten
RegisterServerEvent('routes:processItem')
AddEventHandler('routes:processItem', function(routeName)
    local src = source

    if IsOnCooldown(src, 'process', 2) then
        TriggerClientEvent('routes:notify', src, 'Zu schnell! Warte kurz.', 'error')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local routeData = Config.Routes[routeName]
    if not routeData or not routeData.Enabled then
        TriggerClientEvent('routes:notify', src, 'Route nicht verfügbar!', 'error')
        return
    end

    local required = routeData.Processor.RequiredItem
    local output = routeData.Processor.OutputItem

    local item = xPlayer.getInventoryItem(required.name)
    if not item or item.count < required.amount then
        TriggerClientEvent('routes:notify', src, ('Du benötigst %dx %s!'):format(required.amount, required.label), 'error')
        return
    end

    if not xPlayer.canCarryItem(output.name, output.amount) then
        TriggerClientEvent('routes:notify', src, 'Nicht genug Platz im Inventar!', 'error')
        return
    end

    xPlayer.removeInventoryItem(required.name, required.amount)
    xPlayer.addInventoryItem(output.name, output.amount)

    TriggerClientEvent('routes:notify', src, ('Du hast %dx %s zu %dx %s verarbeitet!'):format(required.amount, required.label, output.amount, output.label), 'success')
    SendLog(Webhooks.Process, "Verarbeiten", ('%dx %s -> %dx %s verarbeitet'):format(required.amount, required.label, output.amount, output.label), src)

    if Config.Debug then
        print(('[Routen-System] %s verarbeitet %dx %s -> %dx %s'):format(xPlayer.identifier, required.amount, required.label, output.amount, output.label))
    end
end)

-- Verkaufen
RegisterServerEvent('routes:sellItem')
AddEventHandler('routes:sellItem', function(routeName)
    local src = source

    if IsOnCooldown(src, 'sell', 2) then
        TriggerClientEvent('routes:notify', src, 'Zu schnell! Warte kurz.', 'error')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local routeData = Config.Routes[routeName]
    if not routeData or not routeData.Enabled then
        TriggerClientEvent('routes:notify', src, 'Route nicht verfügbar!', 'error')
        return
    end

    local availableItems = {}
    for _, itemData in pairs(routeData.Seller.Items) do
        local item = xPlayer.getInventoryItem(itemData.name)
        if item and item.count >= itemData.amount then
            table.insert(availableItems, itemData)
        end
    end

    if #availableItems == 0 then
        TriggerClientEvent('routes:notify', src, 'Du hast keine verkaufbaren Items!', 'error')
        return
    end

    local randomItem = availableItems[math.random(1, #availableItems)]
    local price = randomItem.payment.amount

    if randomItem.payment.amountMin and randomItem.payment.amountMax then
        price = math.random(randomItem.payment.amountMin, randomItem.payment.amountMax)
    end

    local totalPrice = price * randomItem.amount

    xPlayer.removeInventoryItem(randomItem.name, randomItem.amount)

    if randomItem.payment.type == 'black_money' then
        xPlayer.addAccountMoney('black_money', totalPrice)
    else
        xPlayer.addMoney(totalPrice)
    end

    local moneyType = randomItem.payment.type == 'black_money' and 'Schwarzgeld' or 'Bargeld'

    TriggerClientEvent('routes:notify', src, ('Du hast %dx %s für $%d %s verkauft!'):format(randomItem.amount, randomItem.label, totalPrice, moneyType), 'success')
    SendLog(Webhooks.Sell, "Verkaufen", ('%dx %s verkauft für $%d (%s)'):format(randomItem.amount, randomItem.label, totalPrice, moneyType), src)

    if Config.Debug then
        print(('[Routen-System] %s verkauft %dx %s für $%d (%s)'):format(xPlayer.identifier, randomItem.amount, randomItem.label, totalPrice, moneyType))
    end
end)

-- Server Callbacks
ESX.RegisterServerCallback('routes:checkItem', function(source, cb, itemName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end

    local item = xPlayer.getInventoryItem(itemName)
    if item and item.count >= amount then
        cb(true)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback('routes:checkAnyItem', function(source, cb, items)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end

    for _, itemData in pairs(items) do
        local item = xPlayer.getInventoryItem(itemData.name)
        if item and item.count >= itemData.amount then
            cb(true)
            return
        end
    end

    cb(false)
end)

ESX.RegisterServerCallback('routes:checkRequiredItem', function(source, cb, itemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end

    if not itemName then
        cb(true)
        return
    end

    local item = xPlayer.getInventoryItem(itemName)
    if item and item.count >= 1 then
        cb(true)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback('routes:canCarryItem', function(source, cb, itemName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end

    if xPlayer.canCarryItem(itemName, amount) then
        cb(true)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback('routes:canCarryItems', function(source, cb, items)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end

    local maxAmount = 1
    local testItemName = items[1].name

    for _, itemData in pairs(items) do
        if itemData.amountMax > maxAmount then
            maxAmount = itemData.amountMax
            testItemName = itemData.name
        end
    end

    if xPlayer.canCarryItem(testItemName, maxAmount) then
        cb(true)
    else
        cb(false)
    end
end)

-- Events
AddEventHandler('playerDropped', function(reason)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer then
        if playerCooldowns[xPlayer.identifier] then
            playerCooldowns[xPlayer.identifier] = nil
        end
    end
end)
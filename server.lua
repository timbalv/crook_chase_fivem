local activePlayers = {}

local function hasCrook()
    for _, data in pairs(activePlayers) do
        if data.role == 'crook' then
            return true
        end
    end
    return false
end

local function getCopCount()
    local count = 0
    for _, data in pairs(activePlayers) do
        if data.role == 'cop' then
            count = count + 1
        end
    end
    return count
end

local function isLobbyFull()
    return hasCrook() and getCopCount() >= 1
end

RegisterNetEvent('crookChase:joinLobby')
AddEventHandler('crookChase:joinLobby', function(role)
    local src = source

    if role ~= 'cop' and role ~= 'crook' then
        TriggerClientEvent('crookChase:notify', src, 'Invalid role. Choose "cop" or "crook".')
        return
    end

    if activePlayers[src] then
        TriggerClientEvent('crookChase:notify', src, 'You are already in the lobby as a ' .. activePlayers[src].role .. '.')
        return
    end

    if role == 'crook' and hasCrook() then
        TriggerClientEvent('crookChase:notify', src, 'A crook already exists in the lobby. Choose "cop" instead.')
        return
    end

    activePlayers[src] = { role = role }

    local playerName = GetPlayerName(src)
    print(('[CrookChase] %s (ID: %d) joined the lobby as %s'):format(playerName, src, role))
    TriggerClientEvent('crookChase:notify', src, 'You joined the lobby as a ' .. role .. '.')

    if isLobbyFull() then
        TriggerClientEvent('crookChase:lobbyFull', -1)
    end
end)

RegisterCommand('join', function(source, args)
    if source == 0 then
        print('[CrookChase] This command can only be used by players.')
        return
    end

    local role = args[1]

    if not role then
        TriggerClientEvent('crookChase:notify', source, 'Usage: /join [cop|crook]')
        return
    end

    role = string.lower(role)
    TriggerEvent('crookChase:joinLobby', role)
end, false)

AddEventHandler('playerDropped', function()
    local src = source
    if activePlayers[src] then
        local playerName = GetPlayerName(src)
        print(('[CrookChase] %s (ID: %d) left the lobby.'):format(playerName, src))
        activePlayers[src] = nil
    end
end)

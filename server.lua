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

    -- 1. Ellenőrzések: Érvényes-e a szerepkör?
    if role ~= 'cop' and role ~= 'crook' then
        TriggerClientEvent('crookChase:notify', src, 'Érvénytelen szerepkör! Használd: /join [cop|crook]')
        return
    end

    -- 2. Ellenőrzés: Benne van-e már a lobbyban?
    if activePlayers[src] then
        TriggerClientEvent('crookChase:notify', src, 'Már tagja vagy a lobby-nak mint ' .. activePlayers[src].role .. '!')
        return
    end

    -- 3. Ellenőrzés: Van-e már bűnöző?
    if role == 'crook' and hasCrook() then
        TriggerClientEvent('crookChase:notify', src, 'Már van bűnöző a lobby-ban! Válassz a rendőrök közé.')
        return
    end

    -- 4. Tényleges mentés a listába
    activePlayers[src] = { role = role }

    -- 5. AZONNALI VISSZAJELZÉS (Hogy ne legyen csendes)
    local roleNameText = (role == 'crook') and "Bűnöző" or "Rendőr"
    TriggerClientEvent('crookChase:notify', src, 'Sikeresen csatlakoztál mint ' .. roleNameText .. '.')

    -- 6. Lobby állapot ellenőrzése és indítás
    if isLobbyFull() then
        -- Ha ketten vagytok, indul a menet
        local roles = {}
        for id, data in pairs(activePlayers) do
            roles[id] = data.role
        end
        TriggerClientEvent('crookChase:syncRoles', -1, roles)
        TriggerClientEvent('crookChase:lobbyFull', -1)
    else
        -- Ha egyedül vagy, jelezzük, kire várunk
        if role == 'crook' then
            TriggerClientEvent('crookChase:notify', src, 'Várakozás legalább egy rendőrre az induláshoz...')
        else
            TriggerClientEvent('crookChase:notify', src, 'Várakozás egy bűnözőre az induláshoz...')
        end
        print(('[CrookChase] %s várakozik. Jelenlegi létszám: %d/2'):format(GetPlayerName(src), getCopCount() + (hasCrook() and 1 or 0)))
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


-- ================================================================
-- /endchase – reset the entire lobby
-- ================================================================

RegisterCommand('endchase', function(source)
    if source == 0 then
        print('[CrookChase] Chase ended by server console.')
    else
        local playerName = GetPlayerName(source)
        print(('[CrookChase] Chase ended by %s (ID: %d).'):format(playerName, source))
    end

    activePlayers = {}
    TriggerClientEvent('crookChase:resetChase', -1)
    TriggerClientEvent('crookChase:notify', -1, 'The chase has been ended. Lobby reset.')
end, false)

RegisterNetEvent('crookChase:bustSuccess')
AddEventHandler('crookChase:bustSuccess', function(crookServerId)
    local src = source

    if not activePlayers[src] or activePlayers[src].role ~= 'cop' then
        return
    end

    if not activePlayers[crookServerId] or activePlayers[crookServerId].role ~= 'crook' then
        return
    end

    local copName = GetPlayerName(src)
    local crookName = GetPlayerName(crookServerId)
    local msg = ('%s busted %s! The chase is over.'):format(copName, crookName)
    print('[CrookChase] ' .. msg)
    TriggerClientEvent('crookChase:notify', -1, msg)
    TriggerClientEvent('crookChase:removeBlip', -1)
end)

-- ================================================================
-- Blip sync – relay crook position to all cops
-- ================================================================

RegisterNetEvent('crookChase:updateCrookPos')
AddEventHandler('crookChase:updateCrookPos', function(x, y, z)
    local src = source

    if not activePlayers[src] or activePlayers[src].role ~= 'crook' then
        return
    end

    for id, data in pairs(activePlayers) do
        if data.role == 'cop' then
            TriggerClientEvent('crookChase:crookPosition', id, x, y, z)
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activePlayers[src] then
        local playerName = GetPlayerName(src)
        print(('[CrookChase] %s (ID: %d) left the lobby.'):format(playerName, src))
        activePlayers[src] = nil
    end
end)

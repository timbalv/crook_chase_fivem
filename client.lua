local myRole = nil
local lobbyRoles = {}
local bustInProgress = false
local crookBlip = nil

-- ============================================================
-- Event handlers
-- ============================================================

RegisterNetEvent('crookChase:syncRoles')
AddEventHandler('crookChase:syncRoles', function(roles)
    lobbyRoles = roles
    local myServerId = GetPlayerServerId(PlayerId())
    myRole = lobbyRoles[myServerId]
end)

RegisterNetEvent('crookChase:notify')
AddEventHandler('crookChase:notify', function(message)
    TriggerEvent('chat:addMessage', {
        color = { 255, 200, 0 },
        args = { '[CrookChase]', message }
    })
end)

RegisterNetEvent('crookChase:lobbyFull')
AddEventHandler('crookChase:lobbyFull', function()
    TriggerEvent('chat:addMessage', {
        color = { 0, 255, 0 },
        args = { '[CrookChase]', 'The lobby is full! The chase is about to begin!' }
    })
end)

-- ============================================================
-- Helpers
-- ============================================================

local function getCrookServerId()
    for serverId, role in pairs(lobbyRoles) do
        if role == 'crook' then
            return serverId
        end
    end
    return nil
end

local function getPlayerPedByServerId(serverId)
    local playerId = GetPlayerFromServerId(serverId)
    if playerId == -1 then
        return nil
    end
    return GetPlayerPed(playerId)
end

-- ============================================================
-- Bust mechanic – distance-check loop (cops only)
-- ============================================================

Citizen.CreateThread(function()
    local bustTimer = 0.0
    local BUST_THRESHOLD = 5.0
    local BUST_TIME = 5.0
    local SPEED_THRESHOLD = 1.0
    local TICK_INTERVAL = 500

    while true do
        Citizen.Wait(TICK_INTERVAL)

        if myRole ~= 'cop' then
            bustTimer = 0.0
            goto continue
        end

        local crookServerId = getCrookServerId()
        if not crookServerId then
            bustTimer = 0.0
            goto continue
        end

        local crookPed = getPlayerPedByServerId(crookServerId)
        if not crookPed or not DoesEntityExist(crookPed) then
            bustTimer = 0.0
            goto continue
        end

        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)
        local crookCoords = GetEntityCoords(crookPed)
        local dist = #(myCoords - crookCoords)

        if dist >= BUST_THRESHOLD then
            if bustTimer > 0.0 then
                bustTimer = 0.0
                TriggerEvent('chat:addMessage', {
                    color = { 255, 80, 80 },
                    args = { '[CrookChase]', 'Bust cancelled — crook moved out of range.' }
                })
            end
            goto continue
        end

        -- Crook is within range — check vehicle speed
        local crookVehicle = GetVehiclePedIsIn(crookPed, false)
        local crookSpeed = 0.0
        if crookVehicle ~= 0 then
            crookSpeed = GetEntitySpeed(crookVehicle)
        end

        if crookSpeed >= SPEED_THRESHOLD then
            if bustTimer > 0.0 then
                bustTimer = 0.0
                TriggerEvent('chat:addMessage', {
                    color = { 255, 80, 80 },
                    args = { '[CrookChase]', 'Bust cancelled — crook is still moving.' }
                })
            end
            goto continue
        end

        -- Both conditions met — accumulate timer
        bustTimer = bustTimer + (TICK_INTERVAL / 1000.0)

        local remaining = math.ceil(BUST_TIME - bustTimer)
        if remaining > 0 then
            TriggerEvent('chat:addMessage', {
                color = { 255, 255, 0 },
                args = { '[CrookChase]', ('Busting crook... %d seconds remaining.'):format(remaining) }
            })
        end

        if bustTimer >= BUST_TIME then
            bustTimer = 0.0
            bustInProgress = false
            TriggerServerEvent('crookChase:bustSuccess', crookServerId)
            TriggerEvent('chat:addMessage', {
                color = { 0, 255, 0 },
                args = { '[CrookChase]', 'Bust successful!' }
            })
        end

        ::continue::
    end
end)

-- ============================================================
-- Blip sync – crook broadcasts position to server every 1000ms
-- ============================================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        if myRole ~= 'crook' then
            goto continue
        end

        local myPed = PlayerPedId()
        local coords = GetEntityCoords(myPed)
        TriggerServerEvent('crookChase:updateCrookPos', coords.x, coords.y, coords.z)

        ::continue::
    end
end)

-- ============================================================
-- Blip sync – cop receives crook position and renders map blip
-- ============================================================

local function removeCrookBlip()
    if crookBlip and DoesBlipExist(crookBlip) then
        RemoveBlip(crookBlip)
        crookBlip = nil
    end
end

RegisterNetEvent('crookChase:crookPosition')
AddEventHandler('crookChase:crookPosition', function(x, y, z)
    if myRole ~= 'cop' then
        return
    end

    if crookBlip and DoesBlipExist(crookBlip) then
        SetBlipCoords(crookBlip, x, y, z)
    else
        crookBlip = AddBlipForCoord(x, y, z)
        SetBlipSprite(crookBlip, 161)
        SetBlipColour(crookBlip, 1)
        SetBlipScale(crookBlip, 1.2)
        SetBlipAsShortRange(crookBlip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Crook')
        EndTextCommandSetBlipName(crookBlip)
    end
end)

RegisterNetEvent('crookChase:removeBlip')
AddEventHandler('crookChase:removeBlip', function()
    removeCrookBlip()
end)

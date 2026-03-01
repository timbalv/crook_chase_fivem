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

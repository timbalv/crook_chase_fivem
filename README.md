# Crook Chase – FiveM Gamemode

A Cops vs. Crook pursuit gamemode for FiveM. One player is the **Crook** trying to escape; every other player is a **Cop** trying to bust them.

## Installation

1. Drop the `crook_chase_fivem` folder into your server's `resources/` directory.
2. Add `ensure crook_chase_fivem` to your `server.cfg`.

## How to Play

### Joining the Lobby

Use the `/join` command in chat to pick your role:

```
/join crook
/join cop
```

- Only **one** crook is allowed per lobby. If someone already claimed the role, you must join as a cop.
- You cannot switch roles once you have joined.
- The chase begins automatically once the lobby has **1 crook** and **at least 1 cop**. All players receive a chat notification when this happens.

### Roles

| Role | Objective |
|------|-----------|
| **Crook** | Escape the cops. Stay in a vehicle and keep moving. |
| **Cop** | Track down the crook using the map blip and get close enough to bust them. |

### Map Blip (Pursuit Tracking)

Once the chase starts, the crook's position is broadcast to the server every second. The server relays those coordinates exclusively to cop players, who see a red blip (Sprite 161, labeled **"Crook"**) on their map that updates in real time. The crook does not see their own blip.

When the chase ends (successful bust or crook disconnects), the blip is removed from every cop's map.

### The Bust Mechanic

Cops bust the crook through proximity and persistence — there is no button to press. A background loop on each cop's client checks every **500 ms**:

1. **Distance check** — the cop must be within **5.0 units** of the crook.
2. **Speed check** — the crook's vehicle speed must be below **1.0** (effectively stopped or nearly stopped).

When both conditions are met simultaneously, a **5-second countdown timer** begins. The cop sees a chat message each tick showing the remaining seconds:

```
[CrookChase] Busting crook... 5 seconds remaining.
[CrookChase] Busting crook... 4 seconds remaining.
...
```

The timer **resets** if either condition breaks before it reaches zero:

- The crook moves out of the 5.0-unit range → `"Bust cancelled — crook moved out of range."`
- The crook accelerates above 1.0 speed → `"Bust cancelled — crook is still moving."`

If the timer reaches zero uninterrupted, the cop's client fires `crookChase:bustSuccess` to the server. The server validates that the caller is a cop and the target is the crook, then announces the result to every player:

```
[CrookChase] PlayerA busted PlayerB! The chase is over.
```

## Events Reference

### Server Events

| Event | Triggered By | Description |
|-------|-------------|-------------|
| `crookChase:joinLobby` | `/join` command | Adds a player to the lobby with their chosen role. |
| `crookChase:updateCrookPos` | Crook client (every 1s) | Receives crook coordinates and relays them to all cops. |
| `crookChase:bustSuccess` | Cop client | Validates the bust and broadcasts the result to all players. |

### Client Events

| Event | Sent To | Description |
|-------|---------|-------------|
| `crookChase:syncRoles` | All players (`-1`) | Broadcasts the full role table when the lobby fills. |
| `crookChase:lobbyFull` | All players (`-1`) | Notifies everyone the chase is starting. |
| `crookChase:crookPosition` | Individual cops | Delivers crook coordinates for blip rendering. |
| `crookChase:removeBlip` | All players (`-1`) | Tells clients to clean up the crook blip. |
| `crookChase:notify` | Target player or all (`-1`) | Sends a `[CrookChase]` chat message. |

## File Structure

```
crook_chase_fivem/
├── fxmanifest.lua   -- Resource manifest (cerulean, gta5)
├── client.lua       -- Role state, bust loop, blip rendering
├── server.lua       -- Lobby management, position relay, bust validation
└── README.md
```

## Tuning Constants

These values live at the top of the bust-mechanic thread in `client.lua` and can be adjusted:

| Constant | Default | Purpose |
|----------|---------|---------|
| `BUST_THRESHOLD` | `5.0` | Max distance (units) between cop and crook for a bust to progress. |
| `BUST_TIME` | `5.0` | Seconds the cop must stay in range to complete the bust. |
| `SPEED_THRESHOLD` | `1.0` | Max crook vehicle speed for the bust to progress. |
| `TICK_INTERVAL` | `500` | Milliseconds between each bust-check tick. |

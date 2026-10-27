# Kingz Path

Roblox game source managed with [Rojo](https://rojo.space/).

## Sync into Roblox Studio

1. Install the Rojo command-line tool and the Rojo Studio plugin.
2. In a terminal, change directory to this repository (the folder containing `default.project.json`).
3. Start the Rojo server:

   ```sh
   rojo serve default.project.json
   ```

4. In Roblox Studio, open the Rojo plugin and connect to the server (normally `localhost:34872`).
5. Start a **Play** test. The HUD is created by the LocalScript at runtime, so it will not appear in Edit mode.

The project file maps:

- `src/ReplicatedStorage/Shared` to `ReplicatedStorage/Shared`
- `src/ServerScriptService` to `ServerScriptService`
- `src/StarterPlayer/StarterPlayerScripts` to `StarterPlayer/StarterPlayerScripts`

Expected synced scripts include `GameServer` (a server Script) and `GameClient` (a LocalScript). Shared `.lua` files become ModuleScripts. Check both Client and Server contexts in Studio's Output window if something does not start.

> The project source does not include a Roblox place file (`.rbxl`/`.rbxlx`). Rojo syncs the code and generated prototype geometry into the open place; it does not provide finished map art. Save or publish the place from Studio when ready.

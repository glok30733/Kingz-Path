# Architecture Assessment

## Summary

The project begins with a minimal, server-authoritative Roblox MMORPG architecture. That design intentionally keeps the gameplay loop small and robust before larger content is added.

## Core Layers

### 1. Shared configuration
The shared config module defines:

- class data for the Warrior archetype
- monster balance values for the Slime enemy
- EXP thresholds per level
- default player profile data

This centralizes tuning and makes later expansion easier.

### 2. Server authority
The server controls:

- player profile loading and saving
- character level and EXP calculations
- monster spawn and respawn logic
- damage validation and kill rewards
- data persistence

The client never decides damage, rewards, or level progression.

### 3. Client presentation
The local client only:

- builds the battle HUD
- finds nearby targets
- sends a request to attack the target
- reads the server-authoritative state for display

This prevents exploit loops while keeping the UX responsive.

## Dependencies

The main dependencies in the Phase 1 loop are:

- `Config` -> shared tuning values
- `CombatUtil` -> damage and level calculations
- `PlayerDataService` -> profile load/save operations
- `MonsterService` -> object generation and respawn flow
- `GameServer` -> unified combat orchestration
- `GameClient` -> UI and input handling

## Implementation plan

1. Build a safe default player profile and DataStore save path.
2. Spawn a single monster model with a server-side humanoid and reward values.
3. Create a damage request path that validates distance and target validity.
4. Add EXP, leveling, and gold rewards.
5. Display a simple HUD and target state.
6. Verify the loop manually in Studio before expanding.

## Phase 1 deliverables

The current implementation satisfies the minimum requirements for a stable gameplay loop:

- spawn and movement
- Warrior class
- melee attack
- Slime monster
- death and respawn
- EXP progression
- save and load
- basic UI

## Test strategy

Because Roblox Studio runtime testing is not available in the current environment, the code was checked for Lua syntax and structured to be directly usable in Roblox Studio. The testing path for developers is:

1. Launch a Studio play session.
2. Walk to a slime.
3. Attack the monster.
4. Confirm damage, death, respawn, and level-up behavior.
5. Leave and rejoin to validate persistence.

## Known limitations

- only the Warrior class is implemented in this phase
- only the Slime monster is active
- no equipment, auto-combat, or map progression yet
- no advanced validation for multiple combatants or party systems

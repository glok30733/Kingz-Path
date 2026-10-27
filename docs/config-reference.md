# Configuration Reference

## Shared Config Fields

### Classes

The `Config.Classes` table contains class definitions used in the early progression loop. The first entry is:

- `Warrior`
  - Base stats: STR, AGI, INT, VIT, DEX, LUK
  - Weapon restrictions: Sword, Axe, Mace
  - Basic attack: Heavy Slash
  - Range: 18 units

### Monsters

The `Config.Monsters` table contains enemy templates. Current default:

- `Slime`
  - Level 1
  - 50 health
  - 8 attack
  - 2 defense
  - 7 walk speed
  - 15 EXP reward
  - 8–18 gold reward

### Level progression

The XP table is generated from a stepped formula and is used to check level advancement upon rewards. This is currently tuned for a small early-game loop.

### Player defaults

New players start with:

- Class: Warrior
- Level: 1
- Exp: 0
- Gold: 0
- Health: 100
- Mana: 50
- Empty inventory and equipment slots
- Spawn position at the origin village spawn point

## Adding new content later

To add a new class or monster, define a new entry in the relevant table and ensure the server can resolve it through the helper methods:

- `Config.GetClassConfig(className)`
- `Config.GetMonsterTemplate(monsterName)`

This keeps future game systems modular and avoids hardcoding class or monster names across scripts.

# GOAP Battle - Love2D Strategic Warfare Game

A large-scale real-time strategy game built with Love2D and GOAP (Goal-Oriented Action Planning) AI system.

## Features

### 🤖 GOAP AI System
- Goal-oriented action planning with A* pathfinding
- Dynamic decision making based on game state
- 4 AI actions: FindTarget, MoveToEnemy, AttackEnemy, Idle

### 🎮 Gameplay
- **Large Map**: 1600x900 battlefield for epic battles
- **Base Defense Mode**: Two AI-controlled bases battle for supremacy
- **Resource Economy**: 12 resource nodes across the map
- **Miner Units**: Deploy specialized workers to boost resource gathering
- **Barracks System**: 8 specialized barracks types for diverse army composition
- **Strategic Unit Production**: Bases intelligently choose unit types based on available resources
- **9 Unit Classes** with unique abilities:
  - **Miner** ($40): Resource gatherer, boosts economy (non-combat, high evasion)
  - **Soldier** ($50): Balanced all-rounder
  - **Scout** ($55): Ultra-fast reconnaissance unit (high dodge, high crit)
  - **Gunner** ($70): Fast fire rate, high armor, suppression fire
  - **Healer** ($75): Supports troops with healing aura (low combat power)
  - **Sniper** ($80): Long range, high damage, high critical chance
  - **Ranger** ($85): Extreme range, mobile shooting
  - **Demolisher** ($90): Siege specialist with splash damage, 2x damage to buildings
  - **Tank** ($100): Heavy armor, high HP, regeneration

### 🏭 Barracks System (8 Types)
Build specialized facilities to produce units faster and cheaper:
- **Infantry Barracks** ($150): Produces Soldiers for $40 in 2 seconds
- **Scout Camp** ($140): Produces Scouts for $45 in 1.5 seconds - fastest production!
- **Armory** ($180): Produces Gunners for $55 in 2.5 seconds
- **Sniper Tower** ($200): Produces Snipers for $60 in 3 seconds
- **Field Hospital** ($220): Produces Healers for $60 in 3.5 seconds
- **Ranger Post** ($210): Produces Rangers for $65 in 3.2 seconds
- **Demolition Workshop** ($240): Produces Demolishers for $70 in 3.8 seconds
- **Heavy Barracks** ($250): Produces Tanks for $80 in 4 seconds
- Maximum 6 barracks per base
- Bases automatically build diverse barracks for varied army composition

### 💎 Resource System
- **12 resource nodes** distributed across the battlefield (1000 resources each)
  - 4 nodes near red base
  - 4 nodes near blue base  
  - 4 nodes in contested center
- **Base Mining**: Automatic mining by bases (range: 150, base rate: 3/sec)
- **Miner Units**: Deploy workers to boost resource gathering
  - Each miner adds +2/sec to base mining rate
  - Miners carry up to 50 resources
  - Automatically find nearest resource and return to base
  - High evasion, non-combat units
- **Resource storage limit**: 800 per base
- Control center resources for strategic advantage
- Early game economy critical for mid/late game dominance

### 🎯 Combat System
- Physics-based collision detection
- Unit-to-unit combat with different weapon ranges
- Base and building targeting when enemies are eliminated
- Armor and damage reduction system
- Critical hits and dodge mechanics
- **Special Abilities**:
  - Healers: Passive healing aura for nearby allies
  - Demolishers: Splash damage and building bonus
  - Rangers: Can move while shooting
  - Scouts: Ultra-high mobility for hit-and-run tactics

## Requirements

- [Love2D](https://love2d.org/) 11.4 or higher
- Lua 5.1+

## Installation

1. Install Love2D from [https://love2d.org/](https://love2d.org/)
2. Clone this repository:
```bash
git clone https://github.com/YOUR_USERNAME/love-goap.git
cd love-goap
```
3. Run the game:
```bash
love .
```

## Controls

- **Left Click**: Select agent, base, or barracks to view detailed information
- **Click Anywhere**: Close info panel
- **R**: Restart game
- **ESC**: Quit game

## Project Structure

```
love-goap/
├── main.lua              # Main game loop
├── conf.lua              # Love2D configuration
├── test_goap.lua         # GOAP system tests
├── actions/              # GOAP action definitions
│   ├── attack_base.lua
│   ├── attack_enemy.lua
│   ├── find_target.lua
│   ├── idle.lua
│   ├── move_to_base.lua
│   ├── move_to_enemy.lua
│   └── retreat.lua
├── entities/             # Game entities
│   ├── agent.lua         # Combat units with GOAP AI
│   ├── base.lua          # Base buildings with production
│   ├── resource.lua      # Resource nodes
│   └── barracks.lua      # Specialized production facilities
└── goap/                 # GOAP system core
    ├── action.lua        # Action base class
    └── planner.lua       # A* planning algorithm
```

## Game Mechanics

### Resource Economy
- Bases automatically mine nearby resources
- Each unit type costs different amounts of resources
- Strategic resource control leads to better unit composition

### Unit Production
- Bases produce units automatically when resources are available
- Production time: 8 seconds per unit (base)
- **Max units per base**: 25 (increased for epic battles!)
- AI strategically chooses from 9 unit types based on resource availability
- Diverse army composition for tactical depth

### Barracks Production
- Each barracks specializes in one unit type
- Faster production times than base (1.5-4 seconds)
- Lower resource costs (20-40% discount)
- Requires building time (4-8 seconds)
- Bases auto-build up to 6 diverse barracks for varied armies

### Combat
- Units use GOAP AI to make tactical decisions
- Different weapon ranges and firing rates
- Collision detection prevents unit stacking
- Units target enemy base when no enemies remain

### Victory Conditions
- Destroy enemy base to win
- Game displays winner and battle statistics

## Technical Details

### GOAP Implementation
The GOAP (Goal-Oriented Action Planning) system uses:
- **State-based planning**: Units plan actions based on current world state
- **A* pathfinding**: Finds optimal action sequence to reach goals
- **Dynamic replanning**: Adapts to changing battlefield conditions
- **Cost-based decisions**: Chooses most efficient action paths

### Physics
- Circle-based collision detection
- Push-apart forces for realistic unit movement
- Boundary constraints to keep units on map

## Development

### Adding New Unit Types
Edit `entities/agent.lua` and add to `unitClasses` table:
```lua
YourUnit = {
    hp = 100,
    damage = 15,
    fireRate = 1.0,
    range = 150,
    speed = 80,
    armor = 0.1,
    size = 8
}
```

### Adding New GOAP Actions
1. Create action file in `actions/` directory
2. Define preconditions and effects
3. Implement `perform()` method
4. Add to agent's available actions

## Credits

- **Framework**: Love2D
- **AI Algorithm**: GOAP (Goal-Oriented Action Planning)
- **Developer**: [Your Name]

## License

MIT License - Feel free to use and modify for your projects!

## Screenshots

[Add screenshots of your game here]

---

**Note**: This is a demonstration project showcasing GOAP AI in a real-time strategy game context.

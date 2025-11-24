# GOAP Battle - Love2D Strategy Game

A real-time strategy game built with Love2D and GOAP (Goal-Oriented Action Planning) AI system.

## Features

### 🤖 GOAP AI System
- Goal-oriented action planning with A* pathfinding
- Dynamic decision making based on game state
- 4 AI actions: FindTarget, MoveToEnemy, AttackEnemy, Idle

### 🎮 Gameplay
- **Base Defense Mode**: Two AI-controlled bases battle for supremacy
- **Resource Economy**: Collect resources to produce units
- **Strategic Unit Production**: Bases intelligently choose unit types based on available resources
- **4 Unit Classes** with unique abilities:
  - **Soldier** ($50): Balanced all-rounder (45% spawn rate)
  - **Gunner** ($70): Fast fire rate, high armor (20% spawn rate)
  - **Sniper** ($80): Long range, high damage (20% spawn rate)
  - **Tank** ($100): Heavy armor, high HP (15% spawn rate)

### 💎 Resource System
- 6 resource nodes distributed across the map
- Automatic mining by bases (range: 150, rate: 5/sec)
- Resource storage limit: 500 per base
- Control center resources for strategic advantage

### 🎯 Combat System
- Physics-based collision detection
- Unit-to-unit combat with different weapon ranges
- Base targeting when enemies are eliminated
- Armor and damage reduction system

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

- **Left Click**: Select agent or base to view detailed information
- **Click Anywhere**: Close info panel
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
│   └── resource.lua      # Resource nodes
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
- Production time: 3 seconds per unit
- Max units per base: 15
- AI strategically chooses unit types based on resource availability

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

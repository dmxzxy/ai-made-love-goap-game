# GOAP Battle - Love2D Multi-Team Strategic Warfare Game

A large-scale real-time strategy game built with Love2D and GOAP (Goal-Oriented Action Planning) AI system, featuring **dynamic multi-team battles** (2-4 teams).

## 🌟 Multi-Team System (NEW!)

### Configurable Team Count
The game now supports **2, 3, or 4-way battles**! Simply change `TEAM_COUNT` in `main.lua`:

```lua
local TEAM_COUNT = 4  -- Set to 2, 3, or 4
```

### Team Configurations
- **RED Team** 🔴: Left side (classic attacker)
- **BLUE Team** 🔵: Right side (classic defender)  
- **GREEN Team** 🟢: Top side (new challenger!)
- **YELLOW Team** 🟡: Bottom side (wildcard entry!)

### Dynamic Gameplay Features
- **Multi-directional Combat**: Teams attack all non-allied forces
- **Alliance-Free Warfare**: Every team for themselves - no permanent alliances
- **Strategic Positioning**: Teams spawn at map edges/corners based on count
- **Adaptive Resource Distribution**: Resource points placed fairly for all teams
- **Victory Condition**: Last team standing wins!

### Benefits of Multi-Team Battles
- 🎲 **Unpredictable Outcomes**: 3+ teams create chaotic, dynamic battles
- 🧠 **Strategic Depth**: Teams must balance aggression vs conservation
- 👀 **Spectator Value**: More engaging to watch with multiple fronts
- 🔄 **Replay Value**: Each game plays out differently with team dynamics

### Tower Improvements
- **Reduced Size**: All towers 20-40% smaller to prevent overlap
  - Arrow Tower: 35 → 22
  - Cannon Tower: 45 → 28  
  - Laser Tower: 40 → 25
  - Frost Tower: 38 → 24
- **Better Placement**: Smart distribution algorithm prevents stacking

## 🧠 Tactical AI System

### Dynamic Strategy Modes
The AI now adapts its behavior based on game state:

1. **Economy Mode** �
   - Triggered: First 60 seconds or when miners < 2
   - Focus: Rebuild economic foundation
   - Reserved Gold: $150 (emergency fund)
   - Unit Production: Prioritize miners, small defensive forces
   - Goal: Establish stable resource income

2. **Defensive Mode** 🛡️
   - Triggered: Enemy has +5 unit advantage OR base HP < 70%
   - Focus: Consolidate forces and defend territory
   - Reserved Gold: $120
   - Unit Production: Balanced army composition
   - Wave Size: 4 units before attacking

3. **Offensive Mode** ⚔️
   - Triggered: Own unit advantage (+3) AND resources > $300
   - Focus: Aggressive expansion and pressure
   - Reserved Gold: $100
   - Unit Production: High-quality assault units (Tanks, Demolishers, Rangers)
   - Wave Size: 5 units for overwhelming attacks

4. **Desperate Mode** 🔥
   - Triggered: All miners dead OR (base HP < 30% AND units < 5)
   - Focus: Last-ditch survival attempt
   - Reserved Gold: $80 (reduced to enable comeback)
   - Unit Production: Emergency miner rebuild, then cheap fast units
   - Wave Size: 2 units for quick harassment

### Strategic Features
- **Resource Protection**: AI reserves gold to rebuild miners if they're wiped out
- **No More Feeding**: Units are produced in waves, preventing single-unit suicide charges
- **Comeback Mechanics**: Desperate mode enables dramatic reversals when near defeat
- **Adaptive Decision Making**: Strategy updates every second based on battlefield state
- **Visible AI State**: Strategy mode and reserved gold shown in UI panels

### Benefits
- 🎯 **Better Pacing**: No instant spending = more strategic buildup
- 🔄 **Comebacks Possible**: Reserved gold enables economic recovery
- 🎭 **Varied Gameplay**: Different strategies create diverse battle scenarios
- 📊 **Transparent AI**: Players can see what the AI is thinking

## 🎨 Visual Effects System

### Particle Effects
- **Combat Effects**:
  - Bullet trails for ranged units (Sniper, Gunner, Ranger)
  - Muzzle flashes and sparks for melee combat
  - Blood splatters on hit
  - Explosion particles for critical hits
- **Death Effects**:
  - Multi-layered explosion on unit death
  - Debris and smoke particles
  - Shockwave ripples
- **Tower Effects**:
  - Arrow Tower: Arrow trails with impact sparks
  - Cannon Tower: Ballistic trajectory + massive explosion with camera shake
  - Laser Tower: Continuous energy beam particles
  - Frost Tower: Ice projectiles + freezing pulse effect
- **Special Effects**:
  - Gold coins flying to base during mining
  - Energy pulses for building construction
  - Smoke trails for damaged units

### Floating Damage Numbers
- **Dynamic Combat Feedback**:
  - Normal damage: White floating numbers
  - Critical hits: Large golden numbers with glow effect
  - High armor: Blue-tinted damage display
  - Dodge: Green "DODGE" text with particles
  - Smooth fade-out and arc animations

### Camera System
- **Screen Shake**:
  - Small shake on unit death (intensity: 2)
  - Medium shake on critical hits (intensity: 3)
  - Heavy shake on cannon tower explosions (intensity: 4)
- **Dynamic Background**:
  - Grid battlefield layout (100px cells)
  - Team-colored territory zones (red/blue tint)
  - Enhanced center dividing line

### Animation System
- **Unit Movement**:
  - Bobbing animation while moving (3px vertical oscillation)
  - Direction-based rotation
  - Speed-based animation frequency
- **Attack Animations**:
  - Enhanced attack lines with double-layer glow
  - Expanding shockwave circles on impact
  - Weapon-specific visual effects

### Unit Leveling System (NEW!)
- **Experience & Progression**:
  - Units gain 1 EXP per kill
  - 5 levels max (requires 3/5/7/9 kills per level)
  - Each level up: Full heal + 10% all stats boost + 5% range increase
- **Visual Progression**:
  - Level 1: Normal appearance
  - Level 2: Green aura (Veteran)
  - Level 3: Blue aura (Elite)
  - Level 4: Purple aura (Champion)
  - Level 5: Golden aura (Legend)
- **Level Up Effects**:
  - Golden energy pulse explosion
  - Rotating stars around unit (count = level)
  - 1.5s visual celebration
  - 5% size increase per level
  - Camera shake on level up

### Minimap System (NEW!)
- **Location**: Bottom-right corner (200x200px)
- **Features**:
  - Real-time unit tracking (red/blue dots)
  - Base locations with health rings
  - Tower and barracks markers
  - Resource nodes with depletion indicators
  - Grid overlay with team-colored zones
  - Unit counters (Red: X, Blue: Y)
- **Interaction**:
  - Click minimap to instantly jump camera to location
  - Hover for detailed view
  - Updates every frame for accuracy

### Battle Notifications System (NEW!)
- **Real-time Combat Alerts**:
  - **Base Under Attack**: Red warning notification when base takes damage (5s cooldown)
  - **Unit Level Up**: Golden celebration notification when units reach new levels
  - **Building Complete**: Green notification for barracks/tower construction
  - **Victory/Defeat**: Large announcement when game ends
- **Visual Design**:
  - Animated slide-in from top (smooth 60fps animation)
  - Color-coded by notification type (red=danger, gold=achievement, green=success)
  - Team-colored badges
  - Life bar showing remaining display time (4s duration)
  - Auto-stacking with max 5 notifications
  - Fade-out animation when expiring
- **Smart Anti-Spam**: Duplicate messages within 2s are filtered

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

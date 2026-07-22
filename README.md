# Mojo Tactics

A tactical turn-based strategy game developed in **Mojo** using **Pygame**.

## Development Note

This project was built using **agentic development exclusively** via **Modular's Kimi K2.6 endpoint**. All code, design decisions, and iterations were generated and refined through AI-driven development workflows.

## Overview

Mojo Tactics is a grid-based tactical game where you command a squad of 3 units against 6 enemy bugs. Position your units, use their unique powers, and wipe out the enemy to win.

## Prerequisites

- [Mojo](https://docs.modular.com/mojo/manual/get-started/) installed
- Python with Pygame installed (`pip install pygame`)

## Setup & Installation

```bash
# Clone the repository
git clone <repository-url>
cd mojo-tactics

# Ensure Pygame is available in your Python environment
pip install pygame

# Run the game
mojo mojo_tactics.mojo
```

## Game Rules

### Objective
**Defeat all 6 enemy bugs to win.** The enemy starts with 3 bugs on the board and receives 3 reinforcements over time. If all your player units are defeated, you lose.

### The Grid
- The battlefield is a **12×12 grid**.
- Terrain includes **Grass** (cost 1), **Water** (cost 2), and **Rocks** (impassable).

### Player Units
You control 3 unique units, each with 4 HP:

| Unit | Power | Notes |
|------|-------|-------|
| **Mojo** | **Flame** — Creates a fire tile within 4 spaces | Classic tactician |
| **Max** | **Swap** — Swap places with any unit within 4 spaces | Has a **jetpack**: ignores terrain and hovers over fire |
| **Mammoth** | **Charge** — Rush up to 4 spaces, pushing enemies and dealing damage | Charge direction must be adjacent to start |

### Turn Structure
1. **Select a unit** (left-click).
2. **Move** up to 4 movement points (green tiles).
3. **Attack** an adjacent enemy for 1 damage, **or** use your unit's **Power**.
4. Press **End Turn** when done.
5. The **enemy takes their turn** — bugs move toward your units and attack when adjacent.

### Key Mechanics

- **Movement Budget**: Each unit has a budget of 4 per turn. Moving through Water costs 2; Grass costs 1; Rocks are blocked.
- **Attack vs. Power**: You can move, then either attack **or** use a power — **not both** in the same turn.
- **Fire Tiles**: Stepping onto or ending a turn on a fire tile deals **1 damage**. Max's jetpack negates this.
- **Batteries**: Cyan circles on the map heal **1 HP** when stepped on. Maximum 3 on the board at once.
- **Enemy Spawns**: The enemy squad consists of exactly 6 bugs total. 3 start on the board; up to 3 more spawn on the bottom/right edges over time.

### Controls

| Input | Action |
|-------|--------|
| **Left Click** | Select unit, move, attack, use powers |
| **Right Click** | Deselect current unit |
| **End Turn** | Finish your turn and let the enemy act |

### Winning & Losing

- **Win**: All 6 enemy bugs are defeated.
- **Lose**: All 3 player units are defeated.
- Your **high score** (total bugs killed) is saved locally.

## Project Structure

```
mojo-tactics/
├── mojo_tactics.mojo    # Entry point
├── game.mojo            # Main game loop, state, and UI
├── ai.mojo              # Enemy AI — pathfinding and decision making
├── unit.mojo            # Unit definitions and stats
├── terrain.mojo         # Terrain types and rendering
├── sprites.mojo         # Sprite rendering utilities
├── constants.mojo       # Grid size, screen dimensions, etc.
└── .highscore           # Local high score file (auto-generated)
```

## License

[Add your license here]

# Zoids

A boids simulation written in Zig using Raylib. This project implements the classic flocking behavior algorithm where virtual birds (boids) exhibit emergent group behavior through simple local rules.

## Features

- Real-time boids simulation with thousands of entities
- Spatial partitioning for performance optimization
- Interactive controls for adjusting simulation parameters
- Visual debugging options
- Staggered updates for smooth performance

## Requirements

- Zig 0.15.1 or later
- Raylib (automatically fetched via raylib-zig dependency)

## Building

```bash
zig build
```

## Running

```bash
zig build run
```

## Controls

The simulation includes an input handler for real-time parameter adjustment and interaction with the boids.

## Architecture

- `main.zig` - Entry point and main game loop
- `boids.zig` - Boids behavior implementation
- `game.zig` - Game state management
- `renderer.zig` - Rendering system
- `spatial.zig` - Spatial partitioning for performance
- `input.zig` - Input handling
- `settings.zig` - Configuration and constants
- `player.zig` - Player interaction system
- `utils.zig` - Utility functions

## Performance Notes

The simulation uses heap allocation for game state to support large numbers of boids (15k+ entities). Spatial partitioning is implemented to maintain performance at scale.
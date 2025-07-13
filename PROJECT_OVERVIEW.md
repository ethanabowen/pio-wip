# Isometric Time Map Project

A generic Godot 4.2 project template for creating isometric games with time manipulation mechanics, tile-based maps, and proper sprite handling.

## Project Structure

```
├── project.godot           # Main Godot project file
├── icon.svg               # Project icon
├── scenes/
│   └── Main.tscn          # Main game scene
├── scripts/
│   ├── TimeManager.gd     # Core time management system
│   ├── IsometricUtils.gd  # Isometric coordinate utilities
│   ├── IsometricTileMap.gd # Tile map with time state management
│   ├── IsometricCharacter.gd # Base character controller
│   └── PlayerController.gd # Player-specific controller
├── components/
│   └── TimeUI.gd          # Time control UI component
└── assets/
    ├── sprites/
    │   └── isometric/     # Isometric sprite assets
    ├── tiles/             # Tile textures
    └── audio/             # Audio assets
```

## Core Features

### Time Management System
- **TimeManager**: Central system for handling time states
- **Time States**: Normal, Paused, Rewinding, Fast Forward
- **Time Recording**: Automatic state recording and playback
- **Time Objects**: Any object can be registered for time manipulation

### Isometric System
- **IsometricUtils**: Coordinate conversion utilities
- **Proper Sorting**: Automatic depth sorting for isometric sprites
- **Tile-based**: Grid-based movement and interaction
- **Mouse Interaction**: Click-to-move and tile interaction

### Tile Map System
- **IsometricTileMap**: Extended TileMap with time state management
- **Multiple Tile Types**: Grass, Stone, Water, Trees, etc.
- **Pathfinding**: Built-in A* pathfinding
- **Dynamic Editing**: Tiles can be changed at runtime

## Controls

### Movement
- **WASD**: Move character
- **Mouse Click**: Move to tile / Interact with tile

### Time Controls
- **Space**: Pause/Resume time
- **Q**: Rewind time (hold)
- **E**: Fast forward time (hold)
- **UI Buttons**: Alternative time controls

## Usage Instructions

### 1. Setting up the Project
1. Open the project in Godot 4.2+
2. The main scene is already configured in `scenes/Main.tscn`
3. Run the project to see the basic functionality

### 2. Adding Custom Tiles
1. Create or import tile sprites
2. Set up a TileSet resource in the Godot editor
3. Assign the TileSet to the IsometricTileMap node
4. Update the `_update_tile_visual()` method in `IsometricTileMap.gd`

### 3. Adding Custom Characters
1. Create a new script extending `IsometricCharacter`
2. Override `get_time_state()` and `set_time_state()` for time mechanics
3. Add custom movement logic in `_handle_movement()`
4. Set up sprite animations for different directions

### 4. Extending Time Mechanics
1. Register objects with `TimeManager.register_time_object()`
2. Implement `get_time_state()` and `set_time_state()` methods
3. Time states are automatically recorded and restored

## Key Classes

### TimeManager
Central time management system that handles:
- Time state recording and playback
- Time object registration
- Input handling for time controls
- Signal emission for time events

### IsometricUtils
Static utility class providing:
- Coordinate conversion (world ↔ isometric)
- Tile position calculations
- Mouse interaction helpers
- Pathfinding utilities

### IsometricTileMap
Extended TileMap with:
- Time state management
- Tile type system
- Pathfinding capabilities
- Dynamic tile editing

### IsometricCharacter
Base character controller with:
- Isometric movement
- Time state management
- Animation system
- Collision handling

## Customization Guide

### Adding New Tile Types
1. Add to the `TileType` enum in `IsometricTileMap.gd`
2. Update `_update_tile_visual()` method
3. Add interaction logic in `PlayerController.interact_with_tile()`

### Creating Custom Time Objects
```gdscript
extends Node
class_name CustomTimeObject

var time_manager: TimeManager
var custom_state: Dictionary = {}

func _ready():
    time_manager = get_node("/root/TimeManager")
    if time_manager:
        time_manager.register_time_object(self)

func get_time_state() -> Dictionary:
    return custom_state.duplicate()

func set_time_state(state: Dictionary):
    custom_state = state.duplicate()
```

### Modifying Time Mechanics
- Adjust `time_chunk_size` in TimeManager for recording frequency
- Modify `max_history_length` for memory management
- Change `rewind_speed` and `fast_forward_speed` for different time rates

## Performance Notes

### Time System
- Time states are recorded every 0.1 seconds by default
- History is limited to 3600 entries (60 seconds at 60 FPS)
- Only registered objects are included in time recording

### Isometric Rendering
- Sprites are automatically sorted by depth
- TileMap uses built-in Godot optimization
- Camera follows player smoothly

### Memory Management
- Time history automatically manages memory
- Old states are removed when limit is reached
- Objects are properly unregistered when destroyed

## Expansion Ideas

### Gameplay Features
- Multiple time periods (past, present, future)
- Time puzzles and mechanics
- Temporal NPCs and objects
- Time-based resource management

### Technical Enhancements
- Save/load system for time states
- Network synchronization for multiplayer
- Advanced pathfinding with obstacles
- Animated tiles and sprites

### Visual Improvements
- Particle effects for time changes
- Smooth camera transitions
- Advanced lighting and shadows
- UI animations and feedback

## Dependencies

- Godot 4.2 or higher
- No external plugins required
- All scripts are self-contained

## Getting Started

1. Clone or download the project
2. Open in Godot 4.2+
3. Press F5 to run the project
4. Use WASD to move, Space to pause, Q/E for time control
5. Click on tiles to interact with them

The project is designed to be easily extensible - use it as a foundation for your isometric time-based game!
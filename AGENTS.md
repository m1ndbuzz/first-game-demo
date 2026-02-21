# AGENTS.md - Coding Guidelines for AI Agents

## Project Overview

Godot 4.4 3D platformer game using GDScript. Simple mechanics: movement, jumping, wall-jumping, dashing, and score tracking.

## Build/Test Commands

```bash
# Run the game (from project root)
godot --path .

# Run with verbose output
godot --path . --verbose

# Export for specific platform (example: macOS)
godot --path . --export-release "macOS" ./builds/game.dmg

# No formal linting - follow style guidelines below
# No formal test runner - test manually by running the game
```

## Code Style Guidelines

### File Organization
- **Scripts**: Place in `scripts/` folder
- **Scenes**: Place in `scenes/` folder, subfolders for levels (`scenes/levels/`)
- **Naming**: Use `snake_case` for filenames (e.g., `player.gd`, `main_menu.gd`)

### GDScript Conventions

**Class Definitions:**
```gdscript
extends CharacterBody3D
class_name Player  # PascalCase for class names
```

**Variables:**
```gdscript
# Exported variables - snake_case, descriptive
@export var speed = 10.0
@export var jump_speed = 7.0
@export var wall_jump_velocity = Vector3(0, 7.0, 5.0)

# Private/internal variables - snake_case
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var jumping = false
var coyote_timer = 0.0

# Constants - UPPER_SNAKE_CASE
const SAVE_PATH = "res://data/scores.json"
const MAX_SCORES = 10

# Node references - use @onready
@onready var spring_arm = $SpringArm3D
@onready var model = $Rig
@onready var anim_tree = $AnimationTree
```

**Functions:**
```gdscript
# snake_case with type hints
func _physics_process(delta: float) -> void:
    # implementation

func get_move_input(delta: float) -> void:
    # implementation

# Return types when applicable
func wall_jump_check() -> Vector3:
    return Vector3.ZERO
```

**Signals:**
```gdscript
# Define in SignalManager autoload (or use @warning_ignore)
@warning_ignore("unused_signal")
signal restart

@warning_ignore("unused_signal")
signal menu

# Emit via SignalManager
SignalManager.restart.emit()
SignalManager.menu.emit()
```

**Imports/Preloading:**
```gdscript
# Use preload for scene references
const FIRST_LEVEL = preload("res://scenes/levels/first_level.tscn")
var player_scene = preload("res://scenes/knight.tscn")
```

### Key Patterns

**Input Handling:**
- Use Input maps defined in `project.godot` (e.g., `move_left`, `jump`, `dash`)
- Use `Input.is_action_just_pressed("action_name")` for one-time actions
- Use `Input.get_vector("left", "right", "forward", "back")` for movement

**Autoloads (Singletons):**
- `Score` - manages high scores persistence
- `SignalManager` - global signal hub for cross-scene communication

**Physics & Movement:**
- Use `_physics_process(delta)` for physics-based updates
- Use `move_and_slide()` for CharacterBody3D movement
- Store velocity in `velocity` property, then call `move_and_slide()`

**Node References:**
- Use `@onready` to cache node references
- Use relative paths with `$` operator: `$"../../Canvas/UI/TimeLabel"`
- Use `get_node_or_null()` for optional nodes

**Signals & Callbacks:**
```gdscript
func _ready() -> void:
    SignalManager.restart.connect(_on_scene_reloaded)

func _on_scene_reloaded():
    # Handle signal
```

### Error Handling
- Use `is_instance_valid()` to check node validity before accessing
- Check file existence before reading: `FileAccess.file_exists(path)`
- Print debug messages for troubleshooting: `print("Debug: ", variable)`

### Groups
- Player character is in the "player" group (configured in project.godot)
- Check membership: `if body.is_in_group("player"):`

### Physics Layers
- Layer 2 = "Player" (configured in project.godot)
- Check collisions with `is_on_floor()`, `is_on_wall()`

### InputMap Action Names
Action names in `project.godot` use **specific casing**:
- **lowercase**: `move_left`, `move_right`, `move_forward`, `move_back`, `jump`, `dash`, `interact`
- **PascalCase**: `Reset`, `Menu`
- Check `project.godot` input section to verify exact action names before using `InputMap` functions
- When converting from scene node names (e.g., "MoveLeft", "Interact"), use a match statement to convert to correct InputMap action names

## Formatting

- Indent with tabs (Godot default)
- Max line length: ~100 characters
- Use trailing commas in arrays/dicts when multi-line
- Add blank lines between logical sections
- Comments start with `#` and a space

## Project Structure

```
first-game-demo/
├── scripts/           # All GDScript files
│   ├── player.gd      # Main player controller
│   ├── score.gd       # Score persistence
│   ├── signal_manager.gd  # Global signals
│   └── ...
├── scenes/            # All .tscn scene files
│   ├── levels/        # Level scenes
│   ├── knight.tscn    # Player scene
│   └── ...
├── models/            # 3D models
├── data/              # JSON data files
├── addons/            # Godot addons
└── project.godot      # Main project config
```

## No External Dependencies

This project uses only Godot 4.4 built-in features. No package managers or external libraries.

## IMPORTANT - File Modification Rules

When encountering errors during file modifications:
1. **DO NOT** use bash scripts or Python scripts to fix files
2. **DO NOT** use sed, awk, or other command-line tools to edit files
3. **Report the error** to the user and ask what they would like to do
4. Wait for user guidance before proceeding

Use only the Read and Edit tools for file modifications. If you get a "file has been modified" error, re-read the file before editing.

# ShapeMath

**ShapeMath** is an offline-first, portrait Android educational puzzle game built with **Godot 4** and **GDScript**. It is designed around quick, engaging logic, spatial, and mathematics puzzle runs suitable for children and learners of all ages.

---

## Current Production Status

- **57 Production Levels**:
  - **19 Easy (Tier 1)**
  - **19 Medium (Tier 2)**
  - **19 Hard (Tier 3)**
- **6 Production Puzzle Types**:
  1. `MATH_MATCH` (Arithmetic matching)
  2. `SHAPE_MATCH` (Spatial shape pairing)
  3. `MISSING_NUMBER` (Equation completion)
  4. `EQUIVALENT_EXPRESSION` (Target value composition)
  5. `NUMBER_SEQUENCE` (Pattern recognition)
  6. `SQUARE_FILL` (9-piece 3x3 square grid placement)
- **Standard Run Mode**: 15 levels per run (5 Easy + 5 Medium + 5 Hard) with smart anti-clumping and recent-run candidate cooldown.
- **Daily Challenge Mode**: 10 levels per day (3 Easy + 4 Medium + 3 Hard) with deterministic date-based seed generation and rolling 24-hour completion cooldown.
- **Player Progression & Systems**:
  - 3-lives system with mistake tracking
  - Continuous streak counter with milestone celebrations (5x, 10x) and personal best record breaking
  - Comprehensive offline statistics tracking (runs started, runs completed, perfect runs, total puzzles solved, success rate)
  - Audio and haptic feedback toggles with persistent settings
  - Responsive portrait Android layout supporting aspect ratios from 4:3 to 22:9 (including safe area top insets for device notches and camera cutouts)

---

## Puzzle Types

1. **Math Match**: Drag and drop the correct numerical result into the equation slot to solve arithmetic equations.
2. **Shape Match**: Align and match complementary geometric shape halves/pieces to complete the shape.
3. **Missing Number**: Identify and place the missing operand inside an incomplete equation.
4. **Equivalent Expression**: Select the mathematical expression that equals the requested target sum or difference.
5. **Number Sequence**: Deduce the underlying mathematical pattern (additive, geometric, alternating, increasing differences) to place the missing term.
6. **Square Fill**: A 9-piece spatial placement puzzle on a 3x3 square board:
   - Exactly 9 draggable squircle pieces and 9 target slots.
   - Fixed orientation (no piece rotation or flipping required).
   - Asymmetric drop fairness model: wide tolerance (d <= 65 px) for the correct target slot; strict intent radius (d <= 45 px) for wrong drops.
   - Distinct tier progression:
     - **Easy (Tier 1)**: Strong slot color preview and numerical identifiers (1..9).
     - **Medium (Tier 2)**: Two-layer clue system with 12% subtle row color tint and matching secondary geometric motifs (dot, dash, diamond) to ensure deductive, zero-guesswork solvability.
     - **Hard (Tier 3)**: Deep gradient matrix with spatial structural glyphs guiding edge, corner, and center placement.

---

## Features

- **Standard Run**: 15-level curated run progressing smoothly through Easy, Medium, and Hard tiers.
- **Daily Challenge**: 10-level challenge with deterministic daily seeding (`DAILY_ALGORITHM_VERSION = 1`) and rolling 24-hour completion cooldown.
- **Lives & Streak System**: 3 lives per run, dynamic streak tracking, and personal best persistence.
- **Offline Local Persistence**: High-integrity local save system (`user://save_data.json`) storing lifetime statistics, audio/haptics preferences, tutorial state, and daily cooldowns.
- **Sound & Haptics**: Full toggle controls with responsive vibration and audio feedback.
- **Responsive Android Layout**: Adaptive UI scaling, auto-centering menus, safe-area top inset handling, and standard Android Back button navigation hierarchy.
- **Interruption & Focus Safety**: Active drag operations gracefully cancel on Android Back or app focus loss / backgrounding without state corruption or piece loss.

---

## Production Level Distribution

| Puzzle Type | Tier 1 (Easy) | Tier 2 (Medium) | Tier 3 (Hard) | Total Levels | Pool Share |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `MATH_MATCH` | 6 (`01, 03, 04, 05, 22, 26`) | 6 (`06, 08, 10, 27, 31, 43`) | 6 (`11, 13, 15, 32, 36, 49`) | **18** | 31.6% |
| `SHAPE_MATCH` | 3 (`02, 23, 24`) | 3 (`07, 09, 29`) | 3 (`12, 14, 34`) | **9** | 15.8% |
| `MISSING_NUMBER` | 3 (`16, 37, 38`) | 3 (`17, 28, 44`) | 3 (`18, 33, 50`) | **9** | 15.8% |
| `EQUIVALENT_EXPRESSION` | 3 (`19, 25, 39`) | 3 (`20, 30, 45`) | 3 (`21, 35, 51`) | **9** | 15.8% |
| `NUMBER_SEQUENCE` | 3 (`40, 41, 42`) | 3 (`46, 47, 48`) | 3 (`52, 53, 54`) | **9** | 15.8% |
| `SQUARE_FILL` | 1 (`55`) | 1 (`56`) | 1 (`57`) | **3** | 5.3% |
| **Tier Totals** | **19** | **19** | **19** | **57** | **100.0%** |

---

## Tech Stack

- **Game Engine**: Godot 4.7.2 (or compatible Godot 4 release)
- **Scripting Language**: GDScript
- **Target Platform**: Android (API 21+)
- **Renderer**: Compatibility Renderer (Mobile / GLES3 fallback)
- **Reference Viewport**: 720x1280 (Portrait)

---

## Project Structure

```text
shape-math/
├── android/                   # Android export templates and build source
├── data/
│   └── levels/                # 57 production LevelData resources (level_01.tres .. level_57.tres)
│       └── samples/           # Isolated development sample levels
├── scenes/
│   ├── components/            # Reusable UI overlays and gameplay components
│   ├── pieces/                # Draggable piece scenes
│   └── main.tscn              # Root gameplay and orchestration scene
├── scripts/
│   ├── core/                  # Core managers (LevelManager, SaveManager, FeedbackManager, Main)
│   ├── gameplay/              # Gameplay node controllers (DraggablePiece, SquareFillSlot)
│   ├── resources/             # Resource schemas and validators (LevelData, SquareFillValidator, SequenceValidator)
│   └── tests/                 # 10 automated headless test suites
├── builds/
│   └── debug/                 # Exported debug APK artifacts
├── project.godot              # Godot project configuration
└── export_presets.cfg         # Android export configuration
```

---

## Running the Project

1. Install **Godot 4.7.2** (or compatible Godot 4 release).
2. Clone the repository:
   ```bash
   git clone https://github.com/AbdullahTurgut/shapemath-godot.git
   ```
3. Open Godot and select **Import** -> choose `project.godot`.
4. Press **F5** (or click **Play**) to launch the main scene (`scenes/main.tscn`).

---

## Android Build

- **Package ID**: `com.alcor.shapemath`
- **Orientation**: Portrait (`portrait`)
- **Exporting via Godot Editor / CLI**:
  ```bash
  godot --headless --export-debug "ShapeMath Android" "builds/debug/ShapeMath-debug.apk"
  ```
- Ensure Android SDK (Build Tools 34+ / 36+) and JDK 17+ are configured in Editor Settings.

---

## Testing & Quality Assurance

The project includes 10 automated test suites executed via Godot headless runner:

```bash
godot --headless --script scripts/tests/test_square_fill.gd
godot --headless --script scripts/tests/test_visual_polish.gd
godot --headless --script scripts/tests/test_responsive_layout.gd
godot --headless --script scripts/tests/test_daily_challenge.gd
godot --headless --script scripts/tests/test_step17d.gd
godot --headless --script scripts/tests/test_step17c.gd
godot --headless --script scripts/tests/test_step17b.gd
godot --headless --script scripts/tests/test_step17a.gd
godot --headless --script scripts/tests/test_statistics.gd
godot --headless --script scripts/tests/test_progression.gd
```

### Test Suite Coverage:
- `test_square_fill.gd`: 57-level pool integrity, asymmetric drop fairness, 50-cycle load/cleanup stress test, 100-run Standard simulation, 30-date Daily simulation.
- `test_visual_polish.gd`: Container visibility, mutual exclusion across 6 puzzle types, and scene transitions.
- `test_responsive_layout.gd`: Verification across 6 aspect ratios (4:3, 16:9, 18:9, 19.5:9, 20:9, 22:9) and safe top insets.
- `test_daily_challenge.gd`: Deterministic daily seed formula, 24-hour completion cooldown, and timestamp serialization.
- `test_step17d.gd`: Multi-run candidate sampling, cooldown, anti-clumping, and puzzle type exposure tracking.
- `test_step17c.gd`: 57-level production pool loading, tier balance, and 6-3-3-3-3-1 distribution.
- `test_step17b.gd`: Sequence validator grammar, interaction hardening, and drop error penalties.
- `test_step17a.gd`: PuzzleType enum integrity, sequence routing, and sample resources.
- `test_statistics.gd`: Lifetime statistics tracking, UI formatting, and Android Back routing.
- `test_progression.gd`: Scenarios A-X master progression, streak milestones, and perfect run handling.

---

## Development Notes

- **Separation of Production vs Sample Content**: Production levels (`data/levels/level_01.tres` through `data/levels/level_57.tres`) are loaded automatically; experimental or test levels remain segregated in `data/levels/samples/`.
- **Deterministic Generators**: Daily Challenge runs use isolated, deterministic PRNG seeds derived from the calendar date key, leaving the Standard Run history and cooldown pool unaffected.
- **Resource Validation**: All `SQUARE_FILL` and `NUMBER_SEQUENCE` levels are validated at load time and during tests to prevent malformed properties, duplicate visual signatures, or out-of-bounds indices.

---

## License

No license has been specified yet.
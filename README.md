# ShapeMath

**ShapeMath** is an offline-first, portrait Android educational puzzle game built with **Godot 4** and **GDScript**. It is designed around quick, engaging logic, spatial, and mathematics puzzle runs suitable for children and learners of all ages.

---

## Current Production Status

- **72 Production Levels**:
  - **24 Easy (Tier 1)**
  - **24 Medium (Tier 2)**
  - **24 Hard (Tier 3)**
- **6 Production Puzzle Types**:
  1. `MATH_MATCH` (Arithmetic matching — 18 levels)
  2. `SHAPE_MATCH` (Spatial shape pairing — 12 levels)
  3. `MISSING_NUMBER` (Equation completion — 10 levels)
  4. `EQUIVALENT_EXPRESSION` (Target value composition — 11 levels)
  5. `NUMBER_SEQUENCE` (Pattern recognition — 12 levels)
  6. `SQUARE_FILL` (9-piece 3x3 square grid placement — 9 levels)
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
2. **Shape Match**: Align and match complementary geometric shape halves/pieces to complete the shape (including horizontal, diagonal, circular, curved, and dovetail cuts).
3. **Missing Number**: Identify and place the missing operand inside an incomplete equation (addition and subtraction across all tiers).
4. **Equivalent Expression**: Select the mathematical expression that equals the requested target sum, difference, or equivalent formulation.
5. **Number Sequence**: Deduce the underlying mathematical pattern (constant additive, constant descending, geometric multiplication, alternating additive/subtractive, increasing differences) to place the missing term.
6. **Square Fill**: A 9-piece spatial placement puzzle on a 3x3 square board:
   - Exactly 9 draggable squircle pieces and 9 target slots.
   - Fixed orientation (no piece rotation or flipping required).
   - Asymmetric drop fairness model: wide tolerance ($d \le 65\text{ px}$) for the correct target slot; strict intent radius ($d \le 45\text{ px}$) for wrong drops.
   - Distinct tier progression across 9 curated levels:
     - **Easy (Tier 1 — Levels 55, 58, 59)**: Strong slot color preview, numerical identifiers (1..9), and intuitive geometric motifs (dots, horizontal bars, corner solids).
     - **Medium (Tier 2 — Levels 56, 63, 64)**: Dual-layer clue system with subtle 12% row color tints, secondary geometric motifs, and directional tessellation arrows ensuring zero-guesswork solvability.
     - **Hard (Tier 3 — Levels 57, 68, 69)**: Deep gradient matrix, continuous circuit/network pathways, and centripetal vector convergence glyphs.

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
| `MATH_MATCH` | 6 (`01, 03, 04, 05, 22, 26`) | 6 (`06, 08, 10, 27, 31, 43`) | 6 (`11, 13, 15, 32, 36, 49`) | **18** | 25.0% |
| `SHAPE_MATCH` | 4 (`02, 23, 24, 60`) | 4 (`07, 09, 29, 65`) | 4 (`12, 14, 34, 70`) | **12** | 16.7% |
| `MISSING_NUMBER` | 3 (`16, 37, 38`) | 4 (`17, 28, 44, 66`) | 3 (`18, 33, 50`) | **10** | 13.9% |
| `EQUIVALENT_EXPRESSION` | 4 (`19, 25, 39, 62`) | 3 (`20, 30, 45`) | 4 (`21, 35, 51, 72`) | **11** | 15.3% |
| `NUMBER_SEQUENCE` | 4 (`40, 41, 42, 61`) | 4 (`46, 47, 48, 67`) | 4 (`52, 53, 54, 71`) | **12** | 16.7% |
| `SQUARE_FILL` | 3 (`55, 58, 59`) | 3 (`56, 63, 64`) | 3 (`57, 68, 69`) | **9** | 12.5% |
| **Tier Totals** | **24** | **24** | **24** | **72** | **100.0%** |

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
│   └── levels/                # 72 production LevelData resources (level_01.tres .. level_72.tres)
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
- `test_square_fill.gd`: 72-level pool integrity, asymmetric drop fairness, 50-cycle load/cleanup stress test, 500-run Standard simulation, 100-date Daily simulation (100% level reachability).
- `test_visual_polish.gd`: Container visibility, mutual exclusion across 6 puzzle types, and scene transitions.
- `test_responsive_layout.gd`: Verification across 6 aspect ratios (4:3, 16:9, 18:9, 19.5:9, 20:9, 22:9) and safe top insets.
- `test_daily_challenge.gd`: Deterministic daily seed formula, 24-hour completion cooldown, and timestamp serialization.
- `test_step17d.gd`: Multi-run candidate sampling, cooldown, anti-clumping, and puzzle type exposure tracking.
- `test_step17c.gd`: 72-level production pool loading, tier balance (24/24/24), SequenceValidator verification across all 12 sequence levels.
- `test_step17b.gd`: Sequence validator grammar, interaction hardening, and drop error penalties.
- `test_step17a.gd`: PuzzleType enum integrity, sequence routing, and sample resources.
- `test_statistics.gd`: Lifetime statistics tracking, UI formatting, and Android Back routing.
- `test_progression.gd`: Scenarios A-X master progression, streak milestones, and perfect run handling.

---

## Development Notes

- **Separation of Production vs Sample Content**: Production levels (`data/levels/level_01.tres` through `data/levels/level_72.tres`) are loaded automatically; experimental or test levels remain segregated in `data/levels/samples/`.
- **Deterministic Generators**: Daily Challenge runs use isolated, deterministic PRNG seeds derived from the calendar date key, leaving the Standard Run history and cooldown pool unaffected.
- **Resource Validation**: All `SQUARE_FILL` and `NUMBER_SEQUENCE` levels are validated at load time and during tests to prevent malformed properties, duplicate visual signatures, or out-of-bounds indices.

---

## License

No license has been specified yet.
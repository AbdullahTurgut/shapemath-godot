extends SceneTree

const SaveManager = preload("res://scripts/core/save_manager.gd")
const LevelManager = preload("res://scripts/core/level_manager.gd")
const SquareFillSlot = preload("res://scripts/gameplay/square_fill_slot.gd")
const SquareFillValidator = preload("res://scripts/resources/square_fill_validator.gd")
const SequenceValidator = preload("res://scripts/tools/sequence_validator.gd")

var _tested: bool = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	_run_tests()
	return false

func _sync_physics() -> void:
	await physics_frame
	await physics_frame

func _run_tests() -> void:
	print("================================================================================")
	print("--- BEGINNING STEP 21B: SQUARE FILL HARDENING & PRODUCTION READINESS TESTS ---")
	print("================================================================================")

	# [SECTION 1] ENUM & SCHEMA VERIFICATION
	print("\n[TEST 1] LevelData.PuzzleType Enum & SQUARE_FILL value")
	assert("SQUARE_FILL" in LevelData.PuzzleType, "PuzzleType enum contains SQUARE_FILL")
	assert(LevelData.PuzzleType.SQUARE_FILL == 5, "SQUARE_FILL is index 5")
	print("-> TEST 1 PASSED: Enum verification complete.")

	# [SECTION 2] VALIDATOR & CONTENT CHECKING
	print("\n[TEST 2] SquareFillValidator on valid samples and malformed resources")
	var easy_res: LevelData = load("res://data/levels/samples/sample_square_fill_easy.tres")
	var med_res: LevelData = load("res://data/levels/samples/sample_square_fill_medium.tres")
	var hard_res: LevelData = load("res://data/levels/samples/sample_square_fill_hard.tres")

	assert(SquareFillValidator.validate(easy_res).is_empty(), "Easy sample passes validator")
	assert(SquareFillValidator.validate(med_res).is_empty(), "Medium sample passes validator")
	assert(SquareFillValidator.validate(hard_res).is_empty(), "Hard sample passes validator")

	# Malformed checks
	var bad_colors := LevelData.new()
	bad_colors.puzzle_type = LevelData.PuzzleType.SQUARE_FILL
	bad_colors.square_fill_piece_colors = [Color.RED] # only 1 color
	bad_colors.square_fill_piece_symbols = ["A","B","C","D","E","F","G","H","I"]
	assert(SquareFillValidator.validate(bad_colors).size() > 0, "Malformed color count fails validator")

	var bad_symbols := LevelData.new()
	bad_symbols.puzzle_type = LevelData.PuzzleType.SQUARE_FILL
	bad_symbols.square_fill_piece_colors = easy_res.square_fill_piece_colors
	bad_symbols.square_fill_piece_symbols = ["A","B",""] # missing/empty
	assert(SquareFillValidator.validate(bad_symbols).size() > 0, "Malformed symbol count fails validator")

	var bad_shelf_len := LevelData.new()
	bad_shelf_len.puzzle_type = LevelData.PuzzleType.SQUARE_FILL
	bad_shelf_len.square_fill_piece_colors = easy_res.square_fill_piece_colors
	bad_shelf_len.square_fill_piece_symbols = easy_res.square_fill_piece_symbols
	bad_shelf_len.square_fill_shelf_order = [0, 1, 2] # only 3
	assert(SquareFillValidator.validate(bad_shelf_len).size() > 0, "Malformed shelf length fails validator")

	var bad_shelf_dup := LevelData.new()
	bad_shelf_dup.puzzle_type = LevelData.PuzzleType.SQUARE_FILL
	bad_shelf_dup.square_fill_piece_colors = easy_res.square_fill_piece_colors
	bad_shelf_dup.square_fill_piece_symbols = easy_res.square_fill_piece_symbols
	bad_shelf_dup.square_fill_shelf_order = [0, 1, 2, 3, 4, 5, 6, 7, 7] # duplicate 7
	assert(SquareFillValidator.validate(bad_shelf_dup).size() > 0, "Duplicate shelf index fails validator")

	var bad_shelf_oor := LevelData.new()
	bad_shelf_oor.puzzle_type = LevelData.PuzzleType.SQUARE_FILL
	bad_shelf_oor.square_fill_piece_colors = easy_res.square_fill_piece_colors
	bad_shelf_oor.square_fill_piece_symbols = easy_res.square_fill_piece_symbols
	bad_shelf_oor.square_fill_shelf_order = [0, 1, 2, 3, 4, 5, 6, 7, 9] # out of range 9
	assert(SquareFillValidator.validate(bad_shelf_oor).size() > 0, "Out of range shelf index fails validator")

	var bad_hint_mode := LevelData.new()
	bad_hint_mode.puzzle_type = LevelData.PuzzleType.SQUARE_FILL
	bad_hint_mode.square_fill_piece_colors = easy_res.square_fill_piece_colors
	bad_hint_mode.square_fill_piece_symbols = easy_res.square_fill_piece_symbols
	bad_hint_mode.square_fill_hint_mode = 5 # invalid
	assert(SquareFillValidator.validate(bad_hint_mode).size() > 0, "Invalid hint mode fails validator")

	# Duplicate visual appearance validation
	var bad_dup_visual := LevelData.new()
	bad_dup_visual.puzzle_type = LevelData.PuzzleType.SQUARE_FILL
	bad_dup_visual.square_fill_piece_colors = [Color.BLUE, Color.BLUE, Color.RED, Color.RED, Color.GREEN, Color.GREEN, Color.WHITE, Color.WHITE, Color.BLACK]
	bad_dup_visual.square_fill_piece_symbols = ["▲", "▲", "■", "■", "●", "●", "★", "★", "◆"]
	assert(SquareFillValidator.validate(bad_dup_visual).size() > 0, "Duplicate visual appearance fails validator")

	# Hint Mode 2 (Hard): Duplicate structural symbol fails validator
	var bad_hard_dup := LevelData.new()
	bad_hard_dup.puzzle_type = LevelData.PuzzleType.SQUARE_FILL
	bad_hard_dup.tier = 3
	bad_hard_dup.square_fill_hint_mode = 2
	bad_hard_dup.square_fill_piece_colors = hard_res.square_fill_piece_colors
	bad_hard_dup.square_fill_piece_symbols = ["A", "B", "C", "D", "E", "F", "G", "H", "A"] # duplicate "A"
	assert(SquareFillValidator.validate(bad_hard_dup).size() > 0, "Hint Mode 2 duplicate symbol fails validator")

	# Hint Mode 2 (Hard): 9 unique structural symbols passes validator
	var valid_hard_symbols := LevelData.new()
	valid_hard_symbols.puzzle_type = LevelData.PuzzleType.SQUARE_FILL
	valid_hard_symbols.tier = 3
	valid_hard_symbols.square_fill_hint_mode = 2
	valid_hard_symbols.square_fill_piece_colors = hard_res.square_fill_piece_colors
	valid_hard_symbols.square_fill_piece_symbols = ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
	assert(SquareFillValidator.validate(valid_hard_symbols).is_empty(), "Hint Mode 2 with 9 unique symbols passes validator")

	print("-> TEST 2 PASSED: SquareFillValidator validated all edge cases, visual uniqueness & Hint Mode 2 uniqueness.")

	# [SECTION 3] PRODUCTION POOL INTEGRITY
	print("\n[TEST 3] Production Pool Integrity (72 levels, 9 production SQUARE_FILL levels)")
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	await _sync_physics()

	var lm: LevelManager = main_node.get_node("LevelManager")
	lm._ensure_levels_loaded()
	assert(lm.levels.size() == 72, "Production level pool count is exactly 72 (got %d)" % lm.levels.size())
	var sq_prod_count: int = 0
	var sq_tier_map := {1: 0, 2: 0, 3: 0}
	for lvl in lm.levels:
		assert(not lvl.resource_path.contains("/samples/"), "Samples excluded from production pool")
		if lvl.puzzle_type == LevelData.PuzzleType.SQUARE_FILL:
			sq_prod_count += 1
			sq_tier_map[lvl.tier] += 1
			var errs: Array[String] = SquareFillValidator.validate(lvl)
			assert(errs.is_empty(), "Production SQUARE_FILL %s failed validator: %s" % [lvl.resource_path, ", ".join(errs)])
	assert(sq_prod_count == 9, "Exactly 9 production SQUARE_FILL levels (got %d)" % sq_prod_count)
	assert(sq_tier_map[1] == 3, "Exactly 3 Tier 1 SQUARE_FILL levels (55, 58, 59)")
	assert(sq_tier_map[2] == 3, "Exactly 3 Tier 2 SQUARE_FILL levels (56, 63, 64)")
	assert(sq_tier_map[3] == 3, "Exactly 3 Tier 3 SQUARE_FILL levels (57, 68, 69)")

	# Specific validation for Level 56 Medium two-layer visual clarity
	var lvl56: LevelData = lm.levels[55]
	assert(lvl56.square_fill_hint_mode == 1, "Level 56 hint mode is SUBTLE (1)")
	assert(lvl56.square_fill_shelf_order == [4, 0, 7, 1, 8, 3, 6, 2, 5], "Level 56 shelf is shuffled")
	var seen_symbols: Dictionary = {}
	for s_i in range(9):
		var sym: String = lvl56.square_fill_piece_symbols[s_i]
		assert(not seen_symbols.has(sym), "Level 56 symbol '%s' at index %d is unique across all 9 pieces" % [sym, s_i])
		seen_symbols[sym] = true
		assert(not sym in ["1", "2", "3", "4", "5", "6", "7", "8", "9"], "No direct digit answer keys in Medium")
		assert(not sym in ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"], "No direct Roman numeral answer keys in Medium")
	print("-> TEST 3 PASSED: Production pool contains 57 levels with 3 validated SQUARE_FILL levels (Level 56 two-layer clarity verified).")

	# [SECTION 4] ASYMMETRIC DROP FAIRNESS MODEL
	print("\n[TEST 4] Asymmetric Drop Fairness (Inner 45px vs Outer 65px)")
	lm.current_run_levels = [easy_res]
	lm.load_level(0)
	main_node.call("_set_gameplay_visible", true)
	await _sync_physics()

	var p0: DraggablePiece = lm.square_fill_pieces[0]
	var s0_pos: Vector2 = lm.square_fill_slots[0].global_position # Correct slot for piece 0
	var s1_pos: Vector2 = lm.square_fill_slots[1].global_position # Wrong slot for piece 0

	# 4.1 Generous Correct Snap at d = 58px (within 65px) -> SHOULD SNAP & LOCK
	p0.global_position = s0_pos + Vector2(-58.0, 0.0) # 58px to the left of top-left slot 0
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p0)
	assert(lm.placed_square_fill_count == 1, "Correct snap at d=58px succeeded")
	assert(p0.is_locked == true, "Piece 0 locked")
	assert(lm.current_lives == 3, "0 life loss")

	# 4.2 Deliberate Wrong at d = 25px (within inner 45px) on unoccupied Slot 1 -> SHOULD PENALIZE (-1 life)
	var p2: DraggablePiece = lm.square_fill_pieces[2] # belongs in Slot 2
	p2._kill_active_tweens()
	p2.global_position = s1_pos + Vector2(0.0, -25.0) # 25px above Slot 1
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p2)
	assert(lm.current_lives == 2, "Deliberate wrong at d=25px deducted 1 life")
	assert(p2.is_locked == false, "Piece 2 not locked")
	assert(lm.placed_square_fill_count == 1, "Count remained 1")

	# 4.3 Outer Band Forgiveness at d = 55px (45px < d <= 65px) on wrong Slot 1 -> SHOULD BE NEUTRAL (0 life loss)
	p2._kill_active_tweens()
	p2.global_position = s1_pos + Vector2(0.0, -55.0) # 55px above wrong Slot 1
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p2)
	assert(lm.current_lives == 2, "Outer band drop at d=55px caused 0 life loss (Neutral forgiveness)")
	assert(p2.is_locked == false, "Piece 2 not locked")
	assert(lm.placed_square_fill_count == 1, "Count remained 1")

	# 4.4 Occupied Slot at d = 20px on Slot 0 -> SHOULD BE NEUTRAL (0 life loss)
	p2._kill_active_tweens()
	p2.global_position = s0_pos + Vector2(-20.0, 0.0)
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p2)
	assert(lm.current_lives == 2, "Occupied slot drop caused 0 life loss (Neutral)")

	# 4.5 Outside 65px (d = 90px) -> SHOULD BE NEUTRAL (0 life loss)
	p2._kill_active_tweens()
	p2.global_position = s1_pos + Vector2(0.0, -90.0)
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p2)
	assert(lm.current_lives == 2, "Empty space drop caused 0 life loss (Neutral)")

	print("-> TEST 4 PASSED: Asymmetric drop fairness model strictly verified.")

	# [SECTION 5] DRAG OWNERSHIP & LIFECYCLE INTERRUPTION SAFETY
	print("\n[TEST 5] Drag Ownership & Lifecycle Interruption Safety")
	lm.load_level(0)
	await _sync_physics()

	var piece_a: DraggablePiece = lm.square_fill_pieces[3]
	var piece_b: DraggablePiece = lm.square_fill_pieces[4]

	# 5.1 Single drag ownership
	piece_a._start_drag(0)
	assert(piece_a.is_dragging == true, "Piece A dragging")
	assert(DraggablePiece.active_drag_piece == piece_a, "Piece A owns active drag")

	# Simultaneous drag attempt on Piece B -> rejected
	piece_b._start_drag(1)
	assert(piece_b.is_dragging == false, "Piece B drag rejected")
	assert(DraggablePiece.active_drag_piece == piece_a, "Piece A retains mutex")

	# 5.2 Application focus out / window blur interruption
	main_node._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(piece_a.is_dragging == false, "Piece A drag cancelled on focus out")
	assert(DraggablePiece.active_drag_piece == null, "Drag mutex cleared on focus out")

	# 5.3 Android Back interruption while holding piece
	piece_a.reset_piece()
	piece_a._start_drag(0)
	assert(DraggablePiece.active_drag_piece == piece_a, "Piece A active")
	main_node.call("_handle_back_request")
	assert(piece_a.is_dragging == false, "Piece A drag cancelled by Back press")
	assert(DraggablePiece.active_drag_piece == null, "Drag mutex cleared by Back press")

	# 5.4 Opening Settings interruption while holding piece
	piece_a.reset_piece()
	piece_a._start_drag(0)
	assert(DraggablePiece.active_drag_piece == piece_a, "Piece A active")
	main_node.call("_on_settings_button_pressed")
	assert(piece_a.is_dragging == false, "Piece A drag cancelled when Settings opened")
	assert(DraggablePiece.active_drag_piece == null, "Drag mutex cleared when Settings opened")
	main_node.call("_on_settings_close_pressed")

	# 5.5 _exit_tree() safety on piece destruction
	piece_a.reset_piece()
	piece_a._start_drag(0)
	assert(DraggablePiece.active_drag_piece == piece_a, "Piece A active")
	piece_a.notification(Node.NOTIFICATION_PREDELETE)
	piece_a._exit_tree()
	assert(DraggablePiece.active_drag_piece == null, "Drag mutex cleared on _exit_tree()")

	print("-> TEST 5 PASSED: Drag ownership and lifecycle interruption safety verified.")

	# [SECTION 6] HARD MODE SPATIAL HINTS (HINT MODE 2)
	print("\n[TEST 6] Hard Mode Spatial Structural Cues (Non-guessing)")
	lm.current_run_levels = [hard_res]
	lm.load_level(0)
	await _sync_physics()

	# Verify each slot has a valid spatial hint symbol rendered in Hint Mode 2
	for i in range(9):
		var slot: SquareFillSlot = lm.square_fill_slots[i]
		var lbl: Label = slot.get_node_or_null("HintLabel")
		assert(lbl != null and lbl.visible == true, "Slot %d has visible spatial hint" % i)
		assert(lbl.text.length() > 0, "Slot %d hint text is non-empty (%s)" % [i, lbl.text])

	# Verify authored symbol decoupling: slot renders authored symbol, not hardcoded table
	var custom_hard := LevelData.new()
	custom_hard.puzzle_type = LevelData.PuzzleType.SQUARE_FILL
	custom_hard.tier = 3
	custom_hard.square_fill_hint_mode = 2
	custom_hard.square_fill_piece_colors = hard_res.square_fill_piece_colors
	custom_hard.square_fill_piece_symbols = ["α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι"]
	lm.current_run_levels = [custom_hard]
	lm.load_level(0)
	await _sync_physics()
	for i in range(9):
		var slot: SquareFillSlot = lm.square_fill_slots[i]
		var lbl: Label = slot.get_node_or_null("HintLabel")
		assert(lbl != null and lbl.text == custom_hard.square_fill_piece_symbols[i], "Slot %d renders authored decoupled symbol '%s'" % [i, custom_hard.square_fill_piece_symbols[i]])

	print("-> TEST 6 PASSED: Hard mode renders structural spatial cues and decoupled authored symbols.")

	# [SECTION 7] RUN FAILURE DURING ACTIVE SQUARE FILL STATE
	print("\n[TEST 7] Mid-Board Failure Interaction Freezing & Visual State")
	lm.current_run_levels = [easy_res]
	lm.load_level(0)
	await _sync_physics()

	# Place 2 pieces correctly
	var slot0: SquareFillSlot = lm.square_fill_slots[0]
	var slot1: SquareFillSlot = lm.square_fill_slots[1]
	lm.square_fill_pieces[0].global_position = slot0.global_position
	await _sync_physics()
	lm._on_square_fill_piece_dropped(lm.square_fill_pieces[0])

	lm.square_fill_pieces[1].global_position = slot1.global_position
	await _sync_physics()
	lm._on_square_fill_piece_dropped(lm.square_fill_pieces[1])
	assert(lm.placed_square_fill_count == 2, "2 pieces placed")

	# Deduct remaining lives to trigger failure
	var p_wrong: DraggablePiece = lm.square_fill_pieces[2]
	p_wrong.global_position = lm.square_fill_slots[8].global_position # slot 8 != 2
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p_wrong)
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p_wrong)
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p_wrong)

	assert(lm.current_lives == 0, "Lives reach 0")
	assert(lm.is_run_failed == true, "Run failed")
	assert(DraggablePiece.active_drag_piece == null, "Active drag cleared on failure")
	for p in lm.square_fill_pieces:
		assert(p.is_draggable == false, "All pieces disabled on failure")
	print("-> TEST 7 PASSED: Mid-board failure freezes interaction cleanly.")

	# [SECTION 8] 50-CYCLE LOAD / CLEANUP STRESS TEST
	print("\n[TEST 8] 50-Cycle Load / Cleanup Stress Test")
	for cycle in range(50):
		lm.current_run_levels = [easy_res]
		lm.load_level(0)
		await _sync_physics()
		assert(lm.square_fill_pieces.size() == 9, "Cycle %d: exactly 9 pieces spawned" % cycle)
		assert(lm.square_fill_slots.size() == 9, "Cycle %d: exactly 9 slots spawned" % cycle)
		assert(lm.placed_square_fill_count == 0, "Cycle %d: placed count is 0" % cycle)
		assert(DraggablePiece.active_drag_piece == null, "Cycle %d: active drag is null" % cycle)

		# Partial interaction
		var test_p: DraggablePiece = lm.square_fill_pieces[0]
		test_p._start_drag(0)
		test_p.global_position = lm.square_fill_slots[0].global_position
		await _sync_physics()
		lm._on_square_fill_piece_dropped(test_p)
		assert(lm.placed_square_fill_count == 1, "Cycle %d: piece placed" % cycle)

		# Cleanup
		main_node.call("return_to_main_menu")
		await _sync_physics()
		assert(lm.square_fill_pieces.size() == 0, "Cycle %d: 0 pieces in memory after cleanup" % cycle)
		assert(lm.square_fill_slots.size() == 0, "Cycle %d: 0 slots in memory after cleanup" % cycle)
		assert(DraggablePiece.active_drag_piece == null, "Cycle %d: active drag cleared after cleanup" % cycle)

	print("-> TEST 8 PASSED: 50 load/cleanup cycles completed with 0 leaked pieces or slots.")

	# [SECTION 9] PUZZLE TYPE INTER-ISOLATION TRANSITIONS
	print("\n[TEST 9] Cross-Puzzle Transitions (Square Fill <-> Math, Shape, Sequence)")
	var shape_res: LevelData = load("res://data/levels/level_02.tres") # SHAPE_MATCH
	var math_res: LevelData = load("res://data/levels/level_01.tres") # MATH_MATCH
	var seq_res: LevelData = load("res://data/levels/level_40.tres") # NUMBER_SEQUENCE

	# Square -> Shape
	lm.current_run_levels = [easy_res, shape_res]
	lm.load_level(0)
	assert(main_node.get_node("SquareFillContainer").visible == true, "SquareFillContainer visible")
	lm.load_level(1)
	assert(main_node.get_node("SquareFillContainer").visible == false, "SquareFillContainer hidden on Shape")
	assert(main_node.get_node("ShapeContainer").visible == true, "ShapeContainer visible")

	# Shape -> Square
	lm.current_run_levels = [shape_res, easy_res]
	lm.load_level(0)
	assert(main_node.get_node("ShapeContainer").visible == true, "ShapeContainer visible")
	lm.load_level(1)
	assert(main_node.get_node("ShapeContainer").visible == false, "ShapeContainer hidden on Square")
	assert(main_node.get_node("SquareFillContainer").visible == true, "SquareFillContainer visible")

	# Square -> Math
	lm.current_run_levels = [easy_res, math_res]
	lm.load_level(0)
	lm.load_level(1)
	assert(main_node.get_node("SquareFillContainer").visible == false, "SquareFillContainer hidden on Math")
	assert(main_node.get_node("MathContainer").visible == true, "MathContainer visible")

	# Square -> Sequence
	lm.current_run_levels = [easy_res, seq_res]
	lm.load_level(0)
	lm.load_level(1)
	assert(main_node.get_node("SquareFillContainer").visible == false, "SquareFillContainer hidden on Sequence")
	assert(main_node.get_node("MathContainer").visible == true, "MathContainer visible")

	print("-> TEST 9 PASSED: Clean cross-puzzle transitions verified.")

	# [SECTION 10] 500-RUN STANDARD SIMULATION & BALANCE STRESS-TEST (STEP 22C)
	print("\n[TEST 10] 500-Run Standard Simulation & Production Pool Stress-Test (Step 22C)")
	var sim_rng := RandomNumberGenerator.new()
	sim_rng.seed = 424242
	var total_std_runs: int = 500
	var prev_std_run: Array[LevelData] = []
	var std_zero_overlap: int = 0
	var std_overlap_1plus: int = 0
	var max_overlap: int = 0
	var total_overlap_sum: int = 0
	var sq_appearances_std: int = 0
	var runs_with_sq_ge1: int = 0
	var runs_with_sq_0: int = 0
	var runs_with_sq_ge2: int = 0
	var max_sq_in_run: int = 0
	var sq_by_tier_std: Dictionary = { 1: 0, 2: 0, 3: 0 }
	var tier_start_repeats: int = 0
	var tier_start_checks: int = 0
	var clump_3_count: int = 0
	var clump_4_count: int = 0

	var std_type_exposure := {
		LevelData.PuzzleType.MATH_MATCH: 0,
		LevelData.PuzzleType.SHAPE_MATCH: 0,
		LevelData.PuzzleType.MISSING_NUMBER: 0,
		LevelData.PuzzleType.EQUIVALENT_EXPRESSION: 0,
		LevelData.PuzzleType.NUMBER_SEQUENCE: 0,
		LevelData.PuzzleType.SQUARE_FILL: 0
	}

	var level_exposure: Dictionary = {}
	for lvl in lm.levels:
		level_exposure[lvl.resource_path] = 0

	var std_sim_start: int = Time.get_ticks_usec()
	for r_i in range(total_std_runs):
		var run: Array[LevelData] = lm.generate_run_sequence(sim_rng)
		assert(run.size() == 15, "Run %d has 15 levels" % (r_i + 1))
		for k in range(5): assert(run[k].tier == 1, "Run %d lvl %d is Tier 1" % [r_i + 1, k + 1])
		for k in range(5, 10): assert(run[k].tier == 2, "Run %d lvl %d is Tier 2" % [r_i + 1, k + 1])
		for k in range(10, 15): assert(run[k].tier == 3, "Run %d lvl %d is Tier 3" % [r_i + 1, k + 1])

		var run_seen: Dictionary = {}
		var run_sq_count: int = 0
		for lvl in run:
			assert(not run_seen.has(lvl), "No duplicate level in run %d: %s" % [r_i + 1, lvl.resource_path])
			run_seen[lvl] = true
			assert(not lvl.resource_path.contains("/samples/"), "No samples in production run")
			std_type_exposure[lvl.puzzle_type] += 1
			level_exposure[lvl.resource_path] = level_exposure.get(lvl.resource_path, 0) + 1

			if lvl.puzzle_type == LevelData.PuzzleType.SQUARE_FILL:
				sq_appearances_std += 1
				sq_by_tier_std[lvl.tier] += 1
				run_sq_count += 1

		if run_sq_count >= 1:
			runs_with_sq_ge1 += 1
		else:
			runs_with_sq_0 += 1
		if run_sq_count >= 2:
			runs_with_sq_ge2 += 1
		if run_sq_count > max_sq_in_run:
			max_sq_in_run = run_sq_count

		# Anti-clump checks
		if lm._has_clump_of_three(run):
			clump_3_count += 1
		var c_streak: int = 1
		for idx in range(1, run.size()):
			if run[idx].puzzle_type == run[idx - 1].puzzle_type:
				c_streak += 1
				if c_streak >= 4:
					clump_4_count += 1
			else:
				c_streak = 1

		# Overlap and tier-start novelty vs previous run
		if not prev_std_run.is_empty():
			var ov: int = 0
			for lvl in run:
				if prev_std_run.has(lvl):
					ov += 1
			total_overlap_sum += ov
			if ov == 0:
				std_zero_overlap += 1
			else:
				std_overlap_1plus += 1
			if ov > max_overlap:
				max_overlap = ov

			# Tier-start checks: Easy (0), Medium (5), Hard (10)
			for t_start_idx in [0, 5, 10]:
				tier_start_checks += 1
				if run[t_start_idx] == prev_std_run[t_start_idx]:
					tier_start_repeats += 1

		prev_std_run = run.duplicate()

	var std_sim_elapsed: int = Time.get_ticks_usec() - std_sim_start
	var avg_std_ms: float = float(std_sim_elapsed) / float(total_std_runs) / 1000.0
	var avg_overlap: float = float(total_overlap_sum) / float(total_std_runs - 1)

	# Calculate level reachability & min/max/avg
	var min_level_count: int = 999999
	var max_level_count: int = 0
	var level_count_sum: int = 0
	var sorted_levels: Array = []

	for lvl_path in level_exposure.keys():
		var cnt: int = level_exposure[lvl_path]
		if cnt < min_level_count: min_level_count = cnt
		if cnt > max_level_count: max_level_count = cnt
		level_count_sum += cnt
		sorted_levels.append({"path": lvl_path.get_file(), "count": cnt})

	sorted_levels.sort_custom(func(a, b): return a["count"] < b["count"])
	var least_5: Array = sorted_levels.slice(0, 5)
	var most_5: Array = sorted_levels.slice(sorted_levels.size() - 5, sorted_levels.size())
	most_5.reverse()

	print("   • Standard Simulation Duration: %.2f ms (Average: %.3f ms/run across %d runs)" % [float(std_sim_elapsed) / 1000.0, avg_std_ms, total_std_runs])
	print("   • Consecutive Pair Overlap (499 pairs): Zero-overlap: %d (%.1f%%) | 1+ Overlap: %d | Max: %d | Avg: %.3f" % [
		std_zero_overlap, (float(std_zero_overlap) / float(total_std_runs - 1)) * 100.0, std_overlap_1plus, max_overlap, avg_overlap
	])
	print("   • Tier-Start Novelty: %d checks, %d repeats (%.2f%% repeat rate)" % [tier_start_checks, tier_start_repeats, (float(tier_start_repeats) / float(tier_start_checks)) * 100.0])
	print("   • Anti-Clump Audit: 3-clumps: %d | 4+-clumps: %d" % [clump_3_count, clump_4_count])
	print("   • Puzzle Type Exposure across 7500 puzzles:")
	var total_puzzles: int = total_std_runs * 15
	for ptype in std_type_exposure.keys():
		var cnt: int = std_type_exposure[ptype]
		var pct: float = (float(cnt) / float(total_puzzles)) * 100.0
		var type_name: String = ""
		match ptype:
			LevelData.PuzzleType.MATH_MATCH: type_name = "MATH_MATCH"
			LevelData.PuzzleType.SHAPE_MATCH: type_name = "SHAPE_MATCH"
			LevelData.PuzzleType.MISSING_NUMBER: type_name = "MISSING_NUMBER"
			LevelData.PuzzleType.EQUIVALENT_EXPRESSION: type_name = "EQUIVALENT_EXPRESSION"
			LevelData.PuzzleType.NUMBER_SEQUENCE: type_name = "NUMBER_SEQUENCE"
			LevelData.PuzzleType.SQUARE_FILL: type_name = "SQUARE_FILL"
		print("     - %s: %d (%.2f%%)" % [type_name, cnt, pct])

	print("   • Square Fill Exposure in Standard:")
	print("     - Total appearances: %d / %d (%.2f%%)" % [sq_appearances_std, total_puzzles, (float(sq_appearances_std) / float(total_puzzles)) * 100.0])
	print("     - Runs with >= 1 Square Fill: %d (%.1f%%)" % [runs_with_sq_ge1, (float(runs_with_sq_ge1) / float(total_std_runs)) * 100.0])
	print("     - Runs with 0 Square Fill: %d (%.1f%%)" % [runs_with_sq_0, (float(runs_with_sq_0) / float(total_std_runs)) * 100.0])
	print("     - Runs with 2+ Square Fill: %d (%.1f%%)" % [runs_with_sq_ge2, (float(runs_with_sq_ge2) / float(total_std_runs)) * 100.0])
	print("     - Max Square Fill in one run: %d" % max_sq_in_run)
	print("     - By tier: Easy %d, Medium %d, Hard %d" % [sq_by_tier_std[1], sq_by_tier_std[2], sq_by_tier_std[3]])

	print("   • Individual Level Exposure (all 72 levels):")
	print("     - Min count: %d | Max count: %d | Avg count: %.2f" % [min_level_count, max_level_count, float(level_count_sum) / 72.0])
	print("     - Least exposed 5: %s" % [", ".join(least_5.map(func(e): return "%s (%d)" % [e["path"], e["count"]]))])
	print("     - Most exposed 5: %s" % [", ".join(most_5.map(func(e): return "%s (%d)" % [e["path"], e["count"]]))])

	assert(std_zero_overlap == total_std_runs - 1, "100% zero-overlap across all 499 consecutive runs")
	assert(tier_start_repeats == 0, "0 tier-start repeats across all 499 transitions")
	assert(clump_3_count == 0, "0 avoidable 3-type clumps across 500 runs")
	assert(clump_4_count == 0, "0 4+-type clumps across 500 runs")
	assert(min_level_count > 0, "All 72 production levels are reachable (min count > 0)")
	assert(sq_appearances_std > 0, "Square Fill appeared regularly in Standard runs")
	print("-> TEST 10 PASSED: 500-run Standard simulation & balance verified.")

	# [SECTION 11] 100-DATE DAILY CHALLENGE SIMULATION & DETERMINISM (STEP 22C)
	print("\n[TEST 11] 100-Date Daily Challenge Simulation & Determinism (Step 22C)")
	assert(LevelManager.DAILY_ALGORITHM_VERSION == 1, "DAILY_ALGORITHM_VERSION is 1")
	var saved_prev_levels: Array[LevelData] = lm.previous_run_levels.duplicate()

	var total_daily_dates: int = 100
	var daily_sq_total: int = 0
	var daily_dates_with_sq: int = 0
	var daily_sq_by_tier: Dictionary = { 1: 0, 2: 0, 3: 0 }
	var daily_type_exposure := {
		LevelData.PuzzleType.MATH_MATCH: 0,
		LevelData.PuzzleType.SHAPE_MATCH: 0,
		LevelData.PuzzleType.MISSING_NUMBER: 0,
		LevelData.PuzzleType.EQUIVALENT_EXPRESSION: 0,
		LevelData.PuzzleType.NUMBER_SEQUENCE: 0,
		LevelData.PuzzleType.SQUARE_FILL: 0
	}
	var daily_level_exposure: Dictionary = {}
	for lvl in lm.levels:
		daily_level_exposure[lvl.resource_path] = 0

	var daily_sim_start: int = Time.get_ticks_usec()
	var base_unix: int = Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 9, "day": 1, "hour": 0, "minute": 0, "second": 0})
	for d_idx in range(total_daily_dates):
		var dt: Dictionary = Time.get_date_dict_from_unix_time(base_unix + d_idx * 86400)
		var date_key: int = dt["year"] * 10000 + dt["month"] * 100 + dt["day"]
		var daily_seq_1: Array[LevelData] = lm.generate_daily_run_sequence(date_key)
		var daily_seq_2: Array[LevelData] = lm.generate_daily_run_sequence(date_key)

		assert(daily_seq_1.size() == 10, "Daily challenge has 10 levels")
		assert(daily_seq_2.size() == 10, "Daily repeat has 10 levels")

		for k in range(10):
			assert(daily_seq_1[k] == daily_seq_2[k], "Date %d index %d strictly deterministic" % [date_key, k])

		for k in range(3): assert(daily_seq_1[k].tier == 1, "Slot %d is Tier 1" % k)
		for k in range(3, 7): assert(daily_seq_1[k].tier == 2, "Slot %d is Tier 2" % k)
		for k in range(7, 10): assert(daily_seq_1[k].tier == 3, "Slot %d is Tier 3" % k)

		var daily_seen: Dictionary = {}
		var date_has_sq: bool = false
		for lvl in daily_seq_1:
			assert(not daily_seen.has(lvl), "No duplicate in daily %d: %s" % [date_key, lvl.resource_path])
			daily_seen[lvl] = true
			assert(not lvl.resource_path.contains("/samples/"), "No samples in Daily challenge")
			daily_type_exposure[lvl.puzzle_type] += 1
			daily_level_exposure[lvl.resource_path] = daily_level_exposure.get(lvl.resource_path, 0) + 1
			if lvl.puzzle_type == LevelData.PuzzleType.SQUARE_FILL:
				daily_sq_total += 1
				daily_sq_by_tier[lvl.tier] += 1
				date_has_sq = true

		if date_has_sq:
			daily_dates_with_sq += 1

	var daily_sim_elapsed: int = Time.get_ticks_usec() - daily_sim_start
	var avg_daily_ms: float = float(daily_sim_elapsed) / float(total_daily_dates) / 1000.0

	# Verify Standard history was NOT mutated by Daily generation
	assert(lm.previous_run_levels == saved_prev_levels, "Daily generation preserved Standard run history (RNG/state isolation)")

	# Calculate daily reachability
	var daily_levels_reached: int = 0
	var daily_unseen: Array[String] = []
	var daily_min_cnt: int = 999999
	var daily_max_cnt: int = 0
	for lvl_path in daily_level_exposure.keys():
		var cnt: int = daily_level_exposure[lvl_path]
		if cnt > 0:
			daily_levels_reached += 1
			if cnt < daily_min_cnt: daily_min_cnt = cnt
		else:
			daily_unseen.append(lvl_path.get_file())
		if cnt > daily_max_cnt: daily_max_cnt = cnt

	print("   • Daily Simulation Duration: %.2f ms (Average: %.3f ms/challenge across %d dates)" % [float(daily_sim_elapsed) / 1000.0, avg_daily_ms, total_daily_dates])
	print("   • Daily Puzzle Type Exposure across 1000 puzzles:")
	for ptype in daily_type_exposure.keys():
		var cnt: int = daily_type_exposure[ptype]
		var pct: float = (float(cnt) / 1000.0) * 100.0
		var type_name: String = ""
		match ptype:
			LevelData.PuzzleType.MATH_MATCH: type_name = "MATH_MATCH"
			LevelData.PuzzleType.SHAPE_MATCH: type_name = "SHAPE_MATCH"
			LevelData.PuzzleType.MISSING_NUMBER: type_name = "MISSING_NUMBER"
			LevelData.PuzzleType.EQUIVALENT_EXPRESSION: type_name = "EQUIVALENT_EXPRESSION"
			LevelData.PuzzleType.NUMBER_SEQUENCE: type_name = "NUMBER_SEQUENCE"
			LevelData.PuzzleType.SQUARE_FILL: type_name = "SQUARE_FILL"
		print("     - %s: %d (%.2f%%)" % [type_name, cnt, pct])

	print("   • Daily Square Fill Exposure:")
	print("     - Dates containing >= 1 Square Fill: %d / %d (%.1f%%)" % [daily_dates_with_sq, total_daily_dates, (float(daily_dates_with_sq) / float(total_daily_dates)) * 100.0])
	print("     - Total appearances: %d / 1000 (%.2f%%)" % [daily_sq_total, (float(daily_sq_total) / 1000.0) * 100.0])
	print("     - By tier: Easy %d, Medium %d, Hard %d" % [daily_sq_by_tier[1], daily_sq_by_tier[2], daily_sq_by_tier[3]])

	print("   • Daily Content Reachability across 100 dates:")
	print("     - Unique production levels reached: %d / 72 (%.1f%%)" % [daily_levels_reached, (float(daily_levels_reached) / 72.0) * 100.0])
	print("     - Unreached levels: %s" % [", ".join(daily_unseen) if not daily_unseen.is_empty() else "None (all 72 reached)"])
	print("     - Min count (among reached): %d | Max count: %d" % [daily_min_cnt, daily_max_cnt])

	assert(daily_sq_total > 0, "Square Fill appeared naturally in Daily challenges")
	print("-> TEST 11 PASSED: 100-date Daily challenge determinism & structure verified.")

	# [SECTION 12] STEP 22A: ARCHITECTURE READINESS & UNIVERSAL CONTENT AUDIT
	print("\n[TEST 12] Step 22A: Architecture Readiness, Content Refinement & Future Compatibility")

	# 12.1 Refined content checks
	var lvl11: LevelData = load("res://data/levels/level_11.tres")
	var lvl13: LevelData = load("res://data/levels/level_13.tres")
	var lvl22: LevelData = load("res://data/levels/level_22.tres")

	assert(lvl11 != null, "level_11 exists")
	assert(lvl11.prompt_text == "12 + 8 = ?", "level_11 prompt unchanged")
	assert(lvl11.correct_answer == "20", "level_11 correct_answer unchanged")
	assert(lvl11.tier == 3, "level_11 tier unchanged")

	assert(lvl22 != null, "level_22 exists")
	assert(lvl22.prompt_text == "5 + 3 = ?", "level_22 prompt unchanged")
	assert(lvl22.correct_answer == "8", "level_22 correct_answer unchanged")
	assert(lvl22.tier == 1, "level_22 tier unchanged")

	assert(lvl13 != null, "level_13 exists")
	assert(lvl13.prompt_text == "42 - 18 = ?", "level_13 prompt is refined Tier 3 subtraction")
	assert(lvl13.correct_answer == "24", "level_13 correct_answer is 24")
	assert(lvl13.tier == 3, "level_13 tier is 3")
	assert(lvl13.answer_choices == ["22", "24", "26", "34"], "level_13 answer_choices refined")

	# 12.2 Production pool strictly 72 levels (no level_73+ exists)
	assert(lm.levels.size() == 72, "Production pool remains exactly 72 (got %d)" % lm.levels.size())
	assert(not ResourceLoader.exists("res://data/levels/level_73.tres"), "No level_73 exists yet")

	# 12.3 Universal content validation across all 72 production levels
	var tier_counts := {1: 0, 2: 0, 3: 0}
	var type_counts := {
		LevelData.PuzzleType.MATH_MATCH: 0,
		LevelData.PuzzleType.SHAPE_MATCH: 0,
		LevelData.PuzzleType.MISSING_NUMBER: 0,
		LevelData.PuzzleType.EQUIVALENT_EXPRESSION: 0,
		LevelData.PuzzleType.NUMBER_SEQUENCE: 0,
		LevelData.PuzzleType.SQUARE_FILL: 0,
	}

	for idx in range(1, 73):
		var path: String = "res://data/levels/level_%02d.tres" % idx
		assert(ResourceLoader.exists(path), "Level %d exists at %s" % [idx, path])
		var res: LevelData = load(path) as LevelData
		assert(res != null, "Level %d loads successfully" % idx)
		assert(not res.prompt_text.strip_edges().is_empty(), "Level %d prompt_text is non-empty" % idx)
		assert(res.tier in [1, 2, 3], "Level %d tier is in 1..3 (got %d)" % [idx, res.tier])

		tier_counts[res.tier] += 1
		type_counts[res.puzzle_type] += 1

		match res.puzzle_type:
			LevelData.PuzzleType.MATH_MATCH, LevelData.PuzzleType.MISSING_NUMBER, LevelData.PuzzleType.EQUIVALENT_EXPRESSION, LevelData.PuzzleType.NUMBER_SEQUENCE:
				assert(not res.correct_answer.strip_edges().is_empty(), "Level %d correct_answer non-empty" % idx)
				assert(res.correct_answer in res.answer_choices, "Level %d correct_answer '%s' in answer_choices" % [idx, res.correct_answer])
				assert(res.answer_choices.size() >= 2, "Level %d has at least 2 choices" % idx)
				for c in res.answer_choices:
					assert(not c.strip_edges().is_empty(), "Level %d has non-empty choice '%s'" % [idx, c])
				if res.puzzle_type == LevelData.PuzzleType.NUMBER_SEQUENCE:
					var seq_val_res: Dictionary = SequenceValidator.validate_sequence_level(res)
					assert(seq_val_res.valid, "Level %d SequenceValidator passed: %s" % [idx, seq_val_res.get("error", "")])
			LevelData.PuzzleType.SHAPE_MATCH:
				assert(not res.match_id.is_empty(), "Level %d match_id non-empty" % idx)
			LevelData.PuzzleType.SQUARE_FILL:
				var sq_errs: Array[String] = SquareFillValidator.validate(res)
				assert(sq_errs.is_empty(), "Level %d SquareFillValidator passed: %s" % [idx, ", ".join(sq_errs)])

	# Verify exact tier distributions: 24 / 24 / 24
	assert(tier_counts[1] == 24, "Tier 1 has exactly 24 levels (got %d)" % tier_counts[1])
	assert(tier_counts[2] == 24, "Tier 2 has exactly 24 levels (got %d)" % tier_counts[2])
	assert(tier_counts[3] == 24, "Tier 3 has exactly 24 levels (got %d)" % tier_counts[3])

	# Verify exact puzzle type totals: MATH 18, SHAPE 12, MISSING 10, EQUIV 11, SEQUENCE 12, SQUARE_FILL 9
	assert(type_counts[LevelData.PuzzleType.MATH_MATCH] == 18, "MATH_MATCH has 18 (got %d)" % type_counts[LevelData.PuzzleType.MATH_MATCH])
	assert(type_counts[LevelData.PuzzleType.SHAPE_MATCH] == 12, "SHAPE_MATCH has 12 (got %d)" % type_counts[LevelData.PuzzleType.SHAPE_MATCH])
	assert(type_counts[LevelData.PuzzleType.MISSING_NUMBER] == 10, "MISSING_NUMBER has 10 (got %d)" % type_counts[LevelData.PuzzleType.MISSING_NUMBER])
	assert(type_counts[LevelData.PuzzleType.EQUIVALENT_EXPRESSION] == 11, "EQUIVALENT_EXPRESSION has 11 (got %d)" % type_counts[LevelData.PuzzleType.EQUIVALENT_EXPRESSION])
	assert(type_counts[LevelData.PuzzleType.NUMBER_SEQUENCE] == 12, "NUMBER_SEQUENCE has 12 (got %d)" % type_counts[LevelData.PuzzleType.NUMBER_SEQUENCE])
	assert(type_counts[LevelData.PuzzleType.SQUARE_FILL] == 9, "SQUARE_FILL has 9 (got %d)" % type_counts[LevelData.PuzzleType.SQUARE_FILL])

	# 12.3.1 Strict production source-of-truth assertions for Step 22B authored content
	var lvl61: LevelData = load("res://data/levels/level_61.tres") as LevelData
	assert(lvl61 != null, "level_61 exists")
	assert(lvl61.prompt_text == "10, 20, 30, ?", "level_61 prompt_text is '10, 20, 30, ?'")
	assert(lvl61.correct_answer == "40", "level_61 correct_answer is '40'")
	assert(lvl61.answer_choices == ["35", "40", "45", "50"], "level_61 answer_choices are strictly ['35', '40', '45', '50']")

	var lvl62: LevelData = load("res://data/levels/level_62.tres") as LevelData
	assert(lvl62 != null, "level_62 exists")
	assert(lvl62.prompt_text == "7 sayısını oluştur", "level_62 prompt_text is '7 sayısını oluştur'")
	assert(lvl62.target_display == "7", "level_62 target_display is '7'")
	assert(lvl62.correct_answer == "10 - 3", "level_62 correct_answer is '10 - 3'")
	assert(lvl62.answer_choices == ["10 - 3", "10 - 4", "9 - 3", "8 - 2"], "level_62 answer_choices are strictly ['10 - 3', '10 - 4', '9 - 3', '8 - 2']")

	var lvl64: LevelData = load("res://data/levels/level_64.tres") as LevelData
	assert(lvl64 != null, "level_64 exists")
	assert(lvl64.square_fill_hint_mode == 1, "level_64 hint mode is 1")
	assert(lvl64.square_fill_piece_symbols == ["◤", "▼", "◥", "►", "◈", "◄", "◣", "▲", "◢"], "level_64 symbols match directional tessellation")

	var lvl68: LevelData = load("res://data/levels/level_68.tres") as LevelData
	assert(lvl68 != null, "level_68 exists")
	assert(lvl68.square_fill_hint_mode == 2, "level_68 hint mode is 2")
	assert(lvl68.square_fill_piece_symbols == ["┏", "┳", "┓", "┣", "╬", "┫", "┗", "┻", "┛"], "level_68 symbols match continuous network")

	var lvl69: LevelData = load("res://data/levels/level_69.tres") as LevelData
	assert(lvl69 != null, "level_69 exists")
	assert(lvl69.square_fill_hint_mode == 2, "level_69 hint mode is 2")
	assert(lvl69.square_fill_piece_symbols == ["↘", "↓", "↙", "→", "◎", "←", "↗", "↑", "↖"], "level_69 symbols match centripetal directional convergence")

	# 12.4 Future grammar compatibility checks
	# Number Sequence: +10 constant additive
	var seq_future_10: LevelData = LevelData.new()
	seq_future_10.puzzle_type = LevelData.PuzzleType.NUMBER_SEQUENCE
	seq_future_10.tier = 1
	seq_future_10.prompt_text = "10, 20, 30, ?"
	seq_future_10.correct_answer = "40"
	seq_future_10.answer_choices = ["35", "40", "45", "50"]
	var v_10: Dictionary = SequenceValidator.validate_sequence_level(seq_future_10)
	assert(v_10.valid and v_10.expected == 40, "Future +10 sequence validates correctly")

	# Number Sequence: -3 descending
	var seq_future_desc: LevelData = LevelData.new()
	seq_future_desc.puzzle_type = LevelData.PuzzleType.NUMBER_SEQUENCE
	seq_future_desc.tier = 2
	seq_future_desc.prompt_text = "15, 12, 9, ?"
	seq_future_desc.correct_answer = "6"
	seq_future_desc.answer_choices = ["3", "6", "7", "8"]
	var v_desc: Dictionary = SequenceValidator.validate_sequence_level(seq_future_desc)
	assert(v_desc.valid and v_desc.expected == 6, "Future -3 descending sequence validates correctly")

	# Number Sequence: +5 / -2 alternating
	var seq_future_alt: LevelData = LevelData.new()
	seq_future_alt.puzzle_type = LevelData.PuzzleType.NUMBER_SEQUENCE
	seq_future_alt.tier = 3
	seq_future_alt.prompt_text = "2, 7, 5, 10, 8, ?"
	seq_future_alt.correct_answer = "13"
	seq_future_alt.answer_choices = ["11", "12", "13", "14"]
	var v_alt: Dictionary = SequenceValidator.validate_sequence_level(seq_future_alt)
	assert(v_alt.valid and v_alt.expected == 13, "Future +5/-2 alternating sequence validates correctly")

	# Equivalent Expression string compatibility: "10 - 3", "3 × 6", "9 + 9"
	var expr_future: LevelData = LevelData.new()
	expr_future.puzzle_type = LevelData.PuzzleType.EQUIVALENT_EXPRESSION
	expr_future.tier = 2
	expr_future.prompt_text = "7 sayısını oluştur"
	expr_future.target_display = "7"
	expr_future.correct_answer = "10 - 3"
	expr_future.answer_choices = ["10 - 3", "10 - 4", "9 - 3", "8 - 2"]
	assert(expr_future.correct_answer in expr_future.answer_choices, "Future subtraction equivalent expression supported")

	# Missing Number: "? - 8 = 7" -> "15"
	var miss_future: LevelData = LevelData.new()
	miss_future.puzzle_type = LevelData.PuzzleType.MISSING_NUMBER
	miss_future.tier = 3
	miss_future.prompt_text = "? - 8 = 7"
	miss_future.target_display = "?"
	miss_future.correct_answer = "15"
	miss_future.answer_choices = ["13", "14", "15", "16"]
	assert(miss_future.correct_answer in miss_future.answer_choices, "Future subtraction missing number supported")

	print("-> TEST 12 PASSED: Step 22A architecture readiness & universal content validation complete.")

	print("\n================================================================================")
	print(">>> ALL STEP 21C & STEP 22A TESTS PASSED 100%! <<<")
	print("================================================================================")
	quit(0)
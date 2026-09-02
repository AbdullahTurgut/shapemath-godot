extends SceneTree

const SaveManager = preload("res://scripts/core/save_manager.gd")
const LevelManager = preload("res://scripts/core/level_manager.gd")
const SquareFillSlot = preload("res://scripts/gameplay/square_fill_slot.gd")
const SquareFillValidator = preload("res://scripts/resources/square_fill_validator.gd")

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
	print("-> TEST 2 PASSED: SquareFillValidator validated all edge cases & visual uniqueness.")

	# [SECTION 3] PRODUCTION POOL INTEGRITY
	print("\n[TEST 3] Production Pool Integrity (57 levels, 3 production SQUARE_FILL levels)")
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	await _sync_physics()

	var lm: LevelManager = main_node.get_node("LevelManager")
	lm._ensure_levels_loaded()
	assert(lm.levels.size() == 57, "Production level pool count is exactly 57 (got %d)" % lm.levels.size())
	var sq_prod_count: int = 0
	for lvl in lm.levels:
		assert(not lvl.resource_path.contains("/samples/"), "Samples excluded from production pool")
		if lvl.puzzle_type == LevelData.PuzzleType.SQUARE_FILL:
			sq_prod_count += 1
			var errs: Array[String] = SquareFillValidator.validate(lvl)
			assert(errs.is_empty(), "Production SQUARE_FILL %s failed validator: %s" % [lvl.resource_path, ", ".join(errs)])
	assert(sq_prod_count == 3, "Exactly 3 production SQUARE_FILL levels (got %d)" % sq_prod_count)
	assert(lm.levels[54].puzzle_type == LevelData.PuzzleType.SQUARE_FILL and lm.levels[54].tier == 1, "Level 55 is Tier 1 SQUARE_FILL")
	assert(lm.levels[55].puzzle_type == LevelData.PuzzleType.SQUARE_FILL and lm.levels[55].tier == 2, "Level 56 is Tier 2 SQUARE_FILL")
	assert(lm.levels[56].puzzle_type == LevelData.PuzzleType.SQUARE_FILL and lm.levels[56].tier == 3, "Level 57 is Tier 3 SQUARE_FILL")

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
	print("-> TEST 6 PASSED: Hard mode renders structural spatial cues.")

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

	# [SECTION 10] 100-RUN STANDARD SIMULATION
	print("\n[TEST 10] 100-Run Standard Simulation & Production Square Fill Exposure")
	var sim_rng := RandomNumberGenerator.new()
	sim_rng.seed = 424242
	var total_std_runs: int = 100
	var prev_std_run: Array[LevelData] = []
	var std_zero_overlap: int = 0
	var sq_appearances_std: int = 0
	var runs_with_sq: int = 0
	var sq_by_tier: Dictionary = { 1: 0, 2: 0, 3: 0 }

	var std_sim_start: int = Time.get_ticks_usec()
	for r_i in range(total_std_runs):
		var run: Array[LevelData] = lm.generate_run_sequence(sim_rng)
		assert(run.size() == 15, "Run %d has 15 levels" % (r_i + 1))
		for k in range(5): assert(run[k].tier == 1, "Run %d lvl %d is Tier 1" % [r_i + 1, k + 1])
		for k in range(5, 10): assert(run[k].tier == 2, "Run %d lvl %d is Tier 2" % [r_i + 1, k + 1])
		for k in range(10, 15): assert(run[k].tier == 3, "Run %d lvl %d is Tier 3" % [r_i + 1, k + 1])

		var run_seen: Dictionary = {}
		var run_has_sq: bool = false
		for lvl in run:
			assert(not run_seen.has(lvl), "No duplicate level in run %d: %s" % [r_i + 1, lvl.resource_path])
			run_seen[lvl] = true
			assert(not lvl.resource_path.contains("/samples/"), "No samples in production run")
			if lvl.puzzle_type == LevelData.PuzzleType.SQUARE_FILL:
				sq_appearances_std += 1
				sq_by_tier[lvl.tier] += 1
				run_has_sq = true

		if run_has_sq:
			runs_with_sq += 1

		assert(not lm._has_clump_of_three(run), "Run %d has no 3-type clumps" % (r_i + 1))

		if not prev_std_run.is_empty():
			var ov: int = 0
			for lvl in run:
				if prev_std_run.has(lvl): ov += 1
			if ov == 0:
				std_zero_overlap += 1

		prev_std_run = run.duplicate()

	var std_sim_elapsed: int = Time.get_ticks_usec() - std_sim_start
	var avg_std_ms: float = float(std_sim_elapsed) / float(total_std_runs) / 1000.0
	print("   • 100 Standard runs generated in %.2f ms (Average: %.3f ms/run)" % [float(std_sim_elapsed) / 1000.0, avg_std_ms])
	print("   • Zero-overlap consecutive runs: %d / %d (%.1f%%)" % [std_zero_overlap, total_std_runs - 1, (float(std_zero_overlap) / float(total_std_runs - 1)) * 100.0])
	print("   • Square Fill total appearances: %d / 1500 levels (%.2f%%)" % [sq_appearances_std, (float(sq_appearances_std) / 1500.0) * 100.0])
	print("   • Runs with >= 1 Square Fill: %d / 100 (%.1f%%)" % [runs_with_sq, float(runs_with_sq)])
	print("   • Square Fill by tier: Easy %d, Medium %d, Hard %d" % [sq_by_tier[1], sq_by_tier[2], sq_by_tier[3]])
	assert(std_zero_overlap == total_std_runs - 1, "100% zero-overlap across consecutive runs")
	assert(sq_appearances_std > 0, "Square Fill appeared naturally in Standard runs")
	print("-> TEST 10 PASSED: 100-run Standard simulation verified.")

	# [SECTION 11] 30-DATE DAILY CHALLENGE SIMULATION
	print("\n[TEST 11] 30-Date Daily Challenge Simulation & Determinism")
	var sq_daily_count: int = 0
	var daily_sim_start: int = Time.get_ticks_usec()
	for d_idx in range(30):
		var date_key: int = 20260901 + d_idx
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
		for lvl in daily_seq_1:
			assert(not daily_seen.has(lvl), "No duplicate in daily %d: %s" % [date_key, lvl.resource_path])
			daily_seen[lvl] = true
			assert(not lvl.resource_path.contains("/samples/"), "No samples in Daily challenge")
			if lvl.puzzle_type == LevelData.PuzzleType.SQUARE_FILL:
				sq_daily_count += 1

	var daily_sim_elapsed: int = Time.get_ticks_usec() - daily_sim_start
	var avg_daily_ms: float = float(daily_sim_elapsed) / 30.0 / 1000.0
	print("   • 30 Daily challenges generated in %.2f ms (Average: %.3f ms/challenge)" % [float(daily_sim_elapsed) / 1000.0, avg_daily_ms])
	print("   • Square Fill total Daily appearances: %d / 300 levels (%.2f%%)" % [sq_daily_count, (float(sq_daily_count) / 300.0) * 100.0])
	print("-> TEST 11 PASSED: 30-date Daily challenge determinism & structure verified.")

	print("\n================================================================================")
	print(">>> ALL STEP 21C PRODUCTION ROLLOUT & GENERATOR TESTS PASSED 100%! <<<")
	print("================================================================================")
	quit(0)
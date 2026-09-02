extends SceneTree

const SaveManager = preload("res://scripts/core/save_manager.gd")
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
	print("--- BEGINNING STEP 17D: 50-RUN VARIETY SIMULATION & HARDENING TESTS ---")
	print("================================================================================")

	var test_save_path: String = "user://test_save_step17d.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()
	var sm: SaveManager = main_node.get_node("SaveManager") as SaveManager
	sm.save_path = test_save_path
	sm.tutorial_completed = true
	sm.save_data()

	root.add_child(main_node)
	await process_frame
	await _sync_physics()

	var lm: LevelManager = main_node.get_node("LevelManager") as LevelManager
	lm.transition_delay = 0.01
	lm.summary_delay = 0.01
	lm.failure_delay = 0.01
	lm._ensure_levels_loaded()

	# ================================================================================
	# TEST 1: 50-RUN VARIETY SIMULATION & COOLDOWN / ANTI-CLUMPING VALIDATION
	# ================================================================================
	print("\n[TEST 1] Running 50 consecutive Standard Run simulations")
	var rng := RandomNumberGenerator.new()
	rng.seed = 123456789

	var type_exposure := {
		LevelData.PuzzleType.MATH_MATCH: 0,
		LevelData.PuzzleType.SHAPE_MATCH: 0,
		LevelData.PuzzleType.MISSING_NUMBER: 0,
		LevelData.PuzzleType.EQUIVALENT_EXPRESSION: 0,
		LevelData.PuzzleType.NUMBER_SEQUENCE: 0,
		LevelData.PuzzleType.SQUARE_FILL: 0
	}

	var total_runs: int = 50
	var prev_run: Array[LevelData] = []
	var zero_overlap_count: int = 0
	var tier_start_repeat_count: int = 0

	var gen_start_time: int = Time.get_ticks_usec()

	for r_idx in range(total_runs):
		var run: Array[LevelData] = lm.generate_run_sequence(rng)
		assert(run.size() == 15, "Run %d has exactly 15 levels" % (r_idx + 1))

		# 1. Structure check: 5 Easy, 5 Medium, 5 Hard
		for i in range(5):
			assert(run[i].tier == 1, "Run %d: level %d is Tier 1 (Easy)" % [r_idx + 1, i + 1])
		for i in range(5, 10):
			assert(run[i].tier == 2, "Run %d: level %d is Tier 2 (Medium)" % [r_idx + 1, i + 1])
		for i in range(10, 15):
			assert(run[i].tier == 3, "Run %d: level %d is Tier 3 (Hard)" % [r_idx + 1, i + 1])

		# 2. No duplicate levels in run
		var seen_in_run: Array[LevelData] = []
		for lvl in run:
			assert(not seen_in_run.has(lvl), "Run %d has duplicate level: %s" % [r_idx + 1, lvl.resource_path])
			seen_in_run.append(lvl)
			assert(lvl.resource_path.begins_with("res://data/levels/level_"), "Run %d: level is from production pool: %s" % [r_idx + 1, lvl.resource_path])
			assert(not lvl.resource_path.contains("/samples/"), "Run %d: sample level leaked into run: %s" % [r_idx + 1, lvl.resource_path])

			# Track exposure
			type_exposure[lvl.puzzle_type] += 1

		# 3. Anti-clumping verification: No 3 consecutive same puzzle types
		assert(not lm._has_clump_of_three(run), "Run %d: anti-clumping check failed" % (r_idx + 1))

		# 4. Consecutive run overlap cooldown check
		if not prev_run.is_empty():
			var overlap: int = 0
			for lvl in run:
				if prev_run.has(lvl):
					overlap += 1
			if overlap == 0:
				zero_overlap_count += 1

			# Tier-start anti-repeat check
			if run[0] == prev_run[0] or run[5] == prev_run[5] or run[10] == prev_run[10]:
				tier_start_repeat_count += 1

		prev_run = run.duplicate()

	var gen_elapsed_usec: int = Time.get_ticks_usec() - gen_start_time
	var avg_gen_time_ms: float = float(gen_elapsed_usec) / float(total_runs) / 1000.0

	print("-> 50 Runs Generated in %.2f ms (Average: %.3f ms per run)" % [float(gen_elapsed_usec) / 1000.0, avg_gen_time_ms])
	print("-> Zero-overlap consecutive runs: %d / %d (%.1f%%)" % [zero_overlap_count, total_runs - 1, (float(zero_overlap_count) / float(total_runs - 1)) * 100.0])
	print("-> Tier-start repeats: %d / %d" % [tier_start_repeat_count, total_runs - 1])
	print("-> Puzzle Type Exposure across 750 levels:")
	print("   • MATH_MATCH: %d (%.1f%%)" % [type_exposure[LevelData.PuzzleType.MATH_MATCH], (float(type_exposure[LevelData.PuzzleType.MATH_MATCH]) / 750.0) * 100.0])
	print("   • SHAPE_MATCH: %d (%.1f%%)" % [type_exposure[LevelData.PuzzleType.SHAPE_MATCH], (float(type_exposure[LevelData.PuzzleType.SHAPE_MATCH]) / 750.0) * 100.0])
	print("   • MISSING_NUMBER: %d (%.1f%%)" % [type_exposure[LevelData.PuzzleType.MISSING_NUMBER], (float(type_exposure[LevelData.PuzzleType.MISSING_NUMBER]) / 750.0) * 100.0])
	print("   • EQUIVALENT_EXPRESSION: %d (%.1f%%)" % [type_exposure[LevelData.PuzzleType.EQUIVALENT_EXPRESSION], (float(type_exposure[LevelData.PuzzleType.EQUIVALENT_EXPRESSION]) / 750.0) * 100.0])
	print("   • NUMBER_SEQUENCE: %d (%.1f%%)" % [type_exposure[LevelData.PuzzleType.NUMBER_SEQUENCE], (float(type_exposure[LevelData.PuzzleType.NUMBER_SEQUENCE]) / 750.0) * 100.0])
	print("   • SQUARE_FILL: %d (%.1f%%)" % [type_exposure[LevelData.PuzzleType.SQUARE_FILL], (float(type_exposure[LevelData.PuzzleType.SQUARE_FILL]) / 750.0) * 100.0])

	assert(zero_overlap_count == total_runs - 1, "100% of consecutive runs had 0 overlap under 19-candidate pool")
	assert(type_exposure[LevelData.PuzzleType.SQUARE_FILL] > 0, "SQUARE_FILL actively appeared in runs")
	assert(tier_start_repeat_count == 0, "Tier-start anti-repeat prevented any consecutive tier-start duplicates")
	print("-> TEST 1 PASSED: Multi-run variety, cooldown, and anti-clumping verified.")

	# ================================================================================
	# TEST 2: PRODUCTION NUMBER_SEQUENCE INTERACTION (EASY, MEDIUM, HARD)
	# ================================================================================
	print("\n[TEST 2] Testing live gameplay interaction on production sequence levels (40, 47, 52)")
	var prod_easy: LevelData = load("res://data/levels/level_40.tres") # Easy: "2, 4, 6, ?" -> 8
	var prod_med: LevelData = load("res://data/levels/level_47.tres")  # Med: "3, 6, 12, ?" -> 24
	var prod_hard: LevelData = load("res://data/levels/level_52.tres") # Hard: "2, 5, 9, 14, ?" -> 20

	var prod_test_levels: Array[LevelData] = [prod_easy, prod_med, prod_hard]
	lm.current_run_levels = prod_test_levels.duplicate()
	lm.current_lives = 3
	lm.current_streak = 0
	lm.mistakes_this_run = 0

	# 2.1: Easy Level 40
	lm.load_level(0)
	await process_frame
	await _sync_physics()

	assert(lm.prompt_label.text == "2, 4, 6, ?", "Prompt renders '2, 4, 6, ?'")
	assert(lm.math_pieces.size() == 4, "4 draggable pieces")

	# Neutral drop
	var p0: DraggablePiece = lm.math_pieces[0]
	p0.global_position = Vector2(0, 0)
	await _sync_physics()
	lm._on_math_piece_dropped(p0)
	assert(lm.current_lives == 3, "Neutral drop loses no life")

	# Wrong drop
	var wrong_p: DraggablePiece = null
	for p in lm.math_pieces:
		if p.piece_text != "8":
			wrong_p = p
			break
	assert(wrong_p != null)
	wrong_p.global_position = lm.math_target_zone.global_position
	await _sync_physics()
	lm._on_math_piece_dropped(wrong_p)
	assert(lm.current_lives == 2, "Wrong drop loses 1 life")
	assert(lm.current_streak == 0, "Streak reset")

	# Correct drop
	var correct_p: DraggablePiece = null
	for p in lm.math_pieces:
		if p.piece_text == "8":
			correct_p = p
			break
	assert(correct_p != null)
	correct_p.global_position = lm.math_target_zone.global_position
	await _sync_physics()
	lm._on_math_piece_dropped(correct_p)
	await lm.level_completed

	assert(lm.current_streak == 1, "Streak is 1")
	assert(sm.get_total_puzzles_solved() == 1, "total_puzzles_solved is 1")

	if lm.transition_tween:
		await lm.transition_tween.finished
	await process_frame
	await _sync_physics()

	# 2.2: Medium Level 47
	lm.load_level(1)
	await process_frame
	await _sync_physics()

	assert(lm.prompt_label.text == "3, 6, 12, ?", "Medium prompt is '3, 6, 12, ?'")
	var med_correct: DraggablePiece = null
	for p in lm.math_pieces:
		if p.piece_text == "24":
			med_correct = p
			break
	assert(med_correct != null)
	med_correct.global_position = lm.math_target_zone.global_position
	await _sync_physics()
	lm._on_math_piece_dropped(med_correct)
	await lm.level_completed

	assert(lm.current_streak == 2, "Streak is 2")
	assert(sm.get_total_puzzles_solved() == 2, "total_puzzles_solved is 2")

	if lm.transition_tween:
		await lm.transition_tween.finished
	await process_frame
	await _sync_physics()

	# 2.3: Hard Level 52
	lm.load_level(2)
	await process_frame
	await _sync_physics()

	assert(lm.prompt_label.text == "2, 5, 9, 14, ?", "Hard prompt is '2, 5, 9, 14, ?'")
	var hard_correct: DraggablePiece = null
	for p in lm.math_pieces:
		if p.piece_text == "20":
			hard_correct = p
			break
	assert(hard_correct != null)
	hard_correct.global_position = lm.math_target_zone.global_position
	await _sync_physics()
	lm._on_math_piece_dropped(hard_correct)
	await lm.level_completed

	assert(lm.current_streak == 3, "Streak is 3")
	assert(sm.get_total_puzzles_solved() == 3, "total_puzzles_solved is 3")
	print("-> TEST 2 PASSED: Production sequence levels interaction verified.")

	# Clean up test save file
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	print("\n================================================================================")
	print(">>> ALL STEP 17D TESTS PASSED 100%! <<<")
	print("================================================================================")
	quit(0)

extends SceneTree

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
	print("--- BEGINNING STEP 12C AUTOMATED TEST SUITE (EQUIVALENT_EXPRESSION & 21-LEVEL POOL) ---")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()
	root.add_child(main_node)

	# Allow a frame for _ready to execute
	await process_frame
	await _sync_physics()

	var level_manager: LevelManager = main_node.get_node("LevelManager") as LevelManager
	var level_lbl: Label = main_node.get_node("LevelIndicatorLabel") as Label
	var lives_lbl: Label = main_node.get_node("LivesLabel") as Label
	var streak_lbl: Label = main_node.get_node("StreakLabel") as Label
	var prompt_lbl: Label = main_node.get_node("PromptLabel") as Label
	var success_lbl: Label = main_node.get_node("SuccessLabel") as Label

	var complete_overlay: Control = main_node.get_node("RunCompleteOverlay") as Control
	var play_again_btn: Button = complete_overlay.get_node("Card/PlayAgainButton") as Button

	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
	var failure_prog_lbl: Label = failure_overlay.get_node("Card/FailureProgressLabel") as Label
	var failure_streak_lbl: Label = failure_overlay.get_node("Card/FailureBestStreakLabel") as Label
	var try_again_btn: Button = failure_overlay.get_node("Card/TryAgainButton") as Button

	assert(level_manager != null, "LevelManager must exist")

	# Accelerate animation delays for test suite execution speed
	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# --- TEST SCENARIO H & I: MASTER POOL CONTAINS 21 RESOURCES (7 PER TIER) ---
	print("\n[SCENARIO H & I] Verify master pool contains 21 resources (7 per tier)")
	assert(level_manager.levels.size() == 21, "Master pool must contain 21 loaded levels (found %d)" % level_manager.levels.size())

	var pool_t1: Array[LevelData] = []
	var pool_t2: Array[LevelData] = []
	var pool_t3: Array[LevelData] = []
	for lvl in level_manager.levels:
		match lvl.tier:
			1: pool_t1.append(lvl)
			2: pool_t2.append(lvl)
			3: pool_t3.append(lvl)

	assert(pool_t1.size() == 7, "Tier 1 pool must have 7 levels")
	assert(pool_t2.size() == 7, "Tier 2 pool must have 7 levels")
	assert(pool_t3.size() == 7, "Tier 3 pool must have 7 levels")

	# --- TEST SCENARIOS A & B: LEVEL 19 LOADS AS EQUIVALENT_EXPRESSION WITH TARGET '8' ---
	print("\n[SCENARIO A & B] Level 19 loads as EQUIVALENT_EXPRESSION with target display '8'")
	var lvl19: LevelData = load("res://data/levels/level_19.tres") as LevelData
	assert(lvl19 != null, "level_19.tres must exist")
	assert(lvl19.puzzle_type == LevelData.PuzzleType.EQUIVALENT_EXPRESSION, "Level 19 puzzle_type must be EQUIVALENT_EXPRESSION")
	assert(lvl19.prompt_text == "8 sayısını oluştur", "Level 19 prompt must be '8 sayısını oluştur'")
	assert(lvl19.target_display == "8", "Level 19 target_display must be '8'")
	assert(lvl19.correct_answer == "3 + 5", "Level 19 correct answer must be '3 + 5'")
	assert(lvl19.tier == 1, "Level 19 must be Tier 1")

	# Load Level 19 directly to test its mechanics in isolation
	level_manager.current_run_levels = [lvl19]
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

	assert(prompt_lbl.text == "8 sayısını oluştur", "PromptLabel must show '8 sayısını oluştur'")
	var placeholder_lbl: Label = level_manager.math_target_zone.get_node("PlaceholderLabel") as Label
	assert(placeholder_lbl.text == "8", "Target zone placeholder must show '8'")
	assert(level_manager.math_pieces.size() == 4, "Must spawn 4 choice pieces")

	# --- TEST SCENARIO E: NEUTRAL EMPTY-SPACE DROP LOSES NO LIFE ---
	print("\n[SCENARIO E] Neutral empty-space drop loses no life and does not reset streak")
	level_manager.current_streak = 2
	var test_piece_wrong: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "4 + 3":
			test_piece_wrong = p
			break
	assert(test_piece_wrong != null, "Piece '4 + 3' must exist")

	# Drop into empty space (away from TargetZone)
	test_piece_wrong.global_position = Vector2(100, 100)
	await _sync_physics()
	level_manager._on_math_piece_dropped(test_piece_wrong)
	test_piece_wrong._kill_active_tweens()
	await _sync_physics()

	assert(level_manager.current_lives == 3, "Lives must remain 3 after neutral drop")
	assert(level_manager.current_streak == 2, "Streak must remain 2 after neutral drop")

	# --- TEST SCENARIO D: WRONG DELIBERATE ANSWER LOSES ONE LIFE ---
	print("\n[SCENARIO D] Wrong deliberate answer ('4 + 3' instead of '3 + 5') loses 1 life & resets streak")
	test_piece_wrong.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(test_piece_wrong)
	test_piece_wrong._kill_active_tweens()
	await _sync_physics()

	assert(level_manager.current_lives == 2, "Lives must decrease from 3 to 2 on wrong drop")
	assert(level_manager.current_streak == 0, "Streak must reset to 0 on wrong drop")

	# --- TEST SCENARIO C: CORRECT ANSWER '3 + 5' COMPLETES LEVEL 19 ---
	print("\n[SCENARIO C] Correct answer '3 + 5' completes Level 19 successfully")
	var test_piece_correct: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "3 + 5":
			test_piece_correct = p
			break
	assert(test_piece_correct != null, "Piece '3 + 5' must exist")

	test_piece_correct.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(test_piece_correct)
	await level_manager.level_completed

	assert(level_manager.is_completed, "Level 19 must be marked completed")
	assert(level_manager.current_streak == 1, "Streak must increment to 1")

	# --- TEST SCENARIO F: LEVEL 20 (14 sayısını oluştur, target 14, answer '8 + 6') VALIDATES CORRECTLY ---
	print("\n[SCENARIO F] Level 20 ('14 sayısını oluştur', target '14', answer '8 + 6') validates correctly")
	var lvl20: LevelData = load("res://data/levels/level_20.tres") as LevelData
	assert(lvl20 != null, "level_20.tres must exist")
	assert(lvl20.puzzle_type == LevelData.PuzzleType.EQUIVALENT_EXPRESSION, "Level 20 puzzle_type must be EQUIVALENT_EXPRESSION")
	assert(lvl20.tier == 2, "Level 20 must be Tier 2")

	level_manager.current_run_levels = [lvl20]
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

	var placeholder_lbl_20: Label = level_manager.math_target_zone.get_node("PlaceholderLabel") as Label
	assert(placeholder_lbl_20.text == "14", "Target zone placeholder must show '14'")

	var test_piece_8_6: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "8 + 6":
			test_piece_8_6 = p
			break
	assert(test_piece_8_6 != null, "Piece '8 + 6' must exist")
	test_piece_8_6.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(test_piece_8_6)
	await level_manager.level_completed
	assert(level_manager.is_completed, "Level 20 solved with '8 + 6'")

	# --- TEST SCENARIO G: LEVEL 21 (20 sayısını oluştur, target 20, answer '12 + 8') VALIDATES CORRECTLY ---
	print("\n[SCENARIO G] Level 21 ('20 sayısını oluştur', target '20', answer '12 + 8') validates correctly")
	var lvl21: LevelData = load("res://data/levels/level_21.tres") as LevelData
	assert(lvl21 != null, "level_21.tres must exist")
	assert(lvl21.puzzle_type == LevelData.PuzzleType.EQUIVALENT_EXPRESSION, "Level 21 puzzle_type must be EQUIVALENT_EXPRESSION")
	assert(lvl21.tier == 3, "Level 21 must be Tier 3")

	level_manager.current_run_levels = [lvl21]
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

	var placeholder_lbl_21: Label = level_manager.math_target_zone.get_node("PlaceholderLabel") as Label
	assert(placeholder_lbl_21.text == "20", "Target zone placeholder must show '20'")

	var test_piece_12_8: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "12 + 8":
			test_piece_12_8 = p
			break
	assert(test_piece_12_8 != null, "Piece '12 + 8' must exist")
	test_piece_12_8.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(test_piece_12_8)
	await level_manager.level_completed
	assert(level_manager.is_completed, "Level 21 solved with '12 + 8'")

	# --- TEST SCENARIOS J, K, L: SAMPLING 15 LEVELS FROM 21-LEVEL POOL (5+5+5), NO DUPLICATES, ANTI-CLUMPING ---
	print("\n[SCENARIO J, K, L] Multi-run sampling from 21-level pool: 5+5+5, no duplicates, anti-clumping")
	level_manager.levels = []
	level_manager._ensure_levels_loaded()
	level_manager.current_run_levels.clear()
	level_manager.previous_run_levels.clear()

	var prev_sampled_run: Array[LevelData] = []

	for iter in range(10):
		var run_seq: Array[LevelData] = level_manager.generate_run_sequence()
		assert(run_seq.size() == 15, "Scenario J: Sampled run %d must contain exactly 15 levels" % (iter + 1))

		# Verify tier structure
		for i in range(15):
			if i < 5:
				assert(run_seq[i].tier == 1, "Position %d must be Tier 1 (Easy)" % (i + 1))
			elif i < 10:
				assert(run_seq[i].tier == 2, "Position %d must be Tier 2 (Medium)" % (i + 1))
			else:
				assert(run_seq[i].tier == 3, "Position %d must be Tier 3 (Hard)" % (i + 1))

		# Scenario K: No duplicate levels in run
		var seen_levels: Dictionary = {}
		for lvl in run_seq:
			assert(not seen_levels.has(lvl), "Scenario K: Duplicate resource sampled in run %d!" % (iter + 1))
			seen_levels[lvl] = true
		assert(seen_levels.size() == 15, "15 distinct resources sampled from pool of 21")

		# Scenario L: Anti-clumping per tier slice
		var t1 = run_seq.slice(0, 5)
		var t2 = run_seq.slice(5, 10)
		var t3 = run_seq.slice(10, 15)
		assert(not level_manager._has_clump_of_three(t1), "Scenario L: Tier 1 anti-clumping violation in run %d" % (iter + 1))
		assert(not level_manager._has_clump_of_three(t2), "Scenario L: Tier 2 anti-clumping violation in run %d" % (iter + 1))
		assert(not level_manager._has_clump_of_three(t3), "Scenario L: Tier 3 anti-clumping violation in run %d" % (iter + 1))

		# Tier-start anti-repeat
		if not prev_sampled_run.is_empty():
			assert(run_seq[0] != prev_sampled_run[0], "Tier 1 start must differ from previous")
			assert(run_seq[5] != prev_sampled_run[5], "Tier 2 start must differ from previous")
			assert(run_seq[10] != prev_sampled_run[10], "Tier 3 start must differ from previous")

		prev_sampled_run = run_seq.duplicate()

	# --- TEST SCENARIO M: FAILURE / RETRY ON AN EQUIVALENT_EXPRESSION PUZZLE ---
	print("\n[SCENARIO M] Failure & retry when failing on an EQUIVALENT_EXPRESSION puzzle")
	# Force Level 19 (EQUIVALENT_EXPRESSION) at position 1 of a run
	level_manager.current_run_levels = [lvl19, lvl20, lvl21]
	level_manager.current_lives = 1
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

	# 1 deliberate wrong drop -> failure
	var wrong_exp_p: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text != "3 + 5":
			wrong_exp_p = p
			break
	assert(wrong_exp_p != null)
	wrong_exp_p.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(wrong_exp_p)

	assert(level_manager.current_lives == 0, "Lives must reach 0")
	assert(level_manager.is_run_failed, "is_run_failed must be true")

	if level_manager.failure_tween:
		await level_manager.failure_tween.finished
	await process_frame

	assert(failure_overlay.visible, "RunFailureOverlay must be visible")

	# Restore full master pool and hit Tekrar Dene
	level_manager.levels = []
	level_manager._ensure_levels_loaded()
	try_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Position 1")
	assert(level_lbl.text == "Bölüm 1 / 15", "Indicator reset to Bölüm 1 / 15")
	assert(level_manager.current_lives == 3, "Lives reset to 3")
	assert(lives_lbl.text == "♥ ♥ ♥", "Lives label shows ♥ ♥ ♥")
	assert(not failure_overlay.visible, "Failure overlay hidden")
	assert(level_manager.current_run_levels.size() == 15, "New 15-level run generated")

	print("\n>>> ALL STEP 12C AUTOMATED TESTS (SCENARIOS A - M) PASSED PERFECTLY! <<<\n")
	quit(0)




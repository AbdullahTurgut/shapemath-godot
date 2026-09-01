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
	print("--- BEGINNING STEP 12B AUTOMATED TEST SUITE (MISSING_NUMBER PUZZLE & 18-LEVEL POOL) ---")
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

	# --- TEST SCENARIO G: MASTER POOL CONTAINS 18 RESOURCES (6 EASY, 6 MEDIUM, 6 HARD) ---
	print("\n[SCENARIO G] Verify master pool contains 18 resources (6 per tier)")
	assert(level_manager.levels.size() == 18, "Master pool must contain 18 loaded levels (found %d)" % level_manager.levels.size())

	var pool_t1: Array[LevelData] = []
	var pool_t2: Array[LevelData] = []
	var pool_t3: Array[LevelData] = []
	for lvl in level_manager.levels:
		match lvl.tier:
			1: pool_t1.append(lvl)
			2: pool_t2.append(lvl)
			3: pool_t3.append(lvl)

	assert(pool_t1.size() == 6, "Tier 1 pool must have 6 levels")
	assert(pool_t2.size() == 6, "Tier 2 pool must have 6 levels")
	assert(pool_t3.size() == 6, "Tier 3 pool must have 6 levels")

	# --- TEST SCENARIO A: LEVEL 16 LOADS AS MISSING_NUMBER ---
	print("\n[SCENARIO A] Level 16 loads as MISSING_NUMBER with prompt '3 + ? = 7'")
	var lvl16: LevelData = load("res://data/levels/level_16.tres") as LevelData
	assert(lvl16 != null, "level_16.tres must exist")
	assert(lvl16.puzzle_type == LevelData.PuzzleType.MISSING_NUMBER, "Level 16 puzzle_type must be MISSING_NUMBER")
	assert(lvl16.prompt_text == "3 + ? = 7", "Level 16 prompt must be '3 + ? = 7'")
	assert(lvl16.correct_answer == "4", "Level 16 correct answer must be '4'")
	assert(lvl16.tier == 1, "Level 16 must be Tier 1")

	# Load Level 16 directly to test its mechanics in isolation
	level_manager.current_run_levels = [lvl16]
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

	assert(prompt_lbl.text == "3 + ? = 7", "PromptLabel must show '3 + ? = 7'")
	var placeholder_lbl: Label = level_manager.math_target_zone.get_node("PlaceholderLabel") as Label
	assert(placeholder_lbl.text == "?", "Target zone placeholder must show '?'")
	assert(level_manager.math_pieces.size() == 4, "Must spawn 4 choice pieces")

	# --- TEST SCENARIO D: NEUTRAL EMPTY-SPACE DROP LOSES NO LIFE ---
	print("\n[SCENARIO D] Neutral empty-space drop loses no life and does not reset streak")
	level_manager.current_streak = 2
	var test_piece_2: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "2":
			test_piece_2 = p
			break
	assert(test_piece_2 != null, "Piece '2' must exist")

	# Drop into empty space (away from TargetZone)
	test_piece_2.global_position = Vector2(100, 100)
	await _sync_physics()
	level_manager._on_math_piece_dropped(test_piece_2)
	test_piece_2._kill_active_tweens()
	await _sync_physics()

	assert(level_manager.current_lives == 3, "Lives must remain 3 after neutral drop")
	assert(level_manager.current_streak == 2, "Streak must remain 2 after neutral drop")

	# --- TEST SCENARIO C: WRONG DELIBERATE ANSWER LOSES ONE LIFE ---
	print("\n[SCENARIO C] Wrong deliberate answer ('3' instead of '4') loses 1 life & resets streak")
	var test_piece_3: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "3":
			test_piece_3 = p
			break
	assert(test_piece_3 != null, "Piece '3' must exist")

	test_piece_3.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(test_piece_3)
	test_piece_3._kill_active_tweens()
	await _sync_physics()

	assert(level_manager.current_lives == 2, "Lives must decrease from 3 to 2 on wrong drop")
	assert(level_manager.current_streak == 0, "Streak must reset to 0 on wrong drop")

	# --- TEST SCENARIO B: CORRECT ANSWER 4 FOR '3 + ? = 7' COMPLETES LEVEL ---
	print("\n[SCENARIO B] Correct answer '4' completes Level 16 successfully")
	var test_piece_4: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "4":
			test_piece_4 = p
			break
	assert(test_piece_4 != null, "Piece '4' must exist")

	test_piece_4.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(test_piece_4)
	await level_manager.level_completed

	assert(level_manager.is_completed, "Level 16 must be marked completed")
	assert(level_manager.current_streak == 1, "Streak must increment to 1")

	# --- TEST SCENARIO E: LEVEL 17 (? + 6 = 15, ANSWER 9) VALIDATES CORRECTLY ---
	print("\n[SCENARIO E] Level 17 ('? + 6 = 15', answer '9') validates correctly")
	var lvl17: LevelData = load("res://data/levels/level_17.tres") as LevelData
	assert(lvl17 != null, "level_17.tres must exist")
	assert(lvl17.puzzle_type == LevelData.PuzzleType.MISSING_NUMBER, "Level 17 puzzle_type must be MISSING_NUMBER")
	assert(lvl17.tier == 2, "Level 17 must be Tier 2")

	level_manager.current_run_levels = [lvl17]
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

	var test_piece_9: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "9":
			test_piece_9 = p
			break
	assert(test_piece_9 != null, "Piece '9' must exist")
	test_piece_9.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(test_piece_9)
	await level_manager.level_completed
	assert(level_manager.is_completed, "Level 17 solved with '9'")

	# --- TEST SCENARIO F: LEVEL 18 (20 - ? = 13, ANSWER 7) VALIDATES CORRECTLY ---
	print("\n[SCENARIO F] Level 18 ('20 - ? = 13', answer '7') validates correctly")
	var lvl18: LevelData = load("res://data/levels/level_18.tres") as LevelData
	assert(lvl18 != null, "level_18.tres must exist")
	assert(lvl18.puzzle_type == LevelData.PuzzleType.MISSING_NUMBER, "Level 18 puzzle_type must be MISSING_NUMBER")
	assert(lvl18.tier == 3, "Level 18 must be Tier 3")

	level_manager.current_run_levels = [lvl18]
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

	var test_piece_7: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "7":
			test_piece_7 = p
			break
	assert(test_piece_7 != null, "Piece '7' must exist")
	test_piece_7.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(test_piece_7)
	await level_manager.level_completed
	assert(level_manager.is_completed, "Level 18 solved with '7'")

	# --- TEST SCENARIO H, I, J: SAMPLING 15 LEVELS FROM 18-LEVEL POOL (5+5+5), NO DUPLICATES, ANTI-CLUMPING ---
	print("\n[SCENARIO H, I, J] Multi-run sampling from 18-level pool: 5+5+5, no duplicates, anti-clumping")
	level_manager.levels = []
	level_manager._ensure_levels_loaded()
	level_manager.current_run_levels.clear()
	level_manager.previous_run_levels.clear()

	var prev_sampled_run: Array[LevelData] = []

	for iter in range(10):
		var run_seq: Array[LevelData] = level_manager.generate_run_sequence()
		assert(run_seq.size() == 15, "Scenario H: Sampled run %d must contain exactly 15 levels" % (iter + 1))

		# Verify tier structure
		for i in range(15):
			if i < 5:
				assert(run_seq[i].tier == 1, "Position %d must be Tier 1 (Easy)" % (i + 1))
			elif i < 10:
				assert(run_seq[i].tier == 2, "Position %d must be Tier 2 (Medium)" % (i + 1))
			else:
				assert(run_seq[i].tier == 3, "Position %d must be Tier 3 (Hard)" % (i + 1))

		# Scenario I: No duplicate levels in run
		var seen_levels: Dictionary = {}
		for lvl in run_seq:
			assert(not seen_levels.has(lvl), "Scenario I: Duplicate resource sampled in run %d!" % (iter + 1))
			seen_levels[lvl] = true
		assert(seen_levels.size() == 15, "15 distinct resources sampled from pool of 18")

		# Scenario J: Anti-clumping per tier slice
		var t1 = run_seq.slice(0, 5)
		var t2 = run_seq.slice(5, 10)
		var t3 = run_seq.slice(10, 15)
		assert(not level_manager._has_clump_of_three(t1), "Scenario J: Tier 1 anti-clumping violation in run %d" % (iter + 1))
		assert(not level_manager._has_clump_of_three(t2), "Scenario J: Tier 2 anti-clumping violation in run %d" % (iter + 1))
		assert(not level_manager._has_clump_of_three(t3), "Scenario J: Tier 3 anti-clumping violation in run %d" % (iter + 1))

		# Tier-start anti-repeat
		if not prev_sampled_run.is_empty():
			assert(run_seq[0] != prev_sampled_run[0], "Tier 1 start must differ from previous")
			assert(run_seq[5] != prev_sampled_run[5], "Tier 2 start must differ from previous")
			assert(run_seq[10] != prev_sampled_run[10], "Tier 3 start must differ from previous")

		prev_sampled_run = run_seq.duplicate()

	# --- TEST SCENARIO K: FAILURE / RETRY ON A MISSING_NUMBER PUZZLE ---
	print("\n[SCENARIO K] Failure & retry when failing on a MISSING_NUMBER puzzle")
	# Force Level 16 (MISSING_NUMBER) at position 1 of a run
	level_manager.current_run_levels = [lvl16, lvl17, lvl18]
	level_manager.current_lives = 1
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

	# 1 deliberate wrong drop -> failure
	var wrong_p: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text != "4":
			wrong_p = p
			break
	assert(wrong_p != null)
	wrong_p.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(wrong_p)

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

	print("\n>>> ALL STEP 12B AUTOMATED TESTS (SCENARIOS A - K) PASSED PERFECTLY! <<<\n")
	quit(0)



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
	print("--- BEGINNING STEP 11D AUTOMATED TEST SUITE (TIER START ANTI-REPEAT & PROGRESSION) ---")
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
	assert(level_manager.levels.size() == 15, "Master pool must contain 15 levels")

	# Accelerate animation delays for test suite execution speed
	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# --- TEST SCENARIO A: FIRST RUN GENERATES NORMALLY WITH NO PREVIOUS HISTORY ---
	print("\n[SCENARIO A] First run generates normally with no previous history")
	assert(level_manager.previous_run_levels.is_empty(), "First run must have empty previous_run_levels")
	assert(level_manager.current_run_levels.size() == 15, "Run must contain 15 levels (found %d)" % level_manager.current_run_levels.size())

	# --- TEST SCENARIO B, C, D, E: GENERATE MULTIPLE CONSECUTIVE RUNS & VERIFY RULES ---
	print("\n[SCENARIO B, C, D, E] Multi-run anti-repeat, level uniqueness, tier boundaries & anti-clumping")
	var prev_run: Array[LevelData] = level_manager.current_run_levels.duplicate()

	for run_iter in range(10):
		var new_run: Array[LevelData] = level_manager.generate_run_sequence()
		assert(new_run.size() == 15, "Run %d must contain 15 levels" % (run_iter + 1))

		# Verify Scenario B: Tier start levels differ from previous run
		var prev_t1 = level_manager._get_level_number(prev_run[0])
		var prev_t2 = level_manager._get_level_number(prev_run[5])
		var prev_t3 = level_manager._get_level_number(prev_run[10])

		var new_t1 = level_manager._get_level_number(new_run[0])
		var new_t2 = level_manager._get_level_number(new_run[5])
		var new_t3 = level_manager._get_level_number(new_run[10])

		assert(new_t1 != prev_t1, "Run %d Tier 1 start (%d) must differ from previous (%d)" % [run_iter + 1, new_t1, prev_t1])
		assert(new_t2 != prev_t2, "Run %d Tier 2 start (%d) must differ from previous (%d)" % [run_iter + 1, new_t2, prev_t2])
		assert(new_t3 != prev_t3, "Run %d Tier 3 start (%d) must differ from previous (%d)" % [run_iter + 1, new_t3, prev_t3])

		# Verify Scenario C: All 15 levels appear exactly once
		var seen: Dictionary = {}
		for lvl in new_run:
			var lvl_num = level_manager._get_level_number(lvl)
			assert(lvl_num >= 1 and lvl_num <= 15, "Level number out of range: %d" % lvl_num)
			assert(not seen.has(lvl_num), "Duplicate level %d found in run sequence!" % lvl_num)
			seen[lvl_num] = true
		assert(seen.size() == 15, "All 15 levels must appear in run %d" % (run_iter + 1))

		# Verify Scenario D: Tier boundary distribution
		for i in range(15):
			var lvl_num = level_manager._get_level_number(new_run[i])
			if i < 5:
				assert(lvl_num >= 1 and lvl_num <= 5, "Position %d must be Easy (1-5), found Level %d" % [i + 1, lvl_num])
			elif i < 10:
				assert(lvl_num >= 6 and lvl_num <= 10, "Position %d must be Medium (6-10), found Level %d" % [i + 1, lvl_num])
			else:
				assert(lvl_num >= 11 and lvl_num <= 15, "Position %d must be Hard (11-15), found Level %d" % [i + 1, lvl_num])

		# Verify Scenario E: Anti-clumping (no 3 consecutive identical puzzle types in any tier)
		var t1 = new_run.slice(0, 5)
		var t2 = new_run.slice(5, 10)
		var t3 = new_run.slice(10, 15)
		assert(not level_manager._has_clump_of_three(t1), "Tier 1 anti-clumping violation in run %d" % (run_iter + 1))
		assert(not level_manager._has_clump_of_three(t2), "Tier 2 anti-clumping violation in run %d" % (run_iter + 1))
		assert(not level_manager._has_clump_of_three(t3), "Tier 3 anti-clumping violation in run %d" % (run_iter + 1))

		prev_run = new_run.duplicate()

	# Re-load level 0 for active gameplay test
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

	assert(level_lbl.text == "Bölüm 1 / 15", "Indicator must show Bölüm 1 / 15 (got '%s')" % level_lbl.text)
	assert(level_manager.current_level_index == 0, "current_level_index must be 0")
	assert(level_manager.current_lives == 3, "Lives must be 3")

	# Generic solver for any level in current_run_levels
	var solve_current_level = func() -> void:
		var cur_lvl = level_manager.current_level_data
		if cur_lvl.puzzle_type == LevelData.PuzzleType.MATH_MATCH:
			var target_piece: DraggablePiece = null
			for p in level_manager.math_pieces:
				if p.piece_text == cur_lvl.correct_answer:
					target_piece = p
					break
			assert(target_piece != null, "Target math piece '%s' not found" % cur_lvl.correct_answer)
			target_piece.global_position = level_manager.math_target_zone.global_position
			await _sync_physics()
			level_manager._on_math_piece_dropped(target_piece)
		else:
			assert(level_manager.shape_piece_a != null and level_manager.shape_piece_b != null, "Shape pieces missing")
			level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
			await _sync_physics()
			level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
		await level_manager.level_completed

	var make_deliberate_mistake = func() -> void:
		var cur_lvl = level_manager.current_level_data
		if cur_lvl.puzzle_type == LevelData.PuzzleType.MATH_MATCH:
			var wrong_piece: DraggablePiece = null
			for p in level_manager.math_pieces:
				if p.piece_text != cur_lvl.correct_answer:
					wrong_piece = p
					break
			assert(wrong_piece != null, "Wrong math piece not found")
			wrong_piece.global_position = level_manager.math_target_zone.global_position
			await _sync_physics()
			level_manager._on_math_piece_dropped(wrong_piece)
		else:
			level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
			var old_match_id = level_manager.shape_piece_a.match_id
			level_manager.shape_piece_a.match_id = "incompatible_match_id"
			await _sync_physics()
			level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
			level_manager.shape_piece_a.match_id = old_match_id

	# Advance through run positions 1 to 4
	for pos in range(4):
		await solve_current_level.call()
		if level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(level_manager.current_level_index == 4, "Now on Run Position 5")
	assert(level_lbl.text == "Bölüm 5 / 15", "Indicator shows Bölüm 5 / 15")

	# --- TEST SCENARIO F & H: FAILURE -> TEKRAR DENE RESPECTS PREVIOUS TIER STARTS & RESETS STATE ---
	print("\n[SCENARIO F & H] Failure -> Tekrar Dene respects previous tier starts and resets state")
	var failed_run: Array[LevelData] = level_manager.current_run_levels.duplicate()
	var failed_t1_start = level_manager._get_level_number(failed_run[0])
	var failed_t2_start = level_manager._get_level_number(failed_run[5])
	var failed_t3_start = level_manager._get_level_number(failed_run[10])

	# 3 mistakes to trigger failure
	await make_deliberate_mistake.call()
	await _sync_physics()
	await make_deliberate_mistake.call()
	await _sync_physics()
	await make_deliberate_mistake.call()
	await _sync_physics()

	assert(level_manager.current_lives == 0, "Lives must be 0")
	assert(level_manager.is_run_failed, "is_run_failed must be true")

	if level_manager.failure_tween:
		await level_manager.failure_tween.finished
	await process_frame

	assert(failure_overlay.visible, "RunFailureOverlay must be visible")
	assert(failure_prog_lbl.text == "5 / 15 Bölüme Ulaştın", "Failure milestone must show '5 / 15 Bölüme Ulaştın' (got '%s')" % failure_prog_lbl.text)

	# Click Tekrar Dene
	try_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	# Verify reset state
	assert(level_manager.current_level_index == 0, "Returned to Position 1")
	assert(level_lbl.text == "Bölüm 1 / 15", "Indicator reset to Bölüm 1 / 15")
	assert(level_manager.current_lives == 3, "Lives reset to 3")
	assert(lives_lbl.text == "♥ ♥ ♥", "Lives label shows ♥ ♥ ♥")
	assert(level_manager.current_streak == 0 and level_manager.best_streak_this_run == 0, "Streaks reset to 0")
	assert(not failure_overlay.visible, "Failure overlay hidden")

	# Verify anti-repeat after retry
	var retry_run: Array[LevelData] = level_manager.current_run_levels
	var retry_t1_start = level_manager._get_level_number(retry_run[0])
	var retry_t2_start = level_manager._get_level_number(retry_run[5])
	var retry_t3_start = level_manager._get_level_number(retry_run[10])

	assert(retry_t1_start != failed_t1_start, "Retry Tier 1 start (%d) must differ from failed run start (%d)" % [retry_t1_start, failed_t1_start])
	assert(retry_t2_start != failed_t2_start, "Retry Tier 2 start (%d) must differ from failed run start (%d)" % [retry_t2_start, failed_t2_start])
	assert(retry_t3_start != failed_t3_start, "Retry Tier 3 start (%d) must differ from failed run start (%d)" % [retry_t3_start, failed_t3_start])

	# --- TEST SCENARIO G: SUCCESS -> TEKRAR OYNA RESPECTS PREVIOUS TIER STARTS ---
	print("\n[SCENARIO G] Success -> Tekrar Oyna produces a new run respecting previous tier starts")
	var active_run: Array[LevelData] = level_manager.current_run_levels.duplicate()
	var run_t1_start = level_manager._get_level_number(active_run[0])
	var run_t2_start = level_manager._get_level_number(active_run[5])
	var run_t3_start = level_manager._get_level_number(active_run[10])

	for pos in range(14):
		await solve_current_level.call()
		if level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	# Position 15 solve
	assert(level_manager.current_level_index == 14, "On Position 15")
	await solve_current_level.call()
	if level_manager.summary_tween:
		await level_manager.summary_tween.finished
	await process_frame

	assert(complete_overlay.visible, "RunCompleteOverlay visible")

	# Tap Play Again (Tekrar Oyna)
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Position 1")
	assert(level_manager.current_lives == 3, "Lives reset to 3 on Play Again")
	assert(lives_lbl.text == "♥ ♥ ♥", "Lives label shows ♥ ♥ ♥")
	assert(not complete_overlay.visible, "Complete overlay hidden")

	var play_again_run: Array[LevelData] = level_manager.current_run_levels
	var pa_t1_start = level_manager._get_level_number(play_again_run[0])
	var pa_t2_start = level_manager._get_level_number(play_again_run[5])
	var pa_t3_start = level_manager._get_level_number(play_again_run[10])

	assert(pa_t1_start != run_t1_start, "Play Again Tier 1 start (%d) must differ from completed run start (%d)" % [pa_t1_start, run_t1_start])
	assert(pa_t2_start != run_t2_start, "Play Again Tier 2 start (%d) must differ from completed run start (%d)" % [pa_t2_start, run_t2_start])
	assert(pa_t3_start != run_t3_start, "Play Again Tier 3 start (%d) must differ from completed run start (%d)" % [pa_t3_start, run_t3_start])

	print("\n>>> ALL STEP 11D AUTOMATED TESTS (SCENARIOS A - H) PASSED PERFECTLY! <<<\n")
	quit(0)

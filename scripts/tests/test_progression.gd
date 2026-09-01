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
	print("--- BEGINNING STEP 12A AUTOMATED TEST SUITE (POOL SAMPLING & TIER ARCHITECTURE) ---")
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
	assert(level_manager.levels.size() == 15, "Master pool must contain 15 loaded levels")

	# Accelerate animation delays for test suite execution speed
	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# --- TEST SCENARIO A: FIRST RUN GENERATES NORMALLY WITH NO PREVIOUS HISTORY ---
	print("\n[SCENARIO A] First run generates normally with no previous history")
	assert(level_manager.previous_run_levels.is_empty(), "First run must have empty previous_run_levels")
	assert(level_manager.current_run_levels.size() == 15, "Run must contain 15 levels (found %d)" % level_manager.current_run_levels.size())

	# --- TEST SCENARIOS B, C, D, E, F, G: VERIFY TIER COMPOSITION, UNIQUENESS, ANTI-REPEAT & ANTI-CLUMPING ---
	print("\n[SCENARIO B, C, D, E, F, G] Tier composition (5+5+5), uniqueness, tier-start anti-repeat & anti-clumping")
	var prev_run: Array[LevelData] = level_manager.current_run_levels.duplicate()

	for run_iter in range(10):
		var new_run: Array[LevelData] = level_manager.generate_run_sequence()
		assert(new_run.size() == 15, "Scenario D: Run %d must contain exactly 15 levels" % (run_iter + 1))

		# Scenario B: Verify explicit LevelData.tier grouping
		for i in range(15):
			var lvl: LevelData = new_run[i]
			if i < 5:
				assert(lvl.tier == 1, "Scenario B: Position %d must be Tier 1 (Easy), found tier %d" % [i + 1, lvl.tier])
			elif i < 10:
				assert(lvl.tier == 2, "Scenario B: Position %d must be Tier 2 (Medium), found tier %d" % [i + 1, lvl.tier])
			else:
				assert(lvl.tier == 3, "Scenario B: Position %d must be Tier 3 (Hard), found tier %d" % [i + 1, lvl.tier])

		# Scenario C: Verify uniqueness (no duplicates in run)
		var seen: Dictionary = {}
		for lvl in new_run:
			assert(not seen.has(lvl), "Scenario C: Duplicate LevelData resource found in run sequence!")
			seen[lvl] = true
		assert(seen.size() == 15, "Scenario C: Run must have 15 distinct level instances")

		# Scenario F: Tier-start anti-repeat
		var prev_t1 = level_manager._get_level_number(prev_run[0])
		var prev_t2 = level_manager._get_level_number(prev_run[5])
		var prev_t3 = level_manager._get_level_number(prev_run[10])

		var new_t1 = level_manager._get_level_number(new_run[0])
		var new_t2 = level_manager._get_level_number(new_run[5])
		var new_t3 = level_manager._get_level_number(new_run[10])

		assert(new_t1 != prev_t1, "Scenario F: Tier 1 start (%d) must differ from previous (%d)" % [new_t1, prev_t1])
		assert(new_t2 != prev_t2, "Scenario F: Tier 2 start (%d) must differ from previous (%d)" % [new_t2, prev_t2])
		assert(new_t3 != prev_t3, "Scenario F: Tier 3 start (%d) must differ from previous (%d)" % [new_t3, prev_t3])

		# Scenario G: Anti-clumping per tier slice
		var t1 = new_run.slice(0, 5)
		var t2 = new_run.slice(5, 10)
		var t3 = new_run.slice(10, 15)
		assert(not level_manager._has_clump_of_three(t1), "Scenario G: Tier 1 anti-clumping violation")
		assert(not level_manager._has_clump_of_three(t2), "Scenario G: Tier 2 anti-clumping violation")
		assert(not level_manager._has_clump_of_three(t3), "Scenario G: Tier 3 anti-clumping violation")

		prev_run = new_run.duplicate()

	# Re-load level 0 for active gameplay test
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

	# Scenario E: UI display
	print("\n[SCENARIO E] UI indicator shows 'Bölüm 1 / 15'")
	assert(level_lbl.text == "Bölüm 1 / 15", "Scenario E: Indicator must show Bölüm 1 / 15 (got '%s')" % level_lbl.text)
	assert(level_manager.current_level_index == 0, "current_level_index must be 0")
	assert(level_manager.current_lives == 3, "Lives must be 3")

	# Generic solver for active run
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

	# --- TEST SCENARIO I: FAILURE + TEKRAR DENE GENERATES A VALID RUN RESPECTING ANTI-REPEAT ---
	print("\n[SCENARIO I] Failure + Tekrar Dene generates valid run respecting anti-repeat")
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
	assert(failure_prog_lbl.text == "5 / 15 Bölüme Ulaştın", "Failure milestone shows '5 / 15 Bölüme Ulaştın'")

	# Click Tekrar Dene
	try_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Position 1")
	assert(level_lbl.text == "Bölüm 1 / 15", "Indicator reset to Bölüm 1 / 15")
	assert(level_manager.current_lives == 3, "Lives reset to 3")
	assert(lives_lbl.text == "♥ ♥ ♥", "Lives label shows ♥ ♥ ♥")
	assert(level_manager.current_streak == 0 and level_manager.best_streak_this_run == 0, "Streaks reset to 0")
	assert(not failure_overlay.visible, "Failure overlay hidden")

	var retry_run: Array[LevelData] = level_manager.current_run_levels
	assert(retry_run.size() == 15, "Retry run has 15 levels")
	assert(level_manager._get_level_number(retry_run[0]) != failed_t1_start, "Retry Tier 1 start must differ")
	assert(level_manager._get_level_number(retry_run[5]) != failed_t2_start, "Retry Tier 2 start must differ")
	assert(level_manager._get_level_number(retry_run[10]) != failed_t3_start, "Retry Tier 3 start must differ")

	# --- TEST SCENARIO H & J: SOLVE RUN TO POSITION 15 -> RUN COMPLETE -> PLAY AGAIN ---
	print("\n[SCENARIO H & J] Solve full 15-level run -> Run Complete -> Play Again generates fresh run")
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

	# Scenario H: Run Complete occurs after position 15
	assert(complete_overlay.visible, "Scenario H: RunCompleteOverlay visible after position 15")

	# Scenario J: Tap Play Again (Tekrar Oyna)
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Position 1")
	assert(level_manager.current_lives == 3, "Lives reset to 3 on Play Again")
	assert(lives_lbl.text == "♥ ♥ ♥", "Lives label shows ♥ ♥ ♥")
	assert(not complete_overlay.visible, "Complete overlay hidden")

	var play_again_run: Array[LevelData] = level_manager.current_run_levels
	assert(play_again_run.size() == 15, "Play Again run has 15 levels")
	assert(level_manager._get_level_number(play_again_run[0]) != run_t1_start, "Play Again Tier 1 start must differ")
	assert(level_manager._get_level_number(play_again_run[5]) != run_t2_start, "Play Again Tier 2 start must differ")
	assert(level_manager._get_level_number(play_again_run[10]) != run_t3_start, "Play Again Tier 3 start must differ")

	# --- TEST SCENARIO K: SYNTHETIC LARGE POOL (36 LEVELS) SUBSET SAMPLING VERIFICATION ---
	print("\n[SCENARIO K] Synthetic Large Pool (36 levels, 12 per tier) samples exactly 5 per tier without duplicates")
	var synthetic_levels: Array[LevelData] = []
	for t in range(1, 4):
		for idx in range(12):
			var mock_lvl: LevelData = LevelData.new()
			mock_lvl.tier = t
			mock_lvl.puzzle_type = LevelData.PuzzleType.MATH_MATCH if (idx % 2 == 0) else LevelData.PuzzleType.SHAPE_MATCH
			mock_lvl.prompt_text = "Synthetic T%d L%d" % [t, idx + 1]
			mock_lvl.resource_path = "res://synthetic/tier%d_level_%02d.tres" % [t, idx + 1]
			synthetic_levels.append(mock_lvl)

	assert(synthetic_levels.size() == 36, "Synthetic pool has 36 levels")

	# Temporarily assign synthetic master pool to LevelManager
	var original_master = level_manager.levels
	level_manager.levels = synthetic_levels
	level_manager.current_run_levels.clear()
	level_manager.previous_run_levels.clear()

	var synth_prev_run: Array[LevelData] = []
	for test_iter in range(5):
		var sampled_run: Array[LevelData] = level_manager.generate_run_sequence()
		assert(sampled_run.size() == 15, "Synthetic run %d must contain exactly 15 levels" % (test_iter + 1))

		# Verify tier slices
		var t1_sample = sampled_run.slice(0, 5)
		var t2_sample = sampled_run.slice(5, 10)
		var t3_sample = sampled_run.slice(10, 15)

		for lvl in t1_sample:
			assert(lvl.tier == 1, "Must be Tier 1")
		for lvl in t2_sample:
			assert(lvl.tier == 2, "Must be Tier 2")
		for lvl in t3_sample:
			assert(lvl.tier == 3, "Must be Tier 3")

		# Verify no duplicates in the 15-level sampled run
		var synth_seen: Dictionary = {}
		for lvl in sampled_run:
			assert(not synth_seen.has(lvl), "Duplicate resource sampled in synthetic run!")
			synth_seen[lvl] = true
		assert(synth_seen.size() == 15, "15 distinct resources sampled from pool of 36")

		# Verify anti-clumping in synthetic sampled run
		assert(not level_manager._has_clump_of_three(t1_sample), "Synthetic Tier 1 anti-clumping violation")
		assert(not level_manager._has_clump_of_three(t2_sample), "Synthetic Tier 2 anti-clumping violation")
		assert(not level_manager._has_clump_of_three(t3_sample), "Synthetic Tier 3 anti-clumping violation")

		# Verify tier-start anti-repeat in synthetic pool
		if not synth_prev_run.is_empty():
			assert(sampled_run[0] != synth_prev_run[0], "Synthetic Tier 1 start must differ from previous")
			assert(sampled_run[5] != synth_prev_run[5], "Synthetic Tier 2 start must differ from previous")
			assert(sampled_run[10] != synth_prev_run[10], "Synthetic Tier 3 start must differ from previous")

		synth_prev_run = sampled_run.duplicate()

	# Restore original master pool
	level_manager.levels = original_master

	print("\n>>> ALL STEP 12A AUTOMATED TESTS (SCENARIOS A - K) PASSED PERFECTLY! <<<\n")
	quit(0)


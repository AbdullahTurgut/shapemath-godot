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
	print("--- BEGINNING STEP 11C AUTOMATED TEST SUITE (CONTROLLED RANDOMIZED RUNS) ---")
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

	# --- TEST SCENARIO A: GENERATED RUN CONTAINS EXACTLY 15 LEVELS ---
	print("\n[SCENARIO A] Verify current_run_levels contains exactly 15 levels")
	assert(level_manager.current_run_levels.size() == 15, "Run must contain 15 levels (found %d)" % level_manager.current_run_levels.size())

	# --- TEST SCENARIO B: EACH ORIGINAL LEVEL APPEARS EXACTLY ONCE ---
	print("\n[SCENARIO B] Verify no duplicates or missing levels in current_run_levels")
	var seen_levels: Dictionary = {}
	for lvl in level_manager.current_run_levels:
		var lvl_num = level_manager._get_level_number(lvl)
		assert(lvl_num >= 1 and lvl_num <= 15, "Level number out of range: %d" % lvl_num)
		assert(not seen_levels.has(lvl_num), "Duplicate level %d found in run sequence!" % lvl_num)
		seen_levels[lvl_num] = true
	assert(seen_levels.size() == 15, "All 15 levels must appear in run")

	# --- TEST SCENARIO C: POSITIONS RESPECT DIFFICULTY TIERS (EASY -> MEDIUM -> HARD) ---
	print("\n[SCENARIO C] Verify Tier 1 (Positions 1-5 Easy), Tier 2 (6-10 Med), Tier 3 (11-15 Hard)")
	for i in range(15):
		var lvl_num = level_manager._get_level_number(level_manager.current_run_levels[i])
		if i < 5:
			assert(lvl_num >= 1 and lvl_num <= 5, "Position %d must be Easy (1-5), found Level %d" % [i + 1, lvl_num])
		elif i < 10:
			assert(lvl_num >= 6 and lvl_num <= 10, "Position %d must be Medium (6-10), found Level %d" % [i + 1, lvl_num])
		else:
			assert(lvl_num >= 11 and lvl_num <= 15, "Position %d must be Hard (11-15), found Level %d" % [i + 1, lvl_num])

	# --- TEST SCENARIO D: NO 3 CONSECUTIVE IDENTICAL PUZZLE TYPES IN A TIER ---
	print("\n[SCENARIO D] Verify anti-clumping (no 3 identical puzzle types consecutively in each tier)")
	var t1 = level_manager.current_run_levels.slice(0, 5)
	var t2 = level_manager.current_run_levels.slice(5, 10)
	var t3 = level_manager.current_run_levels.slice(10, 15)
	assert(not level_manager._has_clump_of_three(t1), "Tier 1 must not have 3 identical puzzle types in a row")
	assert(not level_manager._has_clump_of_three(t2), "Tier 2 must not have 3 identical puzzle types in a row")
	assert(not level_manager._has_clump_of_three(t3), "Tier 3 must not have 3 identical puzzle types in a row")

	# --- TEST SCENARIO E: UI SHOWS BÖLÜM 1 / 15 AT START OF RUN ---
	print("\n[SCENARIO E] Verify UI level indicator shows run position 'Bölüm 1 / 15'")
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

	# --- TEST SCENARIO F: AUTO PROGRESSION ADVANCES THROUGH RUN POSITIONS 1 TO 8 ---
	print("\n[SCENARIO F] Advance through run positions 1 to 7 correctly")
	for pos in range(7):
		await solve_current_level.call()
		await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()
		assert(level_manager.current_level_index == pos + 1, "Must advance to run position %d" % [pos + 2])
		assert(level_lbl.text == "Bölüm %d / 15" % [pos + 2], "Indicator must show Bölüm %d / 15" % [pos + 2])

	# Now on Run Position 8 (index 7)
	assert(level_manager.current_level_index == 7, "Now on Run Position 8")
	assert(level_lbl.text == "Bölüm 8 / 15", "Indicator shows Bölüm 8 / 15")

	# --- TEST SCENARIO G: RUN FAILURE AT POSITION 8 SHOWS '8 / 15 Bölüme Ulaştın' ---
	print("\n[SCENARIO G] 3 mistakes on Position 8 -> Failure overlay displays '8 / 15 Bölüme Ulaştın'")

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

	# Mistake 1 (3 -> 2 lives)
	await make_deliberate_mistake.call()
	await _sync_physics()
	assert(level_manager.current_lives == 2, "Lives must be 2")

	# Mistake 2 (2 -> 1 life)
	await make_deliberate_mistake.call()
	await _sync_physics()
	assert(level_manager.current_lives == 1, "Lives must be 1")

	# Mistake 3 (1 -> 0 lives -> Run Failure)
	await make_deliberate_mistake.call()
	await _sync_physics()
	assert(level_manager.current_lives == 0, "Lives must be 0")
	assert(level_manager.is_run_failed, "is_run_failed must be true")

	await level_manager.failure_tween.finished
	await process_frame

	assert(failure_overlay.visible, "RunFailureOverlay must be visible")
	assert(failure_prog_lbl.text == "8 / 15 Bölüme Ulaştın", "Failure milestone must show '8 / 15 Bölüme Ulaştın' (got '%s')" % failure_prog_lbl.text)

	# --- TEST SCENARIO H & J: TEKRAR DENE GENERATES A FRESH RANDOMIZED RUN ---
	print("\n[SCENARIO H & J] Tekrar Dene -> Generates fresh valid run, resets lives to 3 and streak to 0")
	var old_run_sequence = level_manager.current_run_levels.duplicate()

	try_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Position 1")
	assert(level_lbl.text == "Bölüm 1 / 15", "Indicator reset to Bölüm 1 / 15")
	assert(level_manager.current_lives == 3, "Lives reset to 3")
	assert(lives_lbl.text == "♥ ♥ ♥", "Lives label shows ♥ ♥ ♥")
	assert(level_manager.current_streak == 0 and level_manager.best_streak_this_run == 0, "Streaks reset to 0")
	assert(not failure_overlay.visible, "Failure overlay hidden")
	assert(level_manager.current_run_levels.size() == 15, "New run has 15 levels")

	# --- TEST SCENARIO I: SOLVE FULL 15-LEVEL RUN & PLAY AGAIN ---
	print("\n[SCENARIO I] Solve all 15 levels of new randomized run -> Run Complete -> Play Again generates fresh run")
	for pos in range(14):
		await solve_current_level.call()
		await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	# Position 15 solve
	assert(level_manager.current_level_index == 14, "On Position 15")
	await solve_current_level.call()
	await level_manager.summary_tween.finished
	await process_frame

	assert(complete_overlay.visible, "RunCompleteOverlay visible")

	# Tap Play Again
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Position 1")
	assert(level_manager.current_lives == 3, "Lives reset to 3 on Play Again")
	assert(lives_lbl.text == "♥ ♥ ♥", "Lives label shows ♥ ♥ ♥")
	assert(not complete_overlay.visible, "Complete overlay hidden")
	assert(level_manager.current_run_levels.size() == 15, "New run sequence active")

	print("\n>>> ALL STEP 11C AUTOMATED TESTS PASSED PERFECTLY! <<<\n")
	quit(0)

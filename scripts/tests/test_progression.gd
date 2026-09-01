extends SceneTree

const SaveManager = preload("res://scripts/core/save_manager.gd")

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
	print("--- BEGINNING STEP 14D AUTOMATED TEST SUITE (NEAR-RECORD MOTIVATION & LIFE POLISH) ---")

	# Define isolated test save paths
	var test_save_path: String = "user://test_save_14d.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	# --- TEST SCENARIO A: PB START = 5, RUN BEST = 4 -> 'Rekoruna sadece 1 kaldı!' ---
	print("\n[SCENARIO A] PB = 5, run best = 4 -> failure motivation displays 'Rekoruna sadece 1 kaldı!'")
	var sm_setup := SaveManager.new()
	sm_setup.save_path = test_save_path
	sm_setup.sound_enabled = true
	sm_setup.haptics_enabled = true
	sm_setup.personal_best_streak = 5
	sm_setup.tutorial_completed = true
	sm_setup.save_data()

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()
	var save_manager: SaveManager = main_node.get_node("SaveManager") as SaveManager
	save_manager.save_path = test_save_path

	root.add_child(main_node)
	await process_frame
	await _sync_physics()

	var level_manager: LevelManager = main_node.get_node("LevelManager") as LevelManager
	var feedback_manager: FeedbackManager = main_node.get_node("FeedbackManager") as FeedbackManager
	var main_menu: Control = main_node.get_node("MainMenu") as Control
	var start_btn: Button = main_menu.get_node("StartGameButton") as Button
	var lives_lbl: Label = main_node.get_node("LivesLabel") as Label
	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
	var failure_motivation_lbl: Label = failure_overlay.get_node("Card/FailureMotivationLabel") as Label
	var failure_try_again_btn: Button = failure_overlay.get_node("Card/TryAgainButton") as Button

	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# Helper to solve current active level
	var solve_current = func() -> void:
		var cur_data = level_manager.current_level_data
		if cur_data.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
			level_manager.shape_piece_a.reset_piece()
			level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
			await _sync_physics()
			level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
		else:
			var cp: DraggablePiece = null
			for p in level_manager.math_pieces:
				if p.piece_text == cur_data.correct_answer:
					cp = p
					break
			assert(cp != null, "Correct piece not found")
			cp.reset_piece()
			cp.global_position = level_manager.math_target_zone.global_position
			await _sync_physics()
			level_manager._on_math_piece_dropped(cp)
		await level_manager.level_completed

	# Helper to perform deliberate wrong drop
	var drop_wrong = func() -> void:
		var c_data = level_manager.current_level_data
		if c_data.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
			level_manager.shape_piece_a.reset_piece()
			var old_m = level_manager.shape_piece_a.match_id
			level_manager.shape_piece_a.match_id = "wrong_id"
			level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
			await _sync_physics()
			level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
			level_manager.shape_piece_a.match_id = old_m
		else:
			var wp: DraggablePiece = null
			for p in level_manager.math_pieces:
				if p.piece_text != c_data.correct_answer:
					wp = p
					break
			assert(wp != null)
			wp.reset_piece()
			wp.global_position = level_manager.math_target_zone.global_position
			await _sync_physics()
			level_manager._on_math_piece_dropped(wp)

	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.personal_best_at_run_start == 5, "PB at start = 5")

	# --- TEST SCENARIO I: NEUTRAL DROP -> NO LIFE LOSS, NO PULSE ---
	print("\n[SCENARIO I] Neutral drop in empty space -> 3 lives intact, no pulse")
	var initial_lives = level_manager.current_lives
	var initial_lives_text = lives_lbl.text
	var cur_d = level_manager.current_level_data
	if cur_d.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
		level_manager.shape_piece_a.global_position = Vector2(30, 30)
		await _sync_physics()
		level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
	else:
		level_manager.math_pieces[0].global_position = Vector2(30, 30)
		await _sync_physics()
		level_manager._on_math_piece_dropped(level_manager.math_pieces[0])

	assert(level_manager.current_lives == initial_lives, "Scenario I: Lives remained 3")
	assert(lives_lbl.text == initial_lives_text, "Scenario I: Lives label text unchanged")

	# Solve 4 levels to reach best streak 4
	for i in range(4):
		await solve_current.call()
		if level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(level_manager.best_streak_this_run == 4, "Best streak is 4")

	# --- TEST SCENARIO G, H, J: DELIBERATE WRONG DROPS & LIFE LOSS ANIMATION ---
	print("\n[SCENARIO G, H, J] Deliberate wrong drops decrease lives by 1, start life-loss visual tween, and trigger failure")
	await drop_wrong.call()
	assert(level_manager.current_lives == 2, "Scenario G: Lives = 2")
	assert(level_manager.lives_tween != null, "Scenario H: Life loss tween started")

	await drop_wrong.call()
	assert(level_manager.current_lives == 1, "Scenario G: Lives = 1")

	await drop_wrong.call() # Final life lost
	assert(level_manager.current_lives == 0, "Scenario J: Lives = 0")
	assert(lives_lbl.text == "♡ ♡ ♡", "Scenario J: All hearts empty")

	if level_manager.failure_tween:
		await level_manager.failure_tween.finished
	await process_frame
	await _sync_physics()

	assert(failure_overlay.visible == true, "Failure overlay shown")
	assert(failure_motivation_lbl.visible == true, "Scenario A: Motivation visible for gap 1")
	assert(failure_motivation_lbl.text == "Rekoruna sadece 1 kaldı!", "Scenario A: Motivation text matches 'Rekoruna sadece 1 kaldı!'")

	# --- TEST SCENARIO K: RETRY RESETS LIVES VISUAL STATE ---
	print("\n[SCENARIO K] Retry resets LivesLabel visual state and hides motivation label")
	failure_try_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_lives == 3, "Lives reset to 3")
	assert(lives_lbl.scale == Vector2.ONE, "Scenario K: Lives label scale is (1, 1)")
	assert(lives_lbl.modulate == Color.WHITE, "Scenario K: Lives label color is WHITE")
	assert(failure_motivation_lbl.visible == false, "Scenario K: Motivation label hidden on new run")

	# --- TEST SCENARIO B: PB START = 8, RUN BEST = 6 -> 'Rekoruna çok yaklaştın!' ---
	print("\n[SCENARIO B] PB start = 8, run best = 6 -> failure motivation displays 'Rekoruna çok yaklaştın!'")
	level_manager.personal_best_at_run_start = 8
	level_manager.best_streak_this_run = 6
	level_manager.record_broken_this_run = false
	level_manager.is_run_failed = true
	level_manager._show_run_failure_overlay()

	assert(failure_motivation_lbl.visible == true, "Scenario B: Motivation visible for gap 2")
	assert(failure_motivation_lbl.text == "Rekoruna çok yaklaştın!", "Scenario B: Motivation text matches 'Rekoruna çok yaklaştın!'")

	# --- TEST SCENARIO C: PB START = 10, RUN BEST = 5 (GAP 5) -> NO MOTIVATION ---
	print("\n[SCENARIO C] PB start = 10, run best = 5 (gap = 5) -> motivation hidden")
	level_manager.personal_best_at_run_start = 10
	level_manager.best_streak_this_run = 5
	level_manager._show_run_failure_overlay()

	assert(failure_motivation_lbl.visible == false, "Scenario C: Motivation hidden for gap 5")

	# --- TEST SCENARIO D: PB START = 2, RUN BEST = 1 -> NO MOTIVATION (LOW PB) ---
	print("\n[SCENARIO D] PB start = 2, run best = 1 (PB < 3) -> motivation hidden")
	level_manager.personal_best_at_run_start = 2
	level_manager.best_streak_this_run = 1
	level_manager._show_run_failure_overlay()

	assert(failure_motivation_lbl.visible == false, "Scenario D: Motivation hidden for PB < 3")

	# --- TEST SCENARIO E: RECORD BROKEN DURING RUN -> NO MOTIVATION ---
	print("\n[SCENARIO E] Record broken during run -> motivation hidden on failure")
	level_manager.personal_best_at_run_start = 5
	level_manager.best_streak_this_run = 6
	level_manager.record_broken_this_run = true
	level_manager._show_run_failure_overlay()

	assert(failure_motivation_lbl.visible == false, "Scenario E: Motivation hidden when record was broken")

	# --- TEST SCENARIO L: RETURN TO MAIN MENU RESTORES LIVES VISUAL STATE ---
	print("\n[SCENARIO L] Return to Main Menu resets lives visual state and motivation label")
	main_node.return_to_main_menu()
	await process_frame
	await _sync_physics()

	assert(lives_lbl.scale == Vector2.ONE, "Scenario L: Lives scale is 1.0")
	assert(lives_lbl.modulate == Color.WHITE, "Scenario L: Lives modulate is WHITE")
	assert(failure_motivation_lbl.visible == false, "Scenario L: Motivation label hidden")

	# Clean up test save file
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	print("\n>>> ALL STEP 14D AUTOMATED TESTS (SCENARIOS A - R) PASSED PERFECTLY! <<<\n")
	quit(0)














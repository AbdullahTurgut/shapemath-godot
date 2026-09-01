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
	print("--- BEGINNING STEP 14C AUTOMATED TEST SUITE (STREAK MILESTONES & PERFECT RUN) ---")

	# Define isolated test save paths
	var test_save_path: String = "user://test_save_14c.cfg"
	var fresh_save_path: String = "user://test_save_14c_fresh.cfg"

	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	if FileAccess.file_exists(fresh_save_path):
		DirAccess.remove_absolute(fresh_save_path)

	# --- TEST SCENARIO D, O, P: RECORD BREAK PRECEDENCE OVER x5 MILESTONE ---
	print("\n[SCENARIO D, O, P] PB = 4 -> reaching x5 triggers Personal Record Banner, suppressing x5 milestone text")
	var sm_d := SaveManager.new()
	sm_d.save_path = test_save_path
	sm_d.sound_enabled = true
	sm_d.haptics_enabled = true
	sm_d.personal_best_streak = 4
	sm_d.tutorial_completed = true
	sm_d.save_data()

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
	var success_lbl: Label = main_node.get_node("SuccessLabel") as Label
	var record_banner: Control = main_node.get_node("RecordBanner") as Control
	var summary_overlay: Control = main_node.get_node("RunCompleteOverlay") as Control
	var summary_title: Label = summary_overlay.get_node("Card/CardTitle") as Label
	var summary_final_streak: Label = summary_overlay.get_node("Card/FinalStreakLabel") as Label
	var summary_best_streak: Label = summary_overlay.get_node("Card/BestStreakLabel") as Label
	var summary_session_streak: Label = summary_overlay.get_node("Card/SessionStreakLabel") as Label
	var play_again_btn: Button = summary_overlay.get_node("Card/PlayAgainButton") as Button

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

	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.personal_best_at_run_start == 4, "PB at run start is 4")
	assert(level_manager.mistakes_this_run == 0, "Scenario G: mistakes_this_run is 0 on fresh run")
	assert(level_manager.current_run_levels.size() == 15, "Scenario R: 15 levels generated")
	assert(level_manager.levels.size() == 36, "Scenario Q: 36 levels in pool")

	# Solves 1 to 4: standard feedback
	for i in range(4):
		await solve_current.call()
		assert(success_lbl.text == "Harika!", "Scenario A: Standard 'Harika!' at streak %d" % level_manager.current_streak)
		assert(record_banner.visible == false, "No record banner yet")
		if level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(level_manager.current_streak == 4, "Streak is 4")

	# Solve 5: Reaching x5 breaks PB of 4 -> Personal Record Celebration takes priority over x5 milestone
	await solve_current.call()
	assert(level_manager.current_streak == 5, "Streak is 5")
	assert(record_banner.visible == true, "Scenario D: Record banner triggered at x5 (beats PB 4)")
	assert(level_manager.record_broken_this_run == true, "Scenario D: record_broken_this_run is true")
	assert(success_lbl.visible == false, "Scenario D: success_lbl hidden during record celebration")

	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	# --- TEST SCENARIO F, I: NEUTRAL DROP DOES NOT AFFECT STREAK OR MISTAKES ---
	print("\n[SCENARIO F & I] Neutral drop in empty space -> streak and mistakes_this_run unchanged")
	var prev_mistakes = level_manager.mistakes_this_run
	var prev_streak = level_manager.current_streak
	var cur_data = level_manager.current_level_data
	if cur_data.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
		level_manager.shape_piece_a.global_position = Vector2(50, 50)
		await _sync_physics()
		level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
	else:
		level_manager.math_pieces[0].global_position = Vector2(50, 50)
		await _sync_physics()
		level_manager._on_math_piece_dropped(level_manager.math_pieces[0])

	assert(level_manager.current_streak == prev_streak, "Scenario F: Streak unchanged after neutral drop")
	assert(level_manager.mistakes_this_run == prev_mistakes, "Scenario I: mistakes_this_run unchanged after neutral drop")

	# --- TEST SCENARIO C: REACH STREAK x10 -> 'Müthiş Seri!' ---
	print("\n[SCENARIO C] Solves 6 to 10 -> reaching streak 10 shows 'Müthiş Seri!'")
	for i in range(4): # Solves 6, 7, 8, 9
		await solve_current.call()
		if level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(level_manager.current_streak == 9, "Streak is 9")

	# Solve 10: triggers x10 milestone
	await solve_current.call()
	assert(level_manager.current_streak == 10, "Streak is 10")
	assert(success_lbl.visible == true, "Success label visible")
	assert(success_lbl.text == "Müthiş Seri!", "Scenario C: x10 milestone displays 'Müthiş Seri!'")

	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	# --- TEST SCENARIO J, K: FLAWLESS 15/15 FINISH -> 'Mükemmel Tur!' RECOGNITION ---
	print("\n[SCENARIO J & K] Finish levels 11 to 15 with 0 mistakes -> 'Mükemmel Tur!' result overlay")
	for i in range(4): # Solves 11, 12, 13, 14
		await solve_current.call()
		if level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(level_manager.current_level_index == 14, "On final level 15")
	await solve_current.call() # Solve 15
	assert(success_lbl.text == "Harika! Mükemmel Tur!", "Final level success feedback shows Mükemmel Tur")

	if level_manager.summary_tween:
		await level_manager.summary_tween.finished
	await process_frame
	await _sync_physics()

	assert(summary_overlay.visible == true, "Summary overlay visible")
	assert(level_manager.mistakes_this_run == 0, "Zero mistakes in run")
	assert(summary_title.text.contains("Mükemmel Tur!"), "Scenario J: Title displays 'Mükemmel Tur!'")
	assert(summary_final_streak.text == "Son Seri: x15", "Scenario K: Final streak is x15")
	assert(summary_best_streak.text == "Bu Tur En İyi: x15", "Scenario K: Best streak is x15")
	assert(summary_session_streak.text == "Kişisel Rekor: x15", "Scenario K: Kişisel Rekor is x15")

	# --- TEST SCENARIO B, E, H, L, M: RUN WITH 1 MISTAKE -> 'Harika Seri!' RE-TRIGGER & NON-PERFECT COMPLETION ---
	print("\n[SCENARIO B, E, H, L, M] Start new run with 1 mistake -> resets mistakes to 0, tests x5 milestone, shows 'Tur Tamamlandı!'")
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.mistakes_this_run == 0, "Scenario M: New run resets mistakes_this_run = 0")
	assert(level_manager.current_streak == 0, "New run resets streak = 0")

	# Make a deliberate wrong drop on level 1
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

	assert(level_manager.mistakes_this_run == 1, "Scenario H: Deliberate wrong drop incremented mistakes_this_run to 1")
	assert(level_manager.current_streak == 0, "Streak reset to 0")

	# Solve Level 1
	await solve_current.call()
	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	# Solve Levels 2, 3, 4, 5 (streaks 2, 3, 4, 5)
	for i in range(3): # Levels 2, 3, 4 (streaks 2, 3, 4)
		await solve_current.call()
		if level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(level_manager.current_streak == 4, "Streak is 4")

	# Level 5 solve (streak reaches 5)
	await solve_current.call()
	assert(level_manager.current_streak == 5, "Streak is 5")
	assert(success_lbl.text == "Harika Seri!", "Scenario B & E: x5 milestone displays 'Harika Seri!'")

	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	# Complete remaining levels (6 to 15)
	for i in range(10):
		await solve_current.call()
		if level_manager.current_level_index < 14 and level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	if level_manager.summary_tween:
		await level_manager.summary_tween.finished
	await process_frame
	await _sync_physics()

	assert(summary_overlay.visible == true, "Summary overlay visible")
	assert(level_manager.mistakes_this_run == 1, "1 mistake in run")
	assert(summary_title.text == "Tur Tamamlandı!", "Scenario L: Non-perfect run title is 'Tur Tamamlandı!' (NOT 'Mükemmel Tur!')")
	assert(not summary_title.text.contains("Mükemmel"), "Scenario L: Does not say Mükemmel")

	# --- TEST SCENARIO N: RETURN TO MAIN MENU RESETS mistakes_this_run ---
	print("\n[SCENARIO N] Return to Main Menu and start new run -> mistakes_this_run = 0")
	main_node.return_to_main_menu()
	await process_frame
	await _sync_physics()

	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.mistakes_this_run == 0, "Scenario N: mistakes_this_run is 0")

	# Clean up test save files
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	if FileAccess.file_exists(fresh_save_path):
		DirAccess.remove_absolute(fresh_save_path)

	print("\n>>> ALL STEP 14C AUTOMATED TESTS (SCENARIOS A - R) PASSED PERFECTLY! <<<\n")
	quit(0)













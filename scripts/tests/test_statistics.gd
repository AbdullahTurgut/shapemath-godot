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
	print("================================================================================")
	print("--- BEGINNING STEP 16 LIFETIME STATISTICS & UI TEST SUITE ---")
	print("================================================================================")

	var test_save_path: String = "user://test_save_statistics.cfg"
	var legacy_save_path: String = "user://test_save_legacy_stats.cfg"

	for p in [test_save_path, legacy_save_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

	# ================================================================================
	# TEST 1: SAVEMANAGER INITIAL STATE & GETTERS
	# ================================================================================
	print("\n[TEST 1] SaveManager statistics defaults and getters")
	var sm := SaveManager.new()
	sm.save_path = test_save_path
	sm.load_data()

	assert(sm.get_total_runs_started() == 0, "Default runs started is 0")
	assert(sm.get_total_runs_completed() == 0, "Default runs completed is 0")
	assert(sm.get_total_perfect_runs() == 0, "Default perfect runs is 0")
	assert(sm.get_total_puzzles_solved() == 0, "Default puzzles solved is 0")
	assert(sm.get_success_rate_percentage() == 0, "Default success rate is 0%")
	print("-> TEST 1 PASSED: Defaults verified.")

	# ================================================================================
	# TEST 2: SUCCESS RATE PERCENTAGE FORMULA & ROUNDING
	# ================================================================================
	print("\n[TEST 2] Success rate percentage calculation and rounding")
	sm.total_runs_started = 0
	sm.total_runs_completed = 0
	assert(sm.get_success_rate_percentage() == 0, "0/0 -> 0%")

	sm.total_runs_started = 1
	sm.total_runs_completed = 0
	assert(sm.get_success_rate_percentage() == 0, "0/1 -> 0%")

	sm.total_runs_started = 2
	sm.total_runs_completed = 1
	assert(sm.get_success_rate_percentage() == 50, "1/2 -> 50%")

	sm.total_runs_started = 3
	sm.total_runs_completed = 2
	assert(sm.get_success_rate_percentage() == 67, "2/3 -> 67% (rounded)")

	sm.total_runs_started = 4
	sm.total_runs_completed = 3
	assert(sm.get_success_rate_percentage() == 75, "3/4 -> 75%")

	sm.total_runs_started = 1
	sm.total_runs_completed = 1
	assert(sm.get_success_rate_percentage() == 100, "1/1 -> 100%")
	print("-> TEST 2 PASSED: Success rate rounding verified.")

	# ================================================================================
	# TEST 3: LEGACY SAVE FILE COMPATIBILITY
	# ================================================================================
	print("\n[TEST 3] Legacy save file compatibility (missing stats keys)")
	var legacy_cfg := ConfigFile.new()
	legacy_cfg.set_value("settings", "sound_enabled", false)
	legacy_cfg.set_value("settings", "haptics_enabled", true)
	legacy_cfg.set_value("progress", "personal_best_streak", 12)
	legacy_cfg.set_value("progress", "tutorial_completed", true)
	legacy_cfg.save(legacy_save_path)

	var sm_legacy := SaveManager.new()
	sm_legacy.save_path = legacy_save_path
	sm_legacy.load_data()

	assert(sm_legacy.get_sound_enabled() == false, "Legacy sound preserved")
	assert(sm_legacy.get_haptics_enabled() == true, "Legacy haptics preserved")
	assert(sm_legacy.get_personal_best_streak() == 12, "Legacy PB preserved")
	assert(sm_legacy.get_tutorial_completed() == true, "Legacy tutorial status preserved")
	assert(sm_legacy.get_total_runs_started() == 0, "Missing runs started defaults to 0")
	assert(sm_legacy.get_total_runs_completed() == 0, "Missing runs completed defaults to 0")
	assert(sm_legacy.get_total_perfect_runs() == 0, "Missing perfect runs defaults to 0")
	assert(sm_legacy.get_total_puzzles_solved() == 0, "Missing puzzles solved defaults to 0")
	assert(sm_legacy.get_success_rate_percentage() == 0, "Missing success rate defaults to 0%")
	print("-> TEST 3 PASSED: Legacy save compatibility verified.")

	# ================================================================================
	# TEST 4: LIFECYCLE RECORDING & DOUBLE-COUNT PREVENTION
	# ================================================================================
	print("\n[TEST 4] Full run lifecycle and double-count prevention")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()
	var sm_game: SaveManager = main_node.get_node("SaveManager") as SaveManager
	sm_game.save_path = test_save_path
	sm_game.total_runs_started = 0
	sm_game.total_runs_completed = 0
	sm_game.total_perfect_runs = 0
	sm_game.total_puzzles_solved = 0
	sm_game.personal_best_streak = 0
	sm_game.tutorial_completed = true
	sm_game.save_data()

	root.add_child(main_node)
	await process_frame
	await _sync_physics()

	var lm: LevelManager = main_node.get_node("LevelManager") as LevelManager
	var mm: Control = main_node.get_node("MainMenu") as Control
	var start_btn: Button = mm.get_node("StartGameButton") as Button
	var stats_btn: Button = mm.get_node("StatisticsButton") as Button
	var settings_btn: Button = mm.get_node("SettingsButton") as Button
	var stats_overlay: Control = main_node.get_node("StatisticsOverlay") as Control
	var settings_overlay: Control = main_node.get_node("SettingsOverlay") as Control
	var stats_close_btn: Button = stats_overlay.get_node("Card/CloseButton") as Button
	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
	var try_again_btn: Button = failure_overlay.get_node("Card/TryAgainButton") as Button
	var summary_overlay: Control = main_node.get_node("RunCompleteOverlay") as Control
	var play_again_btn: Button = summary_overlay.get_node("Card/PlayAgainButton") as Button

	lm.transition_delay = 0.01
	lm.summary_delay = 0.01
	lm.failure_delay = 0.01

	# Helper to solve current level
	var solve_current = func() -> void:
		var cur_data = lm.current_level_data
		if cur_data.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
			lm.shape_piece_a.reset_piece()
			lm.shape_piece_a.global_position = lm.shape_piece_b.global_position
			await _sync_physics()
			lm._on_shape_piece_dropped(lm.shape_piece_a)
		elif cur_data.puzzle_type == LevelData.PuzzleType.SQUARE_FILL:
			for p in lm.square_fill_pieces:
				var target_slot: SquareFillSlot = null
				for s in lm.square_fill_slots:
					if s.slot_index == p.target_slot_index:
						target_slot = s
						break
				assert(target_slot != null, "Target slot found for piece")
				p.reset_piece()
				p.global_position = target_slot.global_position
				await _sync_physics()
				lm._on_square_fill_piece_dropped(p)
			return
		else:
			var cp: DraggablePiece = null
			for p in lm.math_pieces:
				if p.piece_text == cur_data.correct_answer:
					cp = p
					break
			assert(cp != null, "Correct piece not found")
			cp.reset_piece()
			cp.global_position = lm.math_target_zone.global_position
			await _sync_physics()
			lm._on_math_piece_dropped(cp)
		await lm.level_completed

	# Helper to drop wrong
	var drop_wrong = func() -> void:
		var c_data = lm.current_level_data
		if c_data.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
			lm.shape_piece_a.reset_piece()
			var old_m = lm.shape_piece_a.match_id
			lm.shape_piece_a.match_id = "wrong_id"
			lm.shape_piece_a.global_position = lm.shape_piece_b.global_position
			await _sync_physics()
			lm._on_shape_piece_dropped(lm.shape_piece_a)
			lm.shape_piece_a.match_id = old_m
		elif c_data.puzzle_type == LevelData.PuzzleType.SQUARE_FILL:
			var p: DraggablePiece = lm.square_fill_pieces[0]
			var wrong_slot: SquareFillSlot = null
			for s in lm.square_fill_slots:
				if s.slot_index != p.target_slot_index:
					wrong_slot = s
					break
			assert(wrong_slot != null, "Wrong slot found")
			p.reset_piece()
			p.global_position = wrong_slot.global_position
			await _sync_physics()
			lm._on_square_fill_piece_dropped(p)
		else:
			var wp: DraggablePiece = null
			for p in lm.math_pieces:
				if p.piece_text != c_data.correct_answer:
					wp = p
					break
			assert(wp != null)
			wp.reset_piece()
			wp.global_position = lm.math_target_zone.global_position
			await _sync_physics()
			lm._on_math_piece_dropped(wp)

	# Start Run 1
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(sm_game.get_total_runs_started() == 1, "Run 1 started -> total_runs_started = 1")
	assert(sm_game.get_total_puzzles_solved() == 0, "No puzzles solved yet")

	# Solve Level 1
	await solve_current.call()
	assert(sm_game.get_total_puzzles_solved() == 1, "Level 1 solved -> total_puzzles_solved = 1")

	# Attempt duplicate drop on Level 1 (should not double-count)
	if lm.math_pieces.size() > 0:
		lm._on_math_piece_dropped(lm.math_pieces[0])
	assert(sm_game.get_total_puzzles_solved() == 1, "Duplicate drop guard prevented double count")

	if lm.transition_tween:
		await lm.transition_tween.finished
	await process_frame
	await _sync_physics()

	# Fail Run 1 on Level 2: 3 wrong drops
	await drop_wrong.call()
	await drop_wrong.call()
	await drop_wrong.call()
	if lm.failure_tween:
		await lm.failure_tween.finished
	await process_frame
	await _sync_physics()

	assert(lm.is_run_failed == true, "Run 1 failed")
	assert(sm_game.get_total_runs_started() == 1, "Run 1 failed -> total_runs_started remains 1")
	assert(sm_game.get_total_runs_completed() == 0, "Failed run -> total_runs_completed = 0")
	assert(sm_game.get_total_perfect_runs() == 0, "Failed run -> total_perfect_runs = 0")
	assert(sm_game.get_total_puzzles_solved() == 1, "Puzzles solved remains 1")
	assert(sm_game.get_success_rate_percentage() == 0, "Success rate is 0/1 = 0%")
	print("-> Step 4.1: Run 1 failure recorded without completion.")

	# Start Run 2 (Perfect Run 15/15) via Try Again
	try_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(sm_game.get_total_runs_started() == 2, "Run 2 started -> total_runs_started = 2")

	# Solve all 15 levels perfectly
	for i in range(14):
		await solve_current.call()
		if lm.transition_tween:
			await lm.transition_tween.finished
		await process_frame
		await _sync_physics()

	await solve_current.call() # Final level 15
	if lm.summary_tween:
		await lm.summary_tween.finished
	await process_frame
	await _sync_physics()

	assert(summary_overlay.visible == true, "Summary overlay visible for Run 2")
	assert(sm_game.get_total_runs_started() == 2, "Run 2 complete -> total_runs_started = 2")
	assert(sm_game.get_total_runs_completed() == 1, "Run 2 complete -> total_runs_completed = 1")
	assert(sm_game.get_total_perfect_runs() == 1, "Run 2 perfect -> total_perfect_runs = 1")
	assert(sm_game.get_total_puzzles_solved() == 16, "Puzzles solved = 1 + 15 = 16")
	assert(sm_game.get_success_rate_percentage() == 50, "Success rate is 1/2 = 50%")
	print("-> Step 4.2: Perfect Run 2 completion recorded accurately.")

	# Start Run 3 (Non-Perfect Completed Run) via Play Again
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(sm_game.get_total_runs_started() == 3, "Run 3 started -> total_runs_started = 3")

	# Deliberate 1 mistake on Level 1
	await drop_wrong.call()
	assert(lm.mistakes_this_run == 1, "Run 3 has 1 mistake")

	# Complete all 15 levels
	for i in range(14):
		await solve_current.call()
		if lm.transition_tween:
			await lm.transition_tween.finished
		await process_frame
		await _sync_physics()

	await solve_current.call() # Final level 15
	if lm.summary_tween:
		await lm.summary_tween.finished
	await process_frame
	await _sync_physics()

	assert(sm_game.get_total_runs_started() == 3, "Run 3 complete -> total_runs_started = 3")
	assert(sm_game.get_total_runs_completed() == 2, "Run 3 complete -> total_runs_completed = 2")
	assert(sm_game.get_total_perfect_runs() == 1, "Non-perfect run did not increment perfect runs")
	assert(sm_game.get_total_puzzles_solved() == 31, "Puzzles solved = 16 + 15 = 31")
	assert(sm_game.get_success_rate_percentage() == 67, "Success rate is 2/3 = 67% (rounded)")
	print("-> Step 4.3: Non-perfect Run 3 completion recorded accurately.")

	# ================================================================================
	# TEST 5: STATISTICS OVERLAY UI, FORMATTING & MUTUAL EXCLUSION
	# ================================================================================
	print("\n[TEST 5] Statistics overlay display formatting and mutual exclusion")
	main_node.return_to_main_menu()
	await process_frame
	await _sync_physics()

	assert(main_node.current_state == main_node.AppState.MAIN_MENU, "Returned to Main Menu")

	# Open Statistics Overlay
	stats_btn.pressed.emit()
	assert(stats_overlay.visible == true, "Statistics overlay opened")
	assert(settings_overlay.visible == false, "Settings overlay is closed")

	var val_streak: Label = stats_overlay.get_node("Card/BestStreakValue") as Label
	var val_solved: Label = stats_overlay.get_node("Card/PuzzlesSolvedValue") as Label
	var val_completed: Label = stats_overlay.get_node("Card/RunsCompletedValue") as Label
	var val_perfect: Label = stats_overlay.get_node("Card/PerfectRunsValue") as Label
	var val_rate: Label = stats_overlay.get_node("Card/SuccessRateValue") as Label

	assert(val_streak.text == "x15", "Best streak display matches 'x15'")
	assert(val_solved.text == "31", "Puzzles solved display matches '31'")
	assert(val_completed.text == "2", "Runs completed display matches '2'")
	assert(val_perfect.text == "1", "Perfect runs display matches '1'")
	assert(val_rate.text == "67%", "Success rate display matches '67%'")

	# Mutual Exclusion: Opening Settings while Statistics is open
	settings_btn.pressed.emit()
	assert(settings_overlay.visible == true, "Settings opened")
	assert(stats_overlay.visible == false, "Statistics closed when Settings opened")

	# Opening Statistics while Settings is open
	stats_btn.pressed.emit()
	assert(stats_overlay.visible == true, "Statistics opened")
	assert(settings_overlay.visible == false, "Settings closed when Statistics opened")

	# Close Statistics via CloseButton
	stats_close_btn.pressed.emit()
	assert(stats_overlay.visible == false, "Close button closed statistics overlay")
	print("-> TEST 5 PASSED: UI values and mutual exclusion verified.")

	# ================================================================================
	# TEST 6: ANDROID BACK NAVIGATION HIERARCHY
	# ================================================================================
	print("\n[TEST 6] Android Back navigation hierarchy")
	# 1. Back when Statistics Overlay open -> closes Statistics
	stats_btn.pressed.emit()
	assert(stats_overlay.visible == true)
	main_node._handle_back_request()
	assert(stats_overlay.visible == false, "Back closed Statistics Overlay")

	# 2. Back when Settings Overlay open -> closes Settings
	settings_btn.pressed.emit()
	assert(settings_overlay.visible == true)
	main_node._handle_back_request()
	assert(settings_overlay.visible == false, "Back closed Settings Overlay")

	# 3. Back in Main Menu with quit handler
	var quit_called: Array[bool] = [false]
	main_node.quit_handler = func(): quit_called[0] = true
	main_node._handle_back_request()
	assert(quit_called[0] == true, "Back on Main Menu called quit handler")
	print("-> TEST 6 PASSED: Android Back routing verified.")

	# Clean up test save files
	for p in [test_save_path, legacy_save_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

	print("\n================================================================================")
	print(">>> ALL STEP 16 TESTS PASSED 100%! <<<")
	print("================================================================================\n")
	quit(0)

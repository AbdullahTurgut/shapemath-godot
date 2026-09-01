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
	print("--- BEGINNING STEP 13F AUTOMATED TEST SUITE (BRANDING, ADAPTIVE ICONS & FINAL POLISH) ---")

	# Define isolated test save path
	var test_save_path: String = "user://test_save_13f.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	# Pre-populate test save with personal_best = 7
	var sm_setup := SaveManager.new()
	sm_setup.save_path = test_save_path
	sm_setup.sound_enabled = true
	sm_setup.haptics_enabled = true
	sm_setup.personal_best_streak = 7
	sm_setup.save_data()

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()

	# Point SaveManager to isolated test path before adding to tree
	var save_manager: SaveManager = main_node.get_node("SaveManager") as SaveManager
	save_manager.save_path = test_save_path

	root.add_child(main_node)

	# Allow a frame for _ready to execute
	await process_frame
	await _sync_physics()

	var feedback_manager: FeedbackManager = main_node.get_node("FeedbackManager") as FeedbackManager
	var level_manager: LevelManager = main_node.get_node("LevelManager") as LevelManager
	var main_menu: Control = main_node.get_node("MainMenu") as Control
	var menu_title_lbl: Label = main_menu.get_node("TitleLabel") as Label
	var menu_sub_lbl: Label = main_menu.get_node("SubtitleLabel") as Label
	var start_btn: Button = main_menu.get_node("StartGameButton") as Button
	var settings_btn: Button = main_menu.get_node("SettingsButton") as Button
	var menu_pb_lbl: Label = main_menu.get_node("PersonalBestLabel") as Label

	var in_game_menu_btn: Button = main_node.get_node("InGameMenuButton") as Button
	var settings_overlay: Control = main_node.get_node("SettingsOverlay") as Control
	var settings_card: Control = settings_overlay.get_node("Card") as Control
	var sound_toggle_btn: Button = settings_card.get_node("SoundToggleButton") as Button
	var haptics_toggle_btn: Button = settings_card.get_node("HapticsToggleButton") as Button
	var close_btn: Button = settings_card.get_node("CloseButton") as Button

	var complete_overlay: Control = main_node.get_node("RunCompleteOverlay") as Control
	var complete_pb_lbl: Label = complete_overlay.get_node("Card/SessionStreakLabel") as Label

	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
	var failure_pb_lbl: Label = failure_overlay.get_node("Card/FailureSessionStreakLabel") as Label

	var level_lbl: Label = main_node.get_node("LevelIndicatorLabel") as Label
	var prompt_lbl: Label = main_node.get_node("PromptLabel") as Label

	# Hook quit handler for testing quit branch without killing test runner
	var quit_tracker := [false]
	main_node.quit_handler = func():
		quit_tracker[0] = true

	# Accelerate animation delays for test suite execution speed
	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# --- TEST SCENARIO A & B: MAIN MENU LAUNCH & BRANDING TERMINOLOGY ---
	print("\n[SCENARIO A & B] Main Menu branding text and Kişisel Rekor terminology")
	assert(main_menu.visible == true, "Scenario A: Main Menu visible on launch")
	assert(menu_title_lbl.text == "ShapeMath", "Scenario A: Title is 'ShapeMath'")
	assert(menu_sub_lbl.text == "Matematik & Şekil Bulmacaları", "Scenario A: Subtitle is 'Matematik & Şekil Bulmacaları'")
	assert(menu_pb_lbl.text == "Kişisel Rekor: x7", "Scenario B: Main Menu PB label shows 'Kişisel Rekor: x7'")

	# --- TEST SCENARIO C: NO PLAYER-FACING 'OTURUM REKORU' ---
	print("\n[SCENARIO C] Verify no player-facing 'Oturum Rekoru' exists in result cards")
	assert(not complete_pb_lbl.text.contains("Oturum Rekoru"), "Scenario C: Complete overlay does not say Oturum Rekoru")
	assert(complete_pb_lbl.text.contains("Kişisel Rekor"), "Scenario C: Complete overlay says Kişisel Rekor")
	assert(not failure_pb_lbl.text.contains("Oturum Rekoru"), "Scenario C: Failure overlay does not say Oturum Rekoru")
	assert(failure_pb_lbl.text.contains("Kişisel Rekor"), "Scenario C: Failure overlay says Kişisel Rekor")

	# --- TEST SCENARIO D, J: SETTINGS OVERLAY & PERSISTENCE ---
	print("\n[SCENARIO D, J] Settings overlay open/close & toggle persistence")
	settings_btn.pressed.emit()
	await process_frame
	assert(settings_overlay.visible == true, "SettingsOverlay visible")

	sound_toggle_btn.pressed.emit()
	await process_frame
	assert(feedback_manager.sound_enabled == false, "Scenario J: Sound toggle disabled sound")
	assert(save_manager.get_sound_enabled() == false, "Scenario J: Sound saved as false")

	close_btn.pressed.emit()
	await process_frame
	assert(settings_overlay.visible == false, "Settings closed")

	# Restore sound
	feedback_manager.sound_enabled = true
	save_manager.set_sound_enabled(true)

	# --- TEST SCENARIO E, I: START GAME & 15-LEVEL 5+5+5 RUN GENERATION ---
	print("\n[SCENARIO E, I] Start game -> generates 15-level run (5+5+5) from 36 master levels")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(main_node.current_state == main_node.AppState.PLAYING, "In PLAYING state")
	assert(level_manager.levels.size() == 36, "Scenario I: 36 master levels intact")
	assert(level_manager.current_run_levels.size() == 15, "Scenario E: 15 levels sampled")
	assert(level_manager.current_lives == 3, "Scenario E: 3 lives initialized")
	assert(level_manager.current_streak == 0, "Scenario E: Streak = 0")

	# Helper to solve active level
	var solve_active_level = func() -> void:
		var c_lvl = level_manager.current_level_data
		if c_lvl.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
			level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
			await _sync_physics()
			level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
		else:
			var cor_piece: DraggablePiece = null
			for p in level_manager.math_pieces:
				if p.piece_text == c_lvl.correct_answer:
					cor_piece = p
					break
			assert(cor_piece != null, "Correct piece '%s' not found" % c_lvl.correct_answer)
			cor_piece.global_position = level_manager.math_target_zone.global_position
			await _sync_physics()
			level_manager._on_math_piece_dropped(cor_piece)
		await level_manager.level_completed

	# --- TEST SCENARIO F: BACK NAVIGATION ---
	print("\n[SCENARIO F] Back navigation from gameplay opens Settings and resumes safely")
	main_node._handle_back_request()
	await process_frame
	assert(settings_overlay.visible == true, "Back opened Settings")

	main_node._handle_back_request()
	await process_frame
	assert(settings_overlay.visible == false, "Second Back closed Settings")
	assert(level_manager.current_level_index == 0, "Exact puzzle resumed")

	# --- TEST SCENARIO G: RUN FAILURE UI & KIŞISEL REKOR ---
	print("\n[SCENARIO G] Trigger run failure -> displays Kişisel Rekor (x7)")
	level_manager.current_lives = 1
	var cur_lvl = level_manager.current_level_data
	if cur_lvl.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
		level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
		var old_m = level_manager.shape_piece_a.match_id
		level_manager.shape_piece_a.match_id = "wrong_match_id"
		await _sync_physics()
		level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
		level_manager.shape_piece_a.match_id = old_m
	else:
		var w_piece: DraggablePiece = null
		for p in level_manager.math_pieces:
			if p.piece_text != cur_lvl.correct_answer:
				w_piece = p
				break
		assert(w_piece != null)
		w_piece.global_position = level_manager.math_target_zone.global_position
		await _sync_physics()
		level_manager._on_math_piece_dropped(w_piece)

	if level_manager.failure_tween:
		await level_manager.failure_tween.finished
	await process_frame

	assert(failure_overlay.visible == true, "Scenario G: Failure overlay visible")
	assert(failure_pb_lbl.text == "Kişisel Rekor: x7", "Scenario G: Failure card displays 'Kişisel Rekor: x7' (got '%s')" % failure_pb_lbl.text)

	# Return to Main Menu from failure
	main_node.return_to_main_menu()
	await process_frame
	await _sync_physics()
	assert(main_menu.visible == true, "Returned to Main Menu")

	# --- TEST SCENARIO H & K: RUN COMPLETE UI & NEW PERSONAL BEST (x15) ---
	print("\n[SCENARIO H & K] Complete 15/15 -> updates Kişisel Rekor to x15, persists to disk")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	# Solve all 15 levels
	for pos in range(14):
		await solve_active_level.call()
		if level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(level_manager.current_level_index == 14, "On position 15")
	await solve_active_level.call()
	if level_manager.summary_tween:
		await level_manager.summary_tween.finished
	await process_frame

	assert(complete_overlay.visible == true, "Scenario H: Complete overlay visible")
	assert(complete_pb_lbl.text == "Kişisel Rekor: x15", "Scenario H: Complete card displays 'Kişisel Rekor: x15' (got '%s')" % complete_pb_lbl.text)
	assert(level_manager.personal_best_streak == 15, "Scenario K: LevelManager personal_best = 15")
	assert(save_manager.get_personal_best_streak() == 15, "Scenario K: SaveManager personal_best = 15")

	# Return to Main Menu and verify refreshed PB label
	main_node.return_to_main_menu()
	await process_frame
	await _sync_physics()
	assert(menu_pb_lbl.text == "Kişisel Rekor: x15", "Scenario K: Main Menu shows updated 'Kişisel Rekor: x15'")

	# Reload from disk into fresh SaveManager to verify persistence
	var disk_sm := SaveManager.new()
	disk_sm.save_path = test_save_path
	disk_sm.load_data()
	assert(disk_sm.get_personal_best_streak() == 15, "Scenario K: Reloaded personal best streak is 15")

	# Clean up test save file
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	print("\n>>> ALL STEP 13F AUTOMATED TESTS (SCENARIOS A - K) PASSED PERFECTLY! <<<\n")
	quit(0)












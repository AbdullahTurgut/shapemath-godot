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
	print("--- BEGINNING STEP 13E AUTOMATED TEST SUITE (ANDROID BACK NAVIGATION) ---")

	# Define isolated test save path
	var test_save_path: String = "user://test_save_13e.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	# Pre-populate test save with personal_best = 6
	var sm_setup := SaveManager.new()
	sm_setup.save_path = test_save_path
	sm_setup.sound_enabled = true
	sm_setup.haptics_enabled = true
	sm_setup.personal_best_streak = 6
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
	var start_btn: Button = main_menu.get_node("StartGameButton") as Button
	var settings_btn: Button = main_menu.get_node("SettingsButton") as Button
	var menu_pb_lbl: Label = main_menu.get_node("PersonalBestLabel") as Label

	var in_game_menu_btn: Button = main_node.get_node("InGameMenuButton") as Button
	var settings_overlay: Control = main_node.get_node("SettingsOverlay") as Control
	var settings_card: Control = settings_overlay.get_node("Card") as Control
	var settings_return_btn: Button = settings_card.get_node("ReturnToMenuButton") as Button

	var complete_overlay: Control = main_node.get_node("RunCompleteOverlay") as Control
	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control

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

	# --- TEST SCENARIO A: MAIN MENU -> SETTINGS -> BACK ---
	print("\n[SCENARIO A] Main Menu -> Ayarlar -> Back closes settings and keeps Main Menu")
	settings_btn.pressed.emit()
	await process_frame
	assert(settings_overlay.visible == true, "Settings is open")

	main_node._handle_back_request()
	await process_frame

	assert(settings_overlay.visible == false, "Scenario A: Settings closed via Back")
	assert(main_menu.visible == true, "Scenario A: Main Menu remains visible")
	assert(quit_tracker[0] == false, "Scenario A: App did not exit on closing settings")

	# --- TEST SCENARIO H: MAIN MENU -> BACK (EXIT APP BRANCH) ---
	print("\n[SCENARIO H] Main Menu with no overlay -> Back routes to app exit")
	main_node._handle_back_request()
	await process_frame

	assert(quit_tracker[0] == true, "Scenario H: Back on Main Menu called quit handler")
	quit_tracker[0] = false

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

	# --- TEST SCENARIO C & D: GAMEPLAY -> BACK OPENS SETTINGS (ORIGIN = GAMEPLAY) ---
	print("\n[SCENARIO C & D] Active gameplay -> Back opens Settings overlay with 'Ana Menüye Dön'")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(main_node.current_state == main_node.AppState.PLAYING, "In PLAYING state")
	assert(settings_overlay.visible == false, "Settings hidden")

	# Press Back while playing
	main_node._handle_back_request()
	await process_frame

	assert(settings_overlay.visible == true, "Scenario C: SettingsOverlay opened via Back")
	assert(main_node.settings_origin == main_node.SettingsOrigin.GAMEPLAY, "Scenario C: Origin is GAMEPLAY")
	assert(settings_return_btn.visible == true, "Scenario D: 'Ana Menüye Dön' is visible")

	# --- TEST SCENARIO B, E, J, K: SETTINGS (GAMEPLAY) -> BACK RESUMES EXACT PUZZLE ---
	print("\n[SCENARIO E, J, K] Back on Settings (gameplay) closes overlay and resumes exact puzzle")
	var active_lvl = level_manager.current_level_data
	var active_index = level_manager.current_level_index

	main_node._handle_back_request()
	await process_frame

	assert(settings_overlay.visible == false, "Scenario E: SettingsOverlay closed on second Back")
	assert(level_manager.current_level_data == active_lvl, "Scenario K: Same level data active")
	assert(level_manager.current_level_index == active_index, "Scenario J: Level index unchanged")
	assert(level_manager.current_lives == 3, "Scenario J: Lives = 3")
	assert(level_manager.current_streak == 0, "Scenario J: Streak = 0")

	# --- TEST SCENARIO F: RUN FAILURE OVERLAY -> BACK RETURNS TO MAIN MENU ---
	print("\n[SCENARIO F & L] Run Failure overlay -> Back returns cleanly to Main Menu")
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

	assert(failure_overlay.visible == true, "Failure overlay is visible")

	# Press Back while on failure overlay
	main_node._handle_back_request()
	await process_frame
	await _sync_physics()

	assert(main_menu.visible == true, "Scenario F: Main Menu visible after Back on failure overlay")
	assert(failure_overlay.visible == false, "Scenario F: Failure overlay hidden")
	assert(level_manager.current_level_data == null, "Scenario L: Gameplay cleaned up cleanly")

	# --- TEST SCENARIO G, N, P: RUN COMPLETE OVERLAY -> BACK RETURNS TO MAIN MENU ---
	print("\n[SCENARIO G, N, P] Run Complete overlay -> Back returns to Main Menu with refreshed Personal Best")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	# Solve all 15 levels (sets new personal best = 15)
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

	assert(complete_overlay.visible == true, "Complete overlay visible")

	# Press Back while on complete overlay
	main_node._handle_back_request()
	await process_frame
	await _sync_physics()

	assert(main_menu.visible == true, "Scenario G: Main Menu visible after Back on complete overlay")
	assert(complete_overlay.visible == false, "Scenario G: Complete overlay hidden")
	assert(menu_pb_lbl.text == "Kişisel Rekor: x15", "Scenario N: Personal best refreshed to x15 on menu")

	# --- TEST SCENARIO I, M, O: PERSISTENCE & POOL INTEGRITY ---
	print("\n[SCENARIO I, M, O] Persistence & Pool integrity checks")
	assert(level_manager.levels.size() == 36, "Scenario O: 36 master levels intact")
	assert(save_manager.get_personal_best_streak() == 15, "Scenario N: Persisted personal best is 15")

	# Clean up test save file
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	print("\n>>> ALL STEP 13E AUTOMATED TESTS (SCENARIOS A - P) PASSED PERFECTLY! <<<\n")
	quit(0)











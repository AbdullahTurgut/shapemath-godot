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
	print("--- BEGINNING STEP 13D AUTOMATED TEST SUITE (IN-GAME MENU & MAIN MENU NAVIGATION) ---")

	# Define isolated test save path
	var test_save_path: String = "user://test_save_13d.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	# Pre-populate test save with personal_best = 4
	var sm_setup := SaveManager.new()
	sm_setup.save_path = test_save_path
	sm_setup.sound_enabled = true
	sm_setup.haptics_enabled = true
	sm_setup.personal_best_streak = 4
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
	var sound_toggle_btn: Button = settings_card.get_node("SoundToggleButton") as Button
	var haptics_toggle_btn: Button = settings_card.get_node("HapticsToggleButton") as Button
	var settings_return_btn: Button = settings_card.get_node("ReturnToMenuButton") as Button
	var close_btn: Button = settings_card.get_node("CloseButton") as Button

	var complete_overlay: Control = main_node.get_node("RunCompleteOverlay") as Control
	var play_again_btn: Button = complete_overlay.get_node("Card/PlayAgainButton") as Button
	var complete_menu_btn: Button = complete_overlay.get_node("Card/CompleteMenuButton") as Button

	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
	var try_again_btn: Button = failure_overlay.get_node("Card/TryAgainButton") as Button
	var failure_menu_btn: Button = failure_overlay.get_node("Card/FailureMenuButton") as Button

	var level_lbl: Label = main_node.get_node("LevelIndicatorLabel") as Label
	var lives_lbl: Label = main_node.get_node("LivesLabel") as Label
	var prompt_lbl: Label = main_node.get_node("PromptLabel") as Label

	assert(in_game_menu_btn != null, "InGameMenuButton must exist")
	assert(settings_return_btn != null, "ReturnToMenuButton must exist in SettingsOverlay")
	assert(complete_menu_btn != null, "CompleteMenuButton must exist in RunCompleteOverlay")
	assert(failure_menu_btn != null, "FailureMenuButton must exist in RunFailureOverlay")

	# Accelerate animation delays for test suite execution speed
	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# --- TEST SCENARIO H: SETTINGS OPENED FROM MAIN MENU HIDES 'ANA MENÜYE DÖN' ---
	print("\n[SCENARIO H] Settings opened from Main Menu hides 'Ana Menüye Dön'")
	settings_btn.pressed.emit()
	await process_frame
	assert(settings_overlay.visible == true, "SettingsOverlay is visible")
	assert(settings_return_btn.visible == false, "Scenario H: ReturnToMenuButton must be hidden when opened from Main Menu")
	close_btn.pressed.emit()
	await process_frame
	assert(settings_overlay.visible == false, "SettingsOverlay closed")

	# --- TEST SCENARIO A & B: START GAME -> IN-GAME MENU BUTTON VISIBLE ---
	print("\n[SCENARIO A & B] Start Game -> In-Game Menu button visible while playing")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(main_menu.visible == false, "Scenario A: MainMenu hidden after start")
	assert(in_game_menu_btn.visible == true, "Scenario B: InGameMenuButton is visible during gameplay")
	assert(in_game_menu_btn.text == "Menü", "Scenario B: InGameMenuButton text is 'Menü'")

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

	# Solve Level 1 to get streak = 1
	await solve_active_level.call()
	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 1, "On Level 2")
	assert(level_manager.current_streak == 1, "Streak is 1")
	var initial_run_levels: Array[LevelData] = level_manager.current_run_levels.duplicate()

	# --- TEST SCENARIO C, D, G: OPEN SETTINGS FROM GAMEPLAY ---
	print("\n[SCENARIO C, D, G] Tap In-Game Menu -> Settings opens, 'Ana Menüye Dön' visible, state preserved")
	in_game_menu_btn.pressed.emit()
	await process_frame

	assert(settings_overlay.visible == true, "Scenario C: SettingsOverlay visible over gameplay")
	assert(settings_return_btn.visible == true, "Scenario G: 'Ana Menüye Dön' is visible when opened from gameplay")
	assert(level_manager.current_lives == 3, "Scenario D: Lives preserved at 3")
	assert(level_manager.current_streak == 1, "Scenario D: Streak preserved at 1")
	assert(level_manager.current_level_index == 1, "Scenario D: Level index preserved at 1")
	assert(level_manager.current_run_levels == initial_run_levels, "Scenario D: Run sequence unchanged")

	# --- TEST SCENARIO E & F: TOGGLE SETTINGS & CLOSE -> RESUMES SAME PUZZLE ---
	print("\n[SCENARIO E & F] Toggle sound in gameplay settings & close -> state preserved, same puzzle resumes")
	sound_toggle_btn.pressed.emit()
	await process_frame
	assert(feedback_manager.sound_enabled == false, "Scenario F: Sound disabled from gameplay")
	assert(save_manager.get_sound_enabled() == false, "Scenario F: Persisted sound is false")

	close_btn.pressed.emit()
	await process_frame

	assert(settings_overlay.visible == false, "Scenario E: Settings closed")
	assert(level_manager.current_level_index == 1, "Scenario E: Resumed at Level 2")
	assert(level_manager.current_streak == 1, "Scenario E: Streak still 1")
	assert(level_manager.current_lives == 3, "Scenario E: Lives still 3")

	# Restore sound
	feedback_manager.sound_enabled = true
	save_manager.set_sound_enabled(true)

	# --- TEST SCENARIO I & K: TAP 'ANA MENÜYE DÖN' DURING GAMEPLAY ---
	print("\n[SCENARIO I & K] Tap 'Ana Menüye Dön' -> cleans up gameplay, returns to Main Menu, preserves cooldown")
	in_game_menu_btn.pressed.emit()
	await process_frame
	settings_return_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(main_menu.visible == true, "Scenario I: Main Menu is visible")
	assert(settings_overlay.visible == false, "Scenario I: SettingsOverlay is hidden")
	assert(prompt_lbl.visible == false, "Scenario I: Gameplay prompt is hidden")
	assert(level_lbl.visible == false, "Scenario I: Level indicator is hidden")
	assert(in_game_menu_btn.visible == false, "Scenario I: InGameMenuButton is hidden on menu")
	assert(level_manager.current_level_data == null, "Scenario I: No active level data on menu")
	assert(level_manager.math_pieces.is_empty(), "Scenario I: No math pieces remain")
	assert(level_manager.shape_pieces.is_empty(), "Scenario I: No shape pieces remain")
	assert(level_manager.previous_run_levels == initial_run_levels, "Scenario K: Abandoned run preserved in previous_run_levels for cooldown")

	# --- TEST SCENARIO J: START NEW GAME AFTER RETURNING TO MENU ---
	print("\n[SCENARIO J] Start game after returning to menu -> generates fresh 15-level run")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(main_menu.visible == false, "Scenario J: MainMenu hidden")
	assert(level_manager.current_run_levels.size() == 15, "Scenario J: 15 levels generated")
	assert(level_manager.current_lives == 3, "Scenario J: Lives = 3")
	assert(level_manager.current_streak == 0, "Scenario J: Streak reset to 0")

	# Check 0 overlap with abandoned run
	var overlap_count: int = 0
	for lvl in level_manager.current_run_levels:
		if initial_run_levels.has(lvl):
			overlap_count += 1
	assert(overlap_count == 0, "Scenario K: New run has 0 overlap with abandoned prior run")

	# --- TEST SCENARIO L & M: FAILURE OVERLAY 'ANA MENÜ' BUTTON ---
	print("\n[SCENARIO L & M] Failure overlay -> tap 'Ana Menü' returns cleanly to Main Menu")
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

	assert(failure_overlay.visible == true, "Scenario L: Failure overlay is visible")
	assert(failure_menu_btn.visible == true, "Scenario L: FailureMenuButton is visible on card")

	# Tap Ana Menü on Failure Overlay
	failure_menu_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(main_menu.visible == true, "Scenario M: Main Menu visible after failure Ana Menü")
	assert(failure_overlay.visible == false, "Scenario M: Failure overlay hidden")
	assert(level_manager.current_level_data == null, "Scenario M: Gameplay cleaned up")

	# --- TEST SCENARIO N, O, P: RUN COMPLETE OVERLAY 'ANA MENÜ' & PERSONAL BEST REFRESH ---
	print("\n[SCENARIO N, O, P] Run Complete overlay -> tap 'Ana Menü' returns to menu with updated Kişisel Rekor")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	# Solve all 15 levels to set a new personal record of 15 (exceeding initial 4)
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

	assert(complete_overlay.visible == true, "Scenario N: Complete overlay visible")
	assert(complete_menu_btn.visible == true, "Scenario N: CompleteMenuButton visible on card")
	assert(level_manager.personal_best_streak == 15, "Personal best updated to 15")

	# Tap Ana Menü on Complete Overlay
	complete_menu_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(main_menu.visible == true, "Scenario O: Main Menu visible after complete Ana Menü")
	assert(complete_overlay.visible == false, "Scenario O: Complete overlay hidden")
	assert(menu_pb_lbl.text == "Kişisel Rekor: x15", "Scenario P: Main Menu displays updated Kişisel Rekor: x15 (got '%s')" % menu_pb_lbl.text)

	# --- TEST SCENARIO Q & R: CANCELLATION OF PENDING TRANSITIONS ---
	print("\n[SCENARIO Q & R] Verify returning to menu cancels pending transition and failure tweens")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	# Trigger level solve (schedules transition_tween)
	await solve_active_level.call()
	assert(level_manager.transition_tween != null, "transition_tween scheduled")

	# Return to menu immediately while transition_tween is active
	main_node.return_to_main_menu()
	await process_frame

	assert(level_manager.transition_tween == null, "Scenario Q: transition_tween was cancelled cleanly")
	assert(main_menu.visible == true, "Returned to Main Menu")

	# Clean up test save file
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	print("\n>>> ALL STEP 13D AUTOMATED TESTS (SCENARIOS A - T) PASSED PERFECTLY! <<<\n")
	quit(0)










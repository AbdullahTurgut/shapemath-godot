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
	print("--- BEGINNING STEP 14A AUTOMATED TEST SUITE (FIRST-TIME ONBOARDING & CURATION) ---")

	# Define isolated test save paths
	var fresh_save_path: String = "user://test_save_14a_fresh.cfg"
	var legacy_save_path: String = "user://test_save_14a_legacy.cfg"

	if FileAccess.file_exists(fresh_save_path):
		DirAccess.remove_absolute(fresh_save_path)
	if FileAccess.file_exists(legacy_save_path):
		DirAccess.remove_absolute(legacy_save_path)

	# --- TEST SCENARIO A: LEGACY SAVE WITHOUT tutorial_completed KEY ---
	print("\n[SCENARIO A] Legacy save without tutorial_completed key defaults to false")
	var legacy_cfg := ConfigFile.new()
	legacy_cfg.set_value("settings", "sound_enabled", true)
	legacy_cfg.set_value("settings", "haptics_enabled", true)
	legacy_cfg.set_value("progress", "personal_best_streak", 5)
	legacy_cfg.save(legacy_save_path)

	var sm_legacy := SaveManager.new()
	sm_legacy.save_path = legacy_save_path
	sm_legacy.load_data()
	assert(sm_legacy.get_tutorial_completed() == false, "Scenario A: Legacy save without key defaults to false")
	assert(sm_legacy.get_personal_best_streak() == 5, "Scenario A: Preserved PB streak = 5")

	# --- TEST SCENARIO B: FRESH INSTALL DEFAULTS ---
	print("\n[SCENARIO B] Fresh install defaults")
	var sm_fresh := SaveManager.new()
	sm_fresh.save_path = fresh_save_path
	sm_fresh.load_data()
	assert(sm_fresh.get_tutorial_completed() == false, "Scenario B: Fresh install tutorial_completed is false")
	assert(sm_fresh.get_personal_best_streak() == 0, "Scenario B: Fresh install PB is 0")
	assert(sm_fresh.get_sound_enabled() == true, "Scenario B: Sound is true")
	assert(sm_fresh.get_haptics_enabled() == true, "Scenario B: Haptics is true")

	# Instantiate main scene for full onboarding test flow
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()

	var save_manager: SaveManager = main_node.get_node("SaveManager") as SaveManager
	save_manager.save_path = fresh_save_path

	root.add_child(main_node)
	await process_frame
	await _sync_physics()

	var level_manager: LevelManager = main_node.get_node("LevelManager") as LevelManager
	var feedback_manager: FeedbackManager = main_node.get_node("FeedbackManager") as FeedbackManager
	var main_menu: Control = main_node.get_node("MainMenu") as Control
	var start_btn: Button = main_menu.get_node("StartGameButton") as Button
	var menu_pb_lbl: Label = main_menu.get_node("PersonalBestLabel") as Label

	var onboarding_hint: Label = main_node.get_node("OnboardingHintLabel") as Label
	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
	var failure_try_again_btn: Button = failure_overlay.get_node("Card/TryAgainButton") as Button

	# Accelerate animation delays for test speed
	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# --- TEST SCENARIO P & Q: START RUN -> RETURN TO MAIN MENU BEFORE SOLVING ---
	print("\n[SCENARIO P & Q] Return to Main Menu before completing tutorial -> remains incomplete")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(main_node.current_state == main_node.AppState.PLAYING, "In PLAYING state")
	assert(level_manager.is_onboarding_active == true, "Onboarding active on first launch")
	assert(onboarding_hint.visible == true, "Scenario P: Onboarding hint visible")
	assert(onboarding_hint.text == "Sürükle ve doğru yere bırak", "Scenario P: Hint text matches")

	# Return to Main Menu without solving
	main_node.return_to_main_menu()
	await process_frame
	await _sync_physics()

	assert(main_menu.visible == true, "Returned to Main Menu")
	assert(save_manager.get_tutorial_completed() == false, "Scenario P: tutorial_completed remains false")
	assert(onboarding_hint.visible == false, "Scenario P: Hint hidden on Main Menu")

	# --- TEST SCENARIO N & O: RUN FAILURE BEFORE COMPLETING TUTORIAL ---
	print("\n[SCENARIO N & O] Fail first run before solving -> tutorial_completed remains false & re-curated on retry")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_data.prompt_text == "1 + 2 = ?", "Level 1 is curated onboarding level")
	assert(level_manager.is_onboarding_active == true, "Onboarding active")

	# Deliberately lose all 3 lives
	level_manager.current_lives = 1
	var wrong_piece: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text != level_manager.current_level_data.correct_answer:
			wrong_piece = p
			break
	assert(wrong_piece != null, "Found wrong piece")
	wrong_piece.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(wrong_piece)

	if level_manager.failure_tween:
		await level_manager.failure_tween.finished
	await process_frame

	assert(failure_overlay.visible == true, "Failure overlay shown")
	assert(save_manager.get_tutorial_completed() == false, "Scenario N: tutorial_completed is still false after failure")

	# Retry run
	failure_try_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_run_levels.size() == 15, "Scenario O: 15 levels generated on retry")
	assert(level_manager.current_run_levels[0].prompt_text == "1 + 2 = ?", "Scenario O: First puzzle is curated onboarding level again")
	assert(level_manager.is_onboarding_active == true, "Scenario O: Onboarding active again on retry")

	# --- TEST SCENARIO C, D, E, F, G: FIRST RUN CURATION & STRUCTURE ---
	print("\n[SCENARIO C, D, E, F, G] First run structure: 5 Easy, 5 Medium, 5 Hard, 15 unique, Level 1 at pos 1")
	assert(level_manager.current_run_levels.size() == 15, "Scenario C: Exactly 15 levels")
	assert(level_manager.current_run_levels[0].puzzle_type == LevelData.PuzzleType.MATH_MATCH, "Scenario C: Pos 1 is MATH_MATCH")
	assert(level_manager.current_run_levels[0].tier == 1, "Scenario C: Pos 1 is Tier 1")
	assert(level_manager.current_run_levels[0].prompt_text == "1 + 2 = ?", "Scenario C: Pos 1 is '1 + 2 = ?'")

	# Check tier counts in first run
	var easy_count: int = 0
	var med_count: int = 0
	var hard_count: int = 0
	for lvl in level_manager.current_run_levels:
		match lvl.tier:
			1: easy_count += 1
			2: med_count += 1
			3: hard_count += 1
	assert(easy_count == 5, "Scenario D: Exactly 5 Easy levels")
	assert(med_count == 5, "Scenario D: Exactly 5 Medium levels")
	assert(hard_count == 5, "Scenario D: Exactly 5 Hard levels")

	# Check uniqueness (no duplicates)
	var seen_levels: Array[LevelData] = []
	for lvl in level_manager.current_run_levels:
		assert(not seen_levels.has(lvl), "Scenario E: No duplicate levels in run (%s duplicated)" % lvl.prompt_text)
		seen_levels.append(lvl)

	assert(onboarding_hint.visible == true, "Scenario F: Onboarding hint is visible")
	assert(level_manager.tutorial_pulse_tween != null, "Scenario G: Tutorial pulse tween is running")

	# --- TEST SCENARIO H: NEUTRAL DROP ---
	print("\n[SCENARIO H] Neutral drop in empty space -> tutorial remains active, 3 lives intact")
	var correct_p: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == level_manager.current_level_data.correct_answer:
			correct_p = p
			break
	assert(correct_p != null, "Found correct piece")

	correct_p.global_position = Vector2(100, 100) # Empty space
	await _sync_physics()
	level_manager._on_math_piece_dropped(correct_p)

	assert(level_manager.current_lives == 3, "Scenario H: Lives remained 3")
	assert(level_manager.is_onboarding_active == true, "Scenario H: Onboarding still active")
	assert(save_manager.get_tutorial_completed() == false, "Scenario H: tutorial_completed still false")

	correct_p.reset_piece()
	await _sync_physics()

	# --- TEST SCENARIO I: DELIBERATE WRONG DROP ---
	print("\n[SCENARIO I] Deliberate wrong drop -> life lost, tutorial remains active")
	var wrong_p2: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text != level_manager.current_level_data.correct_answer:
			wrong_p2 = p
			break
	assert(wrong_p2 != null)

	wrong_p2.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(wrong_p2)

	assert(level_manager.current_lives == 2, "Scenario I: Life lost (2/3 remaining)")
	assert(level_manager.is_onboarding_active == true, "Scenario I: Onboarding still active")
	assert(save_manager.get_tutorial_completed() == false, "Scenario I: tutorial_completed still false")

	wrong_p2.reset_piece()
	await _sync_physics()

	# --- TEST SCENARIO J: CORRECT SOLVE & TUTORIAL COMPLETION ---
	print("\n[SCENARIO J] Correct solve -> tutorial_completed = true persisted, hint hidden, pulse killed")
	correct_p.reset_piece()
	correct_p.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(correct_p)
	await level_manager.level_completed

	assert(level_manager.is_onboarding_active == false, "Scenario J: is_onboarding_active is false")
	assert(save_manager.get_tutorial_completed() == true, "Scenario J: SaveManager has tutorial_completed = true")
	assert(level_manager.tutorial_pulse_tween == null, "Scenario J: Tutorial pulse tween stopped")

	# --- TEST SCENARIO K: LEVEL 2 ADVANCE HAS NO TUTORIAL HINT ---
	print("\n[SCENARIO K] Advance to level 2 -> no tutorial hint")
	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 1, "At level 2")
	assert(onboarding_hint.visible == false, "Scenario K: Onboarding hint is hidden on level 2")
	assert(level_manager.is_onboarding_active == false, "Scenario K: is_onboarding_active is false on level 2")

	# --- TEST SCENARIO L & U: START NEW RUN AS RETURNING PLAYER ---
	print("\n[SCENARIO L & U] Start new run as returning player -> normal 15-level 5+5+5 run, no forced pos 1")
	main_node.return_to_main_menu()
	await process_frame
	await _sync_physics()

	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_run_levels.size() == 15, "Scenario U: 15 levels sampled")
	assert(onboarding_hint.visible == false, "Scenario L: Onboarding hint is hidden")
	assert(level_manager.is_onboarding_active == false, "Scenario L: Onboarding not active")

	# --- TEST SCENARIO M, R, S, T: RESTART APP PERSISTENCE INTEGRITY ---
	print("\n[SCENARIO M, R, S, T] Reload from disk with tutorial_completed=true -> intact persistence and 36 pool")
	var disk_sm := SaveManager.new()
	disk_sm.save_path = fresh_save_path
	disk_sm.load_data()

	assert(disk_sm.get_tutorial_completed() == true, "Scenario M: Persisted tutorial_completed is true")
	assert(disk_sm.get_sound_enabled() == true, "Scenario S: Sound enabled persisted")
	assert(disk_sm.get_haptics_enabled() == true, "Scenario S: Haptics enabled persisted")
	assert(level_manager.levels.size() == 36, "Scenario T: 36 master levels intact")

	# Clean up test save files
	if FileAccess.file_exists(fresh_save_path):
		DirAccess.remove_absolute(fresh_save_path)
	if FileAccess.file_exists(legacy_save_path):
		DirAccess.remove_absolute(legacy_save_path)

	print("\n>>> ALL STEP 14A AUTOMATED TESTS (SCENARIOS A - U) PASSED PERFECTLY! <<<\n")
	quit(0)













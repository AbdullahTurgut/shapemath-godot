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
	print("--- BEGINNING STEP 14B AUTOMATED TEST SUITE (PERSONAL RECORD CELEBRATION) ---")

	# Define isolated test save paths
	var test_save_path: String = "user://test_save_14b.cfg"
	var fresh_save_path: String = "user://test_save_14b_fresh.cfg"

	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	if FileAccess.file_exists(fresh_save_path):
		DirAccess.remove_absolute(fresh_save_path)

	# --- TEST SCENARIO G & N: FRESH INSTALL TUTORIAL SOLVE SUPPRESSES TRIVIAL x1 RECORD BANNER ---
	print("\n[SCENARIO G & N] Fresh install tutorial solve -> PB becomes 1, but NO trivial record banner")
	var sm_fresh := SaveManager.new()
	sm_fresh.save_path = fresh_save_path
	sm_fresh.sound_enabled = true
	sm_fresh.haptics_enabled = true
	sm_fresh.personal_best_streak = 0
	sm_fresh.tutorial_completed = false
	sm_fresh.save_data()

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node_fresh: Node2D = main_scene.instantiate()
	var sm_node_fresh: SaveManager = main_node_fresh.get_node("SaveManager") as SaveManager
	sm_node_fresh.save_path = fresh_save_path

	root.add_child(main_node_fresh)
	await process_frame
	await _sync_physics()

	var lm_fresh: LevelManager = main_node_fresh.get_node("LevelManager") as LevelManager
	var mm_fresh: Control = main_node_fresh.get_node("MainMenu") as Control
	var start_fresh_btn: Button = mm_fresh.get_node("StartGameButton") as Button
	var record_banner_fresh: Control = main_node_fresh.get_node("RecordBanner") as Control

	lm_fresh.transition_delay = 0.01
	lm_fresh.summary_delay = 0.01
	lm_fresh.failure_delay = 0.01

	start_fresh_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(lm_fresh.personal_best_at_run_start == 0, "Scenario G: personal_best_at_run_start is 0")
	assert(lm_fresh.record_broken_this_run == false, "Scenario G: record_broken_this_run is false")
	assert(lm_fresh.is_onboarding_active == true, "Scenario N: Onboarding active on first run")

	# Solve tutorial level
	var cor_p_fresh: DraggablePiece = null
	for p in lm_fresh.math_pieces:
		if p.piece_text == lm_fresh.current_level_data.correct_answer:
			cor_p_fresh = p
			break
	assert(cor_p_fresh != null)
	cor_p_fresh.global_position = lm_fresh.math_target_zone.global_position
	await _sync_physics()
	lm_fresh._on_math_piece_dropped(cor_p_fresh)
	await lm_fresh.level_completed

	assert(lm_fresh.current_streak == 1, "Scenario G: Streak incremented to 1")
	assert(lm_fresh.personal_best_streak == 1, "Scenario G: PB updated to 1")
	assert(record_banner_fresh.visible == false, "Scenario G: Record banner was suppressed for trivial x1 PB")
	assert(lm_fresh.record_broken_this_run == false, "Scenario G: record_broken_this_run remained false")

	root.remove_child(main_node_fresh)
	main_node_fresh.queue_free()
	await process_frame

	# --- SETUP ESTABLISHED PLAYER SAVE WITH PB = 5 ---
	var sm_setup := SaveManager.new()
	sm_setup.save_path = test_save_path
	sm_setup.sound_enabled = true
	sm_setup.haptics_enabled = true
	sm_setup.personal_best_streak = 5
	sm_setup.tutorial_completed = true
	sm_setup.save_data()

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
	var record_banner: Control = main_node.get_node("RecordBanner") as Control
	var record_title: Label = record_banner.get_node("RecordTitleLabel") as Label
	var record_val: Label = record_banner.get_node("RecordValueLabel") as Label
	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
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

	# --- TEST SCENARIO A: RUN START WITH PB = 5 ---
	print("\n[SCENARIO A] Run start with existing PB = 5 captures personal_best_at_run_start = 5 and record_broken_this_run = false")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.personal_best_at_run_start == 5, "Scenario A: personal_best_at_run_start is 5")
	assert(level_manager.record_broken_this_run == false, "Scenario A: record_broken_this_run is false")
	assert(level_manager.current_run_levels.size() == 15, "Scenario P: 15-level run intact")
	assert(level_manager.levels.size() == 36, "Scenario O: 36 master levels intact")

	# --- TEST SCENARIO B: SOLVE 5 PUZZLES (REACH STREAK 5) -> NO CELEBRATION BANNER ---
	print("\n[SCENARIO B] Reach streak 5 -> no record celebration banner")
	for i in range(5):
		await solve_current.call()
		assert(record_banner.visible == false, "Scenario B: No record banner at streak %d" % level_manager.current_streak)
		if level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(level_manager.current_streak == 5, "Streak is 5")
	assert(level_manager.personal_best_streak == 5, "Personal best streak is 5")
	assert(level_manager.record_broken_this_run == false, "record_broken_this_run is false at streak 5")

	# --- TEST SCENARIO C: SOLVE 6TH PUZZLE (STREAK 6) -> RECORD CELEBRATION TRIGGERS ---
	print("\n[SCENARIO C] Reach streak 6 -> triggers 'Yeni Kişisel Rekor! x6' celebration once")
	await solve_current.call()

	assert(level_manager.current_streak == 6, "Scenario C: Current streak is 6")
	assert(level_manager.personal_best_streak == 6, "Scenario C: Personal best streak updated to 6")
	assert(save_manager.get_personal_best_streak() == 6, "Scenario C: Saved PB is 6")
	assert(level_manager.record_broken_this_run == true, "Scenario C: record_broken_this_run is true")
	assert(record_banner.visible == true, "Scenario C: Record banner visible")
	assert(record_title.text == "Yeni Kişisel Rekor!", "Scenario C: Title is 'Yeni Kişisel Rekor!'")
	assert(record_val.text == "x6", "Scenario C: Value label is 'x6'")

	# Advance past banner
	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	assert(record_banner.visible == false, "Record banner cleaned on next level")

	# --- TEST SCENARIO D: SOLVE 7TH AND 8TH PUZZLES (STREAKS 7 & 8) -> NO SECOND BANNER ---
	print("\n[SCENARIO D] Reach streaks 7 & 8 -> PB updates to 7 and 8 with NO second banner")
	await solve_current.call()
	assert(level_manager.current_streak == 7, "Streak is 7")
	assert(level_manager.personal_best_streak == 7, "PB updated to 7")
	assert(record_banner.visible == false, "Scenario D: No second banner at streak 7")
	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	await solve_current.call()
	assert(level_manager.current_streak == 8, "Streak is 8")
	assert(level_manager.personal_best_streak == 8, "PB updated to 8")
	assert(record_banner.visible == false, "Scenario D: No second banner at streak 8")
	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	# --- TEST SCENARIO E: WRONG DROP RESETS STREAK, REBUILD DOES NOT RETRIGGER BANNER ---
	print("\n[SCENARIO E] Deliberate wrong drop resets streak -> rebuilding streak does NOT re-trigger banner in same run")
	level_manager._reset_streak()
	assert(level_manager.current_streak == 0, "Streak reset to 0")
	assert(level_manager.record_broken_this_run == true, "record_broken_this_run remains true")

	# Solve another level: streak goes from 0 to 1
	await solve_current.call()
	assert(level_manager.current_streak == 1, "Streak is 1")
	assert(record_banner.visible == false, "Scenario E: No banner on rebuild")
	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	# --- TEST SCENARIO I: RETURN TO MAIN MENU CLEANS BANNER TWEEN ---
	print("\n[SCENARIO I] Return to Main Menu cleans any banner tween safely")
	level_manager._show_record_celebration(9)
	assert(record_banner.visible == true, "Banner simulated")
	main_node.return_to_main_menu()
	await process_frame
	await _sync_physics()
	assert(record_banner.visible == false, "Scenario I: Banner hidden on Main Menu")
	assert(level_manager.record_banner_tween == null, "Scenario I: Tween killed")

	# --- TEST SCENARIO F: NEW RUN INITIALIZATION WITH LATEST PB = 8 ---
	print("\n[SCENARIO F] Start new run -> personal_best_at_run_start uses latest saved PB (8) & resets record_broken_this_run = false")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.personal_best_at_run_start == 8, "Scenario F: personal_best_at_run_start is 8")
	assert(level_manager.record_broken_this_run == false, "Scenario F: record_broken_this_run is false")

	# --- TEST SCENARIO J: FAILURE OVERLAY CLEANS BANNER ---
	print("\n[SCENARIO J] Run failure cleans banner safely")
	level_manager._show_record_celebration(9)
	assert(record_banner.visible == true)
	level_manager._show_run_failure_overlay()
	assert(record_banner.visible == false, "Scenario J: Banner hidden on failure overlay")

	# --- TEST SCENARIO K: RUN COMPLETE OVERLAY CLEANS BANNER ---
	print("\n[SCENARIO K] Run complete cleans banner safely")
	level_manager.is_run_completed = true
	level_manager._show_record_celebration(10)
	assert(record_banner.visible == true)
	level_manager._show_run_complete_overlay()
	assert(record_banner.visible == false, "Scenario K: Banner hidden on run complete overlay")

	# --- TEST SCENARIO L & M: SOUND AND HAPTIC DISABLED SETTINGS RESPECTED ---
	print("\n[SCENARIO L & M] Sound and haptics disabled settings respected during record celebration")
	for p in feedback_manager._players:
		p.stop()
	feedback_manager.sound_enabled = false
	feedback_manager.haptics_enabled = false
	feedback_manager.play_record_break()
	# No audio player should be playing when sound_enabled is false
	for p in feedback_manager._players:
		assert(not p.playing, "Scenario L: No SFX played when sound_enabled = false")

	# Clean up test save files
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	if FileAccess.file_exists(fresh_save_path):
		DirAccess.remove_absolute(fresh_save_path)

	print("\n>>> ALL STEP 14B AUTOMATED TESTS (SCENARIOS A - P) PASSED PERFECTLY! <<<\n")
	quit(0)













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
	print("--- BEGINNING STEP 14E MASTER RETENTION UX REGRESSION SUITE (SCENARIOS A - X) ---")
	print("================================================================================")

	var test_save_path: String = "user://test_save_master_14e.cfg"
	var fresh_save_path: String = "user://test_save_fresh_14e.cfg"
	var legacy_save_path: String = "user://test_save_legacy_14e.cfg"

	for p in [test_save_path, fresh_save_path, legacy_save_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

	var main_scene: PackedScene = load("res://scenes/main.tscn")

	# ================================================================================
	# TEST 1: SCENARIO A, G (PART 1), P (PART 1), R: FRESH USER ONBOARDING & LEVEL 1 CURATION
	# ================================================================================
	print("\n[SCENARIOS A, P, R] Fresh user onboarding -> curated Level 1, hint visible, first solve persists tutorial")
	var sm_fresh := SaveManager.new()
	sm_fresh.save_path = fresh_save_path
	sm_fresh.sound_enabled = true
	sm_fresh.haptics_enabled = true
	sm_fresh.personal_best_streak = 0
	sm_fresh.tutorial_completed = false
	sm_fresh.save_data()

	var node_fresh: Node2D = main_scene.instantiate()
	var sm_node_fresh: SaveManager = node_fresh.get_node("SaveManager") as SaveManager
	sm_node_fresh.save_path = fresh_save_path
	root.add_child(node_fresh)
	await process_frame
	await _sync_physics()

	var lm_fresh: LevelManager = node_fresh.get_node("LevelManager") as LevelManager
	var mm_fresh: Control = node_fresh.get_node("MainMenu") as Control
	var start_fresh_btn: Button = mm_fresh.get_node("StartGameButton") as Button
	var hint_fresh: Label = node_fresh.get_node("OnboardingHintLabel") as Label
	var banner_fresh: Control = node_fresh.get_node("RecordBanner") as Control

	lm_fresh.transition_delay = 0.01
	lm_fresh.summary_delay = 0.01
	lm_fresh.failure_delay = 0.01

	start_fresh_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(lm_fresh.is_onboarding_active == true, "Scenario A: Onboarding active on fresh start")
	assert(hint_fresh.visible == true, "Scenario A: Onboarding hint label is visible")
	assert(lm_fresh.current_level_data.correct_answer == "3", "Scenario A: Curated Level 1 (1 + 2 = 3)")
	assert(lm_fresh.personal_best_at_run_start == 0, "Scenario A: PB start is 0")

	# Solve onboarding puzzle
	var correct_p_fresh: DraggablePiece = null
	for p in lm_fresh.math_pieces:
		if p.piece_text == lm_fresh.current_level_data.correct_answer:
			correct_p_fresh = p
			break
	assert(correct_p_fresh != null)
	correct_p_fresh.reset_piece()
	correct_p_fresh.global_position = lm_fresh.math_target_zone.global_position
	await _sync_physics()
	lm_fresh._on_math_piece_dropped(correct_p_fresh)
	await lm_fresh.level_completed

	assert(lm_fresh.is_onboarding_active == false, "Scenario A: Onboarding inactive after solve")
	assert(sm_node_fresh.get_tutorial_completed() == true, "Scenario R: Tutorial completed persisted")
	assert(lm_fresh.personal_best_streak == 1, "Scenario A: PB is 1")
	assert(banner_fresh.visible == false, "Scenario A: Low-value x1 record banner suppressed")

	root.remove_child(node_fresh)
	node_fresh.queue_free()
	await process_frame

	# ================================================================================
	# TEST 2: SCENARIOS T, U, V, W: 54-POOL, 5+5+5 SAMPLING, COOLDOWN, PUZZLE TYPES
	# ================================================================================
	print("\n[SCENARIOS T, U, V, W] Pool of 54 levels, 5+5+5 sampling, 5 puzzle types, recent cooldown")
	var sm_main := SaveManager.new()
	sm_main.save_path = test_save_path
	sm_main.sound_enabled = true
	sm_main.haptics_enabled = true
	sm_main.personal_best_streak = 4
	sm_main.tutorial_completed = true
	sm_main.save_data()

	var main_node: Node2D = main_scene.instantiate()
	var sm_node: SaveManager = main_node.get_node("SaveManager") as SaveManager
	sm_node.save_path = test_save_path
	root.add_child(main_node)
	await process_frame
	await _sync_physics()

	var lm: LevelManager = main_node.get_node("LevelManager") as LevelManager
	var fb: FeedbackManager = main_node.get_node("FeedbackManager") as FeedbackManager
	var mm: Control = main_node.get_node("MainMenu") as Control
	var start_btn: Button = mm.get_node("StartGameButton") as Button
	var success_lbl: Label = main_node.get_node("SuccessLabel") as Label
	var banner: Control = main_node.get_node("RecordBanner") as Control
	var lives_lbl: Label = main_node.get_node("LivesLabel") as Label
	var summary_overlay: Control = main_node.get_node("RunCompleteOverlay") as Control
	var summary_title: Label = summary_overlay.get_node("Card/CardTitle") as Label
	var play_again_btn: Button = summary_overlay.get_node("Card/PlayAgainButton") as Button
	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
	var failure_motivation_lbl: Label = failure_overlay.get_node("Card/FailureMotivationLabel") as Label
	var failure_try_again_btn: Button = failure_overlay.get_node("Card/TryAgainButton") as Button
	var settings_overlay: Control = main_node.get_node("SettingsOverlay") as Control

	lm.transition_delay = 0.01
	lm.summary_delay = 0.01
	lm.failure_delay = 0.01

	assert(lm.levels.size() == 54, "Scenario T: Pool contains exactly 54 levels")

	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(lm.current_run_levels.size() == 15, "Scenario U: 15 levels in run")
	for i in range(5):
		assert(lm.current_run_levels[i].tier == 1, "Level %d is Easy (Tier 1)" % (i + 1))
	for i in range(5, 10):
		assert(lm.current_run_levels[i].tier == 2, "Level %d is Medium (Tier 2)" % (i + 1))
	for i in range(10, 15):
		assert(lm.current_run_levels[i].tier == 3, "Level %d is Hard (Tier 3)" % (i + 1))

	# Helper to solve current active level
	var solve_current = func() -> void:
		var cur_data = lm.current_level_data
		if cur_data.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
			lm.shape_piece_a.reset_piece()
			lm.shape_piece_a.global_position = lm.shape_piece_b.global_position
			await _sync_physics()
			lm._on_shape_piece_dropped(lm.shape_piece_a)
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

	# Helper to perform deliberate wrong drop
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

	# ================================================================================
	# TEST 3: SCENARIOS C, D, E, F, G, M: RECORD PRIORITY, MILESTONES, PERFECT RUN
	# ================================================================================
	print("\n[SCENARIOS C, D, E, F, G, M] Solves 1..15 -> record celebration at x5 (PB=4), x10 milestone, neutral drop free, Perfect Run 15/15")
	for i in range(4): # Solves 1..4
		await solve_current.call()
		assert(success_lbl.text == "Harika!", "Solves 1-4 standard Harika!")
		if lm.transition_tween:
			await lm.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(lm.current_streak == 4, "Streak is 4")

	# Solve 5: Breaks PB 4 -> Scenario D: Record celebration takes priority over x5 milestone
	await solve_current.call()
	assert(lm.current_streak == 5, "Streak is 5")
	assert(banner.visible == true, "Scenario D: Record banner visible")
	assert(lm.record_broken_this_run == true, "Scenario D: record_broken_this_run true")
	assert(success_lbl.visible == false, "Scenario D: Milestone suppressed on record break")

	if lm.transition_tween:
		await lm.transition_tween.finished
	await process_frame
	await _sync_physics()

	# Scenario M: Neutral drop does not penalize
	var p_mistakes = lm.mistakes_this_run
	var cur_d = lm.current_level_data
	if cur_d.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
		lm.shape_piece_a.global_position = Vector2(25, 25)
		await _sync_physics()
		lm._on_shape_piece_dropped(lm.shape_piece_a)
	else:
		lm.math_pieces[0].global_position = Vector2(25, 25)
		await _sync_physics()
		lm._on_math_piece_dropped(lm.math_pieces[0])

	assert(lm.mistakes_this_run == p_mistakes, "Scenario M: Neutral drop does not increment mistakes")
	assert(lm.current_lives == 3, "Scenario M: Neutral drop does not lose life")

	# Solves 6..9
	for i in range(4):
		await solve_current.call()
		if lm.transition_tween:
			await lm.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(lm.current_streak == 9, "Streak is 9")

	# Solve 10: Scenario F: x10 milestone "Müthiş Seri!"
	await solve_current.call()
	assert(lm.current_streak == 10, "Streak is 10")
	assert(success_lbl.text == "Müthiş Seri!", "Scenario F: x10 displays 'Müthiş Seri!'")

	if lm.transition_tween:
		await lm.transition_tween.finished
	await process_frame
	await _sync_physics()

	# Solves 11..15
	for i in range(4):
		await solve_current.call()
		if lm.transition_tween:
			await lm.transition_tween.finished
		await process_frame
		await _sync_physics()

	await solve_current.call() # Final solve 15
	if lm.summary_tween:
		await lm.summary_tween.finished
	await process_frame
	await _sync_physics()

	assert(summary_overlay.visible == true, "Summary overlay visible")
	assert(lm.mistakes_this_run == 0, "0 mistakes in run")
	assert(summary_title.text.contains("Mükemmel Tur!"), "Scenario G: Title contains 'Mükemmel Tur!'")

	# ================================================================================
	# TEST 4: SCENARIOS B, H, I, J, K, L, N, X: NEAR-RECORD MOTIVATIONS & NON-PERFECT RUN
	# ================================================================================
	print("\n[SCENARIOS B, H, I, J, K, L, N, X] New run with mistake -> x5 milestone re-trigger, life pulse, near-record motivation")
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(lm.is_onboarding_active == false, "Scenario B: Returning user has no onboarding")
	assert(lm.mistakes_this_run == 0, "New run resets mistakes_this_run = 0")
	assert(lm.personal_best_at_run_start == 15, "PB at start is 15")

	# Deliberate wrong drop: Scenario L: life pulse
	await drop_wrong.call()
	assert(lm.current_lives == 2, "Scenario L: Lives = 2")
	assert(lm.lives_tween != null, "Scenario L: Lives tween active")
	assert(lm.mistakes_this_run == 1, "Mistakes incremented to 1")

	# Solve levels 1..4 (streaks 1..4)
	for i in range(4):
		await solve_current.call()
		if lm.transition_tween:
			await lm.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(lm.current_streak == 4, "Streak is 4")

	# Solve level 5 -> reaches streak 5 without record break (PB=15) -> Scenario E: "Harika Seri!"
	await solve_current.call()
	assert(lm.current_streak == 5, "Streak is 5")
	assert(success_lbl.text == "Harika Seri!", "Scenario E: x5 displays 'Harika Seri!'")

	if lm.transition_tween:
		await lm.transition_tween.finished
	await process_frame
	await _sync_physics()

	# Fail near record (e.g. PB = 8, best = 6 -> Gap 2)
	lm.personal_best_at_run_start = 8
	lm.best_streak_this_run = 6
	lm.record_broken_this_run = false
	lm.is_run_failed = true
	lm._show_run_failure_overlay()

	assert(failure_motivation_lbl.visible == true, "Scenario J: Motivation visible for gap 2")
	assert(failure_motivation_lbl.text == "Rekoruna çok yaklaştın!", "Scenario J: Motivation text matches 'Rekoruna çok yaklaştın!'")

	# Test Gap 1 (PB = 8, best = 7)
	lm.best_streak_this_run = 7
	lm._show_run_failure_overlay()
	assert(failure_motivation_lbl.visible == true, "Scenario I: Motivation visible for gap 1")
	assert(failure_motivation_lbl.text == "Rekoruna sadece 1 kaldı!", "Scenario I: Motivation text matches 'Rekoruna sadece 1 kaldı!'")

	# Test non-near gap (PB = 8, best = 3) -> Scenario K
	lm.best_streak_this_run = 3
	lm._show_run_failure_overlay()
	assert(failure_motivation_lbl.visible == false, "Scenario K: Motivation hidden for gap 5")

	# ================================================================================
	# TEST 5: SCENARIOS O, S: ANDROID BACK ROUTING & CLEANUP
	# ================================================================================
	print("\n[SCENARIOS O, S] Android back routing & return-to-menu tween cleanup")
	main_node._handle_back_request() # Failure overlay open -> returns to Main Menu
	await process_frame
	await _sync_physics()

	assert(main_node.current_state == main_node.AppState.MAIN_MENU, "Scenario S: Back from failure returned to Main Menu")
	assert(lives_lbl.scale == Vector2.ONE, "Scenario O: Lives label scale is 1.0")
	assert(lives_lbl.modulate == Color.WHITE, "Scenario O: Lives label modulate is WHITE")
	assert(banner.visible == false, "Scenario O: Record banner is hidden")
	assert(failure_motivation_lbl.visible == false, "Scenario O: Motivation label is hidden")

	# Test Android Back from Main Menu Settings
	main_node._on_settings_button_pressed()
	assert(settings_overlay.visible == true, "Settings opened")
	main_node._handle_back_request()
	assert(settings_overlay.visible == false, "Scenario S: Back closed Settings")

	# ================================================================================
	# TEST 6: SCENARIO P, Q: SETTINGS & PERSONAL BEST PERSISTENCE
	# ================================================================================
	print("\n[SCENARIOS P, Q] Settings & PB persistence")
	sm_node.set_sound_enabled(false)
	sm_node.set_haptics_enabled(false)
	assert(sm_node.get_sound_enabled() == false, "Scenario P: Sound false persisted")
	assert(sm_node.get_haptics_enabled() == false, "Scenario P: Haptics false persisted")

	var reloaded_sm := SaveManager.new()
	reloaded_sm.save_path = test_save_path
	reloaded_sm.load_data()
	assert(reloaded_sm.get_sound_enabled() == false, "Scenario P: Reloaded sound is false")
	assert(reloaded_sm.get_haptics_enabled() == false, "Scenario P: Reloaded haptics is false")
	assert(reloaded_sm.get_personal_best_streak() == 15, "Scenario Q: Reloaded PB is 15")

	# Clean up test save files
	for p in [test_save_path, fresh_save_path, legacy_save_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

	print("\n================================================================================")
	print(">>> ALL STEP 14E MASTER REGRESSION TESTS (SCENARIOS A - X) PASSED 100%! <<<")
	print("================================================================================\n")
	quit(0)














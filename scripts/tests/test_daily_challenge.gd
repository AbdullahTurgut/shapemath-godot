extends SceneTree

const SaveManager = preload("res://scripts/core/save_manager.gd")
const LevelManager = preload("res://scripts/core/level_manager.gd")
const LevelData = preload("res://scripts/resources/level_data.gd")
const MainScene = preload("res://scenes/main.tscn")

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
	print("--- BEGINNING STEP 18-1 OFFLINE DAILY CHALLENGE TEST SUITE ---")
	print("================================================================================")

	var test_save_path: String = "user://test_save_daily.cfg"
	var legacy_save_path: String = "user://test_save_legacy_daily.cfg"

	for p in [test_save_path, legacy_save_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

	# ================================================================================
	# TEST 1: RUNMODE ENUM & RUN LENGTHS
	# ================================================================================
	print("\n[TEST 1] RunMode Enum and Mode-Aware Run Lengths")
	var lm := LevelManager.new()
	assert(LevelManager.RunMode.STANDARD == 0, "RunMode.STANDARD exists")
	assert(LevelManager.RunMode.DAILY == 1, "RunMode.DAILY exists")

	lm.current_run_mode = LevelManager.RunMode.STANDARD
	assert(lm.get_active_run_length() == 15, "Standard run length is 15")

	lm.current_run_mode = LevelManager.RunMode.DAILY
	assert(lm.get_active_run_length() == 10, "Daily run length is 10")
	print("-> TEST 1 PASSED: RunMode and lengths verified.")

	# ================================================================================
	# TEST 2: DETERMINISTIC SEED FORMULA & VERSIONING
	# ================================================================================
	print("\n[TEST 2] Deterministic Seed Formula and DAILY_ALGORITHM_VERSION")
	assert(LevelManager.DAILY_ALGORITHM_VERSION == 1, "DAILY_ALGORITHM_VERSION is 1")
	var date_20260902: int = 20260902
	var seed_1: int = LevelManager.get_daily_seed(date_20260902)
	var seed_2: int = LevelManager.get_daily_seed(date_20260902)
	assert(seed_1 == seed_2, "Seed is deterministic for same date")

	var date_20260903: int = 20260903
	var seed_3: int = LevelManager.get_daily_seed(date_20260903)
	assert(seed_1 != seed_3, "Different date produces different seed")
	print("-> TEST 2 PASSED: Seed derivation verified.")

	# ================================================================================
	# TEST 3: DAILY SEQUENCE GENERATION & REPRODUCIBILITY
	# ================================================================================
	print("\n[TEST 3] Daily Sequence Generation (Length, Tiers, Determinism, Isolation)")
	var seq_a: Array[LevelData] = lm.generate_daily_run_sequence(20260902)
	assert(seq_a.size() == 10, "Daily sequence has exactly 10 levels")

	var seq_b: Array[LevelData] = lm.generate_daily_run_sequence(20260902)
	assert(seq_b.size() == 10, "Repeated Daily sequence has 10 levels")

	for i in range(10):
		assert(seq_a[i] == seq_b[i], "Daily sequence at index %d is strictly identical" % i)

	# Tier distribution: 3 Tier 1, 4 Tier 2, 3 Tier 3
	for i in range(3):
		assert(seq_a[i].tier == 1, "Slot %d is Tier 1" % i)
	for i in range(3, 7):
		assert(seq_a[i].tier == 2, "Slot %d is Tier 2" % i)
	for i in range(7, 10):
		assert(seq_a[i].tier == 3, "Slot %d is Tier 3" % i)

	# No duplicates
	var seen_levels: Dictionary = {}
	for lvl in seq_a:
		assert(not seen_levels.has(lvl), "No duplicate levels in daily run: %s" % lvl.resource_path)
		seen_levels[lvl] = true
		assert(not "samples" in lvl.resource_path, "No sample resources in daily run")

	# Anti-clumping: no 3 consecutive same puzzle types
	for i in range(seq_a.size() - 2):
		var clump: bool = (seq_a[i].puzzle_type == seq_a[i+1].puzzle_type and seq_a[i+1].puzzle_type == seq_a[i+2].puzzle_type)
		assert(not clump, "Anti-clumping satisfied at index %d" % i)

	# Different date produces different challenge
	var seq_diff: Array[LevelData] = lm.generate_daily_run_sequence(20260903)
	assert(seq_diff.size() == 10, "Different date sequence has 10 levels")
	var is_any_different: bool = false
	for i in range(10):
		if seq_a[i] != seq_diff[i]:
			is_any_different = true
			break
	assert(is_any_different, "Different dates generate different level sequences")
	print("-> TEST 3 PASSED: Daily sequence generation verified.")

	# ================================================================================
	# TEST 4: SAVEMANAGER DAILY PERSISTENCE & LEGACY COMPATIBILITY
	# ================================================================================
	print("\n[TEST 4] SaveManager Daily Persistence & Rollover")
	var sm := SaveManager.new()
	sm.save_path = test_save_path
	sm.load_data()

	assert(sm.get_daily_date_key() == 0, "Default daily_date_key is 0")
	assert(sm.get_daily_completed() == false, "Default daily_completed is false")
	assert(sm.get_daily_best_solved() == 0, "Default daily_best_solved is 0")
	assert(sm.get_daily_best_streak() == 0, "Default daily_best_streak is 0")
	assert(sm.get_daily_perfect() == false, "Default daily_perfect is false")
	assert(sm.is_daily_completed_today(20260902) == false, "is_daily_completed_today is false")

	# Start daily for date 20260902
	sm.record_daily_started(20260902)
	assert(sm.get_daily_date_key() == 20260902, "daily_date_key set to 20260902")

	# Record daily progress
	sm.record_daily_progress(20260902, 5, 4)
	assert(sm.get_daily_best_solved() == 5, "daily_best_solved updated to 5")
	assert(sm.get_daily_best_streak() == 4, "daily_best_streak updated to 4")

	# Non-regressing updates
	sm.record_daily_progress(20260902, 3, 2)
	assert(sm.get_daily_best_solved() == 5, "daily_best_solved did not decrease")
	assert(sm.get_daily_best_streak() == 4, "daily_best_streak did not decrease")

	# Record non-perfect completion
	sm.record_daily_completed(20260902, false, 6)
	assert(sm.get_daily_completed() == true, "daily_completed is true")
	assert(sm.get_daily_best_solved() == 10, "daily_best_solved is 10 on completion")
	assert(sm.get_daily_best_streak() == 6, "daily_best_streak is 6")
	assert(sm.get_daily_perfect() == false, "daily_perfect is false")
	assert(sm.is_daily_completed_today(20260902) == true, "is_daily_completed_today returns true")

	# Replay perfect completion later that date
	sm.record_daily_completed(20260902, true, 10)
	assert(sm.get_daily_perfect() == true, "daily_perfect becomes true after perfect replay")
	assert(sm.get_daily_best_streak() == 10, "daily_best_streak updated to 10")

	# Imperfect replay after perfect completion preserves daily_perfect
	sm.record_daily_completed(20260902, false, 8)
	assert(sm.get_daily_perfect() == true, "daily_perfect remains true after subsequent imperfect replay")

	# Rollover to new date 20260903
	sm.set_sound_enabled(false)
	sm.set_haptics_enabled(false)
	sm.personal_best_streak = 12
	sm.total_runs_started = 5
	sm.total_runs_completed = 3
	sm.total_perfect_runs = 1
	sm.total_puzzles_solved = 45
	sm.save_data()

	sm.ensure_daily_state(20260903)
	assert(sm.get_daily_date_key() == 20260903, "Rolled over to new date_key")
	assert(sm.get_daily_completed() == false, "daily_completed reset on new date")
	assert(sm.get_daily_best_solved() == 0, "daily_best_solved reset on new date")
	assert(sm.get_daily_best_streak() == 0, "daily_best_streak reset on new date")
	assert(sm.get_daily_perfect() == false, "daily_perfect reset on new date")

	# Lifetime stats & settings untouched
	assert(sm.get_sound_enabled() == false, "sound_enabled preserved across daily rollover")
	assert(sm.get_haptics_enabled() == false, "haptics_enabled preserved across daily rollover")
	assert(sm.get_personal_best_streak() == 12, "personal_best_streak preserved across daily rollover")
	assert(sm.get_total_runs_started() == 5, "total_runs_started preserved across daily rollover")
	assert(sm.get_total_runs_completed() == 3, "total_runs_completed preserved across daily rollover")
	assert(sm.get_total_perfect_runs() == 1, "total_perfect_runs preserved across daily rollover")
	assert(sm.get_total_puzzles_solved() == 45, "total_puzzles_solved preserved across daily rollover")

	# Legacy save file loading (missing [daily] section)
	var legacy_cfg := ConfigFile.new()
	legacy_cfg.set_value("settings", "sound_enabled", true)
	legacy_cfg.set_value("progress", "total_puzzles_solved", 80)
	legacy_cfg.save(legacy_save_path)

	var legacy_sm := SaveManager.new()
	legacy_sm.save_path = legacy_save_path
	legacy_sm.load_data()
	assert(legacy_sm.get_daily_date_key() == 0, "Legacy save daily_date_key defaults to 0")
	assert(legacy_sm.get_daily_completed() == false, "Legacy save daily_completed defaults to false")
	assert(legacy_sm.get_total_puzzles_solved() == 80, "Legacy save preserves total_puzzles_solved")
	print("-> TEST 4 PASSED: Daily persistence & rollover verified.")

	# ================================================================================
	# TEST 5: FULL SCENE & GAMEPLAY LIFECYCLE SIMULATION (DAILY & STANDARD)
	# ================================================================================
	print("\n[TEST 5] Full Scene & Gameplay Lifecycle Simulation")
	var main_scene = MainScene.instantiate()
	root.add_child(main_scene)
	await _sync_physics()

	var scene_sm: SaveManager = main_scene.save_manager
	var scene_lm: LevelManager = main_scene.level_manager
	scene_sm.save_path = "user://test_scene_daily.cfg"
	if FileAccess.file_exists(scene_sm.save_path):
		DirAccess.remove_absolute(scene_sm.save_path)
	scene_sm.load_data()
	main_scene._refresh_main_menu()

	var daily_btn: Button = main_scene.get_node("MainMenu/DailyChallengeButton")
	var start_btn: Button = main_scene.get_node("MainMenu/StartGameButton")
	var title_lbl: Label = main_scene.get_node("TitleLabel")
	var level_lbl: Label = main_scene.get_node("LevelIndicatorLabel")
	var complete_overlay: Control = main_scene.get_node("RunCompleteOverlay")
	var summary_title: Label = main_scene.get_node("RunCompleteOverlay/Card/CardTitle")
	var failure_overlay: Control = main_scene.get_node("RunFailureOverlay")
	var failure_title: Label = main_scene.get_node("RunFailureOverlay/Card/CardTitle")
	var failure_progress: Label = main_scene.get_node("RunFailureOverlay/Card/FailureProgressLabel")

	# Initial Main Menu state
	assert(daily_btn != null, "DailyChallengeButton exists in MainMenu")
	assert(daily_btn.text == "Günün Turu", "Daily button initially reads 'Günün Turu'")

	# Start Daily Challenge
	main_scene.start_daily_from_menu()
	await _sync_physics()

	assert(main_scene.current_state == main_scene.AppState.PLAYING, "Main state is PLAYING")
	assert(scene_lm.current_run_mode == LevelManager.RunMode.DAILY, "LevelManager is in DAILY mode")
	assert(scene_lm.current_run_levels.size() == 10, "Daily run has 10 levels")
	assert(title_lbl.text == "Günün Turu", "Title label displays 'Günün Turu'")
	assert(level_lbl.text == "Bölüm 1 / 10", "Level indicator displays 'Bölüm 1 / 10'")

	# Daily does not increment standard runs started
	assert(scene_sm.get_total_runs_started() == 0, "Daily start does NOT increment total_runs_started")

	var solve_current := func():
		if scene_lm.current_level_data.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
			scene_lm._process_shape_success(scene_lm.shape_piece_a, scene_lm.shape_piece_b)
		else:
			var target_p: DraggablePiece = null
			for p in scene_lm.math_pieces:
				if p.piece_text == scene_lm.current_level_data.correct_answer:
					target_p = p
					break
			assert(target_p != null)
			target_p.reset_piece()
			target_p.global_position = scene_lm.math_target_zone.global_position
			await _sync_physics()
			scene_lm._on_math_piece_dropped(target_p)

	var drop_wrong := func():
		if scene_lm.current_level_data.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
			scene_lm._handle_deliberate_failure(scene_lm.shape_piece_a)
		else:
			var wp: DraggablePiece = null
			for p in scene_lm.math_pieces:
				if p.piece_text != scene_lm.current_level_data.correct_answer:
					wp = p
					break
			if wp:
				scene_lm._handle_deliberate_failure(wp)
			elif scene_lm.math_pieces.size() > 0:
				scene_lm._handle_deliberate_failure(scene_lm.math_pieces[0])
		await _sync_physics()

	# Simulate solving 10 levels perfectly
	for i in range(10):
		var target_idx: int = i
		await solve_current.call()

		if i < 9:
			var timeout: float = 2.0
			while scene_lm.current_level_index == target_idx and timeout > 0.0:
				await process_frame
				await _sync_physics()
				timeout -= 0.016
			assert(scene_lm.current_level_index == target_idx + 1, "Advanced to level %d" % (target_idx + 2))
		else:
			var timeout: float = 3.0
			while not complete_overlay.visible and timeout > 0.0:
				await process_frame
				await _sync_physics()
				timeout -= 0.016

	await process_frame
	await _sync_physics()

	assert(complete_overlay.visible == true, "RunCompleteOverlay is visible")
	assert("Kusursuz Gün!" in summary_title.text, "Daily perfect title reads 'Kusursuz Gün!'")
	assert("10 / 10" in summary_title.text, "Daily completion displays '10 / 10'")

	# Check statistics isolation
	assert(scene_sm.get_total_runs_started() == 0, "total_runs_started is 0")
	assert(scene_sm.get_total_runs_completed() == 0, "total_runs_completed is 0")
	assert(scene_sm.get_total_perfect_runs() == 0, "total_perfect_runs is 0")
	assert(scene_sm.get_total_puzzles_solved() == 10, "total_puzzles_solved is 10")
	assert(scene_sm.get_personal_best_streak() == 10, "personal_best_streak updated to 10")
	assert(scene_sm.get_daily_completed() == true, "daily_completed is true")
	assert(scene_sm.get_daily_perfect() == true, "daily_perfect is true")
	assert(scene_sm.get_daily_best_solved() == 10, "daily_best_solved is 10")
	assert(scene_sm.get_daily_best_streak() == 10, "daily_best_streak is 10")

	# Return to Main Menu
	main_scene.return_to_main_menu()
	await _sync_physics()

	assert(main_scene.current_state == main_scene.AppState.MAIN_MENU, "Returned to MAIN_MENU")
	assert(daily_btn.text == "Günün Turu ✓", "Daily button displays checkmark 'Günün Turu ✓'")

	# Replay Daily Challenge
	main_scene.start_daily_from_menu()
	await _sync_physics()
	assert(scene_lm.current_run_mode == LevelManager.RunMode.DAILY, "Replay starts in DAILY mode")
	assert(scene_lm.current_run_levels.size() == 10, "Replay has 10 levels")

	# Fail on level 1 (deliberate wrong drop removes lives)
	await drop_wrong.call()
	await drop_wrong.call()
	await drop_wrong.call() # 0 lives -> failure
	var fail_timeout: float = 3.0
	while not failure_overlay.visible and fail_timeout > 0.0:
		await process_frame
		await _sync_physics()
		fail_timeout -= 0.016
	await process_frame
	await _sync_physics()

	assert(failure_overlay.visible == true, "RunFailureOverlay is visible")
	assert(failure_title.text == "Günün Turu Başarısız", "Failure title reads 'Günün Turu Başarısız'")
	assert("1 / 10 Bölüme Ulaştın" in failure_progress.text, "Failure progress displays '1 / 10'")

	# Return to Main Menu and start Standard Run
	main_scene.return_to_main_menu()
	await _sync_physics()
	main_scene.start_game_from_menu()
	await _sync_physics()

	assert(scene_lm.current_run_mode == LevelManager.RunMode.STANDARD, "Standard run mode is STANDARD")
	assert(scene_lm.current_run_levels.size() == 15, "Standard run has 15 levels")
	assert(title_lbl.text == "ShapeMath", "Standard title displays 'ShapeMath'")
	assert(level_lbl.text == "Bölüm 1 / 15", "Standard level indicator displays 'Bölüm 1 / 15'")
	assert(scene_sm.get_total_runs_started() == 1, "Standard start increments total_runs_started to 1")

	main_scene.queue_free()
	print("-> TEST 5 PASSED: Full scene lifecycle and statistics isolation verified.")

	# Cleanup test saves
	for p in [test_save_path, legacy_save_path, "user://test_scene_daily.cfg"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

	print("\n================================================================================")
	print("--- ALL STEP 18-1 DAILY CHALLENGE TESTS PASSED SUCCESSFULLY (100%) ---")
	print("================================================================================")
	quit()

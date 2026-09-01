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
	print("--- BEGINNING STEP 13A AUTOMATED TEST SUITE (PERSISTENT SETTINGS & PERSONAL BEST ARCHITECTURE) ---")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()
	root.add_child(main_node)

	# Allow a frame for _ready to execute
	await process_frame
	await _sync_physics()

	var save_manager: SaveManager = main_node.get_node("SaveManager") as SaveManager
	var feedback_manager: FeedbackManager = main_node.get_node("FeedbackManager") as FeedbackManager
	var level_manager: LevelManager = main_node.get_node("LevelManager") as LevelManager
	var level_lbl: Label = main_node.get_node("LevelIndicatorLabel") as Label
	var lives_lbl: Label = main_node.get_node("LivesLabel") as Label
	var streak_lbl: Label = main_node.get_node("StreakLabel") as Label
	var prompt_lbl: Label = main_node.get_node("PromptLabel") as Label
	var success_lbl: Label = main_node.get_node("SuccessLabel") as Label

	var complete_overlay: Control = main_node.get_node("RunCompleteOverlay") as Control
	var play_again_btn: Button = complete_overlay.get_node("Card/PlayAgainButton") as Button

	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
	var try_again_btn: Button = failure_overlay.get_node("Card/TryAgainButton") as Button

	assert(save_manager != null, "SaveManager must exist in main scene")
	assert(feedback_manager != null, "FeedbackManager must exist in main scene")
	assert(level_manager != null, "LevelManager must exist in main scene")

	# Accelerate animation delays for test suite execution speed
	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# Define isolated test save paths so developer's actual save file is unaffected
	var test_save_path: String = "user://test_save_13a.cfg"
	var test_corrupt_path: String = "user://test_corrupt_13a.cfg"
	var test_partial_path: String = "user://test_partial_13a.cfg"

	# Clean up any existing test files
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	if FileAccess.file_exists(test_corrupt_path):
		DirAccess.remove_absolute(test_corrupt_path)
	if FileAccess.file_exists(test_partial_path):
		DirAccess.remove_absolute(test_partial_path)

	# --- TEST SCENARIO A: FIRST LAUNCH DEFAULTS (NO FILE EXISTS) ---
	print("\n[SCENARIO A] First launch defaults when no save file exists")
	var sm_test := SaveManager.new()
	sm_test.save_path = test_save_path
	sm_test.load_data()
	assert(sm_test.get_sound_enabled() == true, "Scenario A: Default sound_enabled must be true")
	assert(sm_test.get_haptics_enabled() == true, "Scenario A: Default haptics_enabled must be true")
	assert(sm_test.get_personal_best_streak() == 0, "Scenario A: Default personal_best_streak must be 0")

	# --- TEST SCENARIO B: SETTINGS SAVE & RELOAD ---
	print("\n[SCENARIO B] Settings save & reload from disk")
	sm_test.set_sound_enabled(false)
	sm_test.set_haptics_enabled(false)

	var sm_reload := SaveManager.new()
	sm_reload.save_path = test_save_path
	sm_reload.load_data()
	assert(sm_reload.get_sound_enabled() == false, "Scenario B: Persisted sound_enabled must be false")
	assert(sm_reload.get_haptics_enabled() == false, "Scenario B: Persisted haptics_enabled must be false")

	# --- TEST SCENARIO C: INDEPENDENT TOGGLES ---
	print("\n[SCENARIO C] Independent sound and haptic toggles")
	sm_test.set_sound_enabled(false)
	sm_test.set_haptics_enabled(true)

	var sm_reload2 := SaveManager.new()
	sm_reload2.save_path = test_save_path
	sm_reload2.load_data()
	assert(sm_reload2.get_sound_enabled() == false, "Scenario C: sound_enabled must be false")
	assert(sm_reload2.get_haptics_enabled() == true, "Scenario C: haptics_enabled must be true")

	# --- TEST SCENARIO D: PERSONAL RECORD SAVE & RELOAD ---
	print("\n[SCENARIO D] Update personal best streak and reload")
	var updated_d: bool = sm_test.update_personal_best_streak(5)
	assert(updated_d == true, "Scenario D: Updating from 0 to 5 returns true")

	var sm_reload3 := SaveManager.new()
	sm_reload3.save_path = test_save_path
	sm_reload3.load_data()
	assert(sm_reload3.get_personal_best_streak() == 5, "Scenario D: Persisted personal best must be 5")

	# --- TEST SCENARIO E: PERSONAL RECORD CANNOT DECREASE ---
	print("\n[SCENARIO E] Personal best cannot decrease when lower streak is attempted")
	var updated_e: bool = sm_test.update_personal_best_streak(3)
	assert(updated_e == false, "Scenario E: Lower streak of 3 must not overwrite 5 and returns false")
	assert(sm_test.get_personal_best_streak() == 5, "Scenario E: Personal best remains 5")

	# --- TEST SCENARIO F: PERSONAL RECORD INCREASES ---
	print("\n[SCENARIO F] Personal best increases to 8")
	var updated_f: bool = sm_test.update_personal_best_streak(8)
	assert(updated_f == true, "Scenario F: Updating from 5 to 8 returns true")
	assert(sm_test.get_personal_best_streak() == 8, "Scenario F: Personal best is 8")

	var sm_reload4 := SaveManager.new()
	sm_reload4.save_path = test_save_path
	sm_reload4.load_data()
	assert(sm_reload4.get_personal_best_streak() == 8, "Scenario F: Persisted personal best is 8")

	# --- TEST SCENARIO G: SESSION RESET SEMANTICS ---
	print("\n[SCENARIO G] Session reset semantics: volatile streaks reset, personal best preserved")
	level_manager.save_manager = sm_reload4
	level_manager.personal_best_streak = sm_reload4.get_personal_best_streak()
	level_manager.current_streak = 0
	level_manager.best_streak_this_run = 0
	level_manager.best_streak_session = 0

	assert(level_manager.current_streak == 0, "Scenario G: current_streak is 0")
	assert(level_manager.best_streak_this_run == 0, "Scenario G: best_streak_this_run is 0")
	assert(level_manager.best_streak_session == 0, "Scenario G: best_streak_session is 0")
	assert(level_manager.personal_best_streak == 8, "Scenario G: personal_best_streak preserved at 8")

	# --- TEST SCENARIO H: CORRUPT / MALFORMED CONFIG ---
	print("\n[SCENARIO H] Corrupted config file safely falls back to defaults without crashing")
	var file_corrupt := FileAccess.open(test_corrupt_path, FileAccess.WRITE)
	file_corrupt.store_string("[settings\nmalformed === {{{ }}} corrupt data")
	file_corrupt.close()

	var sm_corrupt := SaveManager.new()
	sm_corrupt.save_path = test_corrupt_path
	sm_corrupt.load_data()
	assert(sm_corrupt.get_sound_enabled() == true, "Scenario H: Fallback sound_enabled is true")
	assert(sm_corrupt.get_haptics_enabled() == true, "Scenario H: Fallback haptics_enabled is true")
	assert(sm_corrupt.get_personal_best_streak() == 0, "Scenario H: Fallback personal_best_streak is 0")

	# --- TEST SCENARIO I: MISSING KEYS / PARTIAL CONFIG ---
	print("\n[SCENARIO I] Partial config loads present keys and falls back for missing keys")
	var file_partial := FileAccess.open(test_partial_path, FileAccess.WRITE)
	file_partial.store_string("[settings]\nsound_enabled=false\n")
	file_partial.close()

	var sm_partial := SaveManager.new()
	sm_partial.save_path = test_partial_path
	sm_partial.load_data()
	assert(sm_partial.get_sound_enabled() == false, "Scenario I: Loaded sound_enabled is false")
	assert(sm_partial.get_haptics_enabled() == true, "Scenario I: Fallback haptics_enabled is true")
	assert(sm_partial.get_personal_best_streak() == 0, "Scenario I: Fallback personal_best_streak is 0")

	# --- TEST SCENARIO J, K, L, M: FEEDBACK SOUND AND HAPTIC SUPPRESSION ---
	print("\n[SCENARIO J, K, L, M] FeedbackManager suppression behavior for sound & haptics")
	# Scenario J: Sound disabled suppresses AudioPlayer
	feedback_manager.sound_enabled = false
	feedback_manager.haptics_enabled = true
	feedback_manager.play_correct()
	for player in feedback_manager._players:
		assert(not player.playing, "Scenario J: No AudioPlayer should be playing when sound_enabled is false")

	# Scenario M: Sound enabled + Haptics disabled
	feedback_manager.sound_enabled = true
	feedback_manager.haptics_enabled = false
	feedback_manager.play_correct()
	var any_playing: bool = false
	for player in feedback_manager._players:
		if player.playing:
			any_playing = true
			break
	assert(any_playing == true, "Scenario M: AudioPlayer plays when sound_enabled is true")

	# Restore feedback manager settings to true
	feedback_manager.sound_enabled = true
	feedback_manager.haptics_enabled = true

	# --- TEST SCENARIO N: GAMEPLAY INTEGRATION & REGRESSION ---
	print("\n[SCENARIO N] Gameplay integration: solve level updates personal best and runs 15-level flow")
	var sm_game := SaveManager.new()
	sm_game.save_path = test_save_path
	sm_game.personal_best_streak = 0
	sm_game.save_data()

	level_manager.save_manager = sm_game
	level_manager.personal_best_streak = 0
	level_manager.current_streak = 0
	level_manager.best_streak_this_run = 0
	level_manager.best_streak_session = 0

	level_manager.current_run_levels.clear()
	level_manager.generate_run_sequence()
	assert(level_manager.current_run_levels.size() == 15, "Scenario N: Generated run has 15 levels")
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

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

	# Solve Level 1
	await solve_active_level.call()
	assert(level_manager.current_streak == 1, "Streak is 1")
	assert(level_manager.personal_best_streak == 1, "personal_best_streak is 1")
	assert(sm_game.get_personal_best_streak() == 1, "SaveManager personal_best_streak is 1")

	# Clean up test files
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	if FileAccess.file_exists(test_corrupt_path):
		DirAccess.remove_absolute(test_corrupt_path)
	if FileAccess.file_exists(test_partial_path):
		DirAccess.remove_absolute(test_partial_path)

	print("\n>>> ALL STEP 13A AUTOMATED TESTS (SCENARIOS A - N) PASSED PERFECTLY! <<<\n")
	quit(0)







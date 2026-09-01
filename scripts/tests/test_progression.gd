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
	print("--- BEGINNING STEP 13B AUTOMATED TEST SUITE (MAIN MENU & START GAME FLOW) ---")

	# Define isolated test save path
	var test_save_path: String = "user://test_save_13b.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	# Pre-populate a test save with personal_best_streak = 8 for Scenario D test
	var sm_setup := SaveManager.new()
	sm_setup.save_path = test_save_path
	sm_setup.personal_best_streak = 8
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
	var menu_pb_lbl: Label = main_menu.get_node("PersonalBestLabel") as Label
	var start_btn: Button = main_menu.get_node("StartGameButton") as Button

	var level_lbl: Label = main_node.get_node("LevelIndicatorLabel") as Label
	var lives_lbl: Label = main_node.get_node("LivesLabel") as Label
	var streak_lbl: Label = main_node.get_node("StreakLabel") as Label
	var prompt_lbl: Label = main_node.get_node("PromptLabel") as Label
	var success_lbl: Label = main_node.get_node("SuccessLabel") as Label

	var complete_overlay: Control = main_node.get_node("RunCompleteOverlay") as Control
	var play_again_btn: Button = complete_overlay.get_node("Card/PlayAgainButton") as Button

	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
	var try_again_btn: Button = failure_overlay.get_node("Card/TryAgainButton") as Button

	assert(main_menu != null, "MainMenu control node must exist")
	assert(start_btn != null, "StartGameButton must exist")
	assert(menu_pb_lbl != null, "PersonalBestLabel must exist")

	# Accelerate animation delays for test suite execution speed
	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# --- TEST SCENARIO A: FRESH APP LAUNCH SHOWS MAIN MENU ---
	print("\n[SCENARIO A] App launches into Main Menu")
	assert(main_menu.visible == true, "Scenario A: Main Menu must be visible on launch")
	assert(menu_title_lbl.text == "ShapeMath", "Scenario A: Title must be 'ShapeMath'")

	# --- TEST SCENARIO B: GAMEPLAY CONTENT HIDDEN / INACTIVE ON LAUNCH ---
	print("\n[SCENARIO B] Gameplay content hidden and inactive on launch before pressing Oyuna Başla")
	assert(prompt_lbl.visible == false, "Scenario B: prompt_label must be hidden on launch")
	assert(level_lbl.visible == false, "Scenario B: level_indicator_label must be hidden on launch")
	assert(lives_lbl.visible == false, "Scenario B: lives_label must be hidden on launch")
	assert(level_manager.current_level_data == null, "Scenario B: No active puzzle data before start")
	assert(level_manager.math_pieces.is_empty(), "Scenario B: No active draggable math pieces before start")
	assert(level_manager.shape_pieces.is_empty(), "Scenario B: No active draggable shape pieces before start")

	# --- TEST SCENARIO C & D: PERSONAL BEST DISPLAY REFLECTS PERSISTED VALUE ---
	print("\n[SCENARIO C & D] Main Menu displays loaded Kişisel Rekor (x8)")
	assert(menu_pb_lbl.text == "Kişisel Rekor: x8", "Scenario D: Personal best label must show 'Kişisel Rekor: x8' (got '%s')" % menu_pb_lbl.text)

	# --- TEST SCENARIO E, F, G, H: PRESS OYUNA BAŞLA -> TRANSITIONS TO GAMEPLAY ---
	print("\n[SCENARIO E, F, G, H] Press 'Oyuna Başla' -> transitions to active Level 1/15 run")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(main_menu.visible == false, "Scenario E: Main Menu is hidden after start")
	assert(prompt_lbl.visible == true, "Scenario E: prompt_label is visible")
	assert(level_lbl.visible == true, "Scenario E: level_indicator_label is visible")
	assert(level_lbl.text == "Bölüm 1 / 15", "Scenario E: Indicator shows 'Bölüm 1 / 15'")
	assert(lives_lbl.visible == true, "Scenario E: lives_label is visible")
	assert(lives_lbl.text == "♥ ♥ ♥", "Scenario E: 3 lives displayed")
	assert(level_manager.current_lives == 3, "Scenario E: Lives = 3")
	assert(level_manager.current_streak == 0, "Scenario E: current_streak = 0")
	assert(level_manager.best_streak_this_run == 0, "Scenario E: best_streak_this_run = 0")
	assert(level_manager.current_run_levels.size() == 15, "Scenario E: 15 levels generated")

	# Scenario F: Tier distribution
	for i in range(15):
		if i < 5:
			assert(level_manager.current_run_levels[i].tier == 1, "Scenario F: Position %d must be Tier 1" % (i + 1))
		elif i < 10:
			assert(level_manager.current_run_levels[i].tier == 2, "Scenario F: Position %d must be Tier 2" % (i + 1))
		else:
			assert(level_manager.current_run_levels[i].tier == 3, "Scenario F: Position %d must be Tier 3" % (i + 1))

	# Scenario H: Puzzle is interactive and solves
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

	await solve_active_level.call()
	assert(level_manager.current_streak == 1, "Scenario H: Streak increments to 1 on solve")
	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	# --- TEST SCENARIO I: RUN FAILURE & RETRY FLOW ---
	print("\n[SCENARIO I] Run failure and Tekrar Dene")
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

	assert(failure_overlay.visible == true, "Scenario I: Failure overlay is visible")

	# Retry
	try_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(failure_overlay.visible == false, "Scenario I: Failure overlay hidden after retry")
	assert(level_manager.current_level_index == 0, "Scenario I: Reset to Position 1")
	assert(level_manager.current_lives == 3, "Scenario I: Lives reset to 3")
	assert(level_lbl.text == "Bölüm 1 / 15", "Scenario I: Indicator reset to Bölüm 1 / 15")

	# --- TEST SCENARIO J: RUN COMPLETE & PLAY AGAIN FLOW ---
	print("\n[SCENARIO J] Run complete (15/15) and Tekrar Oyna")
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

	assert(complete_overlay.visible == true, "Scenario J: Complete overlay visible")

	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(complete_overlay.visible == false, "Scenario J: Complete overlay hidden after Play Again")
	assert(level_manager.current_level_index == 0, "Scenario J: Reset to position 0")
	assert(level_manager.current_lives == 3, "Scenario J: Lives reset to 3")

	# --- TEST SCENARIO K & L: 36-LEVEL MASTER POOL & PERSISTENCE UNBROKEN ---
	print("\n[SCENARIO K & L] 36-level pool & persistence integrity")
	assert(level_manager.levels.size() == 36, "Scenario L: Master pool has 36 levels")

	# Clean up isolated test file
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	print("\n>>> ALL STEP 13B AUTOMATED TESTS (SCENARIOS A - L) PASSED PERFECTLY! <<<\n")
	quit(0)








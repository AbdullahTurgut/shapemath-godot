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
	print("--- BEGINNING STEP 17A: NUMBER_SEQUENCE ARCHITECTURE & SAMPLE TESTS ---")
	print("================================================================================")

	var test_save_path: String = "user://test_save_step17a.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	# ================================================================================
	# TEST 1: ENUM & RESOURCE LOADING
	# ================================================================================
	print("\n[TEST 1] LevelData.PuzzleType enum contains NUMBER_SEQUENCE")
	assert("NUMBER_SEQUENCE" in LevelData.PuzzleType, "PuzzleType has NUMBER_SEQUENCE")
	assert(LevelData.PuzzleType.NUMBER_SEQUENCE == 4, "NUMBER_SEQUENCE enum value is 4")
	print("-> TEST 1 PASSED: Enum verification complete.")

	# ================================================================================
	# TEST 2: SAMPLE RESOURCE VALIDATION & FINAL-MISSING GRAMMAR
	# ================================================================================
	print("\n[TEST 2] Sample LevelData resources validation (Easy, Medium, Hard)")
	var sample_easy_path: String = "res://data/levels/samples/sample_sequence_easy.tres"
	var sample_med_path: String = "res://data/levels/samples/sample_sequence_medium.tres"
	var sample_hard_path: String = "res://data/levels/samples/sample_sequence_hard.tres"

	assert(ResourceLoader.exists(sample_easy_path), "Sample Easy exists")
	assert(ResourceLoader.exists(sample_med_path), "Sample Medium exists")
	assert(ResourceLoader.exists(sample_hard_path), "Sample Hard exists")

	var lvl_easy: LevelData = load(sample_easy_path)
	var lvl_med: LevelData = load(sample_med_path)
	var lvl_hard: LevelData = load(sample_hard_path)

	var samples: Array[LevelData] = [lvl_easy, lvl_med, lvl_hard]

	for lvl in samples:
		assert(lvl != null, "Level resource loads successfully")
		assert(lvl.puzzle_type == LevelData.PuzzleType.NUMBER_SEQUENCE, "Puzzle type is NUMBER_SEQUENCE")
		assert(not lvl.prompt_text.is_empty(), "Prompt text is non-empty")
		assert(lvl.prompt_text.strip_edges().ends_with("?"), "Prompt uses final-missing format (ends with '?')")
		assert(lvl.prompt_text.contains(", ?"), "Prompt contains ', ?' separator")
		assert(not lvl.correct_answer.is_empty(), "Correct answer is non-empty")
		assert(lvl.answer_choices.size() >= 3, "At least 3 answer choices")

		# Check correct_answer appears exactly once in answer_choices
		var match_count: int = 0
		for choice in lvl.answer_choices:
			if choice == lvl.correct_answer:
				match_count += 1
		assert(match_count == 1, "correct_answer appears in answer_choices exactly once")

		# Check no duplicate choices
		var unique_choices: Array[String] = []
		for choice in lvl.answer_choices:
			assert(not unique_choices.has(choice), "No duplicate choices: %s" % choice)
			unique_choices.append(choice)

	# Verify Easy grammar
	assert(lvl_easy.tier == 1, "Easy tier is 1")
	assert(lvl_easy.prompt_text == "2, 4, 6, ?", "Easy prompt is '2, 4, 6, ?'")
	assert(lvl_easy.correct_answer == "8", "Easy correct is '8'")

	# Verify Medium grammar
	assert(lvl_med.tier == 2, "Medium tier is 2")
	assert(lvl_med.prompt_text == "3, 6, 12, ?", "Medium prompt is '3, 6, 12, ?'")
	assert(lvl_med.correct_answer == "24", "Medium correct is '24'")

	# Verify Hard grammar
	assert(lvl_hard.tier == 3, "Hard tier is 3")
	assert(lvl_hard.prompt_text == "2, 5, 9, 14, ?", "Hard prompt is '2, 5, 9, 14, ?'")
	assert(lvl_hard.correct_answer == "20", "Hard correct is '20'")
	print("-> TEST 2 PASSED: Sample resource grammar and constraints verified.")

	# ================================================================================
	# TEST 3: NUMBER_SEQUENCE INTERACTION & MATH PIPELINE ROUTING
	# ================================================================================
	print("\n[TEST 3] NUMBER_SEQUENCE math pipeline interaction (solve, wrong drop, neutral drop, lifetime stats)")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()
	var sm: SaveManager = main_node.get_node("SaveManager") as SaveManager
	sm.save_path = test_save_path
	sm.total_runs_started = 0
	sm.total_runs_completed = 0
	sm.total_perfect_runs = 0
	sm.total_puzzles_solved = 0
	sm.personal_best_streak = 0
	sm.tutorial_completed = true
	sm.save_data()

	root.add_child(main_node)
	await process_frame
	await _sync_physics()

	var lm: LevelManager = main_node.get_node("LevelManager") as LevelManager
	var math_container: Node2D = main_node.get_node("MathContainer") as Node2D
	var shape_container: Node2D = main_node.get_node("ShapeContainer") as Node2D
	var prompt_label: Label = main_node.get_node("PromptLabel") as Label

	lm.transition_delay = 0.01
	lm.summary_delay = 0.01
	lm.failure_delay = 0.01

	# Inject our 3 sample levels into LevelManager
	lm.current_run_levels = samples.duplicate()
	lm.load_level(0) # Load Easy sample
	await process_frame
	await _sync_physics()

	assert(math_container.visible == true, "MathContainer is visible for NUMBER_SEQUENCE")
	assert(shape_container.visible == false, "ShapeContainer is hidden for NUMBER_SEQUENCE")
	assert(prompt_label.text == "2, 4, 6, ?", "Prompt label renders sequence text correctly")
	assert(lm.math_pieces.size() == 4, "4 draggable pieces instantiated")

	# 3.1: Test Neutral Drop in empty space (no penalty)
	var initial_lives: int = lm.current_lives
	var initial_mistakes: int = lm.mistakes_this_run
	var piece_0: DraggablePiece = lm.math_pieces[0]
	piece_0.global_position = Vector2(50, 50)
	await _sync_physics()
	lm._on_math_piece_dropped(piece_0)

	assert(lm.current_lives == initial_lives, "Neutral drop loses no life")
	assert(lm.mistakes_this_run == initial_mistakes, "Neutral drop causes no mistakes")
	assert(lm.current_streak == 0, "Streak unchanged")

	# 3.2: Test Deliberate Wrong Drop
	var wrong_piece: DraggablePiece = null
	for p in lm.math_pieces:
		if p.piece_text != lm.current_level_data.correct_answer:
			wrong_piece = p
			break
	assert(wrong_piece != null, "Found wrong piece")
	wrong_piece.global_position = lm.math_target_zone.global_position
	await _sync_physics()
	lm._on_math_piece_dropped(wrong_piece)

	assert(lm.current_lives == 2, "Wrong drop loses 1 life (lives = 2)")
	assert(lm.mistakes_this_run == 1, "Mistakes incremented to 1")
	assert(lm.current_streak == 0, "Streak reset to 0")

	# 3.3: Test Correct Drop on Easy Sequence
	var correct_piece: DraggablePiece = null
	for p in lm.math_pieces:
		if p.piece_text == lm.current_level_data.correct_answer:
			correct_piece = p
			break
	assert(correct_piece != null, "Found correct piece")
	correct_piece.global_position = lm.math_target_zone.global_position
	await _sync_physics()
	lm._on_math_piece_dropped(correct_piece)
	await lm.level_completed

	assert(lm.current_streak == 1, "Streak incremented to 1 on correct solve")
	assert(sm.get_total_puzzles_solved() == 1, "SaveManager.total_puzzles_solved = 1")

	# 3.4: Test Double-count prevention
	lm._on_math_piece_dropped(correct_piece)
	assert(sm.get_total_puzzles_solved() == 1, "Duplicate drop callback does not double-count solve")

	if lm.transition_tween:
		await lm.transition_tween.finished
	await process_frame
	await _sync_physics()

	# 3.5: Test Medium Sequence
	lm.load_level(1)
	await process_frame
	await _sync_physics()

	assert(prompt_label.text == "3, 6, 12, ?", "Medium prompt text matches")
	var med_correct: DraggablePiece = null
	for p in lm.math_pieces:
		if p.piece_text == "24":
			med_correct = p
			break
	assert(med_correct != null, "Found Medium correct piece '24'")
	med_correct.global_position = lm.math_target_zone.global_position
	await _sync_physics()
	lm._on_math_piece_dropped(med_correct)
	await lm.level_completed

	assert(lm.current_streak == 2, "Streak incremented to 2")
	assert(sm.get_total_puzzles_solved() == 2, "SaveManager.total_puzzles_solved = 2")

	if lm.transition_tween:
		await lm.transition_tween.finished
	await process_frame
	await _sync_physics()

	# 3.6: Test Hard Sequence
	lm.load_level(2)
	await process_frame
	await _sync_physics()

	assert(prompt_label.text == "2, 5, 9, 14, ?", "Hard prompt text matches")
	var hard_correct: DraggablePiece = null
	for p in lm.math_pieces:
		if p.piece_text == "20":
			hard_correct = p
			break
	assert(hard_correct != null, "Found Hard correct piece '20'")
	hard_correct.global_position = lm.math_target_zone.global_position
	await _sync_physics()
	lm._on_math_piece_dropped(hard_correct)
	await lm.level_completed

	assert(lm.current_streak == 3, "Streak incremented to 3")
	assert(sm.get_total_puzzles_solved() == 3, "SaveManager.total_puzzles_solved = 3")
	print("-> TEST 3 PASSED: Full interaction flow, solving, error, neutral drop and stats verified.")

	# ================================================================================
	# TEST 4: EXISTING PUZZLE TYPES ROUTING COMPATIBILITY
	# ================================================================================
	print("\n[TEST 4] Existing puzzle types routing validation (Level 1 Math, Level 2 Shape)")
	var lvl1: LevelData = load("res://data/levels/level_01.tres")
	var lvl2: LevelData = load("res://data/levels/level_02.tres")

	lm.current_run_levels = [lvl1, lvl2]
	lm.load_level(0) # MATH_MATCH
	await process_frame
	await _sync_physics()
	assert(math_container.visible == true, "Level 1 MATH_MATCH routes to MathContainer")
	assert(shape_container.visible == false, "Level 1 MATH_MATCH hides ShapeContainer")

	lm.load_level(1) # SHAPE_MATCH
	await process_frame
	await _sync_physics()
	assert(shape_container.visible == true, "Level 2 SHAPE_MATCH routes to ShapeContainer")
	assert(math_container.visible == false, "Level 2 SHAPE_MATCH hides MathContainer")
	print("-> TEST 4 PASSED: Existing types compatibility verified.")

	# Clean up test save file
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	print("\n================================================================================")
	print(">>> ALL STEP 17A TESTS PASSED 100%! <<<")
	print("================================================================================")
	quit(0)

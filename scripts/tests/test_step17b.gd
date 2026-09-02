extends SceneTree

const SaveManager = preload("res://scripts/core/save_manager.gd")
const SequenceValidator = preload("res://scripts/tools/sequence_validator.gd")

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

func _create_test_sequence_level(prompt: String, correct: String, choices: Array[String], tier_num: int) -> LevelData:
	var lvl: LevelData = LevelData.new()
	lvl.puzzle_type = LevelData.PuzzleType.NUMBER_SEQUENCE
	lvl.prompt_text = prompt
	lvl.correct_answer = correct
	lvl.answer_choices = choices
	lvl.tier = tier_num
	lvl.target_display = "?"
	return lvl

func _run_tests() -> void:
	print("================================================================================")
	print("--- BEGINNING STEP 17B: NUMBER_SEQUENCE INTERACTION HARDENING & VALIDATOR ---")
	print("================================================================================")

	var test_save_path: String = "user://test_save_step17b.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	# ================================================================================
	# TEST 1: APPROVED GRAMMAR FAMILIES VALIDATION (PASS CASES)
	# ================================================================================
	print("\n[TEST 1] Validator: Approved grammar pattern families")

	# 1.1: Easy Constant Additive (+2)
	var lvl_easy: LevelData = _create_test_sequence_level("2, 4, 6, ?", "8", ["6", "7", "8", "10"], 1)
	var res1: Dictionary = SequenceValidator.validate_sequence_level(lvl_easy)
	assert(res1.valid == true, "Easy constant additive passes")
	assert(res1.family == "CONSTANT_ADDITIVE", "Family is CONSTANT_ADDITIVE")
	assert(res1.expected == 8, "Expected continuation is 8")

	# 1.2: Medium Constant Additive (+4)
	var lvl_med_add: LevelData = _create_test_sequence_level("4, 8, 12, 16, ?", "20", ["18", "20", "22", "24"], 2)
	var res2: Dictionary = SequenceValidator.validate_sequence_level(lvl_med_add)
	assert(res2.valid == true, "Medium constant additive passes")
	assert(res2.family == "CONSTANT_ADDITIVE")
	assert(res2.expected == 20)

	# 1.3: Medium Geometric x2
	var lvl_med_x2: LevelData = _create_test_sequence_level("3, 6, 12, ?", "24", ["18", "21", "24", "36"], 2)
	var res3: Dictionary = SequenceValidator.validate_sequence_level(lvl_med_x2)
	assert(res3.valid == true, "Medium geometric x2 passes")
	assert(res3.family == "GEOMETRIC_X2")
	assert(res3.expected == 24)

	# 1.4: Medium Descending (-5)
	var lvl_med_desc: LevelData = _create_test_sequence_level("30, 25, 20, ?", "15", ["10", "14", "15", "18"], 2)
	var res4: Dictionary = SequenceValidator.validate_sequence_level(lvl_med_desc)
	assert(res4.valid == true, "Medium descending passes")
	assert(res4.family == "CONSTANT_DESCENDING")
	assert(res4.expected == 15)

	# 1.5: Hard Increasing Differences (+3, +4, +5 -> +6)
	var lvl_hard_inc: LevelData = _create_test_sequence_level("2, 5, 9, 14, ?", "20", ["18", "19", "20", "21"], 3)
	var res5: Dictionary = SequenceValidator.validate_sequence_level(lvl_hard_inc)
	assert(res5.valid == true, "Hard increasing differences passes")
	assert(res5.family == "INCREASING_DIFFERENCES")
	assert(res5.expected == 20)

	# 1.6: Hard Alternating (+3, -2, +3, -2 -> +3)
	var lvl_hard_alt: LevelData = _create_test_sequence_level("5, 8, 6, 9, 7, ?", "10", ["8", "9", "10", "11"], 3)
	var res6: Dictionary = SequenceValidator.validate_sequence_level(lvl_hard_alt)
	assert(res6.valid == true, "Hard alternating additive passes")
	assert(res6.family == "ALTERNATING_ADDITIVE")
	assert(res6.expected == 10)

	print("-> TEST 1 PASSED: All approved pattern families validated successfully.")

	# ================================================================================
	# TEST 2: REJECTED & INVALID PATTERNS VALIDATION (FAIL CASES)
	# ================================================================================
	print("\n[TEST 2] Validator: Rejection of invalid, unapproved or ambiguous patterns")

	# 2.1: Internal missing sequence (e.g. "2, ?, 6, 8") -> MUST FAIL
	var lvl_internal: LevelData = _create_test_sequence_level("2, ?, 6, 8", "4", ["2", "4", "6", "8"], 1)
	var res_int: Dictionary = SequenceValidator.validate_sequence_level(lvl_internal)
	assert(res_int.valid == false, "Internal missing format rejected")

	# 2.2: Duplicate answer choices -> MUST FAIL
	var lvl_dup_choice: LevelData = _create_test_sequence_level("2, 4, 6, ?", "8", ["8", "8", "10", "12"], 1)
	var res_dup: Dictionary = SequenceValidator.validate_sequence_level(lvl_dup_choice)
	assert(res_dup.valid == false, "Duplicate answer choices rejected")

	# 2.3: Correct answer missing from choices -> MUST FAIL
	var lvl_missing_correct: LevelData = _create_test_sequence_level("2, 4, 6, ?", "8", ["6", "7", "9", "10"], 1)
	var res_mc: Dictionary = SequenceValidator.validate_sequence_level(lvl_missing_correct)
	assert(res_mc.valid == false, "Missing correct answer rejected")

	# 2.4: Non-integer answer choice -> MUST FAIL
	var lvl_non_int: LevelData = _create_test_sequence_level("2, 4, 6, ?", "8", ["8", "abc", "10"], 1)
	var res_ni: Dictionary = SequenceValidator.validate_sequence_level(lvl_non_int)
	assert(res_ni.valid == false, "Non-integer choice rejected")

	# 2.5: Arbitrary / unapproved pattern (e.g. random numbers) -> MUST FAIL
	var lvl_random: LevelData = _create_test_sequence_level("2, 9, 3, 11, ?", "7", ["5", "6", "7", "8"], 1)
	var res_rand: Dictionary = SequenceValidator.validate_sequence_level(lvl_random)
	assert(res_rand.valid == false, "Arbitrary unapproved pattern rejected")

	# 2.6: Descending pattern in Tier 1 -> MUST FAIL
	var lvl_desc_t1: LevelData = _create_test_sequence_level("10, 8, 6, ?", "4", ["2", "4", "6", "8"], 1)
	var res_dt1: Dictionary = SequenceValidator.validate_sequence_level(lvl_desc_t1)
	assert(res_dt1.valid == false, "Descending pattern in Tier 1 rejected")

	# 2.7: Increasing difference in Tier 1 -> MUST FAIL
	var lvl_inc_t1: LevelData = _create_test_sequence_level("1, 2, 4, 7, ?", "11", ["9", "10", "11", "12"], 1)
	var res_it1: Dictionary = SequenceValidator.validate_sequence_level(lvl_inc_t1)
	assert(res_it1.valid == false, "Increasing differences in Tier 1 rejected")

	print("-> TEST 2 PASSED: All invalid and out-of-scope patterns successfully rejected.")

	# ================================================================================
	# TEST 3: VALIDATE DISK SAMPLE RESOURCES IN data/levels/samples/
	# ================================================================================
	print("\n[TEST 3] Validating isolated disk sample resources")
	var disk_easy: LevelData = load("res://data/levels/samples/sample_sequence_easy.tres")
	var disk_med: LevelData = load("res://data/levels/samples/sample_sequence_medium.tres")
	var disk_hard: LevelData = load("res://data/levels/samples/sample_sequence_hard.tres")

	var val_easy: Dictionary = SequenceValidator.validate_sequence_level(disk_easy)
	var val_med: Dictionary = SequenceValidator.validate_sequence_level(disk_med)
	var val_hard: Dictionary = SequenceValidator.validate_sequence_level(disk_hard)

	assert(val_easy.valid == true, "sample_sequence_easy.tres is valid")
	assert(val_med.valid == true, "sample_sequence_medium.tres is valid")
	assert(val_hard.valid == true, "sample_sequence_hard.tres is valid")
	print("-> TEST 3 PASSED: All 3 sample resources validated.")

	# ================================================================================
	# TEST 4: INTERACTION HARDENING & EDGE CASE HANDLING
	# ================================================================================
	print("\n[TEST 4] Interaction hardening (repeated drops, neutral drops, life penalty, streak, stats)")
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
	lm.transition_delay = 0.01
	lm.summary_delay = 0.01
	lm.failure_delay = 0.01

	# Test LevelManager with sample levels
	lm.current_run_levels = [disk_easy, disk_med, disk_hard]
	lm.load_level(0)
	await process_frame
	await _sync_physics()

	# 4.1: Neutral Drop does not consume life or reset streak
	var p0: DraggablePiece = lm.math_pieces[0]
	p0.global_position = Vector2(0, 0)
	await _sync_physics()
	lm._on_math_piece_dropped(p0)
	assert(lm.current_lives == 3, "Neutral drop maintains 3 lives")
	assert(lm.mistakes_this_run == 0, "Mistakes count remains 0")
	assert(sm.get_total_puzzles_solved() == 0, "Puzzles solved remains 0")

	# 4.2: Repeated wrong drops deduct lives accurately until failure
	var wrong_p: DraggablePiece = null
	for p in lm.math_pieces:
		if p.piece_text != disk_easy.correct_answer:
			wrong_p = p
			break
	assert(wrong_p != null)

	# First wrong drop -> lives = 2
	wrong_p.global_position = lm.math_target_zone.global_position
	await _sync_physics()
	lm._on_math_piece_dropped(wrong_p)
	assert(lm.current_lives == 2, "Wrong drop 1 -> lives = 2")
	assert(lm.mistakes_this_run == 1, "Mistakes = 1")
	assert(sm.get_total_puzzles_solved() == 0)

	# Second wrong drop -> lives = 1
	wrong_p.global_position = lm.math_target_zone.global_position
	await _sync_physics()
	lm._on_math_piece_dropped(wrong_p)
	assert(lm.current_lives == 1, "Wrong drop 2 -> lives = 1")
	assert(lm.mistakes_this_run == 2, "Mistakes = 2")
	assert(sm.get_total_puzzles_solved() == 0)

	# 4.3: Correct drop solves puzzle and increments stats exactly once
	var correct_p: DraggablePiece = null
	for p in lm.math_pieces:
		if p.piece_text == disk_easy.correct_answer:
			correct_p = p
			break
	assert(correct_p != null)
	correct_p.global_position = lm.math_target_zone.global_position
	await _sync_physics()
	lm._on_math_piece_dropped(correct_p)
	await lm.level_completed

	assert(lm.current_streak == 1, "Streak is 1")
	assert(sm.get_total_puzzles_solved() == 1, "total_puzzles_solved = 1")

	# Repeated drop on solved level does NOT increment streak or stats
	lm._on_math_piece_dropped(correct_p)
	assert(lm.current_streak == 1, "Duplicate drop callback ignored")
	assert(sm.get_total_puzzles_solved() == 1, "total_puzzles_solved still 1")
	print("-> TEST 4 PASSED: Interaction hardening & stats safety verified.")

	# Clean up test save file
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	print("\n================================================================================")
	print(">>> ALL STEP 17B TESTS PASSED 100%! <<<")
	print("================================================================================")
	quit(0)

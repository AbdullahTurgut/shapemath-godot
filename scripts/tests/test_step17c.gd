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

func _run_tests() -> void:
	print("================================================================================")
	print("--- BEGINNING STEP 17C: 54-LEVEL PRODUCTION POOL EXPANSION TESTS ---")
	print("================================================================================")

	var test_save_path: String = "user://test_save_step17c.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	# ================================================================================
	# TEST 1: PRODUCTION POOL INTEGRITY (54 LEVELS, 18 PER TIER, NO SAMPLES IN PRODUCTION)
	# ================================================================================
	print("\n[TEST 1] Production pool loading & tier distribution (1..54)")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()
	var sm: SaveManager = main_node.get_node("SaveManager") as SaveManager
	sm.save_path = test_save_path
	sm.tutorial_completed = true
	sm.save_data()

	root.add_child(main_node)
	await process_frame
	await _sync_physics()

	var lm: LevelManager = main_node.get_node("LevelManager") as LevelManager
	lm._ensure_levels_loaded()

	assert(lm.levels.size() == 54, "Production pool contains exactly 54 levels (got %d)" % lm.levels.size())

	var t1_count: int = 0
	var t2_count: int = 0
	var t3_count: int = 0
	var loaded_paths: Array[String] = []

	var per_tier_type_counts := {
		1: { LevelData.PuzzleType.MATH_MATCH: 0, LevelData.PuzzleType.SHAPE_MATCH: 0, LevelData.PuzzleType.MISSING_NUMBER: 0, LevelData.PuzzleType.EQUIVALENT_EXPRESSION: 0, LevelData.PuzzleType.NUMBER_SEQUENCE: 0 },
		2: { LevelData.PuzzleType.MATH_MATCH: 0, LevelData.PuzzleType.SHAPE_MATCH: 0, LevelData.PuzzleType.MISSING_NUMBER: 0, LevelData.PuzzleType.EQUIVALENT_EXPRESSION: 0, LevelData.PuzzleType.NUMBER_SEQUENCE: 0 },
		3: { LevelData.PuzzleType.MATH_MATCH: 0, LevelData.PuzzleType.SHAPE_MATCH: 0, LevelData.PuzzleType.MISSING_NUMBER: 0, LevelData.PuzzleType.EQUIVALENT_EXPRESSION: 0, LevelData.PuzzleType.NUMBER_SEQUENCE: 0 }
	}

	for idx in range(lm.levels.size()):
		var lvl: LevelData = lm.levels[idx]
		var path: String = lvl.resource_path
		assert(not loaded_paths.has(path), "Duplicate resource in production pool: %s" % path)
		assert(not path.contains("/samples/"), "Sample resource leaked into production pool: %s" % path)
		loaded_paths.append(path)

		assert(lvl.tier in [1, 2, 3], "Level %d has valid tier" % (idx + 1))
		match lvl.tier:
			1: t1_count += 1
			2: t2_count += 1
			3: t3_count += 1

		per_tier_type_counts[lvl.tier][lvl.puzzle_type] += 1

	assert(t1_count == 18, "Tier 1 has exactly 18 levels (got %d)" % t1_count)
	assert(t2_count == 18, "Tier 2 has exactly 18 levels (got %d)" % t2_count)
	assert(t3_count == 18, "Tier 3 has exactly 18 levels (got %d)" % t3_count)

	# Verify per-tier exact distribution: 6 MATH, 3 SHAPE, 3 MISSING, 3 EQUIV, 3 SEQUENCE
	for tier_num in [1, 2, 3]:
		var counts: Dictionary = per_tier_type_counts[tier_num]
		assert(counts[LevelData.PuzzleType.MATH_MATCH] == 6, "Tier %d has 6 MATH_MATCH (got %d)" % [tier_num, counts[LevelData.PuzzleType.MATH_MATCH]])
		assert(counts[LevelData.PuzzleType.SHAPE_MATCH] == 3, "Tier %d has 3 SHAPE_MATCH (got %d)" % [tier_num, counts[LevelData.PuzzleType.SHAPE_MATCH]])
		assert(counts[LevelData.PuzzleType.MISSING_NUMBER] == 3, "Tier %d has 3 MISSING_NUMBER (got %d)" % [tier_num, counts[LevelData.PuzzleType.MISSING_NUMBER]])
		assert(counts[LevelData.PuzzleType.EQUIVALENT_EXPRESSION] == 3, "Tier %d has 3 EQUIVALENT_EXPRESSION (got %d)" % [tier_num, counts[LevelData.PuzzleType.EQUIVALENT_EXPRESSION]])
		assert(counts[LevelData.PuzzleType.NUMBER_SEQUENCE] == 3, "Tier %d has 3 NUMBER_SEQUENCE (got %d)" % [tier_num, counts[LevelData.PuzzleType.NUMBER_SEQUENCE]])

	print("-> TEST 1 PASSED: 54-level pool loading, tier balance and 6-3-3-3-3 distribution verified.")

	# ================================================================================
	# TEST 2: VALIDATE ALL 9 PRODUCTION NUMBER_SEQUENCE RESOURCES VIA SequenceValidator
	# ================================================================================
	print("\n[TEST 2] SequenceValidator validation of all 9 production NUMBER_SEQUENCE levels")
	var seq_levels: Array[LevelData] = []
	for lvl in lm.levels:
		if lvl.puzzle_type == LevelData.PuzzleType.NUMBER_SEQUENCE:
			seq_levels.append(lvl)

	assert(seq_levels.size() == 9, "Exactly 9 NUMBER_SEQUENCE levels across all 54 levels (got %d)" % seq_levels.size())

	for seq_lvl in seq_levels:
		var v_res: Dictionary = SequenceValidator.validate_sequence_level(seq_lvl)
		assert(v_res.valid == true, "Sequence %s failed validation: %s" % [seq_lvl.resource_path, v_res.error])
		print("   ✓ %s -> [%s] Prompt: '%s' | Correct: '%s' | Expected: %d" % [
			seq_lvl.resource_path.get_file(),
			v_res.family,
			seq_lvl.prompt_text,
			seq_lvl.correct_answer,
			v_res.expected
		])

	print("-> TEST 2 PASSED: All 9 sequence levels passed SequenceValidator.")

	# ================================================================================
	# TEST 3: VALIDATE NEW LEVELS 37..54 CONTENT & CHOICES INTEGRITY
	# ================================================================================
	print("\n[TEST 3] Validation of new levels 37..54 (non-empty prompt, unique choices, single correct)")
	for i in range(37, 55):
		var path: String = "res://data/levels/level_%02d.tres" % i
		assert(ResourceLoader.exists(path), "Level %d exists on disk" % i)
		var lvl_res: LevelData = load(path)
		assert(lvl_res != null, "Level %d loads as LevelData" % i)
		assert(not lvl_res.prompt_text.is_empty(), "Level %d has prompt_text" % i)
		assert(not lvl_res.correct_answer.is_empty(), "Level %d has correct_answer" % i)
		assert(lvl_res.answer_choices.size() >= 3, "Level %d has at least 3 choices" % i)

		# Verify correct answer appears in answer choices exactly once
		var correct_matches: int = 0
		for choice in lvl_res.answer_choices:
			if choice == lvl_res.correct_answer:
				correct_matches += 1
		assert(correct_matches == 1, "Level %d correct_answer appears in answer_choices exactly once" % i)

		# Verify no duplicate choices
		var seen_choices: Array[String] = []
		for choice in lvl_res.answer_choices:
			assert(not seen_choices.has(choice), "Level %d has duplicate choice: %s" % [i, choice])
			seen_choices.append(choice)

	# Verify curated level 1 unchanged
	var lvl1: LevelData = load("res://data/levels/level_01.tres")
	assert(lvl1.prompt_text == "1 + 2 = ?", "Curated level 1 prompt unchanged")
	assert(lvl1.correct_answer == "3", "Curated level 1 answer unchanged")
	assert(lvl1.tier == 1, "Curated level 1 tier unchanged")

	print("-> TEST 3 PASSED: New levels 37..54 content integrity verified.")

	# ================================================================================
	# TEST 4: RUN GENERATION WITH 54-LEVEL POOL (5+5+5, RECENT COOLDOWN, 5 TYPES)
	# ================================================================================
	print("\n[TEST 4] Run generator with 54-level pool across 10 consecutive runs")
	var rng := RandomNumberGenerator.new()
	rng.seed = 998877

	for run_idx in range(10):
		var run_levels: Array[LevelData] = lm.generate_run_sequence(rng)
		assert(run_levels.size() == 15, "Run has 15 levels")

		# Check 5 Easy, 5 Medium, 5 Hard
		for k in range(5):
			assert(run_levels[k].tier == 1, "Run %d: level %d is Tier 1" % [run_idx + 1, k + 1])
		for k in range(5, 10):
			assert(run_levels[k].tier == 2, "Run %d: level %d is Tier 2" % [run_idx + 1, k + 1])
		for k in range(10, 15):
			assert(run_levels[k].tier == 3, "Run %d: level %d is Tier 3" % [run_idx + 1, k + 1])

		# Check uniqueness in run
		var unique_set: Array[LevelData] = []
		for lvl in run_levels:
			assert(not unique_set.has(lvl), "Run %d: duplicate level in run: %s" % [run_idx + 1, lvl.resource_path])
			unique_set.append(lvl)

		# Check anti-clumping: no 3 identical puzzle types in a row
		assert(not lm._has_clump_of_three(run_levels), "Run %d: anti-clumping respected" % (run_idx + 1))

	print("-> TEST 4 PASSED: Run generation, 5+5+5 sampling, uniqueness, and anti-clumping verified across 10 runs.")

	# Clean up test save file
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	print("\n================================================================================")
	print(">>> ALL STEP 17C TESTS PASSED 100%! <<<")
	print("================================================================================")
	quit(0)

extends SceneTree

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
	print("--- BEGINNING STEP 12D AUTOMATED TEST SUITE (36-LEVEL MASTER POOL EXPANSION) ---")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()
	root.add_child(main_node)

	# Allow a frame for _ready to execute
	await process_frame
	await _sync_physics()

	var level_manager: LevelManager = main_node.get_node("LevelManager") as LevelManager
	var level_lbl: Label = main_node.get_node("LevelIndicatorLabel") as Label
	var lives_lbl: Label = main_node.get_node("LivesLabel") as Label
	var streak_lbl: Label = main_node.get_node("StreakLabel") as Label
	var prompt_lbl: Label = main_node.get_node("PromptLabel") as Label
	var success_lbl: Label = main_node.get_node("SuccessLabel") as Label

	var complete_overlay: Control = main_node.get_node("RunCompleteOverlay") as Control
	var play_again_btn: Button = complete_overlay.get_node("Card/PlayAgainButton") as Button

	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
	var failure_prog_lbl: Label = failure_overlay.get_node("Card/FailureProgressLabel") as Label
	var failure_streak_lbl: Label = failure_overlay.get_node("Card/FailureBestStreakLabel") as Label
	var try_again_btn: Button = failure_overlay.get_node("Card/TryAgainButton") as Button

	assert(level_manager != null, "LevelManager must exist")

	# Accelerate animation delays for test suite execution speed
	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# --- TEST SCENARIOS A & B: MASTER POOL HAS EXACTLY 36 LEVELS (12 EASY, 12 MEDIUM, 12 HARD) ---
	print("\n[SCENARIO A & B] Verify master pool contains 36 levels (12 Easy, 12 Medium, 12 Hard)")
	assert(level_manager.levels.size() == 36, "Scenario A: Master pool must contain 36 loaded levels (found %d)" % level_manager.levels.size())

	var pool_t1: Array[LevelData] = []
	var pool_t2: Array[LevelData] = []
	var pool_t3: Array[LevelData] = []
	for lvl in level_manager.levels:
		match lvl.tier:
			1: pool_t1.append(lvl)
			2: pool_t2.append(lvl)
			3: pool_t3.append(lvl)

	assert(pool_t1.size() == 12, "Scenario B: Tier 1 pool must have 12 levels (found %d)" % pool_t1.size())
	assert(pool_t2.size() == 12, "Scenario B: Tier 2 pool must have 12 levels (found %d)" % pool_t2.size())
	assert(pool_t3.size() == 12, "Scenario B: Tier 3 pool must have 12 levels (found %d)" % pool_t3.size())

	# --- TEST SCENARIO F, G, H, I, J: VERIFY ALL NEW LEVELS (22-36) LOAD & PLAY CORRECTLY ---
	print("\n[SCENARIO F, G, H, I, J] Verify all new levels (22-36) mechanics, solutions & drops")
	for lvl_idx in range(22, 37):
		var path = "res://data/levels/level_%02d.tres" % lvl_idx
		var lvl: LevelData = load(path) as LevelData
		assert(lvl != null, "Level resource %s must exist" % path)

		level_manager.current_run_levels = [lvl]
		level_manager.current_lives = 3
		level_manager.current_streak = 0
		level_manager.load_level(0)
		await process_frame
		await _sync_physics()

		assert(prompt_lbl.text == lvl.prompt_text, "PromptLabel mismatch on Level %d" % lvl_idx)

		if lvl.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
			# Shape level drop test (Scenario J)
			assert(level_manager.shape_piece_a != null and level_manager.shape_piece_b != null, "Shape pieces missing on Level %d" % lvl_idx)
			level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
			await _sync_physics()
			level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
			await level_manager.level_completed
			assert(level_manager.is_completed, "Scenario J: Shape Level %d completed successfully" % lvl_idx)
		else:
			# Math-style level tests (Math Match, Missing Number, Equivalent Expression)
			assert(level_manager.math_pieces.size() == 4, "Must spawn 4 choice pieces on Level %d" % lvl_idx)

			# Test neutral drop (Scenario I) on first tested level
			if lvl_idx == 22:
				var p_neut = level_manager.math_pieces[0]
				p_neut.global_position = Vector2(100, 100)
				await _sync_physics()
				level_manager._on_math_piece_dropped(p_neut)
				p_neut._kill_active_tweens()
				await _sync_physics()
				assert(level_manager.current_lives == 3, "Scenario I: Neutral drop costs 0 lives")

			# Test deliberate wrong drop (Scenario H) on first tested level
			if lvl_idx == 22:
				var p_wrong: DraggablePiece = null
				for p in level_manager.math_pieces:
					if p.piece_text != lvl.correct_answer:
						p_wrong = p
						break
				assert(p_wrong != null)
				p_wrong.global_position = level_manager.math_target_zone.global_position
				await _sync_physics()
				level_manager._on_math_piece_dropped(p_wrong)
				p_wrong._kill_active_tweens()
				await _sync_physics()
				assert(level_manager.current_lives == 2, "Scenario H: Wrong deliberate drop costs 1 life")

			# Test correct drop (Scenario G)
			var p_correct: DraggablePiece = null
			for p in level_manager.math_pieces:
				if p.piece_text == lvl.correct_answer:
					p_correct = p
					break
			assert(p_correct != null, "Correct piece '%s' not found on Level %d" % [lvl.correct_answer, lvl_idx])
			p_correct.global_position = level_manager.math_target_zone.global_position
			await _sync_physics()
			level_manager._on_math_piece_dropped(p_correct)
			await level_manager.level_completed
			assert(level_manager.is_completed, "Scenario G: Level %d solved with '%s'" % [lvl_idx, lvl.correct_answer])

	# --- TEST SCENARIOS C, D, E, K: MULTI-RUN SAMPLING FROM 36-LEVEL POOL (5+5+5, NO DUPLICATES, ANTI-CLUMPING) ---
	print("\n[SCENARIO C, D, E, K] Multi-run sampling from 36-level pool: 5+5+5, no duplicates, anti-clumping")
	level_manager.levels = []
	level_manager._ensure_levels_loaded()
	level_manager.current_run_levels.clear()
	level_manager.previous_run_levels.clear()

	var prev_sampled_run: Array[LevelData] = []

	for iter in range(15):
		var run_seq: Array[LevelData] = level_manager.generate_run_sequence()
		assert(run_seq.size() == 15, "Scenario C: Run %d must contain exactly 15 levels" % (iter + 1))

		# Scenario D: Verify tier distribution
		for i in range(15):
			if i < 5:
				assert(run_seq[i].tier == 1, "Scenario D: Position %d must be Tier 1" % (i + 1))
			elif i < 10:
				assert(run_seq[i].tier == 2, "Scenario D: Position %d must be Tier 2" % (i + 1))
			else:
				assert(run_seq[i].tier == 3, "Scenario D: Position %d must be Tier 3" % (i + 1))

		# Scenario E: No duplicates within a single 15-level run
		var seen_levels: Dictionary = {}
		for lvl in run_seq:
			assert(not seen_levels.has(lvl), "Scenario E: Duplicate resource sampled in run %d!" % (iter + 1))
			seen_levels[lvl] = true
		assert(seen_levels.size() == 15, "15 distinct resources sampled from pool of 36")

		# Scenario K: Anti-clumping per tier slice
		var t1 = run_seq.slice(0, 5)
		var t2 = run_seq.slice(5, 10)
		var t3 = run_seq.slice(10, 15)
		assert(not level_manager._has_clump_of_three(t1), "Scenario K: Tier 1 anti-clumping violation in run %d" % (iter + 1))
		assert(not level_manager._has_clump_of_three(t2), "Scenario K: Tier 2 anti-clumping violation in run %d" % (iter + 1))
		assert(not level_manager._has_clump_of_three(t3), "Scenario K: Tier 3 anti-clumping violation in run %d" % (iter + 1))

		# Tier-start anti-repeat
		if not prev_sampled_run.is_empty():
			assert(run_seq[0] != prev_sampled_run[0], "Tier 1 start must differ from previous run")
			assert(run_seq[5] != prev_sampled_run[5], "Tier 2 start must differ from previous run")
			assert(run_seq[10] != prev_sampled_run[10], "Tier 3 start must differ from previous run")

		prev_sampled_run = run_seq.duplicate()

	# --- TEST SCENARIO N: UI RUN INDICATOR SHOWS Bölüm 1 / 15 THROUGH Bölüm 15 / 15 ---
	print("\n[SCENARIO N] Player-facing run indicator shows 'Bölüm 1 / 15' through 'Bölüm 15 / 15'")
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()
	assert(level_lbl.text == "Bölüm 1 / 15", "Scenario N: Indicator must show 'Bölüm 1 / 15' (got '%s')" % level_lbl.text)

	# --- TEST SCENARIO L: FAILURE / RETRY ON 36-LEVEL POOL ---
	print("\n[SCENARIO L] Failure & retry generates a valid 15-level run from 36-level pool")
	level_manager.current_lives = 1
	var fail_run = level_manager.current_run_levels.duplicate()

	# Generic deliberate wrong answer
	var cur_lvl = level_manager.current_level_data
	if cur_lvl.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
		level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
		var old_m = level_manager.shape_piece_a.match_id
		level_manager.shape_piece_a.match_id = "wrong_id"
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

	assert(level_manager.current_lives == 0, "Lives reach 0")
	assert(level_manager.is_run_failed, "is_run_failed must be true")

	if level_manager.failure_tween:
		await level_manager.failure_tween.finished
	await process_frame

	assert(failure_overlay.visible, "RunFailureOverlay visible")

	# Retry
	try_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Reset to position 0")
	assert(level_manager.current_lives == 3, "Lives reset to 3")
	assert(level_manager.current_run_levels.size() == 15, "Scenario L: Retry generates 15-level run")
	assert(not failure_overlay.visible, "Failure overlay hidden")

	# --- TEST SCENARIO M: RUN COMPLETE / PLAY AGAIN ON 36-LEVEL POOL ---
	print("\n[SCENARIO M] Solve 15 levels -> Run Complete -> Play Again generates fresh run")
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
			assert(cor_piece != null)
			cor_piece.global_position = level_manager.math_target_zone.global_position
			await _sync_physics()
			level_manager._on_math_piece_dropped(cor_piece)
		await level_manager.level_completed

	for pos in range(14):
		await solve_active_level.call()
		if level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	# Position 15 solve
	assert(level_manager.current_level_index == 14, "On Position 15")
	await solve_active_level.call()
	if level_manager.summary_tween:
		await level_manager.summary_tween.finished
	await process_frame

	assert(complete_overlay.visible, "RunCompleteOverlay visible")

	# Play Again
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Position 1")
	assert(level_manager.current_lives == 3, "Lives reset to 3")
	assert(level_manager.current_run_levels.size() == 15, "Scenario M: Play Again generates 15-level run")
	assert(not complete_overlay.visible, "Complete overlay hidden")

	print("\n>>> ALL STEP 12D AUTOMATED TESTS (SCENARIOS A - N) PASSED PERFECTLY! <<<\n")
	quit(0)





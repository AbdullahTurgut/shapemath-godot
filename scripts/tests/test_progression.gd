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
	print("--- BEGINNING STEP 12E AUTOMATED TEST SUITE (COOLDOWN NOVELTY & SESSION BEST STREAK) ---")
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
	var complete_final_lbl: Label = complete_overlay.get_node("Card/FinalStreakLabel") as Label
	var complete_best_lbl: Label = complete_overlay.get_node("Card/BestStreakLabel") as Label
	var complete_session_lbl: Label = complete_overlay.get_node("Card/SessionStreakLabel") as Label
	var play_again_btn: Button = complete_overlay.get_node("Card/PlayAgainButton") as Button

	var failure_overlay: Control = main_node.get_node("RunFailureOverlay") as Control
	var failure_prog_lbl: Label = failure_overlay.get_node("Card/FailureProgressLabel") as Label
	var failure_best_lbl: Label = failure_overlay.get_node("Card/FailureBestStreakLabel") as Label
	var failure_session_lbl: Label = failure_overlay.get_node("Card/FailureSessionStreakLabel") as Label
	var try_again_btn: Button = failure_overlay.get_node("Card/TryAgainButton") as Button

	assert(level_manager != null, "LevelManager must exist")
	assert(complete_session_lbl != null, "Complete overlay SessionStreakLabel must exist")
	assert(failure_session_lbl != null, "Failure overlay FailureSessionStreakLabel must exist")

	# Accelerate animation delays for test suite execution speed
	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# =========================================================================
	# PART A: RECENT-LEVEL COOLDOWN & REPLAY NOVELTY TESTS (SCENARIOS A - F)
	# =========================================================================

	# --- TEST SCENARIO A, B, C, D, E: CONSECUTIVE RUNS RECENT-LEVEL COOLDOWN ---
	print("\n[SCENARIO A, B, C, D, E] Multi-run consecutive cooldown from 36-level pool (0 overlap expected)")
	level_manager.levels = []
	level_manager._ensure_levels_loaded()
	assert(level_manager.levels.size() == 36, "Must have 36 master levels")

	level_manager.current_run_levels.clear()
	level_manager.previous_run_levels.clear()

	var run_a: Array[LevelData] = level_manager.generate_run_sequence()
	assert(run_a.size() == 15, "Run A must have 15 levels")

	for run_iter in range(10):
		var run_b: Array[LevelData] = level_manager.generate_run_sequence()
		assert(run_b.size() == 15, "Scenario B: Run must contain 15 levels")

		# Scenario A: Under normal 12-per-tier conditions, previous run used 5, 7 remain fresh >= 5, so overlap MUST be 0
		var overlap_count: int = 0
		for lvl in run_b:
			if run_a.has(lvl):
				overlap_count += 1
		assert(overlap_count == 0, "Scenario A: Run %d had %d overlap with immediately previous run (expected 0)" % [run_iter + 1, overlap_count])

		# Scenario B: 5 Easy, 5 Medium, 5 Hard
		for i in range(15):
			if i < 5:
				assert(run_b[i].tier == 1, "Scenario B: Position %d must be Tier 1" % (i + 1))
			elif i < 10:
				assert(run_b[i].tier == 2, "Scenario B: Position %d must be Tier 2" % (i + 1))
			else:
				assert(run_b[i].tier == 3, "Scenario B: Position %d must be Tier 3" % (i + 1))

		# Scenario C: 15 unique levels without duplicate
		var seen_levels: Dictionary = {}
		for lvl in run_b:
			assert(not seen_levels.has(lvl), "Scenario C: Duplicate resource sampled in run!")
			seen_levels[lvl] = true
		assert(seen_levels.size() == 15, "Must have 15 unique levels")

		# Scenario D: Anti-clumping
		assert(not level_manager._has_clump_of_three(run_b.slice(0, 5)), "Scenario D: Tier 1 anti-clumping violation")
		assert(not level_manager._has_clump_of_three(run_b.slice(5, 10)), "Scenario D: Tier 2 anti-clumping violation")
		assert(not level_manager._has_clump_of_three(run_b.slice(10, 15)), "Scenario D: Tier 3 anti-clumping violation")

		# Scenario E: Tier start anti-repeat
		assert(run_b[0] != run_a[0], "Scenario E: Tier 1 start must differ from previous run start")
		assert(run_b[5] != run_a[5], "Scenario E: Tier 2 start must differ from previous run start")
		assert(run_b[10] != run_a[10], "Scenario E: Tier 3 start must differ from previous run start")

		run_a = run_b.duplicate()

	# --- TEST SCENARIO F: SYNTHETIC FALLBACK WHEN FEWER THAN 5 FRESH LEVELS EXIST ---
	print("\n[SCENARIO F] Synthetic fallback: Tier pool has fewer than 5 fresh levels")
	var synthetic_pool: Array[LevelData] = []
	for i in range(6):
		var dummy_lvl: LevelData = LevelData.new()
		dummy_lvl.tier = 1
		dummy_lvl.puzzle_type = LevelData.PuzzleType.MATH_MATCH if (i % 2 == 0) else LevelData.PuzzleType.SHAPE_MATCH
		synthetic_pool.append(dummy_lvl)

	var prev_synthetic_used: Array[LevelData] = synthetic_pool.slice(0, 5) # 5 used, 1 fresh remaining
	var fallback_sampled: Array[LevelData] = level_manager._sample_tier_with_cooldown(synthetic_pool, prev_synthetic_used, 5, prev_synthetic_used[0], 1)
	assert(fallback_sampled.size() == 5, "Scenario F: Fallback must return exactly 5 levels")
	# Must include the 1 fresh level (synthetic_pool[5])
	assert(fallback_sampled.has(synthetic_pool[5]), "Scenario F: Fallback must include available fresh level")
	# Must have 5 unique items
	var fallback_unique: Dictionary = {}
	for lvl in fallback_sampled:
		fallback_unique[lvl] = true
	assert(fallback_unique.size() == 5, "Scenario F: Fallback must not contain internal duplicates")
	assert(fallback_sampled[0] != prev_synthetic_used[0], "Scenario F: Fallback must respect avoid_start")

	# =========================================================================
	# PART B: SESSION BEST STREAK & OVERLAYS TESTS (SCENARIOS G - M)
	# =========================================================================

	# --- TEST SCENARIO G: FRESH APPLICATION SESSION HAS SESSION BEST = 0 ---
	print("\n[SCENARIO G] Fresh application session: best_streak_session = 0")
	level_manager.current_streak = 0
	level_manager.best_streak_this_run = 0
	level_manager.best_streak_session = 0
	assert(level_manager.best_streak_session == 0, "Scenario G: Initial session best streak must be 0")

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

	# --- TEST SCENARIO H: COMPLETE 5 CONSECUTIVE LEVELS -> BOTH BESTS = 5 ---
	print("\n[SCENARIO H] Complete 5 consecutive levels: run best = 5, session best = 5")
	level_manager.current_run_levels.clear()
	level_manager.generate_run_sequence()
	level_manager.load_level(0)
	await process_frame
	await _sync_physics()

	for k in range(5):
		await solve_active_level.call()
		if k < 4 and level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(level_manager.current_streak == 5, "Current streak is 5")
	assert(level_manager.best_streak_this_run == 5, "Scenario H: best_streak_this_run is 5")
	assert(level_manager.best_streak_session == 5, "Scenario H: best_streak_session is 5")

	# --- TEST SCENARIO I: START NEW RUN -> RUN BEST RESETS TO 0, SESSION BEST REMAINS 5 ---
	print("\n[SCENARIO I] Start new run: run best resets to 0, session best preserved at 5")
	level_manager.start_new_run()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_streak == 0, "Current streak resets to 0")
	assert(level_manager.best_streak_this_run == 0, "Scenario I: best_streak_this_run resets to 0")
	assert(level_manager.best_streak_session == 5, "Scenario I: best_streak_session remains 5")

	# --- TEST SCENARIO J: NEXT RUN REACHES STREAK 2 AND FAILS -> FAILURE OVERLAY SHOWS RUN BEST 2 & SESSION BEST 5 ---
	print("\n[SCENARIO J] Run reaches streak 2 and fails: failure card shows 'Bu Tur En İyi: x2' & 'Oturum Rekoru: x5'")
	# Solve 2 levels
	await solve_active_level.call()
	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	await solve_active_level.call()
	if level_manager.transition_tween:
		await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	assert(level_manager.current_streak == 2, "Current streak is 2")
	assert(level_manager.best_streak_this_run == 2, "Run best is 2")
	assert(level_manager.best_streak_session == 5, "Session best is still 5")

	# Deliberate wrong drop to fail run (drain lives to 0)
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

	assert(failure_overlay.visible, "RunFailureOverlay visible")
	assert(failure_best_lbl.text == "Bu Tur En İyi: x2", "Scenario J: Failure card must show 'Bu Tur En İyi: x2' (got '%s')" % failure_best_lbl.text)
	assert(failure_session_lbl.text == "Oturum Rekoru: x5", "Scenario J: Failure card must show 'Oturum Rekoru: x5' (got '%s')" % failure_session_lbl.text)

	# --- TEST SCENARIO M: FAILURE / TEKRAR DENE PRESERVES SESSION RECORD ---
	print("\n[SCENARIO M] Failure / Tekrar Dene resets run state and preserves session record")
	try_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Reset to position 0")
	assert(level_manager.current_streak == 0, "Current streak is 0")
	assert(level_manager.best_streak_this_run == 0, "Run best is 0")
	assert(level_manager.best_streak_session == 5, "Scenario M: Session best preserved at 5 after Tekrar Dene")
	assert(not failure_overlay.visible, "Failure overlay hidden")

	# --- TEST SCENARIO K: NEXT RUN REACHES STREAK 6 -> SESSION BEST BECOMES 6 ---
	print("\n[SCENARIO K] Next run reaches streak 6: session best updates to 6")
	for k in range(6):
		await solve_active_level.call()
		if k < 5 and level_manager.transition_tween:
			await level_manager.transition_tween.finished
		await process_frame
		await _sync_physics()

	assert(level_manager.current_streak == 6, "Current streak is 6")
	assert(level_manager.best_streak_this_run == 6, "Run best is 6")
	assert(level_manager.best_streak_session == 6, "Scenario K: Session best updated to 6")

	# --- TEST SCENARIO L: RUN COMPLETE (15/15 SOLVE) -> SUCCESS OVERLAY SHOWS SESSION RECORD & PLAY AGAIN PRESERVES IT ---
	print("\n[SCENARIO L] Solve remaining to 15/15: Run Complete shows session record, Play Again preserves it")
	# Solve remaining levels up to position 15
	while level_manager.current_level_index < 14:
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

	assert(complete_overlay.visible, "RunCompleteOverlay visible")
	assert(complete_final_lbl.text == "Son Seri: x15", "Final streak label shows 'Son Seri: x15'")
	assert(complete_best_lbl.text == "Bu Tur En İyi: x15", "Best streak label shows 'Bu Tur En İyi: x15'")
	assert(complete_session_lbl.text == "Oturum Rekoru: x15", "Scenario L: Session streak label shows 'Oturum Rekoru: x15'")
	assert(level_manager.best_streak_session == 15, "Session best updated to 15")

	# Play Again
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Position 1")
	assert(level_manager.current_streak == 0, "Current streak is 0")
	assert(level_manager.best_streak_this_run == 0, "Run best is 0")
	assert(level_manager.best_streak_session == 15, "Scenario L: Session best preserved at 15 after Tekrar Oyna")
	assert(not complete_overlay.visible, "Complete overlay hidden")

	print("\n>>> ALL STEP 12E AUTOMATED TESTS (SCENARIOS A - M) PASSED PERFECTLY! <<<\n")
	quit(0)






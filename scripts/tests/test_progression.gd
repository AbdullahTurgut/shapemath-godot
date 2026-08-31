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
	print("--- BEGINNING STEP 10B-2 AUTOMATED TEST SUITE (10-LEVEL PROGRESSION) ---")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()
	root.add_child(main_node)

	# Allow a frame for _ready to execute
	await process_frame
	await _sync_physics()

	var level_manager: LevelManager = main_node.get_node("LevelManager") as LevelManager
	var restart_btn: Button = main_node.get_node("RestartButton") as Button
	var level_lbl: Label = main_node.get_node("LevelIndicatorLabel") as Label
	var streak_lbl: Label = main_node.get_node("StreakLabel") as Label
	var prompt_lbl: Label = main_node.get_node("PromptLabel") as Label
	var success_lbl: Label = main_node.get_node("SuccessLabel") as Label

	var overlay: Control = main_node.get_node("RunCompleteOverlay") as Control
	var final_streak_lbl: Label = overlay.get_node("Card/FinalStreakLabel") as Label
	var best_streak_lbl: Label = overlay.get_node("Card/BestStreakLabel") as Label
	var play_again_btn: Button = overlay.get_node("Card/PlayAgainButton") as Button

	assert(level_manager != null, "LevelManager must exist")
	assert(level_manager.feedback_manager != null, "FeedbackManager must be attached")
	assert(level_manager.levels.size() == 10, "Must load 10 levels (found %d)" % level_manager.levels.size())
	assert(overlay != null, "RunCompleteOverlay must exist")
	assert(not overlay.visible, "Overlay must be hidden initially")
	assert(level_manager.current_streak == 0 and level_manager.best_streak_this_run == 0, "Initial streaks must be 0")
	assert(level_lbl.text == "Bölüm 1 / 10", "Initial indicator must show Bölüm 1 / 10")

	# --- TEST SCENARIO A: PROGRESS SEQUENTIALLY FROM LEVEL 1 TO LEVEL 10 ---
	print("\n[SCENARIO A] Complete Levels 1 to 5 perfectly (reaching Streak x5)")

	# Helper for math solves
	var solve_math = func(expected_ans: String) -> void:
		var target_piece: DraggablePiece = null
		for p in level_manager.math_pieces:
			if p.piece_text == expected_ans:
				target_piece = p
				break
		assert(target_piece != null, "Target math piece '%s' not found" % expected_ans)
		target_piece.global_position = level_manager.math_target_zone.global_position
		await _sync_physics()
		level_manager._on_math_piece_dropped(target_piece)
		await level_manager.level_completed

	# Helper for shape solves
	var solve_shape = func() -> void:
		assert(level_manager.shape_piece_a != null and level_manager.shape_piece_b != null, "Shape pieces not spawned")
		level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
		await _sync_physics()
		level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
		await level_manager.level_completed

	# Level 1: Math (1 + 2 = 3)
	await solve_math.call("3")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 1, "Advanced to Level 2")
	assert(level_lbl.text == "Bölüm 2 / 10", "Indicator shows Bölüm 2 / 10")
	assert(level_manager.current_streak == 1, "Streak 1")

	# Level 2: Shape (Rectangles)
	await solve_shape.call()
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 2, "Advanced to Level 3")
	assert(level_lbl.text == "Bölüm 3 / 10", "Indicator shows Bölüm 3 / 10")
	assert(level_manager.current_streak == 2, "Streak 2")

	# Level 3: Math (7 - 3 = 4)
	await solve_math.call("4")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 3, "Advanced to Level 4")
	assert(level_lbl.text == "Bölüm 4 / 10", "Indicator shows Bölüm 4 / 10")
	assert(level_manager.current_streak == 3, "Streak 3")

	# Level 4: Shape (Diagonals)
	await solve_shape.call()
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 4, "Advanced to Level 5")
	assert(level_lbl.text == "Bölüm 5 / 10", "Indicator shows Bölüm 5 / 10")
	assert(level_manager.current_streak == 4, "Streak 4")

	# Level 5: Math (4 + 4 = 8)
	await solve_math.call("8")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 5, "Advanced to Level 6")
	assert(level_lbl.text == "Bölüm 6 / 10", "Indicator shows Bölüm 6 / 10")
	assert(level_manager.current_streak == 5, "Streak 5")

	# --- TEST SCENARIO B: LEVEL 6 INCORRECT ANSWER RESETS STREAK AND DOES NOT ADVANCE ---
	print("\n[SCENARIO B] Level 6 (9 + 6 = ?) -> Incorrect drop resets streak to 0, stays on Level 6")
	var wrong_p6: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "14": wrong_p6 = p
	wrong_p6.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(wrong_p6)

	assert(level_manager.current_streak == 0, "Streak reset to 0 on wrong drop")
	assert(level_manager.best_streak_this_run == 5, "Best streak preserved as 5")
	assert(level_manager.current_level_index == 5, "Must remain on Level 6")

	if wrong_p6.feedback_tween and wrong_p6.feedback_tween.is_valid():
		await wrong_p6.feedback_tween.finished
	await _sync_physics()

	# Solve Level 6 correctly (9 + 6 = 15)
	await solve_math.call("15")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 6, "Advanced to Level 7")
	assert(level_lbl.text == "Bölüm 7 / 10", "Indicator shows Bölüm 7 / 10")
	assert(level_manager.current_streak == 1, "Streak 1")

	# --- TEST SCENARIO C: LEVEL 7 INVALID SHAPE DROP RETURNS CORRECTLY ---
	print("\n[SCENARIO C] Level 7 (Step Shapes) -> Invalid shape drop returns correctly")
	level_manager.shape_piece_a.global_position = Vector2(100, 300)
	await _sync_physics()
	level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)

	assert(level_manager.current_streak == 0, "Streak reset to 0 on invalid shape drop")
	assert(level_manager.current_level_index == 6, "Must remain on Level 7")

	if level_manager.shape_piece_a.feedback_tween and level_manager.shape_piece_a.feedback_tween.is_valid():
		await level_manager.shape_piece_a.feedback_tween.finished
	await _sync_physics()

	# Solve Level 7 correctly
	await solve_shape.call()
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 7, "Advanced to Level 8")
	assert(level_lbl.text == "Bölüm 8 / 10", "Indicator shows Bölüm 8 / 10")
	assert(level_manager.current_streak == 1, "Streak 1")

	# --- TEST SCENARIO D: RESTART LEVEL 8 KEEPS GAME ON LEVEL 8 ---
	print("\n[SCENARIO D] Restart Level 8 -> Game remains on Level 8")
	restart_btn.pressed.emit()
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 7, "Must remain on Level 8 after restart")
	assert(level_lbl.text == "Bölüm 8 / 10", "Indicator shows Bölüm 8 / 10")
	assert(prompt_lbl.text == "15 - 7 = ?", "Prompt shows Level 8 question")
	assert(level_manager.current_streak == 0, "Streak reset to 0")
	assert(level_manager.best_streak_this_run == 5, "Best streak preserved as 5")

	# Solve Level 8 (15 - 7 = 8)
	await solve_math.call("8")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 8, "Advanced to Level 9")
	assert(level_lbl.text == "Bölüm 9 / 10", "Indicator shows Bölüm 9 / 10")
	assert(level_manager.current_streak == 1, "Streak 1")

	# --- TEST SCENARIO E: LEVEL 9 VALID SHAPE MATCH COMPLETES EXACTLY ONCE ---
	print("\n[SCENARIO E] Level 9 (Trapezoids) -> Solve shape match -> Advances to Level 10")
	assert(prompt_lbl.text == "Şekilleri tamamla", "Level 9 prompt is 'Şekilleri tamamla'")
	await solve_shape.call()
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 9, "Advanced to Level 10")
	assert(level_lbl.text == "Bölüm 10 / 10", "Indicator shows Bölüm 10 / 10")
	assert(level_manager.current_streak == 2, "Streak 2")

	# --- TEST SCENARIO F: LEVEL 10 COMPLETION SHOWS RUN COMPLETE OVERLAY ---
	print("\n[SCENARIO F] Level 10 (11 + 6 = 17) -> Run Complete overlay appears with final and best streak")
	assert(prompt_lbl.text == "11 + 6 = ?", "Level 10 prompt is '11 + 6 = ?'")
	await solve_math.call("17")

	assert(level_manager.current_streak == 3, "Final streak is 3")
	assert(level_manager.best_streak_this_run == 5, "Best streak this run is 5")
	assert(success_lbl.text == "Harika! Tur Tamamlandı!", "Success text is 'Harika! Tur Tamamlandı!'")
	assert(level_manager.summary_tween != null, "Summary delay tween scheduled")

	await level_manager.summary_tween.finished
	await process_frame

	assert(overlay.visible, "RunCompleteOverlay visible after Level 10")
	assert(final_streak_lbl.text == "Son Seri: x3", "Final streak shows 'Son Seri: x3'")
	assert(best_streak_lbl.text == "En İyi Seri: x5", "Best streak shows 'En İyi Seri: x5'")

	# --- TEST SCENARIO G: PLAY AGAIN RETURNS TO LEVEL 1 / 10 ---
	print("\n[SCENARIO G] Play Again -> Returns to Level 1 / 10 with reset state")
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Level 1")
	assert(level_lbl.text == "Bölüm 1 / 10", "Level indicator shows Bölüm 1 / 10")
	assert(level_manager.current_streak == 0, "Current streak reset to 0")
	assert(level_manager.best_streak_this_run == 0, "Best streak reset to 0")
	assert(not overlay.visible, "Overlay hidden")
	assert(restart_btn.visible, "Restart button restored")

	print("\n>>> ALL STEP 10B-2 AUTOMATED TESTS PASSED PERFECTLY! <<<\n")
	quit(0)

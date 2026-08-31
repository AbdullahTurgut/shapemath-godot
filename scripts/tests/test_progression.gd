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
	print("--- BEGINNING STEP 10B-3 AUTOMATED TEST SUITE (15-LEVEL PROGRESSION) ---")
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
	assert(level_manager.levels.size() == 15, "Must load 15 levels (found %d)" % level_manager.levels.size())
	assert(overlay != null, "RunCompleteOverlay must exist")
	assert(not overlay.visible, "Overlay must be hidden initially")
	assert(level_manager.current_streak == 0 and level_manager.best_streak_this_run == 0, "Initial streaks must be 0")
	assert(level_lbl.text == "Bölüm 1 / 15", "Initial indicator must show Bölüm 1 / 15")

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

	# --- TEST SCENARIO A & H: PERFECT RUN FROM LEVEL 1 TO LEVEL 15 (STREAK x15) ---
	print("\n[SCENARIO A & H] Solve Levels 1 to 10 sequentially")

	# Level 1: Math (1 + 2 = 3)
	await solve_math.call("3")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 1 and level_manager.current_streak == 1, "Level 2, Streak 1")

	# Level 2: Shape (Rectangles)
	await solve_shape.call()
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 2 and level_manager.current_streak == 2, "Level 3, Streak 2")

	# Level 3: Math (7 - 3 = 4)
	await solve_math.call("4")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 3 and level_manager.current_streak == 3, "Level 4, Streak 3")

	# Level 4: Shape (Diagonals)
	await solve_shape.call()
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 4 and level_manager.current_streak == 4, "Level 5, Streak 4")

	# Level 5: Math (4 + 4 = 8)
	await solve_math.call("8")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 5 and level_manager.current_streak == 5, "Level 6, Streak 5")

	# Level 6: Math (9 + 6 = 15)
	await solve_math.call("15")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 6 and level_manager.current_streak == 6, "Level 7, Streak 6")

	# Level 7: Shape (Steps)
	await solve_shape.call()
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 7 and level_manager.current_streak == 7, "Level 8, Streak 7")

	# Level 8: Math (15 - 7 = 8)
	await solve_math.call("8")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 8 and level_manager.current_streak == 8, "Level 9, Streak 8")

	# Level 9: Shape (Trapezoids)
	await solve_shape.call()
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 9 and level_manager.current_streak == 9, "Level 10, Streak 9")

	# Level 10: Math (11 + 6 = 17)
	await solve_math.call("17")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 10 and level_manager.current_streak == 10, "Level 11, Streak 10")
	assert(level_lbl.text == "Bölüm 11 / 15", "Indicator shows Bölüm 11 / 15")

	# --- TEST SCENARIO B: LEVEL 11 (12 + 8 = 20) ADVANCES TO LEVEL 12 ---
	print("\n[SCENARIO B] Level 11 (12 + 8 = 20) -> Solve correctly -> Advances to Level 12")
	assert(prompt_lbl.text == "12 + 8 = ?", "Prompt shows '12 + 8 = ?'")
	await solve_math.call("20")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 11, "Advanced to Level 12")
	assert(level_lbl.text == "Bölüm 12 / 15", "Indicator shows Bölüm 12 / 15")
	assert(level_manager.current_streak == 11, "Streak 11")

	# --- TEST SCENARIO C: LEVEL 12 (DIAMOND SHAPE) INVALID DROP + VALID ADVANCE ---
	print("\n[SCENARIO C] Level 12 (Diamond Shape) -> Invalid drop returns, valid drop advances")
	assert(prompt_lbl.text == "Şekli tamamla", "Level 12 prompt shows 'Şekli tamamla'")
	level_manager.shape_piece_a.global_position = Vector2(100, 300)
	await _sync_physics()
	level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)

	assert(level_manager.current_streak == 0, "Streak reset to 0 on invalid drop")
	assert(level_manager.best_streak_this_run == 11, "Best streak preserved as 11")
	assert(level_manager.current_level_index == 11, "Must remain on Level 12")

	if level_manager.shape_piece_a.feedback_tween and level_manager.shape_piece_a.feedback_tween.is_valid():
		await level_manager.shape_piece_a.feedback_tween.finished
	await _sync_physics()

	# Solve Level 12 correctly
	await solve_shape.call()
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 12, "Advanced to Level 13")
	assert(level_lbl.text == "Bölüm 13 / 15", "Indicator shows Bölüm 13 / 15")
	assert(level_manager.current_streak == 1, "Streak 1")

	# --- TEST SCENARIO D: RESTART LEVEL 13 KEEPS LEVEL 13 ACTIVE ---
	print("\n[SCENARIO D] Restart Level 13 -> Level 13 remains active")
	assert(prompt_lbl.text == "20 - 6 = ?", "Prompt shows '20 - 6 = ?'")
	restart_btn.pressed.emit()
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 12, "Must remain on Level 13 after restart")
	assert(level_lbl.text == "Bölüm 13 / 15", "Indicator shows Bölüm 13 / 15")
	assert(level_manager.current_streak == 0, "Streak reset to 0 on restart")
	assert(level_manager.best_streak_this_run == 11, "Best streak preserved as 11")

	# Solve Level 13 (20 - 6 = 14)
	await solve_math.call("14")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 13, "Advanced to Level 14")
	assert(level_lbl.text == "Bölüm 14 / 15", "Indicator shows Bölüm 14 / 15")
	assert(level_manager.current_streak == 1, "Streak 1")

	# --- TEST SCENARIO E: LEVEL 14 (L-BLOCK SHAPES) INVALID + VALID SOLVE ---
	print("\n[SCENARIO E] Level 14 (L-Blocks) -> Solve shape match -> Advances to Level 15")
	assert(prompt_lbl.text == "Parçaları eşleştir", "Level 14 prompt shows 'Parçaları eşleştir'")
	await solve_shape.call()
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 14, "Advanced to Level 15")
	assert(level_lbl.text == "Bölüm 15 / 15", "Indicator shows Bölüm 15 / 15")
	assert(level_manager.current_streak == 2, "Streak 2")

	# --- TEST SCENARIO F: LEVEL 15 WRONG ANSWER DOES NOT COMPLETE RUN ---
	print("\n[SCENARIO F] Level 15 (14 + 7 = ?) -> Wrong answer does not complete run")
	assert(prompt_lbl.text == "14 + 7 = ?", "Prompt shows '14 + 7 = ?'")
	var wrong_p15: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "20": wrong_p15 = p
	wrong_p15.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(wrong_p15)

	assert(level_manager.current_streak == 0, "Streak reset on wrong answer")
	assert(level_manager.current_level_index == 14, "Must remain on Level 15")
	assert(not overlay.visible, "Overlay must NOT appear on wrong answer")

	if wrong_p15.feedback_tween and wrong_p15.feedback_tween.is_valid():
		await wrong_p15.feedback_tween.finished
	await _sync_physics()

	# --- TEST SCENARIO G: LEVEL 15 ANSWER 21 COMPLETES RUN EXACTLY ONCE ---
	print("\n[SCENARIO G] Level 15 (14 + 7 = 21) -> Solve correctly -> Completes run")
	await solve_math.call("21")

	assert(level_manager.current_streak == 1, "Final streak is 1")
	assert(level_manager.best_streak_this_run == 11, "Best streak this run is 11")
	assert(success_lbl.text == "Harika! Tur Tamamlandı!", "Success label shows 'Harika! Tur Tamamlandı!'")
	assert(level_manager.summary_tween != null, "Summary delay tween scheduled")

	await level_manager.summary_tween.finished
	await process_frame

	assert(overlay.visible, "RunCompleteOverlay visible after Level 15")
	assert(final_streak_lbl.text == "Son Seri: x1", "Final streak shows 'Son Seri: x1'")
	assert(best_streak_lbl.text == "En İyi Seri: x11", "Best streak shows 'En İyi Seri: x11'")

	# --- TEST SCENARIO I: PLAY AGAIN RETURNS TO LEVEL 1 / 15 AND RESETS STATE ---
	print("\n[SCENARIO I] Play Again -> Returns to Level 1 / 15 with full run reset")
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Level 1")
	assert(level_lbl.text == "Bölüm 1 / 15", "Indicator shows Bölüm 1 / 15")
	assert(level_manager.current_streak == 0, "Current streak reset to 0")
	assert(level_manager.best_streak_this_run == 0, "Best streak reset to 0")
	assert(not overlay.visible, "Overlay hidden")
	assert(restart_btn.visible, "Restart button restored")

	print("\n>>> ALL STEP 10B-3 AUTOMATED TESTS PASSED PERFECTLY! <<<\n")
	quit(0)

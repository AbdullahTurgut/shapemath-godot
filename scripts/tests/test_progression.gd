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
	print("--- BEGINNING STEP 11A/11B AUTOMATED TEST SUITE (LIVES & RUN FAILURE) ---")
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

	# --- TEST SCENARIO A: NEW RUN STARTS WITH 3 LIVES ---
	print("\n[SCENARIO A] Verify initial state has 3 lives (♥ ♥ ♥)")
	assert(level_manager != null, "LevelManager must exist")
	assert(lives_lbl != null, "LivesLabel must exist")
	assert(failure_overlay != null, "RunFailureOverlay must exist")
	assert(not failure_overlay.visible, "Failure overlay must be hidden initially")
	assert(level_manager.current_lives == 3, "Initial lives must be 3")
	assert(lives_lbl.text == "♥ ♥ ♥", "Lives label must show ♥ ♥ ♥")
	assert(level_manager.current_streak == 0 and level_manager.best_streak_this_run == 0, "Initial streaks must be 0")
	assert(level_lbl.text == "Bölüm 1 / 15", "Indicator must show Bölüm 1 / 15")

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

	# --- TEST SCENARIO C: MATH PIECE DROPPED INTO EMPTY SPACE (CANCELLED DRAG) ---
	print("\n[SCENARIO C] Math piece dropped into empty space -> 0 life loss, 0 streak reset")
	var p_math_cancel: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "2": p_math_cancel = p
	p_math_cancel.global_position = Vector2(100, 300) # Neutral space
	await _sync_physics()
	level_manager._on_math_piece_dropped(p_math_cancel)

	assert(level_manager.current_lives == 3, "Lives must remain 3 on cancelled empty space drop")
	assert(lives_lbl.text == "♥ ♥ ♥", "Lives label must remain ♥ ♥ ♥")
	assert(level_manager.current_level_index == 0, "Must remain on Level 1")

	if p_math_cancel.feedback_tween and p_math_cancel.feedback_tween.is_valid():
		await p_math_cancel.feedback_tween.finished
	await _sync_physics()

	# --- TEST SCENARIO B: DELIBERATE WRONG MATH DROP ONTO TARGETZONE ---
	print("\n[SCENARIO B] Wrong math answer dropped onto TargetZone -> lose 1 life (3 -> 2, ♥ ♥ ♡), streak resets")
	p_math_cancel.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(p_math_cancel)

	assert(level_manager.current_lives == 2, "Lives must decrease to 2 on deliberate wrong drop")
	assert(lives_lbl.text == "♥ ♥ ♡", "Lives label must show ♥ ♥ ♡")
	assert(level_manager.current_streak == 0, "Streak must be 0")
	assert(level_manager.current_level_index == 0, "Must remain on Level 1")

	if p_math_cancel.feedback_tween and p_math_cancel.feedback_tween.is_valid():
		await p_math_cancel.feedback_tween.finished
	await _sync_physics()

	# Solve Level 1 correctly (1 + 2 = 3)
	await solve_math.call("3")
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 1, "Advanced to Level 2")
	assert(level_manager.current_lives == 2, "Lives remain 2 on correct solve")
	assert(level_manager.current_streak == 1 and level_manager.best_streak_this_run == 1, "Streak 1")

	# --- TEST SCENARIO E: SHAPE PIECE DROPPED IN EMPTY SPACE ---
	print("\n[SCENARIO E] Shape piece dropped in empty space -> 0 life loss")
	level_manager.shape_piece_a.global_position = Vector2(100, 300) # Neutral space
	await _sync_physics()
	level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)

	assert(level_manager.current_lives == 2, "Lives must remain 2 on empty space shape drop")
	assert(lives_lbl.text == "♥ ♥ ♡", "Lives label remains ♥ ♥ ♡")

	if level_manager.shape_piece_a.feedback_tween and level_manager.shape_piece_a.feedback_tween.is_valid():
		await level_manager.shape_piece_a.feedback_tween.finished
	await _sync_physics()

	# Solve Level 2 correctly
	await solve_shape.call()
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 2, "Advanced to Level 3")
	assert(level_manager.current_streak == 2 and level_manager.best_streak_this_run == 2, "Streak 2")

	# --- TEST SCENARIO D: WRONG DELIBERATE MATH/SHAPE MATCH (2ND LIFE LOSS) ---
	print("\n[SCENARIO D] Level 3 wrong answer (7 - 3 != 2) -> lose 2nd life (2 -> 1, ♥ ♡ ♡)")
	var wrong_p3: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "2": wrong_p3 = p
	wrong_p3.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(wrong_p3)

	assert(level_manager.current_lives == 1, "Lives must decrease to 1")
	assert(lives_lbl.text == "♥ ♡ ♡", "Lives label must show ♥ ♡ ♡")
	assert(level_manager.current_streak == 0, "Streak reset to 0")
	assert(level_manager.best_streak_this_run == 2, "Best streak preserved as 2")

	if wrong_p3.feedback_tween and wrong_p3.feedback_tween.is_valid():
		await wrong_p3.feedback_tween.finished
	await _sync_physics()

	# --- TEST SCENARIO F: 3RD DELIBERATE MISTAKE -> RUN FAILURE (1 -> 0, ♡ ♡ ♡) ---
	print("\n[SCENARIO F] 3rd deliberate mistake on Level 3 -> Lives 0, failure overlay appears")
	var wrong_p3_again: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "5": wrong_p3_again = p
	wrong_p3_again.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(wrong_p3_again)

	assert(level_manager.current_lives == 0, "Lives must be 0")
	assert(lives_lbl.text == "♡ ♡ ♡", "Lives label must show ♡ ♡ ♡")
	assert(level_manager.is_run_failed, "is_run_failed must be true")
	assert(level_manager.failure_tween != null, "Failure delay tween scheduled")

	await level_manager.failure_tween.finished
	await process_frame

	assert(failure_overlay.visible, "RunFailureOverlay must be visible")
	assert(failure_prog_lbl.text == "3 / 15 Bölüme Ulaştın", "Progress shows reached level (3 / 15 Bölüme Ulaştın)")
	assert(failure_streak_lbl.text == "En İyi Seri: x2", "Best streak shows En İyi Seri: x2")

	# --- TEST SCENARIO G: TEKRAR DENE ON FAILURE OVERLAY ---
	print("\n[SCENARIO G] Tekrar Dene -> Resets to Level 1 / 15, 3 lives (♥ ♥ ♥), streak 0, best 0")
	try_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Level 1")
	assert(level_lbl.text == "Bölüm 1 / 15", "Indicator shows Bölüm 1 / 15")
	assert(level_manager.current_lives == 3, "Lives reset to 3")
	assert(lives_lbl.text == "♥ ♥ ♥", "Lives label shows ♥ ♥ ♥")
	assert(level_manager.current_streak == 0, "Streak reset to 0")
	assert(level_manager.best_streak_this_run == 0, "Best streak reset to 0")
	assert(not failure_overlay.visible, "Failure overlay must be hidden")

	# --- TEST SCENARIO H & I: COMPLETE FULL 15-LEVEL RUN & PLAY AGAIN ---
	print("\n[SCENARIO H & I] Complete all 15 levels successfully -> Run Complete overlay -> Play Again resets lives")

	# Level 1 to 15 sequential solves
	await solve_math.call("3") # L1
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_shape.call()   # L2
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_math.call("4") # L3
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_shape.call()   # L4
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_math.call("8") # L5
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_math.call("15") # L6
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_shape.call()   # L7
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_math.call("8") # L8
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_shape.call()   # L9
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_math.call("17") # L10
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_math.call("20") # L11
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_shape.call()   # L12
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_math.call("14") # L13
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()
	await solve_shape.call()   # L14
	await level_manager.transition_tween.finished; await process_frame; await _sync_physics()

	# Level 15: Math (14 + 7 = 21)
	assert(level_manager.current_level_index == 14, "On Level 15")
	assert(level_manager.current_lives == 3, "Still has 3 lives on flawless run")
	await solve_math.call("21")

	await level_manager.summary_tween.finished
	await process_frame

	assert(complete_overlay.visible, "RunCompleteOverlay visible after Level 15")

	# Play Again after successful run
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Returned to Level 1")
	assert(level_manager.current_lives == 3, "Lives reset to 3 on Play Again")
	assert(lives_lbl.text == "♥ ♥ ♥", "Lives label shows ♥ ♥ ♥")
	assert(not complete_overlay.visible, "Complete overlay hidden")

	print("\n>>> ALL STEP 11A/11B AUTOMATED TESTS PASSED PERFECTLY! <<<\n")
	quit(0)

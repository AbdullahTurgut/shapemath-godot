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
	print("--- BEGINNING STEP 9E AUTOMATED TEST SUITE (END-OF-RUN SUMMARY & PLAY AGAIN) ---")
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
	assert(level_manager.feedback_manager != null, "FeedbackManager must be attached to LevelManager")
	assert(overlay != null, "RunCompleteOverlay must exist")
	assert(not overlay.visible, "Overlay must be hidden initially")
	assert(level_manager.current_streak == 0 and level_manager.best_streak_this_run == 0, "Initial streaks must be 0")

	# --- TEST SCENARIO A: COMPLETE ALL 5 LEVELS PERFECTLY (FINAL STREAK x5, BEST STREAK x5) ---
	print("\n[SCENARIO A] Complete 5 levels perfectly -> Final Streak x5, Best Streak x5 -> Overlay appears")
	# Level 1
	var p1: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "3": p1 = p
	p1.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(p1)
	await level_manager.level_completed
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 1, "Must advance to Level 2")
	assert(level_manager.current_streak == 1 and level_manager.best_streak_this_run == 1, "Streak 1")

	# Level 2
	level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
	await _sync_physics()
	level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
	await level_manager.level_completed
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 2, "Must advance to Level 3")
	assert(level_manager.current_streak == 2 and level_manager.best_streak_this_run == 2, "Streak 2")

	# Level 3
	var p3: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "4": p3 = p
	p3.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(p3)
	await level_manager.level_completed
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 3, "Must advance to Level 4")
	assert(level_manager.current_streak == 3 and level_manager.best_streak_this_run == 3, "Streak 3")

	# Level 4
	level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
	await _sync_physics()
	level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
	await level_manager.level_completed
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_level_index == 4, "Must advance to Level 5")
	assert(level_manager.current_streak == 4 and level_manager.best_streak_this_run == 4, "Streak 4")

	# Level 5
	var p5: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "8": p5 = p
	p5.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(p5)
	await level_manager.level_completed

	assert(level_manager.current_streak == 5, "Final streak must be 5")
	assert(level_manager.best_streak_this_run == 5, "Best streak must be 5")
	assert(level_manager.summary_tween != null, "Summary tween must be scheduled on Level 5")

	# Wait for summary delay (1.0s)
	await level_manager.summary_tween.finished
	await process_frame

	assert(overlay.visible, "RunCompleteOverlay must be visible after Level 5")
	assert(final_streak_lbl.text == "Son Seri: x5", "Final Streak must display 'Son Seri: x5'")
	assert(best_streak_lbl.text == "En İyi Seri: x5", "Best Streak must display 'En İyi Seri: x5'")
	assert(not restart_btn.visible, "Normal restart button must be hidden when overlay is active")
	assert(not prompt_lbl.visible, "Gameplay prompt must be hidden")

	# --- TEST SCENARIO D: PLAY AGAIN RESETS RUN TO LEVEL 1 (STREAK 0, BEST 0) ---
	print("\n[SCENARIO D] Play Again -> Level 1 loads, streak 0, best 0, overlay hidden")
	play_again_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.current_level_index == 0, "Must be back at Level 1")
	assert(level_lbl.text == "Bölüm 1 / 5", "Indicator must show Bölüm 1 / 5")
	assert(level_manager.current_streak == 0, "Current streak must reset to 0")
	assert(level_manager.best_streak_this_run == 0, "Best streak must reset to 0 for new run")
	assert(not overlay.visible, "Overlay must be hidden")
	assert(restart_btn.visible, "Restart button must be restored")
	assert(prompt_lbl.visible and prompt_lbl.text == "1 + 2 = ?", "Prompt must be restored")

	# --- TEST SCENARIO B: STREAK 2 -> INVALID ATTEMPT -> FINISH RUN (FINAL 3, BEST 3) ---
	print("\n[SCENARIO B] Solve Level 1 & 2 (Streak 2) -> Invalid on Level 3 -> Finish run -> Best streak remains accurate")
	# Level 1 correct -> streak 1
	for p in level_manager.math_pieces:
		if p.piece_text == "3": p1 = p
	p1.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(p1)
	await level_manager.level_completed
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()

	# Level 2 correct -> streak 2
	level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
	await _sync_physics()
	level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
	await level_manager.level_completed
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_streak == 2 and level_manager.best_streak_this_run == 2, "Streak 2, Best 2")

	# Level 3: Invalid drop -> resets current_streak to 0, best_streak stays 2!
	var wrong_p3: DraggablePiece = null
	for p in level_manager.math_pieces:
		if p.piece_text == "2": wrong_p3 = p
	wrong_p3.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(wrong_p3)

	assert(level_manager.current_streak == 0, "Current streak reset to 0")
	assert(level_manager.best_streak_this_run == 2, "Best streak must stay 2 despite mistake")

	if wrong_p3.feedback_tween and wrong_p3.feedback_tween.is_valid():
		await wrong_p3.feedback_tween.finished
	await _sync_physics()

	# Level 3 correct -> streak 1, best 2
	for p in level_manager.math_pieces:
		if p.piece_text == "4": p3 = p
	p3.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(p3)
	await level_manager.level_completed
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_streak == 1 and level_manager.best_streak_this_run == 2, "Streak 1, Best 2")

	# Level 4 correct -> streak 2, best 2
	level_manager.shape_piece_a.global_position = level_manager.shape_piece_b.global_position
	await _sync_physics()
	level_manager._on_shape_piece_dropped(level_manager.shape_piece_a)
	await level_manager.level_completed
	await level_manager.transition_tween.finished
	await process_frame
	await _sync_physics()
	assert(level_manager.current_streak == 2 and level_manager.best_streak_this_run == 2, "Streak 2, Best 2")

	# Level 5 correct -> streak 3, best 3!
	for p in level_manager.math_pieces:
		if p.piece_text == "8": p5 = p
	p5.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(p5)
	await level_manager.level_completed

	# --- TEST SCENARIO C: RESTART DURING LEVEL 5 COMPLETION DELAY CANCELS SUMMARY ---
	print("\n[SCENARIO C] Press Restart during Level 5 completion delay -> summary cancelled, Level 5 restarts")
	assert(level_manager.summary_tween != null and level_manager.summary_tween.is_valid(), "Summary tween scheduled")

	# Wait 0.3s (during 1.0s delay) and press Restart
	await create_tween().tween_interval(0.3).finished
	restart_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(level_manager.summary_tween == null, "Summary tween must be cancelled")
	assert(not overlay.visible, "Overlay must NOT appear")
	assert(level_manager.current_level_index == 4, "Must remain on Level 5")
	assert(level_manager.current_streak == 0, "Current streak reset on level restart")
	assert(level_manager.best_streak_this_run == 3, "Best streak preserved on level restart")

	# Complete Level 5 again to test Scenario E
	# --- TEST SCENARIO E: COMPLETE SECOND RUN -> SUMMARY APPEARS EXACTLY ONCE ---
	print("\n[SCENARIO E] Complete Level 5 after restart -> Summary appears cleanly")
	for p in level_manager.math_pieces:
		if p.piece_text == "8": p5 = p
	p5.global_position = level_manager.math_target_zone.global_position
	await _sync_physics()
	level_manager._on_math_piece_dropped(p5)
	await level_manager.level_completed

	assert(level_manager.current_streak == 1, "Streak is 1 after solve")
	assert(level_manager.best_streak_this_run == 3, "Best streak is 3")

	await level_manager.summary_tween.finished
	await process_frame

	assert(overlay.visible, "Overlay appears on completion")
	assert(final_streak_lbl.text == "Son Seri: x1", "Final Streak must be x1")
	assert(best_streak_lbl.text == "En İyi Seri: x3", "Best Streak must be x3")

	print("\n>>> ALL STEP 9E AUTOMATED TESTS PASSED PERFECTLY! <<<\n")
	quit(0)

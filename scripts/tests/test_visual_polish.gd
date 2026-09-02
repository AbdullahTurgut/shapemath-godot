extends SceneTree

const SaveManager = preload("res://scripts/core/save_manager.gd")
const LevelManager = preload("res://scripts/core/level_manager.gd")
const MainScene = preload("res://scenes/main.tscn")

var _tested: bool = false
var passed: int = 0
var failed: int = 0


func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	_run_tests()
	return false


func _sync_physics() -> void:
	await physics_frame
	await physics_frame


func assert_eq(actual, expected, test_name: String) -> void:
	if actual == expected:
		passed += 1
		print("  ✓ PASS: %s" % test_name)
	else:
		failed += 1
		print("  ✗ FAIL: %s | Expected: %s, Got: %s" % [test_name, str(expected), str(actual)])


func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		passed += 1
		print("  ✓ PASS: %s" % test_name)
	else:
		failed += 1
		print("  ✗ FAIL: %s | Expected: true, Got: false" % test_name)


func _run_tests() -> void:
	print("--- STARTING TEST SUITE: STEP 20 VISUAL POLISH PASS ---")

	test_draggable_piece_visual_tokens()
	test_draggable_piece_pickup_and_neutral_drop()
	test_draggable_piece_invalid_feedback()
	await test_main_menu_and_overlay_styles()
	await test_target_zone_and_particles()
	await test_run_state_visual_resets()
	await test_daily_button_cooldown_styling()

	print("\n==========================================")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [passed, failed])
	print("==========================================")

	if failed > 0:
		print("FAILED: Some visual polish tests failed!")
		quit(1)
	else:
		print("SUCCESS: All visual polish tests passed 100%!")
		quit(0)


func test_draggable_piece_visual_tokens() -> void:
	print("\n[TEST] DraggablePiece Visual Structure & Squircles")
	var piece_scene: PackedScene = load("res://scenes/pieces/draggable_piece.tscn")
	assert_true(piece_scene != null, "DraggablePiece scene loaded successfully")

	var piece: DraggablePiece = piece_scene.instantiate() as DraggablePiece
	root.add_child(piece)

	var visual: Polygon2D = piece.get_node_or_null("Visual") as Polygon2D
	var shadow: Polygon2D = piece.get_node_or_null("Shadow") as Polygon2D
	var border: Line2D = piece.get_node_or_null("Border") as Line2D
	var label: Label = piece.get_node_or_null("ValueLabel") as Label

	assert_true(visual != null, "DraggablePiece has Visual Polygon2D")
	assert_true(shadow != null, "DraggablePiece has Shadow Polygon2D underlay")
	assert_true(border != null, "DraggablePiece has Border Line2D outline")
	assert_true(label != null, "DraggablePiece has ValueLabel")

	assert_true(visual.polygon.size() >= 8, "Visual polygon is rounded squircle (>= 8 points)")
	assert_true(shadow.polygon.size() >= 8, "Shadow polygon is rounded squircle (>= 8 points)")
	assert_true(border.points.size() >= 9, "Border line is closed loop (>= 9 points)")

	piece.queue_free()


func test_draggable_piece_pickup_and_neutral_drop() -> void:
	print("\n[TEST] DraggablePiece Pickup Lift, Scale, & Neutral Return")
	var piece_scene: PackedScene = load("res://scenes/pieces/draggable_piece.tscn")
	var piece: DraggablePiece = piece_scene.instantiate() as DraggablePiece
	root.add_child(piece)

	piece.position = Vector2(300, 700)
	piece.set_origin_position(Vector2(300, 700))

	# Neutral drop return
	piece.is_dragging = false
	var neutral_tween: Tween = piece.return_neutral(0.01)
	assert_true(neutral_tween != null, "return_neutral produces valid tween")
	assert_true(piece.z_index == 2, "return_neutral sets z_index to 2")

	piece.queue_free()


func test_draggable_piece_invalid_feedback() -> void:
	print("\n[TEST] DraggablePiece Invalid Feedback & Reset")
	var piece_scene: PackedScene = load("res://scenes/pieces/draggable_piece.tscn")
	var piece: DraggablePiece = piece_scene.instantiate() as DraggablePiece
	root.add_child(piece)

	piece.position = Vector2(200, 500)
	piece.set_origin_position(Vector2(200, 500))

	var invalid_tween: Tween = piece.play_invalid_feedback()
	assert_true(invalid_tween != null, "play_invalid_feedback produces valid tween")
	assert_true(piece.z_index == 8, "Invalid feedback sets z_index to 8")
	assert_true(not piece.is_draggable, "Piece temporarily non-draggable during invalid animation")

	piece.reset_piece()
	assert_true(piece.is_draggable, "reset_piece restores is_draggable to true")
	assert_true(piece.input_pickable, "reset_piece restores input_pickable to true")
	assert_eq(piece.scale, Vector2.ONE, "reset_piece restores scale to Vector2.ONE")
	assert_eq(piece.modulate, Color.WHITE, "reset_piece restores modulate to Color.WHITE")

	piece.queue_free()


func test_main_menu_and_overlay_styles() -> void:
	print("\n[TEST] Main Menu & Overlay Button StyleBoxFlat Tokens")
	var main_node: Node2D = MainScene.instantiate() as Node2D
	root.add_child(main_node)
	await _sync_physics()

	var start_btn: Button = main_node.get_node_or_null("MainMenu/StartGameButton") as Button
	var daily_btn: Button = main_node.get_node_or_null("MainMenu/DailyChallengeButton") as Button
	var stats_btn: Button = main_node.get_node_or_null("MainMenu/StatisticsButton") as Button
	var settings_btn: Button = main_node.get_node_or_null("MainMenu/SettingsButton") as Button
	var exit_btn: Button = main_node.get_node_or_null("MainMenu/MenuExitButton") as Button

	assert_true(start_btn != null, "StartGameButton exists")
	assert_true(daily_btn != null, "DailyChallengeButton exists")
	assert_true(stats_btn != null, "StatisticsButton exists")
	assert_true(settings_btn != null, "SettingsButton exists")
	assert_true(exit_btn != null, "MenuExitButton exists")

	assert_true(start_btn.has_theme_stylebox_override("normal"), "StartGameButton has normal stylebox override")
	assert_true(start_btn.has_theme_stylebox_override("pressed"), "StartGameButton has pressed stylebox override")
	assert_true(daily_btn.has_theme_stylebox_override("normal"), "DailyChallengeButton has normal stylebox override")
	assert_true(daily_btn.has_theme_stylebox_override("disabled"), "DailyChallengeButton has disabled stylebox override")
	assert_true(stats_btn.has_theme_stylebox_override("normal"), "StatisticsButton has normal stylebox override")
	assert_true(settings_btn.has_theme_stylebox_override("normal"), "SettingsButton has normal stylebox override")
	assert_true(exit_btn.has_theme_stylebox_override("normal"), "MenuExitButton has normal stylebox override")

	var confirm_exit_btn: Button = main_node.get_node_or_null("ExitConfirmationOverlay/Card/ConfirmExitButton") as Button
	var cancel_exit_btn: Button = main_node.get_node_or_null("ExitConfirmationOverlay/Card/CancelButton") as Button
	var stats_close_btn: Button = main_node.get_node_or_null("StatisticsOverlay/Card/CloseButton") as Button
	var settings_close_btn: Button = main_node.get_node_or_null("SettingsOverlay/Card/CloseButton") as Button
	var play_again_btn: Button = main_node.get_node_or_null("RunCompleteOverlay/Card/PlayAgainButton") as Button
	var try_again_btn: Button = main_node.get_node_or_null("RunFailureOverlay/Card/TryAgainButton") as Button

	assert_true(confirm_exit_btn.has_theme_stylebox_override("normal"), "ConfirmExitButton has normal stylebox override")
	assert_true(cancel_exit_btn.has_theme_stylebox_override("normal"), "CancelButton has normal stylebox override")
	assert_true(stats_close_btn.has_theme_stylebox_override("normal"), "Statistics CloseButton has normal stylebox override")
	assert_true(settings_close_btn.has_theme_stylebox_override("normal"), "Settings CloseButton has normal stylebox override")
	assert_true(play_again_btn.has_theme_stylebox_override("normal"), "PlayAgainButton has normal stylebox override")
	assert_true(try_again_btn.has_theme_stylebox_override("normal"), "TryAgainButton has normal stylebox override")

	main_node.queue_free()


func test_target_zone_and_particles() -> void:
	print("\n[TEST] TargetZone Squircles & Particles")
	var main_node: Node2D = MainScene.instantiate() as Node2D
	root.add_child(main_node)
	await _sync_physics()

	var target_zone: Area2D = main_node.get_node_or_null("MathContainer/TargetZone") as Area2D
	assert_true(target_zone != null, "TargetZone Area2D exists")

	var border: Polygon2D = target_zone.get_node_or_null("Border") as Polygon2D
	var slot: Polygon2D = target_zone.get_node_or_null("Slot") as Polygon2D
	var label: Label = target_zone.get_node_or_null("PlaceholderLabel") as Label

	assert_true(border != null, "TargetZone Border exists")
	assert_true(slot != null, "TargetZone Slot exists")
	assert_true(label != null, "TargetZone PlaceholderLabel exists")

	assert_true(border.polygon.size() >= 8, "TargetZone Border polygon is squircle (>= 8 points)")
	assert_true(slot.polygon.size() >= 8, "TargetZone Slot polygon is squircle (>= 8 points)")

	var burst: CPUParticles2D = main_node.get_node_or_null("SuccessBurst") as CPUParticles2D
	assert_true(burst != null, "SuccessBurst CPUParticles2D exists")
	assert_true(burst.amount <= 16, "SuccessBurst amount is lightweight (<= 16 particles)")
	assert_true(burst.one_shot, "SuccessBurst is one_shot")
	assert_true(not burst.emitting, "SuccessBurst is not emitting on idle")

	var level_manager: LevelManager = main_node.get_node_or_null("LevelManager") as LevelManager
	assert_true(level_manager != null, "LevelManager exists")
	assert_eq(level_manager.success_burst, burst, "LevelManager has success_burst wired")

	main_node.queue_free()


func test_run_state_visual_resets() -> void:
	print("\n[TEST] Visual State Cleanup & Resets")
	var main_node: Node2D = MainScene.instantiate() as Node2D
	root.add_child(main_node)
	await _sync_physics()

	var level_manager: LevelManager = main_node.get_node_or_null("LevelManager") as LevelManager
	level_manager.start_new_run()

	assert_true(not level_manager.is_run_failed, "is_run_failed is false on new run")
	assert_true(not level_manager.is_run_completed, "is_run_completed is false on new run")
	assert_eq(level_manager.current_lives, level_manager.max_lives, "Lives reset to max on new run")
	assert_eq(level_manager.current_streak, 0, "Streak reset to 0 on new run")

	main_node.queue_free()


func test_daily_button_cooldown_styling() -> void:
	print("\n[TEST] Daily Button Cooldown Styling & Disabled State")
	var test_save_path: String = "user://test_save_visual_polish.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	var main_node: Node2D = MainScene.instantiate() as Node2D
	root.add_child(main_node)
	await _sync_physics()

	var daily_btn: Button = main_node.get_node_or_null("MainMenu/DailyChallengeButton") as Button
	var save_mgr: SaveManager = main_node.get_node_or_null("SaveManager") as SaveManager
	save_mgr.save_path = test_save_path

	# Simulate active cooldown
	var t0: int = int(Time.get_unix_time_from_system())
	save_mgr.record_daily_completed(true, 10, t0)
	main_node._refresh_main_menu()

	assert_true(daily_btn.disabled, "Daily button is disabled during active cooldown")
	assert_eq(daily_btn.text, "Günün Turu ✓", "Daily button text is 'Günün Turu ✓' during cooldown")

	# Simulate expired cooldown
	save_mgr.daily_next_available_at_unix = 0
	main_node._refresh_main_menu()

	assert_true(not daily_btn.disabled, "Daily button is enabled when cooldown is 0")
	assert_eq(daily_btn.text, "Günün Turu", "Daily button text is 'Günün Turu' when available")

	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	main_node.queue_free()

extends SceneTree

const SaveManager = preload("res://scripts/core/save_manager.gd")
const LevelManager = preload("res://scripts/core/level_manager.gd")
const LevelData = preload("res://scripts/resources/level_data.gd")
const MainScene = preload("res://scenes/main.tscn")

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
	print("--- BEGINNING STEP 19 RESPONSIVE ANDROID LAYOUT TEST SUITE ---")
	print("================================================================================")

	var test_save_path: String = "user://test_save_responsive.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	var main_scene = MainScene.instantiate()
	root.add_child(main_scene)
	await _sync_physics()

	var sm: SaveManager = main_scene.save_manager
	var lm: LevelManager = main_scene.level_manager
	sm.save_path = test_save_path
	sm.load_data()
	main_scene._refresh_main_menu()

	# Test Viewport Configurations
	var target_viewports: Array[Vector2] = [
		Vector2(720, 1280),  # 16:9 reference
		Vector2(1080, 1920), # 16:9 full HD (scales to 720x1280 in canvas items)
		Vector2(720, 1440),  # 18:9 (2:1)
		Vector2(720, 1560),  # 19.5:9 (e.g. 1080x2340 normalized)
		Vector2(720, 1600),  # 20:9 (e.g. 1080x2400 / 1440x3200 normalized)
		Vector2(960, 1280),  # 4:3 tablet portrait
	]

	# ================================================================================
	# TEST 1: VIEWPORT SANITY & FULLSCREEN BACKGROUNDS ACROSS ALL RATIOS
	# ================================================================================
	print("\n[TEST 1] Viewport Sanity, Safe Area & Fullscreen Backgrounds across 6 Aspect Ratios")

	for vp_size in target_viewports:
		print("   Testing viewport: %s (Aspect: %.2f:1)" % [str(vp_size), vp_size.y / vp_size.x])
		# Simulate viewport resize
		root.size = Vector2i(int(vp_size.x), int(vp_size.y))
		main_scene.update_responsive_layout()
		await _sync_physics()

		var actual_vp: Vector2 = main_scene.get_viewport_rect().size
		var safe_top: float = main_scene.get_safe_top_inset()
		assert(safe_top >= 24.0, "Safe top inset is at least 24px (was %.1f)" % safe_top)

		# Verify Fullscreen backgrounds and overlay roots
		var bg: ColorRect = main_scene.background
		assert(bg != null, "Background ColorRect exists")
		assert(bg.size.x >= actual_vp.x and bg.size.y >= actual_vp.y, "Main background covers full viewport")
		assert(bg.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Main background ignores mouse clicks")

		var menu: Control = main_scene.main_menu
		var menu_bg: ColorRect = menu.get_node("MenuBackground") as ColorRect
		assert(menu.size.x >= actual_vp.x and menu.size.y >= actual_vp.y, "MainMenu covers full viewport")
		assert(menu_bg.size.x >= actual_vp.x and menu_bg.size.y >= actual_vp.y, "MenuBackground covers full viewport")
		assert(menu_bg.mouse_filter == Control.MOUSE_FILTER_IGNORE, "MenuBackground ignores mouse clicks")

		# Overlays dim backgrounds
		for overlay_name in ["SettingsOverlay", "StatisticsOverlay", "RunCompleteOverlay", "RunFailureOverlay"]:
			var overlay: Control = main_scene.get_node(overlay_name) as Control
			assert(overlay != null, "%s exists" % overlay_name)
			assert(overlay.size.x >= actual_vp.x and overlay.size.y >= actual_vp.y, "%s covers full viewport" % overlay_name)
			var dim: ColorRect = overlay.get_node("DimBackground") as ColorRect
			assert(dim != null, "%s/DimBackground exists" % overlay_name)
			assert(dim.size.x >= actual_vp.x and dim.size.y >= actual_vp.y, "%s/DimBackground covers full viewport" % overlay_name)
			assert(dim.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s/DimBackground ignores mouse clicks" % overlay_name)

	print("-> TEST 1 PASSED: Fullscreen backgrounds, overlays, and safe area verified across all aspect ratios.")

	# ================================================================================
	# TEST 2: MAIN MENU CENTERING, VISIBILITY & TOUCH TARGET SIZES
	# ================================================================================
	print("\n[TEST 2] Main Menu Centering, Bounds & Touch Target Dimensions")

	var menu_buttons: Array[Button] = [
		main_scene.start_game_button,
		main_scene.daily_challenge_button,
		main_scene.statistics_button,
		main_scene.settings_button
	]

	for vp_size in target_viewports:
		root.size = Vector2i(int(vp_size.x), int(vp_size.y))
		main_scene.update_responsive_layout()
		await _sync_physics()

		var actual_vp: Vector2 = main_scene.get_viewport_rect().size

		# Check Main Menu elements
		var title_lbl: Label = main_scene.main_menu.get_node("TitleLabel") as Label
		var sub_lbl: Label = main_scene.main_menu.get_node("SubtitleLabel") as Label
		var pb_lbl: Label = main_scene.personal_best_label

		var menu_elements: Array[Control] = [title_lbl, sub_lbl, pb_lbl]
		menu_elements.append_array(menu_buttons)

		for elem in menu_elements:
			assert(elem != null, "Menu element exists")
			assert(elem.size.x > 0 and elem.size.y > 0, "Menu element has positive size")
			# Within visible viewport bounds
			assert(elem.position.y >= 0, "Menu element Y >= 0 (was %.1f on %s)" % [elem.position.y, str(vp_size)])
			assert(elem.position.y + elem.size.y <= actual_vp.y, "Menu element Y bottom <= vp.y (was %.1f + %.1f > %.1f on %s)" % [
				elem.position.y, elem.size.y, actual_vp.y, str(vp_size)
			])
			# Horizontally centered
			var elem_center_x: float = elem.position.x + elem.size.x * 0.5
			var vp_center_x: float = actual_vp.x * 0.5
			assert(absf(elem_center_x - vp_center_x) <= 2.0, "Menu element is horizontally centered (elem center: %.1f, vp center: %.1f)" % [elem_center_x, vp_center_x])

		# Verify button touch targets (min 48x48)
		for btn in menu_buttons:
			assert(btn.size.x >= 240.0, "Button width >= 240 (was %.1f)" % btn.size.x)
			assert(btn.size.y >= 60.0, "Button height >= 60 (was %.1f)" % btn.size.y)

	print("-> TEST 2 PASSED: Main Menu bounds, horizontal/vertical centering and touch targets verified.")

	# ================================================================================
	# TEST 3: TOP HUD POSITIONING & SAFE MARGIN
	# ================================================================================
	print("\n[TEST 3] Top Gameplay HUD Positioning & Safe Top Clearance")

	var level_lbl: Label = main_scene.get_node("LevelIndicatorLabel")
	var lives_lbl: Label = main_scene.get_node("LivesLabel")
	var streak_lbl: Label = main_scene.get_node("StreakLabel")
	var in_game_menu_btn: Button = main_scene.in_game_menu_button
	var top_title: Label = main_scene.get_node("TitleLabel")

	for vp_size in target_viewports:
		root.size = Vector2i(int(vp_size.x), int(vp_size.y))
		main_scene.update_responsive_layout()
		await _sync_physics()

		var actual_vp: Vector2 = main_scene.get_viewport_rect().size
		var safe_top: float = main_scene.get_safe_top_inset()

		assert(level_lbl.position.y >= safe_top, "Level label Y >= safe_top (was %.1f < %.1f)" % [level_lbl.position.y, safe_top])
		assert(lives_lbl.position.y >= safe_top, "Lives label Y >= safe_top")
		assert(in_game_menu_btn.position.y >= safe_top, "Menu button Y >= safe_top")
		assert(top_title.position.y > level_lbl.position.y, "Top title below HUD labels")

		assert(in_game_menu_btn.size.x >= 80.0 and in_game_menu_btn.size.y >= 50.0, "Menu button touch target >= 80x50")
		assert(in_game_menu_btn.position.x + in_game_menu_btn.size.x <= actual_vp.x, "Menu button within right edge")

	print("-> TEST 3 PASSED: Top HUD safe positioning and touch targets verified.")

	# ================================================================================
	# TEST 4: OVERLAY CARDS CENTERING & BOUNDS
	# ================================================================================
	print("\n[TEST 4] Overlay Cards Centering across all aspect ratios")

	var overlay_cards: Dictionary = {
		"SettingsOverlay": main_scene.settings_overlay.get_node("Card") as ColorRect,
		"StatisticsOverlay": main_scene.statistics_overlay.get_node("Card") as ColorRect,
		"RunCompleteOverlay": main_scene.run_complete_overlay.get_node("Card") as ColorRect,
		"RunFailureOverlay": main_scene.run_failure_overlay.get_node("Card") as ColorRect,
	}

	for vp_size in target_viewports:
		root.size = Vector2i(int(vp_size.x), int(vp_size.y))
		main_scene.update_responsive_layout()
		await _sync_physics()

		var actual_vp: Vector2 = main_scene.get_viewport_rect().size

		for overlay_name in overlay_cards:
			var card: ColorRect = overlay_cards[overlay_name]
			assert(card != null, "Card exists for %s" % overlay_name)
			assert(card.size.x > 0 and card.size.y > 0, "Card has positive dimensions")

			# Within viewport bounds
			assert(card.global_position.y >= 0, "%s Card Y >= 0 (was %.1f)" % [overlay_name, card.global_position.y])
			assert(card.global_position.y + card.size.y <= actual_vp.y, "%s Card bottom <= vp.y (was %.1f > %.1f on %s)" % [
				overlay_name, card.global_position.y + card.size.y, actual_vp.y, str(vp_size)
			])
			assert(card.global_position.x >= 0, "%s Card X >= 0" % overlay_name)
			assert(card.global_position.x + card.size.x <= actual_vp.x, "%s Card right <= vp.x" % overlay_name)

			# Centered in viewport
			var card_center: Vector2 = card.global_position + card.size * 0.5
			var vp_center: Vector2 = actual_vp * 0.5
			assert(absf(card_center.x - vp_center.x) <= 2.0, "%s Card is horizontally centered" % overlay_name)
			assert(absf(card_center.y - vp_center.y) <= 2.0, "%s Card is vertically centered (card center Y: %.1f, vp center Y: %.1f)" % [
				overlay_name, card_center.y, vp_center.y
			])

	print("-> TEST 4 PASSED: Overlay cards centering and bounds verified.")

	# ================================================================================
	# TEST 5: GAMEPLAY LIVE DRAG & DROP ON TALL VIEWPORT (20:9 / 720x1600)
	# ================================================================================
	print("\n[TEST 5] Live Gameplay Drag/Drop & Matching on Tall 20:9 Viewport (720x1600)")

	# Set tall viewport
	root.size = Vector2i(720, 1600)
	main_scene.update_responsive_layout()
	await _sync_physics()

	assert(lm.gameplay_y_offset > 0.0, "gameplay_y_offset is active on tall viewport (was %.1f)" % lm.gameplay_y_offset)

	# Start game
	main_scene.start_game_from_menu()
	await _sync_physics()

	assert(main_scene.current_state == main_scene.AppState.PLAYING, "State is PLAYING")
	assert(lm.current_run_levels.size() == 15, "Standard run has 15 levels")

	var solve_current := func():
		if lm.current_level_data.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
			lm._process_shape_success(lm.shape_piece_a, lm.shape_piece_b)
		else:
			var target_p: DraggablePiece = null
			for p in lm.math_pieces:
				if p.piece_text == lm.current_level_data.correct_answer:
					target_p = p
					break
			assert(target_p != null, "Found correct answer piece")
			target_p.reset_piece()
			target_p.global_position = lm.math_target_zone.global_position
			await _sync_physics()
			lm._on_math_piece_dropped(target_p)

	# Test Level 1 (Math Match) on 720x1600
	var initial_target_y: float = lm.math_target_zone.position.y
	assert(initial_target_y == 540.0 + lm.gameplay_y_offset, "TargetZone Y position incorporates gameplay_y_offset")

	# Test neutral drop
	var first_piece: DraggablePiece = lm.math_pieces[0]
	first_piece.global_position = Vector2(100, 100) # Off-target
	await _sync_physics()
	lm._on_math_piece_dropped(first_piece)
	assert(lm.current_lives == 3, "Neutral drop cost no lives")

	# Solve Level 1
	await solve_current.call()
	var t: float = 2.0
	while lm.current_level_index == 0 and t > 0.0:
		await process_frame
		await _sync_physics()
		t -= 0.016
	assert(lm.current_level_index == 1, "Level 1 solved and advanced on tall viewport")

	# Find and test a Shape Match level
	var shape_lvl_idx: int = -1
	for i in range(lm.current_run_levels.size()):
		if lm.current_run_levels[i].puzzle_type == LevelData.PuzzleType.SHAPE_MATCH:
			shape_lvl_idx = i
			break

	if shape_lvl_idx != -1:
		lm.load_level(shape_lvl_idx)
		await _sync_physics()
		assert(lm.current_level_data.puzzle_type == LevelData.PuzzleType.SHAPE_MATCH, "Loaded shape level")
		assert(lm.shape_piece_a != null and lm.shape_piece_b != null, "Shape pieces spawned")
		assert(lm.shape_piece_a.original_position.y == lm.current_level_data.shape_a_spawn_pos.y + lm.gameplay_y_offset, "Shape piece A spawn incorporates offset")
		assert(lm.shape_piece_b.original_position.y == lm.current_level_data.shape_b_spawn_pos.y + lm.gameplay_y_offset, "Shape piece B spawn incorporates offset")

		# Solve shape match
		await solve_current.call()
		await _sync_physics()
		assert(lm.is_completed == true, "Shape match solved successfully on tall viewport")

	# ================================================================================
	# TEST 6: MAIN MENU EXIT BUTTON & CONFIRMATION OVERLAY (STEP 19.1)
	# ================================================================================
	print("\n[TEST 6] Main Menu Exit Button & Confirmation Overlay (Step 19.1)")

	var exit_btn: Button = main_scene.menu_exit_button
	var exit_overlay: Control = main_scene.exit_confirmation_overlay
	var exit_card: ColorRect = exit_overlay.get_node("Card") as ColorRect
	var exit_dim: ColorRect = exit_overlay.get_node("DimBackground") as ColorRect
	var cancel_btn: Button = main_scene.exit_cancel_button
	var confirm_btn: Button = main_scene.exit_confirm_button

	assert(exit_btn != null, "MenuExitButton exists")
	assert(exit_overlay != null, "ExitConfirmationOverlay exists")
	assert(exit_card != null, "ExitConfirmationOverlay Card exists")
	assert(exit_dim != null, "ExitConfirmationOverlay DimBackground exists")
	assert(cancel_btn != null, "CancelButton exists")
	assert(confirm_btn != null, "ConfirmExitButton exists")

	# 1. Responsive bounds across all 6 aspect ratios
	for vp_size in target_viewports:
		root.size = Vector2i(int(vp_size.x), int(vp_size.y))
		main_scene.update_responsive_layout()
		await _sync_physics()

		var actual_vp: Vector2 = main_scene.get_viewport_rect().size
		var safe_top: float = main_scene.get_safe_top_inset()

		# Exit button position and size
		assert(exit_btn.size.x >= 48.0 and exit_btn.size.y >= 48.0, "Exit button touch target >= 48x48 (was %.1fx%.1f)" % [exit_btn.size.x, exit_btn.size.y])
		assert(exit_btn.position.y >= safe_top, "Exit button Y >= safe_top (was %.1f < %.1f on %s)" % [exit_btn.position.y, safe_top, str(vp_size)])
		assert(exit_btn.position.x + exit_btn.size.x <= actual_vp.x, "Exit button within right edge (was %.1f > %.1f)" % [exit_btn.position.x + exit_btn.size.x, actual_vp.x])

		# Confirmation Dim and Card
		assert(exit_dim.size.x >= actual_vp.x and exit_dim.size.y >= actual_vp.y, "Exit DimBackground covers full viewport")
		var card_center: Vector2 = exit_card.global_position + exit_card.size * 0.5
		var vp_center: Vector2 = actual_vp * 0.5
		assert(absf(card_center.x - vp_center.x) <= 2.0, "Exit Card is horizontally centered")
		assert(absf(card_center.y - vp_center.y) <= 2.0, "Exit Card is vertically centered")

		# Touch target sizes for confirmation buttons
		assert(cancel_btn.size.x >= 120.0 and cancel_btn.size.y >= 48.0, "Cancel button touch target >= 120x48")
		assert(confirm_btn.size.x >= 120.0 and confirm_btn.size.y >= 48.0, "Confirm button touch target >= 120x48")

	# 2. Main Menu vs Gameplay Visibility
	root.size = Vector2i(720, 1280)
	main_scene.update_responsive_layout()
	main_scene._show_main_menu()
	await _sync_physics()

	assert(main_scene.main_menu.visible == true, "Main Menu is visible")
	assert(exit_overlay.visible == false, "Exit Confirmation is initially hidden")

	# Start gameplay -> Main Menu and exit button hidden
	main_scene.start_game_from_menu()
	await _sync_physics()
	assert(main_scene.main_menu.visible == false, "Main Menu hidden during gameplay")
	assert(exit_overlay.visible == false, "Exit Confirmation hidden during gameplay")

	# Return to Main Menu -> Exit button available
	main_scene.return_to_main_menu()
	await _sync_physics()
	assert(main_scene.main_menu.visible == true, "Main Menu visible after return")

	# 3. Open Exit Confirmation via X button
	main_scene._on_menu_exit_pressed()
	assert(exit_overlay.visible == true, "Exit Confirmation is visible after tapping X")

	# 4. Cancel button closes confirmation
	main_scene._on_exit_cancel_pressed()
	assert(exit_overlay.visible == false, "Exit Confirmation closed after Vazgeç")

	# 5. Mutual exclusion with Settings and Statistics
	main_scene._on_menu_exit_pressed()
	assert(exit_overlay.visible == true, "Exit Confirmation reopened")
	main_scene._on_statistics_button_pressed()
	assert(main_scene.statistics_overlay.visible == true, "Statistics overlay opened")
	assert(exit_overlay.visible == false, "Exit Confirmation closed when opening Statistics")
	main_scene._on_statistics_close_pressed()

	main_scene._on_menu_exit_pressed()
	assert(exit_overlay.visible == true, "Exit Confirmation reopened")
	main_scene._on_settings_button_pressed()
	assert(main_scene.settings_overlay.visible == true, "Settings overlay opened")
	assert(exit_overlay.visible == false, "Exit Confirmation closed when opening Settings")
	main_scene._on_settings_close_pressed()

	# 6. Android Back Routing with Exit Confirmation
	main_scene._on_menu_exit_pressed()
	assert(exit_overlay.visible == true, "Exit Confirmation opened")
	var quit_called_count: Array[int] = [0]
	main_scene.quit_handler = func(): quit_called_count[0] += 1

	# Android Back closes Exit Confirmation first without quitting
	main_scene._handle_back_request()
	assert(exit_overlay.visible == false, "Android Back closed Exit Confirmation")
	assert(quit_called_count[0] == 0, "Android Back did NOT quit app while Exit Confirmation was open")

	# Android Back on Main Menu (no overlay) calls quit handler
	main_scene._handle_back_request()
	assert(quit_called_count[0] == 1, "Android Back on Main Menu triggered quit handler")

	# 7. Confirm Exit Button triggers quit handler
	main_scene._on_menu_exit_pressed()
	assert(exit_overlay.visible == true, "Exit Confirmation opened")
	main_scene._on_exit_confirm_pressed()
	assert(quit_called_count[0] == 2, "Çıkış button triggered quit handler")

	print("-> TEST 6 PASSED: Main Menu Exit Button, Confirmation Overlay, safe-area bounds, and back routing verified.")

	main_scene.queue_free()
	print("-> TEST 5 PASSED: Live gameplay drag/drop, target detection, and shape matching verified on 20:9 viewport.")

	# Cleanup test save
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	print("\n================================================================================")
	print("--- ALL STEP 19 & 19.1 RESPONSIVE LAYOUT TESTS PASSED (100%) ---")
	print("================================================================================")
	quit()


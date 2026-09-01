extends SceneTree

const SaveManager = preload("res://scripts/core/save_manager.gd")

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
	print("--- BEGINNING STEP 13C AUTOMATED TEST SUITE (SETTINGS OVERLAY & SOUND/HAPTIC TOGGLES) ---")

	# Define isolated test save path
	var test_save_path: String = "user://test_save_13c.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	# Pre-populate test save with sound=false, haptics=true, personal_best=8
	var sm_setup := SaveManager.new()
	sm_setup.save_path = test_save_path
	sm_setup.sound_enabled = false
	sm_setup.haptics_enabled = true
	sm_setup.personal_best_streak = 8
	sm_setup.save_data()

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_node: Node2D = main_scene.instantiate()

	# Point SaveManager to isolated test path before adding to tree
	var save_manager: SaveManager = main_node.get_node("SaveManager") as SaveManager
	save_manager.save_path = test_save_path

	root.add_child(main_node)

	# Allow a frame for _ready to execute
	await process_frame
	await _sync_physics()

	var feedback_manager: FeedbackManager = main_node.get_node("FeedbackManager") as FeedbackManager
	var level_manager: LevelManager = main_node.get_node("LevelManager") as LevelManager
	var main_menu: Control = main_node.get_node("MainMenu") as Control
	var start_btn: Button = main_menu.get_node("StartGameButton") as Button
	var settings_btn: Button = main_menu.get_node("SettingsButton") as Button

	var settings_overlay: Control = main_node.get_node("SettingsOverlay") as Control
	var settings_card: Control = settings_overlay.get_node("Card") as Control
	var sound_toggle_btn: Button = settings_card.get_node("SoundToggleButton") as Button
	var haptics_toggle_btn: Button = settings_card.get_node("HapticsToggleButton") as Button
	var close_btn: Button = settings_card.get_node("CloseButton") as Button

	var level_lbl: Label = main_node.get_node("LevelIndicatorLabel") as Label
	var lives_lbl: Label = main_node.get_node("LivesLabel") as Label
	var prompt_lbl: Label = main_node.get_node("PromptLabel") as Label

	assert(main_menu != null, "MainMenu must exist")
	assert(settings_btn != null, "SettingsButton must exist")
	assert(settings_overlay != null, "SettingsOverlay must exist")
	assert(sound_toggle_btn != null, "SoundToggleButton must exist")
	assert(haptics_toggle_btn != null, "HapticsToggleButton must exist")
	assert(close_btn != null, "CloseButton must exist")

	# Accelerate animation delays for test suite execution speed
	level_manager.transition_delay = 0.01
	level_manager.summary_delay = 0.01
	level_manager.failure_delay = 0.01

	# --- TEST SCENARIO A & B: MAIN MENU LAUNCH & SETTINGS BUTTON VISIBILITY ---
	print("\n[SCENARIO A & B] App launches into Main Menu with visible Ayarlar button")
	assert(main_menu.visible == true, "Scenario A: Main Menu visible on launch")
	assert(settings_btn.visible == true, "Scenario B: Settings button visible on Main Menu")
	assert(settings_btn.text == "Ayarlar", "Scenario B: Settings button text is 'Ayarlar'")
	assert(settings_overlay.visible == false, "Scenario A: Settings overlay hidden on launch")

	# --- TEST SCENARIO C & D: OPEN SETTINGS OVERLAY & VERIFY LOADED STATE ---
	print("\n[SCENARIO C & D] Tap Ayarlar -> SettingsOverlay opens and displays loaded state (Ses: Kapalı, Titreşim: Açık)")
	settings_btn.pressed.emit()
	await process_frame

	assert(settings_overlay.visible == true, "Scenario C: SettingsOverlay is visible")
	assert(sound_toggle_btn.text == "Kapalı", "Scenario D: Sound toggle reflects persisted false ('Kapalı')")
	assert(haptics_toggle_btn.text == "Açık", "Scenario D: Haptics toggle reflects persisted true ('Açık')")

	# --- TEST SCENARIO E: TOGGLE SOUND OFF -> ON ---
	print("\n[SCENARIO E] Toggle Sound OFF -> ON updates runtime and save immediately")
	sound_toggle_btn.pressed.emit()
	await process_frame

	assert(feedback_manager.sound_enabled == true, "Scenario E: FeedbackManager.sound_enabled is true")
	assert(save_manager.get_sound_enabled() == true, "Scenario E: SaveManager.sound_enabled is true")
	assert(sound_toggle_btn.text == "Açık", "Scenario E: Sound toggle button text is 'Açık'")

	# --- TEST SCENARIO F: TOGGLE SOUND ON -> OFF ---
	print("\n[SCENARIO F] Toggle Sound ON -> OFF updates runtime and save immediately")
	sound_toggle_btn.pressed.emit()
	await process_frame

	assert(feedback_manager.sound_enabled == false, "Scenario F: FeedbackManager.sound_enabled is false")
	assert(save_manager.get_sound_enabled() == false, "Scenario F: SaveManager.sound_enabled is false")
	assert(sound_toggle_btn.text == "Kapalı", "Scenario F: Sound toggle button text is 'Kapalı'")

	# --- TEST SCENARIO G: TOGGLE HAPTICS INDEPENDENTLY ---
	print("\n[SCENARIO G] Toggle Haptics ON -> OFF updates runtime and save independently")
	haptics_toggle_btn.pressed.emit()
	await process_frame

	assert(feedback_manager.haptics_enabled == false, "Scenario G: FeedbackManager.haptics_enabled is false")
	assert(save_manager.get_haptics_enabled() == false, "Scenario G: SaveManager.haptics_enabled is false")
	assert(haptics_toggle_btn.text == "Kapalı", "Scenario G: Haptics toggle button text is 'Kapalı'")

	# --- TEST SCENARIO H: INDEPENDENT TOGGLES ---
	print("\n[SCENARIO H] Verify sound and haptic toggles are completely independent")
	haptics_toggle_btn.pressed.emit() # Haptics -> ON
	await process_frame

	assert(feedback_manager.sound_enabled == false, "Scenario H: Sound remains false")
	assert(feedback_manager.haptics_enabled == true, "Scenario H: Haptics became true")
	assert(sound_toggle_btn.text == "Kapalı", "Scenario H: Sound text remains 'Kapalı'")
	assert(haptics_toggle_btn.text == "Açık", "Scenario H: Haptics text became 'Açık'")

	# --- TEST SCENARIO I: PERSISTENCE SURVIVES RELOAD ---
	print("\n[SCENARIO I] Fresh SaveManager loads persisted toggles from disk")
	var sm_disk := SaveManager.new()
	sm_disk.save_path = test_save_path
	sm_disk.load_data()
	assert(sm_disk.get_sound_enabled() == false, "Scenario I: Persisted sound is false")
	assert(sm_disk.get_haptics_enabled() == true, "Scenario I: Persisted haptics is true")
	assert(sm_disk.get_personal_best_streak() == 8, "Scenario O: Persisted personal best remains 8")

	# --- TEST SCENARIO J, K, L: CLOSE SETTINGS OVERLAY ---
	print("\n[SCENARIO J, K, L] Tap Kapat -> closes SettingsOverlay, MainMenu remains, no gameplay run started")
	close_btn.pressed.emit()
	await process_frame

	assert(settings_overlay.visible == false, "Scenario J: SettingsOverlay hidden after Kapat")
	assert(main_menu.visible == true, "Scenario J: MainMenu remains visible")
	assert(level_manager.current_level_data == null, "Scenario K: No run started during settings operations")
	assert(prompt_lbl.visible == false, "Scenario L: Gameplay prompt hidden while on Main Menu")
	assert(level_lbl.visible == false, "Scenario L: Level indicator hidden while on Main Menu")
	assert(lives_lbl.visible == false, "Scenario L: Lives label hidden while on Main Menu")

	# --- TEST SCENARIO M, N, O: START GAMEPLAY AFTER SETTINGS ---
	print("\n[SCENARIO M, N, O] Start gameplay after settings: valid 15-level run generated, interactive and functional")
	start_btn.pressed.emit()
	await process_frame
	await _sync_physics()

	assert(main_menu.visible == false, "Scenario M: MainMenu hidden after start")
	assert(settings_overlay.visible == false, "Scenario M: SettingsOverlay hidden after start")
	assert(prompt_lbl.visible == true, "Scenario M: Gameplay prompt visible")
	assert(level_lbl.visible == true, "Scenario M: Level indicator visible")
	assert(level_manager.current_lives == 3, "Scenario M: Lives = 3")
	assert(level_manager.current_streak == 0, "Scenario M: Streak = 0")
	assert(level_manager.current_run_levels.size() == 15, "Scenario M: 15 levels generated")
	assert(level_manager.levels.size() == 36, "Scenario N: 36 master levels intact")

	# Solve Level 1
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

	assert(level_manager.current_streak == 1, "Scenario N: Streak increments to 1 on solve")

	# Clean up test save file
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

	print("\n>>> ALL STEP 13C AUTOMATED TESTS (SCENARIOS A - O) PASSED PERFECTLY! <<<\n")
	quit(0)









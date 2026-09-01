extends Node2D

enum AppState {
	MAIN_MENU,
	PLAYING,
}

enum SettingsOrigin {
	MAIN_MENU,
	GAMEPLAY,
}

var current_state: AppState = AppState.MAIN_MENU
var settings_origin: SettingsOrigin = SettingsOrigin.MAIN_MENU

@onready var save_manager: SaveManager = $SaveManager
@onready var feedback_manager: FeedbackManager = $FeedbackManager
@onready var level_manager: LevelManager = $LevelManager
@onready var main_menu: Control = $MainMenu
@onready var personal_best_label: Label = $MainMenu/PersonalBestLabel
@onready var start_game_button: Button = $MainMenu/StartGameButton
@onready var settings_button: Button = $MainMenu/SettingsButton
@onready var in_game_menu_button: Button = $InGameMenuButton
@onready var settings_overlay: Control = $SettingsOverlay
@onready var sound_toggle_button: Button = $SettingsOverlay/Card/SoundToggleButton
@onready var haptics_toggle_button: Button = $SettingsOverlay/Card/HapticsToggleButton
@onready var settings_return_button: Button = $SettingsOverlay/Card/ReturnToMenuButton
@onready var settings_close_button: Button = $SettingsOverlay/Card/CloseButton
@onready var next_button: Button = $NextButton
@onready var play_again_button: Button = $RunCompleteOverlay/Card/PlayAgainButton
@onready var complete_menu_button: Button = $RunCompleteOverlay/Card/CompleteMenuButton
@onready var try_again_button: Button = $RunFailureOverlay/Card/TryAgainButton
@onready var failure_menu_button: Button = $RunFailureOverlay/Card/FailureMenuButton


func _ready() -> void:
	if save_manager:
		save_manager.load_data()
		if feedback_manager:
			feedback_manager.sound_enabled = save_manager.get_sound_enabled()
			feedback_manager.haptics_enabled = save_manager.get_haptics_enabled()
		if level_manager:
			level_manager.save_manager = save_manager
			level_manager.personal_best_streak = save_manager.get_personal_best_streak()

	if start_game_button and not start_game_button.pressed.is_connected(start_game_from_menu):
		start_game_button.pressed.connect(start_game_from_menu)
	if settings_button and not settings_button.pressed.is_connected(_on_settings_button_pressed):
		settings_button.pressed.connect(_on_settings_button_pressed)
	if in_game_menu_button and not in_game_menu_button.pressed.is_connected(_on_in_game_menu_pressed):
		in_game_menu_button.pressed.connect(_on_in_game_menu_pressed)
	if settings_return_button and not settings_return_button.pressed.is_connected(return_to_main_menu):
		settings_return_button.pressed.connect(return_to_main_menu)
	if settings_close_button and not settings_close_button.pressed.is_connected(_on_settings_close_pressed):
		settings_close_button.pressed.connect(_on_settings_close_pressed)
	if sound_toggle_button and not sound_toggle_button.pressed.is_connected(_on_sound_toggle_pressed):
		sound_toggle_button.pressed.connect(_on_sound_toggle_pressed)
	if haptics_toggle_button and not haptics_toggle_button.pressed.is_connected(_on_haptics_toggle_pressed):
		haptics_toggle_button.pressed.connect(_on_haptics_toggle_pressed)

	if next_button and not next_button.pressed.is_connected(_on_next_button_pressed) and (not level_manager or not next_button.pressed.is_connected(level_manager.advance_to_next_level)):
		next_button.pressed.connect(_on_next_button_pressed)
	if play_again_button and not play_again_button.pressed.is_connected(_on_play_again_pressed) and (not level_manager or not play_again_button.pressed.is_connected(level_manager.start_new_run)):
		play_again_button.pressed.connect(_on_play_again_pressed)
	if complete_menu_button and not complete_menu_button.pressed.is_connected(return_to_main_menu):
		complete_menu_button.pressed.connect(return_to_main_menu)
	if try_again_button and not try_again_button.pressed.is_connected(_on_try_again_pressed) and (not level_manager or not try_again_button.pressed.is_connected(level_manager.start_new_run)):
		try_again_button.pressed.connect(_on_try_again_pressed)
	if failure_menu_button and not failure_menu_button.pressed.is_connected(return_to_main_menu):
		failure_menu_button.pressed.connect(return_to_main_menu)

	_show_main_menu()


func _show_main_menu() -> void:
	current_state = AppState.MAIN_MENU
	_refresh_main_menu()

	if main_menu:
		main_menu.visible = true
	if settings_overlay:
		settings_overlay.visible = false

	_set_gameplay_visible(false)


func _refresh_main_menu() -> void:
	if personal_best_label:
		var pb: int = 0
		if level_manager:
			pb = level_manager.personal_best_streak
		elif save_manager:
			pb = save_manager.get_personal_best_streak()
		personal_best_label.text = "Kişisel Rekor: x%d" % pb


func _on_settings_button_pressed() -> void:
	settings_origin = SettingsOrigin.MAIN_MENU
	_refresh_settings_ui()
	if settings_return_button:
		settings_return_button.visible = false
	if settings_overlay:
		settings_overlay.visible = true


func _on_in_game_menu_pressed() -> void:
	settings_origin = SettingsOrigin.GAMEPLAY
	_refresh_settings_ui()
	if settings_return_button:
		settings_return_button.visible = true
	if settings_overlay:
		settings_overlay.visible = true


func _on_settings_close_pressed() -> void:
	if settings_overlay:
		settings_overlay.visible = false


func _refresh_settings_ui() -> void:
	var sound_on: bool = true
	var haptics_on: bool = true
	if feedback_manager:
		sound_on = feedback_manager.sound_enabled
		haptics_on = feedback_manager.haptics_enabled
	elif save_manager:
		sound_on = save_manager.get_sound_enabled()
		haptics_on = save_manager.get_haptics_enabled()

	if sound_toggle_button:
		sound_toggle_button.text = "Açık" if sound_on else "Kapalı"
	if haptics_toggle_button:
		haptics_toggle_button.text = "Açık" if haptics_on else "Kapalı"


func _on_sound_toggle_pressed() -> void:
	var current_sound: bool = true
	if feedback_manager:
		current_sound = feedback_manager.sound_enabled
	elif save_manager:
		current_sound = save_manager.get_sound_enabled()

	var new_sound: bool = not current_sound
	if feedback_manager:
		feedback_manager.set_sound_enabled(new_sound)
	if save_manager:
		save_manager.set_sound_enabled(new_sound)

	_refresh_settings_ui()


func _on_haptics_toggle_pressed() -> void:
	var current_haptics: bool = true
	if feedback_manager:
		current_haptics = feedback_manager.haptics_enabled
	elif save_manager:
		current_haptics = save_manager.get_haptics_enabled()

	var new_haptics: bool = not current_haptics
	if feedback_manager:
		feedback_manager.set_haptics_enabled(new_haptics)
	if save_manager:
		save_manager.set_haptics_enabled(new_haptics)

	_refresh_settings_ui()


func start_game_from_menu() -> void:
	current_state = AppState.PLAYING

	if main_menu:
		main_menu.visible = false
	if settings_overlay:
		settings_overlay.visible = false

	_set_gameplay_visible(true)

	if level_manager:
		level_manager.start_new_run()


func return_to_main_menu() -> void:
	current_state = AppState.MAIN_MENU

	if level_manager:
		level_manager.cleanup_run()

	_show_main_menu()


func _set_gameplay_visible(is_vis: bool) -> void:
	var level_lbl: Label = get_node_or_null("LevelIndicatorLabel")
	var lives_lbl: Label = get_node_or_null("LivesLabel")
	var streak_lbl: Label = get_node_or_null("StreakLabel")
	var title_lbl: Label = get_node_or_null("TitleLabel")
	var prompt_lbl: Label = get_node_or_null("PromptLabel")
	var success_lbl: Label = get_node_or_null("SuccessLabel")
	var next_btn: Button = get_node_or_null("NextButton")
	var in_game_menu_btn: Button = get_node_or_null("InGameMenuButton")
	var shape_cnt: Node2D = get_node_or_null("ShapeContainer")
	var math_cnt: Node2D = get_node_or_null("MathContainer")

	if level_lbl: level_lbl.visible = is_vis
	if lives_lbl: lives_lbl.visible = is_vis
	if streak_lbl: streak_lbl.visible = false
	if title_lbl: title_lbl.visible = is_vis
	if prompt_lbl: prompt_lbl.visible = is_vis
	if success_lbl: success_lbl.visible = false
	if next_btn: next_btn.visible = false
	if in_game_menu_btn: in_game_menu_btn.visible = is_vis
	if shape_cnt: shape_cnt.visible = is_vis
	if math_cnt: math_cnt.visible = is_vis


func _on_next_button_pressed() -> void:
	if level_manager and level_manager.has_method("advance_to_next_level"):
		level_manager.advance_to_next_level()


func _on_play_again_pressed() -> void:
	if level_manager and level_manager.has_method("start_new_run"):
		level_manager.start_new_run()


func _on_try_again_pressed() -> void:
	if level_manager and level_manager.has_method("start_new_run"):
		level_manager.start_new_run()





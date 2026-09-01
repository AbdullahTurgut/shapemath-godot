extends Node2D

enum AppState {
	MAIN_MENU,
	PLAYING,
}

var current_state: AppState = AppState.MAIN_MENU

@onready var save_manager: SaveManager = $SaveManager
@onready var feedback_manager: FeedbackManager = $FeedbackManager
@onready var level_manager: LevelManager = $LevelManager
@onready var main_menu: Control = $MainMenu
@onready var personal_best_label: Label = $MainMenu/PersonalBestLabel
@onready var start_game_button: Button = $MainMenu/StartGameButton
@onready var next_button: Button = $NextButton
@onready var play_again_button: Button = $RunCompleteOverlay/Card/PlayAgainButton
@onready var try_again_button: Button = $RunFailureOverlay/Card/TryAgainButton


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
	if next_button and not next_button.pressed.is_connected(_on_next_button_pressed) and (not level_manager or not next_button.pressed.is_connected(level_manager.advance_to_next_level)):
		next_button.pressed.connect(_on_next_button_pressed)
	if play_again_button and not play_again_button.pressed.is_connected(_on_play_again_pressed) and (not level_manager or not play_again_button.pressed.is_connected(level_manager.start_new_run)):
		play_again_button.pressed.connect(_on_play_again_pressed)
	if try_again_button and not try_again_button.pressed.is_connected(_on_try_again_pressed) and (not level_manager or not try_again_button.pressed.is_connected(level_manager.start_new_run)):
		try_again_button.pressed.connect(_on_try_again_pressed)

	_show_main_menu()


func _show_main_menu() -> void:
	current_state = AppState.MAIN_MENU
	_refresh_main_menu()

	if main_menu:
		main_menu.visible = true

	_set_gameplay_visible(false)


func _refresh_main_menu() -> void:
	if personal_best_label:
		var pb: int = 0
		if level_manager:
			pb = level_manager.personal_best_streak
		elif save_manager:
			pb = save_manager.get_personal_best_streak()
		personal_best_label.text = "Kişisel Rekor: x%d" % pb


func start_game_from_menu() -> void:
	current_state = AppState.PLAYING

	if main_menu:
		main_menu.visible = false

	_set_gameplay_visible(true)

	if level_manager:
		level_manager.start_new_run()


func _set_gameplay_visible(is_vis: bool) -> void:
	var level_lbl: Label = get_node_or_null("LevelIndicatorLabel")
	var lives_lbl: Label = get_node_or_null("LivesLabel")
	var streak_lbl: Label = get_node_or_null("StreakLabel")
	var title_lbl: Label = get_node_or_null("TitleLabel")
	var prompt_lbl: Label = get_node_or_null("PromptLabel")
	var success_lbl: Label = get_node_or_null("SuccessLabel")
	var next_btn: Button = get_node_or_null("NextButton")
	var shape_cnt: Node2D = get_node_or_null("ShapeContainer")
	var math_cnt: Node2D = get_node_or_null("MathContainer")

	if level_lbl: level_lbl.visible = is_vis
	if lives_lbl: lives_lbl.visible = is_vis
	if streak_lbl: streak_lbl.visible = false
	if title_lbl: title_lbl.visible = is_vis
	if prompt_lbl: prompt_lbl.visible = is_vis
	if success_lbl: success_lbl.visible = false
	if next_btn: next_btn.visible = false
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



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
var quit_handler: Callable = Callable()

@onready var background: ColorRect = $Background
@onready var save_manager: SaveManager = $SaveManager
@onready var feedback_manager: FeedbackManager = $FeedbackManager
@onready var level_manager: LevelManager = $LevelManager
@onready var main_menu: Control = $MainMenu
@onready var personal_best_label: Label = $MainMenu/PersonalBestLabel
@onready var start_game_button: Button = $MainMenu/StartGameButton
@onready var daily_challenge_button: Button = $MainMenu/DailyChallengeButton
@onready var statistics_button: Button = $MainMenu/StatisticsButton
@onready var settings_button: Button = $MainMenu/SettingsButton
@onready var menu_exit_button: Button = $MainMenu/MenuExitButton
@onready var in_game_menu_button: Button = $InGameMenuButton
@onready var exit_confirmation_overlay: Control = $ExitConfirmationOverlay
@onready var exit_cancel_button: Button = $ExitConfirmationOverlay/Card/CancelButton
@onready var exit_confirm_button: Button = $ExitConfirmationOverlay/Card/ConfirmExitButton
@onready var statistics_overlay: Control = $StatisticsOverlay
@onready var statistics_close_button: Button = $StatisticsOverlay/Card/CloseButton
@onready var stat_best_streak_value: Label = $StatisticsOverlay/Card/BestStreakValue
@onready var stat_puzzles_solved_value: Label = $StatisticsOverlay/Card/PuzzlesSolvedValue
@onready var stat_runs_completed_value: Label = $StatisticsOverlay/Card/RunsCompletedValue
@onready var stat_perfect_runs_value: Label = $StatisticsOverlay/Card/PerfectRunsValue
@onready var stat_success_rate_value: Label = $StatisticsOverlay/Card/SuccessRateValue
@onready var settings_overlay: Control = $SettingsOverlay
@onready var sound_toggle_button: Button = $SettingsOverlay/Card/SoundToggleButton
@onready var haptics_toggle_button: Button = $SettingsOverlay/Card/HapticsToggleButton
@onready var settings_return_button: Button = $SettingsOverlay/Card/ReturnToMenuButton
@onready var settings_close_button: Button = $SettingsOverlay/Card/CloseButton
@onready var next_button: Button = $NextButton
@onready var run_complete_overlay: Control = $RunCompleteOverlay
@onready var play_again_button: Button = $RunCompleteOverlay/Card/PlayAgainButton
@onready var complete_menu_button: Button = $RunCompleteOverlay/Card/CompleteMenuButton
@onready var run_failure_overlay: Control = $RunFailureOverlay
@onready var try_again_button: Button = $RunFailureOverlay/Card/TryAgainButton
@onready var failure_menu_button: Button = $RunFailureOverlay/Card/FailureMenuButton


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back_request()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		update_responsive_layout()
		if current_state == AppState.MAIN_MENU:
			_refresh_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_back_request()


func _handle_back_request() -> void:
	# Priority 0: Exit confirmation overlay is open
	if exit_confirmation_overlay and exit_confirmation_overlay.visible:
		_on_exit_cancel_pressed()
		return

	# Priority 1: Statistics overlay is open
	if statistics_overlay and statistics_overlay.visible:
		_on_statistics_close_pressed()
		return

	# Priority 2: Settings overlay is open
	if settings_overlay and settings_overlay.visible:
		_on_settings_close_pressed()
		return

	# Priority 3: Run failure overlay is open
	if run_failure_overlay and run_failure_overlay.visible:
		return_to_main_menu()
		return

	# Priority 4: Run complete overlay is open
	if run_complete_overlay and run_complete_overlay.visible:
		return_to_main_menu()
		return

	# Priority 5: Active gameplay -> opens Settings overlay (origin = GAMEPLAY)
	if current_state == AppState.PLAYING:
		_on_in_game_menu_pressed()
		return

	# Priority 6: Main Menu -> exit app
	if current_state == AppState.MAIN_MENU:
		if quit_handler.is_valid():
			quit_handler.call()
		else:
			get_tree().quit()
		return


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
	if daily_challenge_button and not daily_challenge_button.pressed.is_connected(start_daily_from_menu):
		daily_challenge_button.pressed.connect(start_daily_from_menu)
	if statistics_button and not statistics_button.pressed.is_connected(_on_statistics_button_pressed):
		statistics_button.pressed.connect(_on_statistics_button_pressed)
	if statistics_close_button and not statistics_close_button.pressed.is_connected(_on_statistics_close_pressed):
		statistics_close_button.pressed.connect(_on_statistics_close_pressed)
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

	if play_again_button:
		if level_manager and play_again_button.pressed.is_connected(level_manager.start_new_run):
			play_again_button.pressed.disconnect(level_manager.start_new_run)
		if not play_again_button.pressed.is_connected(_on_play_again_pressed):
			play_again_button.pressed.connect(_on_play_again_pressed)

	if complete_menu_button and not complete_menu_button.pressed.is_connected(return_to_main_menu):
		complete_menu_button.pressed.connect(return_to_main_menu)

	if try_again_button:
		if level_manager and try_again_button.pressed.is_connected(level_manager.start_new_run):
			try_again_button.pressed.disconnect(level_manager.start_new_run)
		if not try_again_button.pressed.is_connected(_on_try_again_pressed):
			try_again_button.pressed.connect(_on_try_again_pressed)

	if failure_menu_button and not failure_menu_button.pressed.is_connected(return_to_main_menu):
		failure_menu_button.pressed.connect(return_to_main_menu)

	if menu_exit_button and not menu_exit_button.pressed.is_connected(_on_menu_exit_pressed):
		menu_exit_button.pressed.connect(_on_menu_exit_pressed)
	if exit_cancel_button and not exit_cancel_button.pressed.is_connected(_on_exit_cancel_pressed):
		exit_cancel_button.pressed.connect(_on_exit_cancel_pressed)
	if exit_confirm_button and not exit_confirm_button.pressed.is_connected(_on_exit_confirm_pressed):
		exit_confirm_button.pressed.connect(_on_exit_confirm_pressed)

	var vp: Viewport = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)

	update_responsive_layout()
	_show_main_menu()


func get_safe_top_inset() -> float:
	var win_size: Vector2i = DisplayServer.window_get_size()
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	var vp_size: Vector2 = get_viewport_rect().size
	var top_inset: float = 0.0
	if win_size.y > 0 and safe_rect.position.y > 0:
		var scale_factor: float = vp_size.y / float(win_size.y)
		top_inset = float(safe_rect.position.y) * scale_factor
	return maxf(top_inset, 24.0)


func _on_viewport_size_changed() -> void:
	update_responsive_layout()


func update_responsive_layout() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var safe_top: float = get_safe_top_inset()

	# 1. Fullscreen backgrounds and overlay root sizes
	if background:
		background.size = vp_size
	if main_menu:
		main_menu.size = vp_size
	if settings_overlay:
		settings_overlay.size = vp_size
	if statistics_overlay:
		statistics_overlay.size = vp_size
	if exit_confirmation_overlay:
		exit_confirmation_overlay.size = vp_size
	if run_complete_overlay:
		run_complete_overlay.size = vp_size
	if run_failure_overlay:
		run_failure_overlay.size = vp_size

	# 2. Main Menu vertical centering & exit button
	if main_menu:
		var menu_content_height: float = 635.0
		var menu_start_y: float = maxf(safe_top + 40.0, (vp_size.y - menu_content_height) * 0.5)

		var title_lbl: Label = main_menu.get_node_or_null("TitleLabel") as Label
		var sub_lbl: Label = main_menu.get_node_or_null("SubtitleLabel") as Label

		if title_lbl:
			title_lbl.position = Vector2((vp_size.x - title_lbl.size.x) * 0.5, menu_start_y)
		if sub_lbl:
			sub_lbl.position = Vector2((vp_size.x - sub_lbl.size.x) * 0.5, menu_start_y + 95.0)
		if personal_best_label:
			personal_best_label.position = Vector2((vp_size.x - personal_best_label.size.x) * 0.5, menu_start_y + 175.0)
		if start_game_button:
			start_game_button.position = Vector2((vp_size.x - start_game_button.size.x) * 0.5, menu_start_y + 255.0)
		if daily_challenge_button:
			daily_challenge_button.position = Vector2((vp_size.x - daily_challenge_button.size.x) * 0.5, menu_start_y + 365.0)
		if statistics_button:
			statistics_button.position = Vector2((vp_size.x - statistics_button.size.x) * 0.5, menu_start_y + 475.0)
		if settings_button:
			settings_button.position = Vector2((vp_size.x - settings_button.size.x) * 0.5, menu_start_y + 565.0)
		if menu_exit_button:
			menu_exit_button.position = Vector2(vp_size.x - menu_exit_button.size.x - 40.0, safe_top + 5.0)

	# 3. Top HUD positioning
	var level_lbl: Label = get_node_or_null("LevelIndicatorLabel") as Label
	var lives_lbl: Label = get_node_or_null("LivesLabel") as Label
	var streak_lbl: Label = get_node_or_null("StreakLabel") as Label
	var top_title: Label = get_node_or_null("TitleLabel") as Label

	var hud_y: float = safe_top
	if level_lbl:
		level_lbl.position = Vector2(40.0, hud_y + 5.0)
	if lives_lbl:
		lives_lbl.position = Vector2((vp_size.x - lives_lbl.size.x) * 0.5, hud_y + 5.0)
	if streak_lbl:
		streak_lbl.position = Vector2(vp_size.x - 280.0, hud_y + 5.0)
	if in_game_menu_button:
		in_game_menu_button.position = Vector2(vp_size.x - 140.0, hud_y)
	if top_title:
		top_title.position = Vector2((vp_size.x - top_title.size.x) * 0.5, hud_y + 70.0)

	# 4. Notify LevelManager
	if level_manager and level_manager.has_method("update_responsive_layout"):
		level_manager.update_responsive_layout(vp_size, safe_top)


func _on_menu_exit_pressed() -> void:
	if statistics_overlay:
		statistics_overlay.visible = false
	if settings_overlay:
		settings_overlay.visible = false
	if exit_confirmation_overlay:
		exit_confirmation_overlay.visible = true


func _on_exit_cancel_pressed() -> void:
	if exit_confirmation_overlay:
		exit_confirmation_overlay.visible = false


func _on_exit_confirm_pressed() -> void:
	if quit_handler.is_valid():
		quit_handler.call()
	else:
		get_tree().quit()


func _show_main_menu() -> void:
	current_state = AppState.MAIN_MENU
	update_responsive_layout()
	_refresh_main_menu()

	if main_menu:
		main_menu.visible = true
	if exit_confirmation_overlay:
		exit_confirmation_overlay.visible = false
	if settings_overlay:
		settings_overlay.visible = false
	if statistics_overlay:
		statistics_overlay.visible = false
	if run_complete_overlay:
		run_complete_overlay.visible = false
	if run_failure_overlay:
		run_failure_overlay.visible = false

	_set_gameplay_visible(false)

	_set_gameplay_visible(false)


var _menu_refresh_timer: float = 0.0


func _process(delta: float) -> void:
	if current_state == AppState.MAIN_MENU:
		_menu_refresh_timer += delta
		if _menu_refresh_timer >= 30.0:
			_menu_refresh_timer = 0.0
			_refresh_main_menu()


func _refresh_main_menu() -> void:
	if personal_best_label:
		var pb: int = 0
		if level_manager:
			pb = level_manager.personal_best_streak
		elif save_manager:
			pb = save_manager.get_personal_best_streak()
		personal_best_label.text = "Kişisel Rekor: x%d" % pb

	if daily_challenge_button:
		var is_avail: bool = true
		if save_manager:
			is_avail = save_manager.is_daily_available()
		elif level_manager and level_manager.save_manager:
			is_avail = level_manager.save_manager.is_daily_available()

		if is_avail:
			daily_challenge_button.text = "Günün Turu"
			daily_challenge_button.disabled = false
		else:
			daily_challenge_button.text = "Günün Turu ✓"
			daily_challenge_button.disabled = true


func _on_statistics_button_pressed() -> void:
	if exit_confirmation_overlay:
		exit_confirmation_overlay.visible = false
	if settings_overlay:
		settings_overlay.visible = false
	_refresh_statistics_ui()
	if statistics_overlay:
		statistics_overlay.visible = true


func _on_statistics_close_pressed() -> void:
	if statistics_overlay:
		statistics_overlay.visible = false


func _refresh_statistics_ui() -> void:
	var pb: int = 0
	var solved: int = 0
	var completed: int = 0
	var perfect: int = 0
	var rate: int = 0

	if save_manager:
		pb = save_manager.get_personal_best_streak()
		solved = save_manager.get_total_puzzles_solved()
		completed = save_manager.get_total_runs_completed()
		perfect = save_manager.get_total_perfect_runs()
		rate = save_manager.get_success_rate_percentage()
	elif level_manager and level_manager.save_manager:
		pb = level_manager.save_manager.get_personal_best_streak()
		solved = level_manager.save_manager.get_total_puzzles_solved()
		completed = level_manager.save_manager.get_total_runs_completed()
		perfect = level_manager.save_manager.get_total_perfect_runs()
		rate = level_manager.save_manager.get_success_rate_percentage()

	if stat_best_streak_value:
		stat_best_streak_value.text = "x%d" % pb
	if stat_puzzles_solved_value:
		stat_puzzles_solved_value.text = "%d" % solved
	if stat_runs_completed_value:
		stat_runs_completed_value.text = "%d" % completed
	if stat_perfect_runs_value:
		stat_perfect_runs_value.text = "%d" % perfect
	if stat_success_rate_value:
		stat_success_rate_value.text = "%d%%" % rate


func _on_settings_button_pressed() -> void:
	settings_origin = SettingsOrigin.MAIN_MENU
	if exit_confirmation_overlay:
		exit_confirmation_overlay.visible = false
	if statistics_overlay:
		statistics_overlay.visible = false
	_refresh_settings_ui()
	if settings_return_button:
		settings_return_button.visible = false
	if settings_overlay:
		settings_overlay.visible = true


func _on_in_game_menu_pressed() -> void:
	settings_origin = SettingsOrigin.GAMEPLAY
	if exit_confirmation_overlay:
		exit_confirmation_overlay.visible = false
	if statistics_overlay:
		statistics_overlay.visible = false
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
	if exit_confirmation_overlay:
		exit_confirmation_overlay.visible = false
	if settings_overlay:
		settings_overlay.visible = false
	if statistics_overlay:
		statistics_overlay.visible = false

	if level_manager:
		level_manager.start_new_run()

	_set_gameplay_visible(true)


func start_daily_from_menu() -> void:
	if save_manager and not save_manager.is_daily_available():
		return
	if level_manager and level_manager.save_manager and not level_manager.save_manager.is_daily_available():
		return

	current_state = AppState.PLAYING

	if main_menu:
		main_menu.visible = false
	if exit_confirmation_overlay:
		exit_confirmation_overlay.visible = false
	if settings_overlay:
		settings_overlay.visible = false
	if statistics_overlay:
		statistics_overlay.visible = false

	if level_manager:
		level_manager.start_daily_challenge()

	_set_gameplay_visible(true)


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
	if title_lbl:
		if is_vis and level_manager and level_manager.current_run_mode == LevelManager.RunMode.DAILY:
			title_lbl.text = "Günün Turu"
		else:
			title_lbl.text = "ShapeMath"
		title_lbl.visible = is_vis
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
	if level_manager:
		if level_manager.current_run_mode == LevelManager.RunMode.DAILY:
			level_manager.start_daily_challenge(level_manager.active_daily_date_key)
		else:
			level_manager.start_new_run()
	_set_gameplay_visible(true)


func _on_try_again_pressed() -> void:
	if level_manager:
		if level_manager.current_run_mode == LevelManager.RunMode.DAILY:
			level_manager.start_daily_challenge(level_manager.active_daily_date_key)
		else:
			level_manager.start_new_run()
	_set_gameplay_visible(true)





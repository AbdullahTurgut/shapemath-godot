extends Node2D

@onready var level_manager: Node = $LevelManager
@onready var restart_button: Button = $RestartButton
@onready var next_button: Button = $NextButton
@onready var play_again_button: Button = $RunCompleteOverlay/Card/PlayAgainButton


func _ready() -> void:
	if restart_button and not restart_button.pressed.is_connected(_on_restart_button_pressed) and (not level_manager or not restart_button.pressed.is_connected(level_manager.reset_level)):
		restart_button.pressed.connect(_on_restart_button_pressed)
	if next_button and not next_button.pressed.is_connected(_on_next_button_pressed) and (not level_manager or not next_button.pressed.is_connected(level_manager.advance_to_next_level)):
		next_button.pressed.connect(_on_next_button_pressed)
	if play_again_button and not play_again_button.pressed.is_connected(_on_play_again_pressed) and (not level_manager or not play_again_button.pressed.is_connected(level_manager.start_new_run)):
		play_again_button.pressed.connect(_on_play_again_pressed)


func _on_restart_button_pressed() -> void:
	if level_manager and level_manager.has_method("reset_level"):
		level_manager.reset_level()


func _on_next_button_pressed() -> void:
	if level_manager and level_manager.has_method("advance_to_next_level"):
		level_manager.advance_to_next_level()


func _on_play_again_pressed() -> void:
	if level_manager and level_manager.has_method("start_new_run"):
		level_manager.start_new_run()

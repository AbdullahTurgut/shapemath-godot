extends Node2D

@onready var level_manager: LevelManager = $LevelManager
@onready var restart_button: Button = $RestartButton
@onready var next_button: Button = $NextButton
@onready var play_again_button: Button = $RunCompleteOverlay/Card/PlayAgainButton


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_button_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
	if play_again_button:
		play_again_button.pressed.connect(_on_play_again_pressed)


func _on_restart_button_pressed() -> void:
	level_manager.reset_level()


func _on_next_button_pressed() -> void:
	level_manager.advance_to_next_level()


func _on_play_again_pressed() -> void:
	level_manager.start_new_run()

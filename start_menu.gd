extends Control
func _ready() -> void:
	$CenterContainer/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$CenterContainer/VBoxContainer/TutorialButton.pressed.connect(_on_tutorial_pressed)
	Engine.time_scale = 1.0
	get_tree().paused = false

	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8)
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Levels/Main/L_Main.tscn")
	
func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://TutorialMenu.tscn")

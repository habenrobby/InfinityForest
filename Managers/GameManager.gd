extends Node

@onready var husk_spawns: Array = $"../HuskSpawns".get_children()

func _ready() -> void:
	add_to_group("game_manager")

func _process(delta: float) -> void:
	GameState.current_survival_time += delta

func player_caught() -> void:
	var death_sequence = get_tree().get_first_node_in_group("death_sequence")
	if death_sequence:
		death_sequence.play_death_sequence()
	else:
		# fallback if not set up yet
		GameState.increment_loop()
		get_tree().reload_current_scene()

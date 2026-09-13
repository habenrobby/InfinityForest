extends Node3D

@export var husk_scene: PackedScene = preload("res://Husk/Husk.tscn")
@export var total_husks := 20
@export var sitting_husks := 6  # remainder patrol
@export var min_distance_from_player := 15.0

@onready var spawn_points: Array = $"../HuskSpawns".get_children()

func _ready() -> void:
	_spawn_husks()

func _spawn_husks() -> void:
	var player_node = get_tree().get_first_node_in_group("player")

	var safe_points: Array = spawn_points
	if player_node:
		safe_points = spawn_points.filter(func(p):
			return p.global_position.distance_to(player_node.global_position) > min_distance_from_player
		)
		if safe_points.size() == 0:
			safe_points = spawn_points

	var shuffled_points := safe_points.duplicate()
	shuffled_points.shuffle()

	for i in range(total_husks):
		var husk = husk_scene.instantiate()
		husk.starts_sitting = i < sitting_husks

		var point_index = i % shuffled_points.size()
		if point_index == 0 and i != 0:
			shuffled_points.shuffle()

		add_child(husk)
		husk.global_position = shuffled_points[point_index].global_position

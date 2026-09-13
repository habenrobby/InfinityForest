@tool
extends Node3D

@export var tree_scene: PackedScene
@export var tree_count: int = 60
@export var spawn_radius: float = 40.0
@export var min_distance_from_center: float = 5.0
@export var seed_value: int = 12345

var _regenerate: bool = false
@export var regenerate: bool:
	get:
		return _regenerate
	set(value):
		_regenerate = false
		if value and is_inside_tree():
			call_deferred("generate_trees")

var _clear: bool = false
@export var clear: bool:
	get:
		return _clear
	set(value):
		_clear = false
		if value and is_inside_tree():
			call_deferred("clear_trees")

func generate_trees() -> void:
	if not is_inside_tree():
		return
	clear_trees()
	if not tree_scene:
		push_warning("Assign a Tree Scene first")
		return

	seed(seed_value)
	for i in tree_count:
		var tree = tree_scene.instantiate()
		add_child(tree)
		tree.owner = get_tree().edited_scene_root

		var angle = randf() * TAU
		var dist = randf_range(min_distance_from_center, spawn_radius)
		tree.position = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		tree.rotation.y = randf_range(0, TAU)
		tree.scale = Vector3.ONE * randf_range(0.8, 1.6)

		_add_collision(tree)

func clear_trees() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _add_collision(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			child.create_trimesh_collision()
		_add_collision(child)

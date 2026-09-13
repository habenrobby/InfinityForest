extends CharacterBody3D
class_name Enemy


signal attack_landed(target: Node3D, damage: int)

enum State {
	IDLE,
	CHASE,
	ATTACK,
	SEARCH,
}

@export var move_speed := 6.0
@export var acceleration := 8.0
@export var turn_speed := 10.0
@export var detection_radius := 25.0
@export var attack_range := 2.5
@export var attack_damage := 10
@export var attack_cooldown := 1.2

@export_node_path("Node3D") var target_path := NodePath()
var target: Node3D

var state: State = State.IDLE
var last_known_position := Vector3()
var attack_timer := 0.0


func _ready() -> void:
	if not target_path.is_empty():
		var node := get_node_or_null(target_path)
		if node is Node3D:
			target = node
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(&"player")


func _physics_process(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)

	if not is_on_floor():
		velocity.y -= get_gravity() * delta

	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(&"player")
		if not is_instance_valid(target):
			stop(delta)
			move_and_slide()
			return

	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	var sees_player := distance <= detection_radius and has_line_of_sight()

	match state:
		State.IDLE:
			stop(delta)
			if sees_player:
				state = State.CHASE

		State.CHASE:
			if not sees_player:
				search(target.global_position)
			elif distance <= attack_range:
				state = State.ATTACK
			else:
				face(delta, to_target)
				steer(delta, to_target.normalized())

		State.ATTACK:
			if not sees_player:
				search(target.global_position)
			elif distance > attack_range:
				state = State.CHASE
			else:
				face(delta, to_target)
				attack()

		State.SEARCH:
			if sees_player:
				state = State.CHASE
			else:
				go_to(delta, last_known_position)

	move_and_slide()


# Find the target with a line-of-sight raycast (walls and geometry block it).
func has_line_of_sight() -> bool:
	var space := get_world_3d().direct_space_state
	var origin := global_position + Vector3.UP * 1.5
	var destination := target.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.collision_mask = 3
	query.exclude = [self]
	var hit := space.intersect_ray(query)
	return hit.is_empty() or hit.collider == target


func attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	if target.has_node(&"Health"):
		var health: Node = target.get_node(&"Health")
		if health.has_method(&"take_damage"):
			health.take_damage(attack_damage)
	attack_landed.emit(target, attack_damage)


# Steer towards a horizontal direction with acceleration.
func steer(delta: float, direction: Vector3) -> void:
	var target_velocity := direction * move_speed
	var weight := clampf(acceleration * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, target_velocity.x, weight)
	velocity.z = lerpf(velocity.z, target_velocity.z, weight)


func stop(delta: float) -> void:
	var weight := clampf(acceleration * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, 0.0, weight)
	velocity.z = lerpf(velocity.z, 0.0, weight)


# Rotate the body so its -Z forward faces the given horizontal direction.
func face(delta: float, direction: Vector3) -> void:
	var horizontal := Vector2(direction.x, direction.z)
	if horizontal.length_squared() < 0.0001:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)


# Move to a remembered position; idle once close enough.
func go_to(delta: float, destination: Vector3) -> void:
	var to_goal := destination - global_position
	to_goal.y = 0.0
	if to_goal.length() < 0.5:
		stop(delta)
		state = State.IDLE
		return
	face(delta, to_goal)
	steer(delta, to_goal.normalized())


func search(position: Vector3) -> void:
	last_known_position = position
	state = State.SEARCH
extends CharacterBody3D

enum State { PATROL, INVESTIGATE, CHASE, LOST }
var current_state: State = State.PATROL

@export var patrol_speed := 2.0
@export var chase_speed := 6.5
@export var lost_duration := 4.0
@export var suppression_radius := 6.0
@export var max_suppression := 0.5
@export var starts_sitting := false

@export var fire_radius := 4.5
@export var fire_burn_rate := 20.0
@export var patrol_group_name := "patrol_points"

var lost_timer := 0.0
var last_known_position := Vector3.ZERO
var player: Node3D = null
var torch: Node3D = null

var hp := 100.0
var is_burning := false

@onready var detection_area: Area3D = $DetectionArea
@onready var catch_area: Area3D = $CatchArea
@onready var sprite: AnimatedSprite3D = $Sprite3D

var patrol_points: Array[Node] = []
var patrol_target := Vector3.ZERO
var patrol_wait_timer := 0.0
const PATROL_WAIT_TIME := 2.0
var is_sitting := false

func _ready() -> void:
	is_sitting = starts_sitting
	if is_sitting:
		sprite.visible = true
		sprite.play("eating")

	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Head/Camera/Torch"):
		torch = player.get_node("Head/Camera/Torch")

	patrol_points = get_tree().get_nodes_in_group(patrol_group_name)

	detection_area.body_entered.connect(_on_detection_area_entered)
	catch_area.body_entered.connect(_on_catch_area_entered)
	_pick_new_patrol_target()

func _physics_process(delta: float) -> void:
	_update_torch_suppression()
	_apply_fire(delta)

	match current_state:
		State.PATROL:
			if is_sitting:
				sprite.play("eating")
			else:
				if patrol_wait_timer > 0.0:
					patrol_wait_timer -= delta
				else:
					_move_toward(patrol_target, patrol_speed)
					if global_position.distance_to(patrol_target) < 2.0:
						_pick_new_patrol_target()
						patrol_wait_timer = PATROL_WAIT_TIME

		State.INVESTIGATE:
			_move_toward(last_known_position, patrol_speed * 1.5)
			if global_position.distance_to(last_known_position) < 1.5:
				_change_state(State.LOST)

		State.CHASE:
			if player:
				last_known_position = player.global_position
				var speed := _get_scaled_chase_speed()
				if is_burning:
					speed *= 0.35
				_move_toward(player.global_position, speed)

		State.LOST:
			lost_timer -= delta
			if lost_timer <= 0.0:
				_change_state(State.PATROL)

	velocity.y = max(velocity.y - 15.0 * delta, -18.0)
	move_and_slide()

func _pick_new_patrol_target() -> void:
	if not patrol_points.is_empty():
		var random_node = patrol_points.pick_random() as Node3D
		if random_node:
			patrol_target = random_node.global_position

func _get_scaled_chase_speed() -> float:
	var difficulty: float = GameState.get_difficulty()
	return lerp(chase_speed * 0.6, chase_speed, difficulty)

func _move_toward(target_pos: Vector3, speed: float) -> void:
	var to_target := target_pos - global_position
	to_target.y = 0.0
	if to_target.length() < 0.4:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var dir := to_target.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

func _change_state(new_state: State) -> void:
	current_state = new_state
	if new_state == State.LOST:
		lost_timer = lost_duration
	elif new_state == State.INVESTIGATE:
		sprite.visible = true
		sprite.play("look_back")

func _on_detection_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and current_state != State.CHASE:
		is_sitting = false
		sprite.visible = true
		sprite.play("spot")
		_change_state(State.CHASE)
		await sprite.animation_finished
		if current_state == State.CHASE:
			sprite.play("chase")

func _on_catch_area_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().call_group("game_manager", "player_caught")

func _update_torch_suppression() -> void:
	if player == null or torch == null:
		return
	var distance := global_position.distance_to(player.global_position)
	var difficulty: float = GameState.get_difficulty()

	if distance <= suppression_radius and difficulty > 0.0:
		var proximity_factor := 1.0 - (distance / suppression_radius)
		var dim_amount := difficulty * max_suppression * proximity_factor
		torch.set_dim_factor(1.0 - dim_amount)
	else:
		torch.set_dim_factor(1.0)

func _apply_fire(delta: float) -> void:
	if player == null or torch == null:
		return
	var distance := global_position.distance_to(player.global_position)
	if distance <= fire_radius and torch.has_method("get_fire_power"):
		var power: float = torch.get_fire_power()
		if power > 0.0:
			hp -= fire_burn_rate * power * delta
			is_burning = true
			if hp <= 0.0:
				_drive_off()
			return
	is_burning = false

func _drive_off() -> void:
	hp = 100.0
	is_burning = false
	_change_state(State.PATROL)
	if not patrol_points.is_empty():
		var fallback := global_position
		var best_dist := 0.0
		for p in patrol_points:
			if p is Node3D:
				# Fixed line: explicit float typing instead of type inference (:=)
				var d: float = p.global_position.distance_to(player.global_position) if player else 9999.0
				if d > best_dist:
					best_dist = d
					fallback = p.global_position
		global_position = fallback

extends Node3D


@export_node_path("Camera3D") var cam_path := NodePath("Camera")
@onready var cam: Camera3D = get_node(cam_path)

@export var mouse_sensitivity := 2.0
@export var y_limit := 90.0
var mouse_axis := Vector2()
var rot := Vector3()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_sensitivity = mouse_sensitivity / 1000
	y_limit = deg_to_rad(y_limit)
	print("Loop count is: ", GameState.loop_count)
	


# Called when there is an input event
@export var swing_threshold := 25.0
var swing_cooldown := 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var drag_speed = event.relative.length()
		
		if drag_speed > swing_threshold and swing_cooldown <= 0.0:
			flare_torch()
			swing_cooldown = 0.4
		else:
			mouse_axis = event.relative
			camera_rotation()


func flare_torch() -> void:
	get_node("Camera/Torch").flare()

# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	if swing_cooldown > 0.0:
		swing_cooldown -= delta
	
	var joystick_axis := Input.get_vector(&"look_left", &"look_right",
			&"look_down", &"look_up")
	
	if joystick_axis != Vector2.ZERO:
		mouse_axis = joystick_axis * 1000.0 * delta
		camera_rotation()


func camera_rotation() -> void:
	# Horizontal mouse look.
	rot.y -= mouse_axis.x * mouse_sensitivity
		
	get_owner().rotation.y = rot.y
	rotation.x = rot.x

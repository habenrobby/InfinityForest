extends SpotLight3D

@export var base_energy := 50.0
@export var flare_energy := 70.0
@export var flare_duration := 0.3
@export var smoothing_speed := 6.0
@export var flare_color := Color(1.0, 0.85, 0.6)  # Hotter, whiter-orange color during flare

@export_group("Flicker Limits")
@export var min_flicker_ratio := 0.65  # Light will never drop below 65% of current target
@export var max_flicker_ratio := 1.35  # Light can flicker up to 135% of current target

@export_group("Flicker FX")
@export var flicker_amount := 0.35        # Flame waver intensity in energy units
@export var flicker_speed := 1.2          # Flame movement speed
@export var flicker_range_amount := 0.4   # Light reach wobble
@export var flicker_color_shift := 0.05   # Subtle warm/cool color drift

var flare_timer := 0.0
var target_energy := 0.0
var external_dim_factor := 1.0

var noise := FastNoiseLite.new()
var noise_time := 0.0
var base_range := 0.0
var base_color: Color
var base_color_for_flare: Color

func _ready() -> void:
	target_energy = base_energy
	light_energy = base_energy
	base_range = spot_range
	base_color = light_color
	base_color_for_flare = light_color

	noise.seed = randi()
	noise.frequency = 1.0
	noise.fractal_octaves = 2

func _process(delta: float) -> void:
	noise_time += delta * flicker_speed

	if flare_timer > 0.0:
		flare_timer -= delta
		target_energy = flare_energy
	else:
		target_energy = base_energy

	# Calculate base target with external suppression applied
	var effective_target: float = target_energy * external_dim_factor

	# Smoothly transition energy toward target (for flares and dimming)
	var smoothed_energy: float = lerp(light_energy, effective_target, delta * smoothing_speed)

	# Layer organic flame flicker on top using dual noise samples
	var flicker_noise: float = noise.get_noise_1d(noise_time)
	var flicker_noise_2: float = noise.get_noise_1d(noise_time * 2.3 + 100.0)

	var noise_offset: float = (flicker_noise * flicker_amount) + (flicker_noise_2 * flicker_amount * 0.3)
	
	# Keep light within clean low-to-high boundaries
	var raw_energy: float = smoothed_energy + noise_offset
	var floor_limit: float = effective_target * min_flicker_ratio
	var ceiling_limit: float = max(effective_target * max_flicker_ratio, flare_energy)
	
	light_energy = clamp(raw_energy, floor_limit, ceiling_limit)

	# Range breathing
	spot_range = max(1.0, base_range + flicker_noise * flicker_range_amount)

	# Fire temperature flicker shift blended into the flare color
	var flare_blend: float = clamp(flare_timer / flare_duration, 0.0, 1.0)
	var shift: float = flicker_noise * flicker_color_shift
	var flickered_base: Color = base_color.lightened(max(shift, 0.0)).darkened(max(-shift, 0.0))
	light_color = flickered_base.lerp(flare_color, flare_blend)

func flare() -> void:
	flare_timer = flare_duration

# Called by Husk.gd to dim the light dynamically when close to the enemy
func set_dim_factor(factor: float) -> void:
	external_dim_factor = clamp(factor, 0.0, 1.0)

# Helper called by Husk.gd fire damage check
func get_fire_power() -> float:
	return light_energy / base_energy

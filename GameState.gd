extends Node

var loop_count := 0
var max_smart_loop := 5
var best_survival_time := 0.0
var current_survival_time := 0.0

func increment_loop() -> void:
	loop_count += 1
	if current_survival_time > best_survival_time:
		best_survival_time = current_survival_time
	current_survival_time = 0.0

func get_difficulty() -> float:
	return clamp(float(loop_count) / float(max_smart_loop), 0.0, 1.0)

extends Node

signal hunger_changed(ratio: float)

@export var max_hunger := 100.0
@export var hunger_rate := 1.2  # tune based on how long you want a loop to last

var hunger := 0.0

func _process(delta: float) -> void:
	hunger = min(hunger + hunger_rate * delta, max_hunger)
	hunger_changed.emit(hunger / max_hunger)

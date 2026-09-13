extends Node

signal health_changed(current: int, max: int)
signal died

@export var max_hp := 100
var hp := max_hp: set = set_hp

func _ready() -> void:
	hp = max_hp

func damage(amount: int) -> void:
	set_hp(hp - amount)
	if hp <= 0:
		died.emit()

func heal(amount: int) -> void:
	set_hp(hp + amount)

func set_hp(value: int) -> void:
	hp = clampi(value, 0, max_hp)
	health_changed.emit(hp, max_hp)
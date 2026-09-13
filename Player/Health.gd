extends Node
class_name Health


signal health_changed(current: int, maximum: int)
signal died

@export var max_health := 100
var health: int


func _ready() -> void:
	health = max_health


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	health = clampi(health - amount, 0, max_health)
	health_changed.emit(health, max_health)
	if health <= 0:
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0:
		return
	health = clampi(health + amount, 0, max_health)
	health_changed.emit(health, max_health)
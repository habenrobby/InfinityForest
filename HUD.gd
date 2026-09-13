extends CanvasLayer

@onready var loop_label: Label = $LoopLabel
@onready var best_time_label: Label = $BestTimeLabel

func _process(_delta: float) -> void:
	loop_label.text = "Nights: %d" % (GameState.loop_count + 1)
	best_time_label.text = "Best Survival: %s" % _format_time(GameState.best_survival_time)

func _format_time(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

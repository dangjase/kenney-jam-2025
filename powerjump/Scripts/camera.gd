extends Camera2D

const camera_position_1: Vector2 = Vector2(56, -430)

func _ready() -> void:
	zoom.x = 0.5
	zoom.y = 0.5
	position = camera_position_1


func set_camera_position(target_pos):
	position = target_pos

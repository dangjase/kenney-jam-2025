extends TextureRect

@onready var player = get_node("../Player")

func _process(delta):
	global_position.x = 0
	print(player)

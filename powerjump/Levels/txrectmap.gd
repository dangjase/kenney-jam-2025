extends TextureRect

@onready var player = get_node("/root/LevelVertical/Player")
var lockedxpos
var xpos
var ypos
var selfypos
#func _ready() -> void:
	#xpos = player.global_position.x
	#ypos = player.global_position.y
	#selfypos = global_position.y

#func _process(delta):
	#var y_delta = player.global_position.y - ypos
	#global_position.y = selfypos + 0.5*y_delta
	#return

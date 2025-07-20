extends Control

@onready var music_player = $MusicPlayer
var level_scene: PackedScene = load("res://Levels/level_1_big_vertical.tscn")

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		get_tree().change_scene_to_packed(level_scene)

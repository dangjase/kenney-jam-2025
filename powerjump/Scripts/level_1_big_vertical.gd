extends Node2D

@onready var song1 = $Song1
@onready var song2 = $Song2
@onready var song3 = $Song3
@onready var song4 = $Song4
@onready var song5 = $Song5
@onready var song6 = $Song6
@onready var song7 = $Song7

var songs: Array
var index: int

func _ready() -> void:
	index = 0
	songs = [song1, song2, song3, song4, song5, song6, song7]
	songs.shuffle()
	songs[0].play()

func _process(delta) -> void:
	if Input.is_action_just_pressed("w"):
		songs[index].stop()
		_on_song_finished()


func _on_song_finished() -> void:
	index += 1
	if index >= songs.size():
		index = 0
	songs[index].play()

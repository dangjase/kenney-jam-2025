extends Area2D

@onready var congratsbox = get_parent().get_parent().get_node("HUD/Control2/RichTextLabel")


func _on_body_entered(body:Node2D) -> void:
	congratsbox.visible = true
	get_parent().queue_free()

extends Camera3D

const MAX_SPEED = 0.01

func get_input_vector():
    var input_vector = Vector2.ZERO
    input_vector.x = Input.get_action_strength('d') - Input.get_action_strength('a')
    input_vector.y = Input.get_action_strength('s') - Input.get_action_strength('w')
    input_vector = input_vector.normalized()
    return input_vector

func _process(delta: float) -> void:
    #set_velocity(get_input_vector() * MAX_SPEED)
    #move_and_slide()
    var vel = -get_input_vector().y * MAX_SPEED
	#transform.basis.x += delta*vel
    #global_position += transform.basis.y * vel
    global_position.y += vel
    print(global_position)

extends CharacterBody2D

const DEFAULT_FALL_GRAVITY: float = 3000  # Up from 2200
const DEFAULT_RISE_GRAVITY: float = 2200  # Up from 1600
const JUMP_VELOCITY_MULTIPLIER: float = -1200  # Up from -1000
const MAX_JUMP_HOLD_TIME: float = 1.3
const HORIZONTAL_SPEED: float = 800  # Up from 600
const MAX_FALL_SPEED: float = 2200  # Up from 1600
const MIN_JUMP_HOLD_TIME: float = 0.125

@onready var bodySprite = $BodySprite
@onready var faceSprite = $FaceSprite
#player variables
var player_state: states
var jump_hold_time: float
var fall_gravity: float
var rise_gravity: float
var direction_input: float
enum states {
	GROUNDED,
	CHARGING,
	LAUNCH,
	AIRBORNE
}

func _ready() -> void:
	player_state = states.AIRBORNE
	faceSprite.play('default')
	fall_gravity = DEFAULT_FALL_GRAVITY
	rise_gravity = DEFAULT_RISE_GRAVITY

func _physics_process(delta) -> void:
	handle_input(delta)
	handle_physics(delta)
	move_and_slide()


func handle_input(delta) -> void:
	match player_state:
		states.GROUNDED:
			if Input.is_action_pressed("jump"):
				jump_hold_time = 0;
				player_state = states.CHARGING;
		states.CHARGING:
			jump_hold_time += delta;
			if jump_hold_time >= MAX_JUMP_HOLD_TIME:
				jump_hold_time = MAX_JUMP_HOLD_TIME;
				player_state = states.LAUNCH;
			elif Input.is_action_just_released("jump"):
				if (jump_hold_time > MIN_JUMP_HOLD_TIME):
					player_state = states.LAUNCH;
				else:
					jump_hold_time = 0;
					player_state = states.GROUNDED;
		states.LAUNCH:
			pass
		states.AIRBORNE:
			pass	

func handle_physics(delta) -> void:
	match player_state:
		states.GROUNDED:
			pass
		states.CHARGING:
			pass
		states.LAUNCH:
			#player is launched into the air
			velocity.y = jump_hold_time * JUMP_VELOCITY_MULTIPLIER
			direction_input = Input.get_axis("move_left", "move_right")
			velocity.x = direction_input * HORIZONTAL_SPEED
			player_state = states.AIRBORNE
		states.AIRBORNE:
			if (is_on_floor()):
				#switch to grounded state
				player_state = states.GROUNDED
				velocity.x = 0
				velocity.y = 0
			elif (is_on_wall()):
				#TODO: handle wall bounce
				pass
			elif(is_on_ceiling()):
				#TODO: handle ceiling bounce
				velocity.y = 0  # Reset vertical velocity on ceiling hit
				velocity.y += fall_gravity * delta
			else:
				# Apply different gravity based on vertical movement
				if velocity.y < 0:
					# Rising - use rise gravity
					velocity.y += rise_gravity * delta
					
					# Subtle slowdown near apex (when vertical speed is very low)
					if velocity.y > -100:
						velocity.y += (rise_gravity * 0.5) * delta
				else:
					# Falling - use fall gravity
					velocity.y += fall_gravity * delta
				
				# Clamp to max fall speed
				velocity.y = min(velocity.y, MAX_FALL_SPEED)
			

	

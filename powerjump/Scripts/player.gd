extends CharacterBody2D

const DEFAULT_FALL_GRAVITY: float = 3000
const DEFAULT_RISE_GRAVITY: float = 2200
const JUMP_VELOCITY_MULTIPLIER: float = -1200
const MAX_JUMP_HOLD_TIME: float = 1.3
const HORIZONTAL_SPEED: float = 800
const MAX_FALL_SPEED: float = 2200
const MIN_JUMP_HOLD_TIME: float = 0.125
const WALL_BOUNCE_DAMPENING: float = 0.5 # How much speed is kept after a wall bounce

# Animation constants
const HAND_WAVE_SPEED: float = 5.0
const HAND_WAVE_AMPLITUDE: float = 30.0
const HAND_WAVE_CHARGE_SPEED: float = 30.0
const HAND_WAVE_CHARGE_AMPLITUDE: float = 10.0
const HAND_OFFSET_X: float = 75.0  # Base horizontal distance from body
const HAND_AIR_OFFSET_X: float = 50.0
const HAND_BASE_Y: float = 10.0     # Base vertical position relative to body
const HAND_MOVEMENT_OFFSET: float = 40.0  # Base movement offset
const HAND_MOVEMENT_SCALE: float = 1.5    # How much to scale movement based on vertical position
const HAND_ROTATION_UP: float = 0     # 0 = pointing up
const HAND_ROTATION_DOWN: float = 180  # 180 = pointing down
# Diagonal rotations for combined movement
const HAND_ROTATION_UP_RIGHT: float = 225   # Pointing down-left when moving up-right
const HAND_ROTATION_DOWN_RIGHT: float = 315  # Pointing up-left when moving down-right
const HAND_ROTATION_UP_LEFT: float = 135    # Pointing down-right when moving up-left
const HAND_ROTATION_DOWN_LEFT: float = 45    # Pointing up-right when moving down-left

#player variables
#from the scene
@onready var bodySprite = $BodySprite
@onready var faceSprite = $FaceSprite
@onready var handRightSprite = $HandRight
@onready var handLeftSprite = $HandLeft

#properties
var player_state: states
var jump_hold_time: float
var fall_gravity: float
var rise_gravity: float
var direction_input: float
var animation_time: float = 0.0  # Track time for animations
var last_velocity: Vector2 = Vector2.ZERO # Store velocity from the previous frame

enum states {
	GROUNDED,
	CHARGING,
	LAUNCH,
	AIRBORNE,
	DEBUGFLY
}

func _ready() -> void:
	player_state = states.AIRBORNE
	faceSprite.play('default')
	fall_gravity = DEFAULT_FALL_GRAVITY
	rise_gravity = DEFAULT_RISE_GRAVITY

func _process(delta) -> void:
	handle_animation(delta)

func _physics_process(delta) -> void:
	handle_input(delta)
	handle_physics(delta)
	last_velocity = velocity # Store velocity before any physics calculations
	move_and_slide()

func debug_input_vector():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength('move_right') - Input.get_action_strength('move_left')
	input_vector.y = Input.get_action_strength('move_down') - Input.get_action_strength('jump')
	input_vector = input_vector.normalized()
	return input_vector

func handle_input(delta) -> void:
	match player_state:
		states.GROUNDED:
			if Input.is_action_pressed("jump"):
				jump_hold_time = 0;
				change_player_state(states.CHARGING);
		states.CHARGING:
			jump_hold_time += delta;
			if jump_hold_time >= MAX_JUMP_HOLD_TIME:
				jump_hold_time = MAX_JUMP_HOLD_TIME;
				change_player_state(states.LAUNCH);
			elif Input.is_action_just_released("jump"):
				if (jump_hold_time > MIN_JUMP_HOLD_TIME):
					change_player_state(states.LAUNCH);
				else:
					jump_hold_time = 0;
					change_player_state(states.GROUNDED);
		states.LAUNCH:
			pass
		states.AIRBORNE:
			pass	
		states.DEBUGFLY:
			pass
	if Input.is_action_just_pressed("noclip"):
		if player_state == states.DEBUGFLY:
			change_player_state(states.AIRBORNE)
		else:
			player_state = states.DEBUGFLY

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
			change_player_state(states.AIRBORNE)
		states.AIRBORNE:
			if (is_on_floor()):
				#switch to grounded state
				change_player_state(states.GROUNDED)
				velocity.x = 0
				velocity.y = 0
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
				if (is_on_wall()): #Bounce off wall
					velocity.x = -1 * last_velocity.x * WALL_BOUNCE_DAMPENING
					print('aaa')
					$BoingPlayer.play()
					# Update direction_input to match the new velocity direction
					#NOTE: the player did not actually change input, but we use this to calculate the hand animation
					direction_input = sign(velocity.x) 
				# Clamp to max fall speed
				velocity.y = min(velocity.y, MAX_FALL_SPEED)
		states.DEBUGFLY:
			set_velocity(debug_input_vector() * 5000)

func change_player_state(new_state) -> void:
	# save old state here for transition logic
	player_state = new_state
	match player_state:
		states.GROUNDED:
			$ProgressBar.visible = false
			$ChargingPlayer.stop()
			handRightSprite.play('closed')
			handLeftSprite.play('closed')
			handRightSprite.rotation_degrees = HAND_ROTATION_UP
			handLeftSprite.rotation_degrees = HAND_ROTATION_UP
			faceSprite.play('face_a')
			faceSprite.position.y = 0
			faceSprite.position.x = 0
		states.CHARGING:
			$ProgressBar.visible = true
			handRightSprite.play('open')
			handLeftSprite.play('open')
			handRightSprite.rotation_degrees = HAND_ROTATION_UP
			handLeftSprite.rotation_degrees = HAND_ROTATION_UP
			$ChargingPlayer.play()
		states.LAUNCH:
			$ProgressBar.visible = false
			$ChargingPlayer.stop()
			$ShoutPlayer.play()
			handRightSprite.play('closed')
			handLeftSprite.play('closed')
			handRightSprite.rotation_degrees = HAND_ROTATION_DOWN
			handLeftSprite.rotation_degrees = HAND_ROTATION_DOWN
		states.AIRBORNE:
			handRightSprite.play('open')
			handLeftSprite.play('open')

func handle_animation(delta) -> void:
	animation_time += delta
	
	match player_state:
		states.GROUNDED:
			var idle_wave = sin(animation_time * 4) * 10
			_set_hand_pose(
				Vector2(-HAND_OFFSET_X, HAND_BASE_Y + idle_wave),
				Vector2(HAND_OFFSET_X,  HAND_BASE_Y - idle_wave),
				HAND_ROTATION_UP
			)

		states.CHARGING:
			var charge_progress = jump_hold_time / MAX_JUMP_HOLD_TIME
			var wave  = sin(animation_time * HAND_WAVE_CHARGE_SPEED) * HAND_WAVE_CHARGE_AMPLITUDE
			var height = -160 * charge_progress
			_set_hand_pose(
				Vector2(-HAND_OFFSET_X + wave * 0.3, height + wave),
				Vector2( HAND_OFFSET_X - wave * 0.3, height - wave),
				HAND_ROTATION_UP
			)
			$ProgressBar.value = charge_progress * 100

		states.LAUNCH:
			var y_offset = -HAND_WAVE_AMPLITUDE * 2
			_set_hand_pose(
				Vector2(-HAND_OFFSET_X, y_offset),
				Vector2( HAND_OFFSET_X,  y_offset),
				HAND_ROTATION_DOWN
			)

		states.AIRBORNE:
			_update_airborne_hands()
			_update_airborne_face()


# Helper functions for animation

func _set_hand_pose(left_pos: Vector2, right_pos: Vector2, desired_rotation: float) -> void:
	handLeftSprite.position  = left_pos
	handRightSprite.position = right_pos
	handLeftSprite.rotation_degrees  = desired_rotation
	handRightSprite.rotation_degrees = desired_rotation

func _update_airborne_face() -> void:
	# Target positions based on velocity
	var target_y = 0
	var target_x = 0
	
	if velocity.y < 0:
		faceSprite.play('face_a_up')
		target_y = -20
	elif velocity.y > 0:
		faceSprite.play('face_a_down')
		target_y = 20
	else:
		faceSprite.play('face_a')
		target_y = 0
		
	if velocity.x < 0:
		target_x = -15
	elif velocity.x > 0:
		target_x = 15
	else:
		target_x = 0
	
	# Smooth interpolation (adjust the 0.15 value to control speed)
	faceSprite.position.y = lerp(float(faceSprite.position.y), float(target_y), 0.15)
	faceSprite.position.x = lerp(float(faceSprite.position.x), float(target_x), 0.15)

func _update_airborne_hands() -> void:
	var wave_speed = 24.0 if direction_input != 0 else 12.0
	var air_wave   = sin(animation_time * wave_speed) * 15.0

	# Vertical influence (hands move depending on fall/rise speed)
	var velocity_scale      = 150.0
	var normalized_velocity = clamp(velocity.y / MAX_FALL_SPEED, -1.0, 1.0)
	var velocity_influence  = velocity_scale * (normalized_velocity if normalized_velocity < 0 else normalized_velocity * 1.3)
	velocity_influence      = clamp(velocity_influence, -velocity_scale, velocity_scale * 1.3)

	# Horizontal influence / spread
	var vertical_scale   = 1.0 + abs(velocity_influence) / velocity_scale * HAND_MOVEMENT_SCALE
	var movement_offset  = -direction_input * HAND_MOVEMENT_OFFSET * vertical_scale
	var base_spread      = HAND_AIR_OFFSET_X if direction_input == 0 else HAND_AIR_OFFSET_X - abs(direction_input) * 35.0

	# Determine rotation and smooth it near the apex
	var base_rotation = _compute_base_rotation(velocity.y, direction_input)
	if abs(velocity.y) < 100:
		var t = clamp((abs(velocity.y) - 50.0) / 50.0, 0.0, 1.0)
		var apex_rotation = _compute_apex_rotation(velocity.y, direction_input)
		base_rotation = lerp(apex_rotation, base_rotation, t)

	_set_hand_pose(
		Vector2(-base_spread + air_wave + movement_offset, HAND_BASE_Y - velocity_influence),
		Vector2( base_spread - air_wave + movement_offset, HAND_BASE_Y - velocity_influence),
					base_rotation
	)

func _compute_base_rotation(vel_y: float, dir: float) -> float:
	if dir == 0:
		return HAND_ROTATION_DOWN if vel_y < -50 else (HAND_ROTATION_UP if vel_y > 50 else HAND_ROTATION_UP)
	if dir > 0:
		return HAND_ROTATION_UP_RIGHT if vel_y < -50 else HAND_ROTATION_DOWN_RIGHT
	return HAND_ROTATION_UP_LEFT if vel_y < -50 else HAND_ROTATION_DOWN_LEFT

func _compute_apex_rotation(vel_y: float, dir: float) -> float:
	if dir == 0:
		return HAND_ROTATION_DOWN if vel_y < 0 else HAND_ROTATION_UP
	if dir > 0:
		return HAND_ROTATION_UP_RIGHT if vel_y < 0 else HAND_ROTATION_DOWN_RIGHT
	return HAND_ROTATION_UP_LEFT if vel_y < 0 else HAND_ROTATION_DOWN_LEFT

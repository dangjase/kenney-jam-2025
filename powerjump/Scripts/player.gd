extends CharacterBody2D

const DEFAULT_FALL_GRAVITY: float = 3800  # Was 2500 - Much faster fall
const DEFAULT_RISE_GRAVITY: float = 3000  # Was 2500 - Moderately faster rise
const JUMP_VELOCITY_MULTIPLIER: float = -2267  # Unchanged - keeps same max height
const MAX_JUMP_HOLD_TIME: float = 0.9  # Unchanged - keeps same charge time
const HORIZONTAL_SPEED: float = 1000  # Was 800 - Increased to match faster vertical movement
const MAX_FALL_SPEED: float = 2400  # Was 1800 - Increased to allow faster falling
const MIN_JUMP_HOLD_TIME: float = 0.08  # Unchanged
const WALL_BOUNCE_DAMPENING: float = 0.75  # How much speed is kept after a wall bounce
const SLOPE_SPEED: float = 1200.0  # How fast we move along slopes

# Walking constants
const WALK_SPEED: float = 600.0  # Walking speed on ground
const WALK_HAND_Y: float = 24.0  # Vertical position of hands while walking
const WALK_HAND_AMPLITUDE: float = 40.0  # How far hands move forward/back
const WALK_HAND_SPEED: float = 12.0  # Speed of walking animation
const WALK_HAND_BOUNCE: float = 5.0  # Vertical bounce while walking

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
@onready var progressbar = get_parent().get_node("HUD/Control/ProgressBar")
@onready var jumpSound = $JumpPlayer
@onready var boingSound = $BoingPlayer
@onready var chargingSound = $ChargingPlayer
@onready var landSound = $LandPlayer
@onready var laughSound = $LaughPlayer
@onready var launchParticles = $LaunchParticles

#properties
var player_state: states
var jump_hold_time: float
var fall_gravity: float
var rise_gravity: float
var direction_input: float
var animation_time: float = 0.0  # Track time for animations
var last_velocity: Vector2 = Vector2.ZERO # Store velocity from the previous frame
var jump_start_y: float

enum states {
	GROUNDED,
	CHARGING,
	LAUNCH,
	AIRBORNE,
	WALKING
}

func _ready() -> void:
	get_tree().current_scene.print_tree_pretty()
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
			direction_input = Input.get_axis("move_left", "move_right")
			if Input.is_action_pressed("jump"):
				jump_hold_time = 0;
				change_player_state(states.CHARGING);
			elif abs(direction_input) > 0:
				change_player_state(states.WALKING)
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
			direction_input = Input.get_axis("move_left", "move_right")
		states.WALKING:
			direction_input = Input.get_axis("move_left", "move_right")
			if abs(direction_input) == 0:
				change_player_state(states.GROUNDED)
			elif Input.is_action_pressed("jump"):
				jump_hold_time = 0
				change_player_state(states.CHARGING)
			elif !is_on_floor():
				change_player_state(states.AIRBORNE)

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
					boingSound.play()
					# Update direction_input to match the new velocity direction
					direction_input = sign(velocity.x)
				
				# Check for slope sliding
				_check_slope_slide()
				
				# Clamp to max fall speed
				velocity.y = min(velocity.y, MAX_FALL_SPEED)
		states.WALKING:
			if !is_on_floor():
				change_player_state(states.AIRBORNE)
			else:
				velocity.x = direction_input * WALK_SPEED
				velocity.y = 0  # Keep us on the ground

func change_player_state(new_state) -> void:
	# save old state here for transition logic
	var old_state = player_state
	player_state = new_state
	match player_state:
		states.GROUNDED:
			progressbar.visible = false
			chargingSound.stop()
			handRightSprite.play('closed')
			handLeftSprite.play('closed')
			handRightSprite.rotation_degrees = HAND_ROTATION_UP
			handLeftSprite.rotation_degrees = HAND_ROTATION_UP
			faceSprite.play('face_a')
			faceSprite.position.y = 0
			faceSprite.position.x = 0
			velocity.x = 0  # Stop horizontal movement
			if (old_state == states.AIRBORNE):
				landSound.play()
		states.CHARGING:
			progressbar.visible = true
			handRightSprite.play('open')
			handLeftSprite.play('open')
			faceSprite.play('face_g')
			faceSprite.position.y = 0
			faceSprite.position.x = 0
			handRightSprite.rotation_degrees = HAND_ROTATION_UP
			handLeftSprite.rotation_degrees = HAND_ROTATION_UP
			chargingSound.play()
			velocity.x = 0  # Stop horizontal movement
		states.LAUNCH:
			progressbar.visible = false
			chargingSound.stop()
			jumpSound.play()
			jump_start_y = global_position.y
			handRightSprite.play('closed')
			handLeftSprite.play('closed')
			handRightSprite.rotation_degrees = HAND_ROTATION_DOWN
			handLeftSprite.rotation_degrees = HAND_ROTATION_DOWN
			faceSprite.position.y = lerp(float(faceSprite.position.y), 0.0, 0.5)
			launchParticles.position.x = (handRightSprite.position.x + handLeftSprite.position.x) / 2
			launchParticles.position.y = 45
			launchParticles.emitting = true
		states.AIRBORNE:
			handRightSprite.play('open')
			handLeftSprite.play('open')
		states.WALKING:
			handRightSprite.play('open')
			handLeftSprite.play('open')
			faceSprite.play('face_a')
			if (old_state == states.AIRBORNE):
				landSound.play()
			faceSprite.position.y = 0
			faceSprite.position.x = 0

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
			progressbar.value = charge_progress * 100
			
			# Lerp face upwards during charge
			var target_y = 17
			faceSprite.position.y = lerp(float(faceSprite.position.y), float(target_y), 0.035)
			
			# Lerp face horizontally based on input direction
			direction_input = Input.get_axis("move_left", "move_right")
			var target_x = direction_input * 9
			faceSprite.position.x = lerp(float(faceSprite.position.x), float(target_x), 0.3)
			
			# Update face animation based on charge progress
			if charge_progress >= 0.6:  # 60% charged
				faceSprite.play('face_g')
			else:
				faceSprite.play('face_f')

		states.LAUNCH:
			var y_offset = -HAND_WAVE_AMPLITUDE * 2
			_set_hand_pose(
				Vector2(-HAND_OFFSET_X, y_offset),
				Vector2( HAND_OFFSET_X,  y_offset),
				HAND_ROTATION_DOWN
			)
			launchParticles.position.x = max(handRightSprite.position.x, handLeftSprite.position.x)
			launchParticles.emitting = true

		states.AIRBORNE:
			_update_airborne_hands()
			_update_airborne_face()
		states.WALKING:
			var walk_wave = sin(animation_time * WALK_HAND_SPEED)
			var left_offset = walk_wave * WALK_HAND_AMPLITUDE
			var right_offset = -walk_wave * WALK_HAND_AMPLITUDE  # Opposite phase
			
			# Add vertical bounce synchronized with horizontal movement
			var bounce = abs(walk_wave) * WALK_HAND_BOUNCE
			
			# Update hand sprites based on their movement direction
			if walk_wave > 0:
				handLeftSprite.play('open')
				handRightSprite.play('closed')
			else:
				handLeftSprite.play('closed')
				handRightSprite.play('open')
			
			# Determine hand rotation based on movement direction
			var hand_rotation = HAND_ROTATION_UP
			if direction_input > 0:
				hand_rotation = HAND_ROTATION_UP_LEFT
			elif direction_input < 0:
				hand_rotation = HAND_ROTATION_UP_RIGHT
			
			_set_hand_pose(
				Vector2(-HAND_OFFSET_X + left_offset, WALK_HAND_Y - bounce),
				Vector2(HAND_OFFSET_X + right_offset, WALK_HAND_Y - bounce),
				hand_rotation
			)
			
			# Update face direction
			var target_x = direction_input * 9
			if (target_x > 0):
				faceSprite.play('face_a_right')
			elif (target_x < 0):
				faceSprite.play('face_a_left')
			else:
				faceSprite.play('face_a')
			faceSprite.position.x = lerp(float(faceSprite.position.x), float(target_x), 0.15)


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
		target_y = -17
	elif velocity.y > 0:
		faceSprite.play('face_a_down')
		target_y = 17
	else:
		faceSprite.play('face_a')
		target_y = 0
		
	if velocity.x < 0:
		target_x = -11
	elif velocity.x > 0:
		target_x = 11
	else:
		target_x = 0
	
	# Smooth interpolation (adjust the 0.15 value to control speed)
	faceSprite.position.y = lerp(float(faceSprite.position.y), float(target_y), 0.15)
	faceSprite.position.x = lerp(float(faceSprite.position.x), float(target_x), 0.15)

func _update_airborne_hands() -> void:
	var movement_direction = sign(velocity.x)  # Use velocity direction instead of input
	var wave_speed = 24.0 if movement_direction != 0 else 12.0
	var air_wave   = sin(animation_time * wave_speed) * 15.0

	# Vertical influence (hands move depending on fall/rise speed)
	var velocity_scale      = 150.0
	var normalized_velocity = clamp(velocity.y / MAX_FALL_SPEED, -1.0, 1.0)
	var velocity_influence  = velocity_scale * (normalized_velocity if normalized_velocity < 0 else normalized_velocity * 1.3)
	velocity_influence      = clamp(velocity_influence, -velocity_scale, velocity_scale * 1.3)

	# Horizontal influence / spread
	var vertical_scale   = 1.0 + abs(velocity_influence) / velocity_scale * HAND_MOVEMENT_SCALE
	var movement_offset  = -movement_direction * HAND_MOVEMENT_OFFSET * vertical_scale
	var base_spread      = HAND_AIR_OFFSET_X if movement_direction == 0 else HAND_AIR_OFFSET_X - abs(movement_direction) * 35.0

	# Determine rotation and smooth it near the apex
	var base_rotation = _compute_base_rotation(velocity.y, movement_direction)
	if abs(velocity.y) < 100:
		var t = clamp((abs(velocity.y) - 50.0) / 50.0, 0.0, 1.0)
		var apex_rotation = _compute_apex_rotation(velocity.y, movement_direction)
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

# Slope ricochet functions for trampoline effect

func _check_slope_slide() -> void:
	if not is_on_floor():
		return
		
	var collision = get_last_slide_collision()
	if collision:
		var normal = collision.get_normal()
		if _is_slope_surface(normal):
			_handle_slope_slide(normal)

func _is_slope_surface(normal: Vector2) -> bool:
	return abs(normal.x) > 0.1  # Any non-flat surface counts as slope

func _handle_slope_slide(normal: Vector2) -> void:
	# Get slope direction (tangent to the surface)
	var slope_direction = Vector2(-normal.y, normal.x)
	
	# Make sure we're sliding downhill
	if slope_direction.y < 0:
		slope_direction = -slope_direction
	
	# Project current velocity onto slope direction
	var current_speed = velocity.project(slope_direction).length()
	
	# Apply movement along slope
	velocity = slope_direction.normalized() * max(current_speed, SLOPE_SPEED)
	
	# Update animation direction based on horizontal movement
	direction_input = sign(velocity.x)

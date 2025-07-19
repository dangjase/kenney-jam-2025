extends CharacterBody2D

const DEFAULT_FALL_GRAVITY: float = 3000
const DEFAULT_RISE_GRAVITY: float = 2200
const JUMP_VELOCITY_MULTIPLIER: float = -1200
const MAX_JUMP_HOLD_TIME: float = 1.3
const HORIZONTAL_SPEED: float = 800
const MAX_FALL_SPEED: float = 2200
const MIN_JUMP_HOLD_TIME: float = 0.125

# Animation constants
const HAND_WAVE_SPEED: float = 5.0
const HAND_WAVE_AMPLITUDE: float = 30.0
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

func _process(delta) -> void:
	handle_animation(delta)

func _physics_process(delta) -> void:
	handle_input(delta)
	handle_physics(delta)
	move_and_slide()


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
			

func change_player_state(new_state) -> void:
	# save old state here for transition logic
	player_state = new_state
	match player_state:
		states.GROUNDED:
			handRightSprite.play('closed')
			handLeftSprite.play('closed')
			handRightSprite.rotation_degrees = HAND_ROTATION_UP
			handLeftSprite.rotation_degrees = HAND_ROTATION_UP
		states.CHARGING:
			handRightSprite.play('open')
			handLeftSprite.play('open')
			handRightSprite.rotation_degrees = HAND_ROTATION_UP
			handLeftSprite.rotation_degrees = HAND_ROTATION_UP
		states.LAUNCH:
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
			# Subtle idle hand motion
			var idle_wave = sin(animation_time * 2) * 10
			handLeftSprite.position.x = -HAND_OFFSET_X
			handLeftSprite.position.y = HAND_BASE_Y + idle_wave
			handRightSprite.position.x = HAND_OFFSET_X
			handRightSprite.position.y = HAND_BASE_Y - idle_wave  # Opposite phase
			
		states.CHARGING:
			# Hands move up as charge increases
			var charge_progress = jump_hold_time / MAX_JUMP_HOLD_TIME
			var wave_intensity = sin(animation_time * HAND_WAVE_SPEED) * HAND_WAVE_AMPLITUDE
			var height = -100 * charge_progress  # Move hands up as charge increases
			
			handLeftSprite.position.x = -HAND_OFFSET_X + (wave_intensity * 0.3)
			handLeftSprite.position.y = height + wave_intensity
			handRightSprite.position.x = HAND_OFFSET_X - (wave_intensity * 0.3)
			handRightSprite.position.y = height - wave_intensity
			
		states.LAUNCH:
			# Quick upward motion
			handLeftSprite.position.x = -HAND_OFFSET_X
			handLeftSprite.position.y = -HAND_WAVE_AMPLITUDE * 2
			handRightSprite.position.x = HAND_OFFSET_X
			handRightSprite.position.y = -HAND_WAVE_AMPLITUDE * 2
			
		states.AIRBORNE:
			var wave_speed = 12
			if direction_input != 0:
				wave_speed = 24
			var air_wave = sin(animation_time * wave_speed) * 15
			
			var velocity_scale = 150
			var normalized_velocity = velocity.y / MAX_FALL_SPEED
			
			# Apply asymmetric gravity for better jump feel
			var velocity_influence = velocity_scale * (
				normalized_velocity if normalized_velocity < 0 
				else normalized_velocity * 1.3
			)
			velocity_influence = clamp(velocity_influence, -velocity_scale, velocity_scale * 1.3)
			
			# Scale movement offset based on distance from body
			var vertical_scale = 1.0 + (abs(velocity_influence) / velocity_scale) * HAND_MOVEMENT_SCALE
			var movement_offset = -direction_input * HAND_MOVEMENT_OFFSET * vertical_scale
			
			var base_spread = HAND_AIR_OFFSET_X
			if direction_input != 0:
				base_spread = HAND_AIR_OFFSET_X - (abs(direction_input) * 35.0)
			
			var base_rotation = HAND_ROTATION_UP
			
			if direction_input != 0:
				if velocity.y < -50:
					base_rotation = HAND_ROTATION_UP_RIGHT if direction_input > 0 else HAND_ROTATION_UP_LEFT
				elif velocity.y > 50:
					base_rotation = HAND_ROTATION_DOWN_RIGHT if direction_input > 0 else HAND_ROTATION_DOWN_LEFT
			else:
				if velocity.y < -50:
					base_rotation = HAND_ROTATION_DOWN
				elif velocity.y > 50:
					base_rotation = HAND_ROTATION_UP
					
			# Smooth rotation transition near apex of jump
			if abs(velocity.y) < 100:
				var t = (abs(velocity.y) - 50) / 50.0
				t = clamp(t, 0, 1)
				if velocity.y < 0:
					var target_rotation
					if direction_input > 0:
						target_rotation = HAND_ROTATION_UP_RIGHT
					elif direction_input < 0:
						target_rotation = HAND_ROTATION_UP_LEFT
					else:
						target_rotation = HAND_ROTATION_DOWN
					base_rotation = lerp(HAND_ROTATION_UP, target_rotation, t)
				else:
					var target_rotation
					if direction_input > 0:
						target_rotation = HAND_ROTATION_DOWN_RIGHT
					elif direction_input < 0:
						target_rotation = HAND_ROTATION_DOWN_LEFT
					else:
						target_rotation = HAND_ROTATION_UP
					base_rotation = lerp(target_rotation, HAND_ROTATION_UP, t)
			
			handLeftSprite.position.x = -base_spread + air_wave + movement_offset
			handLeftSprite.position.y = HAND_BASE_Y - velocity_influence
			handLeftSprite.rotation_degrees = base_rotation
			
			handRightSprite.position.x = base_spread - air_wave + movement_offset
			handRightSprite.position.y = HAND_BASE_Y - velocity_influence
			handRightSprite.rotation_degrees = base_rotation

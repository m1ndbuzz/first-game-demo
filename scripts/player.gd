extends CharacterBody3D
class_name Player

@export var speed = 10.0
@export var air_speed = 3.0
@export var acceleration = 4.0
@export var jump_speed = 7.0
@export var rotation_speed = 20.0
@export var mouse_sensitivity = 0.0025
@export var controller_sensitivity = 4
@export var coyote_time = 0.3
@export var fall_multiplier = 2

@export var dash_distance = 12.0  # Distance to travel (in units)
@export var dash_duration = 0.2  # How long the dash lasts (seconds)
@export var dash_cooldown = 1.0  # Time before next dash (seconds)

@export var wall_jump_duration = 0.3 # How long the wall jump lasts (seconds)
@export var wall_jump_rotation_speed = 15.0  # How fast to rotate during wall jump
@export var wall_jump_velocity = Vector3(0, 7.0, 5.0)  # Y for height, Z for push-of

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var jumping = false
var wall_jumping = false
var last_floor = true
var dashing = false  # Track if currently dashing
var dash_timer = 0.0    # Timer for dash duration
var dash_cooldown_timer = 0.0  # Timer for cooldown
var dash_direction = Vector3.ZERO  # Store the forward direction at dash start
var is_on_jumpable_wall = false
var wall_jump_timer = 0.0
var coyote_timer = coyote_time
var was_going_up = false
var wall_jump_direction = Vector3.ZERO

var can_move = true
var finished = false
var started = false

# Variable to track time
var time_elapsed = 0.0
# Reference to the Label node
@onready var timer_label = $"../../CanvasLayer/UI/TimeLabel"
@onready var spring_arm = $SpringArm3D
@onready var model = $Rig
@onready var anim_tree = $AnimationTree
@onready var anim_state = $AnimationTree.get("parameters/playback")

func _physics_process(delta: float) -> void:
	update_time(delta)
	velocity.y += -gravity * delta
	was_going_up = velocity.y > 0
	handle_jump_gravity(delta)	
	controller_camera_rotation(delta)
	
	if can_move:
		get_move_input(delta)
		handle_coyote_time_timer(delta)
		handle_wall_jump_timer(delta)
		handle_dash_timer(delta)
		move_and_slide()
	
		# Check for wall collision
		var wall_normal = Vector3.ZERO
		is_on_jumpable_wall = false
		if is_on_wall() and not is_on_floor():
			wall_normal = wall_jump_check()
		# Wall jump
		if is_on_jumpable_wall and Input.is_action_just_pressed("jump"):
			wall_jump(wall_normal)
		
		#Model rotation based on camera angle when there's movement
		if velocity.length() > 1:
			model.rotation.y = lerp_angle(model.rotation.y, spring_arm.rotation.y, rotation_speed * delta)
		
		if coyote_timer > 0 and Input.is_action_just_pressed("jump"):
			jump()
		if is_on_floor() and not last_floor:
			jump_end()
		if not is_on_floor() and not jumping:
			anim_state.travel("Jump_Idle")
			anim_tree.set("parameters/conditions/grounded", false)
		last_floor = is_on_floor()
	else:
		velocity.x = 0
		velocity.y = 0
		velocity.z = 0
		anim_state.travel("Cheer")
	
func update_time(delta: float):
	if not finished and started:
		# Update time
		time_elapsed += delta
		
		# Format the time (minutes:seconds.milliseconds)
		var minutes = int(time_elapsed / 60)
		var seconds = int(time_elapsed) % 60
		# Corrected milliseconds calculation
		var milliseconds = int(fmod(time_elapsed * 1000, 1000))
		var time_string = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
		
		# Update the Label text
		if timer_label:
			timer_label.text = time_string

func handle_coyote_time_timer(delta: float):
	if not is_on_floor():
		coyote_timer -= delta

func handle_wall_jump_timer(delta: float):
	if wall_jumping:
		wall_jump_timer -= delta
		if wall_jump_timer <= 0:
			wall_jumping = false # End wall jump
		else:
			velocity.x = wall_jump_direction.x
			velocity.z = wall_jump_direction.z

func handle_dash_timer(delta: float):
	if dashing:
			dash_timer -= delta
			if dash_timer <= 0:
				dashing = false  # End dash
			else:
				# Move forward during dash
				var dash_speed = dash_distance / dash_duration  # Calculate speed to cover distance
				velocity.x = dash_direction.x * dash_speed
				velocity.z = dash_direction.z * dash_speed
	else:
		dash_cooldown_timer -= delta  # Reduce cooldown when not dashing

func controller_camera_rotation(delta: float):
	# Controller camera rotation
	var look_h = Input.get_axis("look_horizontal_negative", "look_horizontal_positive")  # Left/Right
	var look_v = Input.get_axis("look_vertical_negative", "look_vertical_positive")    # Up/Down
	if abs(look_h) > 0.1 or abs(look_v) > 0.1:  # Deadzone
		spring_arm.rotation.y -= look_h * controller_sensitivity * delta
		spring_arm.rotation.x -= look_v * controller_sensitivity * delta
		spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -90.0, 30.0)
			
func handle_jump_gravity(delta: float):
	if jumping and not is_on_floor():
		if was_going_up and velocity.y <= 0:  # Just reached or passed peak
			# Apply fall multiplier only when descending after peak
			velocity.y += -gravity * (fall_multiplier) * delta
		elif velocity.y < 0:  # Already falling
			velocity.y += -gravity * (fall_multiplier) * delta
			
func jump():
	started = true
	velocity.y = jump_speed
	jumping = true
	anim_tree.set("parameters/conditions/jumping", true)
	anim_tree.set("parameters/conditions/grounded", false)
	#print("Jump pressed!")  # Debug
	
func jump_end():
	jumping = false
	coyote_timer = coyote_time
	anim_tree.set("parameters/conditions/jumping", false)
	anim_tree.set("parameters/conditions/grounded", true)
	
func wall_jump(wall_normal):
	# Apply velocity: upward force + push away from wall
	velocity.y = wall_jump_velocity.y
	var push_direction = wall_normal * wall_jump_velocity.z  # Push off wall
	wall_jump_direction = Vector3(push_direction.x, 0, push_direction.z)
	velocity.x = wall_jump_direction.x
	velocity.z = wall_jump_direction.z
	wall_jumping = true
	wall_jump_timer = wall_jump_duration
	anim_state.travel("Jump_Start")

	

func wall_jump_check() -> Vector3:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is StaticBody3D:
			# Safely check for the property with a default value
			var is_jumpable = collider.get("is_jumpable")
			if is_jumpable == true:
				is_on_jumpable_wall = true
				return collision.get_normal()  # Store wall normal for jump direction
	return Vector3.ZERO
	
func get_move_input(delta: float) -> void:
	
	#Since we're using gravity we don't want to modify Y on our own, so we 0 it out
	#and return it to what it was after processing velocity so we keep the accumulated gravity
	var vy = velocity.y
	velocity.y = 0
	
	# Check for dash input
	if Input.is_action_just_pressed("dash") and not dashing and dash_cooldown_timer <= 0:
		started = true
		dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		# Lock dash direction to camera forward (ignore vertical component)
		dash_direction = -spring_arm.global_transform.basis.z.normalized()
		dash_direction.y = 0  # Ensure no vertical movement
		dash_direction = dash_direction.normalized()
		anim_state.travel("Dash")
		#print("Dash pressed!")  # Debug
		
	#if not dashing:
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y)
	# Set velocity directly based on input
	
	if input != Vector2.ZERO:  # If there's input
		started = true
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		#print("GMI/Direction:",direction)
	else:  # No input, stop immediately
		velocity.x = move_toward(velocity.x, 0, speed * 10 * delta)
		velocity.z = move_toward(velocity.z, 0, speed * 10 * delta)
		
	# Update animation blend
	var vel = velocity * model.basis
	anim_tree.set("parameters/IWR/blend_position", Vector2(vel.x, -vel.z) / speed)
	
	velocity.y = vy;
	
func _unhandled_input(event: InputEvent) -> void:
	# Toggle mouse capture with Escape
	if can_move:
		if event.is_action_pressed("ui_cancel"):  # Escape key
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event is InputEventMouseMotion:
			spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
			spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -90.0, 30.0)
			spring_arm.rotation.y -= event.relative.x * mouse_sensitivity		
		if event.is_action_pressed("interact"):
			anim_state.travel("Interact")
		
		
	# Debug raw controller input
	#if event is InputEventJoypadButton:
	#	print("Controller button pressed: ", event.button_index, " Action: ", event.is_pressed())

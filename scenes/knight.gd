extends CharacterBody3D
class_name Knight

@export var speed = 10.0
@export var acceleration = 4.0
@export var jump_speed = 7.0
@export var rotation_speed = 20.0
@export var mouse_sensitivity = 0.0025
@export var controller_sensitivity = 4

@export var dash_distance = 7.0  # Distance to travel (in units)
@export var dash_duration = 0.2  # How long the dash lasts (seconds)
@export var dash_cooldown = 1.0  # Time before next dash (seconds)


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var jumping = false
var last_floor = true
var dashing = false  # Track if currently dashing
var dash_timer = 0.0    # Timer for dash duration
var dash_cooldown_timer = 0.0  # Timer for cooldown
var dash_direction = Vector3.ZERO  # Store the forward direction at dash start

@onready var spring_arm = $SpringArm3D
@onready var model = $Rig
@onready var anim_tree = $AnimationTree
@onready var anim_state = $AnimationTree.get("parameters/playback")

func _physics_process(delta: float) -> void:
	velocity.y += -gravity * delta
	
	# Controller camera rotation
	var look_h = Input.get_axis("look_horizontal_negative", "look_horizontal_positive")  # Left/Right
	var look_v = Input.get_axis("look_vertical_negative", "look_vertical_positive")    # Up/Down
	if abs(look_h) > 0.1 or abs(look_v) > 0.1:  # Deadzone
		print("Look H: ", look_h)
		print("Look V: ",look_v)
		spring_arm.rotation.y -= look_h * controller_sensitivity * delta
		spring_arm.rotation.x -= look_v * controller_sensitivity * delta
		spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -90.0, 30.0)
		
		
		
	get_move_input(delta)
	
	# Handle dash timers
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
	
	move_and_slide()
	if velocity.length() > 1:
		model.rotation.y = lerp_angle(model.rotation.y, spring_arm.rotation.y, rotation_speed * delta)
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed
		jumping = true
		anim_tree.set("parameters/conditions/jumping", true)
		anim_tree.set("parameters/conditions/grounded", false)
		print("Jump pressed!")  # Debug
	if is_on_floor() and not last_floor:
		jumping = false
		anim_tree.set("parameters/conditions/jumping", false)
		anim_tree.set("parameters/conditions/grounded", true)
	if not is_on_floor() and not jumping:
		anim_state.travel("Jump_Idle")
		anim_tree.set("parameters/conditions/grounded", false)
	last_floor = is_on_floor()
	
func get_move_input(delta: float) -> void:
	
	#Since we're using gravity we don't want to modify Y on our own, so we 0 it out
	#and return it to what it was after processing velocity so we keep the accumulated gravity
	var vy = velocity.y
	velocity.y = 0
	
	# Check for dash input
	if Input.is_action_just_pressed("dash") and not dashing and dash_cooldown_timer <= 0:
		dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		# Lock dash direction to camera forward (ignore vertical component)
		dash_direction = -spring_arm.global_transform.basis.z.normalized()
		dash_direction.y = 0  # Ensure no vertical movement
		dash_direction = dash_direction.normalized()
		anim_state.travel("Dash")
		print("Dash pressed!")  # Debug
		
	#if not dashing:
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y)
	# Set velocity directly based on input
	if input != Vector2.ZERO:  # If there's input
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:  # No input, stop immediately
		velocity.x = move_toward(velocity.x, 0, speed * 10 * delta)
		velocity.z = move_toward(velocity.z, 0, speed * 10 * delta)
		
	# Update animation blend
	var vel = velocity * model.basis
	anim_tree.set("parameters/IWR/blend_position", Vector2(vel.x, -vel.z) / speed)
	
	velocity.y = vy;
	
func _unhandled_input(event: InputEvent) -> void:
	# Toggle mouse capture with Escape
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
	if event.is_action_pressed("emote"):
		anim_state.travel("Cheer")
		
	# Debug raw controller input
	if event is InputEventJoypadButton:
		print("Controller button pressed: ", event.button_index, " Action: ", event.is_pressed())

extends Camera3D

@onready var springarm = $".."
@onready var camera = $"."
@onready var raycast = $RayCast3D  # Add a RayCast3D node as a child of the camera
var transparent_radius = 3.0  # Radius around the hit point to apply transparency
var affected_objects = {}  #Dict of objects that we changed the material of;Key parent obj, Val affected obj
var transparent_material = StandardMaterial3D.new()  # Material for transparency
var default_materials = {}

func _ready():
	# Configure the raycast
	raycast.enabled = true
	raycast.collision_mask = 1  # Set to the appropriate layer(s)
	
	# Set up the transparent material
	transparent_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	transparent_material.albedo_color = Color(1, 1, 1, 0.2)  # Semi-transparent white

func _physics_process(_delta):
	# Update raycast from screen center
	var screen_center = get_viewport().get_size() / 2.0  # Center of the screen
	var from = project_ray_origin(screen_center)
	var to = from + project_ray_normal(screen_center) * 7.0  # Ray length
	raycast.global_transform.origin = from
	raycast.target_position = raycast.to_local(to)
	
	#for obj in affected_objects.keys():
		#print("adding exception: ",obj)
		#raycast.add_exception(obj)
	raycast.clear_exceptions()
	raycast.force_raycast_update()

	if raycast.is_colliding() and affected_objects.is_empty():
		#make all the obje transperent
		while raycast.is_colliding():
			var obj = raycast.get_collider()
			print("Hit an object: ",obj)
			if not affected_objects.has(obj):
				print("New obj, making it transparent")
				_apply_transparent_material(obj)
				raycast.add_exception(obj)
				raycast.force_raycast_update()
	elif raycast.is_colliding() and not affected_objects.is_empty():
		#check if the obj is in affected objs and if so do nothing
		var obj = raycast.get_collider()
		if not affected_objects.has(obj):
			print("Restoring2")
			_restore_materials()
	else:
		#clear
		if not affected_objects.is_empty():
			print("Restoring1")
			_restore_materials()

func _apply_transparent_material(obj: Node3D):
	if obj is StaticBody3D and not obj.name.contains("Floor"):
		var objChild = obj.get_child(0, true)
		if objChild != null:
			var objChildMesh = objChild.get_child(0, true)
			if objChildMesh != null and objChildMesh is MeshInstance3D:
				# Apply transparent material
				default_materials[obj] = objChildMesh.get_surface_override_material(0)
				objChildMesh.set_surface_override_material(0, transparent_material)
				affected_objects[obj] = objChildMesh

func _restore_materials():
	for obj in affected_objects:
		var afObj = affected_objects[obj]
		var defMat = default_materials[obj]
		afObj.set_surface_override_material(0, defMat)
	affected_objects.clear()
	default_materials.clear()

extends Node3D

@export var heightmap: Texture2D
@export var terrain_width: float = 200.0
@export var terrain_depth: float = 200.0
@export var height_scale: float = 40.0
@export var resolution: int = 80

@export var tree_scene: PackedScene
@export var tree_count: int = 150
@export var tree_seed: int = 12345
@export var tree_height_range: Vector2 = Vector2(3.0, 5.0)
@export var tree_width_range: Vector2 = Vector2(2.0, 3.0)

@export var house_scene: PackedScene
@export var house_count: int = 3

func _ready() -> void:
	generate_terrain()
	await get_tree().physics_frame
	_spawn_trees()
	_spawn_houses()

func generate_terrain() -> void:
	print("Generating terrain...")
	if not heightmap:
		push_warning("Assign a Heightmap texture first")
		return

	var img: Image = heightmap.get_image()
	img.convert(Image.FORMAT_RGB8)

	var verts_per_row = resolution + 1
	var heights := PackedFloat32Array()
	heights.resize(verts_per_row * verts_per_row)

	for z in verts_per_row:
		for x in verts_per_row:
			var u = float(x) / resolution
			var v = float(z) / resolution
			var px = int(u * (img.get_width() - 1))
			var pz = int(v * (img.get_height() - 1))
			var color = img.get_pixel(px, pz)
			var brightness = (color.r + color.g + color.b) / 3.0
			heights[z * verts_per_row + x] = brightness * height_scale

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in resolution:
		for x in resolution:
			var i0 = z * verts_per_row + x
			var i1 = i0 + 1
			var i2 = i0 + verts_per_row
			var i3 = i2 + 1

			var p0 = _vertex_pos(x, z, heights[i0], verts_per_row)
			var p1 = _vertex_pos(x + 1, z, heights[i1], verts_per_row)
			var p2 = _vertex_pos(x, z + 1, heights[i2], verts_per_row)
			var p3 = _vertex_pos(x + 1, z + 1, heights[i3], verts_per_row)

			st.set_uv(Vector2(float(x) / resolution, float(z) / resolution))
			st.add_vertex(p0)
			st.set_uv(Vector2(float(x + 1) / resolution, float(z) / resolution))
			st.add_vertex(p1)
			st.set_uv(Vector2(float(x) / resolution, float(z + 1) / resolution))
			st.add_vertex(p2)

			st.set_uv(Vector2(float(x + 1) / resolution, float(z) / resolution))
			st.add_vertex(p1)
			st.set_uv(Vector2(float(x + 1) / resolution, float(z + 1) / resolution))
			st.add_vertex(p3)
			st.set_uv(Vector2(float(x) / resolution, float(z + 1) / resolution))
			st.add_vertex(p2)

	st.generate_normals()
	var mesh = st.commit()

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	mesh_instance.create_trimesh_collision()

	var material = StandardMaterial3D.new()
	material.albedo_texture = load("res://kenny assets/Models/GLB format/Textures/grass.png")
	material.uv1_scale = Vector3(20, 20, 1)
	material.roughness = 1.0
	mesh_instance.material_override = material

	print("Terrain generated with ", mesh_instance.mesh.get_surface_count(), " surfaces")

func _vertex_pos(x: int, z: int, h: float, verts_per_row: int) -> Vector3:
	var world_x = (float(x) / (verts_per_row - 1)) * terrain_width - (terrain_width / 2.0)
	var world_z = (float(z) / (verts_per_row - 1)) * terrain_depth - (terrain_depth / 2.0)
	return Vector3(world_x, h, world_z)

func _spawn_trees() -> void:
	if not tree_scene:
		push_warning("Assign a Tree Scene first")
		return

	print("Spawning ", tree_count, " trees")
	seed(tree_seed)
	var space_state = get_world_3d().direct_space_state

	var min_dist = 5.0
	var max_dist = terrain_width / 2.0 - 5.0

	for i in tree_count:
		var angle = randf() * TAU
		var dist = sqrt(randf_range(min_dist * min_dist, max_dist * max_dist))
		var x = cos(angle) * dist
		var z = sin(angle) * dist

		var origin = Vector3(x, height_scale + 50.0, z)
		var target = Vector3(x, -50.0, z)
		var query = PhysicsRayQueryParameters3D.create(origin, target)
		var result = space_state.intersect_ray(query)

		if result:
			var tree = tree_scene.instantiate()
			add_child(tree)
			tree.global_position = result.position
			tree.rotation.y = randf_range(0, TAU)

			var width_scale = randf_range(tree_width_range.x, tree_width_range.y)
			var height_scale_val = randf_range(tree_height_range.x, tree_height_range.y)
			tree.scale = Vector3(width_scale, height_scale_val, width_scale)

			_add_collision(tree, width_scale, height_scale_val)

	print("Trees spawned")

func _spawn_houses() -> void:
	if not house_scene:
		push_warning("Assign a House Scene first")
		return

	print("Spawning ", house_count, " houses")
	var space_state = get_world_3d().direct_space_state
	var max_dist = terrain_width / 2.0 - 20.0 

	for i in house_count:
		var x = randf_range(-max_dist, max_dist)
		var z = randf_range(-max_dist, max_dist)

		var origin = Vector3(x, height_scale + 50.0, z)
		var target = Vector3(x, -50.0, z)
		var query = PhysicsRayQueryParameters3D.create(origin, target)
		var result = space_state.intersect_ray(query)

		if result:
			var house = house_scene.instantiate()
			add_child(house)
			house.global_position = result.position
			house.rotation.y = randf_range(0, TAU)
			
			# Increase or decrease this number to change the overall house size
			var house_scale = 15
			house.scale = Vector3(house_scale, house_scale, house_scale)
			
			_add_house_collision(house, house_scale)

func _add_house_collision(house: Node3D, house_scale: float) -> void:
	var static_body = StaticBody3D.new()
	
	add_child(static_body)
	static_body.global_position = house.global_position
	static_body.rotation.y = house.rotation.y 

	var collision_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	
	box.size = Vector3(4.0, 4.0, 4.0) * house_scale 
	
	collision_shape.shape = box
	collision_shape.position.y = box.size.y / 2.0 

	static_body.add_child(collision_shape)

func _add_collision(tree: Node3D, width_scale: float, height_scale_val: float) -> void:
	var static_body = StaticBody3D.new()
	
	add_child(static_body)
	static_body.global_position = tree.global_position

	var collision_shape = CollisionShape3D.new()
	var cylinder = CylinderShape3D.new()
	cylinder.radius = 0.12 * width_scale
	cylinder.height = 4.0 * height_scale_val

	collision_shape.shape = cylinder
	collision_shape.position.y = cylinder.height / 2.0

	static_body.add_child(collision_shape)

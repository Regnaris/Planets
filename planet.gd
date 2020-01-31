tool
extends Spatial

const directions:PoolVector3Array = PoolVector3Array(
	[Vector3.BACK, Vector3.DOWN, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT, Vector3.UP]
)

export(int, 30, 256) var max_resolution:int = 2 setget set_resolution
export(float, 0.1, 0.5) var period:float = 0.3 setget set_period
export(int, 1, 10) var octaves:int = 1 setget set_octaves
export(float, 1) var persistence:float = 0.5 setget set_persistence
export(float, 1) var lacunarity:float = 0.5 setget set_lacunarity
export(float, 1.0, 5.0) var redistribution:float = 1.0 setget set_redistribution
export(float, 0.01, 0.5) var amplitude:float = 0.1 setget set_amplitude

onready var mesh_instance = $Mesh

var noise:OpenSimplexNoise = OpenSimplexNoise.new()
var gen_thread:Thread = Thread.new()
var gen_meshready = false
var gen_res = 32

var sphere_mesh_grid:Array


func _ready():
	pass


func _process(delta):
	if !Engine.editor_hint:
		if gen_res * 2 <= max_resolution:
			if !gen_thread.is_active():
				gen_meshready = false
				gen_thread.start(self, 'generate_mesh', gen_res * 2)
			else:
				if gen_meshready:
					mesh_instance.mesh = gen_thread.wait_to_finish()
					gen_res = gen_res * 2
	else:
		if mesh_instance == null:
			mesh_instance = $Mesh
		if noise == null:
			noise = OpenSimplexNoise.new()
			noise.octaves = octaves
			noise.period = period
			noise.persistence = persistence
			noise.lacunarity = lacunarity
		if gen_thread == null:
			gen_thread = Thread.new()
		if gen_res * 2 <= 64:
			if !gen_thread.is_active():
				gen_meshready = false
				gen_thread.start(self, 'generate_mesh', gen_res * 2)
			else:
				if gen_meshready:
					mesh_instance.mesh = gen_thread.wait_to_finish()
					gen_res = gen_res * 2

func regenerate():
	gen_res = 16


func set_amplitude(value:float):
	amplitude = value
	regenerate()

func set_redistribution(value:float):
	redistribution = value
	regenerate()

func set_lacunarity(value:float):
	lacunarity = value
	noise.lacunarity = value
	regenerate()

func set_persistence(value:float):
	persistence = value
	noise.persistence = value
	regenerate()

func set_octaves(value:int):
	octaves = value
	noise.octaves = value
	regenerate()

func set_period(value:float):
	period = value
	noise.period = value
	regenerate()

func set_resolution(value:int):
	max_resolution = value
	regenerate()


func update_noise_settings():
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistence
	noise.lacunarity = lacunarity


func generate_mesh(resolution):
	var sur_tool = SurfaceTool.new()
	sur_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	sur_tool.add_smooth_group(true)
	var vertices_per_side = resolution * resolution
	for i in range(6):
		generate_face(sur_tool, directions[i], vertices_per_side * i, resolution)
	sur_tool.generate_normals()
	sur_tool.generate_tangents()
	var result = sur_tool.commit()
	gen_meshready = true
	return result


func generate_face(sur_tool:SurfaceTool, local_up:Vector3, global_index:int, resolution:int):
	var axisA:Vector3 = Vector3(local_up.y, local_up.z, local_up.x)
	var axisB:Vector3 = local_up.cross(axisA)
	
	for y in range(resolution):
		for x in range(resolution):
			var percent:Vector2 = Vector2(x, y) / (resolution - 1)
			var point_on_cube:Vector3 = local_up + (percent.x - .5) * 2 * axisA + (percent.y - .5) * 2 * axisB
			var point_on_sphere:Vector3 = point_on_cube.normalized()
			var norm_noise = (noise.get_noise_3dv(point_on_sphere) + 1) / 2
			var gen_value:float = (1 + (pow(norm_noise, redistribution) - 0.5) * amplitude)
			sur_tool.add_uv(percent)
			sur_tool.add_vertex(point_on_sphere * gen_value)
			
			var index = x + y * resolution + global_index
			if x != resolution - 1 and y != resolution - 1:
				sur_tool.add_index(index)
				sur_tool.add_index(index + resolution)
				sur_tool.add_index(index + resolution + 1)
				
				sur_tool.add_index(index)
				sur_tool.add_index(index + resolution + 1)
				sur_tool.add_index(index + 1)















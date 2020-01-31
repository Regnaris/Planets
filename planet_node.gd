extends Spatial
class_name Planet

var surface_meshes:Array
var geometry_type:int = PlanetGen.ICOSPHERE
var _cur_lod:int = 0


func _enter_tree():
	surface_meshes = []
	surface_meshes.resize(PlanetGen.MAX_LOD + 1)
	for i in range(PlanetGen.MAX_LOD + 1):
		surface_meshes[i] = MeshInstance.new()
		add_child(surface_meshes[i])


func _process(delta):
	for lod_level in range(PlanetGen.MAX_LOD + 1):
		if surface_meshes[lod_level].mesh != null:
			_cur_lod = lod_level
	for mesh_inst in surface_meshes:
		mesh_inst.hide()
	surface_meshes[_cur_lod].show()


func _ready():
	for lod_level in range(PlanetGen.MAX_LOD):
		request_lod(lod_level)


func request_lod(lod:int):
	if surface_meshes[lod].mesh == null :
		var signal_id = 'test' + str(lod)
		PlanetGen.request_mesh(signal_id, geometry_type, lod)
		PlanetGen.connect(signal_id, self, '_on_mesh_ready')
	surface_meshes[_cur_lod].hide()
	surface_meshes[lod].show()
	_cur_lod = lod


func _on_mesh_ready(mesh:ArrayMesh, lod:int):
	if mesh == null:
		assert(false)
	surface_meshes[lod].mesh = mesh
	surface_meshes[_cur_lod].hide()
	surface_meshes[lod].show()
	_cur_lod = lod
	print('Mesh received (lod:', lod, ')')

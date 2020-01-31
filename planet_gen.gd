extends Node

const V_ANGLE = atan(1.0 / 2.0)
const H_ANGLE = PI / 180.0 * 72.0
const directions:PoolVector3Array = PoolVector3Array([
	Vector3.BACK,Vector3.DOWN, Vector3.FORWARD,
	Vector3.LEFT, Vector3.RIGHT, Vector3.UP
])
const MAX_LOD = 4
const cube_lods:PoolIntArray = PoolIntArray([32, 64, 128, 256, 512])
const ico_lods:PoolIntArray = PoolIntArray([3, 4, 5, 6, 7])

enum {ICOSPHERE, CUBESPHERE}

var _threads:Array
var _geometry_cache:Array

var _noise:OpenSimplexNoise


func _enter_tree():
	_noise = OpenSimplexNoise.new()
	_noise.octaves = 10
	_noise.period = 0.1
	_noise.persistence = 0.5
	_noise.lacunarity = 0.5
	
	# Cache initialization
	var ico_cache:Array = []
	ico_cache.resize(MAX_LOD + 1)
	var cube_cache:Array = []
	cube_cache.resize(MAX_LOD + 1)
	
	_geometry_cache = []
	_geometry_cache.resize(2)
	_geometry_cache[ICOSPHERE] = ico_cache
	_geometry_cache[CUBESPHERE] = cube_cache

func _exit_tree():
	for thread in _threads:
		thread.wait_to_finish()


func mesh_from_data(data:Dictionary):
	var start_time = OS.get_ticks_usec()
	var geometry:int = data['geometry']
	var lod:int = data['lod']
	var arrays:Array
	if _geometry_cache[geometry][lod] == null:
		match geometry:
			ICOSPHERE:
				arrays = generate_ico_sphere(ico_lods[lod])
			CUBESPHERE:
				arrays = generate_cube_sphere(cube_lods[lod])
			_:
				assert(false)
	else:
		# Get geometry from cache
		assert(false)
	
	# Apply geo data
	for vtx in range(arrays[Mesh.ARRAY_VERTEX].size()):
		var vertex:Vector3 = arrays[Mesh.ARRAY_VERTEX][vtx]
		vertex = vertex * (1 + _noise.get_noise_3dv(vertex) * 0.1)
		arrays[Mesh.ARRAY_VERTEX][vtx] = vertex
		
	
	# Build mesh
	var mesh:ArrayMesh = construct_mesh(arrays, true)
	# Return mesh to requester using deferred call
	var thread_id:String = data['thread'].get_id()
	call_deferred('emit_signal', data['signal_id'], mesh, lod)
	
	var elapsed_time = (OS.get_ticks_usec() - start_time) / 1000000.0
	print('Thread ', thread_id, ' finished (lod:', lod , ' time:', elapsed_time ,'s)')
	
	call_deferred('finish_thread', data['thread'])




func finish_thread(thread:Thread):
	thread.wait_to_finish()
	_threads.erase(thread)




func request_mesh(signal_id:String, geometry:int, lod:int):
	var gen_thread = Thread.new()
	_threads.append(gen_thread)
	self.add_user_signal(signal_id)
	var thread_data = {
		'thread': gen_thread,
		'geometry': geometry,
		'lod': lod,
		'signal_id': signal_id
	}
	gen_thread.start(self, 'mesh_from_data', thread_data)
	print('Thread ', gen_thread.get_id(), ' started')




func construct_mesh(arrays:Array, smoothing:bool = true):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_smooth_group(smoothing)
	# Input data
	if arrays[Mesh.ARRAY_TEX_UV] != null:
		for uv in arrays[Mesh.ARRAY_TEX_UV]:
			st.add_uv(uv)
	for vtx in arrays[Mesh.ARRAY_VERTEX]:
		st.add_vertex(vtx)
	for ind in arrays[Mesh.ARRAY_INDEX]:
		st.add_index(ind)
	# Generate normals/tangents
	st.generate_normals()
	if arrays[Mesh.ARRAY_TEX_UV] != null:
		st.generate_tangents()
	return st.commit()




func generate_cube_sphere(resolution:int):
	var vertices:PoolVector3Array
	var indices:PoolIntArray
	var vertices_per_side = resolution * resolution
	for i in range(6):
		var local_up:Vector3 = directions[i]
		var axisA:Vector3 = Vector3(local_up.y, local_up.z, local_up.x)
		var axisB:Vector3 = local_up.cross(axisA)
		
		for y in range(resolution):
			for x in range(resolution):
				var percent:Vector2 = Vector2(x, y) / (resolution - 1)
				var point_on_cube:Vector3 = local_up + (percent.x - .5) * 2 * axisA + (percent.y - .5) * 2 * axisB
				var point_on_sphere:Vector3 = point_on_cube.normalized()
				#sur_tool.add_uv(percent)
				vertices.append(point_on_sphere)
				
				var index = x + y * resolution + vertices_per_side * i
				if x != resolution - 1 and y != resolution - 1:
					indices.append(index)
					indices.append(index + resolution)
					indices.append(index + resolution + 1)
					
					indices.append(index)
					indices.append(index + resolution + 1)
					indices.append(index + 1)
	# Return as constructed array
	var arrays = Array()
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays




func generate_ico_sphere(subdivisions:int):
	var vertices:PoolVector3Array = PoolVector3Array()
	vertices.resize(12)
	var indices:PoolIntArray = PoolIntArray()
	indices.resize(60)
	
	var h_angle1:float = -PI / 2 - H_ANGLE / 2;
	var h_angle2:float = -PI / 2
	
	vertices[0] = Vector3(0, 0, 1)
	for i in range(5):
		var z:float = sin(V_ANGLE)
		var xy:float = cos(V_ANGLE)
		vertices[i + 1] = Vector3(xy * cos(h_angle1), xy * sin(h_angle1), z)
		vertices[i + 6] = Vector3(xy * cos(h_angle2), xy * sin(h_angle2), -z)
		h_angle1 += H_ANGLE
		h_angle2 += H_ANGLE
	vertices[11] = Vector3(0, 0, -1)
	
	for i in range(5):
		var ind:int = i * 3
		var shift:int = 15
		var v1:int = i + 1
		var v2:int = i + 2
		var v3:int = i + 6
		var v4:int = i + 7
		if i == 4:
			v2 = 1
			v4 = 6
		#Top
		indices[ind] = 0
		indices[ind + 1] = v2
		indices[ind + 2] = v1
		# Sides
		indices[ind + shift] = v1
		indices[ind + shift + 1] = v2
		indices[ind + shift + 2] = v3
		
		indices[ind + shift * 2] = v3
		indices[ind + shift * 2 + 1] = v2
		indices[ind + shift * 2 + 2] = v4
		# Bottom
		indices[ind + shift * 3] = v3
		indices[ind + shift * 3 + 1] = v4
		indices[ind + shift * 3 + 2] = 11
	# Subdivision
	#         V1       
	#        / \       
	#   nV1 *---* nV3
	#      / \ / \     
	#    V2---*---V3   
	#        nV2      
	for sub in range(subdivisions):
		var new_indices:PoolIntArray = PoolIntArray()
		for i in range(indices.size() / 3):
			var v1i = indices[i * 3]
			var v2i = indices[i * 3 + 1]
			var v3i = indices[i * 3 + 2]
			
			var nv1 = half_vertex(vertices[v1i], vertices[v2i])
			var nv2 = half_vertex(vertices[v2i], vertices[v3i])
			var nv3 = half_vertex(vertices[v1i], vertices[v3i])
			
			vertices.append(nv1) # Index: s - 2
			vertices.append(nv2) # Index: s - 1
			vertices.append(nv3) # Index: s
			var nv1i = vertices.size() - 3
			var nv2i = vertices.size() - 2
			var nv3i = vertices.size() - 1
			
			new_indices.append_array([v1i, nv1i, nv3i])
			new_indices.append_array([nv1i, v2i, nv2i])
			new_indices.append_array([nv1i, nv2i, nv3i])
			new_indices.append_array([nv3i, nv2i, v3i])
		indices = new_indices
	
	# Return as constructed array
	var arrays = Array()
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays




# Returns vertex between two
func half_vertex(v1:Vector3, v2:Vector3):
	return Vector3(
		v1.x + v2.x,
		v1.y + v2.y,
		v1.z + v2.z
	).normalized()

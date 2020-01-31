extends Spatial

const V_ANGLE = atan(1.0 / 2.0)
const H_ANGLE = PI / 180.0 * 72.0

func _ready():
	var arrays = PlanetGen.generate_ico_sphere(7)
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	$SurfaceMesh.mesh = PlanetGen.construct_mesh(arrays)

func half_vertex(v1:Vector3, v2:Vector3):
	return Vector3(
		v1.x + v2.x,
		v1.y + v2.y,
		v1.z + v2.z
	).normalized()

func st_arrays(arrays):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vtx in arrays[Mesh.ARRAY_VERTEX]:
		st.add_vertex(vtx)
	for ind in arrays[Mesh.ARRAY_INDEX]:
		st.add_index(ind)
	st.generate_normals()
	var mesh = st.commit()
	return mesh

func build_ico(subs:int):
	var vertices = PoolVector3Array()
	vertices.resize(12)
	var indices = PoolIntArray()
	indices.resize(60)
	
	var h_angle1 = -PI / 2 - H_ANGLE / 2;
	var h_angle2 = -PI / 2
	
	vertices[0] = Vector3(0, 0, 1)
	for i in range(5):
		var z = sin(V_ANGLE)
		var xy = cos(V_ANGLE)
		vertices[i + 1] = Vector3(xy * cos(h_angle1), xy * sin(h_angle1), z)
		vertices[i + 6] = Vector3(xy * cos(h_angle2), xy * sin(h_angle2), -z)
		h_angle1 += H_ANGLE
		h_angle2 += H_ANGLE
	vertices[11] = Vector3(0, 0, -1)
	
	for i in range(5):
		var ind = i * 3
		var shift = 15
		var v1 = i + 1
		var v3 = i + 6
		var v2 = i + 2
		var v4 = i + 7
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
	for sub in range(subs):
		var start_time = OS.get_ticks_usec()
		var new_indices:PoolIntArray = PoolIntArray()
		#         v1       
		#        / \       
		#   nV1 *---* nV3
		#      / \ / \     
		#    v2---*---v3   
		#        nV2      
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
		var elapsed_time = (OS.get_ticks_usec() - start_time) / 1000000.0
		print('Subdivision ', sub + 1 ,' done in ', elapsed_time ,'s')
	
	# Return as constructed array
	var arrays = Array()
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays
	
	
	

tool
extends EditorScript

const directions:PoolVector3Array = PoolVector3Array([
	Vector3.BACK,Vector3.DOWN, Vector3.FORWARD,
	Vector3.LEFT, Vector3.RIGHT, Vector3.UP
])
const lods:PoolIntArray = PoolIntArray([32, 64, 128, 256])

func _run():
	print('MeshGen started.')
	
	var mesh_data:Dictionary = {}
	for cur_lod in lods:
		var start_time = OS.get_ticks_usec()
		printraw('Generating x', cur_lod, '...')
		var lod_data = generate_mesh_data(cur_lod)
		mesh_data[str(cur_lod)] = lod_data
		var elapsed_time = (OS.get_ticks_usec() - start_time) / 1000000.0
		print('OK (', elapsed_time ,'s)')
	
	printraw('Writing to file...')
	var start_time = OS.get_ticks_usec()
	var file = File.new()
	file.open('res://planet_mesh_data.res', File.WRITE)
	file.store_var(mesh_data)
	file.close()
	var elapsed_time = (OS.get_ticks_usec() - start_time) / 1000000.0
	print('OK (', elapsed_time ,'s)')
	print('Done!')

func generate_mesh_data(resolution:int):
	var verts_per_side = resolution * resolution
	var vertices:PoolVector3Array = PoolVector3Array()
	var uvs:PoolVector2Array = PoolVector2Array()
	var indices:PoolIntArray = PoolIntArray()
	
	for i in range(6):
		var face_data = generate_mesh_face(directions[i], verts_per_side * i, resolution)
		vertices.append_array(face_data[0])
		uvs.append_array(face_data[1])
		indices.append_array(face_data[2])
	
	return [vertices, uvs, indices]

func generate_mesh_face(local_up:Vector3, global_index:int, resolution:int):
	var axisA:Vector3 = Vector3(local_up.y, local_up.z, local_up.x)
	var axisB:Vector3 = local_up.cross(axisA)
	
	var vertices:PoolVector3Array
	var uvs:PoolVector2Array
	var indices:PoolIntArray
	
	for y in range(resolution):
		for x in range(resolution):
			var percent:Vector2 = Vector2(x, y) / (resolution - 1)
			var point_on_cube:Vector3 = local_up + (percent.x - .5) * 2 * axisA + (percent.y - .5) * 2 * axisB
			var point_on_sphere:Vector3 = point_on_cube.normalized()
			uvs.append(percent)
			vertices.append(point_on_sphere)
			
			var index = x + y * resolution + global_index
			if x != resolution - 1 and y != resolution - 1:
				indices.append(index)
				indices.append(index + resolution)
				indices.append(index + resolution + 1)
				
				indices.append(index)
				indices.append(index + resolution + 1)
				indices.append(index + 1)
	return [vertices, uvs, indices]

extends MeshInstance

# Input graph - base triangle layout with flow calculated
var input

# This is the input class: a basic collection of triangles
var Graph = load("res://Graph.gd")

func do_flowmesh():

	self.priority_flood()

	self.set_mesh(create_mesh())

class VertexYSort:
	static func sort_by_y(a, b):
		# Sort by y then, z then x
		if a.pos.y > b.pos.y: 
			return true
		elif a.pos.y == b.pos.y:
			if a.pos.z < b.pos.z:
				return true
			elif a.pos.z == b.pos.z:
				if a.pos.x < b.pos.x:
					return true
		return false

static func place_vertex_in_list(list, v):
	var v_ind = list.bsearch_custom(v, VertexYSort, "sort_by_y")
	if v_ind >= 0 and v_ind < len(list) and v.equals(list[v_ind]):
		v = list[v_ind]
	else:
		list.insert(v_ind, v)
		v.closed = true
	return v

func priority_flood():
	# Add all edge vertices to a queue
	var queue = []
	for edge in input.edges:
		if len(edge.tris) == 1:
			for v in [edge.v1, edge.v2]:
				if not v.closed:
					place_vertex_in_list(queue, v)

	print(str(len(queue)), " edge vertices added to queue")
	
	# Take each queued point and process it
	while not queue.empty():
		var v = queue.pop_back()
		# Get the neighbours of v
		for n in v.connectors:
			if n.closed: continue
			n.water_height = max(v.water_height, n.water_height)
			place_vertex_in_list(queue, n)


func create_mesh():
	if not input:
		print("No input or no surface tool supplied!")
		return
	
	# Create a new mesh
	var mesh = Mesh.new()
	var surfTool = SurfaceTool.new()

	# surfTool.begin(Mesh.PRIMITIVE_LINES)
	# surfTool.add_color(Color(1.0, 1.0, 1.0, 1.0))
	
	# # Put all vertices in for indexing
	# for vert in input.vertices:
	# 	var water_vert = Vector3(vert.pos.x, vert.water_height, vert.pos.z)
	# 	surfTool.add_vertex(water_vert)

	# # Draw all edges that aren't just land
	# for edge in input.edges:
	# 	if edge.v1.water_height == edge.v2.water_height:
	# 		surfTool.add_index(edge.v1.index)
	# 		surfTool.add_index(edge.v2.index)
		
	# # # Draw dependency lines
	# # for vert in input.vertices:
	# # 	if vert.dependancy:
	# # 		surfTool.add_index(vert.index)
	# # 		surfTool.add_index(vert.dependancy.index)
	
	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in input.triangles:
		if tri.v1.water_height == tri.v2.water_height and \
				tri.v1.water_height == tri.v3.water_height:
			for vert in [tri.v1, tri.v3, tri.v2]:
				var water_vert = Vector3(vert.pos.x, vert.water_height, vert.pos.z)
				add_coloured_vertex(surfTool, water_vert)
	surfTool.generate_normals()

	# Create mesh with SurfaceTool
	surfTool.commit(mesh)
	return mesh

func add_coloured_vertex(surfTool, pos):
	var red = 0.1
	var green = 0.1
	var blue = 1.0
	surfTool.add_color(Color(red, green, blue, 1.0))
	surfTool.add_vertex(pos)
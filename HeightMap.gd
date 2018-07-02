extends MeshInstance

# Input graph - base triangle layout
var input

# This is the input class - May not actually need to load this
var Graph = load("res://Graph.gd")

const render_options = [
	Mesh.PRIMITIVE_POINTS,
	Mesh.PRIMITIVE_LINES,
	Mesh.PRIMITIVE_TRIANGLES,
]

var render_as = 1

# Hide/Show
func _input(event):
	if event.is_action_pressed("toggle_height_map"):
		visible = not visible
	if event.is_action_pressed("toggle_height_map_mode"):
		render_as = (render_as + 1) % len(render_options)
		print ("changing render to: ", str(render_options[render_as]))
		self.set_mesh(create_mesh())

func do_heightmap():
	# Update the input graph to give variable heights
	# add_height_features()

	# Creating drawing elements
	# Create a mesh from the voronoi site info
	self.set_mesh(create_mesh())

func create_mesh():
	if not input:
		print("No input or no surface tool supplied!")
		return

	# Update the vertex indices
	input.update_vertex_indices()
	
	# Create a new mesh
	var mesh = Mesh.new()
	var surfTool = SurfaceTool.new()

	match render_options[render_as]:
		Mesh.PRIMITIVE_POINTS:
			surfTool.begin(Mesh.PRIMITIVE_POINTS)
			surfTool.add_color(Color(1.0, 1.0, 1.0, 1.0))
			for vert in input.vertices:
				surfTool.add_vertex(vert.pos)
				surfTool.add_index(vert.index)

		Mesh.PRIMITIVE_LINES:
			surfTool.begin(Mesh.PRIMITIVE_LINES)
			surfTool.add_color(Color(1.0, 1.0, 1.0, 1.0))
			for vert in input.vertices:
				surfTool.add_vertex(vert.pos)
			for edge in input.edges:
				surfTool.add_index(edge.v1.index)
				surfTool.add_index(edge.v2.index)

		Mesh.PRIMITIVE_TRIANGLES:
			surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
			for tri in input.triangles:
				surfTool.add_color(Color(1.0, 0.0, 1.0, 1.0))
				surfTool.add_vertex(tri.v1.pos)
				surfTool.add_color(Color(1.0, 1.0, 0.0, 1.0))
				surfTool.add_vertex(tri.v3.pos)
				surfTool.add_color(Color(0.0, 1.0, 1.0, 1.0))
				surfTool.add_vertex(tri.v2.pos)
			
			# surfTool.index()
			surfTool.generate_normals()

		_:
			print("Unsupported render type!")

	# Create mesh with SurfaceTool
	surfTool.commit(mesh)
	return mesh

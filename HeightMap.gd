extends MeshInstance

# Input graph - base triangle layout
var input

var Perlin = load("res://PerlinRef.gd")

const render_options = [
	Mesh.PRIMITIVE_POINTS,
	Mesh.PRIMITIVE_LINES,
	Mesh.PRIMITIVE_TRIANGLES,
]

var render_as = 2

var color_scale

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
	add_base_height_features()

	# Try to describe water movement dependency
	input.create_flow_trees()

	# Erode
	input.erode_height_features()

	# Creating drawing elements
	# Create a mesh from the voronoi site info
	self.set_mesh(create_mesh())

func add_base_height_features():
	var zoom = 0.5
	var procs = [
		Perlin.new(0.125, 0.125, 1.0, zoom),
		Perlin.new(0.03125, 0.03125, 1.0, zoom),
		Perlin.new(0.0078125, 0.0078125, 1.0, zoom),
	]

	input.create_height_features(procs, 0.125, 0.25, 0.125)

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
			# Recalculate the colour scale
			color_scale = (2.0 / (input.max_height - input.min_height))

			surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
			for tri in input.triangles:
				add_coloured_vertex(surfTool, tri.v1.pos)
				add_coloured_vertex(surfTool, tri.v3.pos)
				add_coloured_vertex(surfTool, tri.v2.pos)
			
			# surfTool.index()
			surfTool.generate_normals()

		_:
			print("Unsupported render type!")

	# Create mesh with SurfaceTool
	surfTool.commit(mesh)
	return mesh

func add_coloured_vertex(surfTool, pos):
	var height = pos.y
	var red = max(((height - input.min_height) * color_scale) - 1.0, 0.0)
	var green = min((height - input.min_height) * color_scale, 1.0)
	var blue = max(((height - input.min_height) * color_scale) - 1.0, 0.0)
	surfTool.add_color(Color(red, green, blue, 1.0))
	surfTool.add_vertex(pos)
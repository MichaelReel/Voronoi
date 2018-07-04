extends MeshInstance

# Input graph - base triangle layout with flow calculated
var input

func do_flowmesh():
	self.set_mesh(create_mesh())

func create_mesh():
	if not input:
		print("No input or no surface tool supplied!")
		return
	
	# Create a new mesh
	var mesh = Mesh.new()
	var surfTool = SurfaceTool.new()

	surfTool.begin(Mesh.PRIMITIVE_LINES)
	surfTool.add_color(Color(1.0, 1.0, 1.0, 1.0))
	
	# Put all vertices in for indexing
	for vert in input.vertices:
		surfTool.add_vertex(vert.pos)

	# Create dependency lines
	for vert in input.vertices:
		if vert.dependancy:
			surfTool.add_index(vert.index)
			surfTool.add_index(vert.dependancy.index)
	
	# Create mesh with SurfaceTool
	surfTool.commit(mesh)
	return mesh
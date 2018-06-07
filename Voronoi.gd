extends MeshInstance

export var wireframe = true
export var smooth_shading = false

# A Vector3-array for delaunay triangulator
var delaunay_tris = []

# Stuff for generating mesh
var surfTool = SurfaceTool.new()
var verts = []
var edges = []

# How long does vonoroi take
var generation_time = 0.0

# Status text
var status_text = ""

# Controls
func _on_Wireframe_CheckBox_toggled( pressed ):
	wireframe = pressed

func _on_SmoothShading_CheckBox_toggled( pressed ):
	smooth_shading = pressed

func update_counters():
	var s = "Verts: " + str(verts.size())
	s += "\nEdges: " + str(edges.size())
	s += "\n\nFPS: " + str(Engine.get_frames_per_second())
	s += "\nmsec: " + str(generation_time)
	status_text = s

func do_voronoi():
	generation_time = OS.get_ticks_msec()
	
	# Do the Voronoi calculations
	create_voronoi_graph()
	
	# Use SurfaceTool to create a surface
	CreateSurface()
	
	# Create a mesh from the SurfaceTool
	self.set_mesh(CreateMesh())
	
	generation_time = OS.get_ticks_msec() - generation_time
	update_counters()
	print(status_text)

func CreateSurface():

	# Clear previous data from SurfaceTool
	surfTool.clear()
	
	# Wireframe mode only unless we split voronoi polygons
	surfTool.begin(Mesh.PRIMITIVE_LINES)
	
	# Smooth or flat shading
	if smooth_shading:
		surfTool.add_smooth_group(true)
	
	# Add vertices and UV to SurfaceTool
	var i = 0
	while i < verts.size():
		surfTool.add_uv(Vector2(verts[i].x/100+0.5,verts[i].z/100+0.5))
		surfTool.add_vertex(verts[i])
		i += 1
	
	# Add indices to SurfaceTool
	i = 0
	while i < edges.size():
		surfTool.add_index(edges[i].p1)
		surfTool.add_index(edges[i].p2)
		i += 1
	return surfTool

func CreateMesh():

	# Create a new mesh
	var mesh = Mesh.new()

	# Create mesh with SurfaceTool
	surfTool.index()
	surfTool.commit(mesh)
	
	return mesh

class Edge:
	var p1
	var p2
	func _init(var point1, var point2):
		p1 = point1
		p2 = point2
	func Equals(var other):
		return ((p1 == other.p2) && (p2 == other.p1)) || ((p1 == other.p1) && (p2 == other.p2))

func create_voronoi_graph():

	# The circumcentres of the delaunay triangles make up the vertices
	# The edges are between circumcenters of connected triangles
	var ti = 0
	while ti < delaunay_tris.size():
		verts.append(delaunay_tris[ti].circumcenter)
		ti += 1
	# Add edges for each connected triangle
	ti = 0
	while ti < delaunay_tris.size():
		for con_vert_ind in delaunay_tris[ti].connected:
			# Try to avoid duplicating edges
			if con_vert_ind > ti:
				edges.append(Edge.new(ti, con_vert_ind))
		ti += 1

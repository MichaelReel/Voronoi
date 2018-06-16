extends MeshInstance

export var wireframe = true
export var smooth_shading = false

# Simple x/z bounds
var bounds = Rect2(0.0, 0.0, 1.0, 1.0)

# A Vector3-array for delaunay triangulator
var delaunay_verts = []
var delaunay_tris = []

# Stuff for generating mesh
var surfTool = SurfaceTool.new()
var verts = []
var cells = []
var edges = []

# Some internal bounds collisions
var out_edges = []
var border_cells = []

# How long does vonoroi take
var generation_time = 0.0

# Status text
var status_text = ""

# Controls
func _on_Wireframe_CheckBox_toggled( pressed ):
	wireframe = pressed

func _on_SmoothShading_CheckBox_toggled( pressed ):
	smooth_shading = pressed

func _input(event):
	if event.is_action_pressed("toggle_voronoi"):
		visible = not visible

func update_counters():
	var s = "Verts: " + str(verts.size())
	s += "\nEdges: " + str(edges.size())
	s += "\n\nFPS: " + str(Engine.get_frames_per_second())
	s += "\nmsec: " + str(generation_time)
	status_text = s

func do_voronoi():
	generation_time = OS.get_ticks_msec()

	surfTool.clear()
	verts.clear()
	cells.clear()
	edges.clear()
	print ("Data cleared, creating voronoi graph")
	
	# Do the Voronoi calculations
	create_voronoi_graph()
	print ("voronoi graph created, creating surface")
	
	# Use SurfaceTool to create a surface
	CreateSurface()
	print ("Surface created, setting mesh")
	
	# Create a mesh from the SurfaceTool
	self.set_mesh(CreateMesh())
	print ("Mesh set")
	
	generation_time = OS.get_ticks_msec() - generation_time
	update_counters()
	print(status_text)

func CreateSurface():

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

class Cell:

	var nucleus
	var vs = []
	var es = []

	func _init(var n):
		nucleus = n

	func add_edge(var ei, var edge):
		es.append(ei)
		add_vert(edge.p1)
		add_vert(edge.p2)

	func add_vert(vert):
		if not vs.has(vert):
			vs.append(vert)

func create_voronoi_graph():

	var out_verts = []

	# Create a index-matched polygon array for delaunay verts
	print ("Creating index matched polygon array")
	var vi = 0
	while vi < delaunay_verts.size():
		cells.append(Cell.new(delaunay_verts[vi]))
		vi += 1

	# The circumcentres of the delaunay triangles make up the vertices
	# The edges are between circumcenters of connected triangles
	print ("Adding circumcenters to vertex array")
	var ti = 0
	while ti < delaunay_tris.size():
		var new_vert = delaunay_tris[ti].circumcenter
		verts.append(new_vert)
		if out_of_bounds(new_vert):
			out_verts.append(ti)
		ti += 1

	# Add edges for each connected triangle
	print ("Adding edges from each triangle")
	ti = 0
	while ti < delaunay_tris.size():

		# Each triangle circumcenter connected to this one
		# The verts index created above is the same as the tris index
		# print ("triangle index ", ti)
		for ci in delaunay_tris[ti].connected:

			# Try to avoid duplicating edges - only join unvisited verts
			# print ("connected index ", ci)
			if ci > ti:
				var edge = Edge.new(ti, ci)
				var ei = len(edges)
				edges.append(edge)
				# check if this edge goes out of bounds
				if out_verts.has(ci) or out_verts.has(ti):
					out_edges.append(ei)
				# This edge will also belong to 2 cells
				update_cells(ti, ci, ei)
		ti += 1

	# Do something with border edges
	print ("Border vertices: ", len(out_verts), "/", len(verts))
	print ("Border edges: ", len(out_edges), "/", len(edges))
	print ("Border cells: ", len(border_cells), "/", len(cells))

func out_of_bounds(var vert):
	if vert.x < bounds.position.x:
		return true
	if vert.x > bounds.end.x:
		return true
	if vert.z < bounds.position.y:
		return true
	if vert.z > bounds.end.y:
		return true
	return false

func update_cells(var tri1, var tri2, var ei):
	# print ("update_cells(", tri1, ", ", tri2, ", ", edge, ")")
	# Find which 2 vertex indices are in both tris
	var verts1 = [delaunay_tris[tri1].p1, delaunay_tris[tri1].p2, delaunay_tris[tri1].p3]
	var verts2 = [delaunay_tris[tri2].p1, delaunay_tris[tri2].p2, delaunay_tris[tri2].p3]
	var shared_verts = intersection(verts1, verts2)

	for vert_ind in shared_verts:
		# Update the same indexed cell to add the edge
		cells[vert_ind].add_edge(ei, edges[ei])
		if out_edges.has(ei):
			border_cells.append(vert_ind)

func intersection(var array1, var array2):
	var return_array = []
	for item in array1:
		if array2.has(item):
			return_array.append(item)
	return return_array
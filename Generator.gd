extends Spatial

# # Later, should look at fortunes algorithm

export (int) var vertex_count = 256
export (int) var seedy = 0

var delaunay_vertices = []  # Vector3
var voronoi_vertices = []

func _ready():
	print("starting")

	# Called every time the node is added to the scene.
	# Initialization here
	seed(seedy)
	
	# Create an initial set of vertices
	print("create vertices")
	create_vertices()

	# Process points via delaunay and voronoi
	print("Process points via delaunay")
	$Delaunay.points = delaunay_vertices
	$Delaunay.do_delaunay()

	print("Process points via voronoi")
	$Voronoi.delaunay_verts = delaunay_vertices
	$Voronoi.do_voronoi()

	# # Use lloyds to reposition the vertices
	# print("Improve vertices")
	# voronoi_vertices = $Voronoi.verts
	# improve_vertices($Voronoi.cells)

	# # Process points via delaunay and voronoi
	# print("Process points via delaunay and voronoi")
	# $Delaunay.points = delaunay_vertices
	# $Delaunay.do_delaunay()
	# $Voronoi.delaunay_verts = $Delaunay.verts
	# $Voronoi.delaunay_tris = $Delaunay.tris

	# $Voronoi.do_voronoi()

func create_vertices():
	# Fully random point set:
	for i in range(vertex_count):
		delaunay_vertices.append(Vector3(randf(), 0, randf()))
	
	# # Some debugging grid point set (ignoring vertex_count):
	# var p = 1.0 / 128
	# var i = 1.0 / 32
	# for x in range(32):
	# 	for z in range(32):
	# 		# # Grid: 
	# 		# delaunay_vertices.append(Vector3(p * 2 + (x * i), 0, p * 2 + (z * i)))
	# 		# Wobbly Grid:
	# 		delaunay_vertices.append(Vector3(p + (x * i) + (randf() * p), 0, p + (z * i) + (randf() * p)))
	


func improve_vertices(var cells):
	# We can use Lloyds algorithm for to recalculate the delaunay vertices
	# As long as delaunay and voronoi have already been processed
	# The new set of points need to be processed againt to see the 
	# results of convergence
	delaunay_vertices.clear()
	var speed = 1.0
	for cell in cells:
		var centroid = get_average_vertex(cell.vs)
		# print ("Average of ", cell.vs, " is ", centroid)
		var nucleus = cell.nucleus
		var new_pos = (centroid)
		delaunay_vertices.append(new_pos)

func get_average_vertex(var vertex_list):
	var vert_avg = Vector3()
	var vert_count = len(vertex_list)
	if vert_count > 0:
		for vert in vertex_list:
			vert_avg += voronoi_vertices[vert]
		vert_avg /= vert_count

	return vert_avg

extends Spatial

# # Later, should look at fortunes algorithm

export (int) var vertex_count = 256
export (int) var seedy = 0

var delaunay_vertices = []  # Vector3

func _ready():

	# Called every time the node is added to the scene.
	# Initialization here
	seed(seedy)
	create_vertices()
	
# 	improve_vertices()

	$Delaunay.points = delaunay_vertices
	$Delaunay.do_delaunay()

	$Voronoi.delaunay_tris = $Delaunay.tris
	$Voronoi.do_voronoi()

func create_vertices():
	for i in range(vertex_count):
		delaunay_vertices.append(Vector3(randf(), 0, randf()))

# func improve_vertices():
# 	pass





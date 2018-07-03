extends Spatial

# # Later, should look at fortunes algorithm

export (int) var vertex_count = 256
export (int) var seedy = 0
export (int) var improve_runs = 10

var delaunay_vertices = []  # Vector3

func _ready():
	print("starting")

	# Called every time the node is added to the scene.
	# Initialization here
	seed(seedy)
	
	# Create an initial set of vertices
	print("create vertices")
	create_vertices()

	print("Process points via voronoi")
	$Voronoi.delaunay_verts = delaunay_vertices
	$Voronoi.do_voronoi()
	for i in improve_runs:
		$Voronoi.improve_vertices()
	
	var graph = $Voronoi.create_graph()
	$Voronoi.clear_voronoi_data()

	$HeightMap.input = graph
	$HeightMap.do_heightmap()

func create_vertices():
	# Fully random point set:
	for i in range(vertex_count):
		delaunay_vertices.append(Vector3(randf(), 0, randf()))

extends Spatial

# # Later, should look at fortunes algorithm

export (int) var vertex_count = 256
export (int) var seedy = 0
export (int) var improve_runs = 10

var delaunay_vertices = []  # Vector3

func start_generation(progress_bar):
	print("starting")

	# Called every time the node is added to the scene.
	# Initialization here
	seed(seedy)
	
	progress_bar.value = 10

	# Create an initial set of vertices
	print("create vertices")
	create_vertices()
	
	progress_bar.value = 20

	print("Process points via voronoi")
	$Voronoi.delaunay_verts = delaunay_vertices
	$Voronoi.do_voronoi()

	progress_bar.value = 30

	var prog_inc = 40 / improve_runs
	for i in improve_runs:
		$Voronoi.improve_vertices()
		progress_bar.value += prog_inc
	
	var graph = $Voronoi.create_graph()
	# $Voronoi.clear_voronoi_data()

	progress_bar.value = 80

	$HeightMap.input = graph
	$HeightMap.do_heightmap()
	
	progress_bar.value = 90

	# graph will have been updated by heightmap
	# (This flow will need a little work to get right)
	# Get FlowDiagram to draw the flows created in height map
	$FlowDiagram.input = graph
	$FlowDiagram.do_flowmesh()

	progress_bar.value = 100

func create_vertices():
	# Fully random point set:
	for i in range(vertex_count):
		delaunay_vertices.append(Vector3(randf(), 0, randf()))

extends Spatial

# # looking at porting the (rather slow) voronoi/delaunay algorithm from:
# # https://bitbucket.org/mykilr/toodeetanks/src/master/proj/TooDeeTanks-core/src/com/chaoslemmings/mykilr/tdtank/common/utils/DelaunayDiagram.java
# #
# # Later, should look at fortunes algorithm

export (int) var vertex_count = 256

# class Edge:
# 	var vertices = []       # array of Vector3
# 	var triangles = []      # array of Polygon

# class Polygon:
	# var vertices = []       # array of Vector3
# 	var edges = []          # array of Edge
# 	var circumcenter        # Vector3

var delaunay_vertices = []  # Vector3
# var delaunay_edges = []     # Edge
# var delaunay_triangles = [] # Polygon

# var voronoi_vertices = []   # Vector3
# var voronoi_edges = []      # Edge
# var voronoi_polygons = []   # Polygon

func _ready():
# 	# Called every time the node is added to the scene.
# 	# Initialization here
	create_vertices()
	$Delaunay.points = delaunay_vertices
	$Delaunay.do_delaunay()

# 	improve_vertices()
# 	calculate_corners()

func create_vertices():
	for i in range(vertex_count):
		delaunay_vertices.append(Vector3(randf(), 0, randf()))

# func improve_vertices():
# 	pass

# func calculate_corners():
# 	pass

# func triangulate():
# 	pass


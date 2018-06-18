extends MeshInstance

# Ripped/ported from libgdx:
# https://github.com/libgdx/libgdx/blob/master/gdx/src/com/badlogic/gdx/math/DelaunayTriangulator.java

# To use:
	# append points to the array points[]
	# call do_delaunay()

export var wireframe = true
export var smooth_shading = false

# I don't know the real epsilon in Godot (it's tiny), but this works
var float_Epsilon = 0.0000001

# A Vector3-array for delaunay triangulator
var points = []

# Stuff for generating mesh
var surfTool = SurfaceTool.new()
var verts = []
var tris = []

# how long does triangulation take
var generation_time = 0.0

# Text
var status_text = ""

# Controls
func _on_Wireframe_CheckBox_toggled( pressed ):
	wireframe = pressed

func _on_SmoothShading_CheckBox_toggled( pressed ):
	smooth_shading = pressed

func _input(event):
	if event.is_action_pressed("toggle_delaunay"):
		visible = not visible

func update_counters():
	var s = "Verts: " + str(verts.size())
	s += "\nTris: " + str(tris.size())
	s += "\n\nFPS: " + str(Engine.get_frames_per_second())
	s += "\nmsec: " + str(generation_time)
	status_text = s

func do_delaunay():

	generation_time = OS.get_ticks_msec()
	
	# Do the Delaunay triangulation
	Triangulate()
	
	# Use SurfaceTool to create a surface
	CreateSurface()
	
	# Create a mesh from the SurfaceTool
	self.set_mesh(CreateMesh())
	
	generation_time = OS.get_ticks_msec() - generation_time
	update_counters()
	print(status_text)

class VectorXSort:
	static func sort(a, b):
		return a.x < b.x

func Triangulate():
	
	# Clear any existing data
	# uv.clear()
	surfTool.clear()
	verts.clear()
	tris.clear()
	
	# Create vertices and uv
	var i = 0
	while i<points.size():
		verts.append(Vector3(points[i].x, points[i].y, points[i].z))
		i+=1

	# Sort the verts by the x axis
	verts.sort_custom(VectorXSort, "sort")
	
	# Create triangle indices
	tris = triangulate_polygons(verts)
	for tri in tris:
		create_circumcenter(tri)
		create_connected(tri)

	
func CreateSurface():

	# Select primitive mode
	if wireframe:
		surfTool.begin(Mesh.PRIMITIVE_LINES)
	else:
		surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
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
	while i < tris.size():
		if wireframe:
			surfTool.add_index(tris[i].p1)
			surfTool.add_index(tris[i].p2)
			
			surfTool.add_index(tris[i].p2)
			surfTool.add_index(tris[i].p3)
			
			surfTool.add_index(tris[i].p3)
			surfTool.add_index(tris[i].p1)
		else:
			surfTool.add_index(tris[i].p1)
			surfTool.add_index(tris[i].p2)
			surfTool.add_index(tris[i].p3)
		i += 1
	return surfTool
	

func CreateMesh():
	
	# Create a new mesh
	var mesh = Mesh.new()
	
	# Generate normals if needed
	if wireframe==false && tris.size()>0:
		surfTool.generate_normals()
	
	# Create mesh with SurfaceTool
	surfTool.index()
	surfTool.commit(mesh)
	
	return mesh

## Delaunay-code ##

# classes for delaunay
class Triangle:
	var p1
	var p2
	var p3
	var circumcenter
	var connected

	func _init(var point1, var point2, var point3):
		p1 = point1
		p2 = point2
		p3 = point3

class Edge:
	var p1
	var p2
	func _init(var point1, var point2):
		p1 = point1
		p2 = point2
	func Equals(var other):
		return ((p1 == other.p2) && (p2 == other.p1)) || ((p1 == other.p1) && (p2 == other.p2))

func triangulate_polygons(pts):
	var triangles = []
	var end = len(pts)
	if end < 3:
		return triangles

	# Determine bounds for the super triangle
	var xmin = pts[0].x
	var zmin = pts[0].z
	var xmax = xmin
	var zmax = zmin
	var i = 1
	while i < end:
		var value = points[i].x
		xmin = min(xmin, value)
		xmax = max(xmax, value)
		value = points[i].z
		zmin = min(zmin, value)
		zmax = max(zmax, value)
		i += 1

	# (Find the x and y ranges and mids)
	var dx = xmax - xmin
	var dz = zmax - zmin
	var dmax = max(dx, dz) * 20.0
	var xmid = (xmax + xmin) / 2.0
	var zmid = (zmax + zmin) / 2.0

	# Setup the super triangle, which should contain all the points
	var superTri = []
	superTri.append(Vector3(xmid - dmax, 0, zmid - dmax))
	superTri.append(Vector3(xmid       , 0, zmid + dmax))
	superTri.append(Vector3(xmid + dmax, 0, zmid - dmax))

	# Setup edge storage
	var edgs = []
	var complete = []

	# Add super triangle indices (indices > end == superTri)
	triangles.append(end)
	triangles.append(end + 1)
	triangles.append(end + 2)
	complete.append(false)

	# Include each point (one at a time) into the existing mesh
	var pt_ind = 0
	for pt in pts:

		var x = pt.x
		var z = pt.z

		# If x,z lies inside the circumcircle of a triangle, the edges are stored and the triangle removed
		var tri_ind = len(triangles) - 1
		while tri_ind >= 0:

			var com_ind = tri_ind / 3
			if complete[com_ind]:
				tri_ind -= 3
				continue
			
			# Get the revelant points
			var p_inds = [triangles[tri_ind - 2], triangles[tri_ind - 1], triangles[tri_ind]]
			
			# Get the relevant positional info
			var x_p = []
			var z_p = []

			for j in range(3):
				if p_inds[j] >= end:
					i = p_inds[j] - end
					x_p.append(superTri[i].x)
					z_p.append(superTri[i].z)
				else:
					i = p_inds[j]
					x_p.append(pts[i].x)
					z_p.append(pts[i].z)
			
			# Find if we're inside if x,z is in the circumcircle
			var circum = circumcircle(x, z, x_p[0], z_p[0], x_p[1], z_p[1], x_p[2], z_p[2])
			
			if circum == CIRC.COMPLETE:
				complete[com_ind] = true
			elif circum == CIRC.INSIDE:
				edgs.append(p_inds[0])
				edgs.append(p_inds[1])
				edgs.append(p_inds[1])
				edgs.append(p_inds[2])
				edgs.append(p_inds[2])
				edgs.append(p_inds[0])

				triangles.remove(tri_ind)
				triangles.remove(tri_ind - 1)
				triangles.remove(tri_ind - 2)
				complete.remove(com_ind)
			tri_ind -= 3
	
		# print ("DBG: ", 12)

		var n = len(edgs)
		for i in range (0, n, 2):
			# Skip multiple edges. If all tris are anti-wise then all interior edges are opposite pointing
			var p1 = edgs[i]
			if p1 == -1: continue
			var p2 = edgs[i + 1]
			var skip = false
			for ii in range(i + 2, n, 2):
				if p1 == edgs[ii + 1] and p2 == edgs[ii]:
					skip = true
					edgs[ii] = -1
			if skip: continue
			
			# Form new triangles for the current point. Edges are arranged in clockwise order
			triangles.append(p1)
			triangles.append(edgs[i  + 1])
			triangles.append(pt_ind)
			complete.append(false)
		edgs.clear()
		pt_ind += 1

	# Remove triangles with super triangle vertices
	i = len(triangles) - 1
	while i >= 0:
		if triangles[i] >= end or triangles[i - 1] >= end or triangles[i - 2] >= end:
			triangles.remove(i)
			triangles.remove(i - 1)
			triangles.remove(i - 2)
		i -= 3

	# Adjust triangles to classed rather than edge pairs
	var return_triangles = []
	for i in range(0, len(triangles), 3):
		return_triangles.append(Triangle.new(triangles[i], triangles[i + 1], triangles[i + 2]))
	
	return return_triangles

enum CIRC {
	INCOMPLETE,
	COMPLETE,
	INSIDE
}

func circumcircle(xp, yp, x1, y1, x2, y2, x3, y3):
	var xc
	var yc
	var y1y2 = abs(y1 - y2)
	var y2y3 = abs(y2 - y3)
	if y1y2 < float_Epsilon:
		if y2y3 < float_Epsilon: return CIRC.INCOMPLETE
		var m2 = -(x3 - x2) / (y3 - y2)
		var mx2 = (x2 + x3) / 2.0
		var my2 = (y2 + y3) / 2.0
		xc = (x2 + x1) / 2.0
		yc = m2 * (xc - mx2) + my2
	else:
		var m1 = -(x2 - x1) / (y2 - y1)
		var mx1 = (x1 + x2) / 2.0
		var my1 = (y1 + y2) / 2.0
		if y2y3 < float_Epsilon:
			xc = (x3 + x2) / 2.0
			yc = m1 * (xc - mx1) + my1
		else:
			var m2 = -(x3 - x2) / (y3 - y2)
			var mx2 = (x2 + x3) / 2.0
			var my2 = (y2 + y3) / 2.0
			xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2)
			yc = m1 * (xc - mx1) + my1

	var dx = x2 - xc
	var dy = y2 - yc
	var rsqr = dx * dx + dy * dy

	dx = xp - xc
	dy = yp - yc
	if dx * dx + dy * dy - rsqr <= float_Epsilon: return CIRC.INSIDE
	return CIRC.COMPLETE if xp > xc and dx > rsqr else CIRC.INCOMPLETE

# Some extra calculations

func create_circumcenter(tri):
	var d21 = verts[tri.p2] - verts[tri.p1]
	var d32 = verts[tri.p3] - verts[tri.p2]
	var d13 = verts[tri.p1] - verts[tri.p3]
	var det = d32.x * d21.z - d21.x * d32.z
	assert (abs(det) >= float_Epsilon) # Triangle points should not be colinear.
	det *= 2
	var sqr1 = verts[tri.p1].x * verts[tri.p1].x + verts[tri.p1].z * verts[tri.p1].z
	var sqr2 = verts[tri.p2].x * verts[tri.p2].x + verts[tri.p2].z * verts[tri.p2].z
	var sqr3 = verts[tri.p3].x * verts[tri.p3].x + verts[tri.p3].z * verts[tri.p3].z
	var cx =  (sqr1 * d32.z + sqr2 * d13.z + sqr3 * d21.z) / det
	var cy = 0
	var cz = -(sqr1 * d32.x + sqr2 * d13.x + sqr3 * d21.x) / det
	tri.circumcenter = Vector3(cx, cy, cz)

func create_connected(tri):
	# basically find any other triangles that share 2 vertices
	var pt_inds = [tri.p1, tri.p2, tri.p3]
	var connected_tris = []
	var i = 0
	while connected_tris.size() < 3 and i < tris.size():
		var score = 0
		var other = [tris[i].p1, tris[i].p2, tris[i].p3]
		for t in pt_inds:
			for o in other:
				score += 1 if t == o else 0
		if score == 2:
			connected_tris.append(i)
		i+=1
	tri.connected = connected_tris

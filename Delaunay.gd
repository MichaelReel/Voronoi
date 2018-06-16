extends MeshInstance

# Shamelessly ripped-off Delaunay code ported to Godot by Tapio Pyrhönen
# (https://github.com/TassuP/GodotStuff/tree/master/DelaunayTriangulator)
# Based on this: https://gist.github.com/miketucker/3795318

# To use this code in your project:
	# set demo_mode to false,
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
	
	# Create triangle indices
	tris = TriangulatePolygon(verts)
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


#################  The rest is the delaunay-code #################

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


func TriangulatePolygon(XZofVertices):
	var VertexCount = XZofVertices.size()

	# Find minimum and maximum x and y values
	var xmin = XZofVertices[0].x
	var ymin = XZofVertices[0].y
	var xmax = xmin
	var ymax = ymin
	
	var i = 0
	while i < XZofVertices.size():
		var v = XZofVertices[i]
		xmin = min(xmin, v.x)
		ymin = min(ymin, v.y)
		xmax = max(xmax, v.x)
		ymax = max(ymax, v.y)
		i += 1

	# Find the x and y ranges and mids
	var dx = xmax - xmin
	var dy = ymax - ymin
	var dmax = max(dx,dy)
	var xmid = (xmax + xmin) * 0.5
	var ymid = (ymax + ymin) * 0.5
	
	# Copy the input vertices into the expandedXZ array
	var ExpandedXZ = Array()
	i = 0
	while i < XZofVertices.size():
		var v = XZofVertices[i]
		ExpandedXZ.append(Vector3(v.x, -v.z, v.y))
		i += 1
	
	# Add 3 somewhat weird vertices (enclosing tri)
	ExpandedXZ.append(Vector2((xmid - 2 * dmax), (ymid - dmax)))
	ExpandedXZ.append(Vector2(xmid, (ymid + 2 * dmax)))
	ExpandedXZ.append(Vector2((xmid + 2 * dmax), (ymid - dmax)))
	
	var TriangleList = Array()
	# Add an weird triangle made from the 3 weird vertices above
	TriangleList.append(Triangle.new(VertexCount, VertexCount + 1, VertexCount + 2))
	var ii1 = 0
	while ii1 < VertexCount:
		# For each of the original XZofVertices vertices
		var Edges = Array()
		var ii2 = 0
		while ii2 < TriangleList.size():
			# 
			if TriangulatePolygonSubFunc_InCircle(ExpandedXZ[ii1], ExpandedXZ[TriangleList[ii2].p1], ExpandedXZ[TriangleList[ii2].p2], ExpandedXZ[TriangleList[ii2].p3]):
				Edges.append(Edge.new(TriangleList[ii2].p1, TriangleList[ii2].p2))
				Edges.append(Edge.new(TriangleList[ii2].p2, TriangleList[ii2].p3))
				Edges.append(Edge.new(TriangleList[ii2].p3, TriangleList[ii2].p1))
				TriangleList.remove(ii2)
				ii2-=1
			ii2+=1
		
		ii2 = Edges.size()-2
		while ii2 >= 0:
			var ii3 = Edges.size()-1
			while ii3 >= ii2+1:
				if Edges[ii2].Equals(Edges[ii3]):
					Edges.remove(ii3)
					Edges.remove(ii2)
					ii3-=1
				ii3-=1
			ii2-=1
			
		ii2 = 0
		while ii2 < Edges.size():
			TriangleList.append(Triangle.new(Edges[ii2].p1, Edges[ii2].p2, ii1))
			ii2+=1
		Edges.clear()
		ii1 += 1
		
	ii1 = TriangleList.size()-1
	while ii1 >= 0:
		if TriangleList[ii1].p1 >= VertexCount || TriangleList[ii1].p2 >= VertexCount || TriangleList[ii1].p3 >= VertexCount:
			TriangleList.remove(ii1)
		ii1-=1
		
	return TriangleList
	
func TriangulatePolygonSubFunc_InCircle(p, p1, p2, p3):
	if abs(p1.y - p2.y) < float_Epsilon && abs(p2.y - p3.y) < float_Epsilon:
		return false
	var m1
	var m2
	var mx1
	var mx2
	var my1
	var my2
	var xc
	var yc
	if abs(p2.y - p1.y) < float_Epsilon:
		m2 = -(p3.x - p2.x) / (p3.y - p2.y)
		mx2 = (p2.x + p3.x) * 0.5
		my2 = (p2.y + p3.y) * 0.5
		xc = (p2.x + p1.x) * 0.5
		yc = m2 * (xc - mx2) + my2
	elif abs(p3.y - p2.y) < float_Epsilon:
		m1 = -(p2.x - p1.x) / (p2.y - p1.y)
		mx1 = (p1.x + p2.x) * 0.5
		my1 = (p1.y + p2.y) * 0.5
		xc = (p3.x + p2.x) * 0.5
		yc = m1 * (xc - mx1) + my1
	else:
		m1 = -(p2.x - p1.x) / (p2.y - p1.y)
		m2 = -(p3.x - p2.x) / (p3.y - p2.y)
		mx1 = (p1.x + p2.x) * 0.5
		mx2 = (p2.x + p3.x) * 0.5
		my1 = (p1.y + p2.y) * 0.5
		my2 = (p2.y + p3.y) * 0.5
		xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2)
		yc = m1 * (xc - mx1) + my1
		
	var dx = p2.x - xc
	var dy = p2.y - yc
	var rsqr = dx * dx + dy * dy
	dx = p.x - xc
	dy = p.y - yc
	var drsqr = dx * dx + dy * dy
	return (drsqr <= rsqr)

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
	var this = [tri.p1, tri.p2, tri.p3]
	var connected_tris = []
	var i = 0
	while connected_tris.size() < 3 and i < tris.size():
		var score = 0
		var other = [tris[i].p1, tris[i].p2, tris[i].p3]
		for t in this:
			for o in other:
				score += 1 if t == o else 0
		if score == 2:
			connected_tris.append(i)
		i+=1
	tri.connected = connected_tris

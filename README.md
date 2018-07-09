# Voronoi
Experimenting with voronoi map generation

This is a simple (and fairly slow) terrain generator that uses as it's base a voronoi graph to set the base set of triangles.
I wrote this a technical demonstration and to help further my own knowledge of GDScript.

The code is rough, but the basic flow is:

 1. Generate a set of random 2.5D points (y == 0)
 1. Create a voronoi graph from the points
 1. "Improve" the voronoi sites
 1. Use the perlin noise reference to generate a height map
 1. Use the Priority Flood algorithm to figure out major water bodies

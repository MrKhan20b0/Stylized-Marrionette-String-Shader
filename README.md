# Stylized-Marrionette-String-Shader
Stylized shader, perfect for rendering thin strings for a marrionette puppet.

<p align="center">
  <img src="Imgs/demo.gif?raw=true" alt="Demonstration"/>
</p>

### Usage
Use a thin, long, vertical 2D-plane.
Assign the material to the plane.

A unity prefab contains an example for reference

### Limitations
The plane with the attached material must be vertical.
The shader forces the plane to face the direction of the camera, so the objects rotations are ignored.
Skinned meshes do not work.

#### Attribution
Vertex shader code heavily referenced a vertex shader created by Toocanzs & Nestorboy.
See their Vertical-Billboard shader here: https://github.com/Toocanzs/Vertical-Billboard





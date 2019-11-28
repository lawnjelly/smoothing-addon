# smoothing-addon v 1.0.0
Fixed timestep interpolation gdscript addon for Godot 3.2

## About
The smoothing addon adds 2 new nodes to Godot, 'Smoothing' (for 3d) and 'Smoothing2d' (for 2d). They allow for fixed timestep interpolation without writing any code. See here for an explanation of fixed timestep interpolation:<br/>
https://www.gamedev.net/blogs/entry/2265460-fixing-your-timestep-and-evaluating-godot/
<br/>
https://www.youtube.com/watch?v=lWhHBAcH4sM

## Installation

This repository contains the addon (in the addons folder) and an example demo project as a zip file. To examine the demo simply unzip it to a new folder, copy the addons folder into the demo project, and open it from Godot.

To use the addon in your own project:
1. Create a new project in Godot or use an existing project.
2. Copy the 'addons' folder from this repository to your Godot project folder.
3. Go to 'Project Settings' plugins tab.
4. Find the smoothing plugin and set status to 'Active'.

## Usage

### 3D
1. You would usually in a game choose to create a Spatial, RigidBody, Kinematic body etc node for a game object, and have a visual representation (e.g. a MeshInstance) as a child of this node.
2. Do this as normal so that you can see the object moving in the game.
3. Add the new 'Smoothing' node to the scene.
4. Drag the visual representation from being a child of the gameobject node, to being a child of the Smoothing node.
5. The final step is to 'link' the Smoothing node to the gameobject, such that the gameobject is the target, which the smoothing node will follow.
6. Do this by looking in the inspector panel for the Smoothing node, and select the 'Target' to be the gameobject node.
7. That is mainly it! Just run the game and now hopefully the visual representation will follow the gameobject, but now with interpolation. You can test this is working by running at a low physics tick rate (physics_fps in project settings->physics).

### 2D
The procedure for 2D is pretty much the same as with 3D except you would be using a node derived from Node2D as the gameobject (target) and the 'Smoothing2D' node should be used instead of 'Smoothing'.

### Teleporting
The one special case when using smoothing nodes is the case when you want a target to instantaneously move from one location to another (for instance respawning a player, or at level start) where you do not want interpolation from the previous position. In this special case, you should move the target node (by setting the translation or position), and then call the 'teleport' function in the Smoothing node. This ensures that interpolation will be switched off temporarily for the move.

### Other options
As well as choosing the Target, in the inspector for the Smoothing nodes there are a set of flags.

#### 3D
1. enabled - chooses whether the smoothing node is active
2. translate - interpolation will be done for the position
3. basis - interpolation will be done for rotation and scale
4. slerp - this will do quaternion slerping instead of the simpler basis lerping. Note that this only works with no scaling applied to the target.

#### 2D
1. enabled - as above
2. translate - as above
3. rotate - interpolation of the node angle
4. scale - interpolation of the node scale (x and y)
5. global in - will read the global transform of the target instead of local
6. global out - will set the global transform of the smoothing node instead of local

(in most cases local transform will be the best choice)

Processing will also be turned off automatically for the smoothing nodes if they are hidden (either directly or through a parent).

__This addon is also available as a c++ module (slight differences), see:__
https://github.com/lawnjelly/godot-smooth

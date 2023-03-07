# smoothing-addon v 1.1.1
Fixed timestep interpolation gdscript addon for Godot 4.x (and later versions)

If you were wondering how to use that new function `Engine.get_physics_interpolation_fraction()` in 3.2, feel free to use this as is, or to get ideas from for your own version. 

_If you find bugs / have suggestions, please add an issue to the issue tracker and I will look into it!_ :)

## About
The smoothing addon adds 2 new nodes to Godot, 'Smoothing' (for 3d) and 'Smoothing2d' (for 2d). They allow for fixed timestep interpolation without writing any code. See here for an explanation of fixed timestep interpolation:<br/>
https://www.gamedev.net/blogs/entry/2265460-fixing-your-timestep-and-evaluating-godot/
<br/>
https://www.youtube.com/watch?v=lWhHBAcH4sM

## Installation

This repository contains the addon (in the addons folder) and an example demo project.

To use the addon in your own project:
1. Create a new project in Godot or use an existing project.
2. Copy the 'addons' folder from this repository to your Godot project folder.
3. Go to 'Project Settings' plugins tab.
4. Find the smoothing plugin and set status to 'Active'.

## Explanation
In a game you would usually choose to create a Node2D, Spatial, RigidBody, Kinematic body etc node for a game object, which is affected by physics and / or AI and / or player input. This I will refer to as the PHYSICS REP (representation).

The visual respresentation of this object (VISUAL REP) is often simply a child of this node, such as a MeshInstance, or Sprite. That way it inherits the transform of the parent physics rep. When you move the physics rep, the transform propagates to the child node, the visual rep, and it renders in the same place as the physics rep. In some games the visual rep can even be the same node as the physics rep (particularly when there is no actual physics).

Usually transforms propagate from a parent to child. Fixed timestep interpolation works slightly differently - the VisualRep indirectly _follows_ the transform of the PhysicsRep, rather than being directly affected by it.

In your gameplay programming, 99% of the time you would usually be mostly concerned with the position and rotation of the physics rep. Aside a few things like visual effects, the visual rep will follow the physics rep, and you don't need to worry about it. This also means that providing you drive your gameplay using `_physics_process` rather than `_process`, your gameplay will run the same no matter what machine you run it on! Fantastic.

### Note
The smoothing nodes automatically call `set_as_toplevel()` when in global mode. This ensures that they only follow the selected target, rather than having their transform controlled directly by their parent. The default target to follow will however be the parent node, if a `Target` has not been assigned in the inspector.

## Usage

### 3D
1. You would usually in a game choose to create a Spatial, RigidBody, Kinematic body etc node for your physics rep, and have a visual representation (e.g. a MeshInstance) as a child of this node.
2. Do this as normal so that you can see the object moving in the game.
3. Add the new 'Smoothing' node to the scene, as a child of your physics rep.
4. Drag the visual representation from being a child of the physics rep, to being a child of the Smoothing node.
5. That is mainly it! Just run the game and now hopefully the visual representation will follow the gameobject, but now with interpolation. You can test this is working by running at a low physics tick rate (physics_fps in project settings->physics).

### 2D
The procedure for 2D is pretty much the same as with 3D except you would be using a node derived from Node2D as the physics rep (target) and the 'Smoothing2D' node should be used instead of 'Smoothing'.

### Following targets that are not the parent node
Additionally the smoothing node has the ability to follow targets that are not parent nodes. You can do this by assigning a `Target` in the inspector panel for the Smoothing node.

### Teleporting
There is one special case when using smoothing nodes - the case when you want a target to instantaneously move from one location to another (for instance respawning a player, or at level start) where you do not want interpolation from the previous position. In this special case, you should move the target node (by setting the translation or position), and then call the 'teleport' function in the Smoothing node. This ensures that interpolation will be switched off temporarily for the move.
_Make sure to call `teleport` AFTER moving the target node, rather than before._

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

(Local mode may be more efficient but you must understand the difference between local and global transforms. Additionally you can turn off rotate and scale if not using them, for increased efficiency.)

### Notes

* Processing will also be turned off automatically for the smoothing nodes if they are hidden (either directly or through a parent).
* You can also set the target for the smoothing node from script, using the `set_target` function and passing a NodePath argument (e.g. `mynode.get_path()`).
* The best way to debug / develop smoothing is to set physics ticks per second (`ProjectSettings->Physics->Common->Physics_FPS`) to a low value (e.g. 10). Once you have it working you can set it back up to high value if desired.
* If you encounter problems smoothing a `Camera2D` node, try setting the `ProcessMode` to `Idle` instead of `Physics`.
* In order to prevent an unneeded extra delay of one tick, it is important that smoothing nodes are processed _AFTER_ target nodes. This should now be automatically taken care as the addon internally uses `process_priority` to achieve this. Previously we required smoothing nodes to be placed lower in the scene tree than the target. This should hopefully no longer be the case.

There is no need for JitterFix (`Project Settings->Physics->Common->Physics Jitter Fix`) when using fixed timestep interpolation, indeed it may interfere with getting a good result. The addon now enforces this by setting `Engine.set_physics_jitter_fix` to 0 as smoothing nodes are created.

### Authors
Lawnjelly, Calinou

__This addon is also available as a c++ module (slight differences), see:__
https://github.com/lawnjelly/godot-smooth

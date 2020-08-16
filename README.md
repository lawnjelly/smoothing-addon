# smoothing-addon v 1.0.1
Fixed timestep interpolation gdscript addon for Godot 3.2 (and later versions)

If you were wondering how to use that new function `Engine.get_physics_interpolation_fraction()` in 3.2, feel free to use this as is, or to get ideas from for your own version. 

_If you find bugs / have suggestions, please add an issue to the issue tracker and I will look into it!_ :)

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

## Explanation
In a game you would usually choose to create a Node2D, Spatial, RigidBody, Kinematic body etc node for a game object, which is affected by physics and / or AI and / or player input. This I will refer to as the PHYSICS REP (representation).

The visual respresentation of this object (VISUAL REP) is often simply a child of this node, such as a MeshInstance, or Sprite. That way it inherits the transform of the parent physics rep. When you move the physics rep, the transform propagates to the child node, the visual rep, and it renders in the same place as the physics rep. In some games the visual rep can even be the same node as the physics rep (particularly when there is no actual physics).

In order to use interpolation successfully, you have to slightly change mindset. Instead of the visual rep being directly a child of the physics rep, it needs to be a separate node in the scene tree, preferably inheriting no transform from a parent node (i.e. all the parents and grandparents will have zero translate, no rotate, and 1:1 scale).

e.g. Instead of:
```
Root
    PhysicsRep
        VisualRep (child of PhysicsRep)
```
The relationship becomes:
```
Root
    PhysicsRep
    VisualRep (child of Root)
```
To enable interpolation instead of relying on the scenetree transforms being propagated to children, we specifically tell the VisualRep to follow the PhysicsRep. This way it can follow the position and rotation of the PhysicsRep WITHOUT being directly affected by the transform of the PhysicsRep.

This may sound overly complicated, but because of the 3d maths involved, it is usually essential to getting a good result.

This means in your gameplay programming, 99% of the time you would usually be mostly concerned with the position and rotation of the physics rep. Aside a few things like visual effects, the visual rep will follow the physics rep, and you don't need to worry about it. This also means that providing you drive your gameplay using `_physics_process` rather than `_process`, your gameplay will run the same no matter what machine you run it on! Fantastic.

## Usage

### 3D
1. You would usually in a game choose to create a Spatial, RigidBody, Kinematic body etc node for your physics rep, and have a visual representation (e.g. a MeshInstance) as a child of this node.
2. Do this as normal so that you can see the object moving in the game.
3. Add the new 'Smoothing' node to the scene, but _on a different branch_, as shown in the section above.
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

### Notes

* Consider the order of processing of nodes. Nodes are processed in the scene tree in depth first order. For best results, the smoothing node should be placed in the scene tree so that it updates _AFTER_ the target node (i.e. lower in the list of scene tree nodes). If it updates before the target node, there may be an unneeded extra delay of one tick.
* Processing will also be turned off automatically for the smoothing nodes if they are hidden (either directly or through a parent).
* You can also set the target for the smoothing node from script, using the `set_target` function and passing a NodePath argument (e.g. `mynode.get_path()`).
* If you are using this addon (or indeed your own interpolation using `Engine.get_physics_interpolation_fraction()`), note that you should set `Project Settings->Physics->Common->Physics Jitter Fix` to 0.0.

There is no need for JitterFix when using fixed timestep interpolation, indeed it may interfere with getting a good result.

### Authors
Lawnjelly, Calinou

__This addon is also available as a c++ module (slight differences), see:__
https://github.com/lawnjelly/godot-smooth

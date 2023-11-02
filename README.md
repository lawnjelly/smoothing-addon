# smoothing-addon v 1.2.2
Fixed timestep interpolation gdscript addon for Godot 3.2 (and later versions)

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
The 3D smoothing node automatically calls `set_as_toplevel()` when in global mode. This ensures that it only follows the selected target, rather than having the transform controlled directly by the parent. The default target to follow will however be the parent node, if a `Target` has not been assigned in the inspector.

In 2D, *flips* are supported. That is, if you use negative scaling to flip a sprite, the interpolation will detect this and turn off for a tick to get an instantaneous flip, instead of having the sprite "turn inside out".

## Usage

### 3D
1. You would usually in a game choose to create a Spatial, RigidBody, Kinematic body etc node for your physics rep, and have a visual representation (e.g. a MeshInstance) as a child of this node.
2. Do this as normal so that you can see the object moving in the game.
3. Add the new 'Smoothing' node to the scene, as a child of your physics rep.
4. Drag the visual representation from being a child of the physics rep, to being a child of the Smoothing node.
5. That is mainly it! Just run the game and now hopefully the visual representation will follow the gameobject, but now with interpolation. You can test this is working by running at a low physics tick rate (physics_fps in project settings->physics).

### 2D
The procedure for 2D is pretty much the same as with 3D except you would be using a node derived from Node2D as the physics rep (target) and the 'Smoothing2D' node should be used instead of 'Smoothing'.

In 2D, for legacy support, the smoothing node can be set to `toplevel` if the property flag is enabled (this defaults to disabled). `toplevel` enables the transform of the smoothing node to be specified in true global space (which is more stable, and may play better with GPU snapping), and makes things simpler because the smoothing node can be a direct child of a target.

You are recommended to try `toplevel` mode, however there are two downsides which may preclude its use:
1. Parent node visibility is not automatically propagated to `toplevel` nodes, thus you have to explicitly hide the smoothing node, rather than rely on hiding just the parent node.
2. Y-sorting does not work correctly for `toplevel` nodes.

### Following targets that are not the parent node
When not using `toplevel` mode in 2D, and in other problematic situations you may see jitter. In this case you may want to use the smoothing node's ability to follow targets that are not parent nodes. You can do this by assigning a `Target` in the inspector panel for the Smoothing node.

In this situation you are highly recommended to place the smoothing node on a separate branch in the scene tree, preferably inheriting no transform from a parent node (i.e. all the parents and grandparents will have zero translate, no rotate, and 1:1 scale).

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

This may sound overly complicated, but because of the maths involved, it is usually essential to getting a good result.

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
5. global in - will read the global transform of the target instead of local
6. global out - will set the global transform of the smoothing node instead of local

(Local mode may be more efficient but you must understand the difference between local and global transforms.)

### Notes

* Processing will also be turned off automatically for the smoothing nodes if they are hidden (either directly or through a parent).
* You can also set the target for the smoothing node from script, using the `set_target` function and passing a NodePath argument (e.g. `mynode.get_path()`).
* The best way to debug / develop smoothing is to set physics ticks per second (`ProjectSettings->Physics->Common->Physics_FPS`) to a low value (e.g. 10). Once you have it working you can set it back up to high value if desired.
* If you encounter problems smoothing a `Camera2D` node, try setting the `ProcessMode` to `Idle` instead of `Physics`.
* In order to prevent an unneeded extra delay of one tick, it is important that smoothing nodes are processed _AFTER_ target nodes. This should now be automatically taken care as the addon internally uses `process_priority` to achieve this. Previously we required smoothing nodes to be placed lower in the scene tree than the target. This should hopefully no longer be the case.
* Fixed timestep interpolation may not work well in 2D pixel snapped games. For further info see https://github.com/lawnjelly/godot-snapping-demo .

There is no need for JitterFix (`Project Settings->Physics->Common->Physics Jitter Fix`) when using fixed timestep interpolation, indeed it may interfere with getting a good result. The addon now enforces this by setting `Engine.set_physics_jitter_fix` to 0 as smoothing nodes are created.

### Authors
Lawnjelly, Calinou

__This addon is also available as a c++ module (slight differences), see:__
https://github.com/lawnjelly/godot-smooth

### Addendum
Physics Interpolation is now available in core Godot as of 3.6, and you are encouraged to use core interpolation rather than addons wherever available.
It should be:
* Easier to use.
* Introduces new 2D mode to get around `toplevel` problems.
* More accurate (particularly for pivots).
* Faster.

See the official documentation for details.

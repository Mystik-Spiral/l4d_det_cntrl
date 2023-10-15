---
> ### `Detonation Control` <sub>(l4d_det_cntrl) by</sub> ***Mystik Spiral***
>
> #### Control gascan/molotov detonation based on customizable proximity
---

#### Features:  
If a gascan or molotov detonation location is within a defined proximity
of self/incapped/other survivor, prevent detonation, otherwise treat
normally.  This is very helpful if you have plugins that allow bots to
throw molotovs.  If a bot/player/griefer makes a bad molotov throw or
shoots a gascan that would burn self/incapped/other survivor in the
defind proximity, this plugin will prevent detonation.

For gascans: Shooting the gascan when it is too close will not cause a
fire, though you will see shot decals on the undetonated gascan.  
Move the gascan out of proximity and it will behave normally.

For molotovs: Once a thrown molotov hits the ground, if it is too close,
the molotov will skip across the ground like it does when hitting a wall.
The undetonated molotov can be picked back up and thrown again.  
Throw the molotov out of proximity and it will behave normally.

#### Options:  
- Separate proximity values for gascan and molotov
- Separate proximity values for vertical and vector distance
- Separate proximity values for self, incapped, and other
- Separately enable/disable gascan and molotov protection
- Separately display/surpress gascan and molotov chat messages
- Language translations: English, French, Spanish, Russian, Chinese

#### Notes:  
Vertical proximity is checked first.  If no survivor is in vertical
proximity, then detonation will happen as normal and the vector
proximity check is skipped.

- Vertical refers to the distance in height only (above/below).
- Vector refers to the distance in three-dimensional space.
- Distance is measured to the survivors eye position.

#### Requirements:  
[Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?p=2684862) (left4dhooks.smx) **`v1.138`** or higher

### Discussion:
Discuss this plugin at [AlliedModders - Detonation Control](https://forums.alliedmods.net/showthread.php?t=2811636)

#### Thanks:  
Silvers (SilverShot): Game type/mode detection/enable/disable template,
left4dhooks plugin, examples, fixes, and general community help.

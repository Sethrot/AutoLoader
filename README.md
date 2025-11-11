# AutoLoader (for GearSwap)

AutoLoader builds **plain GearSwap sets from the gear you already own** and equips them automatically.  
It lives in `GearSwap/libs` and runs when your job file loads. No separate addon needed.

---

## Quick Start

1) **Drop the lib files into GearSwap/libs**
```
Windower/addons/GearSwap/libs/
  autoloader-job.lua
  autoloader-sets.lua
  autoloader-codex.lua
  autoloader-utils.lua
  autoloader-logger.lua
```

2) **Add one require to the top of your job file**
```lua
-- minimal job file, ex: GearSwap/data/Seloan_DRK.lua
require("autoloader-job") 
```
Check [data/Seloan_DRK.lua](https://github.com/NeatMachine/AutoLoader/blob/main/data/Seloan_DRK.lua) for a minimal job file.


## What it does
**Auto-Generated Sets**

Whenever you change jobs, AutoLoader will immediately **scan your gear and generate baseline sets** (saved in data/jobs/drk/auto)
This is an "Optimize Gear" button for FFXI, and it works for various situations like idle, melee/engaged, fastcast for casting, etc.
However, the "Optimize Gear" button for FFXI is complicated, and it works about as well as you'd expect.

*If you're a FFXI master tactician, please consider contributing to [libs/autoloader-codex.](https://github.com/NeatMachine/AutoLoader/blob/dev/data/Seloan_DRK.lua)*

*SET_FUNCTIONS define the parameters used to calculate the optimal gear for each set. Most of it is AI generated for now.*

To get the most out of this tool you'll want to save at least a few basic sets yourself.

***sets* Management**
   
The primary reason AutoLoader was created was because I still need a lot of gear and I don't want to edit my luas every time I get a new piece of equipment.

Leveraging GearSwap's export command, we allow you to manage (save/update/view/delete) named sets using the *//gs c auto sets* command. 
These are some of the important ones if you choose to let the *autoloader-jobs* library manage your states for you.
```
//gs c auto sets save idle
//gs c auto sets save melee
//gs c auto sets save fastcast
//gs c auto sets save ws
//gs c auto sets save <magic school> (elemental | enhancing | enfeebling | etc)
```

You can also save a set for any ability or spell by name, and *autoloader-jobs* will use it automatically (precast for abilities, midcast for spells)
```
//gs c auto sets save savage blade -- set names will be automatically normalized, replacing spaces with '_' and removing apostrophes.
```

## Advanced
**Keep your lua and just use *sets***

The *autoloader-sets* library will give you the set mangement functionality independently of *autoloader-job*, so you can use it with Mote or whatever else.
An example of that would be:
```
local autosets = require("autoloader-sets")

get_sets()
   -- some other stuff you're doing in your lua

   sets.best.gear = autosets.get("sets.best.gear") -- or whatever else you want to name it when you save
end
```

***autoloader-job* details**

An important part of this tool is *autoloader-codex*, which is meant to (hopefully) be contributed to by people more knowledgeable than I am. Codex describes stats, spells, sets, etc. and helps to drive *autoloader-job* decisions.

AutoLoader makes heavy use of GearSwap's combine_set to load relevant sets in order of specificity.

Whenever you cast Fire IV, AutoLoader does, in order:
precast => 
equip "fastcast" because this is a magic spell*

midcast => 
equip predefined sets mapped to "fire"
equip "fire" set (if it exists)
equip predefined sets mapped to "fire iv"
equip "fire iv" set (if it exists)

For each of those steps, it also looks for the automatically generated sets if you haven't defined one. 
There are no automatically defined sets for explicit spells, abilities, or weaponskills - only for the predefined sets.
Named spells assume midcast, named anything else assumes midcast. (If you do save precast.fire or midcast.savage_blade for whatever reason, it *will* be used for the step you specified.)



## Help
```
/gs c a help
/gs c a help sets
```

---

## Minimal “works everywhere” job file
```lua
-- data/Char_JOB.lua
local job = require("autoloader-job")  -- AutoLoader: generates + equips core sets

-- Optional QoL:
-- job.lockstyle = 20
-- job.auto_echo_drops = true   -- use Echo Drops if silenced before recasting
-- job.auto_remedy = true       -- use Remedy if paralyzed before recasting
-- job.idle_refresh = true      -- idle state will look for refresh gear (or idle.refresh)
```

## Philosophy

- **Plain GearSwap tables.** Everything it generates/saves is just a normal set you can open and edit. This makes it immediately portable to existing luas.
- **Your saves win.** Anything you save under `jobs/<job>/` overrides auto sets.
- **Better than nothing.** Core five sets (idle, melee, fastcast, ws, + one magic family) carry 90% of play. Add detail later as you like.

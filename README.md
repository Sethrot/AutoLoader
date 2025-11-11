# AutoLoader (for GearSwap/libs)

AutoLoader builds **plain GearSwap sets from the gear you already own** and equips them automatically.  
It lives in `GearSwap/libs` and runs when your job file loads. No separate addon to load.

---

## Quick Start

1) **Install**
```
Drop the lib files into GearSwap/libs => 
Windower/addons/GearSwap/libs/

2) **require("autoloader-job") in your job file** (e.g. `Windower/addons/GearSwap/data/Char_JOB.lua`)
```lua
-- minimal job file
Check data/Seloan_DRK.lua
```

3) **Load your job in-game**  
AutoLoader will immediately **scan your gear and generate baseline sets** (no commands needed).

That’s enough for basic use.

---

## What it creates (automatically)

On load, AutoLoader writes fallback sets (based on your inventory) to:
```
Windower/addons/GearSwap/data/autoloader/auto/
<PlayerName>_<job>.<set>.lua
```
These are normal GearSwap tables and are used **only if you don’t have a saved set** for that name.

---

## Where your saved sets go

When you save a set, it’s written to:
```
Windower/addons/GearSwap/data/autoloader/jobs/<job>/
<PlayerName>_<job>.<set>.lua
```
Saved sets *always* take priority over the auto-generated ones.

---

## The one family of commands you’ll use

All user commands are under the **`a` / `auto`** prefix inside GearSwap’s command channel.

**List your sets**
```
/gs c a sets list
```

**Save your current gear to a set**
```
/gs c a sets save idle
/gs c a sets save melee
/gs c a sets save fastcast
/gs c a sets save ws
/gs c a sets save enfeebling
/gs c a sets save healing
/gs c a sets save enhancing
/gs c a sets save elemental
/gs c a sets save dark
```
Set names are sanitized: spaces → `_`, lowercased.  
Examples: `Vorpal Scythe` → `vorpal_scythe`, `Utsusemi: Ni` → `utsusemi:_ni` (you typically save family/base names instead of per-rank).

**Try/preview a set over current gear**
```
/gs c a sets equip idle
```

**Load a set cleanly (clears body slots first, then applies)**
```
/gs c a sets load melee
```

**Delete a set**
```
/gs c a sets delete elemental
```

**Help**
```
/gs c a help
/gs c a help sets
```

---

## Which sets should you create first?

Create these five and you’ll cover most gameplay:

1. `idle` – your out-of-combat resting/refresh baseline  
2. `melee` – your engaged/TP baseline  
3. `fastcast` – precast for all spells (Fast Cast)  
4. `ws` – generic weapon skills baseline  
5. One or two magic families you use most:
   - `enfeebling`, `healing`, `enhancing`, `elemental`, `dark`

**Notes**
- Family saves apply broadly. For example, saving `dark` will be used for Drain/Aspir and similar via the resolver.
- You can get specific later (e.g., `precast.Phalanx`, `midcast.Phalanx`, `Stoneskin`, `Utsusemi`, or variants like `enhancing.duration`).

---

## How set resolution works (simple)

When equipping, AutoLoader builds an ordered list of set names from **most specific → more general**, then merges them. It equips the result.

- **Idle/Engaged**  
  - `melee` when Engaged (plus `melee.dw` if dual-wielding)  
  - `idle` when not Engaged (plus `idle.refresh` if you need the refresh variant)

- **Precast (magic & WS)**  
  - Spells: `precast.<Spell>` → `precast.<Base>` → `fastcast` (+ common synonyms)  
  - Weapon skills: `precast.<WS>` → `ws` (+ common synonyms)

- **Midcast (magic)**  
  - `midcast.<Spell>` → `<Spell>` → `midcast.<Base>` → `<Base>` → family variants (e.g., `enfeebling`, `healing`, `elemental`, `dark`) → optional mode layers (if you add them later)

- **Weapons (optional overlay)**  
  If you use weapon IDs later, engaged sets can add `melee.weapon<ID>` layers.

Saved sets under `jobs/<job>/` beat auto sets under `auto/`. If nothing is saved for a name, the auto version is used.

---

## Minimal “works everywhere” job file

```lua
-- data/SOMEJOB.lua
local job = require("autoloader-job")  -- AutoLoader: generates + equips core sets

-- Optional QoL:
-- job.lockstyle = 20
-- job.auto_echo_drops = true   -- use Echo Drops if silenced before recasting
-- job.auto_remedy = true       -- use Remedy if paralyzed before recasting
-- job.idle_refresh = 1         -- treat low-MP idle as 'idle.refresh'
```

---

## Optional (advanced) commands

**Logger level**
```
/gs c a log off|error|info|debug
```

**Weapons (if you want per-weapon layers)**
```
/gs c a weapon save <id> <name>
/gs c a weapon select <id>
/gs c a weapon delete <id>
/gs c a weapon next|prev
```

*(You can ignore this section at first. Basic play only needs the “sets” commands above.)*

---

## Troubleshooting

- **“Nothing changed.”**  
  You likely haven’t saved that set name yet; AutoLoader is using the auto fallback. Save it:
  ```
  /gs c a sets save idle
  /gs c a sets save melee
  ```
- **“How do I see what I’ve saved?”**  
  ```
  /gs c a sets list
  ```
- **“Where did the files go?”**  
  - Auto sets (fallback): `data/autoloader/auto/`
  - Your saved sets (priority): `data/autoloader/jobs/<job>/`
- **“My WS didn’t use my specific set.”**  
  Save `ws` for a wide catch-all; add a specific, sanitized WS name if needed, e.g.:
  ```
  /gs c a sets save vorpal_scythe
  ```

---

## Philosophy

- **Plain GearSwap tables.** Everything it generates/saves is just a normal set you can open and edit.
- **Your edits win.** Anything you save under `jobs/<job>/` overrides auto sets.
- **Start simple.** Core five sets (idle, melee, fastcast, ws, + one family) carry 90% of play. Add detail later as you like.
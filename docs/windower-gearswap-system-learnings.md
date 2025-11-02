# Windower/GearSwap System Learnings (Living Cheat‑Sheet)

_A quick, practical reference we’ll keep refining as we study the Windower docs and common addon patterns. Optimized for our AutoLoader/GearSwap workflow._

---

## Core model
- **Event‑driven runtime.** Addons register callbacks: `windower.register_event('<event>', fn)`.
- **No implicit loop.** Use events (`action`, `status change`, `incoming text`, `incoming/outgoing chunk`, `zone change`, `target change`, `prerender`, etc.).
- **Standard libs you’ll see in almost every addon:**
  - `config` (load/save user settings)
  - `texts` (HUD text objects)
  - `resources` (data tables: items, jobs, zones, actions…)
  - `packets` (parse/build/inject network packets)

---

## Minimal addon anatomy
```lua
_addon.name    = 'MyAddon'
_addon.author  = 'You'
_addon.version = '0.1.0'

local config  = require('config')
local texts   = require('texts')
local res     = require('resources')
local packets = require('packets')

local defaults = { enabled = true, hud = { pos = { x = 500, y = 300 } } }
local settings = config.load(defaults)

local hud = texts.new('${state}', settings):pos(settings.hud.pos.x, settings.hud.pos.y)
hud:show()

local state = { enabled = settings.enabled }
local function render() hud:text(state.enabled and 'ON' or 'OFF') end
render()

windower.register_event('addon command', function(cmd, ...)
  cmd = (cmd or ''):lower()
  if cmd == 'toggle' then state.enabled = not state.enabled; render() end
end)
```

---

## Event catalog (high‑leverage)
- **`zone change(new_id, old_id)`** → Use `res.zones[new_id].en` to get names.
- **`status change(new, old)`** → Idle/Melee transitions, sitting, etc.
- **`target change(id)`** → Update HUD or targeting logic.
- **`incoming text(original, modified, mode)`** → Filter chat or scrape combat text (be conservative for performance).
- **`action(act)` / `action message(id, actor, target, param)`** → Combat actions/results (prefer the high‑level events to raw packet parsing when possible).
- **`incoming chunk(id, data)` / `outgoing chunk(id, data)`** → Low‑level packet hooks. Parse/modify via `packets` (see below).
- **`prerender`** → Fires every frame; throttle any work you do here.

### Throttling helper (per‑interval)
```lua
local last = 0
windower.register_event('prerender', function()
  local now = os.clock()
  if now - last < 0.25 then return end -- 4x/second
  last = now
  -- periodic work here
end)
```

---

## HUD & settings patterns (`texts` + `config`)
- Use `config.load(defaults)` to persist user‑editable settings.
- Create a HUD with `texts.new(template, settings)`; update with `:text()`, `:pos()`, `:show()`/`:hide()`.
- The `Text` addon mirrors object methods as chat commands so users can tweak positions/sizes live.

**HUD snippet**
```lua
local hud = texts.new('HP: ${hp|0}
MP: ${mp|0}', settings)
hud:update({ hp = 1200, mp = 600 })
```

---

## `resources` (res.*) usage
```lua
local res = require('resources')

-- Zone names
windower.register_event('zone change', function(new_id, old_id)
  local new_zone = res.zones[new_id] and res.zones[new_id].en or ('#'..tostring(new_id))
  local old_zone = res.zones[old_id] and res.zones[old_id].en or ('#'..tostring(old_id))
  windower.add_to_chat(207, ('Zone: %s → %s'):format(old_zone, new_zone))
end)

-- Job lookup
-- res.jobs[job_id].ens / .en / .ja etc.
```

---

## Packets library (parse/build/inject)
- **Parse existing:** `local p = packets.parse('incoming'|'outgoing', data)`
- **Modify safely:** change fields on `p` → `return packets.build(p)` from the event to send your modified version.
- **Create new:** `local p = packets.new('outgoing', 0xXYZ, { field = value, ... })` then `packets.inject(p)`.
- **Caution:** Only do packet work when necessary; prefer high‑level events/APIs.

**Outgoing example (skeleton)**
```lua
windower.register_event('outgoing chunk', function(id, data, modified, injected, blocked)
  if id == 0x05B then -- example ID
    local p = packets.parse('outgoing', data)
    -- p.<field> = ...
    return packets.build(p) -- returning applies the change
  end
end)
```

---

## GearSwap: lifecycle & helpers
- **Order of phases:** `get_sets()` → `pretarget(spell)` → `precast(spell)` → `midcast(spell)` → `aftercast(spell)`.
- **Other hooks:** `status_change(new, old)`, `buff_change(name, gain, details)`, pet variants, and job‑specific helpers.
- **Core helpers:**
  - `set_combine(a, b, c, ...)` merges left→right (rightmost wins on conflicts).
  - `equip(set_or_table)` applies; last call wins.
  - `disable('slot', ...)` / `enable(...)` to lock/unlock slots.

**Skeleton user file**
```lua
function get_sets()
  sets = {}
  sets.precast = { head = "Carmine Mask +1" }
  sets.midcast = { body = "Vrikodara Jupon" }
  sets.aftercast = { idle = { ring1 = "Stikini Ring +1" } }
end

function precast(spell)
  if spell.action_type == 'Magic' then equip(sets.precast) end
end

function midcast(spell)
  if spell.skill == 'Elemental Magic' then
    equip(set_combine(sets.midcast, { hands = "Amalric Gages +1" }))
  end
end

function aftercast(spell)
  if player.status == 'Engaged' then
    -- equip melee set if you define one
  else
    equip(sets.aftercast.idle)
  end
end
```

### CLI we actually use
- `gs export [inventory|all|sets|xml] [file <name>] [overwrite]` – scaffold/export sets.
- `gs enable|disable <slot>` – lock specific pieces.
- `//lua load|unload|reload <addon>` – control addons from chat.
- `//bind <key> <command>` / `//unbind <key>` – create keybinds (e.g., `//bind ^1 gs c nuke cycle`).

---

## Organizer × GearSwap
- Include `organizer-lib` in your user file to auto‑pull required set items and stash extras. Define `organizer_items` for always‑carry lists. Trigger with `//gs org` in Mog House.

---

## Command & scripting patterns
- **In chat:** prefix game console calls with `//` (double slash).
- **Macros:** use `/console` to forward to Windower, e.g., `/console gs c <args>`.
- **Startup scripts:** `windower/scripts/init.txt` (e.g., autoload addons with `lua l <addon>`).

---

## Idioms & conventions
- Keep a single `settings` table (from `config`) and a small `state` table (runtime toggles).
- Always gate noisy work behind timers/throttles.
- For big HUDs, use a single `texts` object with template variables; update via `:update({...})`.
- Treat `res.*` as the source of truth for IDs→names. Avoid hard‑coding where possible.
- Prefer high‑level events (`action`, `status change`) over raw packet handlers unless you need exact wire data.

---

## Snippets (grab‑and‑go)

**Zone name lookup**
```lua
local res = require('resources')
windower.register_event('zone change', function(new_id, old_id)
  local zn = res.zones[new_id] and res.zones[new_id].en or tostring(new_id)
  windower.add_to_chat(207, 'Now in '..zn)
end)
```

**Per‑slot lock/unlock from chat**
```lua
windower.register_event('addon command', function(cmd, slot)
  cmd  = (cmd or ''):lower()
  slot = (slot or ''):lower()
  if cmd == 'lock'   and slot ~= '' then send_command(('gs disable %s'):format(slot)) end
  if cmd == 'unlock' and slot ~= '' then send_command(('gs enable %s'):format(slot))  end
end)
```

**`prerender` ticker (1/sec)**
```lua
local last = 0
windower.register_event('prerender', function()
  local now = os.clock()
  if now - last >= 1.0 then last = now; windower.send_command('gs c tick') end
end)
```

**Packet build + inject**
```lua
local p = packets.new('outgoing', 0xXYZ, { field_a = 123, field_b = 456 })
packets.inject(p)
```

---

## For AutoLoader/GearSwap specifically
- **Resolver rules mirror GearSwap semantics:** when merging sets, the rightmost set or the latest `equip` call wins. Design set search order accordingly (most specific → most general).
- **Exports:** wrap `gs export` flows (with `file` and `overwrite`) to create predictable snapshots.
- **HUD:** build on `texts` and surface live tuning with chat commands (`text <name> pos X Y`, etc.).
- **Resources:** favor `res.items`, `res.jobs`, `res.zones` for lookups; do not hard‑code.
- **Performance:** any periodic work must be throttled; avoid heavy work in `incoming text` and `prerender`.

---

## Parking lot / next passes
- Catalog common event payload shapes (e.g., `action` table fields) with brief examples.
- Map frequently used packet IDs we may care about and their field names.
- Add a GearSwap set taxonomy we’ll standardize on for AutoLoader (idle/melee/ws/fastcast/… plus category fallbacks).
- Add a short style guide (naming, file layout, logging conventions) to keep new files consistent.



---

## Update — 2025‑11‑01 18:45 PT (Run 1)

### GearSwap — command details & file resolution
- **`gs c <string>` → `self_command(<string>)`**. Use this as the bridge from chat/macros to your user Lua.
- **`gs load <path>` search order (first match wins):**
  1. `..GearSwap/libs-dev/<path>`
  2. `..GearSwap/libs/<path>`
  3. `GearSwap/data/<character>/<path>`
  4. `GearSwap/data/common/<path>`
  5. `GearSwap/data/<path>`
  6. `%APPDATA%/Windower/GearSwap/<character>/<path>`
  7. `%APPDATA%/Windower/GearSwap/common/<path>`
  8. `%APPDATA%/Windower/GearSwap/<path>`
  9. `..Windower/addons/libs/<path>`
  _Implication:_ Put project libs in `libs/` and shared job helpers in `data/common/` for predictable loads.
- **`gs export` quick flags:** `inventory` | `all` | `sets` | `xml` | `mainjob` | `mainsubjob` | `file <name>` | optional `overwrite`. Default: currently equipped to Lua. Good for snapshotting.
- **`gs enable/disable <slot|all>`:** Toggles whether GS may equip into a slot. No argument: enable/disable user file execution (events still run when disabled).
- **`gs validate <sets|inv> [filter...]`**: Diff sets ↔ inventory. Use after Organizer runs.
- **`gs showswaps` / `gs debugmode` / `gs eval <lua>`:** Useful during authoring; `eval` gated by debug mode.

### GearSwap — variable shapes (selected quick reference)
- **`spell`**: `.name`, `.type` (e.g. `WhiteMagic`, `JobAbility`), `.skill`, `.mp_cost`, `.tp_cost`, `.element`, `.range`, `.recast`, `.cast_time`, `.wsA/B/C`, `.interrupted` (only in `aftercast`).
- **`spell.target`**: `.name`, `.raw` (`<t>`, `<me>`, etc.), `.type` (`SELF|PLAYER|NPC|MONSTER`), `.hpp`, `.distance`, `.isallymember`, `.is_npc`, `.tp`, `.mpp`, `.status(_id)`, position `.x/.y/.z`, `.id/.index`.
- **`player`**: `.name`, `.status`, HP/MP/TP (`.hp/.mp/.tp` and `%` variants), job info (`.main_job(_id/_full/_level)`, `.sub_job(_id/_full/_level)`), targeting `.target_index`, position `.x/.y/.z`, speed `.speed(_base)`, bags (`.inventory`, `.sack`, `.satchel`, `.case`, `.wardrobe`, `.wardrobe2`).
_Use these fields in event hooks to branch sets without expensive resource lookups._

### Windower commands — usage patterns
- **Where you can run commands:**
  - **Console:** type the command verbatim.
  - **In‑game chat:** prefix with `//` (e.g., `//showfps 1`).
  - **Macros:** prefix with `/console ` (e.g., `/console gs c toggle idle`).
  - **Scripts:** write commands line‑by‑line into `scripts/*.txt`.
- **Bind syntax:** `bind [modifier][state]<key> [up] <command>`.
  - Example: `//bind ^1 gs c nuke cycle` (Ctrl+1).

### Text HUD — addon ↔ library mapping
- `text <name> <command> [args]` mirrors methods of the `texts` library.
- Lifecycle: `text <n> create [initial text]` → mutate (`pos|color|size|italic|bg_color|bg_transparency|...`) → `text <n> delete`.
- **Idioms:** Keep one `texts` object with template variables and update with `:update{...}`; expose a few chat wrappers for power users.

### Organizer — job snapshotting & GS integration
- **Core commands:**
  - `org freeze [bag] [file]` → snapshot current bag(s) to `Name_JOB.lua` by default.
  - `org get|tidy [bag] [file]` → move toward snapshot / purge not‑needed items to dump bags.
  - `org organize [bag] [file]` → loop `get`+`tidy` until steady state.
- **GearSwap tie‑in:** add `include('organizer-lib')` to your GS file; in Mog House run `//gs org` after job change.
- **Carry‑list:**
```lua
organizer_items = {
  echos = 'Echo Drops',
  shihei = 'Shihei',
  orb   = 'Macrocosmic Orb',
}
```

### Cross‑links for AutoLoader/GearSwap
- Use `gs c` → `self_command` as the control surface for toggles/modes; bind with `//bind`.
- Library load order means we can ship shared helpers in `libs/` and reference them reliably from user files.
- After an `org` run, `gs validate sets` highlights missing items; pipe this to your HUD/log for quick triage.


---

## Update — 2025‑11‑01 19:05 PT (Run 2)

### Modes.lua — quick API & idioms
- Construct with options: `M{ ["description"] = "Idle", "default", "dt", "mdt" }` → `.current` holds the active value.
- Core methods: `:set(value)`, `:cycle()`, `:contains(value)`, `:options(...)` (reset/extend choices).
- Pattern: keep user‑facing names separate if needed (map to pretty strings in `mode_display_names`).
```lua
local Modes = include('Modes')
local Idle = Modes{ ["description"]="Idle", "default","dt","mdt" }
Idle:cycle()  -- default → dt → mdt → default
```

### `include` vs `require` & file layout
- **`include('file')` (GearSwap helper):** searches GS data/libs paths; good for job files and shared GS libs.
- **`require('module')` (Lua):** uses `package.path`; typical for addon‑local libs (e.g., our logger). 
- **Recommendation (this project):**
  - Ship GS‑oriented helpers in `GearSwap/libs/` (or `data/common/`) and load via `include` from job files.
  - Ship addon‑local utilities in `addons/autoloader/libs/` and load via `require` from the addon.
- **Unload hygiene:** unbind keys and stop timers in `user_unload()` to avoid bleed‑through between reloads.

### High‑value GearSwap flows (with intent)
- **`get_sets()`**: bootstrap tables (no equips yet), load exports, register lockstyles.
- **`user_setup()`**: bind keys, initialize modes/HUD state.
- **`precast(spell)`**: fast cast/interrupt mitigation; branch by `spell.action_type` (`Magic`, `WeaponSkill`, `JobAbility`).
- **`midcast(spell)`**: skill‑specific sets (e.g., `enfeebling`, `elemental`, `dark`).
- **`aftercast(spell)`**: snap back to `idle`/`melee` per `player.status`.
- **`status_change(new, old)`**: authoritative idle/melee swap gate; prefer calling a single `status_refresh()` to consolidate.

### Command router pattern (robust `self_command`)
- Parse the first token → dispatch function; pass the tail as free‑form args. Surface friendly errors via `say()`/`echo()`.
- Provide subcommands for save/delete/show/validate, and keep **dry‑run** semantics for destructive ops by default.

### Resources (`res.*`) — fast lookups
- Use `res.<table>:with(<field>, <value>)` to fetch rows (e.g., `res.job_abilities:with('en','Chainspell')`).
- Common tables: `jobs`, `spells`, `weapon_skills`, `job_abilities`, `zones`, `items`. Prefer IDs from event payloads when available; otherwise resolve by `.en`.

### Recast/readiness helpers
- Job abilities: `windower.ffxi.get_ability_recasts()[recast_id] == 0` ⇒ ready.
- Spells: `windower.ffxi.get_spell_recasts()[spell_id] == 0` ⇒ ready. Cache `spell_id` on first use (via `res.spells`).

### Text HUD — templating tricks
- Use a single `texts` object with `${var|default}` placeholders; call `:update{var=val}` instead of rebuilding strings.
- Keep HUD mutation calls sparse (throttle updates in `prerender`).

### Organizer + validation workflow
1) `include('organizer-lib')` in job file.
2) In Mog House: `//gs org` to sync the carry list.
3) `//gs validate sets` to diff exports vs inventory; surface the diff in chat/HUD for quick fixes.

### Packet/event hygiene
- Prefer high‑level `action`, `action message`, `incoming/outgoing text` over raw chunk handlers.
- Only `return packets.build(p)` from chunk events when you truly intend to modify; otherwise return nothing.
- Never do heavy work per frame; throttle `prerender` and debounce spammy events with `os.clock()`.

### Patterns lifted from our AutoLoader (legacy) for consistency
- **Export naming**: `{Name}_{job}.{set}.lua` 
  - Normalize user input: lower, spaces→`_`, strip apostrophes.
- **Weapon slots & lock semantics**: keep a clear separation between full‑set resolution and weapon‑only equips. Respect a `weapon_lock` mode that strips weapon slots from resolved sets, and a **weapon mode** that can still equip just weapon slots when active.
- **Cache resolved sets** and flush on reload to avoid recompute churn.
- **Help system**: in‑chat indexed topics with dynamic state lines (e.g., current mode values) reduce guesswork.

### Style guide (initial)
- **Naming**: lower_snake_case for set keys; use dots for hierarchy (`melee.acc`, `enhancing.duration`).
- **Logging**: prefix all add‑to‑chat lines with `[AutoLoader]`; louder errors via a distinct color; quiet info by default; allow `debug` mode.
- **Colors**: reserve one color for info, one for debug, one for errors, one for say/announcements.
- **APIs**: expose small, intent‑named functions (e.g., `status_refresh()`, `apply_lockstyle()`, `ja_ready(name)`).

### Next targets (Run 3)
- Document typical `action` payload fields (category, param, recast, targets) for quick filters.
- List frequent packet IDs we might care about and recommended non‑packet alternatives.
- Add a canonical **set taxonomy** for Codex (idle/melee/ws/fastcast + `enhancing.*`, `enfeebling.*`, `elemental.*`, `dark.*`, etc.), aligned with Spellbook mapping.


---

## Update — 2025‑11‑01 19:22 PT (Run 3 — GearSwap deep dive)

### GearSwap core semantics (refresher)
- **Set merge rule:** `set_combine(a, b, ...)` returns a new set; **right‑most wins** on slot conflicts.
- **Equip rule:** `equip(a, b, ...)` collapses sets **right→left**, and **later calls override earlier ones**.
- **Practical effect:** Your resolution chain should pass from most‑general → most‑specific, with the last layer carrying highest priority.

### Event flow & intent mapping
- **Primary spell phases:** `precast(spell)` → `midcast(spell)` → `aftercast(spell)`.
  - Typical usage: precast = fast cast & interruption down; midcast = skill/element/buffs; aftercast = revert to idle/melee per `player.status`.
- **Support hooks:**
  - `status_change(new, old)` — authoritative gate for idle↔melee.
  - `buff_change(name, gain, details)` — respond to gains/losses (e.g., Stoneskin, Doom, Aftermath).
  - `self_command(args)` — command router for `gs c ...` controls.
- **Tip:** centralize post‑action logic in a `status_refresh()` function; call it from `aftercast` and `status_change` to keep behavior consistent.

### Command interface (author & debug workflow)
- **Export snapshots:** `gs export <inventory|all|sets|xml|mainjob|mainsubjob> [file <name>] [overwrite]`.
- **Slot gating:** `gs enable <slot|all>` / `gs disable <slot|all>`.
- **Inventory sanity:** `gs validate <sets|inv> [filter...]`.
- **Debugging helpers:** `gs showswaps`, `gs debugmode`, `gs eval <lua>`.

### Organizer integration (carry‑list + sync)
1) Add to job file: `include('organizer-lib')`.
2) In Mog House after job change: `//gs org` to sync items with defined sets.
3) Then `//gs validate` to catch mismatches; fix via Organizer or adjust sets.

### Text HUD patterns (for GS UIs)
- Use `texts` library + a single template object with `${var|default}` placeholders.
- Update HUD via `:update{...}` inside throttled blocks (e.g., only when values change or on a 250ms ticker).
- Mirror commonly used methods as chat commands for power users (position, size, colors).

### File layout & includes
- **GS shared helpers**: keep in `GearSwap/libs/` (or `data/common/`), load with `include('...')` from job files.
- **Addon‑local libs**: keep under your addon's folder and `require('...')` them from addon code.
- **Unload hygiene:** unbind keys and stop timers in `user_unload()` to avoid cross‑reload artifacts.

### Practical idioms we’ll standardize on
- **Mode toggles**: back them with a small state table (or Modes.lua) and a single `self_command` router.
- **Set taxonomy** (initial):
  - Top‑level: `idle.*`, `melee.*`, `weaponskill.*`, `fastcast`, `resting`.
  - Magic families: `enhancing.*` (e.g., `enhancing.duration`, `enhancing.skill_mnd`), `enfeebling.*` (`macc`, `skill_mnd_pot`), `elemental.*` (`nuke`, `mb`), `dark.*` (`drain`, `aspir`), `healing.*` (`cure_pot`, `cure_macc`).
  - Utility: `treasure`, `movement`, `dt`, `mdt`, `pdt`.
- **Resolver order**: search most‑specific → general fallbacks, then merge in priority order using the equip/combine rules above.
- **Throttle everything** in `prerender`/spammy hooks; cache lookups and avoid recomputing resolved sets per frame.

### Notes & cautions
- **Recast vs cast time:** treat precast gear as affecting casting time and midcast as affecting recast; the spell’s recast is calculated as it goes off. (Rule‑of‑thumb for timing sensitive swaps.)
- Prefer high‑level action/chat events before diving into packet handlers unless we need exact wire data.

### To do (next pass)
- Add a concise table of `spell` / `player` / `target` fields we rely on most, with mini‑examples.
- Document common “MB recognition” strategies and safe toggling back to previous mode after burst window.
- Draft a robust `self_command` router with subcommands for modes, weapon locks, and export flows (drop‑in snippet).


---

## Run format note
Each appended run will **begin with a timestamp label line in local time**, e.g.
`2025-11-01 19:40 PT — Run N`
Then the notes follow. No periodic cleanups or summaries unless you ask for them.



---

2025-11-01 19:19 PT — Run 4

### GearSwap hook semantics (from docs)
- **get_sets()**: called once on load; declare variables and **sets** only.
- **pretarget(spell)**: triggers when the command text hits the outgoing buffer; supports `cancel_spell()` and `change_target()`.
- **precast(spell, position)**: fires just before the outgoing action packet; provides `cancel_spell()`, `verify_equip()`, `force_send()`, `cast_delay()`.
- **midcast(spell)**: immediately after packet injection; use for skill/element specific sets.
- **aftercast(spell)**: on result packet or interruption detection.
- **status_change(new, old)**: authoritative status gate.
- **pet_change(gain)**, **pet_midcast/aftercast/status_change**: pet life‑cycle.
- **filtered_action(spell)**: when a player attempts an action they cannot perform (good place to `cancel_spell()`).

### Practical idioms to apply
- Keep **pretarget** for validations & retargeting, **precast** for fastcast/interrupt mitigation & JA readiness checks, **midcast** for potency/accuracy layers, **aftercast** to hand off to a unified `status_refresh()`.
- When using **pet_*** hooks, don’t assume ordering vs master’s `aftercast` (per doc note on Release/Leave). Queue a short delay if you need deterministic sequencing.

### Windower command model (quick ref)
- Where commands run: **console**, `//` in chat, `/console` in macros, or text **scripts**.
- **Key categories**: Console (`console_*`), Input (`bind`, `unbind`, copy/paste), Addon (`lua load|reload|u|list|exec|command`), plus general helpers.
- **Bind syntax**: `bind [modifier][state]<key> [up] <command>`; prefer `/console` invocations in macros.

### Addons to emulate patterns from
- **Organizer**: `include('organizer-lib')` → `//gs org` in Mog House to fill inventory; follow with `//gs validate` for diffs.
- **Shortcuts**: demonstrates “DWIM” parsing (auto‑prefixing, target resolution). Good model for friendly `gs c` UX.
- **Cancel**: accepts buff names or IDs; wildcard patterns supported for batch removals.
- **Text**: command façade for the `texts` library—mirror only a few knobs in chat and keep the rest code‑driven.

### GearSwap command tips
- **export**: `gs export <inventory|all|sets|xml|mainjob|mainsubjob|file <name>> [overwrite]` (defaults to equipped → Lua). Advanced tables include augments.

### Cross‑links to AutoLoader/GearSwap work
- Map our phases to doc semantics exactly: our legacy `precast` fastcast + `midcast` potency split aligns with reference; keep **right‑most‑wins** ordering when layering sets.
- For **weapon mode** vs **weapon_lock**: preserve our current precedence (mode trumps lock on switch; lock strips weapon slots for non‑weapon equips) and surface explicit echo lines for clarity.
- Implement **filtered_action** guardrails to give friendly errors when a user lacks MP/TP/recasts and suggest a fallback command (`gs c help` topic pointer).

### Targets for next pass
- Build a compact field map for `spell`, `player`, and `spell.target` (common fields + examples).
- Document console/input/addon **command lists** we actually rely on (binds, lua load/reload/command/exec, console_echo/clear/position, input copy/paste).
- Note packet/event alternatives (prefer high‑level events; only drop to `packets` when unavoidable).


---

2025-11-01 19:29 PT — Run 5

### Repo & site structure (Windower/docs)
- Docs are generated via Jekyll (Minimal Mistakes), published at `docs.windower.net`. Authoring lives under `_pages/` with `addons/` and `plugins/`; sidebar/nav comes from `_data/navigation.yml`. Each page uses YAML front matter with `permalink` + `title`.

### Windower command ecosystem (fast ref)
- **Categories**: General, Alias, Console, Game, Input, Plugin, Addon.
- **Input**:
  - Bind syntax: `bind [modifier][state]<key> [up] <command>`
    - Modifiers: `^` Ctrl, `!` Alt, `@` Win, `#` Apps, `~` Shift.
    - States: `$` (valid while chat is **open**), `%` (valid while chat is **closed**).
  - Helpers: `unbind`, `listbinds`, `clearbinds`, `type`, `paste`, `setkey`, `keyboard_blockinput`, `mouse_blockinput`.
- **Alias**: `alias <alias> <command>`, `unalias`, `clearaliases`, `listaliases`.
- **Console** (handy while building HUDs & macros): `console_toggle`, `console_clear`, `console_echo`, `console_position`, `console_font`, `console_color`, `console_log`, `exec`.
- **Addon**: `lua load|unload|reload|command|invoke|memory|list|unloadall|exec` (abbr: `lua l|u|r`).
- **Plugin**: `load|unload|reload|toggle|plugin_list|unloadall`.
- **General**: `showfps`, `fps_position`, `screenshot`, `video start|stop`, `wait|pause`.

### Addon API: event-driven model & idioms
- **Event registration**: `windower.register_event('<event>', function(...) ... end)`.
- **Common events seen in docs/examples**: `load`, `login`, `addon command` (parse user args from `//<addon> ...`), `incoming text` (org, mod, org_mode, new_mode, blocked), `outgoing chunk` (id, original, modified, injected, blocked), `prerender` (per-frame), `mouse`.
- **Idioms**:
  - One-time init in `load`; character/job specific init in `login`.
  - Centralize chat/UI output via a `texts` instance; persist settings with `config.load(defaults)`.
  - Guard heavy logic on every-frame hooks; prefer throttles/debouncers.
  - Don’t rely on packet hooks in `unload` (see crash reports); tear down earlier (`logout`/`job change`) or use safe flags.

### Libraries & building blocks
- **texts**: HUDs/overlays. Pattern:
  ```lua
  local texts = require('texts')
  local config = require('config')
  local settings = config.load({ bg = { alpha = 80 }, padding = 3 })
  local hud = texts.new(settings)
  hud:text('Hello'); hud:visible(true)
  ```
  - Instance methods (`t:pos_x()`, `t:text()`, `t:bg_color(r,g,b)`, etc.) are preferred over static calls.
- **send**: IPC across instances: `send @all <command>`, `send <player> <command>`, `send @job <command>`.
- **resources (`res`)**: Data tables bundled with Windower Resources package (Lua). Prefer these over parsing live packets for names/ids.

### Plugins vs Addons
- **Addons**: Lua, event-driven via `register_event`. Favor for new work.
- **Plugins**: Compiled (C++); managed by Plugin commands; legacy/utility features (AutoExec, Config, Timers, IME, etc.).
- **PluginManager** addon: profile-driven loader/unloader; assumes config file is the complete truth; will unload anything not in the profile on login/logoff.

### Notable addon pages to mirror patterns from
- **GearSwap**: rich command surface (`c`, `equip`, `showswaps`, `export`, `enable/disable`, `validate`). Our GS UX should echo these verbs where sensible.
- **Text** addon: commands mirror `texts` library; good model for exposing HUD knobs to users.
- **Send** addon: canonical IPC patterns for multibox control.
- **PointWatch/AnsweringMachine/BattleMod**: consistent short aliases (`pw`, `am`, `bm`) and subcommand style—adopt similar concise aliasing.

### Best practices & cautions
- **Packet caveat**: Avoid using the `packets` API inside `unload` handlers; known hang/crash issues on shutdown. Prefer earlier teardown or soft-disable flags.
- **Injection risk**: Addons that automate NPC interactions (e.g., cape augmentation) warn of item loss/risk; document risks and add safeguards (range checks, retry limits, confirmations).
- **Scripting hygiene**: Chain with `;`, use `wait` sparingly; prefer binds calling aliases to keep `bind` lines short; choose `%` state binds for gameplay, `$` for chat helpers.
- **Dev tips**: Enable `console_log` while iterating; set screenshot dir; keep key HUD positions configurable.

### Resources/data updates
- **Resources repo** now hosts the Windower 5 resource package (Lua-only). XML outputs require running the Resource Extractor locally. Plan our lookups (`res.items`, `res.spells`, etc.) accordingly.

### Cross-links to AutoLoader/GearSwap work
- **AutoLoader**: Use `PluginManager` or `lua exec init.txt` as fallback; provide a character/job → profile map and echo what changed.
- **Multibox flows**: Broadcast `//gs c <verb>` via `send @all` or target subsets (`@others`, `@job`). Add guardrails & echoes (e.g., show who accepted a command).
- **HUD**: Standardize a lightweight `texts` HUD helper we can reuse across GS and other addons (pos/save/theme).


---

2025-11-01 19:57 PT — Run 6

### Additive details from Windower docs
- **Input binds — multi-key & release:** You can bind the *same command* to multiple keys in one statement by separating keys with a pipe (`|`), and use `up` to trigger on key release. Example: `bind ^1|^2 gs c nuke cycle` and `bind ^TAB up gs c mode idle next`.
- **`pretarget` edge-case:** It doesn’t fire for actions that bypass the outgoing text buffer (e.g., using items from menus). Keep validations that must always run in `precast` as a backup.
- **Texts command façade:** The `Text` addon exposes every mutating function of the underlying `texts` library as a command, so we can keep HUDs code-driven while still offering power users live tweaks via `/text`.
- **Resources package shape:** Windower’s resources are produced by a Resource Extractor; data includes auto‑parsed DATs plus manual fixes. Treat `res.*` as canonical for names/IDs and avoid hard‑coding.
- **Key name lookups:** When writing binds in scripts/macros, use the Key Mapping list to get the exact textual names that Windower expects (useful for unusual keys).
- **Recast timing nuance:** Precast gear impacts *cast time*; midcast gear impacts *recast*. The engine computes recast as the spell goes off—time swaps accordingly.

### Cross‑links for AutoLoader/GearSwap
- Prefer binds with `|` to simplify common aliases (e.g., map `gs c mode idle next` to several keys during testing). Keep `/console` in macros and `//` for ad‑hoc.
- For validations that *must* occur even when `pretarget` is skipped (menu items), mirror them in `precast` and early‑out if already handled.
- Expand our HUD help topic: list a few `/text` commands we officially support (pos/size/bg/alpha) and point advanced users to the full `texts` API.
- Confirm our resolver timing for recast‑sensitive swaps (e.g., elemental spells): ensure precast/midcast layering matches the cast→recast split.


---

2025-11-01 20:15 PT — Run 7

### Fresh notes from Windower docs (additive)
- **Bind nuances**: `bind [modifier][state]<key> [up] <command>` supports multi-key with `|` and release-trigger via `up`. States: `$` while chat input is open, `%` while closed. Handy for mapping GS controls without interfering with typing. 
- **Console helpers** worth enabling during development:
  - `console_log 1` (writes to `windower/console.log`), `console_position <x> <y>`, `console_color [A] <R> <G> <B>`, `exec "<file>"` to run scripts. 
- **Key mapping list**: use the exact text names (e.g., `lshift`, `tab`, `grave`) when writing binds; cross-check against the Key Mapping page to avoid mis-typed keys. 
- **Addons vs Plugins**: Prefer addons (Lua, event-driven) for new work; plugins are compiled DLLs maintained by Windower for legacy/engine features. 
- **GearSwap quick refs**: `gs c` → `self_command`, `gs debugmode`, `gs eval <lua>`, `gs enable/disable <slot>`, `gs validate <sets|inv> [filter]`, `gs export [options] [file <name>] [overwrite]`. Keep these in our job-file help. 

### Why this helps AutoLoader
- Bind/state tips let us ship **sane default keybinds** that don’t conflict with chat.
- Console logging & script exec simplify **on-target debugging** when users report issues.
- Explicit key names reduce **support churn** around custom binds in our README.
- Reaffirming addon-first keeps our design within **Lua/event idioms** we already use.


2025-11-01 21:05 PT — Run 8

### Additive notes from Windower docs (focused for AutoLoader/GearSwap)
- **Load vs. Login**: Use `load` for addon one-time init; use `login` for per-character binds/macros and state init. Persist per-char settings with `config.load(defaults)` keyed off player name.
- **Text addon vs `texts` lib**: Keep HUDs code-driven via `texts` and expose only a handful of `/text` knobs (pos, size, bg, alpha). This keeps the UI stable but still tweakable.
- **send addon patterns**: `send @others //gs c <cmd>`, `send @job RDM //gs c <cmd>`; always include `//` for chat-context commands to the target client.
- **`files` lib for caches**: Write sparingly (batch via timer) to avoid disk churn; keep under `data/` and guard with existence checks.
- **Organizer loop**: In Mog House: `org freeze` → `org organize` → `gs validate sets` to catch missing items before runs.
- **Debounce example (buff_change)**
```lua
local last_doom = 0
windower.register_event('buff_change', function(name, gain, details)
  if name == 'Doom' and gain then
    local now = os.clock()
    if now - last_doom > 0.2 then
      last_doom = now
      windower.send_command('input /item "Holy Water" <me>')
    end
  end
end)
```
- **Self-command router (skeleton)**
```lua
function self_command(cmd)
  local words = {}
  for w in tostring(cmd):gmatch('%S+') do words[#words+1] = w end
  local verb = (words[1] or ''):lower()

  if verb == 'mode' then
    local key   = (words[2] or ''):lower()
    local which = (words[3] or ''):lower()
    if key == 'idle' and which == 'next' and Idle and Idle.cycle then
      Idle:cycle()
    end
    if status_refresh then status_refresh() end
    return
  end

  if verb == 'export' then
    windower.send_command('gs export file AutoLoader overwrite')
    return
  end

  windower.add_to_chat(207, '[AutoLoader] Unknown command: '..tostring(cmd))
end
```
- **Bind states recap**: `$` applies while chat is open; `%` applies while chat is closed. Use `%` for gameplay binds to avoid conflicting with typing; `$` for chat helpers.
- **Macro hygiene**: Prefer `/console gs c ...` within in-game macros; use `//` for manual console entry.

#### Why this helps
- Clean separation of one-time vs per-character init clarifies where AutoLoader hooks in.
- A minimal command surface keeps HUD/user UX predictable.
- `send` patterns and validation loop are ready-made for multibox and pre-run checks.

# Architecture Reports — AutoLoader (Scanner -> Codex -> SetGen -> Autoloader)

Initialized by ChatGPT on 2025-11-01.

---

## 2025-11-01 20:35 PT – Initialization

Scope: Brand-new architecture using legacy files only as behavioral references. Unqualified spell set names are midcast by default; default spell precast is precast.fastcast; unqualified WS or JA names apply to precast.

Architecture:

1) Scanner: parse inventory into normalized items with stats and derived tags.
2) Codex: declarative knowledge base for spells, weapon skills, and families. Each entry defines phase, families, ordered stat_tags, and optional calc expression.
3) SetGen: chooses best piece per slot using tags or calc; emits generated sets with deterministic keys.
4) Autoloader: resolves runtime set using precedence and merges user overrides and fallbacks.

 Canonical stat tags (initial cut; synonyms in parentheses):
fast_cast (fast cast, FC); spell_interrupt_down (interrupt down, SIRD); magic_accuracy (macc); magic_attack (matt); magic_damage_flat; elemental_skill; enfeebling_skill; dark_magic_skill; enhancing_skill; healing_skill; cure_potency; cure_potency_received; enhancing_duration; refresh; regen_potency; regen_duration; enmity_plus; enmity_minus; store_tp; tp_bonus; weapon_skill_damage; ws_str_wsc; ws_dex_wsc; ws_vit_wsc; ws_int_wsc; ws_mnd_wsc; ws_agi_wsc; double_attack; triple_attack; quadruple_attack; multi_attack_rate; pdt; mdt; dt; meva; mdef; haste_magic; snapshot; racc; ratk; subtle_blow.

[ Data contracts (concise) ]:
- Scanner -> SetGen: inventory_snapshot = { items = [ { id, name, slot, stats{{...}}, tags[...] }, timestamp }.
- Codex entry: { phase, families, stat_tags, calc? }.
- SetGen output: gen_sets[\"midcast.dark.drain\"] = { head=..., body=..., ... }.
- Autoloader resolver request: { phase, action_type, name, family_keys }.

Precedence and fallbacks:
- Spells: midcast by default for unqualified names; precast uses precast.fastcast unless a specific precast.<name> exists. Resolution order: midcast.<exact_name> -> midcast.<base_name> -> midcast.<family> -> midcast.<skill> -> midcast.<role> -> generated midcast.<family> -> midcast.
- WS or JA: unqualified names apply to precast. Order: precast.<exact_name> -> precast.weaponskill.<family> -> generated precast.weaponskill.<family> -> precast.weaponskill -> precast.

Next steps: 
1) Scanner v1: map common stats to tags; skip augments initially.
2) Codex v1: seed spells and WS with stat_tags; include default fastcast rule.
3) SetGen v1: greedy per-slot selection by tag priority; expose gs c autogen.
4) Autoloader resolver: implement precedence chain and debug logging.
5) Add tests for Drain II, Aspir, and Savage Blade.",
# =========================
# 0) Pre-filters (strings)
# =========================
PRE_FILTER_LINES = [
  r'^\s*Augments?:.*$',
  r'^\s*Path\s*[A-D]\s*:.*$',
  r'^\s*Rank\s*(?:R)?\d+.*$',
  r'^\s*R:\s*\d+.*$',
  r'^\s*\[\d+\]\s*.*$',                               # table row markers
  r'^\s*Latent(?:\s*Effect)?\s*:.*$',
  r'^\s*Set(?:\s*(?:Bonus|Effect))?\s*:.*$',
  r'^\s*(?:Unity\s*Rank(?:ing)?|Enchantment|Aftermath|Afterglow)\s*:.*$',
  r'^\s*(?:Reives|Campaign|Ballista|Dynamis|Abyssea|Odyssey|Sortie|Ambuscade|Assault|Salvage|Einherjar|Limbus|Walk(?:\s*of\s*)?Echoes|Legion|Besieged|Voidwatch|Delve|Skirmish|Nyzul(?:\s*Isle)?)\s*:.*$',
  r'^\s*Additional\s+effect\s*:.*$',                  # weapon on-hit (skip)
  r'^\s*(DMG|Delay|DPS)\s*:\s*\d+.*$',               # weapon params (skip)
]

# Inline segments (e.g., "... Haste+3%  Set: Haste+5%  Reives: TP+30")
PRE_FILTER_INLINE = r'''(?i)\s+(?:Set(?:\s*(?:Bonus|Effect))?|Latent(?:\s*Effect)?|Unity\s*Rank(?:ing)?|Aftermath|Enchantment|Reives|Campaign|Ballista|Dynamis|Abyssea|Odyssey|Sortie)\s*:\s*[^.\n]*'''

# Also strip inline "Main hand: ..." (weapon-only)
PRE_FILTER_MAINHAND = r'(?i)\bMain\s*hand\s*:\s*[^.\n]*'


# ======================================
# 1) Level / Jobs (normalization inputs)
# ======================================
RE_LEVEL = r'''(?ix)
  \b(?:lv\.?|level)\s*[:\s]* (?P<level>\d{1,3}) \b
'''

# BG/FFXIclopedia jobs line or “All Jobs”
RE_JOBS = r'''(?ix)
  \bjobs?\s*:\s*(?P<jobs>
      all\s+jobs
    | [A-Z]{2,3}(?:\s*(?:/|,|\s)\s*[A-Z]{2,3})+
    | [A-Za-z][A-Za-z ]+(?:\s*(?:/|,|\s)\s*[A-Za-z][A-Za-z ]+)*
  )\b
'''

# FFXIAH form: "LV 99 WAR MNK ..."
RE_LV_JOBS_COMBINED = r'''(?ix)
  \bLV\s*(?P<level>\d{1,3})\s+(?P<jobs>[A-Z]{2,3}(?:\s+[A-Z]{2,3})+)\b
'''


# ============================
# 2) Primary attributes (±N)
# ============================
RE_PRIMARY = r'''(?ix)
  \b(?P<tag>HP|MP|STR|DEX|VIT|AGI|INT|MND|CHR)\s*
  (?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b
'''


# =================================
# 3) Melee / Ranged Acc / Attack
# =================================
RE_ACC_ATK = r'''(?ix)
  \b(?P<tag>Accuracy|Acc\.)\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b
  |
  \b(?P<tag2>Attack|Atk\.)\s*(?P<sign2>[+-])\s*(?P<val2>\d+)\s*(?P<unit2>%?)\b
'''

RE_RANGED = r'''(?ix)
  \b(?:Rng\.?|Ranged|R\.)\s*
  (?P<tag>Accuracy|Acc\.|Attack|Atk\.)\s*
  (?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b
'''


# ======================================
# 4) Magic offense / defense families
# ======================================
RE_MAGIC = r'''(?ix)
  # Magic Accuracy (quoted/abbr)
  "?\b(?P<tag_macc>(?:Magic|Mag\.?)\s+Acc(?:uracy)?\.?)"?\s*(?P<sign_macc>[+-])\s*(?P<val_macc>\d+)\s*(?P<unit_macc>%?)\b
  |
  # Magic Atk. Bonus (quoted/abbr)
  "?\b(?P<tag_mab>(?:Magic|Mag\.?)\s+Atk\.?\s+(?:Bonus|Bns\.?))"?\s*(?P<sign_mab>[+-])\s*(?P<val_mab>\d+)\s*(?P<unit_mab>%?)\b
  |
  # Magic Evasion (spelled/abbr)
  \b(?P<tag_meva>(?:Magic\s+Evasion|Mag\.?\s*Eva\.?|M\.?\s*Eva\.?|Magic\s*Eva\.))\s*(?P<sign_meva>[+-])\s*(?P<val_meva>\d+)\s*(?P<unit_meva>%?)\b
  |
  # Magic Def. Bonus (quoted/abbr)
  "?\b(?P<tag_mdb>Magic\s+Def\.?\s+Bonus|Magic\s+Defense\s+Bonus|MDB)"?\s*(?P<sign_mdb>[+-])\s*(?P<val_mdb>\d+)\s*(?P<unit_mdb>%?)\b
'''

# Plain evasion (physical)
RE_EVASION = r'''(?ix)\b(?P<tag>Evasion|Eva\.)\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''


# ======================================
# 5) Tempo / TP / Multi / Crit
# ======================================
RE_HASTE      = r'''(?ix)\b(?P<tag>Haste)\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%)\b'''
RE_DUALWIELD  = r'''(?ix)\b(?P<tag>Dual\s*Wield)\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''

RE_STORETP    = r'''(?ix)"?\b(?P<tag>Store\s*TP)"?\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''
RE_SAVETP     = r'''(?ix)\b(?P<tag>Save\s*TP)\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''
RE_TPBONUS    = r'''(?ix)\b(?P<tag>TP\s*Bonus)\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''
RE_REGAIN     = r'''(?ix)\b(?P<tag>Regain)\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''

RE_SUBTLE     = r'''(?ix)"?\b(?P<tag>Subtle\s+Blow(?:\s*II)?)"?\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''

RE_MULTI      = r'''(?ix)"?(?P<tag>Double\s+Attack|Triple\s+Attack|Quadruple\s+Attack)"?\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%)\b'''
RE_CRITRATE   = r'''(?ix)\b(?P<tag>Critical\s+hit\s+rate)\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%)\b'''

RE_SNAPSHOT   = r'''(?ix)"?\b(?P<tag>Snapshot)"?\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''
RE_RAPIDSHOT  = r'''(?ix)"?\b(?P<tag>Rapid\s+Shot)"?\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''


# =====================
# 6) MB / SC / FastCast
# =====================
RE_MBD        = r'''(?ix)\b(?P<tag>Magic\s+burst\s+damage(?:\s*II)?)\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''
RE_SCBONUS    = r'''(?ix)"?\b(?P<tag>Skillchain\s+Bonus)"?\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''
RE_FASTCAST   = r'''(?ix)"?\b(?P<tag>Fast\s+Cast)"?\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b'''
RE_WSD        = r'''(?ix)"?\b(?P<tag>Weapon\s+Skill\s+Damage)"?\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%)\b'''
# (Skip WS attribute mods; weapon-only)


# ==========================
# 7) Mitigation / PDL
# ==========================
RE_DT         = r'''(?ix)\b(?P<tag>Damage\s+taken)\s*(?P<val>-?\d+)\s*(?P<unit>%)\b'''
RE_PDT        = r'''(?ix)\b(?P<tag>PDT|Physical\s+(?:damage|dmg\.?)\s+taken)\s*(?P<val>-?\d+)\s*(?P<unit>%)\b'''
RE_MDT        = r'''(?ix)\b(?P<tag>MDT|Magic\s+(?:damage|dmg\.?)\s+taken)\s*(?P<val>-?\d+)\s*(?P<unit>%)\b'''
RE_PDL        = r'''(?ix)\b(?P<tag>Physical\s+(?:damage|dmg\.?)\s+limit|PDL)\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%)\b'''


# ==========================
# 8) Skills (+X)
# ==========================
RE_SKILL      = r'''(?ix)
  \b(?P<tag>[A-Za-z][A-Za-z ]+?\s+skill)\s*(?P<sign>[+-])\s*(?P<val>\d+)\b
'''
# e.g., "Dagger skill +248", "Magic Accuracy skill +255"


# =========================================
# 9) Quoted specials / Cure received / misc
# =========================================
RE_QUOTED     = r'''(?ix)
  "(?P<tag>[^"]+)"\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%?)\b
'''
# "Treasure Hunter"+1, "Store TP"+11, "Magic Def. Bonus"+8, etc.

RE_EFFECT_RECV = r'''(?ix)
  (?:Potency\s+of\s+)?"(?P<ename>[^"]+)"\s+(?:effect\s+)?(?:received\s+)?(?P<sign>[+-])(?P<val>\d+)\s*(?P<unit>%?)\b
'''
# tag will be built as: Tag = f'"{ename}" effect received' (see post-proc)


# ========================================
# 10) Resistances / utility / control
# ========================================
RE_RESIST_GENERIC = r'''(?ix)
  \b(?P<tag>Resistance\s+to\s+all\s+status\s+ailments)\s*(?P<sign>[+-])\s*(?P<val>\d+)\b
'''
RE_RESIST_SPEC = r'''(?ix)
  \b(?:"?(?P<tag>Resist\s+[A-Za-z]+)"?)\s*(?P<sign>[+-])\s*(?P<val>\d+)\b
'''

RE_MOVESPD   = r'''(?ix)\b(?P<tag>Movement\s+speed)\s*(?P<sign>[+-])\s*(?P<val>\d+)\s*(?P<unit>%)\b'''
RE_ENMITY    = r'''(?ix)\b(?P<tag>Enmity)\s*(?P<sign>[+-])?\s*(?P<val>-?\d+)\s*(?P<unit>%?)\b'''
RE_REFRESH   = r'''(?ix)"?\b(?P<tag>Refresh)"?\s*(?P<sign>[+-])\s*(?P<val>\d+)\b'''
RE_CONSMP    = r'''(?ix)\b(?P<tag>Conserve\s*MP)\s*(?P<sign>[+-])\s*(?P<val>\d+)\b'''

# ==========================
# 11) Pet / Avatar prefixes
# ==========================
RE_PET_INLINE  = r'''(?ix)\b(?P<header>Pet\s*:\s*|Pet\s*Alive\s*:\s*|Avatar\s*:\s*)(?P<tail>[^\n\r.]+)'''
# -> re-scan tail with all the stat regex above; Tag should be from the inner token (e.g., "Accuracy"),
# and you will prefix the final *canon* as "Pet.Accuracy" / "Avatar.Enmity" in post-processing.


EX:
{
  "canon": "DT",                 // from your alias normalization of Tag
  "Tag": "Damage taken",         // EXACT label as matched in (?P<tag>...) or built from effect
  "value": -9,
  "sign": "-",
  "unit": "%",
  "unit_source": "explicit",     // or "inferred" when you add % via percent_like
  "raw": "Damage taken -9%",
  "span": [s, e]                 // indices in the sanitized string
}


import re

def sanitize_base_text(text: str) -> str:
    # drop whole-line noise first
    for pat in PRE_FILTER_LINES:
        text = re.sub(pat, '', text, flags=re.I|re.M)
    # strip inline gates
    text = re.sub(PRE_FILTER_INLINE, '', text, flags=re.I)
    text = re.sub(PRE_FILTER_MAINHAND, '', text, flags=re.I)
    # collapse whitespace & blank lines
    text = re.sub(r'[ \t]+', ' ', text)
    text = re.sub(r'(?m)^\s*$', '', text)
    return text.strip()

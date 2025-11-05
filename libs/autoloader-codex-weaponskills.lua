-- WEAPON_SKILLS.lua
-- Source notes:
--  - Numbers taken from BG Wiki pages (current as of mid-2025).
--  - fTP arrays are ordered {1000, 2000, 3000}.
--  - Omitted fields mean “not applicable / not listed”.

local WEAPON_SKILLS = {

  sword = {
    ["Savage Blade"] = {
      hits = 2,
      class = "physical",
      ftp = {4.00, 10.25, 13.75},
      ftp_rep = false,
      wsc = { STR = 0.50, MND = 0.50 },
      sc = {"Fragmentation", "Scission"},
    },

    ["Chant du Cygne"] = {
      hits = 3,
      class = "physical",
      ftp = {1.6328125, 1.6328125, 1.6328125},
      ftp_rep = true,
      wsc = { DEX = 0.80 },
      crit_rate = {0.15, 0.25, 0.40},
      sc = {"Light", "Distortion"},
    },
  },

  great_sword = {
    ["Resolution"] = {
      hits = 5,
      class = "physical",
      ftp = {0.71875, 1.50, 2.25},
      ftp_rep = true,
      wsc = { STR = 0.80 },        -- BG lists 73~85% depending on merits/history; use 0.80 as current
      attack_mod = 0.85,
      sc = {"Light", "Fragmentation", "Scission"},
    },

    ["Torcleaver"] = {
      hits = 1,
      class = "physical",
      ftp = {4.75, 7.50, 9.765625},
      ftp_rep = false,
      wsc = { VIT = 0.80 },
      sc = {"Light", "Distortion"},
    },
  },

  dagger = {
    ["Rudra's Storm"] = {
      hits = 1,
      class = "physical",
      ftp = {5.00, 10.19, 13.00},
      ftp_rep = false,
      wsc = { DEX = 0.80 },
      sc = {"Darkness", "Distortion"},
    },

    ["Evisceration"] = {
      hits = 5,
      class = "physical",
      ftp = {1.25, 1.25, 1.25},
      ftp_rep = true,
      wsc = { DEX = 0.50 },
      crit_rate = {0.10, 0.25, 0.50},
      sc = {"Gravitation", "Transfixion"},
    },
  },

  katana = {
    ["Blade: Hi"] = {
      hits = 1,
      class = "physical",
      ftp = {3.50, 3.50, 3.50},
      ftp_rep = false,
      wsc = { DEX = 0.80 },
      crit_rate = {0.10, 0.25, 0.40},
      sc = {"Light", "Transfixion"},
    },
  },

  great_katana = {
    ["Tachi: Fudo"] = {
      hits = 1,
      class = "physical",
      ftp = {4.75, 7.50, 9.75},
      ftp_rep = false,
      wsc = { STR = 0.80 },
      sc = {"Light", "Fragmentation"},
    },
  },

  polearm = {
    ["Stardiver"] = {
      hits = 4,
      class = "physical",
      ftp = {0.828125, 0.875, 0.90625},
      ftp_rep = true,
      wsc = { STR = 0.60 },
      sc = {"Light", "Detonation"},
    },
  },

  hand_to_hand = {
    ["Victory Smite"] = {
      hits = 4,
      class = "physical",
      ftp = {1.50, 1.50, 1.50},
      ftp_rep = true,
      wsc = { STR = 0.80 },
      crit_rate = {0.10, 0.25, 0.45},
      sc = {"Light", "Fragmentation"},
    },
  },

  staff = {
    ["Cataclysm"] = {
      hits = 1,
      class = "magical",
      ftp = {3.75, 6.50, 8.50},
      ftp_rep = false,
      wsc = { INT = 0.40, MND = 0.40 },
      element = "Darkness",
      dstat = "INT-MND",
      sc = {"Darkness", "Gravitation"},
    },
  },

  marksmanship = {
    ["Last Stand"] = {
      hits = 2,
      class = "ranged_physical",
      ftp = {2.00, 2.00, 2.00},
      ftp_rep = true,
      wsc = { AGI = 0.80 },
      sc = {"Light", "Fragmentation"},
    },

    ["Leaden Salute"] = {
      hits = 1,
      class = "magical_ranged",
      ftp = {4.00, 10.19, 13.00},
      ftp_rep = false,
      wsc = { AGI = 0.80 },
      element = "Darkness",
      dstat = "AGI-VIT",
      sc = {"Darkness", "Gravitation"},
    },

    ["Wildfire"] = {
      hits = 1,
      class = "magical_ranged",
      ftp = {2.00, 2.75, 3.50},
      ftp_rep = false,
      wsc = { AGI = 0.60 },
      element = "Fire",
      dstat = "AGI-MND",
      sc = {"Light", "Fusion"},
    },
  },

  archery = {
    ["Jishnu's Radiance"] = {
      hits = 3,
      class = "ranged_physical",
      ftp = {1.75, 1.75, 1.75},
      ftp_rep = true,
      wsc = { DEX = 0.80 },
      -- (Page notes crit scales with TP, but exact tiers aren’t listed; omit when not explicit.)
      sc = {"Light", "Transfixion"},
    },

    ["Namas Arrow"] = {
      hits = 1,
      class = "ranged_physical",
      ftp = {3.50, 3.50, 3.50},
      ftp_rep = false,
      wsc = { STR = 0.30, AGI = 0.30 },
      sc = {"Light", "Fusion"},
    },

    ["Apex Arrow"] = {
      hits = 1,
      class = "ranged_physical",
      ftp = {1.50, 1.75, 2.00},
      ftp_rep = false,
      wsc = { STR = 0.20, AGI = 0.20 },
      sc = {"Light", "Detonation"},
    },
  },
}

return WEAPON_SKILLS

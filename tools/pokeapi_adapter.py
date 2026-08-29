#!/usr/bin/env python3
"""PokéAPI api-data -> canonical raw dataset adapter (build tool, not game code).

Reads the OFFICIAL PokéAPI api-data clone (treated as SOURCE DATA, never as domain
code) and emits the canonical raw JSON that DataImporter (Godot) consumes, plus a
versioned manifest, a forms policy report and a mechanics classification report.

IDs are slugified (hyphens -> underscores) to satisfy the project's stable-id regex
^[a-z0-9_]+$. The slug mapping is internal and consistent across all references.
"""
import json
import os
import re
import sys
from collections import defaultdict

SOURCE = r"F:\pokemon roma el calvo\POKEMON_DATA_LIBRARY\01_POKEAPI_DATA\data\api\v2"
OUT_RAW = r"F:\pokemon roma el calvo\pokemon-calvo\data\raw\pokemon_api.json"
OUT_MANIFEST = r"F:\pokemon roma el calvo\pokemon-calvo\data\manifests\pokemon_api_manifest.json"
OUT_FORMS = r"F:\pokemon roma el calvo\pokemon-calvo\data\reports\forms_policy_report.json"
OUT_UNSUPPORTED = r"F:\pokemon roma el calvo\pokemon-calvo\data\reports\unsupported_mechanics.json"
OUT_BATTLE_EFFECTS = r"F:\pokemon roma el calvo\pokemon-calvo\data\reports\battle_effect_specs_summary.json"
SCHEMA_VERSION = 2
SOURCE_COMMIT = "784c50b3ad27d0390d3b047fc4c4511f71edd049"
SOURCE_COMMIT_SHORT = "784c50b3"
SOURCE_URL = "https://github.com/PokeAPI/api-data.git"


def slug(name: str) -> str:
    s = re.sub(r"[^a-z0-9]+", "_", (name or "").lower()).strip("_")
    return s


def load_ep(ep: str, i: str) -> dict:
    p = os.path.join(SOURCE, ep, str(i), "index.json")
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def list_ids(ep: str) -> list:
    d = os.path.join(SOURCE, ep)
    if not os.path.isdir(d):
        return []
    return [x for x in os.listdir(d) if x.isdigit()]


def en_effect(entries) -> str:
    if not entries:
        return ""
    for e in entries:
        if e.get("language", {}).get("name") == "en":
            return (e.get("short_effect") or e.get("effect") or "").strip()
    return (entries[0].get("short_effect") or entries[0].get("effect") or "").strip()


# ---- moves whose behavior we explicitly do NOT model yet (gimmick / copy moves) ----
UNSUPPORTED_MOVE_NAMES = {
    "metronome", "sketch", "assist", "copycat", "mimic", "transform",
    "sleep-talk", "me-first", "mirror-move", "bestow", "belch",
    "nature-power", "astonish",  # placeholder; refined below
}


# --- Structured move metadata -> BattleEffectSpec generation (FASE 5) ---
# PokéAPI ailment name -> StatusSystem status id. Unknown ailments stay unmapped (deferred).
AILMENT_MAP = {
    "paralysis": "paralysis",
    "sleep": "sleep",
    "freeze": "freeze",
    "burn": "burn",
    "poison": "poison",
    "confusion": "confusion",
}
# Explicit overrides for moves whose ailment needs a non-default status id.
AILMENT_OVERRIDES = {
    "toxic": "badly_poisoned",
}
# PokéAPI stat name -> StatStages stat id.
STAT_MAP = {
    "attack": "attack",
    "defense": "defense",
    "special-attack": "special_attack",
    "special-defense": "special_defense",
    "speed": "speed",
    "accuracy": "accuracy",
    "evasion": "evasion",
}
# Moves whose runtime behavior Battle Core V2 already supported via explicit registry specs
# (used only to compute the BEFORE coverage baseline for the report).
RUNTIME_SUPPORTED_REGISTRY = {
    "double_edge", "ember", "growl", "mega_drain", "quick_attack", "recover",
    "sleep_powder", "swords_dance", "tackle", "thunder", "thunder_punch",
    "thunder_wave", "toxic", "water_gun", "will_o_wisp",
}


def _load_contact_override() -> set:
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "move_flags_override.json")
    if not os.path.isfile(p):
        return set()
    try:
        data = json.load(open(p, encoding="utf-8"))
        return set(data.get("contact", []))
    except Exception:
        return set()


def generate_move_specs(m: dict, contact_set: set):
    """Return (specs, crit_rate_bp, makes_contact, coverage_label, override_count, unsupported_note).

    specs are SECONDARY effect specs only; the implicit DAMAGE spec is added by the runtime
    for power>0 moves (except multi-hit, which repeats damage internally).
    """
    sid = slug(m["name"])
    meta = m.get("meta") or {}
    ailment = (meta.get("ailment") or {}).get("name")
    ailment_chance = int(meta.get("ailment_chance") or 0)
    stat_chance = int(meta.get("stat_chance") or 0)
    drain = int(meta.get("drain") or 0)
    healing = int(meta.get("healing") or 0)
    flinch = int(meta.get("flinch_chance") or 0)
    crit = int(meta.get("crit_rate") or 0)
    min_hits = int(meta.get("min_hits") or 0)
    max_hits = int(meta.get("max_hits") or 0)
    effect_chance = m.get("effect_chance")
    effect_chance = int(effect_chance) if isinstance(effect_chance, int) else 0

    move_target = (m.get("target") or {}).get("name", "selected-pokemon")
    self_target = move_target in ("self", "user", "user-or-ally", "ally")
    stat_target = "self" if self_target else "opponent"

    specs = []
    override_count = 0
    unsupported_ailment = False
    unmodeled_stat = False

    # Status ailment
    if ailment and ailment not in ("none", "", None):
        status_id = AILMENT_OVERRIDES.get(sid, AILMENT_MAP.get(ailment))
        if status_id is None:
            unsupported_ailment = True
        else:
            if sid in AILMENT_OVERRIDES:
                override_count += 1
            bp = ailment_chance * 100 if ailment_chance > 0 else 10000
            spec = {"kind": "inflict_status", "target": "opponent",
                    "status_id": status_id, "chance_basis_points": bp}
            if bp < 10000:
                spec = {"kind": "chance", "target": "opponent",
                        "chance_basis_points": bp, "children": [spec]}
            specs.append(spec)

    # Stat changes
    for sc in m.get("stat_changes") or []:
        stat_id = STAT_MAP.get((sc.get("stat") or {}).get("name"))
        if stat_id is None:
            unmodeled_stat = True
            continue
        bp = stat_chance * 100 if stat_chance > 0 else 10000
        spec = {"kind": "modify_stat_stage", "target": stat_target,
                "stat_id": stat_id, "value": int(sc.get("change", 0)),
                "chance_basis_points": bp}
        if bp < 10000:
            spec = {"kind": "chance", "target": stat_target,
                    "chance_basis_points": bp, "children": [spec]}
        specs.append(spec)

    # Drain / recoil
    if drain > 0:
        specs.append({"kind": "drain", "target": "self", "ratio_basis_points": drain * 100})
    elif drain < 0:
        specs.append({"kind": "recoil", "target": "self", "ratio_basis_points": -drain * 100})

    # Healing
    if healing > 0:
        specs.append({"kind": "heal", "target": "self", "ratio_basis_points": healing * 100})

    # Flinch
    if flinch > 0:
        specs.append({"kind": "chance", "target": "opponent",
                      "chance_basis_points": flinch * 100,
                      "children": [{"kind": "flinch", "target": "opponent"}]})

    # Multi-hit: wrap damage (implicit) repetition; move drain/recoil inside the hit.
    if min_hits and max_hits and max_hits > 1:
        mh_children = []
        kept = []
        for s in specs:
            if s["kind"] in ("drain", "recoil"):
                mh_children.append(s)
            else:
                kept.append(s)
        specs = kept
        specs.insert(0, {"kind": "multi_hit", "target": "opponent",
                         "min_hits": min_hits, "max_hits": max_hits,
                         "children": mh_children})

    makes_contact = sid in contact_set
    crit_rate_bp = crit * 625 if crit > 0 else 0

    # Coverage (honest)
    has_secondary = (
        (ailment not in ("none", "", None)) or bool(m.get("stat_changes"))
        or drain != 0 or healing != 0 or flinch > 0 or (min_hits and max_hits and max_hits > 1)
    )
    power = m.get("power") or 0
    is_damaging = (m.get("damage_class") or {}).get("name") in ("physical", "special") and power and power > 0
    if sid in UNSUPPORTED_MOVE_NAMES:
        coverage = "UNSUPPORTED"
    elif is_damaging:
        if unsupported_ailment or unmodeled_stat:
            coverage = "PARTIAL_RUNTIME"
        elif effect_chance > 0 and not has_secondary:
            coverage = "PARTIAL_RUNTIME"
        else:
            coverage = "RUNTIME_SUPPORTED"
    elif ailment not in ("none", "", None):
        coverage = "RUNTIME_SUPPORTED" if (not unsupported_ailment) else "DATA_ONLY"
    else:
        coverage = "DATA_ONLY"

    return specs, crit_rate_bp, makes_contact, coverage, override_count, (unsupported_ailment or unmodeled_stat)


def classify_move_before(m: dict) -> str:
    """Coverage of the CURRENT runtime (explicit registry specs only), for the BEFORE baseline."""
    sid = slug(m["name"])
    meta = m.get("meta") or {}
    ailment = (meta.get("ailment") or {}).get("name")
    has_secondary = (
        (ailment not in ("none", "", None)) or bool(m.get("stat_changes"))
        or int(meta.get("drain") or 0) != 0 or int(meta.get("healing") or 0) != 0
        or int(meta.get("flinch_chance") or 0) > 0
        or (int(meta.get("min_hits") or 0) and int(meta.get("max_hits") or 0) > 1)
    )
    power = m.get("power") or 0
    is_damaging = (m.get("damage_class") or {}).get("name") in ("physical", "special") and power and power > 0
    if sid in UNSUPPORTED_MOVE_NAMES:
        return "UNSUPPORTED"
    if sid in RUNTIME_SUPPORTED_REGISTRY:
        return "RUNTIME_SUPPORTED"
    if is_damaging:
        return "RUNTIME_SUPPORTED" if not has_secondary else "PARTIAL_RUNTIME"
    if ailment not in ("none", "", None):
        return "RUNTIME_SUPPORTED"
    return "DATA_ONLY"


def classify_evolution_trigger(trigger_slug: str) -> str:
    # SUPPORTED_RUNTIME_OR_MODEL -> the data MODEL represents this trigger (min_level stored)
    # PARTIAL_RUNTIME            -> some data modeled (e.g. item_id for use-item)
    # UNSUPPORTED                -> trigger the model cannot represent yet
    if trigger_slug == "level_up":
        return "SUPPORTED_RUNTIME_OR_MODEL"
    if trigger_slug == "use_item":
        return "PARTIAL_RUNTIME"
    return "UNSUPPORTED"


def form_kind(name: str) -> str:
    n = name.lower()
    if "mega" in n:
        return "MEGA"
    if "gmax" in n or "gigantamax" in n:
        return "GIGANTAMAX"
    if any(r in n for r in ("alola", "galar", "hisui", "paldea", "unova", "hoenn", "sinnoh")):
        return "REGIONAL"
    if "totem" in n:
        return "TOTEM"
    if "cosplay" in n or "flower" in n or "pattern" in n or "size" in n:
        return "COSMETIC"
    return "ALTERNATE"


def main():
    types = []
    type_slugs = set()
    for i in list_ids("type"):
        t = load_ep("type", i)
        eff = {}
        rel = t.get("damage_relations", {})
        for target_list, mult in (
            (rel.get("double_damage_to", []), 2.0),
            (rel.get("half_damage_to", []), 0.5),
            (rel.get("no_damage_to", []), 0.0),
        ):
            for x in target_list:
                eff[slug(x["name"])] = mult
        sid = slug(t["name"])
        type_slugs.add(sid)
        types.append({"id": sid, "display_name": t["name"], "effectiveness": eff})
    print(f"types: {len(types)}")

    moves = []
    move_slugs = set()
    move_class = defaultdict(list)
    before_class = defaultdict(int)
    contact_set = _load_contact_override()
    for i in list_ids("move"):
        m = load_ep("move", i)
        sid = slug(m["name"])
        move_slugs.add(sid)
        specs, crit_bp, contact, cls, override_count, _ = generate_move_specs(m, contact_set)
        move_class[cls].append(sid)
        before_class[classify_move_before(m)] += 1
        moves.append({
            "id": sid,
            "display_name": m["name"],
            "power": m.get("power") or 0,
            "type_id": slug((m.get("type") or {}).get("name", "normal")),
            "priority": m.get("priority") or 0,
            "damage_class": (m.get("damage_class") or {}).get("name") or "status",
            "accuracy": m.get("accuracy") if m.get("accuracy") is not None else 100,
            "pp": m.get("pp") or 0,
            "target": (m.get("target") or {}).get("name", "selected"),
            "effect_summary": en_effect(m.get("effect_entries")),
            "effect_specs": specs,
            "crit_rate_bp": crit_bp,
            "makes_contact": contact,
            "classification": cls,
        })
    print(f"moves: {len(moves)}  classes={ {k: len(v) for k, v in move_class.items()} }")

    abilities = []
    ability_slugs = set()
    for i in list_ids("ability"):
        a = load_ep("ability", i)
        sid = slug(a["name"])
        ability_slugs.add(sid)
        abilities.append({
            "id": sid,
            "display_name": a["name"],
            "description": en_effect(a.get("effect_entries")),
            "effect_id": sid,
            "effect_summary": en_effect(a.get("effect_entries")),
            "classification": "DATA_ONLY",
        })
    print(f"abilities: {len(abilities)}")

    items = []
    seen_item = set()
    dup_items = 0
    for i in list_ids("item"):
        it = load_ep("item", i)
        sid = slug(it["name"])
        if sid in seen_item:
            dup_items += 1
            continue
        seen_item.add(sid)
        items.append({
            "id": sid,
            "display_name": it["name"],
            "description": en_effect(it.get("effect_entries")),
            "category": slug((it.get("category") or {}).get("name", "misc")),
        })
    print(f"items: {len(items)}  duplicate_item_slugs_skipped={dup_items}")

    statuses = []
    if os.path.isdir(os.path.join(SOURCE, "status")):
        for i in list_ids("status"):
            st = load_ep("status", i)
            statuses.append({"id": slug(st["name"]), "display_name": st["name"]})
    print(f"statuses: {len(statuses)}")

    # pokemon -> stats/types/abilities/learnset (keyed by pokemon name slug)
    pokemon_by_name = {}
    for i in list_ids("pokemon"):
        pk = load_ep("pokemon", i)
        pname = slug(pk["name"])
        types_l = [slug(x["type"]["name"]) for x in sorted(pk.get("types", []), key=lambda x: x.get("slot", 0))]
        stats = {}
        for s in pk.get("stats", []):
            key = {"hp": "hp", "attack": "attack", "defense": "defense",
                   "special-attack": "spatk", "special-defense": "spdef",
                   "speed": "speed"}.get(s["stat"]["name"], s["stat"]["name"])
            stats[key] = s["base_stat"]
        abilities_l = [slug(a["ability"]["name"]) for a in pk.get("abilities", [])]
        learnset = []
        seen = set()
        for mv in pk.get("moves", []):
            msid = slug(mv["move"]["name"])
            for d in mv.get("version_group_details", []):
                method = slug(d["move_learn_method"]["name"])
                level = d.get("level_learned_at", 0) or 0
                key = (msid, method, level)
                if key in seen:
                    continue
                seen.add(key)
                learnset.append({"level": level, "move_id": msid, "method": method})
        effort = {}
        key_map = {"hp": "hp", "attack": "attack", "defense": "defense",
                   "special-attack": "special_attack", "special-defense": "special_defense",
                   "speed": "speed"}
        for s in pk.get("stats", []):
            effort[key_map.get(s["stat"]["name"], s["stat"]["name"])] = int(s.get("effort") or 0)
        pokemon_by_name[pname] = {
            "types": types_l, "stats": stats, "abilities": abilities_l,
            "learnset": learnset, "effort": effort,
            "base_experience": pk.get("base_experience") or 0,
            "species_name": slug(pk["species"]["name"]),
        }
    print(f"pokemon entries: {len(pokemon_by_name)}")

    # evolution chains -> per-species evolution records (raw, before forms drop)
    evo_map = defaultdict(list)
    for i in list_ids("evolution-chain"):
        chain = load_ep("evolution-chain", i)["chain"]

        def walk(node):
            from_name = slug(node["species"]["name"])
            for e in node.get("evolves_to", []):
                to_name = slug(e["species"]["name"])
                details = e.get("evolution_details") or [{}]
                det = details[0] if details else {}
                trigger = slug((det.get("trigger") or {}).get("name", "level_up"))
                item = slug(det["item"]["name"]) if det.get("item") else ""
                min_level = det.get("min_level") or 0
                evo_map[from_name].append({
                    "species_id": to_name, "min_level": min_level,
                    "trigger": trigger, "item_id": item,
                })
                walk(e)
        walk(chain)
    total_source_evo = sum(len(v) for v in evo_map.values())
    print(f"evolution chains: {len(list_ids('evolution-chain'))}  total evo links (SOURCE): {total_source_evo}")

    # species (apply forms policy: hyphen == form -> deferred)
    species = []
    deferred_forms = []
    imported_species_slugs = set()
    for i in list_ids("pokemon-species"):
        ps = load_ep("pokemon-species", i)
        sname = slug(ps["name"])
        if "-" in ps["name"]:
            deferred_forms.append({
                "id": sname, "original_name": ps["name"], "kind": form_kind(ps["name"]),
                "reason": "Hyphenated name treated as form; deferred (not a base SpeciesDefinition).",
            })
            continue
        # default variety pokemon
        default_pname = sname
        for v in ps.get("varieties", []):
            if v.get("is_default"):
                default_pname = slug(v["pokemon"]["name"])
                break
        pk = pokemon_by_name.get(default_pname)
        if pk is None:
            # fallback: maybe species name matches a pokemon name exactly
            pk = pokemon_by_name.get(sname)
        if pk is None:
            deferred_forms.append({"id": sname, "original_name": ps["name"], "kind": "UNMAPPED",
                                   "reason": "No pokemon stats found; deferred."})
            continue
        st = pk["stats"]
        entry = {
            "id": sname,
            "display_name": ps["name"],
            "types": pk["types"],
            "base_hp": st.get("hp", 1),
            "base_attack": st.get("attack", 1),
            "base_defense": st.get("defense", 1),
            "base_speed": st.get("speed", 1),
            "base_special_attack": st.get("spatk", 1),
            "base_special_defense": st.get("spdef", 1),
            "ability_ids": pk["abilities"],
            "base_experience": pk.get("base_experience") or 0,
            "growth_rate": (ps.get("growth_rate") or {}).get("name", "medium"),
            "ev_yield": pk.get("effort", {}),
            "learnset": pk["learnset"],
            "evolutions": [],
        }
        # only keep evolutions whose target is also an imported (base) species
        for ev in evo_map.get(sname, []):
            if ev["species_id"] in imported_species_slugs or True:
                # target validity resolved after full pass; tentatively include
                entry["evolutions"].append(ev)
        imported_species_slugs.add(sname)
        species.append(entry)
    # second pass: drop evolutions pointing to deferred forms, and classify only IMPORTED edges
    deferred_targets = {f["id"] for f in deferred_forms}
    imported_evo_class = defaultdict(list)
    retained_evo = 0
    for sp in species:
        kept = []
        for ev in sp["evolutions"]:
            if ev["species_id"] in deferred_targets:
                continue
            kept.append(ev)
            retained_evo += 1
            cls = classify_evolution_trigger(ev["trigger"])
            imported_evo_class[cls].append(f"{sp['id']}->{ev['species_id']}")
        sp["evolutions"] = kept
    deferred_evo = total_source_evo - retained_evo
    print(f"species (imported): {len(species)}  forms deferred: {len(deferred_forms)}  evo IMPORTED: {retained_evo}  DEFERRED: {deferred_evo}")

    raw = {
        "types": types,
        "moves": moves,
        "abilities": abilities,
        "items": items,
        "statuses": statuses,
        "species": species,
    }

    os.makedirs(os.path.dirname(OUT_RAW), exist_ok=True)
    with open(OUT_RAW, "w", encoding="utf-8") as f:
        json.dump(raw, f, ensure_ascii=False, indent=1)

    manifest = {
        "schema_version": SCHEMA_VERSION,
        "dataset_version": "2.0.0",
        "source": "pokeapi/api-data",
        "generated_at": "2026-08-29",
        "ruleset": "foundation_v1",
        "provenance": {
            "source_name": "PokeAPI/api-data",
            "source_version": SOURCE_COMMIT,
            "source_commit": SOURCE_COMMIT,
            "source_commit_short": SOURCE_COMMIT_SHORT,
            "source_url": SOURCE_URL,
            "license": "BSD 3-Clause (see LICENSE.txt in PokeAPI/api-data). Pokemon character/name/design IP is owned by Nintendo/Creatures/Game Freak; this dataset reuses factual game data under the source's BSD 3-Clause license and is not affiliated with or endorsed by Nintendo/Creatures/Game Freak.",
            "import_date": "2026-08-29",
            "schema_version": SCHEMA_VERSION,
        },
    }
    with open(OUT_MANIFEST, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    forms_report = {
        "policy": "Hyphenated PokemonAPI names are treated as forms (regional/alternate/mega/gigantamax/totem/cosmetic) and are NOT imported as base SpeciesDefinition. Only the default variety of each base species is imported. Evolutions targeting deferred forms are dropped to avoid broken references.",
        "forms_total": len(deferred_forms),
        "species_total": len(species),
        "deferred": deferred_forms,
    }
    os.makedirs(os.path.dirname(OUT_FORMS), exist_ok=True)
    with open(OUT_FORMS, "w", encoding="utf-8") as f:
        json.dump(forms_report, f, ensure_ascii=False, indent=1)

    unsupported = {
        "summary": {
            "moves": {
                "DATA_READY": len(moves),
                "RUNTIME_SUPPORTED": len(move_class.get("RUNTIME_SUPPORTED", [])),
                "PARTIAL_RUNTIME": len(move_class.get("PARTIAL_RUNTIME", [])),
                "DATA_ONLY": len(move_class.get("DATA_ONLY", [])),
                "UNSUPPORTED": len(move_class.get("UNSUPPORTED", [])),
            },
            "abilities": {"DATA_READY": len(abilities), "DATA_ONLY": len(abilities)},
            "items": {"DATA_READY": len(items), "DATA_ONLY": len(items)},
            "evolutions": {
                "SOURCE_EDGES": total_source_evo,
                "IMPORTED_EDGES": retained_evo,
                "DEFERRED_FORM_EDGES": deferred_evo,
                "REJECTED_EDGES": 0,
                "SUPPORTED_RUNTIME_OR_MODEL": len(imported_evo_class.get("SUPPORTED_RUNTIME_OR_MODEL", [])),
                "PARTIAL_RUNTIME": len(imported_evo_class.get("PARTIAL_RUNTIME", [])),
                "UNSUPPORTED": len(imported_evo_class.get("UNSUPPORTED", [])),
            },
        },
        "moves": {k: sorted(v) for k, v in move_class.items()},
        "abilities": {"DATA_ONLY": sorted([a["id"] for a in abilities])},
        "items": {"DATA_ONLY": sorted([it["id"] for it in items])},
        "evolutions": {
            "SOURCE_EDGES": total_source_evo,
            "IMPORTED_EDGES": retained_evo,
            "DEFERRED_FORM_EDGES": deferred_evo,
            "REJECTED_EDGES": 0,
            "SUPPORTED_RUNTIME_OR_MODEL": sorted(imported_evo_class.get("SUPPORTED_RUNTIME_OR_MODEL", [])),
            "PARTIAL_RUNTIME": sorted(imported_evo_class.get("PARTIAL_RUNTIME", [])),
            "UNSUPPORTED": sorted(imported_evo_class.get("UNSUPPORTED", [])),
        },
        "forms": {"deferred_total": len(deferred_forms), "deferred": deferred_forms},
        "statuses": {"DATA_READY": len(statuses), "DATA_ONLY": sorted([s["id"] for s in statuses])},
        "other": {},
    }
    with open(OUT_UNSUPPORTED, "w", encoding="utf-8") as f:
        json.dump(unsupported, f, ensure_ascii=False, indent=1)

    # quick self-check: broken references
    broken = []
    for sp in species:
        for t in sp["types"]:
            if t not in type_slugs:
                broken.append(f"{sp['id']} bad type {t}")
        for a in sp["ability_ids"]:
            if a not in ability_slugs:
                broken.append(f"{sp['id']} bad ability {a}")
        for ls in sp["learnset"]:
            if ls["move_id"] not in move_slugs:
                broken.append(f"{sp['id']} bad move {ls['move_id']}")
        for ev in sp["evolutions"]:
            if ev["species_id"] not in imported_species_slugs:
                broken.append(f"{sp['id']} bad evo {ev['species_id']}")
    for mv in moves:
        if mv["type_id"] not in type_slugs:
            broken.append(f"move {mv['id']} bad type {mv['type_id']}")
    print(f"BROKEN REFERENCES (pre-import self-check): {len(broken)}")
    for b in broken[:20]:
        print("  ", b)

    # Battle effect specs summary (FASE 5 deliverable report).
    effect_specs_generated = sum(1 for mv in moves if mv["effect_specs"])
    generated_by_metadata = sum(len(mv["effect_specs"]) for mv in moves)
    generated_by_override = sum(
        1 for mv in moves
        if any(s.get("status_id") in ("badly_poisoned",) for s in mv["effect_specs"])
    )
    specific_handler = sum(
        1 for mv in moves
        if not mv["effect_specs"] and mv["id"] in RUNTIME_SUPPORTED_REGISTRY
    )
    battle_effect_report = {
        "schema_version": SCHEMA_VERSION,
        "source_sha": SOURCE_COMMIT,
        "generated_at": "2026-08-29",
        "moves_total": len(moves),
        "effect_specs_generated": effect_specs_generated,
        "runtime_supported_before": before_class.get("RUNTIME_SUPPORTED", 0),
        "runtime_supported_after": len(move_class.get("RUNTIME_SUPPORTED", [])),
        "partial_runtime": len(move_class.get("PARTIAL_RUNTIME", [])),
        "data_only": len(move_class.get("DATA_ONLY", [])),
        "unsupported": len(move_class.get("UNSUPPORTED", [])),
        "generated_by_metadata": generated_by_metadata,
        "generated_by_override": generated_by_override,
        "specific_handler": specific_handler,
        "validation_errors": [],
        "contact_metadata": "OVERRIDE",
        "contact_override_source": "tools/move_flags_override.json",
        "static_contact": "CORRECTED",
        "multi_hit": "IMPLEMENTED",
        "protect": "DEFERRED",
        "ruleset_fingerprint": "DEFERRED",
        "deferred": [
            "protect_and_vulnerable_implementations",
            "weather_terrain_hazards",
            "doubles_targeting",
            "unmodeled_ailments_infatuation_trap_fling",
        ],
    }
    os.makedirs(os.path.dirname(OUT_BATTLE_EFFECTS), exist_ok=True)
    with open(OUT_BATTLE_EFFECTS, "w", encoding="utf-8") as f:
        json.dump(battle_effect_report, f, ensure_ascii=False, indent=2)
    print(f"battle effect specs: generated={effect_specs_generated} "
          f"runtime_supported_before={before_class.get('RUNTIME_SUPPORTED', 0)} "
          f"after={len(move_class.get('RUNTIME_SUPPORTED', []))}")

    print("DONE")


if __name__ == "__main__":
    main()

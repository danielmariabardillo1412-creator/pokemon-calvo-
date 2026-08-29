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
SOURCE_COMMIT = "784c50b3"
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


def classify_move(m: dict) -> str:
    dmg = (m.get("damage_class") or {}).get("name")
    power = m.get("power") or 0
    if slug(m["name"]) in UNSUPPORTED_MOVE_NAMES:
        return "UNSUPPORTED"
    if dmg in ("physical", "special") and power and power > 0:
        return "SUPPORTED"
    if dmg == "status" or power == 0:
        return "PARTIAL"
    return "DATA_ONLY"


def classify_evolution_trigger(trigger_name: str) -> str:
    return "SUPPORTED" if trigger_name == "level-up" else "UNSUPPORTED"


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
    for i in list_ids("move"):
        m = load_ep("move", i)
        sid = slug(m["name"])
        move_slugs.add(sid)
        cls = classify_move(m)
        move_class[cls].append(sid)
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
        pokemon_by_name[pname] = {
            "types": types_l, "stats": stats, "abilities": abilities_l,
            "learnset": learnset, "species_name": slug(pk["species"]["name"]),
        }
    print(f"pokemon entries: {len(pokemon_by_name)}")

    # evolution chains -> per-species evolution records
    evo_map = defaultdict(list)
    evo_class = defaultdict(list)
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
                cls = classify_evolution_trigger((det.get("trigger") or {}).get("name", ""))
                evo_class[cls].append(f"{from_name}->{to_name}")
                evo_map[from_name].append({
                    "species_id": to_name, "min_level": min_level,
                    "trigger": trigger, "item_id": item,
                })
                walk(e)
        walk(chain)
    print(f"evolution chains: {len(list_ids('evolution-chain'))}  total evo links: {sum(len(v) for v in evo_map.values())}")

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
            "base_experience": ps.get("base_experience") or 0,
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
    # second pass: drop evolutions pointing to deferred forms
    deferred_targets = {f["id"] for f in deferred_forms}
    for sp in species:
        sp["evolutions"] = [ev for ev in sp["evolutions"] if ev["species_id"] not in deferred_targets]
    print(f"species (imported): {len(species)}  forms deferred: {len(deferred_forms)}")

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
        "schema_version": 1,
        "dataset_version": "1.0.0",
        "source": "pokeapi/api-data",
        "generated_at": "2026-08-29",
        "ruleset": "foundation_v1",
        "provenance": {
            "source_name": "PokeAPI/api-data",
            "source_version": "regenerated from PokeAPI#1629",
            "source_commit": SOURCE_COMMIT,
            "source_url": SOURCE_URL,
            "license": "PokeAPI data license (see https://github.com/PokeAPI/api-data/blob/master/LICENSE.txt); derived Pokemon data is not affiliated with Nintendo/Creatures/Game Freak.",
            "import_date": "2026-08-29",
            "schema_version": 1,
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
        "moves": {k: sorted(v) for k, v in move_class.items()},
        "abilities": {"DATA_ONLY": sorted([a["id"] for a in abilities])},
        "evolutions": {k: sorted(v) for k, v in evo_class.items()},
        "forms": {"deferred_total": len(deferred_forms)},
        "statuses": {"DATA_ONLY": sorted([s["id"] for s in statuses])},
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

    print("DONE")


if __name__ == "__main__":
    main()

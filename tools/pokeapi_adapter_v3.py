#!/usr/bin/env python3
"""PokéAPI snapshot -> canonical runtime dataset, V3.

V3 fixes the two structural mistakes of the legacy adapter:
1) learnsets are selected from ONE coherent version-group per Pokémon instead of
   unioning every generation together;
2) hyphenated species names are not treated as forms. Species/varieties are read
   from pokemon-species.varieties and the default variety is selected explicitly.

The source snapshot is treated as immutable. This tool only writes project-owned
raw/manifest/report files. Godot's tools/run_import.gd remains the second stage that
validates and writes data/normalized/pokemon_api.json.

The mature move-effect conversion from pokeapi_adapter.py is intentionally reused;
V3 replaces source selection/provenance, localization, species/forms, learnsets and
full evolution preservation around it.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable

# tools/ is automatically on sys.path when this file is executed directly.
import pokeapi_adapter as legacy

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT / "data" / "api" / "v2"
DEFAULT_RAW = ROOT / "data" / "raw" / "pokemon_api.json"
DEFAULT_MANIFEST = ROOT / "data" / "manifests" / "pokemon_api_manifest.json"
DEFAULT_FORMS = ROOT / "data" / "reports" / "forms_policy_report.json"
DEFAULT_UNSUPPORTED = ROOT / "data" / "reports" / "unsupported_mechanics.json"
DEFAULT_AUDIT = ROOT / "data" / "reports" / "pokeapi_v3_audit.json"
DEFAULT_AUX = ROOT / "data" / "reports" / "pokeapi_v3_auxiliary.json"

SCHEMA_VERSION = 2  # backwards-compatible extension of the existing canonical schema
DATASET_VERSION = "3.0.0"
SOURCE_SNAPSHOT_COMMIT = "2f218ec3765c01c894a42bbbd074f15ddf3f32d1"
SOURCE_API_TREE = "8349ea1ce75716897fe96e02a15950d19edba6c3"
SOURCE_SCHEMA_TREE = "02e031e1928d7e9456bf6f7486daacc4b8946c84"
SOURCE_URL = "https://github.com/PokeAPI/pokeapi"

STANDARD_TYPES = (
    "normal", "fire", "water", "electric", "grass", "ice",
    "fighting", "poison", "ground", "flying", "psychic", "bug",
    "rock", "ghost", "dragon", "dark", "steel", "fairy",
)
STANDARD_TYPE_SET = set(STANDARD_TYPES)

# Newest -> oldest. Deliberately excludes side-game/special-mechanics groups such as
# Stadium, Colosseum/XD and Legends: Arceus. If a species is absent from a newer game,
# we fall back to its newest available conventional main-series learnset.
MAINLINE_VERSION_GROUP_PRIORITY = (
    "scarlet-violet",
    "brilliant-diamond-shining-pearl",
    "sword-shield",
    "lets-go-pikachu-lets-go-eevee",
    "ultra-sun-ultra-moon",
    "sun-moon",
    "omega-ruby-alpha-sapphire",
    "x-y",
    "black-2-white-2",
    "black-white",
    "heartgold-soulsilver",
    "platinum",
    "diamond-pearl",
    "firered-leafgreen",
    "emerald",
    "ruby-sapphire",
    "crystal",
    "gold-silver",
    "yellow",
    "red-blue",
)
VERSION_PRIORITY_RANK = {name: i for i, name in enumerate(MAINLINE_VERSION_GROUP_PRIORITY)}

LANGUAGE_PRIORITY = ("es", "es-419", "en")


def slug(value: str) -> str:
    return legacy.slug(value)


def load_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)


def list_ids(source: Path, endpoint: str) -> list[str]:
    directory = source / endpoint
    if not directory.is_dir():
        return []
    return sorted((p.name for p in directory.iterdir() if p.is_dir() and p.name.isdigit()), key=int)


def load_ep(source: Path, endpoint: str, entry_id: str | int) -> dict:
    return load_json(source / endpoint / str(entry_id) / "index.json")


def localized_name(record: dict, fallback: str | None = None) -> str:
    names = record.get("names") or []
    for language in LANGUAGE_PRIORITY:
        for entry in names:
            if (entry.get("language") or {}).get("name") == language and entry.get("name"):
                return str(entry["name"])
    return str(fallback if fallback is not None else record.get("name", ""))


def localized_effect(entries: Iterable[dict] | None) -> str:
    entries = list(entries or [])
    for language in LANGUAGE_PRIORITY:
        for entry in entries:
            if (entry.get("language") or {}).get("name") == language:
                text = entry.get("short_effect") or entry.get("effect") or ""
                if text:
                    return str(text).strip()
    for entry in entries:
        text = entry.get("short_effect") or entry.get("effect") or ""
        if text:
            return str(text).strip()
    return ""


def resource_name(value: Any) -> str:
    if not isinstance(value, dict):
        return ""
    return slug(str(value.get("name", "")))


def preserve_project_statuses() -> list[dict]:
    """Statuses are project battle rules, not a direct PokeAPI endpoint."""
    path = DEFAULT_RAW
    if not path.is_file():
        return []
    try:
        raw = load_json(path)
        statuses = raw.get("statuses", [])
        return statuses if isinstance(statuses, list) else []
    except Exception:
        return []


def load_version_group_ids(source: Path) -> dict[str, int]:
    result: dict[str, int] = {}
    for entry_id in list_ids(source, "version-group"):
        vg = load_ep(source, "version-group", entry_id)
        name = str(vg.get("name", ""))
        if name:
            result[name] = int(vg.get("id", entry_id))
    return result


def choose_version_group(pokemon: dict, version_ids: dict[str, int]) -> tuple[str, str]:
    groups: set[str] = set()
    for move in pokemon.get("moves", []) or []:
        for detail in move.get("version_group_details", []) or []:
            name = str((detail.get("version_group") or {}).get("name", ""))
            if name:
                groups.add(name)
    for preferred in MAINLINE_VERSION_GROUP_PRIORITY:
        if preferred in groups:
            return preferred, "mainline_priority"
    if not groups:
        return "", "no_learnset_data"
    # Rare fallback: preserve data rather than emit an empty species, but make the
    # deviation auditable. Highest PokeAPI version-group id is deterministic.
    selected = max(groups, key=lambda g: (version_ids.get(g, -1), g))
    return selected, "fallback_latest_any"


def build_learnset(pokemon: dict, selected_group: str) -> list[dict]:
    out: list[dict] = []
    seen: set[tuple] = set()
    for move in pokemon.get("moves", []) or []:
        move_id = slug((move.get("move") or {}).get("name", ""))
        if not move_id:
            continue
        for detail in move.get("version_group_details", []) or []:
            group = str((detail.get("version_group") or {}).get("name", ""))
            if group != selected_group:
                continue
            method = slug((detail.get("move_learn_method") or {}).get("name", ""))
            level = int(detail.get("level_learned_at", 0) or 0)
            order_raw = detail.get("order")
            order = int(order_raw) if isinstance(order_raw, int) else -1
            key = (move_id, method, level, order, group)
            if key in seen:
                continue
            seen.add(key)
            entry = {
                "level": level,
                "move_id": move_id,
                "method": method,
                "version_group": group,
            }
            if order >= 0:
                entry["order"] = order
            out.append(entry)
    method_rank = {"level_up": 0, "egg": 1, "machine": 2, "tutor": 3}
    out.sort(key=lambda e: (
        method_rank.get(e["method"], 99),
        int(e["level"]),
        int(e.get("order", 1_000_000)),
        e["move_id"],
        e["method"],
    ))
    return out


def condition_value(value: Any) -> Any:
    if isinstance(value, dict) and "name" in value:
        return slug(str(value.get("name", "")))
    if isinstance(value, (str, int, bool)) or value is None:
        return value
    if isinstance(value, list):
        return [condition_value(v) for v in value]
    return value


def evolution_record(target_name: str, detail: dict) -> dict:
    trigger = resource_name(detail.get("trigger")) or "level_up"
    item_id = resource_name(detail.get("item"))
    version_group = resource_name(detail.get("version_group"))
    min_level = int(detail.get("min_level") or 0)
    conditions: dict[str, Any] = {}
    # Preserve every source condition except fields already represented as legacy
    # first-class fields. Null/false/empty values are omitted to keep raw compact.
    skip = {"trigger", "item", "min_level", "version_group", "is_default"}
    for key, value in detail.items():
        if key in skip:
            continue
        normalized = condition_value(value)
        if normalized in (None, "", False, 0, [], {}):
            continue
        conditions[key] = normalized
    record = {
        "species_id": slug(target_name),
        "min_level": min_level,
        "trigger": trigger,
        "item_id": item_id,
    }
    if version_group:
        record["version_group"] = version_group
    if detail.get("is_default") is False:
        record["is_default"] = False
    if conditions:
        record["conditions"] = conditions
    return record


def build_evolution_map(source: Path) -> dict[str, list[dict]]:
    evo_map: dict[str, list[dict]] = defaultdict(list)
    for chain_id in list_ids(source, "evolution-chain"):
        chain = (load_ep(source, "evolution-chain", chain_id).get("chain") or {})

        def walk(node: dict) -> None:
            from_name = str((node.get("species") or {}).get("name", ""))
            for child in node.get("evolves_to", []) or []:
                target_name = str((child.get("species") or {}).get("name", ""))
                details = child.get("evolution_details") or [{}]
                if not details:
                    details = [{}]
                for detail in details:
                    evo_map[slug(from_name)].append(evolution_record(target_name, detail or {}))
                walk(child)

        walk(chain)
    return evo_map


def build_types(source: Path) -> list[dict]:
    records: dict[str, dict] = {}
    for entry_id in list_ids(source, "type"):
        t = load_ep(source, "type", entry_id)
        sid = slug(str(t.get("name", "")))
        if sid not in STANDARD_TYPE_SET:
            continue
        effectiveness: dict[str, float] = {}
        relations = t.get("damage_relations") or {}
        for field, multiplier in (
            ("double_damage_to", 2.0),
            ("half_damage_to", 0.5),
            ("no_damage_to", 0.0),
        ):
            for target in relations.get(field, []) or []:
                target_id = slug(str(target.get("name", "")))
                if target_id in STANDARD_TYPE_SET:
                    effectiveness[target_id] = multiplier
        records[sid] = {
            "id": sid,
            "display_name": localized_name(t, t.get("name", sid)),
            "effectiveness": effectiveness,
        }
    return [records[t] for t in STANDARD_TYPES if t in records]


def build_moves(source: Path) -> tuple[list[dict], dict[str, list[str]], dict[str, int]]:
    moves: list[dict] = []
    move_classes: dict[str, list[str]] = defaultdict(list)
    before_classes: Counter[str] = Counter()
    contact_set = legacy._load_contact_override()
    for entry_id in list_ids(source, "move"):
        move = load_ep(source, "move", entry_id)
        sid = slug(str(move.get("name", "")))
        specs, crit_bp, contact, classification, _, _ = legacy.generate_move_specs(move, contact_set)
        move_classes[classification].append(sid)
        before_classes[legacy.classify_move_before(move)] += 1
        moves.append({
            "id": sid,
            "display_name": localized_name(move, move.get("name", sid)),
            "power": int(move.get("power") or 0),
            "type_id": resource_name(move.get("type")) or "normal",
            "priority": int(move.get("priority") or 0),
            "damage_class": (move.get("damage_class") or {}).get("name") or "status",
            "accuracy": int(move.get("accuracy")) if move.get("accuracy") is not None else 100,
            "pp": int(move.get("pp") or 0),
            "target": (move.get("target") or {}).get("name", "selected"),
            "effect_summary": localized_effect(move.get("effect_entries")),
            "effect_specs": specs,
            "crit_rate_bp": crit_bp,
            "makes_contact": contact,
            "classification": classification,
        })
    moves.sort(key=lambda x: x["id"])
    return moves, {k: sorted(v) for k, v in move_classes.items()}, dict(before_classes)


def build_abilities(source: Path) -> list[dict]:
    out: list[dict] = []
    for entry_id in list_ids(source, "ability"):
        ability = load_ep(source, "ability", entry_id)
        sid = slug(str(ability.get("name", "")))
        out.append({
            "id": sid,
            "display_name": localized_name(ability, ability.get("name", sid)),
            "description": localized_effect(ability.get("effect_entries")),
            "effect_id": sid,
            "effect_summary": localized_effect(ability.get("effect_entries")),
            "classification": "DATA_ONLY",
        })
    out.sort(key=lambda x: x["id"])
    return out


def build_items(source: Path) -> list[dict]:
    out: list[dict] = []
    seen: set[str] = set()
    for entry_id in list_ids(source, "item"):
        item = load_ep(source, "item", entry_id)
        sid = slug(str(item.get("name", "")))
        if not sid or sid in seen:
            continue
        seen.add(sid)
        out.append({
            "id": sid,
            "display_name": localized_name(item, item.get("name", sid)),
            "description": localized_effect(item.get("effect_entries")),
            "category": resource_name(item.get("category")) or "misc",
        })
    out.sort(key=lambda x: x["id"])
    return out


def pokemon_index(source: Path, version_ids: dict[str, int]) -> tuple[dict[str, dict], list[dict]]:
    by_name: dict[str, dict] = {}
    selection_report: list[dict] = []
    for entry_id in list_ids(source, "pokemon"):
        pokemon = load_ep(source, "pokemon", entry_id)
        pname = slug(str(pokemon.get("name", "")))
        selected_group, selection_reason = choose_version_group(pokemon, version_ids)
        learnset = build_learnset(pokemon, selected_group)
        stats: dict[str, int] = {}
        effort: dict[str, int] = {}
        stat_key = {
            "hp": "hp", "attack": "attack", "defense": "defense",
            "special-attack": "spatk", "special-defense": "spdef", "speed": "speed",
        }
        effort_key = {
            "hp": "hp", "attack": "attack", "defense": "defense",
            "special-attack": "special_attack", "special-defense": "special_defense", "speed": "speed",
        }
        for stat in pokemon.get("stats", []) or []:
            source_name = str((stat.get("stat") or {}).get("name", ""))
            stats[stat_key.get(source_name, source_name)] = int(stat.get("base_stat") or 0)
            effort[effort_key.get(source_name, source_name)] = int(stat.get("effort") or 0)
        ability_slots: list[dict] = []
        ability_ids: list[str] = []
        for slot in pokemon.get("abilities", []) or []:
            aid = resource_name(slot.get("ability"))
            if not aid:
                continue
            ability_ids.append(aid)
            ability_slots.append({
                "ability_id": aid,
                "slot": int(slot.get("slot") or 0),
                "is_hidden": bool(slot.get("is_hidden", False)),
            })
        types = [
            resource_name(x.get("type"))
            for x in sorted(pokemon.get("types", []) or [], key=lambda x: int(x.get("slot") or 0))
        ]
        types = [t for t in types if t in STANDARD_TYPE_SET]
        by_name[pname] = {
            "types": types,
            "stats": stats,
            "ability_ids": ability_ids,
            "ability_slots": ability_slots,
            "learnset": learnset,
            "learnset_version_group": selected_group,
            "learnset_selection_reason": selection_reason,
            "effort": effort,
            "base_experience": int(pokemon.get("base_experience") or 0),
            "species_name": resource_name(pokemon.get("species")),
        }
        selection_report.append({
            "pokemon": pname,
            "version_group": selected_group,
            "reason": selection_reason,
            "entries": len(learnset),
        })
    return by_name, selection_report


def build_species(source: Path, pokemon_by_name: dict[str, dict], evo_map: dict[str, list[dict]]) -> tuple[list[dict], list[dict], list[dict]]:
    species: list[dict] = []
    forms: list[dict] = []
    anomalies: list[dict] = []
    species_ids = {slug(str(load_ep(source, "pokemon-species", sid).get("name", ""))) for sid in list_ids(source, "pokemon-species")}

    for entry_id in list_ids(source, "pokemon-species"):
        ps = load_ep(source, "pokemon-species", entry_id)
        sid = slug(str(ps.get("name", "")))
        varieties = ps.get("varieties", []) or []
        defaults = [v for v in varieties if v.get("is_default")]
        if len(defaults) != 1:
            anomalies.append({"kind": "default_variety_count", "species": sid, "count": len(defaults)})
        default_variety = defaults[0] if defaults else (varieties[0] if varieties else None)
        default_pokemon_name = resource_name((default_variety or {}).get("pokemon")) if default_variety else sid
        pokemon = pokemon_by_name.get(default_pokemon_name) or pokemon_by_name.get(sid)
        if pokemon is None:
            anomalies.append({"kind": "missing_default_pokemon", "species": sid, "pokemon": default_pokemon_name})
            continue

        for variety in varieties:
            if variety is default_variety:
                continue
            forms.append({
                "species_id": sid,
                "pokemon_id": resource_name(variety.get("pokemon")),
                "is_default": bool(variety.get("is_default", False)),
                "kind": legacy.form_kind(str((variety.get("pokemon") or {}).get("name", ""))),
            })

        st = pokemon["stats"]
        retained_evolutions: list[dict] = []
        for evolution in evo_map.get(sid, []):
            if evolution["species_id"] not in species_ids:
                anomalies.append({"kind": "broken_evolution_target", "species": sid, "target": evolution["species_id"]})
                continue
            retained_evolutions.append(evolution)

        metadata = {
            "source_pokemon_id": default_pokemon_name,
            "learnset_version_group": pokemon["learnset_version_group"],
            "learnset_selection_reason": pokemon["learnset_selection_reason"],
            "generation": resource_name(ps.get("generation")),
            "gender_rate": int(ps.get("gender_rate", -1)),
            "base_happiness": int(ps.get("base_happiness") or 0),
            "is_baby": bool(ps.get("is_baby", False)),
            "is_legendary": bool(ps.get("is_legendary", False)),
            "is_mythical": bool(ps.get("is_mythical", False)),
            "hatch_counter": int(ps.get("hatch_counter") or 0),
            "has_gender_differences": bool(ps.get("has_gender_differences", False)),
            "forms_switchable": bool(ps.get("forms_switchable", False)),
            "egg_groups": [resource_name(g) for g in ps.get("egg_groups", []) or []],
        }
        species.append({
            "id": sid,
            "display_name": localized_name(ps, ps.get("name", sid)),
            "types": pokemon["types"],
            "base_hp": int(st.get("hp", 1)),
            "base_attack": int(st.get("attack", 1)),
            "base_defense": int(st.get("defense", 1)),
            "base_speed": int(st.get("speed", 1)),
            "base_special_attack": int(st.get("spatk", 1)),
            "base_special_defense": int(st.get("spdef", 1)),
            "ability_ids": pokemon["ability_ids"],
            "ability_slots": pokemon["ability_slots"],
            "source_metadata": metadata,
            "base_experience": pokemon["base_experience"],
            "growth_rate": str((ps.get("growth_rate") or {}).get("name", "medium")),
            "ev_yield": pokemon["effort"],
            "capture_rate": int(ps.get("capture_rate") or 0),
            "learnset": pokemon["learnset"],
            "evolutions": retained_evolutions,
        })
    species.sort(key=lambda x: x["id"])
    forms.sort(key=lambda x: (x["species_id"], x["pokemon_id"]))
    return species, forms, anomalies


def build_auxiliary(source: Path, version_ids: dict[str, int]) -> dict:
    natures: list[dict] = []
    for entry_id in list_ids(source, "nature"):
        n = load_ep(source, "nature", entry_id)
        natures.append({
            "id": slug(str(n.get("name", ""))),
            "display_name": localized_name(n, n.get("name", "")),
            "increased_stat": resource_name(n.get("increased_stat")),
            "decreased_stat": resource_name(n.get("decreased_stat")),
        })
    methods: list[dict] = []
    for entry_id in list_ids(source, "move-learn-method"):
        method = load_ep(source, "move-learn-method", entry_id)
        methods.append({
            "id": slug(str(method.get("name", ""))),
            "display_name": localized_name(method, method.get("name", "")),
        })
    return {
        "natures": sorted(natures, key=lambda x: x["id"]),
        "move_learn_methods": sorted(methods, key=lambda x: x["id"]),
        "version_group_ids": dict(sorted(version_ids.items(), key=lambda kv: kv[1])),
        "mainline_version_group_priority": list(MAINLINE_VERSION_GROUP_PRIORITY),
    }


def audit_dataset(raw: dict, forms: list[dict], selection_report: list[dict], anomalies: list[dict]) -> dict:
    species = {s["id"]: s for s in raw.get("species", [])}
    types = {t["id"]: t for t in raw.get("types", [])}
    moves = {m["id"]: m for m in raw.get("moves", [])}
    abilities = {a["id"]: a for a in raw.get("abilities", [])}

    learnset_anomalies: list[dict] = []
    for sid, sp in species.items():
        groups = {e.get("version_group", "") for e in sp.get("learnset", []) if e.get("version_group")}
        exact = Counter((e.get("move_id"), e.get("method"), int(e.get("level", 0)), int(e.get("order", -1))) for e in sp.get("learnset", []))
        duplicates = [list(k) + [count] for k, count in exact.items() if count > 1]
        level_up_counts = Counter(e.get("move_id") for e in sp.get("learnset", []) if e.get("method") == "level_up")
        repeated_level_up = {k: v for k, v in level_up_counts.items() if v > 1}
        if len(groups) > 1 or duplicates or repeated_level_up:
            learnset_anomalies.append({
                "species": sid,
                "version_groups": sorted(groups),
                "exact_duplicates": duplicates,
                "repeated_level_up_moves": repeated_level_up,
            })

    broken: list[str] = []
    for sid, sp in species.items():
        for t in sp.get("types", []):
            if t not in types:
                broken.append(f"{sid}:type:{t}")
        for aid in sp.get("ability_ids", []):
            if aid not in abilities:
                broken.append(f"{sid}:ability:{aid}")
        for entry in sp.get("learnset", []):
            if entry.get("move_id") not in moves:
                broken.append(f"{sid}:move:{entry.get('move_id')}")
        for evo in sp.get("evolutions", []):
            if evo.get("species_id") not in species:
                broken.append(f"{sid}:evolution:{evo.get('species_id')}")

    required_hyphen_species = ("mr_mime", "mime_jr", "ho_oh", "porygon_z", "jangmo_o", "hakamo_o", "kommo_o")
    missing_hyphen_species = [sid for sid in required_hyphen_species if sid not in species]

    sample = {}
    for sid in ("gengar", "pinsir"):
        if sid in species:
            sp = species[sid]
            sample[sid] = {
                "display_name": sp.get("display_name"),
                "learnset_version_group": (sp.get("source_metadata") or {}).get("learnset_version_group", ""),
                "learnset_entries": len(sp.get("learnset", [])),
                "level_up_entries": sum(1 for e in sp.get("learnset", []) if e.get("method") == "level_up"),
                "version_groups": sorted({e.get("version_group", "") for e in sp.get("learnset", []) if e.get("version_group")}),
            }

    return {
        "model": "pokeapi_snapshot_canonical_import_v3",
        "species_total": len(species),
        "forms_total": len(forms),
        "types_total": len(types),
        "moves_total": len(moves),
        "abilities_total": len(abilities),
        "broken_references": broken,
        "missing_standard_types": [t for t in STANDARD_TYPES if t not in types],
        "missing_hyphenated_base_species": missing_hyphen_species,
        "learnset_anomalies": learnset_anomalies,
        "source_anomalies": anomalies,
        "selection_fallbacks": [x for x in selection_report if x["reason"] != "mainline_priority"],
        "samples": sample,
        "checks": {
            "exactly_18_standard_types": set(types) == STANDARD_TYPE_SET,
            "no_broken_references": not broken,
            "hyphenated_base_species_preserved": not missing_hyphen_species,
            "gengar_single_version_group": len(sample.get("gengar", {}).get("version_groups", [])) <= 1,
            "pinsir_single_version_group": len(sample.get("pinsir", {}).get("version_groups", [])) <= 1,
        },
    }


def build(source: Path) -> tuple[dict, dict, dict, dict, dict]:
    if not source.is_dir():
        raise FileNotFoundError(f"PokéAPI snapshot not found: {source}")
    version_ids = load_version_group_ids(source)
    types = build_types(source)
    moves, move_classes, before_classes = build_moves(source)
    abilities = build_abilities(source)
    items = build_items(source)
    statuses = preserve_project_statuses()
    pokemon_by_name, selection_report = pokemon_index(source, version_ids)
    evo_map = build_evolution_map(source)
    species, forms, anomalies = build_species(source, pokemon_by_name, evo_map)

    raw = {
        "types": types,
        "moves": moves,
        "abilities": abilities,
        "items": items,
        "statuses": statuses,
        "species": species,
    }
    manifest = {
        "schema_version": SCHEMA_VERSION,
        "dataset_version": DATASET_VERSION,
        "source": "pokeapi/v2-snapshot",
        "generated_at": "2026-08-31",
        "ruleset": "latest_conventional_mainline_per_species_v1",
        "provenance": {
            "source_name": "PokeAPI v2 snapshot",
            "source_snapshot_commit": SOURCE_SNAPSHOT_COMMIT,
            "source_api_tree": SOURCE_API_TREE,
            "source_schema_tree": SOURCE_SCHEMA_TREE,
            "source_url": SOURCE_URL,
            "license": "BSD 3-Clause (data/POKEAPI_DATA_LICENSE.txt)",
            "learnset_policy": "one latest available conventional main-series version-group per Pokemon",
            "move_values_policy": "current values from snapshot; historical past_values retained in source snapshot",
            "language_priority": list(LANGUAGE_PRIORITY),
        },
    }
    forms_report = {
        "policy": "pokemon-species is canonical; select varieties[].is_default. Non-default varieties are forms and are reported, never inferred from hyphens.",
        "forms_total": len(forms),
        "species_total": len(species),
        "forms": forms,
        "anomalies": anomalies,
    }
    unsupported = {
        "summary": {
            "moves": {k: len(v) for k, v in move_classes.items()},
            "abilities": {"DATA_READY": len(abilities), "RUNTIME_EFFECTS_PARTIAL": len(abilities)},
            "items": {"DATA_READY": len(items), "RUNTIME_EFFECTS_PARTIAL": len(items)},
            "evolutions": {"SOURCE_RECORDS_PRESERVED": sum(len(s.get("evolutions", [])) for s in species)},
        },
        "moves": move_classes,
        "runtime_supported_before": before_classes,
        "notes": [
            "Evolution conditions are preserved even where runtime execution is not implemented yet.",
            "Ability slot/hidden metadata is preserved on species; ability runtime coverage remains explicit and partial.",
            "Learnset version-group is selected before canonicalization; cross-generation unions are forbidden.",
        ],
    }
    audit = audit_dataset(raw, forms, selection_report, anomalies)
    aux = build_auxiliary(source, version_ids)
    return raw, manifest, forms_report, unsupported, {"audit": audit, "auxiliary": aux}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--raw", type=Path, default=DEFAULT_RAW)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--forms", type=Path, default=DEFAULT_FORMS)
    parser.add_argument("--unsupported", type=Path, default=DEFAULT_UNSUPPORTED)
    parser.add_argument("--audit", type=Path, default=DEFAULT_AUDIT)
    parser.add_argument("--aux", type=Path, default=DEFAULT_AUX)
    parser.add_argument("--check-only", action="store_true", help="Build/audit in memory; do not overwrite canonical outputs")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    raw, manifest, forms_report, unsupported, extras = build(args.source.resolve())
    audit = extras["audit"]
    checks = audit["checks"]
    print("DATA V3: species=%d forms=%d types=%d moves=%d abilities=%d" % (
        audit["species_total"], audit["forms_total"], audit["types_total"], audit["moves_total"], audit["abilities_total"],
    ))
    print("DATA V3 samples:", json.dumps(audit["samples"], ensure_ascii=False, sort_keys=True))
    print("DATA V3 checks:", json.dumps(checks, ensure_ascii=False, sort_keys=True))
    if not args.check_only:
        write_json(args.raw, raw)
        write_json(args.manifest, manifest)
        write_json(args.forms, forms_report)
        write_json(args.unsupported, unsupported)
        write_json(args.audit, audit)
        write_json(args.aux, extras["auxiliary"])
    required = (
        checks["exactly_18_standard_types"],
        checks["no_broken_references"],
        checks["hyphenated_base_species_preserved"],
        checks["gengar_single_version_group"],
        checks["pinsir_single_version_group"],
    )
    return 0 if all(required) else 1


if __name__ == "__main__":
    raise SystemExit(main())

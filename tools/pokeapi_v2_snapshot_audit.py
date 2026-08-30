#!/usr/bin/env python3
"""Audit the vendored PokeAPI v2 snapshot without flattening versioned data.

The goal is diagnostic: prove which information the legacy adapter loses and emit a
small JSON report that can drive the next importer. It intentionally reads the whole
snapshot in CI so humans/LLMs do not need to inspect thousands of files manually.
"""
from __future__ import annotations

import json
import os
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
API = ROOT / "data" / "api" / "v2"
SCHEMA = ROOT / "data" / "schema" / "v2"
REPORT = ROOT / "data" / "reports" / "pokeapi_v2_snapshot_audit.json"

STANDARD_TYPES = {
    "normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison",
    "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark",
    "steel", "fairy",
}


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def numeric_ids(endpoint: str) -> list[int]:
    root = API / endpoint
    if not root.is_dir():
        return []
    out = []
    for child in root.iterdir():
        if child.is_dir() and child.name.isdigit() and (child / "index.json").is_file():
            out.append(int(child.name))
    return sorted(out)


def ep(endpoint: str, ident: int) -> dict:
    return load_json(API / endpoint / str(ident) / "index.json")


def localized_name(record: dict, language: str) -> str | None:
    for item in record.get("names") or []:
        if (item.get("language") or {}).get("name") == language:
            return item.get("name")
    return None


def url_id(resource: dict | None) -> int | None:
    if not resource:
        return None
    url = resource.get("url") or ""
    match = re.search(r"/(\d+)/?$", url)
    return int(match.group(1)) if match else None


def analyze_learnsets(pokemon_ids: list[int]) -> dict:
    conflict_pokemon = set()
    conflict_pairs = 0
    within_group_duplicates = 0
    method_counts = Counter()
    version_groups = Counter()
    worst = []
    named = {}

    for pid in pokemon_ids:
        pk = ep("pokemon", pid)
        pname = pk.get("name", str(pid))
        per_move_levels: dict[str, set[int]] = defaultdict(set)
        per_move_groups: dict[str, set[str]] = defaultdict(set)
        within_seen = set()

        for mv in pk.get("moves") or []:
            move_name = (mv.get("move") or {}).get("name", "")
            for detail in mv.get("version_group_details") or []:
                method = ((detail.get("move_learn_method") or {}).get("name") or "")
                group = ((detail.get("version_group") or {}).get("name") or "")
                level = int(detail.get("level_learned_at") or 0)
                method_counts[method] += 1
                version_groups[group] += 1
                signature = (move_name, method, level, group)
                if signature in within_seen:
                    within_group_duplicates += 1
                within_seen.add(signature)
                if method == "level-up":
                    per_move_levels[move_name].add(level)
                    per_move_groups[move_name].add(group)

        local_conflicts = []
        for move_name, levels in per_move_levels.items():
            if len(levels) > 1:
                conflict_pairs += 1
                conflict_pokemon.add(pname)
                local_conflicts.append({
                    "move": move_name,
                    "levels_if_version_is_dropped": sorted(levels),
                    "version_group_count": len(per_move_groups[move_name]),
                })
        if local_conflicts:
            local_conflicts.sort(key=lambda x: (-len(x["levels_if_version_is_dropped"]), x["move"]))
            worst.append({"pokemon": pname, "conflicts": local_conflicts[:8]})
        if pid in (94, 127):
            named[pname] = local_conflicts

    worst.sort(key=lambda x: (-sum(len(c["levels_if_version_is_dropped"]) - 1 for c in x["conflicts"]), x["pokemon"]))
    return {
        "pokemon_with_cross_version_level_conflicts": len(conflict_pokemon),
        "move_level_conflict_pairs": conflict_pairs,
        "within_same_version_group_duplicate_entries": within_group_duplicates,
        "method_entry_counts": dict(method_counts.most_common()),
        "version_group_entry_counts_top20": dict(version_groups.most_common(20)),
        "gengar_and_pinsir": named,
        "worst_examples": worst[:20],
    }


def analyze_species(species_ids: list[int]) -> dict:
    hyphenated = []
    localized_es = 0
    legendary = mythical = baby = 0
    variety_count = 0
    for sid in species_ids:
        sp = ep("pokemon-species", sid)
        name = sp.get("name", "")
        if "-" in name:
            hyphenated.append(name)
        if localized_name(sp, "es"):
            localized_es += 1
        legendary += bool(sp.get("is_legendary"))
        mythical += bool(sp.get("is_mythical"))
        baby += bool(sp.get("is_baby"))
        variety_count += len(sp.get("varieties") or [])
    return {
        "count": len(species_ids),
        "hyphenated_base_species_count": len(hyphenated),
        "hyphenated_base_species_examples": hyphenated[:80],
        "spanish_name_coverage": localized_es,
        "legendary_count": legendary,
        "mythical_count": mythical,
        "baby_count": baby,
        "variety_records": variety_count,
    }


def analyze_pokemon_metadata(pokemon_ids: list[int]) -> dict:
    hidden = 0
    past = 0
    held = 0
    for pid in pokemon_ids:
        pk = ep("pokemon", pid)
        if any(bool(a.get("is_hidden")) for a in pk.get("abilities") or []):
            hidden += 1
        if pk.get("past_abilities"):
            past += 1
        if pk.get("held_items"):
            held += 1
    return {
        "count": len(pokemon_ids),
        "pokemon_with_hidden_ability": hidden,
        "pokemon_with_past_abilities": past,
        "pokemon_with_versioned_wild_held_items": held,
    }


def analyze_moves(move_ids: list[int]) -> dict:
    past_values = 0
    effect_changes = 0
    null_accuracy = 0
    variable_power = 0
    es_names = 0
    es419_names = 0
    generated = []
    for mid in move_ids:
        mv = ep("move", mid)
        if mv.get("past_values"):
            past_values += 1
        if mv.get("effect_changes"):
            effect_changes += 1
        if mv.get("accuracy") is None:
            null_accuracy += 1
        damage_class = ((mv.get("damage_class") or {}).get("name") or "")
        if damage_class in ("physical", "special") and mv.get("power") is None:
            variable_power += 1
            if len(generated) < 30:
                generated.append(mv.get("name"))
        if localized_name(mv, "es"):
            es_names += 1
        if localized_name(mv, "es-419"):
            es419_names += 1
    return {
        "count": len(move_ids),
        "moves_with_past_values": past_values,
        "moves_with_effect_changes": effect_changes,
        "moves_with_null_accuracy": null_accuracy,
        "damaging_moves_with_variable_or_null_power": variable_power,
        "variable_power_examples": generated,
        "spanish_name_coverage_es": es_names,
        "spanish_name_coverage_es_419": es419_names,
    }


def analyze_localized_endpoint(endpoint: str) -> dict:
    ids = numeric_ids(endpoint)
    es = es419 = 0
    for ident in ids:
        rec = ep(endpoint, ident)
        es += bool(localized_name(rec, "es"))
        es419 += bool(localized_name(rec, "es-419"))
    return {"count": len(ids), "spanish_name_coverage_es": es, "spanish_name_coverage_es_419": es419}


def analyze_types() -> dict:
    ids = numeric_ids("type")
    names = []
    standard_present = set()
    past_relations = 0
    for ident in ids:
        rec = ep("type", ident)
        name = rec.get("name", "")
        names.append(name)
        if name in STANDARD_TYPES:
            standard_present.add(name)
        if rec.get("past_damage_relations"):
            past_relations += 1
    return {
        "count": len(ids),
        "names": sorted(names),
        "standard_18_present": sorted(standard_present),
        "missing_standard_types": sorted(STANDARD_TYPES - standard_present),
        "extra_nonstandard_types": sorted(set(names) - STANDARD_TYPES),
        "types_with_past_damage_relations": past_relations,
    }


def walk_evolution_node(node: dict, stats: dict) -> None:
    for child in node.get("evolves_to") or []:
        details = child.get("evolution_details") or []
        stats["edges"] += 1
        if len(details) > 1:
            stats["edges_with_multiple_details"] += 1
        for det in details:
            stats["detail_records"] += 1
            for key in (
                "version_group", "item", "held_item", "known_move", "known_move_type", "location",
                "min_level", "min_happiness", "min_beauty", "min_affection", "near_special_rock",
                "needs_multiplayer", "needs_overworld_rain", "party_species", "party_type",
                "relative_physical_stats", "time_of_day", "trade_species", "turn_upside_down",
                "region", "base_form", "evolved_form", "used_move", "min_move_count", "min_steps",
                "min_damage_taken", "gender",
            ):
                value = det.get(key)
                if value not in (None, False, "", 0):
                    stats["condition_usage"][key] += 1
        walk_evolution_node(child, stats)


def analyze_evolutions() -> dict:
    ids = numeric_ids("evolution-chain")
    stats = {
        "chains": len(ids),
        "edges": 0,
        "edges_with_multiple_details": 0,
        "detail_records": 0,
        "condition_usage": Counter(),
    }
    for ident in ids:
        chain = ep("evolution-chain", ident)
        walk_evolution_node(chain.get("chain") or {}, stats)
    stats["condition_usage"] = dict(stats["condition_usage"].most_common())
    return stats


def endpoint_counts() -> dict:
    out = {}
    if not API.is_dir():
        return out
    for child in sorted(API.iterdir(), key=lambda p: p.name):
        if child.is_dir():
            out[child.name] = len(numeric_ids(child.name))
    return out


def required_schema_status() -> dict:
    required = [
        "pokemon/$id/index.json", "pokemon-species/$id/index.json", "move/$id/index.json",
        "type/$id/index.json", "ability/$id/index.json", "item/$id/index.json",
        "nature/$id/index.json", "evolution-chain/$id/index.json", "version-group/$id/index.json",
        "machine/$id/index.json", "location-area/$id/index.json", "growth-rate/$id/index.json",
    ]
    return {path: (SCHEMA / path).is_file() for path in required}


def main() -> int:
    if not API.is_dir() or not SCHEMA.is_dir():
        raise SystemExit("PokeAPI v2 snapshot trees are missing")

    pokemon_ids = numeric_ids("pokemon")
    species_ids = numeric_ids("pokemon-species")
    move_ids = numeric_ids("move")

    report = {
        "model": "pokeapi_v2_snapshot_audit_v1",
        "api_root": str(API.relative_to(ROOT)),
        "schema_root": str(SCHEMA.relative_to(ROOT)),
        "endpoint_counts": endpoint_counts(),
        "schemas": required_schema_status(),
        "species": analyze_species(species_ids),
        "pokemon": analyze_pokemon_metadata(pokemon_ids),
        "learnsets": analyze_learnsets(pokemon_ids),
        "moves": analyze_moves(move_ids),
        "types": analyze_types(),
        "abilities": analyze_localized_endpoint("ability"),
        "items": analyze_localized_endpoint("item"),
        "natures": analyze_localized_endpoint("nature"),
        "move_learn_methods": analyze_localized_endpoint("move-learn-method"),
        "version_groups": {"count": len(numeric_ids("version-group"))},
        "machines": {"count": len(numeric_ids("machine"))},
        "location_areas": {"count": len(numeric_ids("location-area"))},
        "growth_rates": {"count": len(numeric_ids("growth-rate"))},
        "evolutions": analyze_evolutions(),
    }

    # High-value source assumptions that the new importer may rely on.
    assumptions = {
        "all_required_schemas_present": all(report["schemas"].values()),
        "all_standard_18_types_present": not report["types"]["missing_standard_types"],
        "spanish_move_names_available": report["moves"]["spanish_name_coverage_es"] > 0,
        "version_groups_available": report["version_groups"]["count"] > 1,
        "legacy_flattening_is_demonstrably_unsafe": report["learnsets"]["move_level_conflict_pairs"] > 0,
        "hyphen_is_not_a_valid_form_classifier": report["species"]["hyphenated_base_species_count"] > 0,
    }
    report["assumptions"] = assumptions

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    compact = {
        "endpoints": len(report["endpoint_counts"]),
        "pokemon": report["pokemon"]["count"],
        "species": report["species"]["count"],
        "moves": report["moves"]["count"],
        "version_groups": report["version_groups"]["count"],
        "hyphenated_base_species": report["species"]["hyphenated_base_species_count"],
        "pokemon_with_cross_version_level_conflicts": report["learnsets"]["pokemon_with_cross_version_level_conflicts"],
        "move_level_conflict_pairs": report["learnsets"]["move_level_conflict_pairs"],
        "moves_with_past_values": report["moves"]["moves_with_past_values"],
        "evolution_edges_with_multiple_details": report["evolutions"]["edges_with_multiple_details"],
        "spanish_move_names": report["moves"]["spanish_name_coverage_es"],
    }
    print("POKEAPI_V2_AUDIT_SUMMARY=" + json.dumps(compact, ensure_ascii=False, sort_keys=True))
    print("POKEAPI_V2_AUDIT_ASSUMPTIONS=" + json.dumps(assumptions, sort_keys=True))

    if not all(assumptions.values()):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

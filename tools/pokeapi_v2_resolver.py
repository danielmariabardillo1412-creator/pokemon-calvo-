#!/usr/bin/env python3
"""Version-aware resolver for the vendored PokeAPI V2 snapshot.

This module deliberately does not flatten all historical move data together.  It picks
one coherent version group for each Pokemon under an explicit profile and preserves
which group was selected in every resolved learnset entry.

The first profile, ``modern_unified_v1``, is intended for this fan game's cross-region
world: use the newest standard-mainline learnset available for each Pokemon, with a
clearly reported fallback only when the snapshot has no standard-mainline group.
"""
from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[1]
API_ROOT = ROOT / "data" / "api" / "v2"
DEFAULT_REPORT = ROOT / "data" / "reports" / "pokeapi_v2_resolver_report.json"

# Newest -> oldest. Side-game groups intentionally are not in the preferred list.
# If a Pokemon has no data in any preferred group, the resolver may use a marked
# fallback instead of silently dropping that Pokemon.
MODERN_MAINLINE_PRIORITY: tuple[str, ...] = (
    "scarlet-violet",
    "brilliant-diamond-and-shining-pearl",
    "sword-shield",
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

# Known non-standard groups are allowed only as provenance-marked last resort.
# Unknown future groups are not automatically considered "standard".
NONSTANDARD_GROUPS: frozenset[str] = frozenset({
    "colosseum",
    "xd",
    "lets-go-pikachu-lets-go-eevee",
    "legends-arceus",
})


@dataclass(frozen=True)
class ResolvedLearnset:
    pokemon_id: int
    pokemon_name: str
    version_group: str
    selection_reason: str
    entries: tuple[dict[str, Any], ...]


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def endpoint_record(endpoint: str, ident: int) -> dict[str, Any]:
    return load_json(API_ROOT / endpoint / str(ident) / "index.json")


def numeric_endpoint_ids(endpoint: str) -> list[int]:
    root = API_ROOT / endpoint
    if not root.is_dir():
        return []
    return sorted(
        int(child.name)
        for child in root.iterdir()
        if child.is_dir() and child.name.isdigit() and (child / "index.json").is_file()
    )


def resource_id(resource: dict[str, Any] | None) -> int | None:
    if not resource:
        return None
    match = re.search(r"/(\d+)/?$", str(resource.get("url") or ""))
    return int(match.group(1)) if match else None


def localized_name(record: dict[str, Any], language: str = "es") -> str:
    for item in record.get("names") or []:
        if ((item.get("language") or {}).get("name") or "") == language:
            name = str(item.get("name") or "").strip()
            if name:
                return name
    return str(record.get("name") or "")


def normalize_learn_method(method: str) -> str:
    # Existing Godot domain uses level_up rather than PokeAPI's level-up.
    return method.strip().replace("-", "_")


def version_groups_in_pokemon(pokemon: dict[str, Any]) -> set[str]:
    groups: set[str] = set()
    for move_record in pokemon.get("moves") or []:
        for detail in move_record.get("version_group_details") or []:
            group = str(((detail.get("version_group") or {}).get("name") or "")).strip()
            if group:
                groups.add(group)
    return groups


def _group_rank_from_snapshot() -> dict[str, tuple[int, int]]:
    """Return group -> (generation_number, endpoint_id), both ascending historically."""
    generation_number_by_url: dict[str, int] = {}
    for generation_id in numeric_endpoint_ids("generation"):
        generation = endpoint_record("generation", generation_id)
        generation_number_by_url[str(generation.get("url") or "")] = generation_id

    rank: dict[str, tuple[int, int]] = {}
    for group_id in numeric_endpoint_ids("version-group"):
        group = endpoint_record("version-group", group_id)
        name = str(group.get("name") or "")
        generation = group.get("generation") or {}
        generation_url = str(generation.get("url") or "")
        generation_id = resource_id(generation) or generation_number_by_url.get(generation_url, 0)
        rank[name] = (int(generation_id or 0), group_id)
    return rank


def choose_version_group(
    available_groups: Iterable[str],
    profile: str = "modern_unified_v1",
    group_rank: dict[str, tuple[int, int]] | None = None,
) -> tuple[str, str]:
    groups = {str(group) for group in available_groups if str(group)}
    if not groups:
        return "", "no_versioned_move_data"
    if profile != "modern_unified_v1":
        raise ValueError(f"Unsupported PokeAPI resolver profile: {profile}")

    for group in MODERN_MAINLINE_PRIORITY:
        if group in groups:
            return group, "preferred_mainline"

    # Do not guess that an unknown group is normal mainline. Pick the latest source
    # record only as an explicit fallback and report that decision to downstream QA.
    rank = group_rank or _group_rank_from_snapshot()
    chosen = max(groups, key=lambda name: rank.get(name, (0, 0)))
    reason = "fallback_nonstandard" if chosen in NONSTANDARD_GROUPS else "fallback_unclassified"
    return chosen, reason


def resolve_learnset(
    pokemon: dict[str, Any],
    profile: str = "modern_unified_v1",
    group_rank: dict[str, tuple[int, int]] | None = None,
) -> ResolvedLearnset:
    pokemon_id = int(pokemon.get("id") or 0)
    pokemon_name = str(pokemon.get("name") or pokemon_id)
    selected_group, selection_reason = choose_version_group(
        version_groups_in_pokemon(pokemon), profile, group_rank
    )

    entries: list[dict[str, Any]] = []
    seen: set[tuple[str, str, int, int, str]] = set()
    if selected_group:
        for move_record in pokemon.get("moves") or []:
            move_name = str(((move_record.get("move") or {}).get("name") or "")).strip()
            if not move_name:
                continue
            move_id = resource_id(move_record.get("move"))
            for detail in move_record.get("version_group_details") or []:
                group = str(((detail.get("version_group") or {}).get("name") or "")).strip()
                if group != selected_group:
                    continue
                raw_method = str(((detail.get("move_learn_method") or {}).get("name") or "")).strip()
                method = normalize_learn_method(raw_method)
                level = int(detail.get("level_learned_at") or 0)
                raw_order = detail.get("order")
                order = int(raw_order) if raw_order is not None else -1
                signature = (move_name, method, level, order, selected_group)
                if signature in seen:
                    continue
                seen.add(signature)
                entries.append({
                    "move_id": move_name,
                    "source_move_id": move_id,
                    "method": method,
                    "level": level,
                    "version_group_id": selected_group,
                    "order": order,
                })

    # Stable ordering makes generated data reproducible. PokeAPI order is meaningful
    # when supplied; otherwise method/level/move ID provide deterministic fallback.
    entries.sort(key=lambda item: (
        1 if int(item["order"]) < 0 else 0,
        int(item["order"]) if int(item["order"]) >= 0 else 10**9,
        str(item["method"]),
        int(item["level"]),
        str(item["move_id"]),
    ))
    return ResolvedLearnset(
        pokemon_id=pokemon_id,
        pokemon_name=pokemon_name,
        version_group=selected_group,
        selection_reason=selection_reason,
        entries=tuple(entries),
    )


def default_pokemon_for_species(species: dict[str, Any]) -> tuple[int | None, str]:
    defaults = [
        variety for variety in (species.get("varieties") or [])
        if bool(variety.get("is_default"))
    ]
    if len(defaults) != 1:
        return None, f"expected_one_default_variety_got_{len(defaults)}"
    pokemon = defaults[0].get("pokemon") or {}
    return resource_id(pokemon), "default_variety"


def build_resolution_report(profile: str = "modern_unified_v1") -> dict[str, Any]:
    group_rank = _group_rank_from_snapshot()
    species_ids = numeric_endpoint_ids("pokemon-species")

    resolved_count = 0
    no_default: list[str] = []
    no_group: list[str] = []
    fallback: list[dict[str, str]] = []
    incoherent: list[str] = []
    duplicate_exact = 0
    spanish_species_names = 0
    hyphenated_retained: list[str] = []
    samples: dict[str, Any] = {}

    for species_id in species_ids:
        species = endpoint_record("pokemon-species", species_id)
        species_name = str(species.get("name") or species_id)
        display_name = localized_name(species, "es")
        if display_name and display_name != species_name:
            spanish_species_names += 1
        if "-" in species_name:
            hyphenated_retained.append(species_name)

        pokemon_id, reason = default_pokemon_for_species(species)
        if pokemon_id is None:
            no_default.append(species_name)
            continue
        pokemon = endpoint_record("pokemon", pokemon_id)
        resolved = resolve_learnset(pokemon, profile, group_rank)
        if not resolved.version_group:
            no_group.append(species_name)
        if resolved.selection_reason.startswith("fallback_"):
            fallback.append({
                "species": species_name,
                "pokemon": resolved.pokemon_name,
                "version_group": resolved.version_group,
                "reason": resolved.selection_reason,
            })

        groups = {str(entry["version_group_id"]) for entry in resolved.entries}
        if len(groups) > 1:
            incoherent.append(species_name)
        signatures = [
            (
                str(entry["move_id"]), str(entry["method"]), int(entry["level"]),
                int(entry["order"]), str(entry["version_group_id"]),
            )
            for entry in resolved.entries
        ]
        duplicate_exact += len(signatures) - len(set(signatures))
        resolved_count += 1

        if species_name in {"gengar", "pinsir"}:
            level_entries = [entry for entry in resolved.entries if entry["method"] == "level_up"]
            by_move: dict[str, list[int]] = {}
            for entry in level_entries:
                by_move.setdefault(str(entry["move_id"]), []).append(int(entry["level"]))
            samples[species_name] = {
                "pokemon_id": pokemon_id,
                "selected_version_group": resolved.version_group,
                "selection_reason": resolved.selection_reason,
                "level_up_entry_count": len(level_entries),
                "level_up_levels_by_move": by_move,
            }

    return {
        "model": "pokeapi_v2_versioned_resolver_report_v1",
        "profile": profile,
        "species_total": len(species_ids),
        "species_resolved": resolved_count,
        "species_without_single_default_variety": no_default,
        "species_without_versioned_move_data": no_group,
        "fallback_species": fallback,
        "resolved_learnsets_with_multiple_version_groups": incoherent,
        "duplicate_exact_entries_after_resolution": duplicate_exact,
        "spanish_species_name_coverage": spanish_species_names,
        "hyphenated_base_species_retained": hyphenated_retained,
        "samples": samples,
        "preferred_mainline_priority": list(MODERN_MAINLINE_PRIORITY),
    }


def validate_report(report: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if report.get("species_total") != 1025:
        errors.append(f"expected 1025 species, got {report.get('species_total')}")
    if report.get("species_resolved") != report.get("species_total"):
        errors.append("not every species resolved through its default Pokemon variety")
    if report.get("species_without_single_default_variety"):
        errors.append("some species do not have exactly one default variety")
    if report.get("resolved_learnsets_with_multiple_version_groups"):
        errors.append("at least one resolved learnset mixes version groups")
    if int(report.get("duplicate_exact_entries_after_resolution") or 0) != 0:
        errors.append("exact duplicate learnset entries survived resolution")
    retained = set(report.get("hyphenated_base_species_retained") or [])
    for expected in ("mr-mime", "ho-oh", "porygon-z", "type-null", "jangmo-o"):
        if expected not in retained:
            errors.append(f"hyphenated base species missing: {expected}")
    for sample in ("gengar", "pinsir"):
        data = (report.get("samples") or {}).get(sample) or {}
        if not data.get("selected_version_group"):
            errors.append(f"{sample} has no selected version group")
        levels_by_move = data.get("level_up_levels_by_move") or {}
        # The same move may legitimately appear more than once within one game, but the
        # old failure was a large cross-version pile-up. Guard specifically against that.
        if any(len(levels) > 3 for levels in levels_by_move.values()):
            errors.append(f"{sample} still has implausible repeated level-up entries")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--profile", default="modern_unified_v1")
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    args = parser.parse_args()

    report = build_resolution_report(args.profile)
    errors = validate_report(report)
    report["validation_errors"] = errors
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(
        json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    summary = {
        "species_total": report["species_total"],
        "species_resolved": report["species_resolved"],
        "hyphenated_retained": len(report["hyphenated_base_species_retained"]),
        "fallback_species": len(report["fallback_species"]),
        "no_versioned_moves": len(report["species_without_versioned_move_data"]),
        "mixed_version_learnsets": len(report["resolved_learnsets_with_multiple_version_groups"]),
        "exact_duplicates": report["duplicate_exact_entries_after_resolution"],
        "gengar_group": report["samples"].get("gengar", {}).get("selected_version_group", ""),
        "pinsir_group": report["samples"].get("pinsir", {}).get("selected_version_group", ""),
        "errors": len(errors),
    }
    print("POKEAPI_V2_RESOLVER_SUMMARY=" + json.dumps(summary, ensure_ascii=False, sort_keys=True))
    if errors:
        print("POKEAPI_V2_RESOLVER_ERRORS=" + json.dumps(errors, ensure_ascii=False))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

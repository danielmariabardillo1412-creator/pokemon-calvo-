#!/usr/bin/env python3
"""Move Effects V3 audit for selected-target moves with missing stateful mechanics.

This layer is intentionally narrow. It validates immutable PokéAPI source records
and the legacy-generated stat effects before deciding whether the current Battle
Core can safely execute a faithful subset.
"""
from __future__ import annotations

from typing import Any


def _slug_stat(name: str) -> str:
    return str(name).replace("-", "_")


def _source_stats(move: dict) -> dict[str, int]:
    result: dict[str, int] = {}
    for change in move.get("stat_changes") or []:
        stat_name = (change.get("stat") or {}).get("name")
        if stat_name:
            result[_slug_stat(stat_name)] = int(change.get("change", 0))
    return result


def _generated_stats(specs: list[dict]) -> dict[str, int]:
    result: dict[str, int] = {}
    for spec in specs:
        if spec.get("kind") != "modify_stat_stage":
            raise RuntimeError(f"DATA V3 selected-stateful generated non-stat effect: {spec}")
        if spec.get("target") != "opponent" or int(spec.get("chance_basis_points", 0)) != 10000:
            raise RuntimeError(f"DATA V3 selected-stateful generated wrong stat shape: {spec}")
        result[str(spec.get("stat_id", ""))] = int(spec.get("value", 0))
    return result


def _english_effect_text(move: dict) -> str:
    parts: list[str] = []
    for entry in move.get("effect_entries") or []:
        if (entry.get("language") or {}).get("name") == "en":
            parts.append(str(entry.get("effect") or ""))
            parts.append(str(entry.get("short_effect") or ""))
    return " ".join(parts).lower()


def _require_common(
    move: dict,
    specs: list[dict],
    sid: str,
    expected_accuracy: int | None,
    expected_stats: dict[str, int],
) -> None:
    if (move.get("target") or {}).get("name") != "selected-pokemon":
        raise RuntimeError(f"DATA V3 selected-stateful target changed for {sid}")
    if (move.get("damage_class") or {}).get("name") != "status":
        raise RuntimeError(f"DATA V3 selected-stateful damage class changed for {sid}")
    if move.get("accuracy") != expected_accuracy or int(move.get("priority") or 0) != 0:
        raise RuntimeError(f"DATA V3 selected-stateful accuracy/priority changed for {sid}")
    if move.get("effect_changes"):
        raise RuntimeError(f"DATA V3 selected-stateful effect history changed for {sid}")
    if _source_stats(move) != expected_stats:
        raise RuntimeError(
            f"DATA V3 selected-stateful source stats changed for {sid}: {_source_stats(move)}"
        )
    if len(specs) != len(expected_stats) or _generated_stats(specs) != expected_stats:
        raise RuntimeError(
            f"DATA V3 selected-stateful generated stats changed for {sid}: {specs}"
        )


def apply_selected_stateful(
    move: dict,
    generated: tuple[list[dict], int, bool, str, int, Any],
) -> tuple[list[dict], int, bool, str, int, Any]:
    specs, crit_rate_bp, makes_contact, coverage, override_count, unsupported_note = generated
    sid = str(move.get("name", "")).replace("-", "_")

    if sid == "defog":
        _require_common(move, specs, sid, None, {"evasion": -1})
        meta = move.get("meta") or {}
        text = _english_effect_text(move)
        if (
            (meta.get("category") or {}).get("name") != "unique"
            or (meta.get("ailment") or {}).get("name") not in ("none", "", None)
            or "lowers the target’s evasion by one stage" not in text
            or "removes field effects" not in text
        ):
            raise RuntimeError("DATA V3 Defog source semantics changed")
        # Modern Defog's field cleanup is integral and can affect hazards on both
        # sides. Keeping only the evasion drop can remove a strategic drawback and
        # create a stronger fake move, so no executable subset is exposed yet.
        specs = []
        coverage = "DATA_ONLY"

    elif sid == "memento":
        _require_common(
            move,
            specs,
            sid,
            100,
            {"attack": -2, "special_attack": -2},
        )
        text = _english_effect_text(move)
        if "user faints" not in text:
            raise RuntimeError("DATA V3 Memento self-faint semantics changed")
        # The stat drops are inseparable from the user's mandatory faint. Exposing
        # them alone would grant a free -2/-2 debuff, which is strategically false.
        specs = []
        coverage = "DATA_ONLY"

    elif sid == "parting_shot":
        _require_common(
            move,
            specs,
            sid,
            100,
            {"attack": -1, "special_attack": -1},
        )
        text = _english_effect_text(move)
        if "makes the user switch out" not in text:
            raise RuntimeError("DATA V3 Parting Shot switch semantics changed")
        # The switch is part of the move transaction. A repeatable -1/-1 while the
        # user remains active is a different and potentially stronger move.
        specs = []
        coverage = "DATA_ONLY"

    elif sid == "tar_shot":
        _require_common(move, specs, sid, 100, {"speed": -1})
        meta = move.get("meta") or {}
        text = _english_effect_text(move)
        if (
            (meta.get("ailment") or {}).get("name") != "tar-shot"
            or int(meta.get("ailment_chance") or 0) != 100
            or int(meta.get("stat_chance") or 0) != 100
            or "effectiveness of fire-type moves is doubled" not in text
        ):
            raise RuntimeError("DATA V3 Tar Shot fire-vulnerability semantics changed")
        # Speed -1 is independently faithful. The persistent Fire vulnerability is
        # not representable yet, so retain the safe weaker subset explicitly.
        coverage = "PARTIAL_RUNTIME"

    return (
        specs,
        crit_rate_bp,
        makes_contact,
        coverage,
        override_count,
        unsupported_note,
    )

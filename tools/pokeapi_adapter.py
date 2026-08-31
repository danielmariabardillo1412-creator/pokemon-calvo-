#!/usr/bin/env python3
"""Compatibility shim for DATA FOUNDATION V3 legacy move-effect helpers.

This module is intentionally NOT a runnable PokéAPI adapter. The obsolete V2
adapter lives in ``tools/archive/pokeapi_adapter_v2_legacy.py`` for provenance.
``pokeapi_adapter_v3.py`` still imports the historical module name while reusing
its mature move-effect conversion helpers, so this shim forwards attribute access
to the archived implementation without restoring V2 as a canonical pipeline.

The shim also contains the narrowly scoped compatibility corrections required
because the archived implementation predates DATA V3's normalized IDs and the
repository reorganization. The archived source itself remains untouched.
"""
from __future__ import annotations

import json
from pathlib import Path

from archive import pokeapi_adapter_v2_legacy as _legacy


_CONTACT_OVERRIDE = Path(__file__).with_name("move_flags_override.json")
_REQUIRED_CONTACT_SENTINELS = {"tackle", "thunder_punch"}
_REQUIRED_UNSUPPORTED_NORMALIZED = {
    "sleep_talk",
    "me_first",
    "mirror_move",
    "nature_power",
}

# The V2 list mixes raw PokéAPI hyphenated names with the underscore-normalized
# IDs used by the adapter. Normalize it once for the archived helper functions.
# ``astonish`` was an old placeholder: its damage + flinch effect is fully
# representable by generate_move_specs(), so keeping it unsupported is incorrect.
_legacy.UNSUPPORTED_MOVE_NAMES = {
    _legacy.slug(name) for name in _legacy.UNSUPPORTED_MOVE_NAMES
}
_legacy.UNSUPPORTED_MOVE_NAMES.discard("astonish")

if not _REQUIRED_UNSUPPORTED_NORMALIZED.issubset(_legacy.UNSUPPORTED_MOVE_NAMES):
    raise RuntimeError("DATA V3 legacy unsupported-move normalization failed")
if "astonish" in _legacy.UNSUPPORTED_MOVE_NAMES:
    raise RuntimeError("DATA V3 legacy Astonish placeholder was not removed")


def _load_contact_override() -> set[str]:
    if not _CONTACT_OVERRIDE.is_file():
        raise FileNotFoundError(
            f"DATA V3 contact override missing: {_CONTACT_OVERRIDE}"
        )
    try:
        data = json.loads(_CONTACT_OVERRIDE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(
            f"DATA V3 contact override is unreadable: {_CONTACT_OVERRIDE}"
        ) from exc

    contact = set(data.get("contact", []))
    missing = sorted(_REQUIRED_CONTACT_SENTINELS - contact)
    if missing:
        raise RuntimeError(
            "DATA V3 contact override lost required sentinels: %s"
            % ", ".join(missing)
        )
    return contact


def __getattr__(name: str):
    return getattr(_legacy, name)

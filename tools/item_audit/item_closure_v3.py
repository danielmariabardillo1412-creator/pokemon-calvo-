#!/usr/bin/env python3
"""Inventario V3 no destructivo: catálogo actual + estado V27 + contexto histórico.

No declara una mecánica probada por el mero hecho de tener descriptor o icono.
Ejecutar: python -B tools/item_audit/item_closure_v3.py
"""
from __future__ import annotations
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / ".godot/item_closure_v3/inventory.json"
DATA = "data/normalized/pokemon_api.json"
POLICY = "config/item_selection_v1.json"
CONNECTIONS = "modules/inventory/item_connections_v1.json"
STATUS = "docs/current/ITEM_SYSTEM_CURRENT_STATUS.json"
HISTORY = "docs/opencode/ITEM_CLOSURE_V2/COVERAGE.json"
POWER = {"macho_brace", "power_weight", "power_bracer", "power_belt",
         "power_lens", "power_band", "power_anklet"}
MISSING = {"amulet_coin": "ECONOMY", "luck_incense": "ECONOMY", "exp_share": "XP_EV_RECIPIENT_PROFILE"}


def read(p: str) -> dict:
    return json.loads((ROOT / p).read_text(encoding="utf-8-sig"))


def digest(p: str) -> str:
    return hashlib.sha256((ROOT / p).read_bytes()).hexdigest()


def validate_runtime_evidence() -> dict:
    """Reject invalid, unexercised or missing V3 runtime evidence."""
    native = json.loads((ROOT / ".godot/item_verification_v3/native.json").read_text())
    mirror = json.loads((ROOT / ".godot/item_verification_v3/godot.json").read_text())
    ev = json.loads((ROOT / ".godot/item_closure_v3/godot.json").read_text())
    nr, gr = native["results"], mirror["results"]
    assert len(nr) == len(gr) == 908
    assert all(row["status"] == "NATIVE_SCENARIO_PASS" for row in nr)
    assert all(row["status"] == "PASS" for row in native["branchChecks"])
    assert mirror["status"] == "PASS_WITH_EXPLICIT_PENDING"
    assert mirror["pending_protocol_cases"] == 0 and mirror["checks"] >= 20000
    assert not mirror["errors"] and all(row["status"].endswith("_PASS") for row in gr)
    live = {row["id"] for row in gr if row.get("live_ipc", False)}
    item_ids = {row["id"] for row in nr}
    assert len(item_ids) == len(live) == 65 and item_ids == live
    assert ev["status"] == "PASS" and ev["checks"] >= 94 and not ev["errors"]
    route_types = {row["family"] for row in ev["routes"]}
    assert {"EV_DOMAIN", "EV_NATIVE", "EV_NEXT_BATTLE", "EV_MAP_BAG_SAVE"} <= route_types
    by_id = {}
    for row in nr:
        by_id.setdefault(row["id"], []).append(row["case_id"])
    return {"native_ids": item_ids, "native_cases": by_id,
            "ev_checks": ev["checks"], "mirror_checks": mirror["checks"]}


def generate(with_evidence: bool = False) -> dict:
    evidence = validate_runtime_evidence() if with_evidence else None
    canonical = read(DATA)["items"]
    policy, connections, status = read(POLICY), read(CONNECTIONS), read(STATUS)
    historical = {r["id"]: r for r in read(HISTORY)["rows"]}
    excluded = {
        i for i, row in canonical.items()
        if i in policy["excluded_ids"] or row.get("category") in policy["excluded_categories"]
    }
    held = set(connections["holdable_ids"]) - excluded
    native_missing = set(status["native_missing_permitted_equipped_ids"])
    assert len(canonical) == 2222 and len(excluded) == 44
    assert len(held) == status["trade_item_restoration_v27"]["permitted_holdable_ids"] == 624
    assert len(held - native_missing) == status["native_known_permitted_equipped_ids"] == 621
    assert native_missing == set(MISSING)
    assert set(historical) == set(canonical)
    rows = []
    for item_id, item in sorted(canonical.items()):
        old = historical[item_id]
        allowed = item_id not in excluded
        can_hold = item_id in held
        special = MISSING.get(item_id)
        context = {
            "field": old["field_use"],
            "battle": old["battle_use"],
            "evolution": old["evolution"],
            "machine": old["machine"],
            "scenario": old["scenario"],
        }
        if not allowed:
            current = "EXCLUDED"
        elif item_id in POWER:
            current = "IMPLEMENTED_UNVERIFIED_AT_V3_CHECKPOINT"
        elif special:
            current = "DEPENDENCY_MISSING"
        else:
            current = "LEGACY_CONTEXT_REVALIDATION_REQUIRED"
        if evidence and item_id in evidence["native_ids"]:
            current = "NATIVE_GODOT_LIVE_IPC_SCENARIOS_VERIFIED_BOUNDED"
        if evidence and item_id in POWER:
            current = ("EV_NATIVE_FIELD_BAG_PERSISTENCE_VERIFIED" if item_id == "power_weight"
                       else "EV_DOMAIN_VERIFIED")
        rows.append({
            "id": item_id, "family": old["family"], "category": item.get("category", ""),
            "definition_present": True, "excluded": not allowed,
            "exclusion_reason": policy["excluded_ids"].get(item_id) or policy["excluded_categories"].get(item.get("category"), ""),
            "equip_permitted": can_hold,
            "native_descriptor_v27_documented": can_hold and item_id not in native_missing,
            "native_descriptor_retested_at_v3": False,
            "effect_current_status": current,
            "connection": "PROGRESSION_RECONCILIATION" if item_id in POWER else "REVIEW_EXISTING_CONTEXT",
            "scenario_executed_at_v3": bool(evidence and (item_id in evidence["native_ids"] or item_id in POWER)),
            "scenario_ids_executed_at_v3": evidence["native_cases"].get(item_id, []) if evidence else [],
            "observed_contexts_v3": (
                (["native_engine", "godot_adapter", "real_ipc"] if item_id in evidence["native_ids"] else []) +
                (["ev_domain"] if item_id in POWER else []) +
                (["ev_native", "real_bag", "field_save_load", "next_battle"] if item_id == "power_weight" else [])
            ) if evidence else [],
            "dependency": special or old.get("dependency", ""),
            "historical_snapshot": {
                "context": context, "overall": old["overall"],
                "source": HISTORY, "not_current_assertion": True,
            },
        })
    return {
        "schema_version": 1,
        "status": "SCOPED_EFFECT_EVIDENCE_VALIDATED" if evidence else "INVENTORIED_NOT_EFFECT_CERTIFIED",
        "generation_profile": "Gen VII-IX EV (with legacy Macho Brace)",
        "base_status_source": STATUS,
        "counts": {
            "canonical": len(rows), "excluded": len(excluded), "permitted_held": len(held),
            "native_present_documented": len(held - native_missing),
            "native_missing_documented": len(native_missing),
            "v3_effects_implemented_unverified": len(POWER),
            "v3_scenarios_executed": 908 if evidence else 0,
            "v3_native_item_ids_live_ipc": len(evidence["native_ids"]) if evidence else 0,
            "v3_ev_item_ids_domain": len(POWER) if evidence else 0,
            "v3_ev_native_and_bag_ids": 1 if evidence else 0,
            "v3_mirror_checks": evidence["mirror_checks"] if evidence else 0,
            "v3_ev_checks": evidence["ev_checks"] if evidence else 0,
            "v3_effect_item_ids_with_proof": sum(row["scenario_executed_at_v3"] for row in rows),
            "family_counts": dict(sorted(Counter(x["family"] for x in rows).items())),
            "current_states": dict(sorted(Counter(x["effect_current_status"] for x in rows).items())),
        },
        "explicit_missing_native": sorted(native_missing),
        "all_item_effects_certified": False,
        "sources_sha256": {p: digest(p) for p in (DATA, POLICY, CONNECTIONS, STATUS, HISTORY)},
        "limits": ["V2 result statuses are historical; no carry-forward as fresh PASS",
                   "V27 descriptor presence is documented; requires independent native runtime probe",
                   "Item art, definition or native metadata never certifies effects",
                   "EV family changes only progression; family integration requires Godot CI",
                   "The remaining 2215 IDs have not gained certification from this census"],
        "rows": rows,
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--output", type=Path, default=OUT)
    p.add_argument("--with-evidence", action="store_true", help="Require new PASS from V3 native, IPC and EV runtime tests")
    args = p.parse_args()
    data = generate(with_evidence=args.with_evidence)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("ITEM_CLOSURE_V3_INVENTORY", json.dumps(
        {k: v for k, v in data["counts"].items() if not isinstance(v, dict)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

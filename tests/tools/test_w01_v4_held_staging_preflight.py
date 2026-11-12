#!/usr/bin/env python3
"""W01 staging V4: non-invasive held native invariants and IA6 policy boundary."""
import hashlib, json, pathlib
R=pathlib.Path(__file__).resolve().parents[2]
def blob_sha(p):
 b=(R/p).read_bytes()
 return hashlib.sha1(b"blob "+str(len(b)).encode()+b"\0"+b).hexdigest()
expected={
 "modules/battle/backends/showdown/native_engine.cjs":"073e5c8523f47a477735b98a766437392c201e33",
 "modules/inventory/item_connections_v1.json":"0525b37021edfc2e74c4fc2cb96e62f6f5b3e261",
 "config/item_selection_v1.json":"bf76a361b30e158f613f31ef275006862562cea8"
}
for path,sha in expected.items():
 assert blob_sha(path)==sha,(path,"source/staging production blob diverged; audit before any copy")
cfg=json.loads((R/"config/item_selection_v1.json").read_text(encoding="utf-8"))
assert "dynamax_candy" in cfg["excluded_ids"]
assert "rare_candy" not in cfg["excluded_ids"]
catalog=json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
for held in ("leftovers","choice_band","sitrus_berry","black_sludge","eviolite","draco_plate","dread_plate","zap_plate"):
 assert held in catalog["holdable_ids"],held
print("W01_V4_STAGE_PREFLIGHT PASS held_engine_same=1 policy_same=1 held_catalog_same=1 selected_held=8")

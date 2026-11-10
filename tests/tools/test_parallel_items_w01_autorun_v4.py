#!/usr/bin/env python3
"""W01 TANDA04 preflight: canonical policy, inherited source, and pilot contract.
Never counts runtime tests as passed; CI must execute native + Godot separately.
"""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/parallel_items/w01_autorun_v4.json"
PROGRESS = ROOT / "docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V4_PROGRESS.csv"
IDS = ["leftovers","life_orb","choice_band","choice_specs","choice_scarf","shell_bell","eviolite","safety_goggles","black_sludge","sitrus_berry"]
checks = 0

def check(condition, message):
    global checks
    checks += 1
    if not condition:
        raise AssertionError(message)

def csv_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))

def main():
    f = json.loads(FIXTURE.read_text(encoding="utf-8"))
    check(f["schema_version"] == 1 and f["worker"] == "W01" and f["tanda"] == "04"
        and f["kind"] == "AUTORUN_V4_W01_COMPETITIVE_HELD"
        and f["format"] == "gen9calvounifiedv1", "fixture identity")
    check([(r["row"],r["id"]) for r in f["items"]] ==
        [(f"{i:02d}",id) for i,id in enumerate(IDS,1)], "exact 10 rows ordered")
    check(f["stage01"] == {
        "id":"leftovers","variants":["active","none","reserve","full"],
        "mechanic":"end_turn_1_of_16_if_hp_missing","seed":19,
        "move":"reflect","finisher":"tackle"}, "leftovers positive and three controls")
    check(f["replacements"] == ["adrenaline_orb","absorb_bulb","rowap_berry"],
        "only three substitute candidates")
    scope = {r["id"]:r for r in csv_rows(ROOT/"docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
    inventory = {r["id"]:r for r in csv_rows(ROOT/"docs/current/ITEM_INVENTORY.csv")}
    connections = json.loads((ROOT/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
    allowed = set(connections["holdable_ids"])
    for id in IDS:
        check(scope[id]["estado_contenido"] == "SELECCIONADO",
            "item not selected by effective policy " + id)
        check(id in allowed and inventory[id]["native_entry"] == "True"
              and inventory[id]["native_hooks"],
            "native held integration absent " + id)
    p = csv_rows(PROGRESS)
    check(len(p) == 10 and [(r["fila"],r["id"]) for r in p] ==
        [(f"{i:02d}",id) for i,id in enumerate(IDS,1)], "CSV row identities")
    check(all(r["estado"] in
        {"PENDIENTE","EN_CI_AUTOMATICA","CERTIFICADO","YA_CERTIFICADO",
         "BLOQUEADO","PARCIAL","NO_APLICA"} for r in p), "CSV statuses must remain auditable")
    check(all(r["objetos_nuevos"] == "0" for r in p),
        "do not claim new effect until it is actually certified")
    gd = (ROOT/"tests/gameplay/parallel_items_w01_autorun_v4_leftovers.gd").read_text(encoding="utf-8")
    node = (ROOT/"tests/tools/repro_w01_autorun_v4_leftovers_native.cjs").read_text(encoding="utf-8")
    for marker in ("ItemService.new()", "service.equip(", "FieldSession.new(",
                   "settle_finished_battle", "_roundtrip(", "leftovers", "W01_V4_L3_ROW PASS"):
        check(marker in gd, "missing real L3 integration proof code: "+marker)
    for marker in ("NativeEngine","checkpoint","prepare","commit","leftovers","W01_V4_NATIVE PASS"):
        check(marker in node, "missing native test infrastructure: "+marker)
    print(f"W01_V4_PY PASS rows=10 stage=leftovers checks={checks}")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""W01 AUTORUN V1: 10 independent gems, real engine contract and provenance."""
from __future__ import annotations

import csv
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V1_PROGRESS.csv"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w01_autorun_v1.json"
INVENTORY = ROOT / "docs/current/ITEM_INVENTORY.csv"
SCOPE = ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
HISTORY = ROOT / "docs/coordination/items_parallel_v1/reports/W01/CAMP_005_PROGRESO.csv"
GODOT = ROOT / "tests/gameplay/parallel_items_w01_autorun_v1.gd"
NATIVE = ROOT / "tests/tools/repro_w01_autorun_v1_native.cjs"
EXPECTED = [
    ("electric_gem","electric","thunderbolt","tackle","thunder_wave"),
    ("grass_gem","grass","energy_ball","tackle","grassy_terrain"),
    ("ice_gem","ice","ice_beam","tackle","haze"),
    ("fighting_gem","fighting","brick_break","tackle","bulk_up"),
    ("poison_gem","poison","sludge_bomb","tackle","toxic_spikes"),
    ("ground_gem","ground","earth_power","tackle","spikes"),
    ("flying_gem","flying","aerial_ace","tackle","roost"),
    ("psychic_gem","psychic","psychic","tackle","calm_mind"),
    ("bug_gem","bug","bug_buzz","tackle","sticky_web"),
    ("rock_gem","rock","smack_down","tackle","stealth_rock"),
]
CHECKS = 0

def check(value: bool, message: str) -> None:
    global CHECKS
    CHECKS += 1
    if not value:
        raise AssertionError(message)

def read_rows(path: Path) -> list[dict[str,str]]:
    with path.open(encoding="utf-8-sig", newline="") as fp:
        return list(csv.DictReader(fp))

def validate() -> None:
    manifest = json.loads(FIXTURE.read_text(encoding="utf-8"))
    check(manifest["schema_version"] == 1 and manifest["kind"] == "AUTORUN_V1_W01_GEMS"
          and manifest["worker"] == "W01" and manifest["tanda"] == "01"
          and manifest["format"] == "gen9calvounifiedv1", "Fixture identidad/version errónea")
    check(manifest["modes"] == ["active","none","reserve"], "Tres contextos obligatorios")
    check(manifest["reference_baseline"] == {
        "campaign":"CAMP_005",
        "sha":"5303578448d909cf1b4e2c3c60c7d3e231203f98",
        "run":42717306543}, "No perder SHA histórico de CAMP005")
    check(len(manifest["items"]) == 10, "Diez gemas exactas")
    progress = read_rows(REPORT)
    check(len(progress) == 10, "Diez filas de progreso exigidas")
    prev = read_rows(HISTORY)
    check(len(prev) == 10 and all(x["estado"]=="CI_PASS_VERIFICADO" for x in prev)
          and prev[-1]["sha_pruebas"] == "5303578448d909cf1b4e2c3c60c7d3e231203f98"
          and prev[-1]["ci_run"] == "42717306543", "CAMP005 debe conservar 10/10 y SHA")
    inv = {r["id"]:r for r in read_rows(INVENTORY)}
    scope = {r["id"]:r for r in read_rows(SCOPE)}
    for i,(id,typ,attack,wrong,status) in enumerate(EXPECTED):
        row = manifest["items"][i]
        check((row["row"],row["id"],row["type"],row["attack"],row["wrong"],row["status"])
              == (f"{i+1:02d}",id,typ,attack,wrong,status), "ID o perfil de ataque no autorizado "+id)
        check(row["cases"] == [
            {"op":"matching","move":attack,"seeds":[19,23]},
            {"op":"wrong_type","move":wrong,"seeds":[19]},
            {"op":"status_same_type","move":status,"seeds":[19]}], "Matriz positiva/negativa "+id)
        check(progress[i]["fila"] == row["row"] and progress[i]["id"] == id
              and progress[i]["estado"] in {"PENDIENTE","EN_CI_AUTOMATICA","CERTIFICADO","BLOQUEADO","NO_APLICA","DIFERIDO"},
              "Fila de progreso no corresponde al objeto "+id)
        check(inv[id]["family"]=="HELD_COMBAT_CANDIDATE" and inv[id]["native_entry"]=="True"
              and inv[id]["native_id"] == id.replace("_","")
              and "onSourceTryPrimaryHit" in inv[id]["native_hooks"], "Motor nativo no verificado "+id)
        check(scope[id]["familia"]=="HELD_COMBAT_CANDIDATE" and
              scope[id]["estado_contenido"]=="SELECCIONADO", "Fuera del catálogo elegido "+id)
        check(id not in ";".join(r["ids"] for r in prev), "No repetir objeto CAMP005 "+id)
    runner = GODOT.read_text(encoding="utf-8")
    for token in ["_run_autorun_v1","_w01_c004_probe_lane","gem_matching",
                  "gem_first_consumed","gem_second_consumed","gem_mid_save","gem_final_save",
                  "physical_units","SaveV2", "AUTORUN_W01_ROW_PASS"]:
        check(token in runner, "No hay prueba efectiva en Godot: "+token)
    parent_godot = (ROOT / "tests/gameplay/parallel_items_w01_campaign_005.gd").read_text(encoding="utf-8")
    check("func _frame_c003(" in parent_godot and "func _probe_c005_gem_matching(" in parent_godot,
          "Faltan probes heredados y cerrados de CAMP005")
    check(NATIVE.is_file(), "Falta simulador nativo real")
    source = NATIVE.read_text(encoding="utf-8")
    for token in ["NativeEngine","onSourceTryPrimaryHit","moveSlots","switch 2",
                  "restore","W01_AUTORUN_NATIVE_ROW PASS"]:
        check(token in source, "Falta cobertura nativa: "+token)

def main() -> int:
    try:
        validate()
        run = subprocess.run(["node",str(NATIVE)],cwd=ROOT,capture_output=True,text=True,check=True)
        print(run.stdout.strip())
        check("W01_AUTORUN_NATIVE PASS rows=10" in run.stdout,
              "Nativo incompleto: faltan gemas o negativos")
    except (AssertionError, OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        if isinstance(exc,subprocess.CalledProcessError):
            print("W01_AUTORUN_NATIVE_STDERR:",exc.stderr)
            print("W01_AUTORUN_NATIVE_STDOUT:",exc.stdout)
        print("W01_AUTORUN_PY FAIL:",str(exc))
        return 1
    print(f"W01_AUTORUN_PY PASS rows=10 checks={CHECKS}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

"""Contratos de pruebas W02/CAMP003. --ci valida evidencia estática real;
la CI ejecuta separadamente Godot nativo y exige ambos recibos.
"""
import argparse
import copy
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/parallel_items/w02_campaign_003.json"
QUEUE = ROOT / "docs/coordination/items_parallel_v1/CAMPAIGN_003_QUEUE_APPROVED.csv"
PROGRESS = ROOT / "docs/coordination/items_parallel_v1/reports/W02/CAMP_003_PROGRESO.csv"
NATIVE_V2 = ROOT / "tools/item_audit/held_effect_sweep_v2.cjs"
NATIVE_V3 = ROOT / "tools/item_audit/held_effect_sweep_v3.cjs"
MODES = ("active", "none", "reserve")
IDS_01 = ("aguav_berry", "apicot_berry", "aspear_berry", "babiri_berry")
EXPECTED_01 = {
    "aguav_disliked_naughty": ("aguav_berry", "heal_flavor", "naughty", "fifth", "", "amnesia", True, True),
    "aguav_neutral_hardy": ("aguav_berry", "heal_flavor", "hardy", "fifth", "", "amnesia", True, False),
    "aguav_above_threshold": ("aguav_berry", "heal_flavor", "naughty", "near_full", "", "amnesia", False, False),
    "apicot_pinch": ("apicot_berry", "boost_spd", "hardy", "fifth", "", "amnesia", True, False),
    "apicot_not_triggered": ("apicot_berry", "boost_spd", "hardy", "near_full", "", "amnesia", False, False),
    "aspear_frozen": ("aspear_berry", "cure_freeze", "hardy", "full", "freeze", "amnesia", True, False),
    "aspear_healthy": ("aspear_berry", "cure_freeze", "hardy", "full", "", "amnesia", False, False),
    "babiri_super_effective_steel": ("babiri_berry", "resist_steel", "hardy", "full", "", "flash_cannon", True, False),
    "babiri_wrong_type": ("babiri_berry", "resist_steel", "hardy", "full", "", "tackle", False, False),
}


class ContractError(ValueError):
    pass


class Checks:
    def __init__(self):
        self.count = 0

    def demand(self, condition, reason):
        self.count += 1
        if not condition:
            raise ContractError(reason)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def validate(fixture, queue, progress, check):
    check.demand(isinstance(fixture, dict), "Fixture no es objeto")
    check.demand(set(fixture) == {"schema_version", "campaign", "worker",
        "completed_blocks", "format", "level", "seed", "modes",
        "field_scope", "blocks", "limitations"}, "Esquema fuera del permiso")
    check.demand(fixture["schema_version"] == 1 and fixture["campaign"] == "CAMP_003"
                 and fixture["worker"] == "W02", "Identidad o campaña incorrectas")
    check.demand(fixture["format"] == "gen9calvounifiedv1"
                 and fixture["level"] == 100 and fixture["seed"] == [23, 19, 29, 43],
                 "Formato/RNG reproducible no coincide")
    check.demand(fixture["modes"] == list(MODES) and fixture["field_scope"] == "NOT_TESTED",
                 "Faltan controles o se declara uso de campo")
    tasks = [row for row in queue if row["trabajadora"] == "W02"]
    check.demand(len(tasks) == 10
                 and [r["bloque"] for r in tasks] == [f"{i:02d}" for i in range(1, 11)],
                 "Cola oficial W02 distinta de diez bloques")
    count = len(progress)
    check.demand(1 <= count <= 10, "Se exige progreso publicado en el CSV")
    check.demand(len(fixture["blocks"]) == count, "Fixture no coincide con bloques terminados")
    check.demand(fixture["completed_blocks"] == list(range(1, count + 1)),
                 "Microbloques no consecutivos")
    for i, entry in enumerate(fixture["blocks"]):
        authorized = tasks[i]
        ids = authorized["ids"].split(";")
        check.demand(entry["block"] == authorized["bloque"]
                     and entry["ids"] == ids, "IDs sin reserva oficial")
        check.demand(progress[i]["bloque"] == authorized["bloque"]
                     and progress[i]["ids"] == authorized["ids"],
                     "CSV publicado discrepa de encargo")
        check.demand(len(ids) == 4 and len(set(ids)) == 4, "Bloque W02 exige cuatro bayas")
        check.demand(type(entry["cases"]) is list and bool(entry["cases"]),
                     "Bloque sin escenarios, no puede dar PASS")
        if i == 0:
            check.demand(tuple(ids) == IDS_01 and len(entry["cases"]) == 9,
                         "ITER_01 exige exactamente nueve escenarios para cuatro IDs")
            seen = set()
            for case in entry["cases"]:
                check.demand(set(case) == {"scenario", "id", "kind", "nature", "start",
                    "status", "foe_species", "foe_move", "consumes", "confuses"}
                    or (set(case) == {"scenario", "id", "kind", "nature", "start",
                    "status", "foe_species", "foe_move", "consumes", "confuses",
                    "actor_species"} and case.get("actor_species") == "clefable"),
                    "Caso con campos extra o faltantes")
                scenario = case["scenario"]
                check.demand(scenario in EXPECTED_01 and scenario not in seen,
                             "Escenario desconocido o duplicado")
                seen.add(scenario)
                expected = EXPECTED_01[scenario]
                actual = (case["id"], case["kind"], case["nature"], case["start"],
                          case["status"], case["foe_move"], case["consumes"], case["confuses"])
                check.demand(actual == expected and case["foe_species"] == "mew",
                             "Contrato de naturaleza/umbral/tipo alterado: " + scenario)
                check.demand(case["id"] in ids, "Caso ajeno a la reserva")
            check.demand(seen == set(EXPECTED_01), "Cobertura positiva/negativa incompleta")
        # Las iteraciones posteriores añadirán sus propios contratos inmutables.
    return count


def verify_sources(check):
    v2 = NATIVE_V2.read_text(encoding="utf-8")
    v3 = NATIVE_V3.read_text(encoding="utf-8")
    for needle in ("['aguav_berry','naughty']", "heal_and_disliked_flavor",
                   "heal_without_confusion", "high_hp_no_trigger"):
        check.demand(needle in v3, "No se localizó precedente Aguav: " + needle)
    for needle in ("apicot_berry:'spd'", "aspear_berry:'freeze'",
                   "steel:['babiri_berry','clefable']", "flash_cannon",
                   "resist_nonmatching", "pinch_not_triggered"):
        check.demand(needle in v2, "No se localizó precedente V2: " + needle)


def negative_controls(fixture, queue, progress, check):
    edits = [
        lambda f: f["completed_blocks"].append(2),
        lambda f: f["blocks"][0]["ids"].append("sitrus_berry"),
        lambda f: f["blocks"][0]["cases"].pop(),
        lambda f: f["blocks"][0]["cases"][0].update({"nature": "hardy"}),
        lambda f: f.update({"field_scope": "TESTED"}),
        lambda f: f["blocks"][0]["cases"][-2].update({"foe_move": "tackle"}),
        lambda f: f["blocks"][0]["cases"][-1].update({"consumes": True}),
        lambda f: f["blocks"][0]["cases"][5].update({"status": ""}),
    ]
    for i, edit in enumerate(edits):
        tampered = copy.deepcopy(fixture)
        edit(tampered)
        rejected = False
        try:
            validate(tampered, queue, progress, Checks())
        except (ContractError, KeyError, TypeError):
            rejected = True
        check.demand(rejected, f"Falso PASS no rechazado, adversarial {i}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    args = parser.parse_args()
    checks = Checks()
    fixture, queue, progress = read_json(FIXTURE), read_csv(QUEUE), read_csv(PROGRESS)
    blocks = validate(fixture, queue, progress, checks)
    verify_sources(checks)
    negative_controls(fixture, queue, progress, checks)
    if checks.count == 0:
        raise ContractError("Sin comprobaciones ejecutadas")
    if args.ci:
        print(f"CAMP003_W02_PY PASS blocks={blocks} checks={checks.count}")
    else:
        print(f"Contrato W02 verificado: blocks={blocks}, checks={checks.count}; no ejecuta Godot")


if __name__ == "__main__":
    main()

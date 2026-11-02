"""W02/CAMP_002: contratos de Zidra y Ziuela equipadas; no altera mecánicas.

Un PASS de --unittest/--fixture-only prueba el validador, no Godot.
El resultado --result requiere evidencias generadas realmente por la sesión nativa.
"""
import argparse
import copy
import json
import tempfile
import unittest
from pathlib import Path

from test_parallel_items_w02_berries_v1 import physical_units, valid_file

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/parallel_items/w02_campaign_002.json"
MODES = ("active", "none", "reserve")
EXPECTED = {
    "sitrus_low_hp_c002": ("sitrus_berry", "low_hp", "mew", "amnesia", True),
    "sitrus_high_hp_c002": ("sitrus_berry", "high_hp", "mew", "amnesia", False),
    "lum_poison_c002": ("lum_berry", "poison", "mew", "amnesia", True),
    "lum_healthy_c002": ("lum_berry", "healthy", "mew", "amnesia", False),
}
PROFILES = {
    "sitrus_berry": ("quarter_hp_below_half", "PRESENT_NOT_TESTED",
                     ("sitrus_low_hp_c002",), ("sitrus_high_hp_c002",)),
    "lum_berry": ("persistent_status_all", "PRESENT_NOT_TESTED",
                  ("lum_poison_c002",), ("lum_healthy_c002",)),
}


def demand(condition, msg):
    if not condition:
        raise ValueError(msg)


def read(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def verify_fixture(f):
    demand(set(f) == {"schema_version", "campaign", "worker", "completed_iterations",
                      "family", "format", "level", "seed", "variants", "item_ids",
                      "field_scope", "cases", "coverage_matrix", "note"},
           "Estructura de fixture alterada")
    demand(f["schema_version"] == 1 and f["campaign"] == "CAMP_002"
           and f["worker"] == "W02" and f["completed_iterations"] == [1]
           and f["family"] == "held_berry_revalidation", "Identidad/campaña fuera del gate")
    demand(f["format"] == "gen9calvounifiedv1" and f["level"] == 100
           and f["seed"] == [23, 19, 29, 43], "Semilla o formato ajeno")
    demand(f["variants"] == list(MODES) and f["item_ids"] == ["sitrus_berry", "lum_berry"]
           and f["field_scope"] == "NOT_TESTED_ITER_01", "Rango o alcance alterado")
    demand(type(f["cases"]) is list and len(f["cases"]) == 4, "Faltan casos obligatorios")
    seen = set()
    for case in f["cases"]:
        demand(set(case) == {"id", "scenario", "kind", "actor_species", "foe_move", "consumes"},
               "Caso con campos ausentes o no autorizados")
        scenario = case["scenario"]
        demand(scenario in EXPECTED and scenario not in seen, "Caso extraño o duplicado")
        seen.add(scenario)
        demand((case["id"], case["kind"], case["actor_species"],
                case["foe_move"], case["consumes"]) == EXPECTED[scenario],
               "Expectativa cambiada para forzar PASS")
    demand(seen == set(EXPECTED), "La familia tiene huecos")
    demand(set(f["coverage_matrix"]) == set(PROFILES), "La matriz no separa las dos bayas")
    for item, profile in PROFILES.items():
        entry = f["coverage_matrix"][item]
        demand(set(entry) == {"positive", "negative", "effect", "field_profile"},
               "Descriptor de objeto inválido")
        demand((entry["effect"], entry["field_profile"], tuple(entry["positive"]),
                tuple(entry["negative"])) == profile, "Positivos y negativos no coinciden")
    return f


def verify_result(f, result, folder):
    verify_fixture(f)
    demand(set(result) == {"schema_version", "campaign", "family", "status", "checks",
                           "errors", "cases", "per_item", "field_scope",
                           "full_item_certification", "gpu"}, "Esquema de Godot inválido")
    demand(result["schema_version"] == 1 and result["campaign"] == "CAMP_002"
           and result["family"] == f["family"] and result["status"] == "PASS"
           and result["errors"] == [] and result["full_item_certification"] is False
           and result["gpu"] is False and result["field_scope"] == f["field_scope"],
           "Se ha usado PASS ficticio o se ha ampliado alcance")
    demand(type(result["checks"]) is int and result["checks"] >= 120,
           "La ejecución no tiene suficientes aserciones")
    demand(type(result["cases"]) is list and len(result["cases"]) == 4, "Faltan pruebas")
    seen = set()
    for row in result["cases"]:
        demand(set(row) == {"id", "scenario", "status", "checks", "observed"},
               "Informe de escenario incompleto")
        key = row["scenario"]
        demand(key in EXPECTED and key not in seen and row["id"] == EXPECTED[key][0],
               "ID o escenario atribuido incorrectamente")
        seen.add(key)
        demand(row["status"] == "PASS" and type(row["checks"]) is int
               and row["checks"] >= 20, "Escenario sin aserciones reales")
        modes = row["observed"]
        demand(set(modes) == set(MODES), "Control nativo incompleto")
        should_consume = EXPECTED[key][4]
        for mode, rec in modes.items():
            demand(set(rec) == {"valid", "hp", "max_hp", "status", "damage", "consumed",
                                "stock_total", "bag", "evidence", "sha256",
                                "restored", "settled_once", "save_v2"},
                   "Recibo de simulador incompleto")
            demand(all(rec[flag] is True for flag in ("valid", "restored",
                   "settled_once", "save_v2")), "No se guardó/restauró FLED o SaveV2")
            consumed = should_consume and mode == "active"
            expected_bag = 2 if mode == "none" else 1
            expected_units = 1 if consumed else 2
            demand(rec["consumed"] is consumed and rec["bag"] == expected_bag
                   and rec["stock_total"] == expected_units,
                   "Consumo distinto de exactamente una unidad")
            demand(type(rec["hp"]) is int and type(rec["max_hp"]) is int
                   and 0 < rec["hp"] <= rec["max_hp"], "PS nativos fuera de rango")
            initial_hp = (max(1, rec["max_hp"] // 4) if EXPECTED[key][1] == "low_hp"
                          else rec["max_hp"] - 1 if EXPECTED[key][1] == "high_hp"
                          else rec["max_hp"])
            demand(rec["damage"] == initial_hp - rec["hp"],
                   "PS/daño no atribuibles a estado inicial")
            raw = valid_file(folder, rec["evidence"], rec["sha256"])
            demand(raw["scenario"] == key and raw["mode"] == mode
                   and isinstance(raw["before"], dict) and "native" in raw["before"]
                   and raw["native_hp"] == rec["hp"]
                   and raw["native_status"] == rec["status"]
                   and raw["native_consumed"] is consumed
                   and raw["stock_total"] == expected_units,
                   "Recibo nativo/propiedad alterado")
            owner = raw["owner_after"]
            demand(owner["inventory"]["quantities"].get(row["id"], 0) == expected_bag
                   and physical_units(owner, row["id"]) == expected_units,
                   "Stock físico o portador no coincide en SaveV2")
            own = next(c for c in owner["creatures"] if c["instance_id"] == "own")
            reserve = next(c for c in owner["creatures"] if c["instance_id"] == "reserve")
            demand(own["held_item_consumed"] is consumed and own["current_hp"] == rec["hp"],
                   "Dueño activo/snapshot incoherente")
            if mode == "reserve":
                demand(reserve["held_item_id"] == row["id"]
                       and reserve["held_item_consumed"] is False,
                       "Objeto de reserva mal atribuido")
            if mode == "none":
                demand(not own["held_item_id"] and not reserve["held_item_id"],
                       "Control ausente con objeto oculto")
        active, none, reserve = (modes[m] for m in MODES)
        demand(none["hp"] == reserve["hp"] and none["status"] == reserve["status"],
               "Reserva afecta al activo")
        kind = EXPECTED[key][1]
        if kind == "low_hp":
            demand(active["hp"] - none["hp"] == max(1, active["max_hp"] // 4),
                   "Zidra no recupera un cuarto")
        elif kind == "high_hp":
            demand(active["hp"] == none["hp"], "Zidra se activó sobre el umbral")
        elif kind == "poison":
            demand(active["status"] == "" and none["status"] == reserve["status"] == "poison",
                   "Ziuela no limpia el veneno solo del portador")
        elif kind == "healthy":
            demand(active["status"] == none["status"] == "", "Ziuela se gasta sin estado")
    demand(seen == set(EXPECTED), "Faltan escenas comprobadas")
    demand(set(result["per_item"]) == set(PROFILES), "Faltan bayas en resumen")
    for item, profile in PROFILES.items():
        row = result["per_item"][item]
        demand(set(row) == {"status", "cases"} and row["status"] == "PASS"
               and row["cases"] == len(profile[2] + profile[3]), "PASS no individual")
    return {"status": "PASS_ACOTADO_VERIFICADO", "cases": len(seen),
            "native_variants": len(seen) * 3, "checks": result["checks"]}


class W02Campaign2Contracts(unittest.TestCase):
    def setUp(self):
        self.fixture = read(FIXTURE)

    def test_fixture(self):
        self.assertEqual(len(verify_fixture(self.fixture)["cases"]), 4)

    def test_no_third_item(self):
        f = copy.deepcopy(self.fixture)
        f["item_ids"].append("leppa_berry")
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_no_unapproved_iteration(self):
        f = copy.deepcopy(self.fixture)
        f["completed_iterations"] = [1, 2]
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_missing_scenario(self):
        f = copy.deepcopy(self.fixture)
        f["cases"].pop()
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_wrong_consumption(self):
        f = copy.deepcopy(self.fixture)
        f["cases"][0]["consumes"] = False
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_wrong_status_kind(self):
        f = copy.deepcopy(self.fixture)
        f["cases"][2]["kind"] = "healthy"
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_duplicate_case(self):
        f = copy.deepcopy(self.fixture)
        f["cases"][1] = f["cases"][0].copy()
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_no_false_field_pass(self):
        f = copy.deepcopy(self.fixture)
        f["field_scope"] = "PASS"
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_missing_held_control(self):
        f = copy.deepcopy(self.fixture)
        f["variants"].pop()
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_unverified_report_rejected(self):
        with self.assertRaises(ValueError):
            verify_result(self.fixture, {"status": "PASS"}, Path("."))

    def test_cannot_claim_full_game(self):
        with self.assertRaises(ValueError):
            verify_result(self.fixture, {"status": "PASS", "full_item_certification": True}, Path("."))

    def test_matrix_cannot_claim_other_id(self):
        f = copy.deepcopy(self.fixture)
        f["coverage_matrix"]["lum_berry"]["positive"] = ["sitrus_low_hp_c002"]
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_no_evidence_traversal(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(ValueError):
                valid_file(Path(d), "../untrusted.json", "0" * 64)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--fixture-only", action="store_true")
    parser.add_argument("--unittest", action="store_true")
    parser.add_argument("--result", type=Path)
    args = parser.parse_args()
    if args.unittest:
        unittest.main(argv=["W02Campaign2Contracts"], verbosity=2)
    else:
        fixture = verify_fixture(read(FIXTURE))
        if args.result is None:
            print("CAMP002_W02_FIXTURE_PASS_ONLY; NATIVE_GODOT_SIN_EJECUTAR")
        else:
            print(json.dumps(verify_result(fixture, read(args.result),
                  args.result.resolve().parent), ensure_ascii=False, sort_keys=True))

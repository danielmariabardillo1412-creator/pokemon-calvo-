"""W02/CAMP_002: contratos de Zidra y Ziuela equipadas; no altera mecánicas.

Un PASS de --unittest/--fixture-only prueba el validador, no Godot.
El resultado --result requiere evidencias generadas realmente por la sesión nativa.
"""
import argparse
import copy
import hashlib
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
    "leppa_zero_pp_c002": ("leppa_berry", "pp_empty", "mew", "amnesia", True),
    "leppa_one_pp_c002": ("leppa_berry", "pp_nonempty", "mew", "amnesia", False),
    "figy_modest_low_c002": ("figy_berry", "figy_disliked", "mew", "amnesia", True),
    "figy_hardy_low_c002": ("figy_berry", "figy_neutral", "mew", "amnesia", True),
    "figy_modest_high_c002": ("figy_berry", "figy_high_hp", "mew", "amnesia", False),
}
EXTENSIONS = {
    "leppa_zero_pp_c002": {"own_moves": ["tackle", "reflect"], "own_choice": "move 2", "first_move_pp": 0, "pp_restore": 10},
    "leppa_one_pp_c002": {"own_moves": ["tackle", "reflect"], "own_choice": "move 2", "first_move_pp": 1, "pp_restore": 0},
    "figy_modest_low_c002": {"actor_nature": "modest", "hp_state": "fifth", "disliked": True, "heal_denominator": 3},
    "figy_hardy_low_c002": {"actor_nature": "hardy", "hp_state": "fifth", "disliked": False, "heal_denominator": 3},
    "figy_modest_high_c002": {"actor_nature": "modest", "hp_state": "near_full", "disliked": True, "heal_denominator": 3},
}
PROFILES = {
    "sitrus_berry": ("quarter_hp_below_half", "PRESENT_NOT_TESTED",
                     ("sitrus_low_hp_c002",), ("sitrus_high_hp_c002",)),
    "lum_berry": ("persistent_status_all", "PRESENT_NOT_TESTED",
                  ("lum_poison_c002",), ("lum_healthy_c002",)),
    "leppa_berry": ("restore_10_first_move_when_zero_pp", "PRESENT_NOT_TESTED",
                     ("leppa_zero_pp_c002",), ("leppa_one_pp_c002",)),
    "figy_berry": ("third_hp_low_disliked_spicy_confusion", "NOT_REGISTERED",
                   ("figy_modest_low_c002", "figy_hardy_low_c002"), ("figy_modest_high_c002",)),
}


def demand(condition, msg):
    if not condition:
        raise ValueError(msg)


def read(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def verify_fixture(f):
    demand(set(f) == {"schema_version", "campaign", "worker", "completed_iterations",
                      "family", "format", "level", "seed", "variants", "item_ids",
                      "field_scope", "cases", "coverage_matrix", "regression_contract", "note"},
           "Estructura de fixture alterada")
    demand(f["schema_version"] == 1 and f["campaign"] == "CAMP_002"
           and f["worker"] == "W02" and f["completed_iterations"] == [1, 2, 3]
           and f["family"] == "held_berry_revalidation", "Identidad/campaña fuera del gate")
    demand(f["format"] == "gen9calvounifiedv1" and f["level"] == 100
           and f["seed"] == [23, 19, 29, 43], "Semilla o formato ajeno")
    demand(f["variants"] == list(MODES) and f["item_ids"] == ["sitrus_berry", "lum_berry", "leppa_berry", "figy_berry"]
           and f["field_scope"] == "NOT_TESTED_ITER_02", "Rango o alcance alterado")
    demand(type(f["cases"]) is list and len(f["cases"]) == 9, "Faltan casos obligatorios")
    seen = set()
    for case in f["cases"]:
        scenario = case["scenario"]
        base_keys = {"id", "scenario", "kind", "actor_species", "foe_move", "consumes"}
        expected_extension = EXTENSIONS.get(scenario, {})
        demand(set(case) == base_keys | set(expected_extension), "Campos de caso ajenos/ausentes")
        for key, value in expected_extension.items():
            demand(case[key] == value, "Contrato especial manipulado: " + scenario + "/" + key)
        demand(scenario in EXPECTED and scenario not in seen, "Caso extraño o duplicado")
        seen.add(scenario)
        demand((case["id"], case["kind"], case["actor_species"],
                case["foe_move"], case["consumes"]) == EXPECTED[scenario],
               "Expectativa cambiada para forzar PASS")
    demand(seen == set(EXPECTED), "La familia tiene huecos")
    demand(set(f["coverage_matrix"]) == set(PROFILES), "La matriz no separa las cuatro bayas")
    for item, profile in PROFILES.items():
        entry = f["coverage_matrix"][item]
        demand(set(entry) == {"positive", "negative", "effect", "field_profile"},
               "Descriptor de objeto inválido")
        demand((entry["effect"], entry["field_profile"], tuple(entry["positive"]),
                tuple(entry["negative"])) == profile, "Positivos y negativos no coinciden")
    reg = f["regression_contract"]
    demand(set(reg) == {"expected_scenarios", "expected_native_variants", "expected_owners",
                       "per_item_cases", "save_v2_required", "single_consumption_required",
                       "field_tested", "preserve_legacy_persim"},
           "Contrato de regresión incompleto")
    expected_counts = {item: len(profile[2] + profile[3])
                       for item, profile in PROFILES.items()}
    demand(reg["expected_scenarios"] == 9 and reg["expected_native_variants"] == 27
           and reg["expected_owners"] == list(MODES)
           and reg["per_item_cases"] == expected_counts
           and reg["save_v2_required"] is True
           and reg["single_consumption_required"] is True
           and reg["field_tested"] is False
           and reg["preserve_legacy_persim"] is True,
           "Matriz de regresión altera cobertura, persistencia o Persim")
    return f


def verify_result(f, result, folder):
    verify_fixture(f)
    demand(set(result) == {"schema_version", "campaign", "family", "status", "checks",
                           "errors", "cases", "per_item", "field_scope",
                           "regression", "fixture_sha256", "full_item_certification", "gpu"}, "Esquema de Godot inválido")
    demand(result["schema_version"] == 1 and result["campaign"] == "CAMP_002"
           and result["family"] == f["family"] and result["status"] == "PASS"
           and result["errors"] == [] and result["full_item_certification"] is False
           and result["gpu"] is False and result["field_scope"] == f["field_scope"],
           "Se ha usado PASS ficticio o se ha ampliado alcance")
    demand(type(result["fixture_sha256"]) is str
           and result["fixture_sha256"] == hashlib.sha256(FIXTURE.read_bytes()).hexdigest(),
           "El runner no ha ejecutado el fixture exacto de este SHA")
    demand(type(result["checks"]) is int and result["checks"] >= 120,
           "La ejecución no tiene suficientes aserciones")
    demand(type(result["cases"]) is list and len(result["cases"]) == 9, "Faltan pruebas")
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
            basic = {"valid", "hp", "max_hp", "status", "damage", "consumed",
                     "stock_total", "bag", "evidence", "sha256",
                     "restored", "settled_once", "save_v2"}
            extra = {"initial_hp", "initial_pp", "first_move_pp", "nature", "native_confusion"} if key in EXTENSIONS else set()
            demand(set(rec) == basic | extra, "Recibo de simulador incompleto")
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
            if key in EXTENSIONS:
                initial_hp = rec["initial_hp"]
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
            if key in EXTENSIONS:
                demand(raw["initial_hp"] == rec["initial_hp"]
                       and raw["initial_pp"] == rec["initial_pp"]
                       and raw["native_pp"] == rec["first_move_pp"]
                       and raw["nature"] == rec["nature"]
                       and raw["native_confusion"] is rec["native_confusion"],
                       "PP/naturaleza/confusion no corresponden con recibo")
                demand(type(raw["native_confusion_events"]) is list, "Eventos del motor no capturados")
                if rec["native_confusion"]:
                    demand(any(line.lower().startswith("|-start|") and "|confusion" in line.lower()
                               for line in raw["native_confusion_events"]),
                           "Confusion inventada sin evento nativo")
            owner = raw["owner_after"]
            demand(owner["inventory"]["quantities"].get(row["id"], 0) == expected_bag
                   and physical_units(owner, row["id"]) == expected_units,
                   "Stock físico o portador no coincide en SaveV2")
            own = next(c for c in owner["creatures"] if c["instance_id"] == "own")
            reserve = next(c for c in owner["creatures"] if c["instance_id"] == "reserve")
            demand(own["held_item_consumed"] is consumed and own["current_hp"] == rec["hp"],
                   "Dueño activo/snapshot incoherente")
            if key in EXTENSIONS:
                demand(own["nature_id"] == rec["nature"]
                       and own["moveset"][0]["current_pp"] == rec["first_move_pp"],
                       "SaveV2 perdió PP/naturaleza")
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
        elif kind in ("pp_empty", "pp_nonempty"):
            initial = EXTENSIONS[key]["first_move_pp"]
            demand(active["first_move_pp"] == initial + (10 if should_consume else 0)
                   and none["first_move_pp"] == reserve["first_move_pp"] == initial,
                   "Zanama no restaura PP del slot correcto")
            demand(active["hp"] == none["hp"] and active["status"] == none["status"],
                   "Zanama altera PS/estado")
        elif kind.startswith("figy_"):
            extra = EXTENSIONS[key]
            gain = active["max_hp"] // 3 if should_consume else 0
            demand(active["hp"] == min(active["max_hp"], none["hp"] + gain),
                   "Higog cura cantidad o umbral erróneos")
            demand(active["nature"] == none["nature"] == reserve["nature"] == extra["actor_nature"],
                   "Se ha cambiado la naturaleza para forzar PASS")
            demand(active["native_confusion"] is (should_consume and extra["disliked"])
                   and none["native_confusion"] is False
                   and reserve["native_confusion"] is False,
                   "Higog confunde por naturaleza incorrecta")
    demand(seen == set(EXPECTED), "Faltan escenas comprobadas")
    demand(set(result["per_item"]) == set(PROFILES), "Faltan bayas en resumen")
    for item, profile in PROFILES.items():
        row = result["per_item"][item]
        demand(set(row) == {"status", "cases"} and row["status"] == "PASS"
               and row["cases"] == len(profile[2] + profile[3]), "PASS no individual")
    regression = result["regression"]
    demand(set(regression) == {"status", "scenarios", "native_variants",
                              "save_v2_variants", "mode_counts", "field_tested"},
           "Evidencia final de regresión incompleta")
    demand(regression["status"] == "PASS" and regression["scenarios"] == 9
           and regression["native_variants"] == 27
           and regression["save_v2_variants"] == 27
           and regression["mode_counts"] == {"active": 9, "none": 9, "reserve": 9}
           and regression["field_tested"] is False,
           "Regresión 27/27 o SaveV2 no verificada")
    return {"status": "PASS_ACOTADO_VERIFICADO", "cases": len(seen),
            "native_variants": len(seen) * 3, "checks": result["checks"]}


class W02Campaign2Contracts(unittest.TestCase):
    def setUp(self):
        self.fixture = read(FIXTURE)

    def test_fixture(self):
        self.assertEqual(len(verify_fixture(self.fixture)["cases"]), 9)

    def test_no_third_item(self):
        f = copy.deepcopy(self.fixture)
        f["item_ids"].append("oran_berry")
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_no_unapproved_iteration(self):
        f = copy.deepcopy(self.fixture)
        f["completed_iterations"] = [1, 2, 3, 4]
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

    def test_wrong_leppa_slot(self):
        f = copy.deepcopy(self.fixture)
        f["cases"][4]["own_choice"] = "move 1"
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_wrong_leppa_pp_trigger(self):
        f = copy.deepcopy(self.fixture)
        f["cases"][5]["consumes"] = True
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_wrong_figy_nature(self):
        f = copy.deepcopy(self.fixture)
        f["cases"][6]["actor_nature"] = "adamant"
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_wrong_figy_confusion_rule(self):
        f = copy.deepcopy(self.fixture)
        f["cases"][7]["disliked"] = True
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_regression_cannot_drop_one_item(self):
        f = copy.deepcopy(self.fixture)
        del f["regression_contract"]["per_item_cases"]["figy_berry"]
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_regression_cannot_hide_save_v2(self):
        f = copy.deepcopy(self.fixture)
        f["regression_contract"]["save_v2_required"] = False
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_regression_cannot_invent_field_tests(self):
        f = copy.deepcopy(self.fixture)
        f["regression_contract"]["field_tested"] = True
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_regression_cannot_rewrite_persim(self):
        f = copy.deepcopy(self.fixture)
        f["regression_contract"]["preserve_legacy_persim"] = False
        with self.assertRaises(ValueError): verify_fixture(f)

    def test_regression_cannot_change_total_variants(self):
        f = copy.deepcopy(self.fixture)
        f["regression_contract"]["expected_native_variants"] = 24
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

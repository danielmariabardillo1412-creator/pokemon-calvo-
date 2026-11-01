"""Validador W02: controla cobertura, aserciones y evidencias de las tres bayas.

El PASS de este archivo certifica sólo el contrato del validador, no el motor Godot.
Uso:
 python tests/tools/test_parallel_items_w02_berries_v1.py --unittest
 python tests/tools/test_parallel_items_w02_berries_v1.py --fixture-only
 python tests/tools/test_parallel_items_w02_berries_v1.py --result .godot/parallel_items/w02_berries_v1/godot.json
"""
import argparse
import copy
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/parallel_items/w02_berries_v1.json"
MODES = ("active", "none", "reserve")
EXPECTED = {
    "sitrus_low_hp": ("sitrus_berry", "low_hp", "mew", "amnesia", True),
    "sitrus_high_hp": ("sitrus_berry", "high_hp", "mew", "amnesia", False),
    "lum_poison": ("lum_berry", "poison", "mew", "amnesia", True),
    "lum_healthy": ("lum_berry", "healthy", "mew", "amnesia", False),
    "colbur_super_dark": ("colbur_berry", "super_dark", "mew", "dark_pulse", True),
    "colbur_neutral_dark": ("colbur_berry", "neutral_dark", "snorlax", "dark_pulse", False),
    "colbur_wrong_type": ("colbur_berry", "other_type", "mew", "water_gun", False),
}
IDS = {"sitrus_berry", "lum_berry", "colbur_berry"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def validate_fixture(data):
    require(set(data) == {"schema_version", "family", "format", "level", "seed",
                          "variants", "item_ids", "cases", "note"}, "Campos desconocidos o ausentes")
    require(data["schema_version"] == 1 and data["family"] == "consumable_held_berries"
            and data["format"] == "gen9calvounifiedv1", "Versión/familia/formato incorrectos")
    require(data["level"] == 100 and data["seed"] == [23, 19, 29, 43], "Semilla/nivel distintos")
    require(data["variants"] == list(MODES) and set(data["item_ids"]) == IDS
            and len(data["item_ids"]) == 3, "Controles o IDs incompletos")
    require(type(data["cases"]) is list and len(data["cases"]) == len(EXPECTED), "Cantidad de casos incorrecta")
    found = set()
    for row in data["cases"]:
        require(set(row) == {"id", "scenario", "kind", "actor_species", "foe_move", "consumes"},
                "Contrato con campos extra/ausentes")
        key = row["scenario"]
        require(key in EXPECTED and key not in found, "Caso extraño o duplicado")
        found.add(key)
        require((row["id"], row["kind"], row["actor_species"], row["foe_move"], row["consumes"])
                == EXPECTED[key], "Caso alterado: " + key)
    require(found == set(EXPECTED), "Faltan escenarios")
    return data


def valid_file(folder, name, claimed_hash):
    require(type(name) is str and name.endswith(".json") and "/" not in name
            and "\\" not in name and name not in {".json", "..json"}, "Nombre de evidencia inseguro")
    path = (folder / name).resolve()
    require(path.parent == folder.resolve() and path.is_file(), "Evidencia ausente")
    require(type(claimed_hash) is str and len(claimed_hash) == 64
            and hashlib.sha256(path.read_bytes()).hexdigest() == claimed_hash,
            "SHA-256 de evidencia no coincide")
    return load(path)


def physical_units(owner, item):
    quantities = owner["inventory"]["quantities"]
    count = quantities.get(item, 0)
    require(type(count) is int and count >= 0, "Cantidad de mochila inválida")
    creatures = owner["creatures"]
    require(type(creatures) is list and {c["instance_id"] for c in creatures} >= {"own", "reserve"},
            "Faltan criaturas/propietarios")
    for c in creatures:
        if c["held_item_id"] == item and not c["held_item_consumed"]:
            count += 1
    return count


def validate_result(fixture, report, folder):
    validate_fixture(fixture)
    require(set(report) == {"schema_version", "family", "status", "checks", "errors",
                             "cases", "full_item_certification", "gpu", "limits"},
            "Informe con campos incorrectos")
    require(report["schema_version"] == 1 and report["family"] == fixture["family"],
            "Versión de informe incorrecta")
    require(report["status"] == "PASS" and report["errors"] == []
            and report["full_item_certification"] is False and report["gpu"] is False,
            "FAIL, errores, GPU inventada o certificación total indebida")
    require(type(report["checks"]) is int and report["checks"] >= 200,
            "Comprobaciones insuficientes")
    require(type(report["cases"]) is list and len(report["cases"]) == 7,
            "Faltan filas Godot")
    original = {row["scenario"]: row for row in fixture["cases"]}
    found = set()
    for row in report["cases"]:
        require(set(row) == {"id", "scenario", "status", "checks", "observed"},
                "Fila de escenario incompleta")
        scenario = row["scenario"]
        require(scenario in original and scenario not in found and
                row["id"] == original[scenario]["id"], "ID/escenario duplicado o ausente")
        found.add(scenario)
        require(row["status"] == "PASS" and type(row["checks"]) is int and row["checks"] >= 20,
                "No hay prueba real por escenario")
        observed = row["observed"]
        require(set(observed) == set(MODES), "Faltan variantes")
        expect = bool(original[scenario]["consumes"])
        for mode, data in observed.items():
            require(set(data) == {"valid", "hp", "max_hp", "status", "damage", "consumed",
                                  "stock_total", "bag", "evidence", "sha256",
                                  "restored", "settled_once", "save_v2"},
                    "Resultado de modo incompleto")
            require(all(data[key] is True for key in ("valid", "restored", "settled_once", "save_v2")),
                    "Falta restauración/cierre/guardado real")
            require(type(data["hp"]) is int and type(data["max_hp"]) is int
                    and 0 < data["hp"] <= data["max_hp"], "PS fuera de rango")
            consume = expect and mode == "active"
            expected_bag = 2 if mode == "none" else 1
            expected_stock = 1 if consume else 2
            require(data["consumed"] is consume and data["bag"] == expected_bag
                    and data["stock_total"] == expected_stock, "Consumo/propiedad física incorrectos")
            raw = valid_file(folder, data["evidence"], data["sha256"])
            require(raw["scenario"] == scenario and raw["mode"] == mode
                    and raw["native_hp"] == data["hp"]
                    and raw["native_status"] == data["status"]
                    and raw["native_consumed"] is data["consumed"]
                    and raw["stock_total"] == expected_stock, "Evidencia no corresponde al resultado")
            owner = raw["owner_after"]
            require(owner["inventory"]["quantities"].get(original[scenario]["id"], 0) == expected_bag
                    and physical_units(owner, original[scenario]["id"]) == expected_stock,
                    "La partida final no conserva cantidades/portadores")
            own = next(c for c in owner["creatures"] if c["instance_id"] == "own")
            reserve = next(c for c in owner["creatures"] if c["instance_id"] == "reserve")
            require(own["current_hp"] == data["hp"] and own["held_item_consumed"] is consume,
                    "Estado final del Pokémon propio incorrecto")
            if mode == "reserve":
                require(reserve["held_item_id"] == original[scenario]["id"]
                        and reserve["held_item_consumed"] is False,
                        "El suplente pierde su objeto")
            if mode == "none":
                require(not own["held_item_id"] and not reserve["held_item_id"],
                        "Objeto extraño en control vacío")
        active, none, reserve = (observed[m] for m in MODES)
        require(none["hp"] == reserve["hp"] and none["status"] == reserve["status"]
                and none["damage"] == reserve["damage"],
                "El objeto de reserva altera al dueño activo")
        kind = original[scenario]["kind"]
        if kind == "low_hp":
            require(active["hp"] - none["hp"] == max(1, active["max_hp"] // 4),
                    "Zidra no cura exactamente un cuarto")
        elif kind == "high_hp":
            require(active["hp"] == none["hp"], "Zidra gasta sin umbral")
        elif kind == "poison":
            require(active["status"] == "" and none["status"] == reserve["status"] == "poison",
                    "Ziuela no cura el veneno sólo del portador")
        elif kind == "healthy":
            require(active["status"] == none["status"] == "", "Ziuela cambia un control sano")
        elif kind == "super_dark":
            require(0 < active["damage"] < none["damage"], "Dillo no reduce daño supereficaz")
        else:
            require(active["damage"] == none["damage"], "Dillo reduce daño que no corresponde")
    require(found == set(EXPECTED), "Resultados incompletos")
    return {"status": "PASS_VALIDADO_ACOTADO", "scenarios": 7, "variants": 21, "checks": report["checks"]}


class W02ValidatorTests(unittest.TestCase):
    def setUp(self):
        self.fixture = {
            "schema_version": 1, "family": "consumable_held_berries",
            "format": "gen9calvounifiedv1", "level": 100, "seed": [23, 19, 29, 43],
            "variants": list(MODES), "item_ids": sorted(IDS), "note": "fixture mock",
            "cases": [
                dict(id=id_, scenario=s, kind=k, actor_species=species, foe_move=move, consumes=spent)
                for s, (id_, k, species, move, spent) in EXPECTED.items()
            ],
        }
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        cases = []
        for row in self.fixture["cases"]:
            observed = {}
            for mode in MODES:
                spent = row["consumes"] and mode == "active"
                status = ("poison" if row["kind"] == "poison" and mode != "active" else "")
                hp = 200 if row["kind"] == "low_hp" and mode == "active" else (
                    100 if row["kind"] == "low_hp" else 399 if row["kind"] == "high_hp" else 400)
                damage = (50 if mode == "active" else 100) if row["kind"] == "super_dark" else (
                    80 if row["kind"] == "neutral_dark" else 70 if row["kind"] == "other_type" else 400 - hp)
                bag = 2 if mode == "none" else 1
                own = {"instance_id": "own", "current_hp": hp, "held_item_id": row["id"] if mode == "active" else "",
                       "held_item_consumed": spent}
                reserve = {"instance_id": "reserve", "current_hp": 400,
                           "held_item_id": row["id"] if mode == "reserve" else "", "held_item_consumed": False}
                owner = {"inventory": {"quantities": {row["id"]: bag}}, "creatures": [own, reserve]}
                name = row["scenario"] + "_" + mode + ".json"
                raw = {"scenario": row["scenario"], "mode": mode,
                       "native_hp": hp, "native_status": status, "native_consumed": spent,
                       "stock_total": 1 if spent else 2, "owner_after": owner}
                data = json.dumps(raw, sort_keys=True).encode()
                (self.folder / name).write_bytes(data)
                observed[mode] = {
                    "valid": True, "hp": hp, "max_hp": 400, "status": status, "damage": damage,
                    "consumed": spent, "stock_total": 1 if spent else 2, "bag": bag,
                    "evidence": name, "sha256": hashlib.sha256(data).hexdigest(),
                    "restored": True, "settled_once": True, "save_v2": True,
                }
            cases.append({"id": row["id"], "scenario": row["scenario"],
                          "status": "PASS", "checks": 30, "observed": observed})
        self.report = {"schema_version": 1, "family": "consumable_held_berries",
                       "status": "PASS", "checks": 250, "errors": [],
                       "cases": cases, "full_item_certification": False,
                       "gpu": False, "limits": ["simulated validator contract only"]}

    def fail_validation(self, report=None, fixture=None):
        with self.assertRaises(ValueError):
            validate_result(self.fixture if fixture is None else fixture,
                            self.report if report is None else report, self.folder)

    def test_fixture_complete(self):
        self.assertEqual(len(validate_fixture(self.fixture)["cases"]), 7)

    def test_coherent_mock_report_is_structurally_accepted(self):
        self.assertEqual(validate_result(self.fixture, self.report, self.folder)["variants"], 21)

    def test_missing_negative_mode_rejected(self):
        r = copy.deepcopy(self.report)
        del r["cases"][0]["observed"]["reserve"]
        self.fail_validation(report=r)

    def test_missing_case_rejected(self):
        r = copy.deepcopy(self.report)
        r["cases"].pop()
        self.fail_validation(report=r)

    def test_duplicate_case_rejected(self):
        r = copy.deepcopy(self.report)
        r["cases"][1] = r["cases"][0]
        self.fail_validation(report=r)

    def test_mutated_contract_rejected(self):
        f = copy.deepcopy(self.fixture)
        f["cases"][0]["consumes"] = False
        self.fail_validation(fixture=f)

    def test_wrong_native_status_rejected(self):
        r = copy.deepcopy(self.report)
        r["cases"][2]["observed"]["active"]["status"] = "poison"
        self.fail_validation(report=r)

    def test_wrong_stock_rejected(self):
        r = copy.deepcopy(self.report)
        r["cases"][4]["observed"]["active"]["stock_total"] = 2
        self.fail_validation(report=r)

    def test_corrupt_evidence_rejected(self):
        (self.folder / "sitrus_low_hp_active.json").write_text("{}", encoding="utf-8")
        self.fail_validation()

    def test_fake_full_certification_rejected(self):
        r = copy.deepcopy(self.report)
        r["full_item_certification"] = True
        self.fail_validation(report=r)

    def test_hidden_errors_rejected(self):
        r = copy.deepcopy(self.report)
        r["errors"] = ["native error"]
        self.fail_validation(report=r)

    def test_missing_save_flag_rejected(self):
        r = copy.deepcopy(self.report)
        r["cases"][0]["observed"]["active"]["save_v2"] = False
        self.fail_validation(report=r)

    def test_reserve_owner_wrong_rejected(self):
        raw_path = self.folder / "colbur_super_dark_reserve.json"
        raw = load(raw_path)
        raw["owner_after"]["creatures"][1]["held_item_id"] = ""
        data = json.dumps(raw).encode()
        raw_path.write_bytes(data)
        r = copy.deepcopy(self.report)
        r["cases"][4]["observed"]["reserve"]["sha256"] = hashlib.sha256(data).hexdigest()
        self.fail_validation(report=r)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fixture-only", action="store_true")
    parser.add_argument("--result", type=Path)
    parser.add_argument("--unittest", action="store_true")
    args = parser.parse_args()
    if args.unittest:
        unittest.main(argv=["W02ValidatorTests"], verbosity=2)
    else:
        fixture = validate_fixture(load(FIXTURE))
        if args.result:
            report = load(args.result)
            print(json.dumps(validate_result(fixture, report, args.result.resolve().parent),
                             ensure_ascii=False, sort_keys=True))
        else:
            print("W02_FIXTURE_PASS (sin ejecución Godot; solo contrato estático)")

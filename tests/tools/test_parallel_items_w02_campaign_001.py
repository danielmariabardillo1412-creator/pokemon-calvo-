"""Validador independiente W02 CAMP_001: matriz, falsos PASS y pruebas de guardado.

Este archivo no ejecuta Godot ni implementa bayas. Acepta únicamente recibos reales
de `parallel_items_w02_campaign_001.gd`, además de sus tests unitarios sintéticos.
"""
import argparse
import copy
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/parallel_items/w02_campaign_001.json"
EXPECTED_01 = {
    "oran_low_hp": ("oran_berry", "hp", "quarter", "", True, True, 10),
    "oran_full_hp": ("oran_berry", "hp", "full", "", False, False, 10),
    "pecha_poison": ("pecha_berry", "status", "full", "poison", True, True, 0),
    "pecha_burn": ("pecha_berry", "status", "full", "burn", False, False, 0),
    "pecha_healthy": ("pecha_berry", "status", "full", "", False, False, 0),
    "cheri_paralysis": ("cheri_berry", "status", "full", "paralysis", True, True, 0),
    "cheri_poison": ("cheri_berry", "status", "full", "poison", False, False, 0),
    "cheri_healthy": ("cheri_berry", "status", "full", "", False, False, 0),
}
MODES = ("active", "none", "reserve")
LOCATIONS = ("PARTY", "STORAGE")


def require(ok, reason):
    if not ok:
        raise ValueError(reason)


def read(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def validate_fixture(f):
    require(set(f) == {"schema_version", "family", "campaign",
                       "microblocks_completed", "format", "level", "seed",
                       "variants", "locations", "cases", "note"},
            "Claves de matriz alteradas")
    require(f["schema_version"] == 1 and f["family"] == "berry_campaign_w02"
            and f["campaign"] == "CAMP_001" and f["microblocks_completed"] == [1],
            "Campaña o microbloque no autorizado")
    require(f["format"] == "gen9calvounifiedv1"
            and f["seed"] == [23, 19, 29, 43] and f["level"] == 100,
            "Simulador/semilla/nivel no reproducibles")
    require(f["variants"] == list(MODES) and f["locations"] == list(LOCATIONS),
            "No hay controles completos de dueño y mochila")
    require(isinstance(f["cases"], list) and len(f["cases"]) == len(EXPECTED_01),
            "Faltan casos o se han añadido sin permiso")
    seen = set()
    for r in f["cases"]:
        require(set(r) == {"id", "scenario", "kind", "initial", "status",
                           "consumes", "field_applies", "heal"},
                "Campos de caso incompatibles")
        key = r["scenario"]
        require(key in EXPECTED_01 and key not in seen, "Caso desconocido/repetido")
        seen.add(key)
        require((r["id"], r["kind"], r["initial"], r["status"],
                 r["consumes"], r["field_applies"], r["heal"]) == EXPECTED_01[key],
                "Expectativa de baya modificada: " + key)
    require(seen == set(EXPECTED_01), "Matriz sin todos los casos obligatorios")
    return f


def verified_raw(folder, filename, sha256):
    require(isinstance(filename, str) and filename.endswith(".json")
            and "/" not in filename and "\\" not in filename,
            "Ruta no segura")
    file = (folder / filename).resolve()
    require(file.parent == folder.resolve() and file.is_file(),
            "Evidencia JSON ausente")
    require(isinstance(sha256, str) and len(sha256) == 64
            and hashlib.sha256(file.read_bytes()).hexdigest() == sha256,
            "SHA-256 de evidencia inválido")
    return read(file)


def stock(owner, item):
    bag = owner["inventory"]["quantities"].get(item, 0)
    require(type(bag) is int and bag >= 0, "Inventario inválido")
    monsters = owner["creatures"]
    require({x["instance_id"] for x in monsters} >= {"own", "reserve"},
            "Faltan dueños necesarios")
    return bag + sum(x["held_item_id"] == item and not x["held_item_consumed"]
                     for x in monsters)


def validate_result(f, result, folder):
    validate_fixture(f)
    require(set(result) == {"schema_version", "family", "status", "checks",
                            "errors", "cases", "full_item_certification", "gpu"},
            "Esquema de informe alterado")
    require(result["schema_version"] == 1 and result["family"] == f["family"]
            and result["status"] == "PASS" and result["errors"] == []
            and result["full_item_certification"] is False and result["gpu"] is False,
            "Informe fallido o certificación indebida")
    require(type(result["checks"]) is int and result["checks"] >= 160,
            "Insuficientes aserciones reales")
    require(len(result["cases"]) == len(f["cases"]), "Faltan filas Godot")
    lookup = {r["scenario"]: r for r in f["cases"]}
    seen = set()
    for row in result["cases"]:
        require(set(row) == {"id", "scenario", "checks", "status", "native", "field"},
                "Fila sin aserciones/evidencia")
        key = row["scenario"]
        require(key in lookup and key not in seen and row["id"] == lookup[key]["id"],
                "Escenario duplicado o atribuido a otra baya")
        seen.add(key)
        require(row["status"] == "PASS" and type(row["checks"]) is int
                and row["checks"] >= 20, "Caso no aprobado")
        spec = lookup[key]
        require(set(row["native"]) == set(MODES), "Falta control activo/ausente/reserva")
        require(set(row["field"]) == set(LOCATIONS), "Falta PARTY/STORAGE")
        for mode, v in row["native"].items():
            require(set(v) == {"valid", "hp", "max_hp", "status",
                               "consumed", "units", "bag", "save", "evidence", "sha256"},
                    "Contrato de combate incompleto")
            consumed = bool(spec["consumes"]) and mode == "active"
            bag = 2 if mode == "none" else 1
            units = 1 if consumed else 2
            require(v["valid"] is True and v["save"] is True and v["consumed"] is consumed
                    and v["bag"] == bag and v["units"] == units,
                    "Propietario/consumo/SaveV2 falso")
            require(type(v["hp"]) is int and type(v["max_hp"]) is int
                    and 0 < v["hp"] <= v["max_hp"], "PS fuera de rango")
            raw = verified_raw(folder, v["evidence"], v["sha256"])
            require(raw["scenario"] == key and raw["mode"] == mode
                    and raw["native_hp"] == v["hp"]
                    and raw["native_status"] == v["status"]
                    and raw["native_consumed"] is consumed
                    and raw["units"] == units,
                    "Evidencia combate no corresponde al resultado")
            saved = raw["owner_after"]
            require(saved["inventory"]["quantities"].get(spec["id"], 0) == bag
                    and stock(saved, spec["id"]) == units,
                    "Stock físico no cuadra con la partida")
            own = next(x for x in saved["creatures"] if x["instance_id"] == "own")
            reserve = next(x for x in saved["creatures"] if x["instance_id"] == "reserve")
            require(own["current_hp"] == v["hp"]
                    and own["held_item_consumed"] is consumed, "Dueño activo incoherente")
            if mode == "reserve":
                require(reserve["held_item_id"] == spec["id"]
                        and reserve["held_item_consumed"] is False,
                        "Objeto mal ubicado o consumido en reserva")
            if mode == "none":
                require(not own["held_item_id"] and not reserve["held_item_id"],
                        "Caso control sin objeto tiene equipamiento")
        active, plain, reserve = (row["native"][mode] for mode in MODES)
        require(plain["hp"] == reserve["hp"] and plain["status"] == reserve["status"],
                "Reserva altera resultado del activo")
        if spec["kind"] == "hp":
            require(active["hp"] == min(active["max_hp"],
                    plain["hp"] + (spec["heal"] if spec["consumes"] else 0))
                    and active["status"] == plain["status"],
                    "Aranja incumple cura/tope/control")
        else:
            expected_status = "" if spec["consumes"] else spec["status"]
            require(active["status"] == expected_status
                    and plain["status"] == reserve["status"] == spec["status"],
                    "Estado curado/no curado fuera del contrato")
        for place, v in row["field"].items():
            require(set(v) == {"valid", "accepted", "hp", "status", "bag",
                               "save", "evidence", "sha256"}, "Contrato campo incompleto")
            apply = bool(spec["field_applies"])
            require(v["valid"] is True and v["save"] is True
                    and v["accepted"] is apply and v["bag"] == (1 if apply else 2),
                    "Campo consumo/rechazo incorrecto")
            raw = verified_raw(folder, v["evidence"], v["sha256"])
            require(raw["scenario"] == key and raw["location"] == place
                    and raw["accepted"] is apply,
                    "Prueba de campo no corresponde a su recibo")
            own = next(x for x in raw["owner_after"]["creatures"]
                       if x["instance_id"] == "own")
            require(own["current_hp"] == v["hp"]
                    and own["status_state"]["persistent_id"] == v["status"]
                    and raw["owner_after"]["inventory"]["quantities"].get(spec["id"], 0)
                    == v["bag"], "SaveV2 de campo incorrecto")
            hp_base = raw["initial_hp"]
            expected_hp = (min(own["stats"]["max_hp"], hp_base + spec["heal"])
                           if apply else hp_base)
            status_base = raw["initial_status"]
            expected_status = ("" if apply and spec["kind"] == "status"
                               else status_base)
            require(v["hp"] == expected_hp and v["status"] == expected_status,
                    "Campo cura estado/PS erróneos")
    require(seen == set(lookup), "Matriz real incompleta")
    return {"status": "PASS_VERIFICADO_ACOTADO", "cases": len(seen),
            "native_variants": len(seen) * 3, "field_variants": len(seen) * 2,
            "checks": result["checks"]}


class ContractTests(unittest.TestCase):
    def setUp(self):
        self.fixture = {"schema_version": 1, "family": "berry_campaign_w02",
                        "campaign": "CAMP_001", "microblocks_completed": [1],
                        "format": "gen9calvounifiedv1", "level": 100,
                        "seed": [23, 19, 29, 43], "variants": list(MODES),
                        "locations": list(LOCATIONS), "note": "test",
                        "cases": [
                            {"id": v[0], "scenario": name, "kind": v[1],
                             "initial": v[2], "status": v[3],
                             "consumes": v[4], "field_applies": v[5], "heal": v[6]}
                            for name, v in EXPECTED_01.items()
                        ]}

    def test_real_fixture_passes_contract(self):
        self.assertEqual(len(validate_fixture(read(FIXTURE))["cases"]), 8)

    def test_synthetic_fixture_passes(self):
        self.assertEqual(len(validate_fixture(self.fixture)["cases"]), 8)

    def test_missing_case_rejected(self):
        data = copy.deepcopy(self.fixture)
        data["cases"].pop()
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_duplicate_case_rejected(self):
        data = copy.deepcopy(self.fixture)
        data["cases"][0] = data["cases"][1]
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_wrong_status_rejected(self):
        data = copy.deepcopy(self.fixture)
        data["cases"][2]["status"] = "paralysis"
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_wrong_berry_rejected(self):
        data = copy.deepcopy(self.fixture)
        data["cases"][0]["id"] = "pecha_berry"
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_fake_consumption_rejected(self):
        data = copy.deepcopy(self.fixture)
        data["cases"][5]["consumes"] = False
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_missing_reserve_rejected(self):
        data = copy.deepcopy(self.fixture)
        data["variants"] = ["active", "none"]
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_other_microblock_unapproved(self):
        data = copy.deepcopy(self.fixture)
        data["microblocks_completed"] = [1, 2]
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_full_certification_rejected(self):
        with self.assertRaises(ValueError):
            validate_result(self.fixture,
                            {"status": "PASS", "full_item_certification": True},
                            Path("."))

    def test_insecure_file_name_rejected(self):
        with self.assertRaises(ValueError):
            verified_raw(Path("."), "../fake.json", "0" * 64)

    def test_bad_digest_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            folder = Path(d)
            (folder / "case.json").write_text("{}", encoding="utf-8")
            with self.assertRaises(ValueError):
                verified_raw(folder, "case.json", "f" * 64)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--unittest", action="store_true")
    parser.add_argument("--fixture-only", action="store_true")
    parser.add_argument("--result", type=Path)
    args = parser.parse_args()
    if args.unittest:
        unittest.main(argv=["ContractTests"], verbosity=2)
    else:
        data = validate_fixture(read(FIXTURE))
        if args.result is None:
            print("W02_CAMP001_FIXTURE_PASS (solo estructura; Godot SIN_EJECUTAR)")
        else:
            print(json.dumps(validate_result(data, read(args.result),
                      args.result.resolve().parent), ensure_ascii=False, sort_keys=True))

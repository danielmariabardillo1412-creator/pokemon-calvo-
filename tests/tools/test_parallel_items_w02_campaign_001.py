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
# Contratos ITER_02: los ocho EXPECTED_01 permanecen idénticos.
# (id,kind,initial,status,consumes,field_applies,heal,foe_species,foe_move,
#  field_confusion,field_status,native_expected_status)
EXPECTED_02 = {
    "persim_confuse_ray": ("persim_berry", "confusion", "full", "", True, False, 0, "gengar", "confuse_ray", True, "", ""),
    "persim_no_confusion": ("persim_berry", "confusion", "full", "", False, False, 0, "mew", "amnesia", False, "", ""),
    "chesto_spore": ("chesto_berry", "status", "full", "", True, True, 0, "gengar", "spore", False, "sleep", "sleep"),
    "chesto_burn": ("chesto_berry", "status", "full", "burn", False, False, 0, "mew", "amnesia", False, "", ""),
    "chesto_healthy": ("chesto_berry", "status", "full", "", False, False, 0, "mew", "amnesia", False, "", ""),
    "rawst_burn": ("rawst_berry", "status", "full", "burn", True, True, 0, "mew", "amnesia", False, "", ""),
    "rawst_poison": ("rawst_berry", "status", "full", "poison", False, False, 0, "mew", "amnesia", False, "", ""),
    "rawst_healthy": ("rawst_berry", "status", "full", "", False, False, 0, "mew", "amnesia", False, "", ""),
}
ALL_EXPECTED = set(EXPECTED_01) | set(EXPECTED_02)
MATRIX_PROFILES = {"oran_berry": ("hp_10", "heal_10"), "pecha_berry": ("poison_specific", "poison_specific"), "cheri_berry": ("paralysis_specific", "paralysis_specific"), "persim_berry": ("volatile_confusion_specific", "NOT_REGISTERED"), "chesto_berry": ("sleep_specific", "sleep_specific"), "rawst_berry": ("burn_specific", "burn_specific")}

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
                       "variants", "locations", "cases", "note", "coverage_matrix"},
            "Claves de matriz alteradas")
    require(f["schema_version"] == 1 and f["family"] == "berry_campaign_w02"
            and f["campaign"] == "CAMP_001" and f["microblocks_completed"] == [1, 2, 3],
            "Campaña o microbloque no autorizado")
    require(f["format"] == "gen9calvounifiedv1"
            and f["seed"] == [23, 19, 29, 43] and f["level"] == 100,
            "Simulador/semilla/nivel no reproducibles")
    require(f["variants"] == list(MODES) and f["locations"] == list(LOCATIONS),
            "No hay controles completos de dueño y mochila")
    require(isinstance(f["cases"], list) and len(f["cases"]) == len(ALL_EXPECTED),
            "Faltan casos o se han añadido sin permiso")
    seen = set()
    for r in f["cases"]:
        key = r["scenario"]
        require(key in ALL_EXPECTED and key not in seen, "Caso desconocido/repetido")
        seen.add(key)
        base_fields = {"id", "scenario", "kind", "initial", "status",
                       "consumes", "field_applies", "heal"}
        original = (r["id"], r["kind"], r["initial"], r["status"],
                    r["consumes"], r["field_applies"], r["heal"])
        if key in EXPECTED_01:
            require(set(r) == base_fields and original == EXPECTED_01[key],
                    "ITER_01 alterada: " + key)
        else:
            suffix = (r.get("foe_species"), r.get("foe_move"),
                      r.get("field_confusion"), r.get("field_status", ""),
                      r.get("native_expected_status", ""))
            expected_keys = base_fields | {"foe_species", "foe_move", "field_confusion"}
            if key == "chesto_spore":
                expected_keys |= {"field_status", "native_expected_status"}
            require(set(r) == expected_keys and original + suffix == EXPECTED_02[key],
                    "ITER_02 alterada: " + key)
    require(seen == ALL_EXPECTED, "Matriz sin todos los casos obligatorios")
    matrix = f["coverage_matrix"]
    require(set(matrix) == set(MATRIX_PROFILES), "Familias fuera del permiso")
    for item, desc in matrix.items():
        require(set(desc) == {"effect", "field_profile", "positive", "negative"},
                "Descriptor incompleto: " + item)
        require((desc["effect"], desc["field_profile"]) == MATRIX_PROFILES[item],
                "Perfil no autorizado: " + item)
        canonical = {**EXPECTED_01, **EXPECTED_02}
        positive = [name for name, val in canonical.items() if val[0] == item and val[4] is True]
        negative = [name for name, val in canonical.items() if val[0] == item and val[4] is False]
        require(desc["positive"] == positive and desc["negative"] == negative,
                "Contratos positivos/negativos desalineados: " + item)
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
                            "errors", "cases", "per_item", "full_item_certification", "gpu"},
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
            require(set(v) == {"valid", "hp", "max_hp", "status", "confused",
                               "native_confusion_started", "consumed", "units", "bag", "save", "evidence", "sha256"},
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
                    and raw["native_confused"] is v["confused"]
                    and raw["native_confusion_started"] is v["native_confusion_started"]
                    and raw["native_consumed"] is consumed
                    and raw["units"] == units,
                    "Evidencia combate no corresponde al resultado")
            native_events = raw.get("native_confusion_events")
            require(type(v["native_confusion_started"]) is bool and isinstance(native_events, list)
                    and all(type(e) is str and e.lower().startswith("|-start|") and "|confusion" in e.lower() for e in native_events)
                    and bool(native_events) is v["native_confusion_started"],
                    "Evento de confusión nativo ausente o falsificado")
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
        require(plain["hp"] == reserve["hp"] and plain["status"] == reserve["status"]
                and plain["confused"] is reserve["confused"],
                "Reserva altera resultado del activo")
        if spec["kind"] == "confusion":
            require(active["native_confusion_started"] is bool(spec["consumes"])
                    and plain["native_confusion_started"] is bool(spec["consumes"])
                    and reserve["native_confusion_started"] is bool(spec["consumes"]),
                    "Persim no controla confusion de portador/suplente")
            require(active["status"] == plain["status"] == reserve["status"] == spec["status"],
                    "Persim no debe curar estado persistente")
        elif spec["kind"] == "hp":
            require(active["hp"] == min(active["max_hp"],
                    plain["hp"] + (spec["heal"] if spec["consumes"] else 0))
                    and active["status"] == plain["status"],
                    "Aranja incumple cura/tope/control")
        else:
            base_status = spec.get("native_expected_status", spec["status"])
            expected_status = "" if spec["consumes"] else base_status
            require(active["status"] == expected_status
                    and plain["status"] == reserve["status"] == base_status,
                    "Estado curado/no curado fuera del contrato")
            require(all(v["native_confusion_started"] is False for v in (active, plain, reserve)),
                    "Baya específica no relacionada presenta activación nativa de confusión")
        for place, v in row["field"].items():
            require(set(v) == {"valid", "accepted", "hp", "status", "confused", "bag",
                               "save", "evidence", "sha256"}, "Contrato campo incompleto")
            apply = bool(spec["field_applies"])
            require(v["valid"] is True and v["save"] is True
                    and v["accepted"] is apply and v["bag"] == (1 if apply else 2),
                    "Campo consumo/rechazo incorrecto")
            raw = verified_raw(folder, v["evidence"], v["sha256"])
            require(raw["scenario"] == key and raw["location"] == place
                    and raw["accepted"] is apply
                    and raw["confused"] is v["confused"],
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
            require(v["confused"] is raw["initial_confused"]
                    and v["confused"] is bool(spec.get("field_confusion", False)),
                    "Confusion campo no registrada/no preservada")
            if key == "persim_confuse_ray":
                require(raw["initial_confused"] is True and apply is False,
                        "Persim no tiene perfil campo; no simular curacion integral")
            if key == "chesto_spore":
                require(raw["initial_status"] == "sleep" and v["status"] == "",
                        "Chesto campo debe quitar sueño")
    require(seen == set(lookup), "Matriz real incompleta")
    per_item = result["per_item"]
    require(set(per_item) == set(f["coverage_matrix"]), "Falta estado por baya")
    for item, summary in per_item.items():
        require(set(summary) == {"status", "cases"} and summary["status"] == "PASS",
                "Una baya no ha pasado su matriz")
        expected_count = len(f["coverage_matrix"][item]["positive"] +
                             f["coverage_matrix"][item]["negative"])
        actual_count = sum(row["id"] == item for row in result["cases"])
        require(summary["cases"] == expected_count == actual_count,
                "Resumen atribuye escenarios incorrectos: " + item)
    return {"status": "PASS_VERIFICADO_ACOTADO", "cases": len(seen),
            "native_variants": len(seen) * 3, "field_variants": len(seen) * 2,
            "checks": result["checks"]}


class ContractTests(unittest.TestCase):
    def setUp(self):
        self.fixture = {"schema_version": 1, "family": "berry_campaign_w02",
                        "campaign": "CAMP_001", "microblocks_completed": [1, 2, 3],
                        "format": "gen9calvounifiedv1", "level": 100,
                        "seed": [23, 19, 29, 43], "variants": list(MODES),
                        "locations": list(LOCATIONS), "note": "test",
                        "cases": [
                            {"id": v[0], "scenario": name, "kind": v[1],
                             "initial": v[2], "status": v[3],
                             "consumes": v[4], "field_applies": v[5], "heal": v[6]}
                            for name, v in EXPECTED_01.items()
                        ] + [
                            dict(id=v[0], scenario=name, kind=v[1], initial=v[2],
                                 status=v[3], consumes=v[4], field_applies=v[5], heal=v[6],
                                 foe_species=v[7], foe_move=v[8], field_confusion=v[9],
                                 **({"field_status": v[10], "native_expected_status": v[11]}
                                    if name == "chesto_spore" else {}))
                            for name, v in EXPECTED_02.items()
                        ],
                        "coverage_matrix": {
                            item: {"effect": profile[0], "field_profile": profile[1],
                                   "positive": [key for key, val in {**EXPECTED_01, **EXPECTED_02}.items()
                                                if val[0] == item and val[4] is True],
                                   "negative": [key for key, val in {**EXPECTED_01, **EXPECTED_02}.items()
                                                if val[0] == item and val[4] is False]}
                            for item, profile in MATRIX_PROFILES.items()
                        }}

    def test_real_fixture_passes_contract(self):
        self.assertEqual(len(validate_fixture(read(FIXTURE))["cases"]), 16)

    def test_synthetic_fixture_passes(self):
        self.assertEqual(len(validate_fixture(self.fixture)["cases"]), 16)

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
        data["microblocks_completed"] = [1, 2, 3, 4]
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_persim_field_cure_falsification_rejected(self):
        data = copy.deepcopy(self.fixture)
        row = next(x for x in data["cases"] if x["scenario"] == "persim_confuse_ray")
        row["field_applies"] = True
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_chesto_spore_trigger_missing_rejected(self):
        data = copy.deepcopy(self.fixture)
        row = next(x for x in data["cases"] if x["scenario"] == "chesto_spore")
        row["foe_move"] = "amnesia"
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_rawst_wrong_status_rejected(self):
        data = copy.deepcopy(self.fixture)
        row = next(x for x in data["cases"] if x["scenario"] == "rawst_poison")
        row["consumes"] = True
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_missing_per_berry_contract_rejected(self):
        data = copy.deepcopy(self.fixture)
        del data["coverage_matrix"]["rawst_berry"]
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_swapped_positive_negative_rejected(self):
        data = copy.deepcopy(self.fixture)
        row = data["coverage_matrix"]["chesto_berry"]
        row["negative"] = row["positive"]
        with self.assertRaises(ValueError): validate_fixture(data)

    def test_persim_field_profile_falsification_rejected(self):
        data = copy.deepcopy(self.fixture)
        data["coverage_matrix"]["persim_berry"]["field_profile"] = "all_cure"
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

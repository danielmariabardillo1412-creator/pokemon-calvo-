#!/usr/bin/env python3
"""W05 CAMP_002: muestreo reproducible de MT, lectura del catálogo real, sin Godot.

Este módulo NO enseña movimientos. --report usa el checkout completo y devuelve
una muestra con especies compatibles para los siguientes microbloques.
"""
from __future__ import annotations

import csv
import json
import sys
import unittest
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
FIXTURE = RAIZ / "tests/fixtures/parallel_items/w05_campaign_002.json"


class ErrorMuestra(ValueError):
    pass


def leer_json(ruta: Path) -> dict:
    with ruta.open(encoding="utf-8-sig") as archivo:
        dato = json.load(archivo)
    if not isinstance(dato, dict):
        raise ErrorMuestra(f"JSON no es diccionario: {ruta}")
    return dato


def leer_filtrado(ruta: Path) -> list[dict]:
    with ruta.open(encoding="utf-8-sig", newline="") as archivo:
        lector = csv.DictReader(archivo)
        if not {"id", "familia", "estado_contenido"}.issubset(lector.fieldnames or []):
            raise ErrorMuestra("Catálogo sin columnas de selección")
        filas = [f for f in lector if f["familia"] == "MACHINE" and f["estado_contenido"] == "SELECCIONADO"]
    ids = [f["id"] for f in filas]
    if len(ids) != len(set(ids)):
        raise ErrorMuestra("IDs MACHINE duplicados")
    return filas


def _motivos_politica(policy: dict) -> tuple[set[str], set[str], set[str]]:
    excluidos = {id for grupo in policy.get("move_exclusions", []) for id in grupo.get("ids", [])}
    z = set(policy.get("z_moves", {}).get("ids", []))
    max_ids = set(policy.get("protected_max_move_ids", []))
    especies = set(policy.get("excluded_species_ids", []))
    return excluidos | z | max_ids, especies, z


def seleccionar(fixture: dict, filas: list[dict], profile: dict, dataset: dict, policy: dict) -> dict:
    if fixture.get("schema_version") != 1 or fixture.get("campaign") != "CAMP_002_W05":
        raise ErrorMuestra("Fixture de campaña inválido")
    if profile.get("schema_version") != 1 or profile.get("profile_id") != "calvo_item_connections_v1":
        raise ErrorMuestra("Perfil de máquinas inválido")
    version = fixture.get("active_version")
    if version != "scarlet-violet" or profile.get("active_machine_version") != version:
        raise ErrorMuestra("Perfil histórico no autorizado")
    mapping = profile.get("machine_rows")
    moves, species, items = (dataset.get(key) for key in ("moves", "species", "items"))
    if not all(isinstance(d, dict) and d for d in (mapping, moves, species, items)):
        raise ErrorMuestra("Catálogos canónicos incompletos")
    expected = fixture["scope_expected"]
    activos = {}
    legacy = []
    for fila in filas:
        item_id = fila["id"]
        versiones = mapping.get(item_id)
        if not isinstance(versiones, dict) or item_id not in items:
            raise ErrorMuestra("Máquina sin datos canónicos: " + item_id)
        mov = versiones.get(version, "")
        if mov:
            if mov not in moves:
                raise ErrorMuestra("Movimiento activo ausente: " + item_id)
            activos[item_id] = mov
        else:
            legacy.append(item_id)
    if (len(filas), len(activos), len(legacy)) != (
        expected["selected_machines"], expected["active"], expected["legacy"]
    ):
        raise ErrorMuestra("Drift de censo MACHINE; no ajustar límites a ciegas")
    reglas = fixture["sample"]
    quota = reglas["minimum_valid"]
    if not 1 <= quota <= reglas["max_selected"]:
        raise ErrorMuestra("Cuota inválida")
    omitidos = set(reglas["exclude_already_tested"])
    if len(omitidos) != 3 or omitidos != {"tm01", "tm02", "tm77"}:
        raise ErrorMuestra("Muestra debe excluir las tres MT ya probadas")
    banned_moves, banned_species, _z = _motivos_politica(policy)

    # Precomputar primero un índice inverso de learnsets, sin inferir números de MT.
    especie_por_mov: dict[str, set[str]] = {}
    for sid, entry in species.items():
        if sid in banned_species or not isinstance(entry, dict):
            continue
        for le in entry.get("learnset", []):
            if (isinstance(le, dict) and le.get("method") == "machine"
                    and le.get("version_group") == version):
                mov = le.get("move_id")
                if isinstance(mov, str):
                    especie_por_mov.setdefault(mov, set()).add(sid)

    candidatos = reglas["candidates"]
    ids_candidatos = [c["item_id"] for c in candidatos]
    if len(ids_candidatos) != len(set(ids_candidatos)):
        raise ErrorMuestra("Candidaturas duplicadas")
    # Orden del fixture estable, seguido de resto del censo ordenado por tipo y clase.
    prioridad = ids_candidatos + sorted(
        (id for id in activos if id not in ids_candidatos),
        key=lambda id: (
            str(moves[activos[id]].get("type_id", "")),
            str(moves[activos[id]].get("damage_class", "")), id,
        ),
    )
    seleccionados, descartados, vistos = [], [], set()
    for item_id in prioridad:
        if item_id in vistos:
            continue
        vistos.add(item_id)
        if item_id in omitidos:
            continue
        if item_id not in activos:
            descartados.append({"item_id": item_id, "motivo": "sin_version_activa"})
            continue
        move_id = activos[item_id]
        definition = moves[move_id]
        if not isinstance(definition, dict):
            raise ErrorMuestra("Definición movimiento incorrecta " + move_id)
        candidate = next((c for c in candidatos if c["item_id"] == item_id), None)
        tipo = definition.get("type_id", "")
        clase = definition.get("damage_class", "")
        pp = definition.get("pp")
        if candidate is not None and (candidate["move_id"] != move_id
                                      or candidate["type_id"] != tipo
                                      or candidate["damage_class"] != clase):
            raise ErrorMuestra("Candidato ha cambiado contra catálogo: " + item_id)
        motivo = ""
        if move_id in banned_moves:
            motivo = "movimiento_prohibido_por_politica"
        elif not tipo or clase not in {"physical", "special", "status"} or not isinstance(pp, int) or pp <= 0:
            motivo = "metadatos_movimiento_invalidos"
        compatibles = sorted(especie_por_mov.get(move_id, set()))
        if not motivo and not compatibles:
            motivo = "sin_especie_compatible_en_learnset_SV"
        if motivo:
            descartados.append({"item_id": item_id, "move_id": move_id, "motivo": motivo})
            continue
        seleccionados.append({
            "item_id": item_id, "move_id": move_id, "type_id": tipo,
            "damage_class": clase, "pp": pp, "species_id": compatibles[0],
            "compatibility": "LEARNSET_VERSIONADO_VERIFICADO_ESTATICO_NO_GODOT",
        })
        if len(seleccionados) == reglas["max_selected"]:
            break
    if len(seleccionados) < quota:
        raise ErrorMuestra(f"Solo {len(seleccionados)} máquinas con especie verificable; se requieren {quota}")
    return {
        "status": "MUESTRA_ESTATICA_NO_GODOT",
        "campaign": fixture["campaign"], "selected_count": len(seleccionados),
        "source_scope": {"total": len(filas), "active": len(activos), "legacy": len(legacy)},
        "distinct_types": len({r["type_id"] for r in seleccionados}),
        "excluded_pretested": sorted(omitidos),
        "sample": seleccionados, "rejected_candidates": descartados,
    }


def desde_checkout(root: Path = RAIZ) -> dict:
    fixture = leer_json(root / "tests/fixtures/parallel_items/w05_campaign_002.json")
    rutas = fixture["source_paths"]
    return seleccionar(
        fixture, leer_filtrado(root / rutas["selection"]),
        leer_json(root / rutas["mapping"]), leer_json(root / rutas["normalized"]),
        leer_json(root / rutas["policy"]),
    )


class TestMuestraW05(unittest.TestCase):
    def setUp(self):
        self.fixture = {"schema_version": 1, "campaign": "CAMP_002_W05",
                        "active_version": "scarlet-violet",
                        "scope_expected": {"selected_machines": 4, "active": 3, "legacy": 1},
                        "sample": {"minimum_valid": 2, "max_selected": 2,
                                   "exclude_already_tested": ["tm01", "tm02", "tm77"],
                                   "candidates": [
                                       {"item_id": "tm08", "move_id": "fire_fang", "type_id": "fire", "damage_class": "physical"},
                                       {"item_id": "tm04", "move_id": "agility", "type_id": "psychic", "damage_class": "status"},
                                   ]}}
        self.filas = [{"id": id} for id in ["tm08", "tm04", "tm09", "hm01"]]
        self.profile = {"schema_version": 1, "profile_id": "calvo_item_connections_v1",
                        "active_machine_version": "scarlet-violet",
                        "machine_rows": {"tm08": {"scarlet-violet": "fire_fang"},
                                         "tm04": {"scarlet-violet": "agility"},
                                         "tm09": {"scarlet-violet": "thunder_fang"},
                                         "hm01": {"red-blue": "cut"}}}
        self.dataset = {
            "moves": {"fire_fang": {"type_id": "fire", "damage_class": "physical", "pp": 15},
                      "agility": {"type_id": "psychic", "damage_class": "status", "pp": 30},
                      "thunder_fang": {"type_id": "electric", "damage_class": "physical", "pp": 15}},
            "items": {id: {"id": id} for id in ["tm08", "tm04", "tm09", "hm01"]},
            "species": {
                "charizard": {"learnset": [{"method": "machine", "version_group": "scarlet-violet", "move_id": "fire_fang"}]},
                "raichu": {"learnset": [{"method": "machine", "version_group": "scarlet-violet", "move_id": "agility"},
                                      {"method": "machine", "version_group": "scarlet-violet", "move_id": "thunder_fang"}]},
                "old": {"learnset": [{"method": "machine", "version_group": "sword-shield", "move_id": "fire_fang"}]},
            }}
        self.policy = {"move_exclusions": [], "z_moves": {"ids": []},
                       "protected_max_move_ids": [], "excluded_species_ids": []}

    def ejecutar(self):
        return seleccionar(self.fixture, self.filas, self.profile, self.dataset, self.policy)

    def test_seleccion_estratificada_con_especie_real_del_fixture(self):
        resultado = self.ejecutar()
        self.assertEqual([r["item_id"] for r in resultado["sample"]], ["tm08", "tm04"])
        self.assertEqual(resultado["distinct_types"], 2)
        self.assertEqual(resultado["sample"][0]["species_id"], "charizard")

    def test_fallback_sin_especie_no_fabrica_compatibilidad(self):
        self.dataset["species"]["charizard"]["learnset"] = []
        resultado = self.ejecutar()
        self.assertEqual([r["item_id"] for r in resultado["sample"]], ["tm04", "tm09"])
        self.assertEqual(resultado["rejected_candidates"][0]["motivo"], "sin_especie_compatible_en_learnset_SV")

    def test_no_incluir_legacy_ni_anteriores(self):
        self.assertEqual(self.ejecutar()["source_scope"], {"total": 4, "active": 3, "legacy": 1})
        self.assertNotIn("hm01", [r["item_id"] for r in self.ejecutar()["sample"]])

    def test_criterio_reproducible(self):
        self.assertEqual(self.ejecutar(), self.ejecutar())

    def test_catalogo_drift_falla(self):
        self.profile["machine_rows"]["tm08"].pop("scarlet-violet")
        with self.assertRaisesRegex(ErrorMuestra, "Drift"):
            self.ejecutar()

    def test_candidatura_tipo_falso_no_pasa(self):
        self.fixture["sample"]["candidates"][0]["type_id"] = "water"
        with self.assertRaisesRegex(ErrorMuestra, "ha cambiado"):
            self.ejecutar()

    def test_umbral_no_se_reduce(self):
        self.dataset["species"] = {"empty": {"learnset": []}}
        with self.assertRaisesRegex(ErrorMuestra, "se requieren 2"):
            self.ejecutar()

    def test_politica_move_exclusion_filtra(self):
        self.policy["move_exclusions"] = [{"ids": ["fire_fang"]}]
        resultado = self.ejecutar()
        self.assertEqual([r["item_id"] for r in resultado["sample"]], ["tm04", "tm09"])
        self.assertEqual(resultado["rejected_candidates"][0]["motivo"], "movimiento_prohibido_por_politica")

    def test_especie_excluida_no_es_compatible(self):
        self.policy["excluded_species_ids"] = ["charizard"]
        resultado = self.ejecutar()
        self.assertEqual([r["item_id"] for r in resultado["sample"]], ["tm04", "tm09"])

    def test_especie_version_historica_no_cuenta(self):
        self.dataset["species"]["charizard"]["learnset"] = [
            {"method": "machine", "version_group": "sword-shield", "move_id": "fire_fang"}]
        self.assertEqual([r["item_id"] for r in self.ejecutar()["sample"]], ["tm04", "tm09"])

    @unittest.skipUnless(
        (RAIZ / "data/normalized/pokemon_api.json").is_file()
        and FIXTURE.is_file(), "Sin checkout local: validación real corresponde a CI")
    def test_catalogo_real_12_si_checkout(self):
        r = desde_checkout()
        self.assertEqual(r["source_scope"], {"total": 248, "active": 229, "legacy": 19})
        self.assertEqual(r["selected_count"], 12)
        self.assertGreaterEqual(r["distinct_types"], 8)
        self.assertFalse({x["item_id"] for x in r["sample"]} & {"tm01", "tm02", "tm77"})


if __name__ == "__main__":
    if "--report" in sys.argv:
        try:
            print(json.dumps(desde_checkout(), ensure_ascii=False, sort_keys=True, indent=2))
        except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
            print(f"W05_CAMP002_MUESTRA_ERROR: {exc}", file=sys.stderr)
            sys.exit(1)
    else:
        unittest.main()

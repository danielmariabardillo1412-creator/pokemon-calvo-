"""Controles de contrato W05; sin engine, sin red y sin escribir en producción."""
from __future__ import annotations

import copy
import csv
import hashlib
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
RUTA = RAIZ / "tools/item_audit/parallel_w05_machine_scope.py"
ESPEC = importlib.util.spec_from_file_location("parallel_w05_machine_scope", RUTA)
MODULO = importlib.util.module_from_spec(ESPEC)
ESPEC.loader.exec_module(MODULO)


class ValidadorMaquinas(unittest.TestCase):
    def setUp(self):
        self.temporal = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporal.cleanup)
        carpeta = Path(self.temporal.name)
        self.catalogo = carpeta / "catalogo.csv"
        self.perfil = carpeta / "perfil.json"
        self.contrato = carpeta / "contrato.json"
        self.filas = [
            {"id": "tm01", "familia": "MACHINE", "estado_contenido": "SELECCIONADO"},
            {"id": "tm02", "familia": "MACHINE", "estado_contenido": "SELECCIONADO"},
            {"id": "hm05", "familia": "MACHINE", "estado_contenido": "SELECCIONADO"},
            {"id": "tr13", "familia": "MACHINE", "estado_contenido": "SELECCIONADO"},
        ]
        self.mapa = {
            "schema_version": 1,
            "profile_id": "calvo_item_connections_v1",
            "active_machine_version": "scarlet-violet",
            "machine_rows": {
                "tm01": {"scarlet-violet": "take_down", "sword-shield": "mega_kick"},
                "tm02": {"scarlet-violet": "waterfall"},
                "hm05": {"omega-ruby-alpha-sapphire": "waterfall"},
                "tr13": {"sword-shield": "focus_energy"},
            },
        }
        self.reglas = {
            "schema_version": 1,
            "familia": "MACHINE",
            "profile_schema_version": 1,
            "profile_id": "calvo_item_connections_v1",
            "active_machine_version": "scarlet-violet",
            "legacy_reference_preference": {
                "tm": ["sword-shield"], "hm": ["omega-ruby-alpha-sapphire"],
                "tr": ["sword-shield"]},
            "expected_snapshot": {"total": 4, "activas": 2, "heredadas": 2,
                                  "por_prefijo": {"hm": 1, "tm": 2, "tr": 1}},
            "expected_cross_profile_overlaps": [
                {"heredado": "hm05", "activo": "tm02", "movimiento": "waterfall"}],
        }
        self.guardar()

    def guardar(self):
        with self.catalogo.open("w", encoding="utf-8", newline="") as archivo:
            w = csv.DictWriter(archivo, fieldnames=["id", "familia", "estado_contenido"])
            w.writeheader()
            w.writerows(self.filas)
        self.perfil.write_text(json.dumps(self.mapa), encoding="utf-8")
        self.contrato.write_text(json.dumps(self.reglas), encoding="utf-8")

    def ejecutar(self):
        return MODULO.validar(self.catalogo, self.perfil, self.contrato)

    def test_camino_valido_y_solape_interversion(self):
        r = self.ejecutar()
        self.assertEqual(r["estado"], "PASS_MAPA_ESTATICO_NO_FUNCIONAL")
        self.assertEqual(r["conteos"]["heredadas"], 2)
        self.assertEqual(r["ids_heredados"], ["hm05", "tr13"])
        self.assertEqual(r["solapes"], self.reglas["expected_cross_profile_overlaps"])

    def test_no_escribe_fuentes(self):
        rutas = (self.catalogo, self.perfil, self.contrato)
        antes = [hashlib.sha256(p.read_bytes()).hexdigest() for p in rutas]
        self.ejecutar()
        despues = [hashlib.sha256(p.read_bytes()).hexdigest() for p in rutas]
        self.assertEqual(antes, despues)

    def test_id_faltante_en_perfil(self):
        del self.mapa["machine_rows"]["tm01"]
        self.guardar()
        with self.assertRaisesRegex(MODULO.ErrorMapa, "sin mapa"):
            self.ejecutar()

    def test_id_duplicado_en_catalogo(self):
        self.filas.append(copy.deepcopy(self.filas[0]))
        self.guardar()
        with self.assertRaisesRegex(MODULO.ErrorMapa, "duplicado"):
            self.ejecutar()

    def test_perfil_activo_invalido(self):
        self.mapa["active_machine_version"] = "otra-version"
        self.guardar()
        with self.assertRaisesRegex(MODULO.ErrorMapa, "Perfil"):
            self.ejecutar()

    def test_perfil_sin_tabla(self):
        self.mapa["machine_rows"] = []
        self.guardar()
        with self.assertRaisesRegex(MODULO.ErrorMapa, "machine_rows"):
            self.ejecutar()

    def test_dos_ids_activos_mismo_movimiento(self):
        self.mapa["machine_rows"]["tm02"]["scarlet-violet"] = "take_down"
        self.guardar()
        with self.assertRaisesRegex(MODULO.ErrorMapa, "duplicado"):
            self.ejecutar()

    def test_version_historica_no_autorizada(self):
        self.mapa["machine_rows"]["tr13"] = {"red-blue": "focus_energy"}
        self.guardar()
        with self.assertRaisesRegex(MODULO.ErrorMapa, "Sin versión histórica"):
            self.ejecutar()

    def test_solape_nuevo_detectado_como_deriva(self):
        self.mapa["machine_rows"]["hm05"]["omega-ruby-alpha-sapphire"] = "cut"
        self.guardar()
        with self.assertRaisesRegex(MODULO.ErrorMapa, "Solapes"):
            self.ejecutar()

    def test_conteos_no_se_autocorrigen(self):
        self.reglas["expected_snapshot"]["activas"] = 3
        self.guardar()
        with self.assertRaisesRegex(MODULO.ErrorMapa, "Conteos"):
            self.ejecutar()

    def test_identificador_maquina_invalido(self):
        self.filas[0]["id"] = "libro_01"
        self.guardar()
        with self.assertRaisesRegex(MODULO.ErrorMapa, "inválido"):
            self.ejecutar()

    def test_movimiento_malformado(self):
        self.mapa["machine_rows"]["tm01"]["scarlet-violet"] = "take down"
        self.guardar()
        with self.assertRaisesRegex(MODULO.ErrorMapa, "inválido"):
            self.ejecutar()

    def test_cli_solo_lectura_y_json(self):
        import contextlib
        import io
        salida = io.StringIO()
        with contextlib.redirect_stdout(salida):
            codigo = MODULO.main(["--catalogo", str(self.catalogo), "--perfil", str(self.perfil),
                                  "--contrato", str(self.contrato)])
        self.assertEqual(codigo, 0)
        dato = json.loads(salida.getvalue())
        self.assertEqual(dato["conteos"]["total"], 4)
        self.assertNotIn("filas", dato)

    def test_ruta_real_248_si_disponible(self):
        if not all(p.is_file() for p in [MODULO.CATALOGO, MODULO.PERFIL, MODULO.CONTRATO]):
            self.skipTest("Sin checkout: control sobre 248 IDs corresponde a CI consolidada")
        resultado = MODULO.validar()
        self.assertEqual(resultado["conteos"]["total"], 248)
        self.assertEqual(resultado["conteos"]["activas"], 229)
        self.assertEqual(resultado["conteos"]["heredadas"], 19)
        self.assertEqual(resultado["solapes"][0]["heredado"], "hm05")


if __name__ == "__main__":
    unittest.main()

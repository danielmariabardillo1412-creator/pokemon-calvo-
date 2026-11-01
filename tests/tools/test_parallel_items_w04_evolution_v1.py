#!/usr/bin/env python3
"""W04: contrato evolutivo de tres IDs + lanzador opcional Godot 4.7.

Por defecto verifica datos del checkout (NO certifica comportamiento GDScript).
Con --godot [ruta] ejecuta la prueba funcional separada y exige su propio PASS.
No modifica fuentes, datos, fixtures ni políticas.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
RUTAS = (
    ("auspicious_armor", "charcadet", "armarouge", 490),
    ("malicious_armor", "charcadet", "ceruledge", 490),
    ("black_augurite", "scyther", "kleavor", 58),
)
SCRIPT_GODOT = "res://tests/gameplay/parallel_items_w04_evolution_v1.gd"
MARCADOR = "PARALLEL_ITEMS_W04_EVOLUTION_V1 "


def exigir(condicion: bool, detalle: str) -> None:
    if not condicion:
        raise AssertionError(detalle)


def cargar(ruta: str):
    return json.loads((RAIZ / ruta).read_text(encoding="utf-8-sig"))


def buscar_ruta(arbol: dict, origen: str, destino: str) -> list[dict]:
    exigir(arbol["chain"]["species"]["name"] == origen, f"origen distinto: {origen}")
    opciones = [
        detalle
        for evolucion in arbol["chain"]["evolves_to"]
        if evolucion["species"]["name"] == destino
        for detalle in evolucion["evolution_details"]
    ]
    return opciones


def verificar_datos() -> int:
    """Comprueba fuentes originales, inventario, selección y traza histórica V1."""
    comprobaciones = 0
    with (RAIZ / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv").open(
        newline="", encoding="utf-8-sig"
    ) as f:
        seleccion = list(csv.DictReader(f))
    with (RAIZ / "docs/current/ITEM_INVENTORY.csv").open(
        newline="", encoding="utf-8-sig"
    ) as f:
        inventario = list(csv.DictReader(f))
    matriz = cargar("docs/current/ITEM_CONNECTIONS_V1.json")
    perfil = cargar("modules/inventory/item_connections_v1.json")
    politica = cargar("config/item_selection_v1.json")
    fuente = {
        numero: cargar(f"data/api/v2/evolution-chain/{numero}/index.json")
        for numero in {fila[3] for fila in RUTAS}
    }
    script = (RAIZ / SCRIPT_GODOT.removeprefix("res://")).read_text(encoding="utf-8")

    for item, origen, destino, cadena in RUTAS:
        elegidos = [r for r in seleccion if r["id"] == item]
        exigir(len(elegidos) == 1 and elegidos[0]["decision"] == "SELECCIONADO",
               f"{item}: scope no único o no seleccionado")
        comprobaciones += 1
        entrada = [r for r in inventario if r["id"] == item]
        exigir(len(entrada) == 1 and entrada[0]["evolution_links"] == "1",
               f"{item}: referencia inventario cambiada")
        comprobaciones += 1
        traza = [r for r in matriz["rows"] if r["id"] == item]
        exigir(len(traza) == 1 and traza[0]["supported_evolution_routes_tested"] == 1,
               f"{item}: matriz V1 sin ruta histórica")
        comprobaciones += 1
        exigir(traza[0]["field_use_status"] == "BAG_EVOLUTION_VERIFIED_WITH_SUPPORTED_TARGETS",
               f"{item}: clasificación histórica distinta")
        comprobaciones += 1
        detalle = buscar_ruta(fuente[cadena], origen, destino)
        exigir(len(detalle) == 1, f"{item}: falta o se duplica destino fuente")
        comprobar_item = detalle[0].get("item") or {}
        exigir(
            detalle[0]["trigger"]["name"] == "use-item"
            and comprobar_item.get("name") == item.replace("_", "-")
            and detalle[0].get("min_level") is None
            and detalle[0].get("held_item") is None,
            f"{item}: regla canónica distinta; revisión humana necesaria",
        )
        comprobaciones += 1
        exigir(item in script, f"{item}: no se parametriza en GDScript")
        comprobaciones += 1
        # No proponer enlace nativo ficticio: es distinto del uso en bolsa Godot.
        exigir((item in perfil["holdable_ids"]) == (item != "black_augurite"),
               f"{item}: equipabilidad cambió; revisar contrato")
        comprobaciones += 1
        exigir(item not in json.dumps(politica["excluded_ids"]),
               f"{item}: veto activo incompatible")
        comprobaciones += 1

    for simbolo in ("use_item(", "evolve(", "save_collection(", "repositorio.load(",
                    "deposit(", "instantanea(", "ko_sin_resurreccion",
                    "destino_alternativo_sin_gasto", "sin_stock", "campo_bloqueado_sin_gasto"):
        exigir(simbolo in script, f"prueba no contiene el escenario: {simbolo}")
        comprobaciones += 1
    print(f"PARALLEL_ITEMS_W04_STATIC PASS checks={comprobaciones} cases=3 "
          "scope=METADATOS_NO_RUNTIME")
    return comprobaciones


def ejecutar_godot(binario: str, timeout: int) -> dict:
    comando = [binario, "--headless", "--path", str(RAIZ), "--script", SCRIPT_GODOT]
    try:
        completado = subprocess.run(
            comando, cwd=RAIZ, encoding="utf-8", errors="replace",
            capture_output=True, timeout=timeout, check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise RuntimeError(f"Godot no ejecutado/completado: {error}") from error
    salida = completado.stdout + "\n" + completado.stderr
    print(salida.rstrip(), flush=True)
    exigir(completado.returncode == 0, f"Godot exit={completado.returncode}")
    exigir(not re.search(r"SCRIPT ERROR|Parse Error|Failed to load script", salida, re.I),
           "Godot informa errores de carga/parseo")
    resultados = []
    for linea in salida.splitlines():
        if linea.startswith(MARCADOR):
            resultados.append(json.loads(linea[len(MARCADOR):]))
    exigir(len(resultados) == 1, "falta o se repite resultado W04 JSON")
    resultado = resultados[0]
    exigir(resultado.get("status") == "PASS" and resultado.get("errors") == [],
           "GDScript falló en aserciones")
    exigir(resultado.get("cases") == 3 and resultado.get("checks", 0) >= 55,
           "cobertura nominal insuficiente")
    exigir(resultado.get("scope") == "W04_ITEM_EVOLUTIONS_BAG_PC_SAVE_NO_GPU",
           "marcador de alcance distinto")
    print(f"PARALLEL_ITEMS_W04_GODOT PASS checks={resultado['checks']} "
          f"cases=3 headless=true")
    return resultado


def principal() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", nargs="?", const="", default=None,
                        help="Godot 4.7 binario opcional: ejecuta test runtime además de estático")
    parser.add_argument("--timeout", type=int, default=180)
    args = parser.parse_args()
    try:
        verificar_datos()
        if args.godot is not None:
            binario = args.godot or os.environ.get("GODOT_BIN") or shutil.which("godot")
            exigir(bool(binario), "SIN_EJECUTAR: no se encontró Godot (usar --godot RUTA)")
            ejecutar_godot(str(binario), args.timeout)
    except (AssertionError, OSError, KeyError, ValueError, RuntimeError) as error:
        print(f"PARALLEL_ITEMS_W04 FAIL {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(principal())

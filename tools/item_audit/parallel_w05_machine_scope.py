#!/usr/bin/env python3
"""Audita mapas de máquinas seleccionadas. Solo lectura; no prueba mecánicas Godot."""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import Counter
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
CATALOGO = RAIZ / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
PERFIL = RAIZ / "modules/inventory/item_connections_v1.json"
CONTRATO = RAIZ / "tests/fixtures/parallel_items/w05_machine_scope_v1.json"
PATRON_ID = re.compile(r"^(hm|tm|tr)\d+$")
PATRON_MOV = re.compile(r"^[a-z][a-z0-9_]*$")


class ErrorMapa(ValueError):
    """Un dato impide certificar siquiera la consistencia estática del mapa."""


def leer_json(ruta: Path) -> dict:
    with ruta.open(encoding="utf-8-sig") as archivo:
        dato = json.load(archivo)
    if not isinstance(dato, dict):
        raise ErrorMapa(f"JSON no es objeto: {ruta}")
    return dato


def leer_seleccion(ruta: Path) -> list[dict]:
    with ruta.open(encoding="utf-8-sig", newline="") as archivo:
        lector = csv.DictReader(archivo)
        columnas = {"id", "familia", "estado_contenido"}
        if not columnas.issubset(lector.fieldnames or []):
            raise ErrorMapa("CSV maestro sin columnas obligatorias")
        maquinas = []
        vistos = set()
        for fila in lector:
            identificador = str(fila.get("id") or "").strip()
            if not identificador:
                raise ErrorMapa("ID vacío en catálogo")
            if identificador in vistos:
                raise ErrorMapa(f"ID duplicado en catálogo: {identificador}")
            vistos.add(identificador)
            if fila["familia"] != "MACHINE":
                continue
            if not PATRON_ID.fullmatch(identificador):
                raise ErrorMapa(f"ID MACHINE inválido: {identificador}")
            if fila["estado_contenido"] != "SELECCIONADO":
                raise ErrorMapa(f"MACHINE fuera de SELECCIONADO: {identificador}")
            maquinas.append(fila)
    if not maquinas:
        raise ErrorMapa("Catálogo sin máquinas seleccionadas")
    return maquinas


def validar(catalogo: Path = CATALOGO, perfil: Path = PERFIL,
            contrato: Path = CONTRATO) -> dict:
    """Deriva los resultados a partir de fuentes; el contrato versiona las expectativas."""
    reglas = leer_json(contrato)
    if reglas.get("schema_version") != 1 or reglas.get("familia") != "MACHINE":
        raise ErrorMapa("Contrato W05 incompatible")
    version = reglas.get("active_machine_version")
    if not isinstance(version, str) or not version:
        raise ErrorMapa("Versión activa del contrato inválida")
    preferencias = reglas.get("legacy_reference_preference")
    if not isinstance(preferencias, dict):
        raise ErrorMapa("Faltan preferencias históricas versionadas")
    perfil_datos = leer_json(perfil)
    if (perfil_datos.get("schema_version") != reglas.get("profile_schema_version")
            or perfil_datos.get("profile_id") != reglas.get("profile_id")
            or perfil_datos.get("active_machine_version") != version):
        raise ErrorMapa("Perfil de máquinas inválido o versión activa distinta")
    mapas = perfil_datos.get("machine_rows")
    if not isinstance(mapas, dict):
        raise ErrorMapa("machine_rows no es una tabla")

    seleccion = leer_seleccion(catalogo)
    activos, heredados, filas = {}, [], []
    prefijos = Counter()
    for fila in seleccion:
        identificador = fila["id"]
        prefijo = PATRON_ID.fullmatch(identificador).group(1)
        prefijos[prefijo] += 1
        versiones = mapas.get(identificador)
        if not isinstance(versiones, dict) or not versiones:
            raise ErrorMapa(f"ID sin mapa de versiones: {identificador}")
        for nombre_version, movimiento in versiones.items():
            if (not isinstance(nombre_version, str) or not nombre_version
                    or not isinstance(movimiento, str)
                    or not PATRON_MOV.fullmatch(movimiento)):
                raise ErrorMapa(f"Versión o movimiento inválido: {identificador}")
        movimiento_actual = versiones.get(version)
        estado = "ACTIVA" if movimiento_actual else "HEREDADA_SIN_PERFIL"
        referencia = version
        movimiento_referencia = movimiento_actual
        if movimiento_actual:
            if movimiento_actual in activos:
                raise ErrorMapa(f"Movimiento activo duplicado: {activos[movimiento_actual]} y {identificador}")
            activos[movimiento_actual] = identificador
        else:
            opciones = preferencias.get(prefijo)
            if not isinstance(opciones, list) or not opciones or any(not isinstance(v, str) for v in opciones):
                raise ErrorMapa(f"Preferencias de versión inexistentes: {prefijo}")
            referencia = next((v for v in opciones if v in versiones), "")
            if not referencia:
                raise ErrorMapa(f"Sin versión histórica definida para {identificador}")
            movimiento_referencia = versiones[referencia]
            heredados.append(identificador)
        filas.append({"id": identificador, "estado": estado, "movimiento_activo": movimiento_actual,
                      "version_referencia": referencia, "movimiento_referencia": movimiento_referencia})

    solapes = sorted(
        ({"heredado": fila["id"], "activo": activos[fila["movimiento_referencia"]],
          "movimiento": fila["movimiento_referencia"]}
         for fila in filas if fila["estado"] == "HEREDADA_SIN_PERFIL"
         and fila["movimiento_referencia"] in activos),
        key=lambda dato: (dato["heredado"], dato["activo"]),
    )
    conteos = {"total": len(filas), "activas": len(activos),
               "heredadas": len(heredados), "por_prefijo": dict(sorted(prefijos.items()))}
    esperado = reglas.get("expected_snapshot")
    if not isinstance(esperado, dict) or conteos != esperado:
        raise ErrorMapa(f"Conteos difieren del contrato versionado: esperado={esperado}, real={conteos}")
    solapes_esperados = reglas.get("expected_cross_profile_overlaps")
    if not isinstance(solapes_esperados, list) or solapes != solapes_esperados:
        raise ErrorMapa(f"Solapes distintos de los aprobados: {solapes}")
    return {"estado": "PASS_MAPA_ESTATICO_NO_FUNCIONAL", "perfil": version,
            "conteos": conteos, "ids_heredados": heredados,
            "solapes": solapes, "filas": filas}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalogo", type=Path, default=CATALOGO)
    parser.add_argument("--perfil", type=Path, default=PERFIL)
    parser.add_argument("--contrato", type=Path, default=CONTRATO)
    parser.add_argument("--detalles", action="store_true", help="Incluir las filas en la salida JSON")
    args = parser.parse_args(argv)
    try:
        resultado = validar(args.catalogo, args.perfil, args.contrato)
    except (ErrorMapa, OSError, UnicodeError, csv.Error, json.JSONDecodeError) as exc:
        print(f"W05_MAPA FAIL: {exc}", file=sys.stderr)
        return 1
    if not args.detalles:
        resultado.pop("filas")
    print(json.dumps(resultado, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

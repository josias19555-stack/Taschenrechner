#!/usr/bin/env python3
"""Persistent SymPy server for the Lua TI-Nspire test bridge (Emulator/cas_bridge.lua).

Protocol (all files inside <bridge_dir>):
  Lua  writes request_<n>.tmp and renames it to request_<n>.txt  (atomic)
  here: reads it, deletes it, writes response_<n>.tmp -> response_<n>.txt (atomic)
Requests are numbered 1, 2, 3, ... so the server only ever looks for the next file.
Special commands: __RESET__ (clear CAS state), __EXIT__ (stop server).
The server stops by itself when no request arrives for --idle seconds (default 600; cas_bridge.lua uses 120),
so a crashed Lua runner never leaves a python process behind.
"""
from __future__ import annotations

import base64
import os
import sys
import time
from pathlib import Path

import python_cas


def write_response(path: Path, value: str) -> None:
    temporary = path.with_suffix(".tmp")
    temporary.write_text(value, encoding="utf-8")
    for _ in range(200):
        try:
            os.replace(temporary, path)
            return
        except PermissionError:
            time.sleep(0.005)
    os.replace(temporary, path)


def handle(command: str, state: python_cas.CasState) -> str:
    try:
        result = python_cas.evaluate(command, state)
    except Exception as error:  # noqa: BLE001 - every error goes back to Lua
        return "__ERROR__" + str(error).replace("\n", " ")
    if result is None:
        return "__NIL__"
    if isinstance(result, bool):
        return "true" if result else "false"
    if isinstance(result, python_cas.TiString):
        return "__STR__" + result
    if isinstance(result, float):
        return repr(result)
    return str(result)


def main() -> int:
    if len(sys.argv) < 2:
        return 2
    bridge_dir = Path(sys.argv[1])
    idle_limit = float(sys.argv[2]) if len(sys.argv) > 2 else 600.0
    bridge_dir.mkdir(parents=True, exist_ok=True)
    (bridge_dir / "server_ready").write_text("ok", encoding="ascii")
    state = python_cas.CasState()
    sequence = 1
    last_request = time.monotonic()

    while True:
        request_path = bridge_dir / ("request_%d.txt" % sequence)
        if not request_path.exists():
            if time.monotonic() - last_request > idle_limit:
                return 0
            time.sleep(0.0005)
            continue
        last_request = time.monotonic()
        try:
            command = base64.b64decode(request_path.read_bytes()).decode("utf-8")
        except OSError:
            time.sleep(0.001)  # file still locked by the writer, try again
            continue
        request_path.unlink(missing_ok=True)
        response_path = bridge_dir / ("response_%d.txt" % sequence)
        sequence += 1

        if command == "__EXIT__":
            write_response(response_path, "true")
            return 0
        if command == "__RESET__":
            state = python_cas.CasState()
            write_response(response_path, "true")
            continue
        write_response(response_path, handle(command, state))


if __name__ == "__main__":
    raise SystemExit(main())

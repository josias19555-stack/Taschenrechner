#!/usr/bin/env python3
"""File-based persistent SymPy bridge for the Lua TI-Nspire test runner."""
from __future__ import annotations

import base64
import json
import sys
import time
from pathlib import Path

import python_cas


def write_response(path: Path, value: str) -> None:
    temporary = path.with_suffix(".tmp")
    temporary.write_text(value, encoding="utf-8")
    for _ in range(100):
        try:
            temporary.replace(path)
            return
        except PermissionError:
            time.sleep(0.005)
    temporary.replace(path)


def main() -> int:
    if len(sys.argv) != 2:
        return 2
    bridge_dir = Path(sys.argv[1])
    bridge_dir.mkdir(exist_ok=True)
    state = {"vars": {}, "funcs": {}}
    processed = set()

    while True:
        requests = sorted(bridge_dir.glob("request_*.txt"))
        requests = [path for path in requests if path.name not in processed]
        if not requests:
            time.sleep(0.002)
            continue
        request_path = requests[0]
        response_path = bridge_dir / request_path.name.replace("request_", "response_")
        try:
            encoded = request_path.read_text(encoding="ascii")
            processed.add(request_path.name)
            command = base64.b64decode(encoded).decode("utf-8")
            if command == "__EXIT__":
                write_response(response_path, "true")
                return 0
            if command == "__RESET__":
                state = {"vars": {}, "funcs": {}}
                write_response(response_path, "true")
                continue
            result = python_cas.evaluate(command, state)
            if result is None:
                output = "__NIL__"
            elif isinstance(result, bool):
                output = "true" if result else "false"
            else:
                output = str(result)
        except Exception as error:
            output = "__ERROR__" + str(error).replace("\n", " ")
        write_response(response_path, output)


if __name__ == "__main__":
    raise SystemExit(main())

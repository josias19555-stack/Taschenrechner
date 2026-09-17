#!/usr/bin/env python3
"""Small SymPy-backed adapter for the TI-Nspire math.eval subset used by test_runner.lua."""
from __future__ import annotations

import base64
import json
import math
import os
import re
import sys
from pathlib import Path

import sympy as sp
from sympy.parsing.sympy_parser import (
    convert_xor,
    implicit_multiplication_application,
    parse_expr,
    standard_transformations,
)

TRANSFORMATIONS = standard_transformations + (
    convert_xor,
    implicit_multiplication_application,
)


def ti_integral(expression, variable, lower, upper):
    return sp.integrate(expression, (variable, lower, upper))


def load_state(path: Path) -> dict:
    if not path.exists():
        return {"vars": {}, "funcs": {}}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"vars": {}, "funcs": {}}


def save_state(path: Path, state: dict) -> None:
    path.write_text(json.dumps(state, ensure_ascii=True), encoding="utf-8")


def symbol_table(state: dict) -> dict:
    table = {
        "pi": sp.pi,
        "e": sp.E,
        "sqrt": sp.sqrt,
        "sin": sp.sin,
        "cos": sp.cos,
        "tan": sp.tan,
        "asin": sp.asin,
        "acos": sp.acos,
        "atan": sp.atan,
        "exp": sp.exp,
        "ln": sp.log,
        "log": sp.log,
        "abs": sp.Abs,
        "integral": ti_integral,
    }
    for name, value in state["vars"].items():
        table[name] = parse_expression(value, state)
    for name, definition in state["funcs"].items():
        argument = sp.Symbol(definition["arg"])
        table[name] = sp.Lambda(argument, parse_expression(definition["body"], state))
    return table


def parse_expression(text: str, state: dict) -> sp.Expr:
    text = text.strip()
    for wrapper in ("exact", "expand", "approx"):
        nested = unwrap(text, wrapper)
        if nested is not None:
            text = nested.strip()
            break
    text = rewrite_integrals(text)
    matrix_names = {
        name for name, value in state["vars"].items()
        if is_matrix_value(value)
    }
    for name in matrix_names:
        pattern = r"\b" + re.escape(name) + r"\[(\d+),(\d+)\]"
        text = re.sub(
            pattern,
            lambda match: "%s[%d,%d]" % (
                name,
                int(match.group(1)) - 1,
                int(match.group(2)) - 1,
            ),
            text,
        )
    local = symbol_table_without_functions(state)
    return parse_expr(text, local_dict=local, transformations=TRANSFORMATIONS)

def is_matrix_value(value: str) -> bool:
    value = value.strip()
    if value.startswith("exact(") and value.endswith(")"):
        value = value[6:-1].strip()
    return value.startswith("[[") and value.endswith("]]" )

def rewrite_integrals(text: str) -> str:
    """Keep TI-Nspire's integral variable local when it equals a function argument."""
    counter = [0]

    def rewrite_segment(segment: str) -> str:
        result = []
        index = 0
        while index < len(segment):
            start = segment.find("integral(", index)
            if start < 0:
                result.append(segment[index:])
                break
            result.append(segment[index:start])
            depth = 1
            end = start + len("integral(")
            while end < len(segment) and depth:
                depth += segment[end] == "("
                depth -= segment[end] == ")"
                end += 1
            if depth:
                result.append(segment[start:])
                break
            inside = segment[start + len("integral("):end - 1]
            parts = []
            part_start = 0
            nested = 0
            for position, character in enumerate(inside):
                if character == "(": nested += 1
                elif character == ")": nested -= 1
                elif character == "," and nested == 0:
                    parts.append(inside[part_start:position])
                    part_start = position + 1
            parts.append(inside[part_start:])
            if len(parts) != 4:
                result.append("integral(" + rewrite_segment(inside) + ")")
            else:
                counter[0] += 1
                variable = parts[1].strip()
                dummy = "__cas_integral_var_" + str(counter[0])
                integrand = rewrite_segment(parts[0])
                integrand = re.sub(r"\b" + re.escape(variable) + r"\b", dummy, integrand)
                result.append("integral(" + integrand + "," + dummy + "," + parts[2] + "," + parts[3] + ")")
            index = end
        return "".join(result)

    return rewrite_segment(text)


def symbol_table_without_functions(state: dict) -> dict:
    table = {
        "pi": sp.pi,
        "e": sp.E,
        "sqrt": sp.sqrt,
        "sin": sp.sin,
        "cos": sp.cos,
        "tan": sp.tan,
        "asin": sp.asin,
        "acos": sp.acos,
        "atan": sp.atan,
        "exp": sp.exp,
        "ln": sp.log,
        "log": sp.log,
        "abs": sp.Abs,
        "integral": ti_integral,
    }
    for name, value in state["vars"].items():
        if is_matrix_value(value):
            table[name] = parse_matrix(value, state)
        else:
            table[name] = parse_expr(value, local_dict=table, transformations=TRANSFORMATIONS)
    for name, definition in state["funcs"].items():
        argument = sp.Symbol(definition["arg"])
        table[name] = sp.Lambda(
            argument,
            parse_expr(
                rewrite_integrals(definition["body"]),
                local_dict={**table, definition["arg"]: argument},
                transformations=TRANSFORMATIONS,
            ),
        )
    return table


def parse_matrix(text: str, state: dict) -> sp.Matrix:
    """Parse TI-Nspire's adjacent-row matrix syntax [[a,b][c,d]]."""
    text = text.strip()
    if text.startswith("exact(") and text.endswith(")"):
        text = text[6:-1].strip()
    content = text[1:-1]
    scalar_table = {
        "pi": sp.pi, "e": sp.E, "sqrt": sp.sqrt, "sin": sp.sin,
        "cos": sp.cos, "tan": sp.tan, "asin": sp.asin, "acos": sp.acos,
        "atan": sp.atan, "exp": sp.exp, "ln": sp.log, "log": sp.log,
        "abs": sp.Abs, "integral": ti_integral,
    }
    for name, value in state["vars"].items():
        if not is_matrix_value(value):
            scalar_table[name] = parse_expr(value, local_dict=scalar_table, transformations=TRANSFORMATIONS)
    rows = []
    index = 0
    while index < len(content):
        while index < len(content) and content[index].isspace():
            index += 1
        if index >= len(content):
            break
        if content[index] != "[":
            raise ValueError("invalid TI matrix row")
        depth = 1
        end = index + 1
        while end < len(content) and depth:
            if content[end] == "[":
                depth += 1
            elif content[end] == "]":
                depth -= 1
            end += 1
        if depth:
            raise ValueError("unterminated TI matrix row")
        row_text = content[index + 1:end - 1]
        entries = []
        for entry in row_text.split(","):
            entries.append(parse_expr(entry.strip(), local_dict=scalar_table, transformations=TRANSFORMATIONS))
        rows.append(entries)
        index = end
    return sp.Matrix(rows)


def matrix_to_ti(matrix: sp.Matrix) -> str:
    rows = []
    for row in matrix.tolist():
        rows.append("[" + ",".join(sp.sstr(value) for value in row) + "]")
    return "[" + "".join(rows) + "]"


def unwrap(text: str, name: str) -> str | None:
    prefix = name + "("
    if text.startswith(prefix) and text.endswith(")"):
        return text[len(prefix):-1]
    return None


def evaluate(text: str, state: dict):
    text = text.strip()
    if text.startswith("DelVar "):
        for name in text[7:].split(","):
            state["vars"].pop(name.strip(), None)
            state["funcs"].pop(name.strip(), None)
        return True

    function_name, assignment = split_assignment(text)
    if isinstance(function_name, tuple):
        state["funcs"][function_name[0]] = {
            "arg": function_name[1],
            "body": assignment,
        }
        return True
    if assignment is not None:
        try:
            value = parse_expression(assignment, state)
            if isinstance(value, sp.MatrixBase):
                state["vars"][function_name] = matrix_to_ti(value)
            else:
                state["vars"][function_name] = assignment
        except Exception:
            state["vars"][function_name] = assignment
        return True

    inner = unwrap(text, "string")
    if inner is not None:
        value = evaluate_string(inner, state)
        return value

    inner = unwrap(text, "approx")
    if inner is not None:
        expression = parse_expression(inner, state)
        value = sp.integrate(expression) if isinstance(expression, sp.Integral) else expression
        value = sp.N(value)
        return float(value) if not value.free_symbols else value

    return None


def split_assignment(text: str):
    if ":=" not in text:
        return (None, None)
    left, right = text.split(":=", 1)
    left = left.strip()
    right = right.strip()
    if left.endswith(")") and "(" in left:
        name, argument = left[:-1].split("(", 1)
        return ((name.strip(), argument.strip()), right)
    return (left, right)


def evaluate_string(inner: str, state: dict) -> str:
    expression = inner.strip()
    for wrapper in ("exact", "expand", "approx"):
        nested = unwrap(expression, wrapper)
        if nested is not None:
            expression = nested.strip()
    parsed = parse_expression(expression, state)
    if isinstance(parsed, sp.Integral):
        parsed = parsed.doit()
    else:
        parsed = parsed.replace(
            lambda node: isinstance(node, sp.Integral),
            lambda node: node.doit(),
        )
    return sp.sstr(sp.expand(parsed))


def main() -> int:
    if len(sys.argv) != 3:
        print("__NIL__")
        return 2
    state_path = Path(sys.argv[1])
    command = base64.b64decode(sys.argv[2]).decode("utf-8")
    state = load_state(state_path)
    try:
        result = evaluate(command, state)
        save_state(state_path, state)
        if result is None:
            print("__NIL__")
        elif isinstance(result, bool):
            print("true" if result else "false")
        else:
            print(str(result))
        return 0
    except Exception as error:
        save_state(state_path, state)
        print("__ERROR__" + str(error).replace("\n", " "))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

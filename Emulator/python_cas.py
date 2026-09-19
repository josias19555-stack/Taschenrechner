#!/usr/bin/env python3
"""SymPy-backed emulation of the TI-Nspire math.eval subset used by the Lua scripts.

Design goals:
  * TI semantics: names are case-insensitive, `log` is log10, `e`/`pi` are constants,
    multi-letter names (EI, lnc1, q_A) are ONE symbol (never split into E*I).
  * Speed: every definition is parsed/integrated exactly once and stored as a SymPy
    object. Requests only parse their own text; identical requests are cached.
  * TI syntax: `f(x):=...`, `name:=...`, `DelVar a,b`, `Disp "..."`, matrices
    `[[a,b][c,d]]`, `[a,b]`, `[a;b]`, 1-based indexing `m[i,j]`, `colAugment`,
    `integral(expr,var,a,b)`, `approx`, `exact`, `expand`, `string`.
"""
from __future__ import annotations

import base64
import json
import re
import sys
from pathlib import Path

import sympy as sp
from sympy.parsing.sympy_parser import (
    convert_xor,
    implicit_multiplication,
    parse_expr,
    standard_transformations,
)

TRANSFORMATIONS = standard_transformations + (convert_xor, implicit_multiplication)
NAME_RE = re.compile(r"(?<![A-Za-z_])[A-Za-z_][A-Za-z0-9_]*")
INTEGER_RE = re.compile(r"^-?\d+$")


class CasError(Exception):
    pass


class TiString(str):
    """Result of string(...): must reach Lua as a string, even if it looks like a number."""


# --------------------------------------------------------------------------
# TI functions
# --------------------------------------------------------------------------
def _is_matrix(value) -> bool:
    return isinstance(value, sp.MatrixBase)


def ti_integral(expression, variable, lower=None, upper=None):
    if lower is None:
        return sp.integrate(expression, variable)
    return sp.integrate(expression, (variable, lower, upper))


def _rational(value: sp.Float) -> sp.Rational:
    """TI exact(): turn a float into the simplest nearby fraction."""
    exact = sp.Rational(str(value))
    simple = exact.limit_denominator(10 ** 6)
    if exact == 0 or abs(simple - exact) <= abs(exact) * sp.Rational(1, 10 ** 10):
        return simple
    return exact


def ti_exact(value):
    if _is_matrix(value):
        return value.applyfunc(ti_exact)
    value = sp.sympify(value)
    floats = value.atoms(sp.Float)
    if floats:
        value = value.xreplace({f: _rational(f) for f in floats})
    return value


def ti_approx(value):
    if _is_matrix(value):
        return value.applyfunc(ti_approx)
    return sp.N(sp.sympify(value).doit(), 15)


def ti_expand(value):
    if _is_matrix(value):
        return value.applyfunc(ti_expand)
    return sp.expand(sp.sympify(value).doit())


def ti_matrix(rows):
    return sp.Matrix(rows)


def ti_index(matrix, i, j=None):
    """TI indexing is 1-based; a vector m[i] addresses the i-th element."""
    if not _is_matrix(matrix):
        raise CasError("index on non-matrix")
    i = int(i) - 1
    if j is None:
        return matrix[i]
    return matrix[i, int(j) - 1]


def ti_colaugment(a, b):
    return a.col_join(b)


def ti_simult(coeff, const):
    """TI simult(A, b): solve A*x = b (b column matrix), returns column matrix.
    Uses exact fraction-free elimination (DomainMatrix), fast also for sqrt(2)-entries."""
    if not _is_matrix(coeff) or not _is_matrix(const):
        raise CasError("simult expects matrices")
    if coeff.rows != coeff.cols or coeff.rows != const.rows:
        raise CasError("simult: dimension mismatch")
    n = coeff.rows
    try:
        from sympy.polys.matrices import DomainMatrix
        aug = DomainMatrix.from_Matrix(coeff.row_join(const))
        rref, pivots = aug.rref()
        if tuple(pivots[:n]) != tuple(range(n)):
            raise CasError("Singular matrix")
        red = rref.to_Matrix()
        return sp.Matrix([sp.simplify(red[i, n] / red[i, i]) if red[i, i] != 1 else red[i, n] for i in range(n)])
    except CasError:
        raise
    except Exception:
        if coeff.det() == 0:
            raise CasError("Singular matrix")
        return coeff.LUsolve(const)


def ti_rref(matrix):
    return matrix.rref()[0]


def ti_det(matrix):
    return matrix.det()


def ti_log(value, base=10):
    return sp.log(value, base)


def ti_limit(expression, variable, point, direction=None):
    """TI limit(expr, var, point[, dir]): dir > 0 von rechts, < 0 von links, sonst beidseitig.
    Nicht endliche Grenzwerte liefern undef (wie der TI bei beidseitig divergenten Grenzwerten)."""
    if _is_matrix(expression):
        return expression.applyfunc(lambda e: ti_limit(e, variable, point, direction))
    expr = sp.sympify(expression).doit()
    if not expr.has(variable):
        return expr
    result = None
    try:
        # rationale Funktion: kuerzen und einsetzen, wenn der Nenner im Punkt nicht verschwindet
        num, den = sp.fraction(sp.cancel(sp.together(expr)))
        d0 = sp.expand(den.subs(variable, point))
        if d0 != 0:
            result = sp.expand(num.subs(variable, point)) / d0
    except Exception:
        result = None
    if result is None:
        side = "+-" if direction is None else ("+" if direction > 0 else "-")
        try:
            result = sp.limit(expr, variable, point, dir=side)
        except (ValueError, NotImplementedError):   # links != rechts
            return sp.Symbol("undef")
    if result.has(sp.oo, -sp.oo, sp.zoo, sp.nan) or result is sp.nan:
        return sp.Symbol("undef")
    return result


BUILTINS = {
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
    "log": ti_log,
    "abs": sp.Abs,
    "sign": sp.sign,
    "max": sp.Max,
    "min": sp.Min,
    "floor": sp.floor,
    "integral": ti_integral,
    "exact": ti_exact,
    "approx": ti_approx,
    "expand": ti_expand,
    "colaugment": ti_colaugment,
    "simult": ti_simult,
    "rref": ti_rref,
    "det": ti_det,
    "limit": ti_limit,
    "__mat": ti_matrix,
    "__idx": ti_index,
}


# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------
class TiFunction:
    """User function f(x):=body. The body is parsed once; names that were still
    undefined at definition time are bound at call time (TI behaviour)."""

    def __init__(self, name: str, argument: sp.Symbol, body, state: "CasState"):
        self.name = name
        self.argument = argument
        self.body = body
        self.state = state

    def __call__(self, value):
        return self.state.bind_late(self.body.subs(self.argument, value))


class CasState:
    def __init__(self):
        self.values: dict[str, object] = {}
        self.functions: dict[str, TiFunction] = {}
        self.version = 0
        self._cache: dict[tuple[int, str], object] = {}

    # -- bookkeeping ----------------------------------------------------------
    def changed(self):
        self.version += 1
        self._cache.clear()

    def delete(self, name: str):
        self.values.pop(name, None)
        self.functions.pop(name, None)
        self.changed()

    def bind_late(self, expression):
        if not hasattr(expression, "free_symbols"):
            return expression
        mapping = {s: self.values[s.name] for s in expression.free_symbols if s.name in self.values}
        if not mapping:
            return expression
        return expression.subs(mapping)

    def namespace(self, text: str, extra: dict | None = None) -> dict:
        table = {}
        for name in set(NAME_RE.findall(text)):
            if extra and name in extra:
                table[name] = extra[name]
            elif name in self.functions:
                table[name] = self.functions[name]
            elif name in self.values:
                table[name] = self.values[name]
            elif name in BUILTINS:
                table[name] = BUILTINS[name]
            else:
                table[name] = sp.Symbol(name)
        return table

    # -- parsing -------------------------------------------------------------
    def parse(self, text: str, extra: dict | None = None):
        prepared = prepare(text)
        try:
            return parse_expr(prepared, local_dict=self.namespace(prepared, extra),
                              transformations=TRANSFORMATIONS, evaluate=True)
        except CasError:
            raise
        except Exception as error:  # noqa: BLE001 - report TI-like
            raise CasError("%s in '%s'" % (error, text)) from None

    def cached_parse(self, text: str):
        key = (self.version, text)
        if key not in self._cache:
            self._cache[key] = self.parse(text)
        return self._cache[key]


# --------------------------------------------------------------------------
# Text preprocessing (TI syntax -> SymPy syntax)
# --------------------------------------------------------------------------
def _split_top(text: str, separator: str) -> list[str]:
    parts, depth, start = [], 0, 0
    for position, character in enumerate(text):
        if character in "([":
            depth += 1
        elif character in ")]":
            depth -= 1
        elif character == separator and depth == 0:
            parts.append(text[start:position])
            start = position + 1
    parts.append(text[start:])
    return parts


def _matching(text: str, start: int, open_char: str, close_char: str) -> int:
    depth = 0
    for position in range(start, len(text)):
        if text[position] == open_char:
            depth += 1
        elif text[position] == close_char:
            depth -= 1
            if depth == 0:
                return position
    raise CasError("unbalanced '%s' in '%s'" % (open_char, text))


def _convert_brackets(text: str) -> str:
    """Rewrite TI matrix literals and 1-based indexing."""
    out: list[str] = []
    position = 0
    while position < len(text):
        character = text[position]
        if character != "[":
            out.append(character)
            position += 1
            continue
        end = _matching(text, position, "[", "]")
        inner = text[position + 1:end]
        previous = "".join(out).rstrip()
        if previous and (previous[-1].isalnum() or previous[-1] in "_)"):
            # indexing: operand is the identifier or parenthesised group before '['
            if previous[-1] == ")":
                depth, cut = 0, len(previous) - 1
                while cut >= 0:
                    if previous[cut] == ")":
                        depth += 1
                    elif previous[cut] == "(":
                        depth -= 1
                        if depth == 0:
                            break
                    cut -= 1
            else:
                cut = len(previous)
                while cut > 0 and (previous[cut - 1].isalnum() or previous[cut - 1] == "_"):
                    cut -= 1
            operand = previous[cut:]
            indices = ",".join(_convert_brackets(part) for part in _split_top(inner, ","))
            out = list(previous[:cut] + "__idx(" + operand + "," + indices + ")")
        else:
            out.append(_matrix_literal(inner))
        position = end + 1
    return "".join(out)


def _matrix_literal(inner: str) -> str:
    inner = inner.strip()
    if inner.startswith("["):
        rows, position = [], 0
        while position < len(inner):
            if inner[position].isspace() or inner[position] == ",":
                position += 1
                continue
            if inner[position] != "[":
                raise CasError("invalid TI matrix '%s'" % inner)
            end = _matching(inner, position, "[", "]")
            rows.append(_split_top(inner[position + 1:end], ","))
            position = end + 1
    else:
        rows = [_split_top(row, ",") for row in _split_top(inner, ";")]  # [a,b] Zeile, [a;b] Spalte
    body = ",".join("[" + ",".join(_convert_brackets(cell.strip()) for cell in row) + "]" for row in rows)
    return "__mat([" + body + "])"


def _rewrite_integrals(text: str) -> str:
    """integral(f,x,a,b) with x also used outside: give the integration variable a private name."""
    counter = [0]

    def rewrite(segment: str) -> str:
        result, index = [], 0
        while True:
            start = segment.find("integral(", index)
            if start < 0 or (start > 0 and (segment[start - 1].isalnum() or segment[start - 1] == "_")):
                if start < 0:
                    result.append(segment[index:])
                    return "".join(result)
                result.append(segment[index:start + 9])
                index = start + 9
                continue
            result.append(segment[index:start])
            end = _matching(segment, start + 8, "(", ")")
            parts = _split_top(segment[start + 9:end], ",")
            if len(parts) == 4:
                counter[0] += 1
                variable = parts[1].strip()
                dummy = "__iv%d" % counter[0]
                integrand = re.sub(r"(?<![A-Za-z0-9_])" + re.escape(variable) + r"(?![A-Za-z0-9_])", dummy, rewrite(parts[0]))
                result.append("integral(%s,%s,%s,%s)" % (integrand, dummy, rewrite(parts[2]), rewrite(parts[3])))
            else:
                result.append("integral(" + ",".join(rewrite(p) for p in parts) + ")")
            index = end + 1

    return rewrite(text)


def prepare(text: str) -> str:
    text = text.strip().lower()
    for old, new in (("−", "-"), ("·", "*"), ("≤", "<="), ("≥", ">=")):
        text = text.replace(old, new)
    text = _rewrite_integrals(text)
    return _convert_brackets(text)


# --------------------------------------------------------------------------
# Output (TI-like)
# --------------------------------------------------------------------------
def to_ti_string(value) -> str:
    if _is_matrix(value):
        return "[" + "".join("[" + ",".join(to_ti_string(v) for v in row) + "]" for row in value.tolist()) + "]"
    return sp.sstr(value).replace("**", "^")


def to_result(value):
    """Value returned to Lua: numbers as float, everything else as TI string."""
    if isinstance(value, bool):
        return value
    if _is_matrix(value):
        return to_ti_string(value)
    value = sp.sympify(value)
    if value.is_number:
        number = sp.N(value)
        if number.is_real:
            return float(number)
    return to_ti_string(value)


# --------------------------------------------------------------------------
# Entry point
# --------------------------------------------------------------------------
def split_assignment(text: str):
    if ":=" not in text:
        return None, None, None
    left, right = text.split(":=", 1)
    left = left.strip().lower()
    match = re.fullmatch(r"([a-z_][a-z0-9_]*)\s*\(\s*([a-z_][a-z0-9_]*)\s*\)", left)
    if match:
        return match.group(1), match.group(2), right.strip()
    if re.fullmatch(r"[a-z_][a-z0-9_]*", left):
        return left, None, right.strip()
    raise CasError("invalid assignment target '%s'" % left)


def _unwrap(text: str, name: str):
    prefix = name + "("
    if text.lower().startswith(prefix) and text.endswith(")"):
        if _matching(text, len(name), "(", ")") == len(text) - 1:
            return text[len(prefix):-1]
    return None


def evaluate(text: str, state: CasState):
    text = text.strip()
    lowered = text.lower()
    if lowered.startswith("delvar "):
        for name in text[7:].split(","):
            state.delete(name.strip().lower())
        return True
    if lowered.startswith("disp "):
        return None

    name, argument, body = split_assignment(text)
    if name is not None:
        if argument is None and body.lstrip()[:1] in ("{", "[") and '"' in body:
            # Liste oder Vektor von Strings (z. B. randbed, lgs): unveraendert als Text speichern
            state.values[name] = TiString(body.strip())
            state.functions.pop(name, None)
            state.changed()
            return True
        if argument is not None:
            symbol = sp.Symbol(argument)
            parsed = state.parse(body, extra={argument: symbol})
            state.functions[name] = TiFunction(name, symbol, parsed, state)
            state.values.pop(name, None)
        else:
            state.values[name] = state.parse(body)
            state.functions.pop(name, None)
        state.changed()
        return True

    inner = _unwrap(text, "string")
    if inner is not None:
        direct = state.values.get(inner.strip().lower())
        if isinstance(direct, TiString):
            return direct
        value = state.cached_parse(inner)
        if not _is_matrix(value):
            value = sp.sympify(value).doit()
        return TiString(to_ti_string(value))

    value = state.cached_parse(text)
    if not _is_matrix(value):
        value = sp.sympify(value).doit()
    return to_result(value)


def main() -> int:
    """One-shot CLI: python_cas.py "<expression>" (base64 or plain)."""
    if len(sys.argv) < 2:
        print("usage: python_cas.py <command> [...]")
        return 2
    state = CasState()
    for command in sys.argv[1:]:
        try:
            print(evaluate(command, state))
        except Exception as error:  # noqa: BLE001
            print("__ERROR__" + str(error).replace("\n", " "))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

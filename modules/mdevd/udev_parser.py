from __future__ import annotations

import ctypes
import os
import threading
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class Clause:
    key: str
    attribute: str | None
    operator: str
    value: str


class UdevParseError(ValueError):
    pass

_LANGUAGE_CACHE: dict[str, tuple[ctypes.CDLL, Any]] = {}
_LANGUAGE_LOCK = threading.RLock()


def _language(grammar_path: str | os.PathLike[str]) -> Any:
    path = os.path.realpath(os.fspath(grammar_path))
    with _LANGUAGE_LOCK:
        cached = _LANGUAGE_CACHE.get(path)
        if cached is not None:
            return cached[1]

        library = ctypes.CDLL(path)
        try:
            language_function = library.tree_sitter_udev
        except AttributeError as exc:
            raise RuntimeError(
                f"{path}: shared library does not export tree_sitter_udev"
            ) from exc
        language_function.argtypes = ()
        language_function.restype = ctypes.c_void_p
        pointer = language_function()
        if not pointer:
            raise RuntimeError(f"{path}: tree_sitter_udev returned a null language")

        capsule_new = ctypes.pythonapi.PyCapsule_New
        capsule_new.argtypes = (ctypes.c_void_p, ctypes.c_char_p, ctypes.c_void_p)
        capsule_new.restype = ctypes.py_object
        capsule = capsule_new(pointer, b"tree_sitter.Language", None)

        try:
            from tree_sitter import Language

            language = Language(capsule)
        except ImportError as exc:
            raise RuntimeError(
                "tree_sitter (modern 0.25+) is required to parse udev rules"
            ) from exc

        _LANGUAGE_CACHE[path] = (library, language)
        return language


def _line(path: str, node: Any) -> int:
    try:
        return int(node.start_point[0]) + 1
    except (AttributeError, IndexError, TypeError):
        return 1


def _fail(path: str, node: Any, message: str) -> UdevParseError:
    return UdevParseError(f"{path}:{_line(path, node)}: {message}")


def _node_text(source: bytes, node: Any) -> str:
    text = getattr(node, "text", None)
    if text is None:
        text = source[node.start_byte : node.end_byte]
    if isinstance(text, str):
        return text
    return bytes(text).decode("utf-8")


def _validate_tree(path: str, root: Any) -> None:
    stack = [root]
    while stack:
        node = stack.pop()
        if getattr(node, "is_error", False):
            raise _fail(path, node, "syntax error")
        if getattr(node, "is_missing", False):
            raise _fail(path, node, f"missing syntax node {node.type!r}")
        stack.extend(getattr(node, "children", ()))


def _decode_value(path: str, node: Any, source: bytes) -> str:
    raw = _node_text(source, node)
    if raw.startswith("e\""):
        raise _fail(path, node, "C-escaped string values (e\"...\") are unsupported")
    if len(raw) < 2 or raw[0] != '"' or raw[-1] != '"':
        raise _fail(path, node, "value node is not a quoted string")

    inner = raw[1:-1]
    result: list[str] = []
    index = 0
    while index < len(inner):
        character = inner[index]
        if character == "\\":
            if index + 1 < len(inner) and inner[index + 1] == "\n":
                index += 2
                continue
            if index + 1 < len(inner) and inner[index + 1] == '"':
                result.append('"')
                index += 2
                continue
        result.append(character)
        index += 1
    return "".join(result)


def _clause(path: str, source: bytes, node: Any) -> Clause:
    if node.type not in {"match", "assignment"}:
        raise _fail(path, node, f"unexpected rule node {node.type!r}")

    key_node = node.child_by_field_name("key")
    value_nodes = [child for child in node.named_children if child.type == "value"]
    attribute_nodes = [
        child for child in node.named_children if child.type == "attribute"
    ]
    value_node = value_nodes[0] if len(value_nodes) == 1 else None
    attribute_node = attribute_nodes[0] if len(attribute_nodes) == 1 else None
    if key_node is None:
        raise _fail(path, node, "rule clause has no key node")
    if value_node is None:
        raise _fail(path, node, "rule clause has no value node")

    operators = [
        child
        for child in node.children
        if child.type in {"match_op", "assignment_op"}
    ]
    if len(operators) != 1:
        raise _fail(path, node, "rule clause has no unique operator node")

    key = _node_text(source, key_node)
    attribute = None if attribute_node is None else _node_text(source, attribute_node)
    operator = _node_text(source, operators[0])
    value = _decode_value(path, value_node, source)
    return Clause(key=key, attribute=attribute, operator=operator, value=value)


def parse_rules(
    source_path: str | os.PathLike[str],
    grammar_path: str | os.PathLike[str],
) -> list[list[Clause]]:
    path = os.fspath(source_path)
    display_path = os.fsdecode(path)
    try:
        source = Path(path).read_bytes()
    except OSError as exc:
        raise OSError(f"{display_path}: {exc}") from exc

    try:
        source.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise UdevParseError(
            f"{display_path}:{exc.start + 1}: source is not valid UTF-8"
        ) from exc

    if source and not source.endswith(b"\n"):
        source += b"\n"

    try:
        from tree_sitter import Parser
    except ImportError as exc:
        raise RuntimeError(
            "tree_sitter (modern 0.25+) is required to parse udev rules"
        ) from exc

    language = _language(grammar_path)
    parser = Parser(language)
    tree = parser.parse(source)
    root = tree.root_node
    _validate_tree(display_path, root)

    rules: list[list[Clause]] = []
    for child in root.named_children:
        if child.type == "comment":
            continue
        if child.type != "rule":
            raise _fail(display_path, child, f"unexpected top-level node {child.type!r}")
        clauses: list[Clause] = []
        for clause_node in child.named_children:
            clauses.append(_clause(display_path, source, clause_node))
        if not clauses:
            raise _fail(display_path, child, "rule contains no clauses")
        rules.append(clauses)
    return rules


__all__ = ["Clause", "UdevParseError", "parse_rules"]

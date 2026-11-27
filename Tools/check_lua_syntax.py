"""Compile Lua files with the Lua 5.4 runtime used by the test harness."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from lupa.lua54 import LuaRuntime
except ImportError as exc:  # pragma: no cover - environment failure
    raise SystemExit("lupa with Lua 5.4 support is required") from exc


def lua_files(root: Path) -> list[Path]:
    excluded = {".git", "References", "__pycache__", "node_modules"}
    return sorted(
        path
        for path in root.rglob("*.lua")
        if not any(part in excluded for part in path.relative_to(root).parts)
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    root = args.root.resolve()
    runtime = LuaRuntime(unpack_returned_tuples=True)
    compile_lua = runtime.eval("load")
    failures: list[str] = []
    files = lua_files(root)
    for path in files:
        source = path.read_text(encoding="utf-8-sig")
        result = compile_lua(source, f"@{path}", "t")
        if isinstance(result, tuple):
            chunk, error = result
        else:
            chunk, error = result, None
        if chunk is None:
            failures.append(f"{path.relative_to(root)}: {error}")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print(f"PASS Lua 5.4 compile ({len(files)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


#!/usr/bin/env python3
"""Install, inspect, or remove skill-scout's Claude SessionStart hook."""

from __future__ import annotations

import argparse
import difflib
import json
import os
import sys
import tempfile
from pathlib import Path

MARKER = "skill-scout/scripts/session-start.sh"
COMMAND = (
    "sh -c 'p=\"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/skill-scout/scripts/"
    "session-start.sh\"; [ -x \"$p\" ] && \"$p\" || true'"
)
HOOK = {
    "matcher": "startup|resume|compact",
    "hooks": [{"type": "command", "command": COMMAND}],
}


def settings_path() -> Path:
    base = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude")).expanduser()
    return base / "settings.json"


def load_settings(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ValueError(f"{path} is not valid JSON: {error}") from error
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def is_skill_scout(entry) -> bool:
    return isinstance(entry, dict) and any(
        isinstance(hook, dict) and MARKER in str(hook.get("command", ""))
        for hook in entry.get("hooks", [])
    )


def install(settings: dict) -> tuple[dict, bool]:
    hooks = settings.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise ValueError("hooks must be an object")
    session = hooks.setdefault("SessionStart", [])
    if not isinstance(session, list):
        raise ValueError("hooks.SessionStart must be an array")
    existing = [entry for entry in session if is_skill_scout(entry)]
    changed = existing != [HOOK]
    session[:] = [entry for entry in session if not is_skill_scout(entry)] + [HOOK]
    return settings, changed


def remove(settings: dict) -> tuple[dict, bool]:
    hooks = settings.get("hooks", {})
    if not isinstance(hooks, dict):
        raise ValueError("hooks must be an object")
    session = hooks.get("SessionStart", [])
    if not isinstance(session, list):
        raise ValueError("hooks.SessionStart must be an array")
    filtered = [entry for entry in session if not is_skill_scout(entry)]
    changed = len(filtered) != len(session)
    if changed:
        if filtered:
            hooks["SessionStart"] = filtered
        else:
            hooks.pop("SessionStart", None)
        if not hooks:
            settings.pop("hooks", None)
    return settings, changed


def render(settings: dict) -> str:
    return json.dumps(settings, indent=2) + "\n"


def write_atomic(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent, text=True)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(text)
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument("--install", action="store_true")
    actions.add_argument("--remove", action="store_true")
    actions.add_argument("--check", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    path = settings_path()
    try:
        settings = load_settings(path)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    hooks = settings.get("hooks", {})
    if not isinstance(hooks, dict):
        print("error: hooks must be an object", file=sys.stderr)
        return 2
    session_hooks = hooks.get("SessionStart", [])
    if not isinstance(session_hooks, list):
        print("error: hooks.SessionStart must be an array", file=sys.stderr)
        return 2
    present = any(is_skill_scout(entry) for entry in session_hooks)
    if args.check or not (args.install or args.remove):
        print(f"skill-scout SessionStart hook: {'installed' if present else 'not installed'} ({path})")
        return 0 if present else 1

    before = render(settings)
    try:
        settings, changed = remove(settings) if args.remove else install(settings)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    after = render(settings)
    if args.dry_run:
        print("".join(difflib.unified_diff(before.splitlines(True), after.splitlines(True), "settings.json", "settings.json")), end="")
        return 0
    if changed:
        write_atomic(path, after)
    action = "removed" if args.remove else "installed"
    print(f"skill-scout SessionStart hook {action if changed else 'already current'} ({path})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Deterministic operations for the skill-scout Markdown notebook."""

from __future__ import annotations

import argparse
import contextlib
import datetime as dt
import fcntl
import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

HEADING = "# Skill ideas"
ENTRY_RE = re.compile(
    r"^- \[(?P<checked>[ xX])\] `(?P<date>\d{4}-\d{2}-\d{2})` "
    r"`(?P<repo>[^`]+)` `(?P<tag>#[^`]+)` — (?P<text>.*?)(?: "
    r"<!-- scout:session=(?P<session>[A-Za-z0-9_-]+) -->)?$"
)
TAG_RE = re.compile(
    r"^(?:#[a-z0-9][a-z0-9-]*|#waste/[a-z0-9][a-z0-9-]*|"
    r"#skill:[a-z0-9][a-z0-9-]*/(?:description|body))$"
)
STATE_RE = re.compile(r"^- `(?P<tag>#[^`]+)` (?P<rest>.+)$")
SESSION_META_RE = re.compile(r"( <!-- scout:session=[A-Za-z0-9_-]+ -->)$")
SECRET_PATTERNS = (
    (re.compile(r"(?i)\b(api[_-]?key|token|secret|password)\s*[:=]\s*[^\s,;]+"), r"\1=[REDACTED]"),
    (re.compile(r"(?i)\bBearer\s+[A-Za-z0-9._~+/-]+"), "Bearer [REDACTED]"),
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----.*", re.DOTALL), "[REDACTED PRIVATE KEY]"),
)


def global_path() -> Path:
    if value := os.environ.get("SKILL_SCOUT_LOG"):
        return Path(value).expanduser()
    if value := os.environ.get("SKILL_SCOUT_HOME"):
        return Path(value).expanduser() / "skill-ideas.md"
    base = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude")).expanduser()
    return base / "skill-ideas.md"


def archive_path(path: Path | None = None) -> Path:
    source = path or global_path()
    return source.with_name("skill-ideas-archive.md")


def repo_root(cwd: Path) -> Path | None:
    result = subprocess.run(
        ["git", "-C", str(cwd), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=False,
    )
    return Path(result.stdout.strip()) if result.returncode == 0 else None


def local_path(cwd: Path) -> Path | None:
    root = repo_root(cwd)
    if root is None:
        return None
    context = root / ".context"
    if context.is_dir():
        return context / "skill-ideas.md"
    claude = root / ".claude"
    candidate = claude / "skill-ideas.md"
    if not claude.is_dir():
        return None
    ignored = subprocess.run(
        ["git", "-C", str(root), "check-ignore", "-q", "--", ".claude/skill-ideas.md"],
        check=False,
    )
    return candidate if ignored.returncode == 0 else None


def sanitize(text: str, limit: int = 600) -> str:
    text = re.sub(r"\s+", " ", text).strip().replace("<!--", "< !--")
    for pattern, replacement in SECRET_PATTERNS:
        text = pattern.sub(replacement, text)
    if len(text) > limit:
        text = text[: limit - 1].rstrip() + "…"
    return text


def validate_tag(tag: str) -> str:
    tag = tag.strip().lower()
    if not TAG_RE.fullmatch(tag):
        raise ValueError(
            "tag must be #kebab-case, #waste/kebab-case, or "
            "#skill:<name>/description|body"
        )
    return tag


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def write_atomic(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent, text=True)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(text)
        os.chmod(temp_name, mode)
        os.replace(temp_name, path)
    finally:
        with contextlib.suppress(FileNotFoundError):
            os.unlink(temp_name)


@contextlib.contextmanager
def notebook_lock(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    lock = path.parent / f".{path.name}.lock"
    with lock.open("a", encoding="utf-8") as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        yield


def insert_entry(text: str, line: str) -> str:
    lines = text.splitlines()
    if not lines:
        return f"{HEADING}\n\n{line}\n"
    if lines[0] != HEADING:
        lines = [HEADING, ""] + lines
    state_at = next(
        (index for index, value in enumerate(lines) if value in {"## Shipped", "## Declined"}),
        len(lines),
    )
    while state_at > 0 and not lines[state_at - 1].strip():
        state_at -= 1
    lines[state_at:state_at] = [line, ""]
    return "\n".join(lines).rstrip() + "\n"


def parse_entries(text: str, source: Path | None = None) -> list[dict]:
    entries = []
    for line in text.splitlines():
        match = ENTRY_RE.match(line)
        if not match:
            continue
        entry = match.groupdict()
        entry["checked"] = entry["checked"].lower() == "x"
        entry["line"] = line
        entry["source"] = str(source) if source else ""
        entries.append(entry)
    return entries


def parse_states(text: str) -> dict[str, dict[str, str]]:
    states: dict[str, dict[str, str]] = {"Shipped": {}, "Declined": {}}
    section = ""
    for line in text.splitlines():
        if line in {"## Shipped", "## Declined"}:
            section = line[3:]
            continue
        if line.startswith("## "):
            section = ""
            continue
        if section and (match := STATE_RE.match(line)):
            states[section][match.group("tag")] = match.group("rest")
    return states


def all_entries(path: Path) -> list[dict]:
    archive = archive_path(path)
    return parse_entries(read_text(path), path) + parse_entries(read_text(archive), archive)


def entry_parts(values: list[str]) -> tuple[str, str]:
    if not values:
        raise ValueError("entry is required")
    if len(values) > 1 and values[0].startswith("#"):
        return values[0], " ".join(values[1:]).removeprefix("—").strip()
    joined = " ".join(values)
    match = re.match(r"^(#[^\s]+)\s+(?:—|--)\s+(.+)$", joined)
    if not match:
        raise ValueError("use: log.sh '#tag — what happened; measured cost; Fix: remedy'")
    return match.group(1), match.group(2)


def current_repo(cwd: Path) -> str:
    root = repo_root(cwd)
    return (root or cwd).name


def log_entry(args: argparse.Namespace) -> int:
    try:
        raw_tag, raw_text = entry_parts(args.entry)
        tag = validate_tag(args.tag or raw_tag)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    body = sanitize(raw_text)
    if not body:
        print("error: entry text is empty", file=sys.stderr)
        return 2
    cwd = Path(args.cwd).expanduser().resolve()
    date = args.date or dt.date.today().isoformat()
    try:
        dt.date.fromisoformat(date)
    except ValueError:
        print("error: date must be YYYY-MM-DD", file=sys.stderr)
        return 2
    repo = sanitize(args.repo or current_repo(cwd), 80).replace("`", "'")
    session = args.session or os.environ.get("SKILL_SCOUT_SESSION_ID", "")
    metadata = f" <!-- scout:session={session} -->" if re.fullmatch(r"[A-Za-z0-9_-]+", session) else ""
    line = f"- [ ] `{date}` `{repo}` `{tag}` — {body}{metadata}"
    path = global_path()
    local = local_path(cwd)
    with notebook_lock(path):
        existing = all_entries(path)
        duplicate = any(
            entry["date"] == date
            and entry["repo"] == repo
            and entry["tag"] == tag
            and entry["text"] == body
            and (not session or entry["session"] == session)
            for entry in existing
        )
        if duplicate:
            print(f"duplicate: {tag}")
            return 0
        write_atomic(path, insert_entry(read_text(path), line))
        if local:
            try:
                write_atomic(local, insert_entry(read_text(local), line))
            except OSError as error:
                print(f"warning: global entry saved; workspace mirror failed: {error}", file=sys.stderr)
                local = None
    print(f"logged {tag} -> {path}" + (f" + {local}" if local else ""))
    return 0


def cost_totals(entries: list[dict]) -> dict[str, int]:
    totals: dict[str, int] = defaultdict(int)
    pattern = re.compile(r"(?i)(\d[\d,]*)\s+(tool calls?|greps?|reads?|lines?|turns?|retries|sessions?)\b")
    for entry in entries:
        for number, unit in pattern.findall(entry["text"]):
            key = unit.lower().removesuffix("s")
            totals[key] += int(number.replace(",", ""))
    return dict(sorted(totals.items()))


def notebook_summary(path: Path) -> dict:
    entries = all_entries(path)
    states = parse_states(read_text(path))
    groups: dict[str, dict] = {}
    for tag in sorted({entry["tag"] for entry in entries}):
        matching = [entry for entry in entries if entry["tag"] == tag]
        dates = sorted(entry["date"] for entry in matching)
        shipped = states["Shipped"].get(tag, "")
        shipped_date = next(iter(re.findall(r"\d{4}-\d{2}-\d{2}", shipped)), "")
        groups[tag] = {
            "entries": len(matching),
            "pending": sum(not entry["checked"] for entry in matching),
            "repos": sorted({entry["repo"] for entry in matching}),
            "oldest": dates[0],
            "newest": dates[-1],
            "costs": cost_totals(matching),
            "shipped": shipped,
            "declined": states["Declined"].get(tag, ""),
            "regressions": sum(bool(shipped_date and entry["date"] > shipped_date) for entry in matching),
        }
    pending_entries = [entry for entry in entries if not entry["checked"] and entry["source"] == str(path)]
    oldest = min((entry["date"] for entry in pending_entries), default="")
    age = (dt.date.today() - dt.date.fromisoformat(oldest)).days if oldest else 0
    return {
        "path": str(path),
        "archive": str(archive_path(path)),
        "pending": len(pending_entries),
        "oldest_pending": oldest,
        "oldest_pending_days": age,
        "harvest_due": len(pending_entries) >= 8 or age > 30,
        "groups": groups,
    }


def active_status(path: Path) -> dict:
    """Return the cheap subset needed by SessionStart; never read the archive."""
    entries = parse_entries(read_text(path), path)
    pending = [entry for entry in entries if not entry["checked"]]
    oldest = min((entry["date"] for entry in pending), default="")
    age = (dt.date.today() - dt.date.fromisoformat(oldest)).days if oldest else 0
    return {
        "pending": len(pending),
        "oldest_pending_days": age,
        "harvest_due": len(pending) >= 8 or age > 30,
        "open_tags": sorted({entry["tag"] for entry in pending}),
    }


def print_summary(args: argparse.Namespace) -> int:
    summary = notebook_summary(global_path())
    if args.json:
        print(json.dumps(summary, indent=2, sort_keys=True))
        return 0
    due = "yes" if summary["harvest_due"] else "no"
    print(
        f"Pending: {summary['pending']} | oldest: {summary['oldest_pending'] or '-'} "
        f"({summary['oldest_pending_days']}d) | harvest due: {due}"
    )
    for tag, group in summary["groups"].items():
        state = (
            f"shipped {group['shipped']}"
            if group["shipped"]
            else f"declined {group['declined']}"
            if group["declined"]
            else "open"
        )
        regression = f" | regressions: {group['regressions']}" if group["regressions"] else ""
        costs = ", ".join(f"{value} {unit}" for unit, value in group["costs"].items()) or "unmeasured"
        print(
            f"{tag} | {group['entries']} entries | {len(group['repos'])} repos | "
            f"{group['oldest']}..{group['newest']} | {costs} | {state}{regression}"
        )
    return 0


def show_entries(args: argparse.Namespace) -> int:
    try:
        tag = validate_tag(args.tag)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    matching = [entry for entry in all_entries(global_path()) if entry["tag"] == tag]
    for entry in matching:
        print(entry["line"])
    return 0 if matching else 1


def replace_tag_lines(text: str, tags: set[str], transform) -> tuple[str, int]:
    changed = 0
    output = []
    for line in text.splitlines():
        match = ENTRY_RE.match(line)
        if match and match.group("tag") in tags:
            new_line = transform(line, match)
            changed += new_line != line
            line = new_line
        output.append(line)
    return "\n".join(output).rstrip() + ("\n" if output else ""), changed


def archive_checked(path: Path, threshold: int) -> int:
    text = read_text(path)
    lines = text.splitlines()
    checked = [line for line in lines if (match := ENTRY_RE.match(line)) and match.group("checked").lower() == "x"]
    if len(checked) <= threshold:
        return 0
    kept = [line for line in lines if line not in checked]
    destination = archive_path(path)
    archive_text = read_text(destination)
    for line in checked:
        if line not in archive_text.splitlines():
            archive_text = insert_entry(archive_text, line)
    write_atomic(path, "\n".join(kept).rstrip() + "\n")
    write_atomic(destination, archive_text)
    return len(checked)


def review_entries(args: argparse.Namespace) -> int:
    try:
        tags = {validate_tag(tag) for tag in args.tags}
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    path = global_path()
    cwd = Path(args.cwd).expanduser().resolve()
    local = local_path(cwd)
    total = 0
    with notebook_lock(path):
        for target in filter(None, [path, local]):
            updated, changed = replace_tag_lines(
                read_text(target),
                tags,
                lambda line, match: line.replace("- [ ]", "- [x]", 1),
            )
            if changed:
                write_atomic(target, updated)
            if target == path:
                total = changed
        archived = archive_checked(path, args.archive_threshold)
        if local and local.exists():
            archive_checked(local, 0 if archived else args.archive_threshold)
    print(f"reviewed {total} entries" + (f"; archived {archived}" if archived else ""))
    return 0


def add_state_record(text: str, section: str, tag: str, rest: str) -> str:
    lines = text.splitlines() or [HEADING]
    header = f"## {section}"
    other = "## Declined" if section == "Shipped" else ""
    filtered = []
    active = ""
    for line in lines:
        if line in {"## Shipped", "## Declined"}:
            active = line[3:]
        match = STATE_RE.match(line)
        if active == section and match and match.group("tag") == tag:
            continue
        filtered.append(line)
    lines = filtered
    if header not in lines:
        insert_at = lines.index(other) if other and other in lines else len(lines)
        while insert_at > 0 and not lines[insert_at - 1].strip():
            insert_at -= 1
        lines[insert_at:insert_at] = ["", header]
    index = lines.index(header) + 1
    lines.insert(index, f"- `{tag}` {rest}")
    return "\n".join(lines).rstrip() + "\n"


def annotate_line(line: str, annotation: str) -> str:
    match = SESSION_META_RE.search(line)
    if match:
        return line[: match.start()] + annotation + match.group(1)
    return line + annotation


def state_change(args: argparse.Namespace, section: str) -> int:
    try:
        tag = validate_tag(args.tag)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    date = args.date or dt.date.today().isoformat()
    detail = sanitize(args.artifact if section == "Shipped" else args.reason, 240)
    if not detail:
        print("error: artifact/reason is required", file=sys.stderr)
        return 2
    path = global_path()
    cwd = Path(args.cwd).expanduser().resolve()
    local = local_path(cwd)
    annotation = f" ✓ {detail} {date}" if section == "Shipped" else ""
    rest = f"→ {detail}, {date}" if section == "Shipped" else f"— {date}: {detail}"
    changed = 0
    with notebook_lock(path):
        targets = [path, archive_path(path)]
        if local:
            targets.extend([local, archive_path(local)])
        for target in targets:
            if not target.exists() and target != path and target != local:
                continue
            text = read_text(target)
            if annotation:
                text, count = replace_tag_lines(
                    text,
                    {tag},
                    lambda line, match: line if f" ✓ {detail} {date}" in line else annotate_line(line, annotation),
                )
                changed += count
            if target in {path, local}:
                text = add_state_record(text, section, tag, rest)
            write_atomic(target, text)
    print(f"{section.lower()} {tag}; updated {changed} entries")
    return 0


def archive_command(args: argparse.Namespace) -> int:
    path = global_path()
    cwd = Path(args.cwd).expanduser().resolve()
    local = local_path(cwd)
    with notebook_lock(path):
        moved = archive_checked(path, args.threshold)
        if local and local.exists():
            archive_checked(local, 0 if moved else args.threshold)
    print(f"archived {moved} checked entries" if moved else "archive threshold not reached")
    return 0


def hook_status(summary: dict) -> str:
    pending = summary["pending"]
    tally = "Nothing pending." if pending == 0 else f"{pending} pending."
    tags = summary["open_tags"]
    shown = tags[:10]
    tag_text = ", ".join(shown) if shown else "none"
    if len(tags) > len(shown):
        tag_text += f", +{len(tags) - len(shown)} more"
    age = summary["oldest_pending_days"]
    due = (
        f"Consider offering a harvest ({pending} pending; oldest {age}d)."
        if summary["harvest_due"]
        else "Harvest only on request or workspace wrap-up."
    )
    return f"{tally} Open tags: {tag_text}. {due}"


def hook_context(args: argparse.Namespace) -> int:
    try:
        raw = sys.stdin.read().strip()
        data = json.loads(raw) if raw else {}
    except json.JSONDecodeError:
        data = {}
    exports = {
        "SKILL_SCOUT_SESSION_ID": data.get("session_id", ""),
        "SKILL_SCOUT_TRANSCRIPT": data.get("transcript_path", ""),
        "SKILL_SCOUT_PROJECT_CWD": data.get("cwd", ""),
    }
    env_file = os.environ.get("CLAUDE_ENV_FILE")
    if env_file:
        with open(env_file, "a", encoding="utf-8") as handle:
            for key, value in exports.items():
                if value:
                    handle.write(f"export {key}={shlex.quote(str(value))}\n")
    status = hook_status(active_status(global_path()))
    log_script = Path(__file__).parent / "log.sh"
    message = (
        "[skill-scout] Watch for recurring procedural friction, skill failures, and repeatable context "
        f"waste. Count the cost. On a hit run {shlex.quote(str(log_script))} "
        "'#tag — what happened; measured cost; Fix: remedy' and continue silently. "
        f"Zero to three entries; zero is normal. {status}"
    )
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": message}}))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    log = sub.add_parser("log", help="append one entry globally and locally")
    log.add_argument("entry", nargs="+")
    log.add_argument("--tag")
    log.add_argument("--repo")
    log.add_argument("--date")
    log.add_argument("--session")
    log.add_argument("--cwd", default=os.getcwd())
    log.set_defaults(func=log_entry)

    summary = sub.add_parser("summary", help="print compact grouped notebook state")
    summary.add_argument("--json", action="store_true")
    summary.set_defaults(func=print_summary)

    show = sub.add_parser("show", help="print entries for one tag")
    show.add_argument("tag")
    show.set_defaults(func=show_entries)

    review = sub.add_parser("review", help="mark tags reviewed and archive when needed")
    review.add_argument("tags", nargs="+")
    review.add_argument("--cwd", default=os.getcwd())
    review.add_argument("--archive-threshold", type=int, default=100)
    review.set_defaults(func=review_entries)

    ship = sub.add_parser("ship", help="record an implemented proposal")
    ship.add_argument("tag")
    ship.add_argument("--artifact", required=True)
    ship.add_argument("--date")
    ship.add_argument("--cwd", default=os.getcwd())
    ship.set_defaults(func=lambda args: state_change(args, "Shipped"))

    decline = sub.add_parser("decline", help="record a rejected proposal")
    decline.add_argument("tag")
    decline.add_argument("--reason", required=True)
    decline.add_argument("--date")
    decline.add_argument("--cwd", default=os.getcwd())
    decline.set_defaults(func=lambda args: state_change(args, "Declined"))

    archive = sub.add_parser("archive", help="move old checked entries out of the active notebook")
    archive.add_argument("--threshold", type=int, default=100)
    archive.add_argument("--cwd", default=os.getcwd())
    archive.set_defaults(func=archive_command)

    hook = sub.add_parser("hook-context", help="emit SessionStart context")
    hook.set_defaults(func=hook_context)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())

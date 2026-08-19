#!/usr/bin/env python3
"""Mine Claude Code JSONL transcripts for objective skill-scout signals."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

import notebook as scout_notebook

DISCOVERY_TOOLS = {"Grep", "Glob", "Read", "LS", "Search"}
MUTATION_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
SEARCH_COMMAND = re.compile(r"(?:^|[;&|]\s*)(?:rg|grep|find|fd|ls)\b")
READ_COMMAND = re.compile(r"(?:^|[;&|]\s*)(?:cat|head|tail|sed\s+-n)\b")
MUTATION_COMMAND = re.compile(
    r"(?:apply_patch|\b(?:sed\s+-i|perl\s+-pi|mkdir|touch|cp|mv)\b|(?:^|[;&|]\s*)git\s+(?:add|commit|mv|rm)\b)"
)
CORRECTION = re.compile(
    r"(?i)(?:\bno,?\s+actually\b|\bthat(?:'s| is)\s+(?:wrong|incorrect|not right)\b|"
    r"\byou(?:'re| are)\s+wrong\b|\bnot what i (?:asked|meant)\b|"
    r"\bi said\b|\bplease don['’]t\b|\bstop,?\s+(?:that|doing|using)\b)"
)
COST_RE = re.compile(r"(?i)(\d[\d,]*)\s+(tool calls?|greps?|reads?|lines?|turns?|retries)\b")


def text_content(value) -> str:
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return "\n".join(
            item.get("text", "") if isinstance(item, dict) and item.get("type") == "text" else ""
            for item in value
        )
    return ""


def tool_result_text(value) -> str:
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return "\n".join(
            item.get("text", "") if isinstance(item, dict) else str(item) for item in value
        )
    return str(value) if value is not None else ""


def line_count(text: str) -> int:
    return 0 if not text else text.count("\n") + 1


def bash_command(tool: dict) -> str:
    return str(tool.get("input", {}).get("command", ""))


def is_discovery(tool: dict) -> bool:
    if tool["name"] in DISCOVERY_TOOLS:
        return True
    if tool["name"] != "Bash":
        return False
    command = bash_command(tool)
    return bool((SEARCH_COMMAND.search(command) or READ_COMMAND.search(command)) and not MUTATION_COMMAND.search(command))


def is_mutation(tool: dict) -> bool:
    return tool["name"] in MUTATION_TOOLS or (
        tool["name"] == "Bash" and bool(MUTATION_COMMAND.search(bash_command(tool)))
    )


def command_signature(command: str) -> str:
    return re.sub(r"\s+", " ", command).strip()


def tool_label(tool: dict) -> str:
    if tool["name"] == "Bash":
        first = command_signature(bash_command(tool)).split("\n", 1)[0]
        return scout_notebook.sanitize(first, 140)
    path = tool.get("input", {}).get("file_path") or tool.get("input", {}).get("path")
    return f"{tool['name']} {scout_notebook.sanitize(str(path), 120)}" if path else tool["name"]


def transcript_project_dir(cwd: Path, projects_root: Path) -> Path | None:
    encoded = projects_root / str(cwd.resolve()).replace("/", "-")
    if encoded.is_dir():
        return encoded
    best: tuple[int, Path] | None = None
    for directory in projects_root.iterdir() if projects_root.is_dir() else []:
        if not directory.is_dir():
            continue
        files = sorted(directory.glob("*.jsonl"), key=lambda path: path.stat().st_mtime, reverse=True)
        if not files:
            continue
        try:
            with files[0].open(encoding="utf-8") as handle:
                first = json.loads(handle.readline())
            transcript_cwd = Path(first.get("cwd", "")).resolve()
        except (OSError, json.JSONDecodeError):
            continue
        if cwd == transcript_cwd or cwd.is_relative_to(transcript_cwd) or transcript_cwd.is_relative_to(cwd):
            score = len(str(transcript_cwd))
            if best is None or score > best[0]:
                best = (score, directory)
    return best[1] if best else None


def session_files(args: argparse.Namespace) -> list[Path]:
    root = Path(args.projects_root).expanduser()
    if not root.is_dir():
        return []
    if args.all_projects:
        files = [path for directory in root.iterdir() if directory.is_dir() for path in directory.glob("*.jsonl")]
    else:
        supplied = Path(args.project).expanduser().resolve()
        directory = supplied if supplied.is_dir() and any(supplied.glob("*.jsonl")) else transcript_project_dir(supplied, root)
        if directory is None:
            return []
        files = list(directory.glob("*.jsonl"))
    return sorted(files, key=lambda path: path.stat().st_mtime, reverse=True)[: args.sessions]


def parse_session(path: Path, args: argparse.Namespace) -> dict:
    tools: list[dict] = []
    tool_by_id: dict[str, dict] = {}
    corrections = []
    session_id = path.stem
    timestamp = ""
    cwd = ""
    with path.open(encoding="utf-8") as handle:
        for raw_line in handle:
            try:
                event = json.loads(raw_line)
            except json.JSONDecodeError:
                continue
            session_id = event.get("sessionId") or session_id
            timestamp = timestamp or event.get("timestamp", "")
            cwd = cwd or event.get("cwd", "")
            message = event.get("message") or {}
            content = message.get("content")
            if message.get("role") == "user" and not event.get("isMeta"):
                user_text = text_content(content)
                if user_text and CORRECTION.search(user_text):
                    corrections.append(scout_notebook.sanitize(user_text, 180))
            if not isinstance(content, list):
                continue
            for block in content:
                if not isinstance(block, dict):
                    continue
                if block.get("type") == "tool_use":
                    tool = {
                        "id": block.get("id", ""),
                        "name": block.get("name", ""),
                        "input": block.get("input") or {},
                        "result": None,
                    }
                    tools.append(tool)
                    tool_by_id[tool["id"]] = tool
                elif block.get("type") == "tool_result" and block.get("tool_use_id") in tool_by_id:
                    text = tool_result_text(block.get("content"))
                    details = event.get("toolUseResult")
                    if isinstance(details, dict):
                        full_output = "\n".join(
                            str(details.get(key, "")) for key in ("stdout", "stderr") if details.get(key)
                        )
                        if line_count(full_output) > line_count(text):
                            text = full_output
                    tool_by_id[block["tool_use_id"]]["result"] = {
                        "error": bool(block.get("is_error")),
                        "lines": line_count(text),
                    }

    first_mutation = next((index for index, tool in enumerate(tools) if is_mutation(tool)), len(tools))
    discovery = [tool for tool in tools[:first_mutation] if is_discovery(tool)]
    greps = sum(
        tool["name"] in {"Grep", "Glob"}
        or (tool["name"] == "Bash" and bool(SEARCH_COMMAND.search(bash_command(tool))))
        for tool in tools
    )
    reads = sum(
        tool["name"] == "Read"
        or (tool["name"] == "Bash" and bool(READ_COMMAND.search(bash_command(tool))))
        for tool in tools
    )
    floods = [
        {
            "tool": tool_label(tool),
            "lines": tool["result"]["lines"],
        }
        for tool in tools
        if tool["result"] and tool["result"]["lines"] >= args.line_threshold
    ]
    attempts: dict[str, list[dict]] = defaultdict(list)
    for tool in tools:
        if tool["name"] == "Bash" and command_signature(bash_command(tool)):
            attempts[command_signature(bash_command(tool))].append(tool)
    retries = []
    for signature, repeated in attempts.items():
        failures = sum(tool["result"] and tool["result"]["error"] for tool in repeated)
        if len(repeated) >= args.retry_threshold and failures:
            retries.append(
                {
                    "command": scout_notebook.sanitize(signature, 160),
                    "attempts": len(repeated),
                    "failures": failures,
                }
            )
    date = timestamp[:10] or dt.datetime.fromtimestamp(path.stat().st_mtime).date().isoformat()
    return {
        "session": session_id,
        "file": str(path),
        "date": date,
        "repo": Path(cwd).name if cwd else path.parent.name,
        "cwd": cwd,
        "metrics": {
            "tool_call": len(tools),
            "grep": greps,
            "read": reads,
            "line": max((tool["result"]["lines"] for tool in tools if tool["result"]), default=0),
            "discovery_before_edit": len(discovery),
        },
        "signals": {
            "discovery": {
                "calls": len(discovery),
                "first_edit": tool_label(tools[first_mutation]) if first_mutation < len(tools) else "none",
            }
            if len(discovery) >= args.search_chain
            else None,
            "floods": floods,
            "corrections": corrections,
            "retries": retries,
        },
    }


def claimed_costs(text: str) -> list[tuple[int, str]]:
    costs = []
    for raw_number, raw_unit in COST_RE.findall(text):
        unit = raw_unit.lower().removesuffix("s").replace(" ", "_")
        costs.append((int(raw_number.replace(",", "")), unit))
    return costs


def measurement_checks(sessions: list[dict]) -> list[dict]:
    by_id = {session["session"]: session for session in sessions}
    checks = []
    for entry in scout_notebook.all_entries(scout_notebook.global_path()):
        if not entry["session"] or entry["session"] not in by_id:
            continue
        session = by_id[entry["session"]]
        for claimed, unit in claimed_costs(entry["text"]):
            metric = session["metrics"].get(unit)
            if metric is None:
                continue
            checks.append(
                {
                    "tag": entry["tag"],
                    "session": entry["session"],
                    "unit": unit,
                    "claimed": claimed,
                    "observed": metric,
                    "status": "inflated" if claimed > metric * 1.2 + 1 else "verified",
                }
            )
    return checks


def has_signals(session: dict) -> bool:
    signals = session["signals"]
    return bool(signals["discovery"] or signals["floods"] or signals["corrections"] or signals["retries"])


def print_report(report: dict, as_json: bool) -> None:
    if as_json:
        print(json.dumps(report, indent=2, sort_keys=True))
        return
    print(
        f"Audited {report['sessions_audited']} sessions; "
        f"{report['sessions_with_signals']} contained objective signals."
    )
    if not report["sessions_with_signals"]:
        print("No signals met the configured thresholds.")
    for session in report["sessions"]:
        if not has_signals(session):
            continue
        print(f"\n### {session['date']} {session['repo']} `{session['session']}`")
        signals = session["signals"]
        if signals["discovery"]:
            value = signals["discovery"]
            print(f"- Discovery chain: {value['calls']} search/read calls before first edit ({value['first_edit']}).")
        for flood in signals["floods"]:
            print(f"- Output flood: {flood['tool']} returned {flood['lines']} lines.")
        for correction in signals["corrections"]:
            print(f"- Correction-like user message: {json.dumps(correction)}")
        for retry in signals["retries"]:
            print(
                f"- Retry ladder: {retry['attempts']} attempts, {retry['failures']} failed: "
                f"`{retry['command']}`"
            )
    if report["measurement_checks"]:
        print("\n### Logged-cost checks")
        for check in report["measurement_checks"]:
            print(
                f"- {check['tag']} `{check['session']}`: claimed {check['claimed']} {check['unit']}; "
                f"observed {check['observed']} — {check['status']}."
            )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sessions", type=int, default=10)
    parser.add_argument("--project", default=os.getcwd(), help="project path or transcript directory")
    parser.add_argument(
        "--projects-root",
        default=str(Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude")) / "projects"),
    )
    parser.add_argument("--all-projects", action="store_true")
    parser.add_argument("--search-chain", type=int, default=8)
    parser.add_argument("--line-threshold", type=int, default=1000)
    parser.add_argument("--retry-threshold", type=int, default=2)
    parser.add_argument("--json", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    files = session_files(args)
    if not files:
        print("error: no Claude JSONL transcripts found for this project", file=sys.stderr)
        return 1
    sessions = [parse_session(path, args) for path in files]
    report = {
        "sessions_audited": len(sessions),
        "sessions_with_signals": sum(has_signals(session) for session in sessions),
        "thresholds": {
            "search_chain": args.search_chain,
            "line_threshold": args.line_threshold,
            "retry_threshold": args.retry_threshold,
        },
        "sessions": sessions,
        "measurement_checks": measurement_checks(sessions),
    }
    print_report(report, args.json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

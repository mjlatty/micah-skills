from __future__ import annotations

import argparse
import datetime as dt
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS))

import audit  # noqa: E402
import notebook  # noqa: E402


def load_setup_module():
    spec = importlib.util.spec_from_file_location("setup_hook", SCRIPTS / "setup-hook.py")
    module = importlib.util.module_from_spec(spec)
    assert spec.loader
    spec.loader.exec_module(module)
    return module


setup_hook = load_setup_module()


class NotebookTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.home = self.base / "scout"
        self.repo = self.base / "repo"
        self.repo.mkdir()
        (self.repo / ".context").mkdir()
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True)
        self.environment = patch.dict(
            os.environ,
            {"SKILL_SCOUT_HOME": str(self.home)},
            clear=False,
        )
        self.environment.start()

    def tearDown(self):
        self.environment.stop()
        self.temp.cleanup()

    def log(self, entry: str, **overrides) -> int:
        values = {
            "entry": [entry],
            "tag": None,
            "repo": None,
            "date": "2026-08-19",
            "session": "session-one",
            "cwd": str(self.repo),
        }
        values.update(overrides)
        with redirect_stdout(io.StringIO()):
            return notebook.log_entry(argparse.Namespace(**values))

    def test_log_mirrors_redacts_and_deduplicates(self):
        entry = "#waste/route-discovery — 11 greps; token=secret-value; Fix: map routes."
        self.assertEqual(self.log(entry), 0)
        self.assertEqual(self.log(entry), 0)
        global_text = notebook.global_path().read_text()
        local_text = (self.repo / ".context/skill-ideas.md").read_text()
        self.assertEqual(global_text, local_text)
        self.assertEqual(global_text.count("#waste/route-discovery` —"), 1)
        self.assertIn("token=[REDACTED]", global_text)
        self.assertIn("scout:session=session-one", global_text)

    def test_parallel_logging_keeps_every_session(self):
        processes = []
        for index in range(8):
            environment = os.environ.copy()
            environment["SKILL_SCOUT_SESSION_ID"] = f"parallel-{index}"
            processes.append(
                subprocess.Popen(
                    [str(SCRIPTS / "log.sh"), "#waste/parallel-log — 8 tool calls; Fix: serialize writes."],
                    cwd=self.repo,
                    env=environment,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )
            )
        for process in processes:
            stdout, stderr = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, stderr or stdout)
        global_text = notebook.global_path().read_text()
        local_text = (self.repo / ".context/skill-ideas.md").read_text()
        self.assertEqual(global_text.count("#waste/parallel-log` —"), 8)
        self.assertEqual(global_text, local_text)

    def test_gitignored_claude_fallback_is_safe(self):
        (self.repo / ".context").rmdir()
        (self.repo / ".claude").mkdir()
        (self.repo / ".gitignore").write_text(".claude/skill-ideas.md\n")
        self.log("#waste/safe-fallback — 4 tool calls; Fix: remember the command.")
        self.assertTrue((self.repo / ".claude/skill-ideas.md").exists())

    def test_unignored_claude_fallback_is_skipped(self):
        (self.repo / ".context").rmdir()
        (self.repo / ".claude").mkdir()
        self.log("#waste/unsafe-fallback — 4 tool calls; Fix: remember the command.")
        self.assertFalse((self.repo / ".claude/skill-ideas.md").exists())

    def test_summary_review_archive_and_ship(self):
        self.log("#waste/route-discovery — 11 greps; Fix: map routes.")
        summary = notebook.notebook_summary(notebook.global_path())
        self.assertEqual(summary["pending"], 1)
        self.assertEqual(summary["groups"]["#waste/route-discovery"]["costs"]["grep"], 11)

        review = argparse.Namespace(
            tags=["#waste/route-discovery"],
            cwd=str(self.repo),
            archive_threshold=0,
        )
        with redirect_stdout(io.StringIO()):
            notebook.review_entries(review)
        self.assertNotIn("#waste/route-discovery` —", notebook.global_path().read_text())
        self.assertIn("#waste/route-discovery` —", notebook.archive_path(notebook.global_path()).read_text())
        self.assertNotIn("#waste/route-discovery` —", (self.repo / ".context/skill-ideas.md").read_text())
        self.assertIn("#waste/route-discovery` —", (self.repo / ".context/skill-ideas-archive.md").read_text())

        ship = argparse.Namespace(
            tag="#waste/route-discovery",
            artifact="CLAUDE.md layout map",
            date="2026-08-20",
            cwd=str(self.repo),
        )
        with redirect_stdout(io.StringIO()):
            notebook.state_change(ship, "Shipped")
        self.assertIn("## Shipped", notebook.global_path().read_text())
        self.assertIn("✓ CLAUDE.md layout map 2026-08-20", notebook.archive_path(notebook.global_path()).read_text())

    def test_hook_context_exports_session_and_lists_tags(self):
        self.log("#waste/route-discovery — 11 greps; Fix: map routes.")
        env_file = self.base / "env"
        hook_input = json.dumps(
            {
                "session_id": "session-two",
                "transcript_path": "/tmp/session-two.jsonl",
                "cwd": str(self.repo),
            }
        )
        output = io.StringIO()
        with patch.dict(os.environ, {"CLAUDE_ENV_FILE": str(env_file)}, clear=False), patch(
            "sys.stdin", io.StringIO(hook_input)
        ), redirect_stdout(output):
            notebook.hook_context(argparse.Namespace())
        payload = json.loads(output.getvalue())
        context = payload["hookSpecificOutput"]["additionalContext"]
        self.assertIn("#waste/route-discovery", context)
        self.assertIn("SKILL_SCOUT_SESSION_ID=session-two", env_file.read_text())

    def test_old_pending_entry_triggers_harvest_nudge(self):
        old = (dt.date.today() - dt.timedelta(days=31)).isoformat()
        self.log("#waste/stale-entry — 4 tool calls; Fix: document the command.", date=old)
        status = notebook.active_status(notebook.global_path())
        self.assertTrue(status["harvest_due"])
        self.assertEqual(status["oldest_pending_days"], 31)


class AuditTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.project = self.base / "project"
        self.project.mkdir()
        self.projects = self.base / "projects"
        self.transcripts = self.projects / str(self.project).replace("/", "-")
        self.transcripts.mkdir(parents=True)
        self.environment = patch.dict(os.environ, {"SKILL_SCOUT_HOME": str(self.base / "scout")}, clear=False)
        self.environment.start()

    def tearDown(self):
        self.environment.stop()
        self.temp.cleanup()

    def write_fixture(self) -> Path:
        session = "audit-session"
        events = []

        def event(role, content):
            events.append(
                {
                    "type": role,
                    "sessionId": session,
                    "timestamp": "2026-08-19T12:00:00Z",
                    "cwd": str(self.project),
                    "message": {"role": role, "content": content},
                }
            )

        event("user", "No, actually, that is the wrong file.")
        for index in range(3):
            tool_id = f"read-{index}"
            event("assistant", [{"type": "tool_use", "id": tool_id, "name": "Read", "input": {"file_path": f"f{index}"}}])
            event("user", [{"type": "tool_result", "tool_use_id": tool_id, "content": "a\nb\nc"}])
        event("assistant", [{"type": "tool_use", "id": "edit", "name": "Write", "input": {"file_path": "out"}}])
        for index, failed in enumerate((True, False)):
            tool_id = f"bash-{index}"
            event("assistant", [{"type": "tool_use", "id": tool_id, "name": "Bash", "input": {"command": "make test"}}])
            event(
                "user",
                [{"type": "tool_result", "tool_use_id": tool_id, "content": "failed" if failed else "ok", "is_error": failed}],
            )
        path = self.transcripts / f"{session}.jsonl"
        path.write_text("\n".join(json.dumps(value) for value in events) + "\n")
        return path

    def test_audit_finds_all_signal_classes_and_inflated_cost(self):
        path = self.write_fixture()
        log_args = argparse.Namespace(
            entry=["#waste/file-discovery — 10 reads before the edit; Fix: add a layout map."],
            tag=None,
            repo=self.project.name,
            date="2026-08-19",
            session="audit-session",
            cwd=str(self.project),
        )
        with redirect_stdout(io.StringIO()):
            notebook.log_entry(log_args)
        args = argparse.Namespace(search_chain=3, line_threshold=3, retry_threshold=2)
        result = audit.parse_session(path, args)
        self.assertEqual(result["signals"]["discovery"]["calls"], 3)
        self.assertEqual(len(result["signals"]["floods"]), 3)
        self.assertEqual(len(result["signals"]["corrections"]), 1)
        self.assertEqual(result["signals"]["retries"][0]["attempts"], 2)
        checks = audit.measurement_checks([result])
        self.assertEqual(checks[0]["status"], "inflated")
        self.assertEqual(checks[0]["observed"], 3)


class SetupHookTests(unittest.TestCase):
    def test_install_preserves_other_hooks_and_remove_is_scoped(self):
        settings = {
            "hooks": {
                "SessionStart": [
                    {"matcher": "startup", "hooks": [{"type": "command", "command": "echo existing"}]}
                ]
            }
        }
        installed, changed = setup_hook.install(settings)
        self.assertTrue(changed)
        self.assertEqual(len(installed["hooks"]["SessionStart"]), 2)
        installed_again, changed_again = setup_hook.install(installed)
        self.assertFalse(changed_again)
        removed, changed_remove = setup_hook.remove(installed_again)
        self.assertTrue(changed_remove)
        self.assertEqual(removed["hooks"]["SessionStart"][0]["hooks"][0]["command"], "echo existing")


if __name__ == "__main__":
    unittest.main()

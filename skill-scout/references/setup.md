# SessionStart hook

Install or update the guarded hook without overwriting unrelated settings:

```sh
python3 scripts/setup-hook.py --dry-run --install
python3 scripts/setup-hook.py --install
python3 scripts/setup-hook.py --check
```

Use `--remove` to remove only skill-scout's hook. The script honors `CLAUDE_CONFIG_DIR`, validates
JSON, preserves unrelated hooks, writes atomically, and stays idempotent.

At startup, resume, and compaction the hook:

- exposes the current transcript ID to `log.sh` for measured audits;
- lists up to ten open tags to prevent near-duplicate names;
- suggests offering a harvest at eight pending entries or when the oldest is over 30 days;
- injects the one-call logging instruction.

Without the hook, manual logging, audit, and harvest still work.

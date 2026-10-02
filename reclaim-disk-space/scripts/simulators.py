#!/usr/bin/env python3
"""Read-only inventory of simulator runtimes and devices, largest first.

Sizes and last-used dates come from simctl's own JSON, so nothing is walked
with du. Runtime sizes are the real on-disk cost: the images live under
/System/Library/AssetsV2 and are mounted at /Library/Developer/CoreSimulator/
Volumes, where du would count them a second time.

    simulators.py          runtimes, then the 15 largest devices
    simulators.py --all    every device, including never-booted stubs
"""

import json
import subprocess
import sys
from collections import defaultdict


def simctl(*args):
    out = subprocess.run(["xcrun", "simctl", *args], capture_output=True, text=True)
    return json.loads(out.stdout) if out.returncode == 0 and out.stdout else {}


def gib(n):
    return f"{n / 2**30:5.1f}G"


def day(ts):
    return ts[:10] if ts else "never"


def devices_by_runtime(device_set=None):
    args = ["--set", device_set] if device_set else []
    listing = simctl(*args, "list", "devices", "-j").get("devices", {})
    return {rt: devs for rt, devs in listing.items() if devs}


def main():
    show_all = "--all" in sys.argv
    named = devices_by_runtime()
    clones = devices_by_runtime("testing")

    print("== runtimes (delete: xcrun simctl runtime delete <id>) ==")
    runtimes = simctl("runtime", "list", "-j")
    total = 0
    for rid, r in sorted(runtimes.items(), key=lambda kv: -kv[1].get("sizeBytes", 0)):
        size = r.get("sizeBytes", 0)
        total += size
        key = r.get("runtimeIdentifier", "")
        platform = key.rsplit(".", 1)[-1].split("-")[0]
        n_named = len(named.get(key, []))
        n_clones = len(clones.get(key, []))
        booted = max((d.get("lastBootedAt", "") for d in named.get(key, [])), default="")
        flag = "" if r.get("deletable", False) else "  (not deletable)"
        print(
            f"{gib(size)}  {platform} {r.get('version')} ({r.get('build')})"
            f"  runtime last used {day(r.get('lastUsedAt'))}"
            f"  devices {n_named} (last booted {day(booted)})  clones {n_clones}"
            f"  id {rid}{flag}"
        )
    print(f"{gib(total)}  total")

    print("\n== named devices (data size, last booted) ==")
    rows = []
    for rt, devs in named.items():
        version = rt.rsplit(".", 1)[-1]
        for d in devs:
            size = d.get("dataPathSize", 0)
            rows.append((size, d.get("name"), version, day(d.get("lastBootedAt")), d.get("state"), d.get("udid")))
    rows.sort(key=lambda r: -r[0])
    shown = rows if show_all else rows[:15]
    for size, name, version, booted, state, udid in shown:
        print(f"{gib(size)}  {name}  {version}  last booted {booted}  {state}  {udid}")
    if len(rows) > len(shown):
        rest = rows[len(shown):]
        print(f"{gib(sum(r[0] for r in rest))}  ...{len(rest)} more (--all to list)")


if __name__ == "__main__":
    main()

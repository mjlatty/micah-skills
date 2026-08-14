---
name: run-laravel-valet
description: Cold-start and serve a Laravel app locally over HTTPS via Laravel Valet on macOS (with `php artisan serve` as an HTTP-only fallback), then verify it serves real pages. Use when asked to run, start, serve, or preview a Laravel/Livewire app locally — as opposed to running its tests. Reads host/db/port from the project's own `.env`; a project-specific run skill, if one exists, wins on project identity.
---

# Run a Laravel app locally over HTTPS (Valet)

"Running it" means starting a PHP web server against the app's real database — not
just building assets. This skill carries the machine- and stack-level know-how for
Laravel + Valet + Livewire on macOS. Everything project-specific (hostname, database,
port, whether the app uses subdomains) comes from **the project's own `.env` and its
directory name** — read those first; never assume the ones in the examples below.

If the repo ships its own run skill (e.g. `.claude/skills/run-app`), that skill owns
the project's identity and quirks — defer to it and use this only to fill gaps.

## Read the project first (don't skip)

```
# App URL, DB connection, session domain — the source of truth for how to serve:
grep -E '^(APP_URL|DB_CONNECTION|DB_DATABASE|DB_HOST|SESSION_DOMAIN|SESSION_SECURE_COOKIE)=' .env
```

- **`APP_URL`** is the base host the app routes against. Site/tenant/subdomain routing
  keys off its host, and secure cookies key off `SESSION_DOMAIN`. If you serve under a
  host that doesn't match `APP_URL`, expect 404s on host-dependent routes and dropped
  sessions — even while `/` still works.
- **DB**: confirm the connection (`pgsql`/`mysql`) and that the server is up on the
  configured host before serving, or migrations and pages fail with connection errors.

## Valet serves by directory basename — mind worktrees

Valet maps a **linked or parked directory to `<basename>.test`**. Two traps:

- **A parked host serves the parked checkout, not your worktree.** If Valet is parked
  on a directory (e.g. `~/Code`) and the repo is linked there as `<name>.test`, that
  hostname serves *that* checkout on *whatever branch it's on* — not the Conductor
  worktree you're editing. Uncommitted changes in a worktree won't show up there.
  Check what's parked/linked: `cat ~/.config/valet/config.json`, `ls ~/.config/valet/Sites`.
- To see **this** worktree in a browser, link it as its own host (`<this-basename>.test`)
  or fall back to `artisan serve`.

## Prerequisites

- PHP, Composer, Node on `PATH`; the app's DB server running on its configured host.
- **Valet installed**, daemons persistent, TLD `.test`, loopback `127.0.0.1`.
- `.env` present. A fresh worktree often needs `npm install` — `node_modules` and
  `public/build` are gitignored and per-worktree.

## Cold-start steps

1. Install deps / build assets if missing (symptom of missing build: pages or tests
   fail with **`Vite manifest not found`**):
   ```
   composer install                 # usually already present
   npm install && npm run build     # or `npm run dev` alongside for hot reload
   ```
   Neither Valet nor `artisan serve` rebuilds assets — re-run `npm run build` after
   frontend changes.
2. Migrate if needed: `php artisan migrate`.
3. Serve — Valet (HTTPS, reflects this worktree persistently) or artisan serve (HTTP).

## Serving via Valet over HTTPS (preferred)

HTTPS is the closest match to production and avoids mixed-content / secure-cookie
surprises. Valet only serves https for hosts that have been **secured** with a
locally-trusted cert, and **certs are per-hostname, not wildcard** — which matters if
the app serves tenants on subdomains (each subdomain host needs its own cert).

### The sudo gotcha (macOS + Homebrew)

Valet's `link`/`secure`/`unlink` shell out to `sudo`. On a machine with passwordless
sudo scoped to the **Homebrew binary path**, `valet` on `PATH` often resolves to the
**Composer** binary (`~/.composer/vendor/bin/valet`), and invoking it plain makes Valet
re-`sudo` on a path the allowlist doesn't cover → `sudo: a password is required`.
Run it **as root via the Homebrew path** instead:

```
sudo -n /opt/homebrew/bin/valet <command>     # e.g. link, secure, links
```

Check your grant with `sudo -n -l` (look for a NOPASSWD entry on
`/opt/homebrew/bin/valet *`). If `sudo -n …` prompts, the grant isn't there — hand the
command to the user or have them run `valet trust`; don't retry in a loop.

### Link, secure, point `.env`, verify

1. Link + secure this worktree (`$(basename "$PWD")` = the host it'll serve as):
   ```
   sudo -n /opt/homebrew/bin/valet link "$(basename "$PWD")"
   sudo -n /opt/homebrew/bin/valet secure "$(basename "$PWD")"    # trusted cert → https
   ```
   If the app serves tenants on subdomains, secure each subdomain host you need too
   (per-host certs): `sudo -n /opt/homebrew/bin/valet secure <sub>.<basename>`.
   `valet secure` restarts nginx, so the first request right after may return HTTP 000
   — retry once.
2. Point `.env` at the https host so routing and secure cookies line up, then clear
   config:
   ```
   APP_URL=https://<basename>.test
   SESSION_DOMAIN=.<basename>.test
   SESSION_SECURE_COOKIE=true
   ```
   ```
   php artisan config:clear
   ```
3. Verify (Valet's cert is locally trusted — plain `curl`, no `-k`). Valet serves
   continuously; nothing to background:
   ```
   curl -s -o /dev/null -w "%{http_code}\n" https://<basename>.test/     # expect 200
   ```

Don't kill Valet's daemons when done — they're persistent shared services.

## Serving via `php artisan serve` (fallback — HTTP only, no sudo)

Fast and isolated, but **http only** (no TLS) and served on `127.0.0.1`, where
host-dependent routes (subdomains/tenants) won't match. The app root works directly;
host-specific pages need a spoofed `Host` header matching `APP_URL`'s host.

```
php artisan serve --port=8123 > /tmp/laravel-serve.log 2>&1 &
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8123/          # root → 200
# host-dependent page (spoof Host to APP_URL's host, or a tenant subdomain of it):
curl -s -H "Host: <sub>.<app-host>" http://127.0.0.1:8123/ -o /dev/null -w "%{http_code}\n"
```

To screenshot a host-routed page in headless Chrome, map the vhost to the local port:

```
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless --disable-gpu --hide-scrollbars \
  --host-resolver-rules="MAP <sub>.<app-host> 127.0.0.1:8123" \
  --window-size=900,1400 --screenshot=/tmp/page.png "http://<sub>.<app-host>/"
```

Stop the background server when done: `lsof -ti:8123 | xargs kill`.

## Livewire / SPA hydration caveat

Livewire (and Inertia/React) views hydrate content via JS **after** load, so a raw
static screenshot may show an empty content area even though the page is fine. Verify
against the response HTML (`curl`) for the expected markup, or add a short wait before
capturing.

## Notes for future runs

- DB servers and Valet daemons run persistently — after the first cold start you
  usually only need to (re)build assets and (for artisan serve) restart the server.
  `composer install` / `npm install` are only needed on lockfile changes or a brand-new
  worktree.
- Valet CLI mutations always need sudo — if one dies with `sudo: a password is
  required`, hand it to the user rather than retrying.
- A parked always-on host is a convenient instance of *main*, but it's a separate
  checkout — never assume it reflects the branch you're on.

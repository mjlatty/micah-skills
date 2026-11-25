// Screenshot variant-lab variants at desktop and phone widths.
//
//   node shoot.mjs --base https://app.test/settings-lab --out .context/lab/shots current a b c d e
//
// For each letter, loads <base>?<param>=<letter> (param defaults to `v`), hides the picker and any
// page-level or sticky header outside the scope (they land mid-capture otherwise), and
// screenshots the element matching --scope (default #lab-scope), or the full page if nothing
// matches, into <out>/<letter>-{desktop,mobile}.png. Uses a real 390px viewport, which headless
// Chrome's --window-size can't do.
// Options: --param <key> changes the query key; --scope <css> changes the captured element;
// --hide <css> overrides what is hidden; --wait <ms> adds a pause after load (motion, hydration).
// For a lab varied in separate parts: --param header --scope '#lab-header' a b c d e.
// Exits 1 if any page fails to load.
//
// Run from the project root so `playwright` resolves from its node_modules. If Playwright's own
// Chromium build isn't downloaded, it falls back to the installed Google Chrome.
import { mkdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import { join } from 'node:path';

const require = createRequire(join(process.cwd(), 'noop.js'));
const { chromium } = require('playwright');

const opts = {
  base: null,
  out: '.context/lab/shots',
  param: 'v',
  scope: '#lab-scope',
  hide: '#lab-picker, #landing-lab-picker, body > header, header.sticky, header.fixed',
  wait: 300,
};
const letters = [];
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) {
  const arg = argv[i];
  if (arg === '--base') opts.base = argv[++i];
  else if (arg === '--out') opts.out = argv[++i];
  else if (arg === '--param') opts.param = argv[++i];
  else if (arg === '--scope') opts.scope = argv[++i];
  else if (arg === '--hide') opts.hide = argv[++i];
  else if (arg === '--wait') opts.wait = Number(argv[++i]);
  else letters.push(arg);
}
if (!opts.base || letters.length === 0) {
  console.error('usage: node shoot.mjs --base <lab-url> [--out dir] [--param v] [--scope css] [--hide css] [--wait ms] <letter> [...]');
  process.exit(2);
}
mkdirSync(opts.out, { recursive: true });

const viewports = [
  ['desktop', { width: 1440, height: 900 }, 1],
  ['mobile', { width: 390, height: 844 }, 2],
];

let browser;
try {
  browser = await chromium.launch();
} catch (err) {
  console.error(`Playwright's Chromium failed to launch, trying installed Chrome: ${err.message.split('\n')[0]}`);
  browser = await chromium.launch({ channel: 'chrome' });
}
try {
  for (const letter of letters) {
    const url = new URL(opts.base);
    url.searchParams.set(opts.param, letter);
    const prefix = opts.param === 'v' ? '' : `${opts.param}-`;
    for (const [name, viewport, scale] of viewports) {
      const page = await browser.newPage({ viewport, deviceScaleFactor: scale, reducedMotion: 'reduce', ignoreHTTPSErrors: true });
      const res = await page.goto(url.toString(), { waitUntil: 'networkidle' });
      if (!res || !res.ok()) {
        console.error(`${opts.param}=${letter} ${name}: HTTP ${res ? res.status() : 'no response'}`);
        process.exitCode = 1;
        await page.close();
        continue;
      }
      // Hide only what sits outside the scope: a sticky header inside a whole-page variant is
      // part of the variant.
      await page.evaluate(({ hide, scope }) => {
        const root = document.querySelector(scope);
        for (const el of document.querySelectorAll(hide)) {
          if (!root || !root.contains(el)) el.style.setProperty('display', 'none', 'important');
        }
      }, { hide: opts.hide, scope: opts.scope });
      if (opts.wait) await page.waitForTimeout(opts.wait);
      const path = join(opts.out, `${prefix}${letter}-${name}.png`);
      const scoped = page.locator(opts.scope).first();
      if (await scoped.count()) await scoped.screenshot({ path });
      else await page.screenshot({ path, fullPage: true });
      console.log(path);
      await page.close();
    }
  }
} finally {
  await browser.close();
}

// Screenshot variant-lab sections at desktop and phone widths.
//
//   node shoot.mjs --base https://app.test/landing-lab --out .context/lab/shots hero b hero c how b
//
// For each <section> <letter> pair, loads <base>?<section>=<letter>, hides the picker and the
// sticky header (both land mid-capture otherwise), and screenshots the element #lab-<section>
// into <out>/<section>-<letter>-{desktop,mobile}.png. Uses a real 390px viewport, which headless
// Chrome's --window-size can't do. Options: --hide <css> overrides what is hidden (the picker
// and a page-level or sticky <header>, not headers inside sections); --wait <ms> adds a pause
// after load (motion, hydration).
// Exits 1 if any page fails to load.
//
// Run from the project root so `playwright` resolves from its node_modules. If Playwright's own
// Chromium build isn't downloaded, it falls back to the installed Google Chrome.
import { mkdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import { join } from 'node:path';

const require = createRequire(join(process.cwd(), 'noop.js'));
const { chromium } = require('playwright');

const opts = { base: null, out: '.context/lab/shots', hide: '#landing-lab-picker, body > header, header.sticky, header.fixed', wait: 300 };
const pairs = [];
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) {
  const arg = argv[i];
  if (arg === '--base') opts.base = argv[++i];
  else if (arg === '--out') opts.out = argv[++i];
  else if (arg === '--hide') opts.hide = argv[++i];
  else if (arg === '--wait') opts.wait = Number(argv[++i]);
  else pairs.push(arg);
}
if (!opts.base || pairs.length === 0 || pairs.length % 2 !== 0) {
  console.error('usage: node shoot.mjs --base <lab-url> [--out dir] [--hide css] [--wait ms] <section> <letter> [...]');
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
  for (let i = 0; i < pairs.length; i += 2) {
    const [section, letter] = [pairs[i], pairs[i + 1]];
    const url = new URL(opts.base);
    url.searchParams.set(section, letter);
    for (const [name, viewport, scale] of viewports) {
      const page = await browser.newPage({ viewport, deviceScaleFactor: scale, reducedMotion: 'reduce', ignoreHTTPSErrors: true });
      const res = await page.goto(url.toString(), { waitUntil: 'networkidle' });
      if (!res || !res.ok()) {
        console.error(`${section}=${letter} ${name}: HTTP ${res ? res.status() : 'no response'}`);
        process.exitCode = 1;
        await page.close();
        continue;
      }
      await page.addStyleTag({ content: `${opts.hide} { display: none !important; }` });
      if (opts.wait) await page.waitForTimeout(opts.wait);
      const path = join(opts.out, `${section}-${letter}-${name}.png`);
      await page.locator(`#lab-${section}`).screenshot({ path });
      console.log(path);
      await page.close();
    }
  }
} finally {
  await browser.close();
}

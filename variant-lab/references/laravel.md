# Laravel + Blade wiring

The lab as it was first built (Laravel 13, Blade partials, Tailwind 4 via Vite). Adapt the names to
the project. The shape is what matters.

## Share the live page's view data

Pull the controller's data-building into a public method, so both routes render from one source:

```php
// app/Http/Controllers/HomeController.php
public function __invoke(Request $request): Response
{
    $html = view('welcome', $this->viewData())->render();

    return PublicCache::respond($html, PublicCacheControl::HOUR, $request);
}

/** @return array{demo: HomeDemoCard, commercial: array{chart: string, coverage: string}|null, story: HomeStory} */
public function viewData(): array
{
    // …whatever __invoke used to build inline…
}
```

## The lab controller

```php
// app/Http/Controllers/LandingLabController.php
final class LandingLabController extends Controller
{
    /** @var array<string, array<string, array{0: string, 1: string}>> section => letter => [view, label], page order */
    public const SECTIONS = [
        'hero' => [
            'a' => ['partials.home.hero', 'Centered: "Get the rate. And the proof."'],
            'b' => ['partials.home.variants.hero-b', 'Split: claim and proof points left, card right'],
            'c' => ['partials.home.variants.hero-c', 'Thesis headline, proof strip under the card'],
        ],
        // …one entry per section…
    ];

    /** @var array<string, string> What the bare URL opens on; the user's picks after round one. */
    public const DEFAULT_PICKS = ['hero' => 'a' /* … */];

    public function __invoke(Request $request, HomeController $home): View
    {
        $picks = [];
        foreach (self::SECTIONS as $section => $variants) {
            $choice = strtolower((string) $request->query($section, self::DEFAULT_PICKS[$section]));
            $picks[$section] = array_key_exists($choice, $variants) ? $choice : self::DEFAULT_PICKS[$section];
        }

        return view('landing-lab', [
            ...$home->viewData(),
            'sections' => self::SECTIONS,
            'picks' => $picks,
            // The picker's links: the same page with one section's pick changed.
            'hrefWith' => fn (string $section, string $letter): string => route('landing-lab', [...$picks, $section => $letter]),
        ]);
    }
}
```

Type-hinting the live controller and calling `viewData()` keeps its dependencies container-resolved.
Building `hrefWith` here rather than in a `@php` block keeps the copied layout free of the
inline-`@php(...)`-then-`@endphp` trap (see "Blade" below).

## Pages behind a login, or with an empty local database

Screenshots and workers can't log in, so the lab logs in for them. It's a local-only route, so
signing in a fixed local user is acceptable:

```php
Auth::login(User::firstOrCreate(['email' => 'lab@localhost'], ['name' => 'Lab', 'password' => Str::random(32)]));
```

Give the user whatever role or tenant the page needs. If the local database has too little data to
make the page look real, add a `?data=sample` toggle that builds the same value objects the live
page receives from a fixture. Build them with the real classes, not arrays shaped like them, so a
variant can't depend on a field production never sends. Keep `live` as the default so the baseline
stays honest.

## The route, local only

```php
// routes/web.php
if (app()->isLocal()) {
    Route::get('/landing-lab', LandingLabController::class)->name('landing-lab');
}
```

## The lab view

Copy the live page's layout (`welcome.blade.php`) and replace its fixed `@include`s with a loop. Keep
any conditional sections conditional (here, commercial renders only with payer data):

```blade
<main>
    @foreach (array_keys($sections) as $section)
        @continue($section === 'commercial' && $commercial === null)
        <div class="relative" id="lab-{{ $section }}">
            <span class="pointer-events-none absolute left-3 top-3 z-40 rounded-md bg-fuchsia-600 px-2 py-1 font-mono text-[11px] font-medium text-white shadow-lg">
                {{ $section }} · {{ strtoupper($picks[$section]) }} — {{ $sections[$section][$picks[$section]][1] }}
            </span>
            @include($sections[$section][$picks[$section]][0], [
                {{-- whatever the live page passes per section, e.g. the band surface --}}
            ])
        </div>
    @endforeach
</main>
```

Add `<meta name="robots" content="noindex, nofollow">` to the head slot.

The picker, fixed bottom-right. Each letter links to the same page with one pick changed. Under each
row, a hidden panel holds a checkbox per letter and a note field, so the user can answer "B, with
D's headline". With no boxes ticked, a section's pick is the letter on screen. Once any are ticked,
the ticked letters are the pick, whatever is on screen, so looking at another letter never changes
the answer. Those live in `localStorage`, because every letter click is a full page load, and the
storage key includes each section's letters, so pruning or adding letters starts a round with empty
notes:

```blade
<div id="landing-lab-picker" class="fixed bottom-4 right-4 z-50 w-[32rem] max-w-[calc(100vw-2rem)] rounded-xl border bg-white/95 p-3 text-xs shadow-2xl backdrop-blur">
    <div class="flex items-center justify-between">
        <p class="font-semibold">Landing lab</p>
        <button type="button" onclick="var b = document.getElementById('landing-lab-rows'); b.hidden = !b.hidden; localStorage.setItem('landingLabCollapsed', b.hidden ? '1' : '');">Hide / show</button>
    </div>
    <div id="landing-lab-rows" class="mt-2 space-y-1.5">
        @foreach ($sections as $section => $variants)
            <div data-lab-section="{{ $section }}" data-lab-pick="{{ $picks[$section] }}" data-lab-letters="{{ implode('', array_keys($variants)) }}">
                <div class="flex items-center gap-2">
                    <a href="#lab-{{ $section }}" class="w-20 shrink-0 font-mono">{{ $section }}</a>
                    <div class="flex gap-1">
                        @foreach ($variants as $letter => [$view, $label])
                            <a href="{{ $hrefWith($section, $letter) }}#lab-{{ $section }}" title="{{ $label }}" @class([
                                'grid size-7 place-items-center rounded-md border font-mono font-semibold uppercase',
                                'border-fuchsia-600 bg-fuchsia-600 text-white' => $picks[$section] === $letter,
                            ])>{{ $letter }}</a>
                        @endforeach
                    </div>
                    <button type="button" data-lab-toggle class="shrink-0 rounded-md border px-1.5 py-1 text-zinc-500" title="Mix in other variants or leave a note">+ mix / note</button>
                    <span class="min-w-0 truncate text-zinc-500">{{ $variants[$picks[$section]][1] }}</span>
                </div>
                <div data-lab-extra hidden class="mt-1 space-y-1 pl-22">
                    <div class="flex flex-wrap items-center gap-2">
                        <span class="text-zinc-500">Take from</span>
                        @foreach ($variants as $letter => [$view, $label])
                            <label class="flex items-center gap-1 font-mono uppercase" title="{{ $label }}"><input type="checkbox" value="{{ $letter }}"> {{ $letter }}</label>
                        @endforeach
                    </div>
                    <input type="text" data-lab-note class="w-full rounded border px-2 py-1" placeholder="What to take from each, or what to change">
                </div>
            </div>
        @endforeach
        <pre id="landing-lab-picks" class="whitespace-pre-wrap pt-1 font-mono text-[11px] text-zinc-500"></pre>
        <div class="flex gap-2">
            <button type="button" id="landing-lab-copy" class="rounded-md border px-2 py-1 font-medium">Copy picks</button>
            <button type="button" id="landing-lab-clear" class="rounded-md px-2 py-1 text-zinc-500">Clear mixes and notes</button>
        </div>
    </div>
</div>
<script>
(() => {
    const rows = [...document.querySelectorAll('[data-lab-section]')];
    const key = 'landingLab:' + location.pathname + ':' + rows.map((r) => r.dataset.labSection + '=' + r.dataset.labLetters).join(',');
    const saved = JSON.parse(localStorage.getItem(key) || '{}');
    const out = document.getElementById('landing-lab-picks');

    const render = () => {
        const picks = [], notes = [];
        for (const row of rows) {
            const section = row.dataset.labSection, state = saved[section];
            picks.push(section + '=' + (state.mix.length ? state.mix : [row.dataset.labPick]).join('+').toUpperCase());
            if (state.note.trim()) notes.push(section + ': ' + state.note.trim());
        }
        out.textContent = 'Picks: ' + picks.join(' ') + (notes.length ? '\nNotes:\n' + notes.join('\n') : '');
        localStorage.setItem(key, JSON.stringify(saved));
    };

    for (const row of rows) {
        const section = row.dataset.labSection;
        const boxes = [...row.querySelectorAll('input[type=checkbox]')];
        const note = row.querySelector('[data-lab-note]'), extra = row.querySelector('[data-lab-extra]');
        const state = (saved[section] ??= { mix: [], note: '' });

        boxes.forEach((b) => {
            b.checked = state.mix.includes(b.value);
            b.addEventListener('change', () => {
                state.mix = boxes.filter((x) => x.checked).map((x) => x.value);
                render();
            });
        });
        note.value = state.note;
        note.addEventListener('input', () => { state.note = note.value; render(); });
        extra.hidden = !state.mix.length && !state.note;
        row.querySelector('[data-lab-toggle]').addEventListener('click', () => { extra.hidden = !extra.hidden; });
    }

    document.getElementById('landing-lab-copy').addEventListener('click', () => navigator.clipboard.writeText(out.textContent));
    document.getElementById('landing-lab-clear').addEventListener('click', () => { localStorage.removeItem(key); location.reload(); });
    if (localStorage.getItem('landingLabCollapsed')) document.getElementById('landing-lab-rows').hidden = true;
    render();
})();
</script>
```

The copied text reads like this, and it's what the user pastes back:

```
Picks: hero=B+D how=C proof=A
Notes:
hero: B's split layout, D's headline
proof: shorter, drop the third logo
```

## Variant files

`resources/views/partials/home/variants/{section}-{letter}.blade.php`. Seed every registered one
with a placeholder before writing any:

```sh
for s in hero how commercial workspace api cta; do for l in b c; do
  echo "<x-home.section><p>$s-$l placeholder</p></x-home.section>" > resources/views/partials/home/variants/$s-$l.blade.php
done; done
```

Shared helpers between a section's variants live beside them with the section's prefix
(`how-scenarios.php` returning an array, `workspace-grid.blade.php`), so a worker never edits
another section's files.

If the live section has an inline `<script>` bound to element ids, move it into its own partial
(`partials/home/hero-script.blade.php`) and `@include` it from the live section and from each
variant.

## Blade

- If the copied layout uses inline `@php(...)` anywhere, don't add a `@php … @endphp` block below
  it. Blade's block matcher starts at the inline `@php` and swallows everything up to the
  `@endphp`, and the error ("unexpected endforeach", undefined variable) points somewhere else.
  Pass values in from the controller, or use the block form throughout.
- Never write a literal `<x-…>` tag inside a comment in `@props([...])` or `@php`. It gets compiled
  as a component, and Livewire reports "regular expression is too large" on the whole template.

## CSS

If the page's stylesheet scopes Tailwind's scan with explicit `@source` lines (a landing-only CSS
entry often does), the lab view's classes won't be generated. Add one line, marked for removal:

```css
/* Local-only variant picker (LandingLabController); drop with the lab. */
@source '../views/landing-lab.blade.php';
```

Check that the variants directory is already covered (`@source '../views/partials/home';` is).

Then build in watch mode, once, in the background:

```sh
npx vite build --watch --no-emptyOutDir > /tmp/vite-watch.log 2>&1 &
```

`--no-emptyOutDir` matters. By default every rebuild empties `public/build` first, and with several
workers saving files the lab 500s on a missing manifest for seconds at a time, over and over.
(`--emptyOutDir false` doesn't work: the flag takes no value, so the build fails.) Stale hashed
assets pile up instead, which is harmless locally. Clear them at promotion with one normal build.

## Checks

```sh
for s in hero how commercial workspace api cta; do for l in a b c; do
  c=$(curl -s -o /dev/null -w "%{http_code}" "https://app.test/landing-lab?$s=$l"); [ "$c" != 200 ] && echo "FAIL $s=$l $c"
done; done
curl -s -o /dev/null -w "live %{http_code}\n" https://app.test/
```

Then run Pint and PHPStan on the touched PHP, and the tests that render the live page, to confirm the
`viewData()` extraction changed nothing.

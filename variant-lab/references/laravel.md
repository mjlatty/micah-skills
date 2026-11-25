# Laravel + Blade wiring

First built for a landing page (Laravel 13, Blade partials, Tailwind 4 via Vite) and shown here for
a settings page. Adapt the names to the project. The shape is what matters.

## Share the live page's view data

Pull the controller's data-building into a public method, so both routes render from one source:

```php
// app/Http/Controllers/SettingsController.php
public function __invoke(Request $request): View
{
    return view('settings.index', $this->viewData($request));
}

/** @return array{user: User, plan: Plan, usage: UsageSummary, invoices: Collection<int, Invoice>} */
public function viewData(Request $request): array
{
    // …whatever __invoke used to build inline…
}
```

If the scope is a whole page, also move the live view's content (everything inside the layout) into
a partial the live view includes, `settings/partials/body.blade.php`, so the lab can render it as
Current. If the scope is one section, its partial already serves.

## The lab controller

```php
// app/Http/Controllers/SettingsLabController.php
final class SettingsLabController extends Controller
{
    /** @var array<string, array{0: string, 1: string}> letter => [view, short name], ranked: the first is the recommendation. */
    public const VARIANTS = [
        'a' => ['settings.variants.two-column.index', 'Two columns: plan and usage beside the forms'],
        'b' => ['settings.variants.attention-first.index', 'Attention first: what needs doing, then the rest'],
        // …five in all, in ranked order…
    ];

    /** @var array<string, array{0: string, 1: string}> Earlier rounds' picks, kept one click away as reference. */
    public const REFERENCES = [];

    public function __invoke(Request $request, SettingsController $settings): View
    {
        $ranked = array_keys(self::VARIANTS);
        $all = ['current' => ['settings.partials.body', 'Live'], ...self::VARIANTS, ...self::REFERENCES];
        $pick = strtolower((string) $request->query('v', $ranked[0]));
        if (! array_key_exists($pick, $all)) {
            $pick = $ranked[0];
        }

        return view('settings-lab', [
            ...$settings->viewData($request),
            'variants' => $all,
            'ranked' => $ranked,
            'firstReference' => array_key_first(self::REFERENCES),
            'pick' => $pick,
            // The on-screen label: letter, rank and name, so every screenshot stands on its own.
            'labelFor' => fn (string $letter): string => match (true) {
                $letter === 'current' => 'Current — live',
                in_array($letter, $ranked, true) => strtoupper($letter).' · #'.(array_search($letter, $ranked, true) + 1).' — '.$all[$letter][1],
                default => strtoupper($letter).' · earlier pick — '.$all[$letter][1],
            },
            // The picker's links: the same lab with only the variant changed (keeps ?data=sample).
            'hrefFor' => fn (string $letter): string => route('settings-lab', [...$request->except('v'), 'v' => $letter]),
        ]);
    }
}
```

Type-hinting the live controller and calling `viewData()` keeps its dependencies container-resolved.
Building `labelFor` and `hrefFor` here rather than in a `@php` block keeps the copied layout free of
the inline-`@php(...)`-then-`@endphp` trap (see "Blade" below).

Variant views are named for their idea, not their letter, because letters are assigned by rank
after the variants are built. Ranking (or reranking) only reorders `VARIANTS`.

## Pages behind a login, or with an empty local database

Screenshots and workers can't log in, so the lab logs in for them. It's a local-only route, so
signing in a fixed local user is acceptable:

```php
Auth::login(User::firstOrCreate(['email' => 'lab@localhost'], ['name' => 'Lab', 'password' => Str::random(32)]));
```

Give the user whatever role or tenant the page needs. If the local database has too little data to
make the page look real, add a `?data=sample` toggle that builds the same value objects the live
page receives from a fixture. Build them with the real classes, not arrays shaped like them, so a
variant can't depend on a field production never sends. Keep `live` as the default so Current
stays honest.

## The route, local only

```php
// routes/web.php
if (app()->isLocal()) {
    Route::get('/settings-lab', SettingsLabController::class)->name('settings-lab');
}
```

## The lab view

Copy the live page's layout (the shell around the scope) and replace the scope with the picked
variant, wrapped in `#lab-scope` with its label:

```blade
<x-app-layout>
    <div id="lab-scope" class="relative">
        <span class="pointer-events-none absolute left-3 top-3 z-40 rounded-md bg-fuchsia-600 px-2 py-1 font-mono text-[11px] font-medium text-white shadow-lg">
            {{ $labelFor($pick) }}
        </span>
        @include($variants[$pick][0])
    </div>
</x-app-layout>
```

For a section scope, copy the whole live page instead and replace only that section's `@include`.
Add `<meta name="robots" content="noindex, nofollow">` to the head slot.

The picker, fixed bottom-right: one row with Current, the five letters in ranked order, and any
earlier pick set apart after them. Each button switches the whole scope. A hidden panel holds a
checkbox per letter and a note field, so the user can answer "B, with D's copy". With no boxes
ticked, the pick is the letter on screen. Once any are ticked, the ticked letters are the pick,
whatever is on screen, so looking at another letter never changes the answer. They live in
`localStorage`, because every click is a full page load, and the storage key includes the round's
letters, so a new round starts with an empty mix and note:

```blade
<div id="lab-picker" data-pick="{{ $pick }}" data-letters="{{ implode('', array_keys($variants)) }}" class="fixed bottom-4 right-4 z-50 w-[28rem] max-w-[calc(100vw-2rem)] rounded-xl border bg-white/95 p-3 text-xs shadow-2xl backdrop-blur">
    <div class="flex items-center justify-between">
        <p class="font-semibold">Settings lab</p>
        <button type="button" onclick="var b = document.getElementById('lab-picker-body'); b.hidden = !b.hidden; localStorage.setItem('variantLabCollapsed', b.hidden ? '1' : '');">Hide / show</button>
    </div>
    <div id="lab-picker-body" class="mt-2 space-y-1.5">
        <div class="flex items-center gap-1">
            @foreach ($variants as $letter => [$view, $name])
                @if ($letter === $ranked[0] || $letter === $firstReference)
                    <span class="mx-1 h-5 border-l"></span>
                @endif
                <a href="{{ $hrefFor($letter) }}" title="{{ $labelFor($letter) }}" @class([
                    'grid h-7 min-w-7 place-items-center rounded-md border px-1.5 font-mono font-semibold',
                    'border-fuchsia-600 bg-fuchsia-600 text-white' => $pick === $letter,
                ])>{{ $letter === 'current' ? 'Current' : strtoupper($letter) }}</a>
            @endforeach
            <button type="button" data-lab-toggle class="ml-auto shrink-0 rounded-md border px-1.5 py-1 text-zinc-500" title="Mix variants or leave a note">+ mix / note</button>
        </div>
        <p class="truncate text-zinc-500">{{ $labelFor($pick) }}</p>
        <div data-lab-extra hidden class="space-y-1">
            <div class="flex flex-wrap items-center gap-2">
                <span class="text-zinc-500">Take from</span>
                @foreach ($variants as $letter => [$view, $name])
                    @continue($letter === 'current')
                    <label class="flex items-center gap-1 font-mono uppercase" title="{{ $labelFor($letter) }}"><input type="checkbox" value="{{ $letter }}"> {{ $letter }}</label>
                @endforeach
            </div>
            <input type="text" data-lab-note class="w-full rounded border px-2 py-1" placeholder="What to take from each, or what to change">
        </div>
        <pre id="lab-pick" class="whitespace-pre-wrap pt-1 font-mono text-[11px] text-zinc-500"></pre>
        <div class="flex gap-2">
            <button type="button" id="lab-copy" class="rounded-md border px-2 py-1 font-medium">Copy pick</button>
            <button type="button" id="lab-clear" class="rounded-md px-2 py-1 text-zinc-500">Clear mix and note</button>
        </div>
    </div>
</div>
<script>
(() => {
    const picker = document.getElementById('lab-picker');
    const key = 'variantLab:' + location.pathname + ':' + picker.dataset.letters;
    const state = Object.assign({ mix: [], note: '' }, JSON.parse(localStorage.getItem(key) || '{}'));
    const out = document.getElementById('lab-pick');
    const boxes = [...picker.querySelectorAll('input[type=checkbox]')];
    const note = picker.querySelector('[data-lab-note]'), extra = picker.querySelector('[data-lab-extra]');
    const name = (letter) => (letter === 'current' ? 'Current' : letter.toUpperCase());

    const render = () => {
        const pick = state.mix.length ? state.mix.map(name).join('+') : name(picker.dataset.pick);
        out.textContent = 'Pick: ' + pick + (state.note.trim() ? '\nNote: ' + state.note.trim() : '');
        localStorage.setItem(key, JSON.stringify(state));
    };

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
    picker.querySelector('[data-lab-toggle]').addEventListener('click', () => { extra.hidden = !extra.hidden; });
    document.getElementById('lab-copy').addEventListener('click', () => navigator.clipboard.writeText(out.textContent));
    document.getElementById('lab-clear').addEventListener('click', () => { localStorage.removeItem(key); location.reload(); });
    if (localStorage.getItem('variantLabCollapsed')) document.getElementById('lab-picker-body').hidden = true;
    render();
})();
</script>
```

The copied text reads like this, and it's what the user pastes back:

```
Pick: B+D
Note: B's layout, D's copy on the billing card
```

## Variant files

One directory per variant, named for its idea: `resources/views/settings/variants/{name}/`, with an
`index.blade.php` entry and any partials it needs beside it, so a worker never edits another
variant's files. Seed every one of the round's five with a placeholder before writing any:

```sh
for v in two-column attention-first tabs single-scroll drawer-edit; do
  mkdir -p resources/views/settings/variants/$v
  echo "<div class=\"p-8\">$v placeholder</div>" > resources/views/settings/variants/$v/index.blade.php
done
```

Register them in `VARIANTS` under provisional letters so workers can load and check their own;
reorder the array once you've ranked them.

If the live view has an inline `<script>` bound to element ids, move it into its own partial
(`settings/partials/billing-script.blade.php`) and `@include` it from the live view and from each
variant.

## Parts varied separately

Only when the user asks for it by name. Give each part its own query key (`?header=b&form=g`), its
own ranked registry, its own picker row and its own `#lab-<part>` wrapper, and make the copied line
read `Pick: header=B form=G`.

## Blade

- If the copied layout uses inline `@php(...)` anywhere, don't add a `@php … @endphp` block below
  it. Blade's block matcher starts at the inline `@php` and swallows everything up to the
  `@endphp`, and the error ("unexpected endforeach", undefined variable) points somewhere else.
  Pass values in from the controller, or use the block form throughout.
- Never write a literal `<x-…>` tag inside a comment in `@props([...])` or `@php`. It gets compiled
  as a component, and Livewire reports "regular expression is too large" on the whole template.

## CSS

If the page's stylesheet scopes Tailwind's scan with explicit `@source` lines (a page-specific CSS
entry often does), the lab view's classes won't be generated. Add one line, marked for removal:

```css
/* Local-only variant lab (SettingsLabController); drop with the lab. */
@source '../views/settings-lab.blade.php';
```

Check that the variants directory is already covered (`@source '../views/settings';` is).

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
for v in current a b c d e; do
  c=$(curl -s -o /dev/null -w "%{http_code}" "https://app.test/settings-lab?v=$v"); [ "$c" != 200 ] && echo "FAIL v=$v $c"
done
curl -s -o /dev/null -w "live %{http_code}\n" https://app.test/settings   # 302 to login is fine for a signed-in page
```

Then run Pint and PHPStan on the touched PHP, and the tests that render the live page, to confirm the
`viewData()` extraction and the body partial changed nothing.

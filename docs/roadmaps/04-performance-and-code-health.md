# Roadmap 4 — Performance and code health

This roadmap keeps the app fast where the reader feels it — the first ten
seconds after a tap, and typing in the journal — and keeps the codebase able to
answer a question about itself. It follows the repository's own rule: a finding
stays a code reading until a measurement backs it, and a simulator build is
never evidence (`docs/agent-skills/`).

Steps 1–4 are code reading with a measurement to confirm. Steps 5–6 are audits
that may change nothing. Steps 7–8 are the harness these decisions rest on.

---

### 1. Take the library decode off the main thread

**High · `Library/LibraryStore.swift` 61–71, 381–441, 509–540**

**What is wrong.** `LibraryStore.shared` is first touched by the Develop tab's
hero figure (`Develop/DevelopHomeView.swift` 313–322), during the first body
evaluation after launch. Its initialiser synchronously decodes every bundled
document (`loadBundled`, 509–540 — eight JSON files, about 4,700 lines), merges
the persisted import, and then builds the whole derived index
(`rebuildIndex`, 381–441), including the verification queue (439). All of that
lands on the main actor before the first frame is drawn. The hero even has a
correct empty state — `--:--` with a sentence saying why — so the app can show
that immediately and fill in when the library is ready.

**What to change.** Load the documents and build the index on a background task;
publish `document` when it is ready, and keep the synchronous initialiser only
for tests that inject a document (61–63). Do not change what is decoded or how
documents are merged — only where the work happens. Guard against a second load
being started while one is in flight.

**Verify.** Cold launch on a device, twice: App Launch instrument, first-frame
time and the `xcodebuild` launch metric before and after. Do not claim an
improvement from a simulator. Confirm the hero's empty state appears first and
the correct figure replaces it.

**Leave alone.** The merge semantics, the first-entry-wins index, the verified
temperature-scale cache. This is a threading change only.

---

### 2. Cache the hero figure

**Medium · `Develop/DevelopHomeView.swift` 313–340**

**What is wrong.** `featuredTime` walks every film in the library and calls
`times(forFilm:)` for each on every body evaluation. `LibraryStore` now answers
those from its index, so it is no longer a filter-and-sort per row — but it is
still a few hundred dictionary lookups per render, on the app's first screen and
on every re-render of it (the soft-glass home re-renders as its six sections
reveal).

**What to change.** Resolve the featured time once when the document changes and
store it beside the index, the way `verificationItems` is cached. Read it from
the screen. Do not move the selection rule — first sourced time at 20 °C, then
first sourced time — out of the store where it can be tested.

**Verify.** Count body evaluations with the SwiftUI instrument on the Develop
tab during the reveal animation. The figure must remain the same value and the
same film.

**Leave alone.** The rule that nothing is invented when no documented time
exists.

---

### 3. Stop saving the whole journal on every keystroke

**High · `Journal/SessionRecord.swift` 195–200, 249–256; `JournalView` 570–572; `SessionSummaryView` 141–144**

**What is wrong.** Typing a note calls `setNotes` on every character
(`JournalView.swift` 570–572; the summary sheet the same at 141–144). `setNotes`
calls `save()`, which re-sorts all records, encodes the **entire** journal with
`.prettyPrinted` and `.sortedKeys`, and writes it atomically. With a few hundred
sessions that is a full-file encode per keystroke, on the main thread, for a
field the reader is still typing in. `prettyPrinted` also inflates the file the
app must re-read at launch.

**What to change.** Debounce the note write (half a second to a second after the
last keystroke) and keep the in-memory record updating immediately so the UI is
unaffected. Remove `.prettyPrinted` from the shipped persistence — formatting is
a debugging aid, not a storage format — and keep `.sortedKeys` only if the
deterministic output is relied on by anything. Do not change the record's shape.

**Verify.** Time Profiler: type two hundred characters into a note with two
hundred records on file. One write, not two hundred. Kill the app mid-typing and
confirm the note is either the last debounced value or the previous one, never
corrupt.

**Leave alone.** The photo handling in the same store (203–227) and the discard
path — they already write once.

---

### 4. Make the theme tokens cheap

**Medium · `Design/Theme.swift` 36, 40–176; `DLRuntime` 480–483; `DLStyle` 21–27**

**What is wrong.** Every `Theme` token read builds a `DLStyle` and re-resolves
the spec's palette: `Theme.base`, `ink`, `hairline`, `amber` and the rest call
`DLRuntime.activeStyle` each time (`Theme.swift` 36 with 40–176), which
constructs `DLStyle(store:)` (`DesignLanguageComponents.swift` 21–27) by reading
`store.spec` → `DLSpec.spec(for:)` (`DesignLanguageSpec.swift` 340) and
`spec.palette(isDark:accent:)`. A single body that reads six tokens does that six
times; a scroll over the library does it hundreds of times. In the native
languages the work is smaller but not free.

**What to change.** Resolve the active style once per change of (language,
brightness, accent, density, text size) — the same conditions that already
invalidate the stores — and have `Theme` read that cached value. Keep the token
API identical so no call site changes. Invalidate on the store's published
changes; do not add a second source of truth.

**Verify.** SwiftUI instrument while scrolling Recipes in a drawn language
(Cyberpunk, Skeuomorphic) and in the darkroom: body-update counts and time per
update drop, and every screen still draws the right colours after switching
language, accent and brightness.

**Leave alone.** The palette values and the spec decisions. This is caching,
not a redesign.

---

### 5. Audit the twelve fields at rest

**Medium · `Languages/DesignLanguageGraphics.swift` (556 lines)**

**What is wrong.** Twelve language fields are drawn behind every screen, and
nothing in the repository records a measurement of them. The app's own backdrop
learned to pause when off screen, when the app is not active and under Reduce
Motion (`docs/performance-pass.md` 53–62); whether the scanlines, mica, metal
and CRT fields do the same is unknown. A field that animates at rest costs
battery and is invisible in a simulator.

**What to change.** Read each field and list what runs continuously. Where a
field animates, give it the same three pauses as `LiquidBackdrop` — off screen,
inactive, Reduce Motion — using the language store's motion setting. Where a
field is static, leave it alone. Do not restyle any field.

**Verify.** Instruments: Animation Hitches and Energy on a device across a
minute of each field at rest, with the screen on and the app idle. Record which
fields were changed and why in `docs/design-languages.md`.

**Leave alone.** The visual recipes of the fields themselves.

---

### 6. Give the journal the index the library got

**Medium · `Journal/SessionRecord.swift` 125–140**

**What is wrong.** `records(matching:film:developer:)` builds a seven-field
haystack string per record, per keystroke. `LibraryStore` solved the same problem
with a derived index (`docs/performance-pass.md` 64–93) and the journal did not
get the same treatment. With a few hundred sessions it is small; with a few
thousand it is every keystroke doing string joins over the whole history.

**What to change.** Cache each record's search key when the record is written or
loaded, exactly as the library caches `filmSearchKey`. Keep the filter order and
the "every field that should match" behaviour identical. This is a cached
haystack, not a new search engine — no fuzzy matching, no scoring.

**Verify.** Type a query in the journal with a large fixture. Results identical
to before; body updates per keystroke lower.

**Leave alone.** The `filmNames` / `developerNames` ordering and the statistics
(261–475), which are already pure and tested.

---

### 7. Test the things that would be embarrassing to ship broken

**High · `DarkroomTests`, `DarkroomUITests`**

**What is wrong.** `DarkroomTests.swift` is still the template (9–14) and both
UI test files are the template (`DarkroomUITests.swift` 20–34). The three real
suites — cross-process profiles, journal statistics, voice commands — are good,
but none of them covers the engine, the compensation flags or the reuse
arithmetic, which is exactly the code the other roadmaps touch.

**What to change.** Add tests for:

- The return path (Roadmap 2, step 1): stage ends while away, the engine reports
  it and lands in the right phase; a pause across the boundary.
- The estimate flags (Roadmap 2, step 4): measured, interpolated, extrapolated,
  calculated — and the continuous-agitation adjustment.
- The reuse arithmetic: `reuseFactor` compounds (third use = +21 %), and the
  printed arithmetic matches the factor.
- The Live Activity stale date calculation, once it is a pure function.

Do not test views. Do not add snapshot infrastructure. Each test should fail if
its bug returns and pass after the fix.

**Verify.** `xcodebuild test` on a simulator destination, and the CI job from
Ship 6 running it on every push.

**Leave alone.** The existing three suites.

---

### 8. Record the numbers

**High · `docs/performance-pass.md` 137–143**

**What is wrong.** The audit's measurement plan has never been run: the file
says so, and says the device is what it needs. Every performance claim these
roadmaps make is a code reading until that changes. Shipping on a reading is how
an app ends up "optimised" in the wrong places.

**What to change.** Run the plan on a device:

1. App Launch, cold, three times — before and after step 1.
2. SwiftUI instrument, "scroll Recipes with a query typed" — before and after
   steps 2, 4 and 6.
3. Animation Hitches, "run a session into the developer stage" — including the
   stage boundary and the return-from-background path.
4. Energy, one minute per language field at rest — step 5.

Write what was measured, on what device and iOS version, in
`docs/performance-pass.md`; replace "still to measure" with the readings and
keep the ones that showed no problem, because a ruled-out hypothesis is also a
result. If a change in this roadmap shows no measurable difference, revert it
rather than keep it for tidiness.

**Verify.** The document answers, for each step, "how much faster, and where".

**Leave alone.** The standard itself — simulator builds stay out of this file.

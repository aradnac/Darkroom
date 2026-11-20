# Performance pass

The six fixes from the audit, in the order they were made. Each was built
separately on the simulator; none was profiled on a device, so the figures a
profiling run would give are still missing. What follows is what changed and why,
not a claim about measured frame times.

## 1. `SessionEngine` no longer publishes ten times a second

`Develop/SessionEngine.swift`

The engine ticks a 0.1 s timer so a stage boundary is never missed. It also
assigned `now = Date()` on every tick, and `now` is observable — so every view
reading `stageElapsed`, `stageRemaining` or `currentPrompt` re-evaluated its
body ten times a second, for a reading that only moves once.

Now the exact instant lives in a separate `@ObservationIgnored preciseNow`, used
by the engine's own boundary checks, prompt announcements and notification
scheduling, where tenth-of-a-second resolution is the point. The published
`now` is only updated when a reading the running screen actually draws changes —
the stage countdown (compared exactly as `Clock.mmssCeil` renders it), the
current agitation phase's countdown, or the phase itself. That is roughly once a
second, plus one update at each prompt boundary, so the displayed prompt is
never behind the chime that marks it.

Timer accuracy and prompt timing are unchanged: the tick is still 0.1 s, and
`refreshAlerts()` deliberately computes elapsed time from `preciseNow` rather
than the published clock — scheduling from a reading up to a second old would
have fired notifications up to a second late.

`preciseNow` is also set wherever the clock is restarted (`begin`, both branches
of `togglePause`, `advance`, `jump`), so a resumed stage never measures from a
stale instant.

## 2. `TimerTools` timelines wrap the digits, not the screen

`Tools/TimerTools.swift`

The stopwatch, interval timer and wash/rinse timer each wrapped a whole
`ScrollView` — cards, credential rows, lap lists, buttons — in a
`TimelineView`. Every tick rebuilt all of it.

A small `LiveTicker<Content>` now renders its content on a timeline only while
something is counting, and renders statically otherwise. It wraps only the one
`Text` that changes in each timer, keeping each call site's font, colour,
`contentTransition` and accessibility label exactly as they were.

The two timers that also did work on the tick (advancing the interval, ending
the final rinse) keep a 0.2 s `Timer.publish` driver on the view, which changes
no state unless a boundary has actually been crossed. The animations, the
`.numericText()` transitions and the 0.1 s / 0.2 s cadences are unchanged.

## 3. `LiquidBackdrop` stops when nobody is looking

`Design/LiquidBackdrop.swift`

The darkroom backdrop is the one thing that drifts forever, at 24 fps, on ~30
screens. It now pauses when the view is off screen (`onAppear` / `onDisappear`),
when the app is not active (`scenePhase`), and when Reduce Motion is on. All
three use the schedule's own `paused:` flag, so the last frame is held rather
than the layer disappearing: with Reduce Motion the backdrop is a still image of
the same liquid, which is what the print theme already does.

## 4. `LibraryStore` answers from an index

`Library/LibraryStore.swift`, `Library/LibraryBrowserView.swift`

Everything the screens asked for repeatedly was recomputed on each call:

- `film(key:)`, `developer(key:)` and `source(key:)` were linear scans, called
  per row from the detail screens;
- `times(forFilm:)` filtered *and sorted* the whole time table, then sorted with
  a comparator that did two developer lookups per comparison — per row, per
  render;
- `developers(matching:)` rebuilt a haystack string per candidate per keystroke;
- `verificationItems` rebuilt a formatted array for every time, film and
  developer entry on every access — including every keystroke in the search
  field.

A private `Index` is now built once per document change (`didSet` on `document`)
and again on first init. It holds key dictionaries (first entry wins, matching
the old `first(where:)`), a film's times already filtered and sorted in the same
order, per-developer film counts, the search haystacks, and the films'
pre-normalised names and makers for the DX match. `libraryFilm(for:)` keeps its
document-order, first-match behaviour and its ISO rule; it simply no longer
re-normalises every candidate.

`verificationItems` is cached, and rebuilt only when the temperature scale it
formats its subtitles in has changed — that scale is the only input it takes
from outside the document.

`developerRow` now asks the store for the film count instead of building a `Set`
across every time entry.

## 5. A stage's agitation script is built once

`Models/SessionPlan.swift`, `Develop/SessionEngine.swift`

`SessionStage.segments` was a computed property rebuilding the whole agitation
array on every read. The engine reads it several times a second while running,
and the running screen reads it again for each prompt it draws.

`segments` is now stored, built in the stage's initialiser. `duration` became
`private(set)`, and the three places that change a stage's length —
`+30 s`, the leader-clearing fixer time, the standard fix time — go through
`addTime(_:)` or `setDuration(_:)`, which update the duration and rebuild the
script once. No behaviour changed: the same three call sites, the same values.

## 6. `StageRing`'s expensive layers only redraw when their values change

`Develop/StageRing.swift`

The bezel (sixty stroked ticks) and the progress arc (a stroked circle with two
shadows and a running animation) sat directly in the ring's body, so any parent
pass re-stroked both — and could re-time the arc's animation — even when neither
had changed.

They are now `StageRingTicks` and `StageRingFill`, both `Equatable`, applied with
`.equatable()`. The tick canvas redraws for a new stage count, active stage,
diameter or accent; the arc redraws only when its fraction changes. Both
animations, both shadows, the opacity rule and the `.id(index)` that restarts
the arc on a new stage are untouched.

## Files changed

| File | Change |
| --- | --- |
| `Develop/SessionEngine.swift` | Publish cadence; `preciseNow`; precise prompt/alerts timing; stage-time setters |
| `Tools/TimerTools.swift` | `LiveTicker`; three timelines unwrapped; tick drivers for interval advance and rinse end |
| `Design/LiquidBackdrop.swift` | Visibility, scene phase and Reduce Motion pause the liquid |
| `Library/LibraryStore.swift` | Derived `Index`; cached lookups, sorted times, film counts, search keys, verification queue |
| `Library/LibraryBrowserView.swift` | Developer row uses the cached film count |
| `Models/SessionPlan.swift` | Stored `segments`; `private(set) duration`; `addTime` / `setDuration` |
| `Develop/StageRing.swift` | Equatable tick and arc subviews |
| `docs/performance-pass.md` | This record |

## Still to measure

The audit's measurement plan (Animation Hitches + the SwiftUI instrument on
"scroll Recipes with a query typed" and "run a session into the developer
stage") has not been run — that needs a device, and this project builds on a
remote Mac. Findings 3, 4, 5 and 6 above are the ones that plan would confirm
first.

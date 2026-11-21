# Darkroom

A film development companion for iPhone and iPad. It runs a roll from
pre-soak to final rinse, keeps the numbers honest about where they came from,
and tracks what is actually in the bottles on the shelf.

## What it does

**Develop.** Pick a film and a developer, set the dilution and temperature, and
run a stage timeline: optional pre-soak, developer with agitation prompts, stop,
fix, wash, final rinse. The running screen scripts the agitation instead of only
beeping — initial agitation, then a timed prompt at each interval split into
agitate, tap the tank and rest, drawn as a moving liquid indicator. Sound and
haptics fire at every prompt, an optional voice speaks the action, a large GO
control starts a stage hands-free, and spoken commands ("add 30 seconds",
"start fixer", "next stage") work through on-device speech recognition. A Live
Activity follows the session to the Lock Screen and the Dynamic Island, and a
widget shows the state of the bench.

**Recipes.** A searchable reference library of films and developers, bundled as
JSON alongside the DX database. Every documented time carries its provenance —
manufacturer datasheet, community chart, or unverified — with a source URL and
a retrieval date, and anything undocumented is shown as not documented rather
than guessed. Film pages list every time at each dilution and temperature;
developer pages cover dilution, capacity and reuse. A verification queue lists
the records still waiting for a source. Every film also carries a
cross-processing section: each documented combination gives its original and
alternative processes, the expected colour, contrast, grain and exposure
changes, the result and its limitations, examples and references, and a
classification — documented, community-tested, experimental, not recommended, or
chemically incompatible. An incompatible combination is shown as a warning, never
as a recipe, and more combinations arrive through the same import pipeline.

The film library is more than three hundred and eighty records rather than a
starter list: current, discontinued, cinema and specialty stocks, every
generation kept apart, and respools and rebrands listed with the stock they
actually come from. Consumer ranges are documented as lineages — every Kodak
Gold generation from the 1988 launch to the 2022 return of 120, the Fujifilm
consumer line from HR through Super G and Superia, and what a later rebrand such
as AgfaPhoto Vista Plus or Fujifilm's plain 200 really is — because the name on
the box is often the least reliable fact about a film. Each
film carries its latitude, grain and grain structure, contrast, reciprocity and
history, plus a `characteristics` list for everything that does not fit the four
headline facts. A respool says which emulsion it is cut from and whether the
rem-jet was removed; a rebrand says what the coating is believed to be and who
says so, because repackagers rarely name their supplier. The documents are split
by manufacturer under `Resources/Library/` and merged at load, so the library can
keep growing without one enormous file.

**Setup maths.** A session asks for one chart time and the temperature it was
measured at; every other temperature comes from the time/temperature converter —
the exponential correction the Massive Dev Chart's calculator uses, with the same
10% reduction for continuous agitation. With two or more chart times entered the
app interpolates between them instead and labels anything extrapolated. Push and
pull set an exposure index and use a documented time where one exists. Reuse
counts compound rather than add, with the arithmetic shown. Roll count, mixed
emulsions, agitation intensity and a per-stage target temperature are all asked
before the chemistry is poured.

**Journal.** Every finished session is logged automatically with its film,
developer, dilution, temperature, time, reuse count, agitation and wash, and can
be given notes about the negatives and an optional photograph of them. Entries
are searchable and filterable by film and developer, and any of them opens a new
session setup carrying the same film, developer, dilution, temperature, exposure
index and developer use. The statistics sum rolls by film, by developer and by
month, the average deviation between the time used and the published time at
that temperature, and per-chemical totals with each bottle's own ledger beside
them.

**Chemistry.** Dilution and volume calculators, stock-solution mixing, a batch
inventory with capacity and expiry, and a reuse ledger that answers how many
rolls a batch has developed and what penalty the next use carries.

**Tools.** A time/temperature converter in either direction — the time for the
water you have, or the water for the time you want — Celsius and Fahrenheit
conversion, stopwatch with laps, interval timer, wash and final-rinse timers, a
tank liquid visualizer drawn to scale, a film leader retrieval guide, tank
capacities and a chemical safety sheet.

**Simulator.** A sandbox for trying a choice before the chemistry is mixed. Pick
a black-and-white film and developer the library documents a time for, then move
dilution, temperature, development time, agitation and fixing on sliders. An
example frame — drawn rather than photographed, so it carries a full range of
tones and fine detail — is rendered at that setting, and the expected movement in
contrast, density, grain and fog is reported beside it. Over-development,
under-development and over-fixing each say so in words, the thumbnails preview a
stop either side, and the setting can be carried straight into a new session.

**Expired film.** A calculator for an out-of-date roll: pick the stock from the
library, give the printed date and how it has been stored, and get a
recommended exposure index, a P10–P90 range, the stops over box speed, a
confidence badge and the warnings that matter — colour crossover, saturation,
and an acetate base that may be deteriorating. Storage can be described as one
period or as a timeline of several. Behind it: a parametric H&D curve, an
Arrhenius thermal model integrated across the timeline, radiation fog counted
separately with a floor that freezing cannot remove, two thousand seeded Monte
Carlo samples, and a calibration that accepts logged roll outcomes and shrinks
them toward the film family. Every parameter says whether it is measured,
manufacturer documented, literature derived, observed or assumed. Exposure only:
it recommends no developer, dilution or time. `docs/expired-film-ei.md`.

**Settings.** Units and temperature scale, the default agitation scheme and its
intensity, the reuse penalty used for compounded increases, the factor that
scales extrapolation past a published temperature range, a sound and a haptic for
each prompt, voice prompts, keep-awake, the default stop, fix, wash and
final-rinse times, appearance and accent, and a reset for every stored
preference. `docs/settings.md` records what each one changes.

## Design languages

Fourteen complete themes ship, chosen in Settings → Appearance and remembered
between launches. They are not colour schemes: each has its own navigation
structure, screen layouts, type ramp, controls, surfaces, borders, shadows,
motion and background, and the same screen is laid out differently in each.
**Darkroom** (the dark default, the app's own native interface) and **Soft Light**
(white for anything you can press, colour only where it decorates or reports) are
two of them; **Clean**, **Fluent**, **Material 3**, **Swiss**, **Brutalist**,
**Neumorphic**, **Cyberpunk**, **Retro Analog**, **Editorial**, **Skeuomorphic**,
**Terminal** and **Recorder** are the rest. **Recorder** is a flat field of the
chosen colour from edge to edge with black type on it: a bold masthead, a disc of
square dots that fills to the featured time, a tabular readout and a two-by-two
deck of black knobs, each with a signal dot, reading the library, the shelf and
the journal. A single Appearance section carries the theme selector and the
palette every theme is lit with, plus brightness, text size, animation intensity,
reduced motion and interface density, with a live preview before anything is
applied. The darkroom itself is lit by nine colour palettes — a lamp and a second
light behind it, so the backdrop carries a gradient — and fades its content into
the chrome at the top and bottom of every screen. `docs/design-languages.md` and
`docs/soft-glass-theme.md` record the decisions.

## Performance notes

`docs/agent-skills/` holds three vendored review guides — profiling, SwiftUI
update cost, Swift concurrency — from
[Livsy90/iOS-Performance-Agent-Skills](https://github.com/Livsy90/iOS-Performance-Agent-Skills)
(MIT). They are the standard for how performance claims are made here: a
finding stays a code reading until a measurement backs it, and Simulator builds
are never presented as evidence for launch, scrolling, memory or power.

## Building

Xcode 26 or later, iOS 26 deployment target, iPhone and iPad. Open
`Darkroom.xcodeproj`, pick the `Darkroom` scheme and run. No package
dependencies; the app folder is a synchronized group, so new Swift files are
compiled without touching the project file.

The bundle identifier is still the template's `com.organizationName.Darkroom`
and needs to become an identifier you own before a device build or a store
upload.

## Layout

    Darkroom/
      Develop/      session engine, setup, running view, agitation, voice
      Library/      film and developer catalogue, importer, scanner
      Chemistry/    batches, stock mixing, volumes
      Tools/        sink-side utilities and references
      Models/       session plans, chemistry maths, compensation
      Design/       shared tokens, panels, glass, soft glass
      Languages/    the twelve design languages: specs, components, navigation, screens
      Support/      clock, feedback, Live Activity
      Resources/    bundled library JSON and DX database

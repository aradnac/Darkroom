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
the records still waiting for a source.

**Setup maths.** A session asks for one chart time and the temperature it was
measured at; every other temperature comes from the time/temperature converter —
the exponential correction the Massive Dev Chart's calculator uses, with the same
10% reduction for continuous agitation. With two or more chart times entered the
app interpolates between them instead and labels anything extrapolated. Push and
pull set an exposure index and use a documented time where one exists. Reuse
counts compound rather than add, with the arithmetic shown. Roll count, mixed
emulsions, agitation intensity and a per-stage target temperature are all asked
before the chemistry is poured.

**Chemistry.** Dilution and volume calculators, stock-solution mixing, a batch
inventory with capacity and expiry, and a reuse ledger that answers how many
rolls a batch has developed and what penalty the next use carries.

**Tools.** A time/temperature converter in either direction — the time for the
water you have, or the water for the time you want — Celsius and Fahrenheit
conversion, stopwatch with laps, interval timer, wash and final-rinse timers, a
tank liquid visualizer drawn to scale, a film leader retrieval guide, tank
capacities and a chemical safety sheet.

**Settings.** Units and temperature scale, the default agitation scheme and its
intensity, the reuse penalty used for compounded increases, the factor that
scales extrapolation past a published temperature range, a sound and a haptic for
each prompt, voice prompts, keep-awake, the default stop, fix, wash and
final-rinse times, appearance and accent, and a reset for every stored
preference. `docs/settings.md` records what each one changes.

## Design languages

Two complete alternates sit behind the dark Liquid Glass default: **Soft Glass**
(white for anything you can press, colour only where it decorates or reports)
and a hidden **13th theme**, unlocked by tapping the Themes row nine times in
Settings, rendered as a print-media collage language with nine palettes.
The darkroom itself is lit by nine colour palettes — a lamp and a second light
behind it, so the backdrop carries a gradient — and fades its content into the
chrome at the top and bottom of every screen.
`docs/soft-glass-theme.md` and `docs/theme13-log.md` record the decisions.

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
      Theme13/      the hidden print language
      Support/      clock, feedback, Live Activity
      Resources/    bundled library JSON and DX database

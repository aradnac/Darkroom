# Roadmaps

Four roadmaps for getting Darkroom to a publishable 1.0, written for a Claude
agent working in this repository. They are documents, not code: nothing here has
been implemented. Each step names the files, the evidence, the change, how to
verify it, and what must be left alone.

They are four tracks over the same app, not four versions of the same list. A
step appears in exactly one roadmap. Three places are deliberately coupled and
are called out in each; do those together.

## The four

| Roadmap | Question it answers | Steps |
| --- | --- | --- |
| `01-ship-readiness.md` | What stands between this build and App Store review? | 8 |
| `02-session-integrity.md` | Is the core loop — a roll developed at the sink — honest and unbreakable? | 7 |
| `03-interface-and-accessibility.md` | Can everyone actually read and use it, and does the interface keep its promises? | 7 |
| `04-performance-and-code-health.md` | Does it start fast, stay smooth, and can a change be trusted? | 8 |

## Recommended order

1. Ship 4, 1, 2, 3, 5 — five small, independent changes that unblock
   TestFlight.
2. Ship 6 — CI, so everything after it is gated by a green build and tests.
3. Session 1–5 — the correctness of the session before anything is promoted.
4. Interface 4–5 — the two appearance bugs a reviewer or an early user hits in
   the first ten minutes.
5. Session 6–7 — landscape and Live Activity lifetime.
6. Interface 1–3, 6–7 — accessibility, first run, iPad.
7. Performance 1–4 — launch, the hero figure, journal saves, theme tokens.
8. Performance 5–8, then Ship 8 — the final measurement pass and the dry run.

## The rules these roadmaps are built on

- **Evidence first.** Every step quotes the code it is about, with a line. A
  finding stays a code reading until a measurement backs it — the standard
  `docs/agent-skills/` sets out. Simulator builds are never presented as
  evidence for launch, scrolling, memory or power.
- **One step, one commit.** Each step is sized to be finished and verified in a
  single session. Do not combine steps to save a build.
- **Nothing is rewritten.** Every step is a targeted change. No reformatting, no
  renames the step does not need, no cleanup that was not asked for.
- **The app's own note is not a target.** These roadmaps assume the twelve design
  languages, the design language system, and every existing ticket stay. Where a
  step touches them, it is to make them honest or cheap, never to replace them.

## Do not touch

These are correct and deliberately tuned. A step that is not explicitly about
one of them must leave it alone:

- The engine's elapsed-time arithmetic (dates, not tick counts) and the 0.1 s
  boundary tick in `Develop/SessionEngine.swift`.
- The shape and timing of the agitation scripts in `Models/SessionPlan.swift`
  (`AgitationSchedule`, `segments`, `addTime` / `setDuration`).
- The library's provenance rules, the bundled JSON under `Resources/Library/`,
  and the "not documented rather than guessed" rule.
- The chemistry arithmetic and the compounded reuse penalty
  (`DevelopmentSetup.reuseFactor`).
- The visual decisions inside the twelve language specs
  (`Languages/DesignLanguageSpec.swift`) and the two native languages'
  palettes.
- The semantics documented in `docs/settings.md`.
- Anything under `visual refrence/` (sic) — reference material, not source.

## Where the roadmaps meet

- **Bundle identity.** Ship 1 changes the bundle ID; `ApiKeyManager` derives its
  AES key from the last bundle-ID component (`Utils/ApiKeyManager.swift`
  36–44, 243–247). Ship 4 deletes that importer. Do 4 first, or 1 and 4
  together.
- **Appearance.** Interface 4 makes the two appearance stores mutually
  exclusive; Interface 5 stops Settings from resetting every tab. They share
  `ContentView.swift`, `Design/Appearance.swift` and `Languages/DesignLanguage.swift`
  and must not be done in the reverse order.
- **The return path.** Session 1 fixes what the app does when it comes back from
  the background; Performance 7 adds the test that keeps it fixed; Ship 6 makes
  that test run on every push.

## Done means

A roadmap is done when every step has been implemented, verified the way its
"verify" line says, and recorded — either in the existing `docs/` file it
belongs to or in a new one beside it. The code comments in this repository
explain decisions; keep that standard for anything these steps decide.

# Roadmap 3 — Interface and accessibility

The app is used at a sink, often in dim light, often by someone whose hands are
wet, and by readers who use larger text, VoiceOver and Reduce Motion. This
roadmap is about the interface keeping three promises: that every reader can
read it, that it moves only if they want it to, and that what it says is what it
does.

Steps 4 and 5 fix two real bugs a reviewer hits in the first ten minutes. Do
them together.

---

### 1. Dynamic Type, screen by screen

**High · 39 files**

**What is wrong.** There are 578 `.font(.system(size:))` call sites across 38
app files and the widget, and not one `relativeTo:` anywhere in the project
(verified by search). Nothing grows with the reader's text size. The places that
matter most are the ones read during a session: `RunningSessionView` (32 call
sites), `SessionSetupView` (49), `FilmDetailView` (54), `JournalView` (39),
`LibraryBrowserView` (25), `SettingsScreens` (22) and `TimerTools` (31).

**What to change.** Convert screen by screen, not with a sweep:

1. The running session: stage label, countdown, next-action card, controls,
   stage chips. The countdown can keep a fixed figure face if the fixed size is
   the point of the design — but its accessibility label must state the number.
2. Session setup and the library browser and film detail.
3. Settings, the journal and the tools.

Use `.system(size:weight:design:relativeTo:)` or the equivalent semantic text
style, preserving each call site's weight, design, colour and line spacing. Do
not change the layout constants in the same commit; a size change and a
reflow in one commit cannot be reviewed.

**Verify.** At AX3 and at the largest accessibility size: the stage ring, the
dot-matrix figure and the stage chips must not clip or overlap, and every
control must still be reachable. Check one screen per commit, on the smallest
supported phone and on iPad.

**Leave alone.** The dot-matrix and tick-strip drawings themselves
(`SoftGlassComponents`); only the text around them converts.

---

### 2. Reduce Motion everywhere

**High · 5 files today**

**What is wrong.** `accessibilityReduceMotion` is read in only five files
(`DevelopHomeView`, `DesignLanguageRootView`, `DesignLanguageGraphics`,
`DesignLanguageComponents`, `LiquidBackdrop`). The stage-chip
`matchedGeometryEffect` slide in the running session
(`RunningSessionView` 21–23), the hero's move transition, the stage strip's
snappy animation, the Soft Glass wave and the page dots all still animate for a
reader who asked the system for less motion, and the running session is not among
the five files that read the flag.

**What to change.** Gate each remaining animation on
`@Environment(\.accessibilityReduceMotion)`, replacing movement with a
cross-fade or an instant state change — never with a different layout, and never
by removing information. Keep the haptics and the sound prompts: those are not
motion.

**Verify.** Turn Reduce Motion on in Settings → Accessibility. Walk the running
session through a stage boundary, the Develop home, a language switch and a tab
switch: information changes, nothing travels.

**Leave alone.** The backdrop's existing pause (`LiquidBackdrop`), and the
language store's own motion setting — the system switch is an additional veto,
not a replacement.

---

### 3. A first run that explains the bench

**High · new flow**

**What is wrong.** The app opens straight onto Develop with a hero figure and
never says what it is for, while microphone, speech, notification and camera
permissions are requested at the moment of need:
`AgitationAlerts.requestPermission()` fires on the running screen's appear
(`RunningSessionView` 54), voice access is requested when the switch is turned on
(`SessionSetupView` 823, `SettingsScreens` 415), and the scanner asks for the
camera when a canister is scanned (`Library/FilmScanner.swift`). On a fresh
install the notification prompt lands mid-setup, with chemistry already poured.

**What to change.** A short first-run flow in the app's own voice: what the app
does, the six stages it runs, and each permission in turn — what it is used for,
what happens if it is refused, and that the app works without it (a timer still
runs; prompts are just quieter). Shown once, skippable, never again. It must
read the same in whichever language is active, so build it from the shared
tokens (`Theme`) rather than one language's components.

**Verify.** Fresh install: the flow appears once; skipping it still leaves a
working session; refusing notifications leaves the in-app prompts intact;
relaunching does not show it again. Delete and reinstall to test again.

**Leave alone.** The permission request sites themselves — they stay, as the
fallback for a reader who skipped the flow.

---

### 4. One appearance system, not two

**High · 3 files, 2 stores**

**What is wrong.** Two stores both claim to be the source of truth for how the
app looks. `AppearanceStore` carries two languages — darkroom and Soft Glass —
and a `revision` that rebuilds the tab stack (`Design/Appearance.swift` 19–47,
56–70). `ThemeLanguageStore` carries the twelve design languages and
`isActive` (`Languages/DesignLanguage.swift` 20–32, 341). `Theme` resolves a
drawn language first and falls back to Soft Glass (`Design/Theme.swift` 36,
40–44, 92–96), but `SettingsView`'s language rows call only
`appearance.selectLanguage` (148–158). `ThemeLanguageStore.select` resets
`AppearanceStore` when a *theme* is chosen (368–378); the reverse does not
happen.

So choosing **Soft Glass while Fluent is active** changes nothing on the Develop
screen — `Theme` still resolves Fluent — while the app's own screens behind the
other tabs branch on `appearance.isSoftGlassActive` and flip to Soft Glass. The
result is a Fluent chrome around soft-glass screens, and a setting that appears
to do nothing.

**What to change.** Make the choice one choice in both directions:

- Either fold the two native languages into the twelve and let
  `ThemeLanguageStore` own everything, or have `AppearanceStore.selectLanguage`
  clear `ThemeLanguageStore.selected` to Liquid Glass and vice versa.
- Give Settings one row set reading one store, with the twelve languages and the
  two native ones in one list and one selected state.
- Keep the `revision` mechanism only for what genuinely needs a rebuild.

**Verify.** Choose every language in turn and confirm the Develop screen, the
tab chrome, Recipes, Chemistry and Settings all agree. Soft Glass → Fluent →
Soft Glass → Darkroom: each change is visible and complete. Relaunch: the choice
persists.

**Leave alone.** Every language spec and field (`DesignLanguageSpec`,
`DesignLanguageGraphics`); this is state ownership, not visual design.

---

### 5. Closing Settings must not reset every tab

**High · `ContentView` 101, `AppearanceStore` 63–70**

**What is wrong.** The tab stack is applied `.id(appearance.revision)`
(`ContentView.swift` 101), and `AppearanceStore` bumps `revision` when the
Settings sheet closes (`Design/Appearance.swift` 63–70), on a language or
density change (84–96), and on every accent, unit and temperature-scale change
(`Support/Preferences.swift` 485–495, 554–558, 602). Closing Settings therefore
throws all five tabs back to their root screens — open a film, adjust a setting,
close, and the film is gone. Every colour tap also rebuilds the tab stack behind
the sheet.

**What to change.** Bump the revision only when the design language or the
density actually changes — the cases that need a rebuild. Accent, units and
temperature scale already resolve live through `Theme`; they do not need one.
If the tab identity can be kept out of the revision entirely, do that instead.

**Verify.** Open a film, open Settings, close it: the film is still on screen.
Change the accent three times with the sheet open: the stack behind it does not
rebuild (watch it, or observe the tab root's `onAppear` count). Change the
design language: the rebuild still happens.

**Leave alone.** The soft-glass dock inset (`ContentView` 87–100) and the
`TabView` selection state, which is held outside the rebuilt tree deliberately
(17–19).

---

### 6. VoiceOver on the running session

**High · the screen a blind reader cannot currently use**

**What is wrong.** The session is drawn almost entirely as figures: the stage
ring, the dot-matrix countdown, the liquid indicator, the tick strip
(`Develop/StageRing.swift`, `Develop/AgitationLiquid.swift`,
`Design/SoftGlassComponents.swift`). Some screens have labels
(`SessionSummaryView` 145 does), but the running session's figures do not
announce themselves, and a countdown re-announcing every second would be worse
than silence.

**What to change.** Give each figure an element with a stable label and a value
that changes at a human cadence: "Developer, 8 minutes 12 seconds left", the
stage position, the current prompt. Group the controls so a swipe reaches GO,
pause, +30 s and skip stage as named buttons, and ensure the confirmation
dialog and the summary sheet read in order. Check that a haptic or a sound is
never the only signal.

**Verify.** Run a whole session with VoiceOver on, screen locked and unlocked:
every action reachable, the countdown not chatty, endings announced. Then check
the same with Voice Control, since the reader may use it instead.

**Leave alone.** The visible layout. Hidden labels only; nothing moves.

---

### 7. A reading width for iPad and long-form screens

**High · all screens today**

**What is wrong.** There is no reading-width cap anywhere (search finds no
`maxWidth: 5xx`/`6xx` outside the dock). On a 12.9-inch iPad the troubleshooter's
causes, a film's history and the chemical safety sheet run the full width — line
lengths far past comfortable reading — and the session's single column stretches
while the ring stays 240 points.

**What to change.** Add one shared reading-width constant and apply it to
long-form columns (film detail, troubleshooter, reference tools, docs-like
screens) and to the session's content column, centred. Grids and the library
shelf stay full-bleed. On iPhone the constant is inert. This is a width cap, not
a redesign: no screen's composition changes.

**Verify.** iPad portrait and landscape, split view at its narrowest and widest:
long text stays in a readable column; nothing is clipped; the session's controls
do not drift apart. iPhone unchanged.

**Leave alone.** The mosaic and shelf layouts, and the `.glassCard` radii — they
are meant to be wide.

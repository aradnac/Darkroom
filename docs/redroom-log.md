# REDROOM — theme 3 implementation log

## Phase 1 — foundations (done)

**Added**

- `Redroom/RedroomTokens.swift` — the nine canonical colours, the four safelight
  intensities (DIM / NORMAL / BRIGHT / EXTREME, each a multiplier for glow and
  highlights only), and the theme's type helpers.
- `Redroom/RedroomLighting.swift` — `SafelightEnvironment`:
  - `RedroomLightParameters` (lamp position in unit space, top-centre under the
    Dynamic Island, plus the intensity) carried in `EnvironmentValues.redroomLight`.
  - `RedroomLightSample.make(frame:light:screen:)` turns any view's global frame
    into a gradient direction facing the lamp, a distance-falloff `strength`, a
    direct edge value and a faint bounce value.
  - `redroomGlass(...)` measures the element in global space with a preference
    and re-samples on every change, so scrolling relights continuously with no
    per-frame drawing.
  - `RedroomSafelight` — the room: near-black field, one radial glow from the
    lamp, a white-hot filament glint, a foot falloff, and a slow breath on
    opacity (skipped under Reduce Motion).
  - `RedroomLabel`, `RedroomSectionHeader`, `RedroomIndicator`.
- `Redroom/RedroomGlass.swift` — six variants (smoked, clear, optical, wet,
  reflective, frosted). Each body and rim reads the light sample; nothing
  hard-codes an angle, a colour or an intensity.
- `Redroom/RedroomRootView.swift` — the Phase 1 foundations room (intensity
  setting, glass gallery, top/middle/foot light test). Replaced by the tab shell
  in a later phase.

**Changed (additive only)**

- `Theme13/Theme13Palette.swift` — a fourth theme identifier (`"redroom"`) with
  an availability flag (`redroom.available`). A persisted REDROOM selection falls
  back to the darkroom while the flag is off, and `selectTheme` refuses it. A
  `#if DEBUG` preview hook sets the flag and selects the theme.
- `ContentView.swift` — one branch: REDROOM active presents `RedroomRootView`,
  otherwise the existing TabView exactly as before.
- `Theme13/Theme13SettingsView.swift` — a `#if DEBUG` preview row in the design
  section.

**Lighting compliance in this phase**

Every glass surface added reads `sample.direct` / `sample.bounce` /
`sample.start` / `sample.end`. There are no literal highlight angles or
per-component light colours. Text colour is independent of intensity, so body
contrast is unchanged by the safelight setting.

**Not yet built (Phases 2–6)**

Liquid tray and calculator integration; the physical component library;
navigation transitions; session and inventory animation; the five tabs and every
pushed screen; the Live Activity look; the lighting audit, the DEBUG lighting
test screen inside the app shell, Instruments profiling and the selector
enablement.

**Known limits**

- The liquid surface is a stylised Canvas liquid: ripples, a meniscus and a
  surface highlight that answers the safelight, but not true refraction. A Metal
  shader was not written; `layerEffect`/`distortionEffect` are available at iOS 26
  if a later phase wants them.
- No device was available, so nothing in this phase was seen rendering. The
  build is the only verification.

## Phase 2 — signature liquid tray (done)

**Added**

- `Redroom/RedroomLiquid.swift` — `DarkroomLiquidTray`. A black tray with a thick
  rim, holding a shallow dark red chemical drawn in one Canvas clipped to the
  tray: a wave surface, the lamp caught along the meniscus, and expanding rings
  from each touch. Content sits beneath the liquid. The Canvas is
  `allowsHitTesting(false)` and the ripples are fed by a `simultaneousGesture`
  Drag gesture on the tray, so steppers, fields and buttons inside keep working.
  The resting surface is one static frame: the TimelineView is paused unless a
  ripple is alive, and Reduce Motion disables ripples entirely.
- `Redroom/RedroomCalculator.swift` — the development time calculator inside a
  tray. Sheet time, sheet temperature, water temperature and continuous
  agitation, computing through the app's own `DevelopmentTimeCalculator` and
  showing its warnings. No maths of its own.
- `RedroomRootView` gained the calculator section.

**Lighting compliance**

The tray rim is drawn from the safelight deep red; the liquid's surface line is
the safelight at low opacity. No component-level angles or colours.



## Phase 3 — physical controls (done)

**Added**

- `Redroom/RedroomComponents.swift` — the bench hardware, each control binding
  to the same value a conventional one would and keeping its accessibility
  label, value and adjustable action:
  - `RedroomPrimaryButtonStyle` / `RedroomSecondaryButtonStyle` — anodised keys,
    pressed state adds light rather than replacing the safelight, `isEnabled`
    now reads through so a disabled Start looks disabled.
  - `RedroomRotaryDial` — drag to turn, one haptic per notch, VoiceOver
    adjustable action. Used for water temperature, minutes and seconds.
  - `RedroomToggleStyle` — a machined switch with a real `Toggle` behind it
    through `accessibilityRepresentation`.
  - `RedroomCounter`, `RedroomThermometer` (draggable red column),
    `RedroomLiquidProgress`, `ChemicalBottle`, `FilmNegativeCard`,
    `RedroomEnlargerPanel` + `.enlargerPanel()`.
- `Redroom/RedroomScreens.swift` — `RedroomPanel`, `RedroomValueRow`,
  `RedroomNavRow`, `RedroomChip`, `RedroomWarning` (icon + heading + text, never
  colour alone), `RedroomNote`, `RedroomEmptyState`, `RedroomSegmented`,
  `RedroomStepper`, `RedroomSheetBody`.

## Phase 4 — navigation, movement, sheets (done)

- `Redroom/RedroomNavigation.swift` — five places as five developing trays on a
  bench rail: `RedroomTab`, `RedroomTabBar` (glass rail, a pilot lamp per tray,
  the active tray raised and lit), `RedroomScreenHeader`, `RedroomDetailHeader`
  (the room hides the system bar, so the header carries the way back),
  `RedroomScreen` scaffold, `RedroomLitRule` (a hairline lit from the lamp's own
  end via `onGeometryChange`).
- `Redroom/RedroomTransitions.swift` — the four movements and their resting
  states:
  - **Safelight fade** — a surface warming up under the lamp.
  - **Chemical immersion** — the screen rising through the surface (used for tab
    changes).
  - **Film strip** — a strip drawn through the gate (used for arrivals and the
    troubleshooter result).
  - **Enlarger shutter** — the print appearing as the blades open (used by every
    sheet's content).
  Each respects Reduce Motion: opacity only, 0.16 s, no movement.
  `redroomSheet()` sets the room's presentation background, 30 pt radius and
  dark scheme.
- `Redroom/RedroomRootView.swift` — replaced the foundations room with the five
  benches; the safelight sits behind everything and never takes a touch.

## Phase 5 — every screen (done)

New files, each drawing the app's own data:

- `RedroomDevelopScreens.swift` — develop home (published-time plate, ring gauge,
  stage list), session setup (film plate, developer panel, EI, rotary water dial,
  directions, compensation, rolls, agitation, stages, adjustments, start),
  running session (ring gauge, GO, liquid next-action tray, controls, stage
  strip, clearing and summary sheets, voice line, Live Activity updates),
  session summary, film and developer pickers, duration, reuse and clearing
  sheets.
- `RedroomLibraryScreens.swift` — recipes browser (search, identify, filters,
  film strips, developers, chart sources, import), film detail (facts with
  provenance, times by temperature, live 35mm.org chart, cross-processing,
  sources, start a session with this film), developer detail, verification
  queue, film finder (index search + Vision scan), index entry sheet.
- `RedroomChemistryScreens.swift` — chemistry home (working solution in a glass
  vessel, ratio chips, calculators, bottles drawn at their real level), batch
  detail, add/edit batch, log a use, volume and mixing calculators, amount
  sheet. Bottle levels go through `RedroomQuantities`.
- `RedroomToolsScreens.swift` — tools hub, temperature converter, times &
  temperature (thermometers + full calculator + nearby table), stopwatch,
  interval timer, wash & rinse (fill-and-dump schedule and rinse timer), tank
  visualizer (glass tank, liquid at its own level, two reels, tilt, slosh,
  coverage warning), troubleshooter (ranked causes with confidence dots), film
  leader guide, tank capacities, chemical safety.
- `RedroomJournalScreen.swift` — the room's own placeholder plate at parity with
  the existing placeholder.
- `RedroomSettingsScreens.swift` — the room's settings: safelight intensity, the
  design language (and the way back to Darkroom), units, development defaults
  and alerts, all on the room's panels and steppers.
- `Redroom/RedroomContrast.swift`, `Redroom/RedroomQuantities.swift`.
- `Darkroom/ContentView.swift` — the settings sheet presents
  `RedroomSettingsView` while REDROOM is active.
- Live Activity: `themeIdentifier` added to both copies of
  `SessionActivityAttributes.ContentState`; the widget picks the room's red and
  near-black card when it is set. The Dynamic Island's layout stays Apple's.

### Screen inventory — materials, controls, lighting

| Screen | Materials | Controls | Lighting |
| --- | --- | --- | --- |
| Develop home | optical + smoked glass, liquid-free | ring gauge, nav rows, primary button | glass and rule sample the lamp; gauge arc glows from `sample.direct` |
| Session setup | FilmNegativeCard, smoked panels, transparent keys, rotary dial | dial, segmented keys, steppers, toggle, disclosure | every panel and key `redroomGlass`; dial rim and thermometer column read the sample |
| Running session | safelight room, optical chips, liquid tray, ring gauge | GO disc, primary/secondary buttons, stage chips | tray liquid lit by safelight, ring trace glows, chips sample per position |
| Summary | shutter-revealed sheet, smoked plate | primary/secondary | rule lit from lamp |
| Recipes browser | film-strip cards, transparent search, chips | chips, search field, nav rows | cards sample; strip frame is its own dark plate |
| Film / developer detail | smoked and optical panels, fact tiles | chips, nav rows, primary | every tile re-samples as it scrolls |
| Chemistry home | optical panel, glass vessel, bottle cards | dial-free steppers, chips, add key | vessel rim from `sample.start/end`, bottle meniscus from `direct` |
| Batch detail | bottle shape, optical/smoked | stepper, ledger | bottle lit; warnings carry icon + words |
| Volume / mixing | vessel + optical result panel | steppers, chips | as chemistry home |
| Journal | optical plate | none | plate samples; rule lit |
| Tools hub | smoked rows | nav rows | each row lit by its position |
| Temperature converter | optical panel | segmented, text field | rule lit |
| Times & temperature | panels + two thermometers | thermometers, segmented, toggle | thermometer columns glow from lamp |
| Stopwatch / interval | optical readout plate | primary/secondary | plate samples |
| Wash & rinse | panels | segmented, steppers, buttons | plate samples |
| Tank visualizer | glass tank Canvas | chemistry keys, steppers, drag | tank rim uses `sample.start/end` converted to the tank's own space; surface line from `direct` |
| Troubleshooter | smoked grid cards, optical result | cards, menu | cards sample per position; result arrives on the shutter |
| Leader / capacities / safety | panels + source rows | source links | as tools hub |
| Settings | optical safelight panel, smoked panels | segmented, steppers, toggles, nav rows | panels sample per position |

## Phase 6 — audit and verification (done in code, awaiting device)

**Contrast, computed from the tokens** (`RedroomContrast`, asserted in
`DarkroomTests/RedroomContrastTests.swift`)

| Pair | DIM | NORMAL | BRIGHT | EXTREME | Required |
| --- | --- | --- | --- | --- | --- |
| Body text on the room | 17.57 | 17.57 | 17.57 | 17.57 | 4.5 |
| Body text on a smoked panel | 17.02 | 17.02 | 17.02 | 17.02 | 4.5 |
| Body text on a raised panel | 16.60 | 16.60 | 16.60 | 16.60 | 4.5 |
| Body text on glass at full lamp | 15.77 | 14.32 | 12.42 | 10.11 | 4.5 |
| Quiet text on the room | 10.57 | 10.57 | 10.57 | 10.57 | 4.5 |
| Quiet text on a smoked panel | 10.24 | 10.24 | 10.24 | 10.24 | 4.5 |
| Quiet text on glass at full lamp | 9.49 | 8.62 | 7.47 | 6.08 | 4.5 |
| Safelight as a control label | 5.28 | 5.28 | 5.28 | 5.28 | 4.5 |

`textMuted` was lifted from `#A99A9A` to `#C4B6B6` because the original failed
this audit on glass at EXTREME (4.42:1). `textDisabled` (`#594747`) is used only
for borders and disabled marks, never for copy, and is not audited as text.

**DEBUG lighting test screen** — Settings → Lighting test (debug builds only):
nine panes under the lamp, the four intensities side by side, a live sample
read-out, and the whole contrast table above computed at runtime.

**Manual checklist for the phone**

1. Settings → Lighting test, then NORMAL. The top-left pane is the brightest and
   the bottom-right the dimmest; every rim faces the lamp.
2. Sweep to EXTREME. Glow and rims brighten; the figures on the panes do not
   change colour.
3. Settings → Reduce Motion on. The safelight stops breathing, tab changes and
   sheets arrive without movement, and highlights stay in place.
4. Running session: tap a stepper inside the liquid tray — it must work, and the
   liquid must never take the touch.
5. Start a session, let one stage complete, then background the app and reopen:
   the stage completes at once and the Lock Screen card still shows the stage.
6. Settings → Design language → Darkroom and back to REDROOM; the chosen tab
   stays, the session data is untouched.
7. Turn the theme back to Darkroom and check the other two languages still look
   and behave as before.

**Instruments (on a Mac, with the app installed on the phone)**

1. Open the project in Xcode, choose the phone as the run destination, then
   Product → Profile (⌘I) and pick **Time Profiler**.
2. Open a session and let it run through the developer stage for two minutes.
   The expectation: no more than a few percent of CPU on the app process, and no
   per-frame work attributable to `RedroomGlassBody` or `RedroomGlassRim` while
   nothing moves — the sample is only recomputed on a frame change.
3. Switch to **Animation Hitches** and scroll the Recipes list and the Develop
   setup bench to the foot. Expect no hitch > 8 ms from relighting; the glass
   re-samples on geometry change, not per frame.
4. Switch to **Allocations** and open/close five sheets and the running session
   twice. The living count should return to its baseline — the liquid's
   `TimelineView` is paused unless a ripple is alive.
5. Leave the session screen idle for five minutes with the display on: the
   safelight breath is an opacity animation on a static gradient and should not
   register as continuous GPU work.

**Unit tests added**

- `RedroomContrastTests` — every pair at every intensity, the invariance of the
  panel pairs, that the glass genuinely brightens, and the WCAG formula itself.
- `RedroomLightingTests` — direction faces the lamp, falloff down the screen,
  clamping, bounce ≤ direct, intensity monotonicity, zero-frame safety, and
  `RedroomQuantities` bottle level → percent.

These compile with the app but **cannot be run on the remote build Mac**: it has
no simulators. Run them from Xcode on a Mac (⌘U), or on the phone through the
test target.

## What remains / known limits

- Nothing has been seen running on a device. The build and the computed audit
  are the only verification; the checklist above is what to look at.
- The liquid is a stylised Canvas surface, not refraction.
- The Dynamic Island keeps Apple's layout; only its tint and content change.
- The `#if DEBUG` preview hook in `Theme13SettingsView.swift` was removed when
  the selector row became permanent; `previewRedroom()` is now unused outside
  debug tooling.

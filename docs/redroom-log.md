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


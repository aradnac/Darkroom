# Soft Glass — the second design language

Theme 2. A second, complete visual language that replaces the interface rather
than tinting it: its own field, its own chrome, its own controls, its own hero
figures. The darkroom theme is untouched by any of it.

Switch with **Tools → Settings → Themes → Design language → Soft Glass**. The
choice persists across launches (`theme13.theme = softglass`).

## The language

Three ideas, applied everywhere:

1. **A black field lit by the chosen lamp.** `SoftGlassTheme.backdrop()` draws a
   near-black plane and bleeds colour in only at the very edges, the way the
   reference screens sit on black: a wash of the lamp's soft light at the
   foot-left, its bloom at the foot-right, its base at the top, each blurred far
   past its own edge so no shape is visible. The colour is whichever lamp
   Appearance has chosen, so the room changes with the palette; the controls
   stay white, because white is what "pressable" means in this language.
   `LiquidBackdrop` swaps to it while the language is active, so every screen that
   already uses the backdrop adopts it without changes. The mesh gradient that
   seeded the palette is still in `SoftGlassTheme` for reference, but the field is
   the flat plane.
2. **White for anything you can press.** There is no coloured accent on a
   control. `SoftGlassTheme.amber` *is* white, `amberInk` is black, so
   `AmberCapsuleStyle` renders a solid white capsule with black ink and a black
   shadow. Small actions are outlined circles (`SoftGlassIconButton`).
3. **Colour only where it decorates or reports.** Saturated gradient tiles
   (`SoftGlassTile`) carry one figure each, and big numbers are set as a grid of
   round dots (`DotMatrixDigits`). Each tile takes the ramp of a reference card —
   hot pink into magenta, mint into forest, lilac into plum, violet into indigo,
   royal blue into navy, orange into rust — lit from the top-left corner and
   deepened at the foot so the figure keeps its contrast.

## Files

| File | Holds |
| --- | --- |
| `Design/SoftGlassTheme.swift` | Palette, gradients, radii, the ambient backdrop |
| `Design/SoftGlassComponents.swift` | Gradient tile, dot-matrix digits, white capsule label, glass row, icon button, caption |
| `Design/SoftGlassChrome.swift` | Floating capsule dock, soft-glass header, `AppNavigationChrome`, `AppBarButton`, `AppHidesSystemTabBar` |
| `Design/Glass.swift` | The panel surface, `AmberCapsuleStyle` and `GlassCapsuleStyle` gained a soft-glass branch |
| `Design/Theme.swift` | The shared tokens resolve to the soft-glass values while it is active |
| `Develop/DevelopHomeView.swift` | The redesigned home: dot-matrix time, colour mosaic, stage plan |

## Chrome

- Five tab roots hide the system tab bar (`.appHidesSystemTabBar()`) and the app
  root adds `SoftGlassTabBar` in a bottom safe-area inset: a frosted capsule with
  five circular targets and a solid white disc under the active one.
- Each tab root uses `.appNavigationChrome(index:title:)`, which picks the print
  theme's specimen strip, the soft-glass header (a small tracked label plus an
  optional action) or the system title.
- `AppBarButton` draws a screen's action in whichever language is active, so
  Chemistry's add button is a bar plate in the print theme, an outlined circle in
  soft glass and a toolbar item in the darkroom.

## Home composition

`DevelopHomeView` while Soft Glass is active:

- a greeting and a settings disc,
- a hero panel with the **first sourced development time in the library** set in
  dot-matrix digits, the film/developer/dilution it belongs to, where the time
  came from, and a white "Start a session" capsule carrying a dark circular
  badge,
- a 2×2 mosaic of gradient tiles (films, published temperature, chemicals,
  stages), all reading real counts,
- the six stages as a glass plan.

No figure on that screen is invented: with no documented time the hero shows
`--:--` and says why.


## The running session

`RunningSessionView` keeps one engine and two dresses. In this language the
stage ring gives way to the reference's radial card: the phase or agitation
prompt as its label, the countdown as dot-matrix digits with `min` / `sec`
beneath, the stage's own total on a quiet left/right row, a tick strip whose
needle follows progress, and one page dot per stage. Waiting to start, the
digits are replaced by the white capsule — "Start Developer" — which is the
hands-free target the darkroom's GO circle provides.

The header is the reference's own: an outlined close circle, a centred stage
name with "Stage 2 of 6" beneath, and the working temperature at the right. The
next-action card, the voice line, the spoken answer and the summary sheet are the
same views in both languages; only the chrome and the figure change. No
behaviour differs between the two: the tap-anywhere start, the controls and the
stage strip are the same actions.

## Edges and motion

`Design/ProgressiveBlur.swift` holds the scroll-edge treatment used by Soft
Glass. It wraps `VariableBlurView`, vendored from [nikstar/VariableBlur](https://github.com/nikstar/VariableBlur)
in `Design/ThirdParty/VariableBlur.swift` under its MIT licence: a real
variable-radius blur whose radius follows a gradient mask, installed on a
visual-effect view's backdrop layer. One local change to the vendored file:
the mask uses `CIFilter.smoothLinearGradient`, so the radius eases in and out
instead of ramping in a straight line.

It is scoped to the bars, never to the scrolled content, and both bands are
anchored with an explicit alignment — a plain `.background` would centre a
taller backdrop on its host and leave the band straddling the screen. Both run
from the physical edge of the display (status bar above, home indicator below)
and ease to nothing over a short feather past the bar, so at rest no content is
touched to more than a whisper:

- The header's fade is a background anchored `.top` to the bar, `safeAreaTop +
  bar + 40 pt` tall, offset upward by the safe-area inset (`ScreenInsets.top`)
  so it covers the status bar and the bar in one continuous ramp.
- The dock's fade lives in one full-width layer beside the capsule — not as
  the capsule's background, which would inherit the capsule's width and leave
  the screen edges uncovered. The layer is `safeAreaBottom + dock + 24 pt`
  tall, offset downward, so the fade starts at the home indicator and eases
  out above the top of the dock. Its blur and scrim are lighter than the
  header's, because they land on visible content beside and above the capsule
  rather than on an empty status strip.
- The gradient mask reaches a radius of exactly 0.0 at the band's inner edge —
  any residual blur there is cut off in one frame and reads as a hard line
  through the content.
- Offsetting a background cannot change the bar's layout, so the geometry of the
  screen is untouched. The darkroom keeps the system bars and Apple's own
  scroll-edge effect; the 13th theme keeps its opaque printed strip.

Note: that library reaches a private cue (`CAFilter`'s `variableBlur`) through
obfuscated strings, the same technique Apple's own translucent bars use
internally. It is not a public API; the upstream author reports it passing App
Store review, but it is a risk to weigh before shipping to the store. If the
class is ever absent the component draws nothing rather than a grey band.

Motion:

- The primary capsule collapses its shadow and scales to 0.96 on a
  0.34 s / 0.62 spring, in both the darkroom and Soft Glass dressings.
- The dock's active disc is a single `matchedGeometryEffect` circle, so it
  springs from tab to tab instead of blinking.
- Develop's sections settle in with a staggered spring on first appearance,
  and fall back to a quick fade under Reduce Motion.
- `SoftGlassTopBar` no longer calls `ignoresSafeArea` from inside a
  `safeAreaInset`; that was pushing the bar off-screen and letting content run
  under the status bar.

- `SoftGlassTopBar` no longer calls `ignoresSafeArea` from inside a
  `safeAreaInset`; that was pushing the bar off-screen and letting content run
  under the status bar.

The Veri redesign (copying the supplied dashboard screenshots):

- The field is now black, as the reference screens are. Colour lives in the
  cards and controls, not in the plane behind them; only faint mint, magenta
  and violet blooms bleed in at the screen's foot and top.
- The component vocabulary is the reference's: the weekday circle strip with
  today filled white, the hero figure set in dot-matrix numerals straight on
  black with the wave and marker beneath it, the wide salmon card with a dotted
  ring gauge, and the two-by-two tiles wearing a range bar, a dot row, a tick
  strip and a blurred pool respectively.
- Develop's Soft Glass home is that dashboard: the featured published time is
  the hero figure, and the tiles carry real counts (films, bottles, the
  published temperature, the stage count).
- Session setup's time chooser is the reference's "Complete setup" card: a pale
  pink field with the deep magenta-to-black radial glow pooling behind the
  figure, the development time (or the wanted time) in dots, and a draggable
  tick ruler beneath — the water temperature in "find the time", the wanted
  time in "find the temperature", whose range is the times the 18–24 °C water
  window can actually produce. Every notch answers with a light haptic.
- Tools launch cards and library rows wear the same card language: a ramp in
  the accent's hue lit from its top-left, library rows picking their ramp by
  the record's key so a film always wears the same tile.
- The earlier dark mesh-gradient field was replaced, not extended: it fought
  the reference's black screens. Its card ramps (pink/magenta, mint/forest,
  blue/navy, orange/rust, and the rest) remain and are reused by the tiles and
  row surfaces.

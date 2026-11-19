# Soft Glass — the second design language

Theme 2. A second, complete visual language that replaces the interface rather
than tinting it: its own field, its own chrome, its own controls, its own hero
figures. The darkroom theme is untouched by any of it.

Switch with **Tools → Settings → Themes → Design language → Soft Glass**. The
choice persists across launches (`theme13.theme = softglass`).

## The language

Three ideas, applied everywhere:

1. **A near-black field lit by colour.** `SoftGlassTheme.backdrop()` draws four
   wide blurred blooms — magenta above, violet at the left, blue below, a little
   mint at the foot — on `#060608`. Nothing is a hard shape; the colour reads as
   light in the room. `LiquidBackdrop` swaps to it while the language is active,
   so every screen that already uses the backdrop adopts it without changes.
2. **White for anything you can press.** There is no coloured accent on a
   control. `SoftGlassTheme.amber` *is* white, `amberInk` is black, so
   `AmberCapsuleStyle` renders a solid white capsule with black ink and a black
   shadow. Small actions are outlined circles (`SoftGlassIconButton`).
3. **Colour only where it decorates or reports.** Saturated gradient tiles
   (`SoftGlassTile`) carry one figure each, and big numbers are set as a grid of
   round dots (`DotMatrixDigits`).

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

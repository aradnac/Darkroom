# Themes

Fourteen themes, chosen in one place: Settings → Appearance (or the gear on the
Develop screen). The choice is remembered between launches. The default is
**Darkroom**, then **Soft Light**, then the design languages.

A design language is not a tint: it brings its own navigation structure, screen
layouts, type ramp, controls, surfaces, borders, shadows, page motion, background
and information density. The app's data, maths and engine are untouched — every
theme reads the same `LibraryStore`, `ChemistryStore`, `JournalStore` and
`SessionSetupView`.

There is one theme list and one palette:

- `ThemeLanguage` (in `Languages/DesignLanguage.swift`) lists the fourteen themes
  in the order Settings shows them. Darkroom keeps the raw value earlier builds
  stored for it.
- `ThemeLanguageStore` is the single source of truth for the chosen theme, its
  brightness, text size, motion, reduced motion and density.
- `Preferences.accent` is the palette, a choice of nine lamps. It lights every
  theme: `DLSpec.palette(isDark:accent:)` applies it to the twelve design
  languages, and `Theme` and `SoftGlassTheme` read it for Darkroom and Soft Light.
- `AppearanceStore` holds no choice of its own. It publishes the revision the
  native tab stack is rebuilt on, and the Settings sheet state.

## The themes

01 **Darkroom** — the app's own dark interface: frosted panels, a capsule dock, a
lit bench behind everything.
02 **Soft Light** — a black field lit by the palette, white capsules for anything
you can press, and colour cards for the figures.
03 **Clean** — hairlines instead of cards, very generous space, one quiet dock.
04 **Fluent** — an acrylic pivot bar on the phone and a sidebar on the iPad.
05 **Material 3** — tonal containers, a pill-indicator navigation bar and an
extended floating action button.
06 **Swiss** — a numbered rail down the leading edge; everything else on a strict
twelve column grid.
07 **Brutalist** — three-pixel rules, hard offset shadows, block navigation,
uppercase at full volume.
08 **Neumorphic** — surfaces pressed out of one soft field, a raised tray for the
tabs, pressed-in selected states.
09 **Cyberpunk** — angular clipped panels, corner brackets, scanlines, a HUD rail
and a phosphor glow.
10 **Retro Analog** — film frames with sprocket edges, monospaced labels at a
safelight, a needle meter and mechanical dials.
11 **Editorial** — a serif masthead across the top, numbered folios, ruled
columns and a pull quote.
12 **Skeuomorphic** — brushed metal panels with screws in the corners, a physical
switchboard, a rotary dial.
13 **Terminal** — a prompt instead of a tab bar, monospaced information panels and
data-dense rows.
14 **Recorder** — one flat colour from edge to edge, taken from the palette, with
black type on it: a bold masthead and a chevron menu, a disc of square dots that
fills to the featured time, a tabular readout, and a two-by-two deck of black
knobs with a signal dot, each reading one figure. It is the one theme that is
always light, because black type on the field is the whole look.

## Files

| File | What it is |
| --- | --- |
| `Languages/DesignLanguage.swift` | The fourteen themes, their metadata, the store, and the runtime that reads the active theme. |
| `Languages/DesignLanguageSpec.swift` | The palette, type ramp, geometry, navigation, layout, surface, button, background and motion of each theme. |
| `Languages/DesignLanguageGraphics.swift` | The field of each theme, plus grain, scanlines, sprockets and signature marks. |
| `Languages/DesignLanguageComponents.swift` | The shared component API — panel, button, label, chip, section header, figure, row, stat, note, segmented, switch, dial, meter. |
| `Languages/DesignLanguageNavigation.swift` | Fourteen navigations. Selection indicators glide between places with matched geometry. |
| `Languages/DesignLanguageScreens.swift` | The Develop front door laid out for each theme. |
| `Languages/DesignLanguageRootView.swift` | The theme root: cross-fade between themes, and each theme's page motion between places. |
| `Languages/DesignLanguageAppearanceView.swift` | The Appearance section: theme grid, palette, brightness, text size, motion, density, and the live preview. |
| `Languages/DesignLanguageChrome.swift` | The system navigation bar, dressed for the active theme. |

## Page motion

Each theme moves between its five places with its own motion (`DLPageMotion`):
Material uses a shared-axis slide, Fluent and Clean a plain slide, Swiss and
Retro Analog an edge move, Neumorphic and Skeuomorphic a lift, Editorial a
drift, and Brutalist, Cyberpunk and Terminal a hard cut. Nothing fades a page
in place. Reduce Motion, and the Reduce Motion switch in Appearance, remove all
of it.

## Brightness

`ThemeLanguage.brightnessMode` says whether a theme follows the brightness
setting, or draws one of its own: Darkroom, Soft Light, Cyberpunk and Retro Analog
are always dark, Recorder is always light, and the rest follow. The Appearance
section disables the control where it has no effect and says why.

## Native themes

Darkroom and Soft Light are drawn by the app's own screens rather than by this
module. Their seams are `Theme`, `.glassCard`, the two button styles,
`LiquidBackdrop`, `appNavigationChrome` and `AppearanceStore.isSoftGlassActive`.
See `soft-glass-theme.md` for Soft Light.

## Adding a theme

Add a case to `ThemeLanguage`, a spec in `DLSpec`, a case in `DLBackgroundView`,
a navigation view, a `DLDevelopScreen` layout and a page motion in
`ThemeLanguage.pageMotion`. No other file needs to change.

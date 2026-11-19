# Theme 13 implementation log

## Audit

- Rendering stack: native SwiftUI iOS application; iOS 26 deployment target; iPhone and iPad. The app folder is an Xcode synchronized group, so every Swift file inside `Darkroom/` is compiled without touching the project file.
- Existing appearance system: one dark darkroom style. `Design/Theme.swift` exposes static colour tokens, `Design/Glass.swift` supplies the glass panel and the two button styles, `Design/LiquidBackdrop.swift` draws the animated bench light.
- Navigation and settings: five tabs (Develop, Recipes, Chemistry, Journal, Tools), each owning a navigation stack. There was no Settings screen and no theme registry.
- Persistence: no app preference store existed. Theme keys are new; nothing else is touched.
- Components and assets: native SwiftUI controls and SF Symbols, no third-party UI libraries, no bundled font files, no localisation catalogue. English strings only.
- Styling footprint: colours are centralised in `Theme.swift`, but screens also hard-code font sizes and a few white opacities. The theme therefore redresses the shared layer (tokens, panels, buttons, segmented control, stat tiles, backdrop, tab tint) rather than rewriting each screen's layout.

## Decisions

- The darkroom appearance stays the default. THE 13TH THEME is additive and hidden.
- Settings is reachable from the Tools hub and is presented as a sheet from the app root. That keeps the nine-tap target inside one screen, lets navigation away reset the counter, and allows the tab stack to be re-dressed when the sheet closes without tearing down the presented screen.
- Repeated taps are counted on the non-navigating "Themes" row of Settings. A tap anywhere else in the screen, a gap of two seconds, backgrounding or dismissal resets the count. Exactly nine consecutive taps unlock; eight never do.
- Fonts: the repository ships no font files or licensing metadata, so each typographic role is carried by the closest system face and width variant (expanded black for display, compressed black for condensed, serif for editorial, monospaced for figures and letter fields). The visual grammar — texture, marks, palettes, layout — is built procedurally in Core Graphics.
- Dark variants are derived by blending each palette's inverse field toward white, so every palette keeps its identity in dark appearance instead of collapsing to one grey.
- The print theme uses flat fills, zero radii and hard offset duplicates only. No blurred shadows and no decorative gradients, per the brief.

## Implementation

- `Theme13/Theme13Palette.swift` — colour maths, the nine palettes with their resolved light/dark variants, the preference enums, and `Theme13SettingsStore` (unlock counter, theme, palette, brightness, text size, motion intensity, still mode, density, system brightness tracking, revision counter).
- `Theme13/Theme13Type.swift` — the type scale, scaled by the text-size preference.
- `Theme13/Theme13Graphics.swift` — bursts, stars, asterisks, thorns, quatrefoils, the spiral, sprocket strips, the mono letter field and the procedural camera plate.
- `Theme13/Theme13Texture.swift` — deterministic noise, halftone, dither, grain, dust, creases, blur-dot plates, stipple plates, hatching, torn paper and the pixel-stair river.
- `Theme13/Theme13Components.swift` — paper surface with misregistration, section headers, film-strip divider, the per-palette print backdrop, the grit-sweep unlock reveal and the specimen preview plate.
- `Theme13/Theme13SettingsView.swift` — Settings: nine-tap Themes row, design-language choice, 3×3 palette grid, brightness, text size, density, motion intensity, still mode, preview sheet, and a debug-only unlock reset.
- `Theme13/Theme13Motion.swift` — the four hard-stepped poses at 6.4 fps, with no easing, frozen to pose 0 under Reduce Motion or Still mode.
- `Theme13/Theme13Chrome.swift` — opaque paper navigation bars with a hard hairline and a serif title face, a paper tab bar with mono labels, and matching toolbars. Reverts to the system defaults for the darkroom.
- `Theme13/Theme13Navigation.swift` — the theme's own navigation layer: a specimen strip (plate number, rule, tracked uppercase name with one interruption, date micro-label, optional inked action) that replaces the system navigation bar, and a film-strip tab bar (numbered tracked labels, sprocket indicator, burst on the active plate, 44pt targets) that replaces the system tab bar. Both are inert in the darkroom, which keeps Apple's Liquid Glass bars.
- `Theme13/Theme13Screens.swift` — the screen archetypes: the poster cover (micro credit, date, display title over one interruption, cutout hero, film-strip rule, serif caption), the cutout hero itself, the specimen index with numbered rows and sprocket rules, the empty state (a burst cut in paper filled with a mono-letter tone field), and the receipt plate for a finished session.
- `Develop/DevelopHomeView.swift` — the home screen now renders the poster cover and specimen index when the theme is active, and its original layout otherwise.
- `Develop/SessionSummaryView.swift` — a finished roll renders as the receipt plate, with mono figures on paper and block actions; the original summary is untouched when the darkroom is active.
- `Recipes/RecipesView.swift`, `Journal/JournalView.swift` — their placeholders become the themed empty state (cutout plate, typewriter message, numbered notes) when the theme is active, and keep the original layout otherwise.
- `Design/Controls.swift` — overlines switch to mono, tracked caps in the theme; the Tools hub's headline switches to the theme's serif.
- `Design/Theme.swift`, `Design/Glass.swift`, `Design/Controls.swift`, `Design/LiquidBackdrop.swift` — every shared token, panel, button and control now resolves to the print language when the theme is active and to the original darkroom language otherwise.
- `ContentView.swift` — Settings presentation, theme-driven colour scheme, a revision-keyed tab stack so a palette change re-dresses the whole app on dismissal, and the chrome refresh.
- `Tools/ToolsView.swift` — the Settings route.

## Minimal contrast deviation

- Bloom (palette 4) specifies cream paper plates with `#2A1026` text on them, while the field itself is deep plum with cream text. Since every panel in this app inherits one ink token (`Theme.ink`) and the navigation bar draws that same ink directly on the field, the two rules cannot both hold. Rather than invent a second text token across every screen, the palette's plates were made deep plum (`#3A0F33`, raised `#4A1B42`) and the cream is carried by the type, the cutout decoration and the yellow stem ink. Contrast for text and controls is preserved; the palette's reading is unchanged.

## Open items

- No build or visual verification was possible: the remote build machine could not be reached in any session. Everything here has been reviewed statically only, so treat it as unbuilt until the app is run.
- Four of the five tabs and two of the session screens now have a themed composition: Develop has the poster cover and specimen index, Recipes and Journal have the cutout-plate empty state, the finished-session summary has the receipt plate, Tools and Settings are themed at the component level with the theme's serif headline. The Chemistry hub and the session setup and running screens keep their existing layouts, dressed by the shared language and system chrome rather than given archetype compositions, because they are the largest and most interaction-heavy files and cannot be verified without a build.
- The burst wiggles, grain and dust cycle, and navigation and tab chrome are themed; the pixel-stair page wipe and the burst-iris modal transition are not implemented, as SwiftUI's system navigation and sheet presentations do not offer custom transitions without replacing the navigation layer.
- Navigation is now split by theme. The darkroom keeps the system tab bar and navigation bars untouched, so their Liquid Glass is exactly Apple's. While the print theme is active the app hides both and draws its own: a specimen strip at the top of each of the five tabs and a film-strip tab bar at the foot. Pushed destinations and sheets (session setup, the tool screens, the pickers) still use the system bars, dressed by the opaque paper appearance — giving them the theme's own strip and torn-paper sheets is the next step and needs a per-screen back and close control first.
- Type inside the theme scales with the in-theme text size and the system Dynamic Type step, capped at 200%. Text in screens outside the theme still uses fixed sizes.
- The brief's QA matrix (device matrix, screenshot regression across nine palettes, automated contrast audit) cannot be run without a build service.

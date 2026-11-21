# Settings

Every preference the Settings screen owns lives in `Support/Preferences.swift`,
persisted to `UserDefaults` under the `prefs.` prefix and written the moment it
changes. The theme, brightness, text size, motion and density live in
`Languages/DesignLanguage.swift`, because the theme is state rather than a
preference.

## What each one changes

| Preference | Read by |
| --- | --- |
| Temperature scale | `Units.temperature`, so every reading in setup, the running screen, the summary, the library and the Lock Screen card |
| Volume unit | `Units.volume` / `Amount`, so chemical volumes, tank pours and calculators |
| Agitation scheme | `SessionPlan.make` — the developer stage's pattern |
| Agitation intensity | A new `DevelopmentSetup`; the setup screen still overrides it per session |
| Reuse penalty | `CompensationRules.reuseStep`, so `DevelopmentSetup.reuseFactor` and every batch's next-use penalty |
| Extrapolation factor | `TemperatureCurve`, when a temperature falls outside the outermost published time |
| Sound and haptic per event | `Preferences.play`, called by `SessionEngine` and the prompt path |
| Voice prompts | A new `DevelopmentSetup` |
| Voice commands | A new `DevelopmentSetup`, on by default; `SessionEngine.activateVoice` starts the recogniser, and switching it on asks for the microphone and speech permissions at once rather than at the first session |
| Keep awake | `RunningSessionView`, on appear |
| Stop and wash times | A new `DevelopmentSetup` |
| Default fix time | `ClearingSheet`, which offers it instead of timing the leader |
| Final rinse | `SessionPlan.finalRinseSeconds` |
| Theme | `ThemeLanguageStore.selected`, one list of thirteen, read by `ContentView` and `ThemeLanguageRootView` |
| Palette | `Preferences.accent`, one of nine lamps, read by every theme through `DLSpec.palette(isDark:accent:)`, by `Theme` and by `SoftGlassTheme` |
| Brightness, text size, motion, density | `ThemeLanguageStore`, read through `DLStyle` by every theme |
| Reset | `Preferences.resetAll` and `ThemeLanguageStore.reset` |

## Decisions

**Published figures stay as published.** A times table printed at 20 °C reads
20 °C whatever the scale; the reading around it, the slider ends, the session
header and the Lock Screen card follow the chosen unit. The same rule holds for
the tank capacity reference, whose volumes are quoted from the manufacturer.

**One theme, one palette.** The theme is chosen in one place, and the palette is
chosen in one place. The palette applies to every theme, so a choice made on
Darkroom is the same lamp on Fluent, Terminal and Soft Light.

**One Appearance entry.** Settings holds one Appearance row. It opens the theme
grid, the palette, brightness, text size, motion and density. Compact controls
were a separate switch; they are now the Compact density.

**A switch is not a button.** In the Soft Light theme white means *pressable*,
so a switch tinted white drew a white knob on a white track: one blank pill.
Switches take `Theme.switchTint` — the palette in Darkroom, a quieter grey in
Soft Light.

**The Lock Screen card carries a formatted string.** The widget extension cannot
read the app's preferences, so the activity state holds `temperatureText` rather
than a bare number.

**Reset returns everything.** Every stored preference returns to its default,
including the theme and the density.

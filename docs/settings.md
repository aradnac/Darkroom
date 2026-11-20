# Settings

Every preference the Settings screen owns lives in `Support/Preferences.swift`,
persisted to `UserDefaults` under the `prefs.` prefix and written the moment it
changes. The theme and its palettes stay in `Theme13SettingsStore`, because the
hidden language's unlock is state rather than a preference.

## What each one changes

| Preference | Read by |
| --- | --- |
| Temperature scale | `Units.temperature`, so every reading in setup, the running screen, the summary, the library and the Lock Screen card |
| Volume unit | `Units.volume` / `Amount`, so chemical volumes, tank pours and calculators |
| Agitation scheme | `SessionPlan.make` — the developer stage's pattern |
| Agitation intensity | A new `DevelopmentSetup`; the setup screen still overrides it per session |
| Reuse penalty | `CompensationRules.reuseStep`, so `DevelopmentSetup.reuseFactor` and every batch's next-use penalty |
| Extrapolation factor | `TemperatureCurve`, when a temperature falls outside the outermost published time |
| Sound and haptic per event | `Preferences.play`, called by `SessionEngine` and the Troubleshooter-free prompt path |
| Voice prompts | A new `DevelopmentSetup` |
| Voice commands | A new `DevelopmentSetup`, on by default; `SessionEngine.activateVoice` starts the recogniser, and switching it on asks for the microphone and speech permissions at once rather than at the first session |
| Keep awake | `RunningSessionView`, on appear |
| Stop and wash times | A new `DevelopmentSetup` |
| Default fix time | `ClearingSheet`, which offers it instead of timing the leader |
| Final rinse | `SessionPlan.finalRinseSeconds` |
| Appearance and colour palette | `Theme` — the nine lamps, each with the second light its backdrop is bloomed with — and the print language's `Theme13SettingsStore` |
| Reset | `Preferences.resetAll` and `Theme13SettingsStore.resetPreferences` |

## Decisions

**Published figures stay as published.** A times table printed at 20 °C reads
20 °C whatever the scale; the reading around it, the slider ends, the session
header and the Lock Screen card follow the chosen unit. The same rule holds for
the tank capacity reference, whose volumes are quoted from the manufacturer.

**The accent belongs to the whole app's field.** Nine lamps — safelight, ruby,
ember, rose, violet, sky, ice, mint, lime — replace the amber ramp in
`Theme.amber`, `amberSoft`, `amberDeep`, `amberInk`, `amberGradient` and the
backdrop. Each one also names a second light (`AccentChoice.bloom`), and
`LiquidBackdrop` blooms the field with both, so every screen carries a gradient
rather than one flat wash. Soft Glass follows the same lamp: its near-black field
keeps the reference's composition, but the three washes bleeding in at the edge
are the chosen lamp's soft light, bloom and base, and its captions take the
accent. Its controls stay white, because white is what "pressable" means in that
language. The print language keeps its own nine palettes by design.

**Design, not two sections.** Language, palette and appearance are one section in
Settings: the three design languages, the nine lamps, the print palettes and the
text size, motion and density controls sit together, because they are all
answers to the same question.

**A switch is not a button.** In the soft-glass language white means *pressable*,
so a switch tinted white drew a white knob on a white track: one blank pill.
Switches take `Theme.switchTint` — the accent in the darkroom and the print
language, a quieter grey in soft glass.

**Brightness is the print language's.** The darkroom language is dark and the
soft-glass language is light by definition, so the system / light / dark choice
applies to the 13th theme and says so on the screen.

**The Lock Screen card carries a formatted string.** The widget extension cannot
read the app's preferences, so the activity state holds `temperatureText` rather
than a bare number.

**Reset keeps the unlock.** Every stored preference returns to its default,
including the chosen design language, but the hidden theme's unlock flag is left
alone: the theme's specification says the unlock is never reset by the UI.

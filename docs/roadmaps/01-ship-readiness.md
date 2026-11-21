# Roadmap 1 — Ship readiness

What stands between this build and an App Store upload that is accepted and
installable. Nothing here changes how the app behaves at the sink; these are
identity, compliance, review risk and the verification harness.

Do them in this order. Steps 1–5 are small and independent and can go in five
consecutive commits.

---

### 1. Own the app's identity

**Blocking · 8 identifiers, 2 entitlements, 1 README**

**What is wrong.** Every product identifier is still the template's:
`com.organizationName.Darkroom` for the app (`project.pbxproj` 521 and 555),
`com.organizationName.DarkroomTests` (576, 594),
`com.organizationName.DarkroomUITests` (611, 628), and
`com.organizationName.Darkroom.darkroomwidgetextension` for the extension
(655, 685). Both entitlement files declare the same placeholder App Group
(`Darkroom/Darkroom.entitlements:7`,
`DarkroomWidgetExtension/DarkroomWidgetExtension.entitlements:7`). `README.md`
125–127 says so in the open. Nothing here can be uploaded, and an unsigned
device build installs under an identity that isn't the reader's.

**What to change.** Replace the app's bundle ID with one you own; derive the
test IDs from it; keep the extension as `<app id>.widget` (the current
`.darkroomwidgetextension` suffix is legal but reads as generated). Change the
App Group to `group.<new app id>.shared` in **both** entitlement files — the app
and the extension must agree or the Live Activity cannot be scheduled. Update
the note in `README.md`.

**Coupling.** `ApiKeyManager` derives its AES key from the last component of the
bundle ID (`Utils/ApiKeyManager.swift` 36–44 and 243–247). A new bundle ID
silently changes that key. Do step 4 first or in the same change; do not leave
a key importer whose decryption key depends on a name that just changed.

**Verify.** Build for the simulator and for a device; run a full session and
confirm the Live Activity still appears on the Lock Screen and in the Dynamic
Island (it is the only cross-target contract here). Install on a registered
device.

**Leave alone.** The two copies of the activity attributes
(`Support/SessionActivityAttributes.swift` and
`DarkroomWidgetExtension/DarkroomWidgetExtension.swift` 28–49). They are
intentionally identical and matched by type name.

---

### 2. Add the privacy manifest and answer export compliance

**Blocking · 2 new files, 1 plist**

**What is wrong.** There is no `PrivacyInfo.xcprivacy` anywhere in the
repository (verified by search), and `Info.plist` has no
`ITSAppUsesNonExemptEncryption`. UserDefaults is a required-reason API and is
read all over: the whole of `Support/Preferences.swift`, the chosen language and
density in `Design/Appearance.swift` 54, 73–74, 87–88, library favourites in
`Library/LibraryStore.swift` 58, 69, 249, and the key importer's flag. Without
the manifest an upload is rejected or warned; without the export key, App Store
Connect asks the same question on every build.

**What to change.** Add `Darkroom/PrivacyInfo.xcprivacy` and
`DarkroomWidgetExtension/PrivacyInfo.xcprivacy`, both declaring
`NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`. Declare the
data the app collects: none — the journal, photos and library stay on the
device. Set `ITSAppUsesNonExemptEncryption` to `false` in `Info.plist`. Declare
file-timestamp APIs only if they are genuinely used; `Data(contentsOf:)` is not
one, so do not copy a manifest wholesale.

**Verify.** `xcodebuild archive` then upload to App Store Connect; the warning
list must be clean and TestFlight must process the build. Check the extension
too — its manifest has to ship inside the `.appex`.

**Leave alone.** The three usage strings already in `Info.plist` (camera,
microphone, speech). They are accurate.

---

### 3. Complete the app icon

**High · 1 asset set**

**What is wrong.** `Assets.xcassets/AppIcon.appiconset/Contents.json` declares a
dark and a tinted slot (lines 9–30) but neither entry has a `filename`. Only
`AppIcon.png` exists. On iOS 18's dark and tinted home screens the app falls
back to the light icon while every other icon on the screen changes.

**What to change.** Produce the two missing 1024×1024 variants in the same
palette: the dark one on the app's near-black field
(`DarkroomThemeDefaults.base`), the tinted one as a grayscale luminance image
that the system tints. Wire both entries. Verify the light icon has **no alpha
channel** — App Store Connect rejects an icon with transparency.

**Verify.** Look at all three appearances on a device home screen; run the
upload and confirm the icon passes validation.

**Leave alone.** The light icon's art.

---

### 4. Delete the key importer that logs

**High · 2 files**

**What is wrong.** `Utils/ApiKeyManager.swift` is referenced only by itself —
search finds 33 matches, all inside that file — and `ENCRYPTED_KEYS.plist` is an
empty `<dict/>` (6 lines). The project has no API keys. Worse, the initialiser
removes its own "initialized" flag on every launch (line 21), so the importer
re-runs and re-logs every time; it prints `"calling get"` (52), the first 500
characters of the plist (112), every key name (128) and each decrypted value's
length (149, 232). A release build must not put key material or its shape on the
console, and an unused keychain writer is an unnecessary surface.

**What to change.** Delete `ApiKeyManager.swift` and `ENCRYPTED_KEYS.plist`.
The folder is a synchronized group, so no project-file edit is needed. If a
key is genuinely planned later, keep the file but gate the importer and its
logging behind `DEBUG` and remove the plist-content prints — do not ship the
importer as it is.

**Verify.** Release build; grep the console for key material; search the project
for `ApiKeyManager` and confirm no references remain; build the test target.

**Leave alone.** Nothing else. This step should touch exactly two files.

---

### 5. Settle the private blur before review

**High · 1 vendored file, 2 design files, 1 doc**

**What is wrong.** `Design/ThirdParty/VariableBlur.swift` reaches `CAFilter`'s
`variableBlur` through obfuscated strings. It is not public API.
`docs/soft-glass-theme.md` 126–130 already records it as an App Store risk and
notes the component draws nothing if the class is absent — so a review
rejection would land on the Soft Glass header and dock fade, and the fallback is
invisible rather than graceful.

**What to change.** Decide now, not after a review round:

- **Keep it.** Leave the vendored file untouched, but make the absent-class case
  draw a plain scrim instead of nothing, and record the decision in
  `docs/soft-glass-theme.md`.
- **Replace it.** Swap the two bands (`Design/ProgressiveBlur.swift`, used by
  `ContentView.dockBand` 118–141 and the Soft Glass header) for a public
  Material or scroll-edge treatment. The Soft Glass chrome must still ease to
  nothing over content at rest; that is the only visual requirement.

**Verify.** Soft Glass, a long scroll: no hard line through content, no content
running under the status bar or the dock. Then choose with the risk understood,
not in a rush.

**Leave alone.** The darkroom's system navigation and tab bars, which use the
system's own effect (`docs/soft-glass-theme.md` 123–124).

---

### 6. A CI signal on every change

**High · 1 workflow**

**What is wrong.** `.github/workflows/build-ios.yml` runs only on
`workflow_dispatch` (line 5), archives with `CODE_SIGNING_ALLOWED=NO` and
`CODE_SIGNING_REQUIRED=NO` (34–35), and packages an unsigned IPA that cannot be
installed. It never runs `DarkroomTests`. The project has three real unit suites
and a full test target, and nothing gates them.

**What to change.** On push and pull request: build for a simulator destination
and run the unit tests, failing the job on either. Keep the archive step for
release tags or manual runs, and stop calling the unsigned IPA an installable
artifact. Do not hard-code a simulator name that a future runner image may drop
— derive one from `xcrun simctl list devices available`.

**Verify.** Open a pull request, see the job green. Introduce a deliberately
failing assertion, confirm red, revert. Then confirm the test job still passes on
a commit that only touches docs.

**Leave alone.** The release archive path used for uploads.

---

### 7. Make the build settings bind

**High · 1 project file, 1 plist**

**What is wrong.** Both app configurations set `GENERATE_INFOPLIST_FILE = NO`
and a hand-written `INFOPLIST_FILE` (`project.pbxproj` 508–514, 542–548) while
also carrying `INFOPLIST_KEY_*` settings for orientations, the scene manifest,
launch screen and indirect input. Those keys populate a *generated* Info.plist;
with a supplied plist they do not reach the bundle. The real `Info.plist` only
declares orientations for iPad (32–38), so iPhone still accepts portrait and both
landscapes by default — while the running screen stacks a 240-point ring,
header, card, two control rows and a stage strip in one column. The two settings
systems disagree about what the app supports.

**What to change.** Pick one source of truth. Either move the keys into
`Info.plist` and delete the inert settings, or switch to a generated plist and
move the custom keys in. Then decide the orientation question: portrait-only on
iPhone for 1.0 (the smallest change that matches the layout), or build the
landscape session (Roadmap 2, step 6). iPad keeps all four orientations.

**Verify.** Build, unzip the `.app`, read the resulting `Info.plist` and confirm
the keys are what you intended. Rotate a simulator through every orientation.

**Leave alone.** The iPad orientation set, including upside-down.

---

### 8. A dry run that proves it

**High · closing step**

**What is wrong.** None of the above can be declared done from a simulator: the
Live Activity, the icon appearances, the privacy manifest and the signed
identity only exist end to end on a device and in App Store Connect. The
roadmap's own promise is only real if it survives the real pipeline.

**What to change.** Run the pipeline once, completely:

1. Archive and upload to App Store Connect; confirm processing and TestFlight
   install.
2. On a device: install from TestFlight, run a full six-stage session with the
   phone locked, and confirm the Live Activity in the Dynamic Island and the
   Lock Screen.
3. Check the icon at all three appearances.
4. Correct the README's widget claim. It says "a widget shows the state of the
   bench" (README 17–18), but the extension only declares an Activity
   configuration (`DarkroomWidgetExtension.swift` 55) and returns only the Live
   Activity from its bundle (240–242). Either add a home-screen widget or change
   the sentence. Do not ship copy the binary does not deliver.
5. Record what was proven and what still needs a device in
   `docs/performance-pass.md`'s "still to measure" spirit.

**Verify.** A build that a stranger could install from TestFlight and run a roll
with.

**Leave alone.** Every feature. This step proves; it does not add.

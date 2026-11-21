# Roadmap 2 — Session integrity

The app exists to run a roll honestly while both hands are wet. Everything in
this roadmap is about the session telling the truth and staying coherent when
the phone is locked, the app is backgrounded, the stage ends early or the reader
looks at it an hour later.

Do these in order. Steps 1–5 change behaviour the reader can observe; 6–7 are
platform edges.

---

### 1. Survive an hour away from the app

**Critical · `Develop/SessionEngine.swift` 219–264**

**What is wrong.** The engine measures elapsed time from dates, so the timer is
right while the phone sleeps. But the return path is one tick:
`refresh()` (219–224) calls `tick()` once (243–264), which can complete at most
the current stage and then lands on a `.ready` phase with no sign that time
passed. A reader who comes back after forty minutes finds, say, "Developer, tap
to start" — the same screen they left — with no statement that the developer
finished at 21:04 and three stages went by. The Lock Screen card keeps whatever
state it was last given.

**What to change.** Record when the app left the foreground, and on return:

- If a stage ended while away, say so before asking for the next GO — a line
  such as "Developer finished 38 minutes ago. Next: Stop." Nothing else changes
  hands-free.
- Carry that fact into the Live Activity update so the card is not silently
  stale while the app was away.
- Keep the rule that one stage completes per return; do not auto-run a second
  stage. The reader still starts each stage.

**Verify.** Start a twelve-minute developer, lock the phone, wait past the stage
end, come back. The screen must state what happened and where the session
actually is. Add this as a test (Roadmap 4, step 7) — "gone for forty minutes
during a twelve-minute developer".

**Leave alone.** The date-based timing, the 0.1 s tick, `preciseNow` and the
publish-cadence logic (243–264). They are correct and were tuned deliberately
(`docs/performance-pass.md` 8–33).

---

### 2. Make the Live Activity stale date tell the truth

**High · `Support/SessionActivityController.swift` 35, 48**

**What is wrong.** The activity is started and updated with
`staleDate: Date().addingTimeInterval(3600)`. A stand development, a long
Rodinal dilution or a stop that runs past an hour greys out the Lock Screen and
Dynamic Island card while the session is still going. The reader sees a dead
card and stops trusting it.

**What to change.** Compute the stale date from what the card actually shows:
the current stage's remaining time plus a margin (the next prompt, not the
stage end, if that is sooner). Keep the one-hour fallback only for a stage with
no end. Refresh on foreground as the view already does
(`Develop/RunningSessionView.swift` 63–68).

**Verify.** Start a stage longer than an hour (or set a very long fix or wash
time in the setup), lock the phone, wait past the old hour mark. The
card must still be live. Also confirm a finished session's card does not outlive
it.

**Leave alone.** The `.timer`-style countdowns: rendering from `stageEndDate` is
what lets the system tick without the app waking.

---

### 3. Carry the chosen lamp to the Lock Screen

**High · 2 attribute copies, 1 controller**

**What is wrong.** `SessionActivityPalette.accent` in the widget is a hard-coded
`.orange` (`DarkroomWidgetExtension/DarkroomWidgetExtension.swift` 143). A
reader who has picked ruby, ice or lime gets an amber card on the Lock Screen
and in the Dynamic Island. The widget cannot read the app's preferences, so the
colour has to travel in the state — the same reason `temperatureText` is already
a formatted string (`docs/settings.md` 56–58).

**What to change.** Add the resolved accent (and the ink that sits on it) to
`ContentState` in **both** copies of the attributes
(`Support/SessionActivityAttributes.swift` 24–46 and the widget's 29–46; they
must stay identical). Fill them in `SessionActivityController.state(for:)` from
the active palette. Tint the card background, the keyline, the next-action row
and the Dynamic Island regions from the state instead of the constant. Keep a
sensible fallback for an activity created before the update.

**Verify.** Pick ruby, run a session, lock the phone: the Lock Screen card and
the Dynamic Island must be ruby. Switch to lime, run again: lime. Confirm the
dark background and the white timer keep their contrast.

**Leave alone.** The Dynamic Island's layout — that is Apple's — and the
existing `temperatureText` field.

---

### 4. Mark interpolated times as worked out

**High · `Models/Compensation.swift` 47–54, 56–68**

**What is wrong.** `TemperatureEstimate.isEstimate` returns `false` for
`.interpolated`. The setup screen draws `compensationIsEstimate` as the
"sourced" checkmark (`Develop/SessionSetupView.swift` 652–662), so a time
interpolated between two published temperatures is shown as if someone printed
it. Interpolation is arithmetic the app did between two points, not a figure
anyone published.

There is a second, related honesty gap: `DevelopmentSetup.compensation` (83–88)
applies the continuous-agitation reduction on top of a **measured** published
reading, yet the note still reads "Published time at 20 °C" while the number is
10 % shorter. The marker and the note must match the number.

**What to change.** Return `true` for `.interpolated`, give it wording that says
"worked out between your 18 °C and 24 °C times", and keep only a true measured
point reading as sourced. Where a published reading is then adjusted for
continuous agitation, change the note (or the estimate case) so the reader is
told the figure was adjusted and why. Do not change the arithmetic itself
without a test proving the new number.

**Verify.** Unit tests in `DarkroomTests`: an exact published point reads as
measured; a two-point interpolated time is flagged and its note says worked out;
the continuous-agitation case states the adjustment. Check the setup screen's
icon, ink and note for all four cases.

**Leave alone.** The log-domain blending, the extrapolation factor and the
`clamp` bounds in `TemperatureCurve` (124–151). Only the labels and the flag
change.

---

### 5. Ask for alerts once, schedule them once

**High · `Develop/AgitationAlerts.swift` 15–54, `SessionEngine` 320–342**

**What is wrong.** `AgitationAlerts.requestPermission()` runs in
`RunningSessionView.onAppear` (54), i.e. every time a session opens, and on a
fresh install the prompt lands mid-setup with chemistry already poured.
`AgitationAlerts.schedule` (21–46) cancels and re-adds up to thirty
notification requests on every prompt change; the engine calls it from
`announcePromptIfChanged` (317) and `addTime` (197). That is a lot of
notification churn on a device whose job is to not miss an agitation.

**What to change.** Ask once, at a deliberate moment — the first run (Roadmap 3,
step 3) or before the first session, with a sentence saying what the alerts are
for and what happens without them. Then schedule the stage's remaining prompts
once, when the stage starts or when the app goes to the background, and leave
the queue alone while it runs. Rebuild only when the stage or its duration
actually changes.

**Verify.** Fresh install: no permission prompt mid-setup. Loss of permission:
the in-app prompts still sound and buzz, and the session never depends on a
notification to function. With a stage of several prompts, inspect the pending
notification queue and confirm it is stable, not rewritten each minute.

**Leave alone.** The in-app prompt choreography and the sound/haptic mapping
(`SessionEngine` 448–460, `Preferences.play`). Notifications are a backup for a
dark screen, never the primary prompt.

---

### 6. Make landscape work, or turn it off

**High · `Info.plist` 32–38, `RunningSessionView` 100–118**

**What is wrong.** The iPhone target ends up supporting landscape (Roadmap 1,
step 7 explains why the plist and the build settings disagree), but
`darkroomBody` stacks a 240-point ring, header, next-action card, two rows of
controls and a stage strip in one column — far taller than a landscape iPhone's
height. Nothing in the app caps its reading width either (no `maxWidth: 5xx` or
`6xx` anywhere outside the dock). Landscape is either broken or untested.

**What to change.** Decide for 1.0:

- **Portrait only on iPhone.** One line in `Info.plist`, iPad unchanged. The
  honest smallest change.
- **Build it.** A two-column landscape session — ring and next action on one
  side, controls and stages on the other — and a walk through every tab in
  landscape, including the sheets and the library.

Whichever you choose, write it down (README's Building section) so the next
person does not rediscover it.

**Verify.** Rotate a simulator through all four orientations on every tab and in
the running session. If portrait only, confirm iPad still rotates.

**Leave alone.** The portrait layout's spacing and the ring's proportion; a
landscape layout is an addition, not a redesign of the portrait one.

---

### 7. Make sure the Live Activity ends when the session does

**Medium · `SessionActivityController` 23–61, `RunningSessionView` 56–61**

**What is wrong.** The card is started on the running screen's `onAppear` and
ended on `onDisappear`. If the app is killed, crashes, or the screen is dismissed
by a path that does not run `onDisappear`, the activity survives — and a Live
Activity that says "Developer · 04:12" for a session that no longer exists is
worse than no card at all. A second session ends the previous one
(`begin` calls `endActivity`), which is right, but nothing cleans up an orphan
on the next launch. `update` also does nothing once `activity` is nil, so a
failed start (activities disabled) never recovers.

**What to change.** On launch, end any activities for this app that are not the
current session. On foreground, re-create the activity if the session is live
and the activity is missing. Make the end path as broad as the start path: a
single `SessionActivityController.endAll()` called from app termination and from
the session's close path. Never leave a card ticking for a dead engine.

**Verify.** Start a session, force-quit the app, relaunch: no card. Start, close
the cover, reopen: one card, correct state. Turn Live Activities off in Settings
and start a session: no crash, and turning them back on plus foregrounding
restores the card.

**Leave alone.** The `ContentState` shape beyond step 3's additions, and the
"one activity per app" rule.

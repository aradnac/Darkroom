# The time / temperature converter

A development time is only true at the temperature it was measured at. The
converter moves it to the temperature the bench is actually at, and it is the
same engine the Massive Dev Chart's Time/Temp Converter runs.

## The formula

    t = t₀ · e^(α(T₀ − T))        α = 0.1 per °C, T in Celsius

`t₀` is the time the datasheet or chart gives at `T₀`; `T` is where the tank
really is. Ten degrees cooler multiplies the time by *e*; ten degrees warmer
divides it by *e*. A fixed 10 % comes off when the tank is worked continuously
instead of at intervals, because a chart's time assumes intermittent agitation.

Both temperatures are converted to Celsius before anything is worked out, so the
app reads in °F without changing the arithmetic. The result is rounded to the
nearest second.

## The other way round

Asking for a time instead of a temperature inverts the same relation:

    T = T₀ − ln(t / (t₀ · k)) / α        k = 0.9 for continuous agitation, else 1

`DevelopmentTimeCalculator.temperature(forSeconds:…)` is that inverse, and both
the tool and session setup use it, so "10:00 instead of 13:00" answers with the
water that does it. The session setup rounds to a tenth of a degree — a whole
0.5 °C step would move a ten-minute time by about 35 seconds.

## Where the numbers come from

The calculator was written for Digitaltruth by Matthew Roughan and is the one
behind `devchart.php?doc=timetemp`; he publishes the formula and a port of the
calculator on his own site. `Models/DevelopmentTimeCalculator.swift` implements
that formula directly.

Two discrepancies are worth recording:

- **Continuous agitation.** Digitaltruth's help text says times are "automatically
  reduced by 15 %". The calculator's own control reads `Yes (-10%)`, and
  Roughan's published port says 10 %, "used by the original calculator". The code
  is followed here, not the prose.
- **Warnings.** The original warns when the temperature difference is large or
  the result is short, but does not publish its thresholds. The app warns past
  5 °C (9 °F) of difference and below 5 minutes. They are the app's thresholds
  and are stated as guidance, not as the original's numbers.

## Where the app uses it

**Tools → Times & temperature.** The converter itself, in either direction: the
time from the sheet, the temperature it is for, and then either the water you
have (which gives the time) or the time you want (which gives the water), with
the warnings and a table of nearby temperatures.

**Session setup.** A new session asks for one time from the sheet and the
temperature it is for — "your sheet says 13:00, at 20 °C" — and nothing else.
From there the same converter answers both questions: *find the time* takes the
water temperature with a slider and shows what to develop for; *find the
temperature* takes the time you want and moves the water to the temperature that
gives it. When two or more times are entered from the sheet, `TemperatureCurve`
interpolates between them instead — documented points beat a formula — and
extrapolates past the outermost one using the extrapolation factor in Settings.

The `calculated` case on `TemperatureEstimate` marks a converter result so the
setup can say where the number came from rather than presenting it as published.

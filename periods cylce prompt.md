# ROLE

Act as a Senior Full-Stack Software Engineer, Flutter/Dart Architect, Algorithm Engineer, Data Engineer, QA Engineer, and menstrual-health domain-aware software architect.

You are modifying an existing production Flutter mobile application called **SYD FLOW**.

The existing architecture is:

- Flutter / Dart
- MVVM
- Clean Architecture
- Firestore
- ChangeNotifier / Provider
- Pure Dart cycle calculation domain layer
- Existing cycle UI
- Existing workout recommendation integration
- Existing authentication
- Existing user profile
- Existing notification system

Your responsibility is to improve the **menstrual cycle tracking and prediction engine** without breaking the existing application.

---

# 1. ABSOLUTE OBJECTIVE

The current system is technically well structured but its menstrual-cycle algorithm is too deterministic.

The goal is to evolve it into a:

> **personalized, evidence-aware, uncertainty-aware menstrual cycle tracking and prediction engine**

while preserving the existing application architecture and user experience.

The new engine must distinguish between:

1. User-observed data
2. Historical data
3. Algorithmic estimates
4. Predictions
5. Confidence/uncertainty
6. Confirmed user corrections

The system must never present an algorithmic calendar estimate as if it were a medically confirmed biological measurement.

---

# 2. NON-NEGOTIABLE PRODUCTION SAFETY RULES

These rules apply to EVERY phase.

## DO NOT:

- rewrite the entire cycle feature
- replace the existing architecture
- migrate Flutter to another framework
- replace Firestore
- change authentication
- change unrelated features
- redesign screens
- change navigation
- change existing layouts
- change colors
- change typography
- change existing workout UI
- change unrelated Firestore collections
- change unrelated APIs/services
- remove existing functionality
- remove existing user history
- delete existing cycle data
- silently modify historical user data
- introduce an ML model without explicit approval
- introduce an LLM into cycle calculations
- invent medical facts
- present estimated ovulation as confirmed ovulation
- modify the frontend merely to hide algorithmic problems

---

# 3. EXISTING ARCHITECTURE MUST BE PRESERVED

Preserve the current structure unless a change is demonstrably required:

```text
lib/
  features/
    cycle/
      data/
      domain/
      presentation/

  core/
    services/
```

The existing:

```text
CycleCalculator
CycleStateNotifier
CycleProvider
CycleService
DayJournal
CycleStatus
CyclePredictions
CyclePhase
```

must remain compatible with existing consumers wherever reasonably possible.

Prefer:

> additive evolution

over:

> destructive replacement.

If an existing public model must change, first identify every consumer and provide a backward-compatible migration strategy.

---

# 4. CRITICAL DOMAIN PRINCIPLE

Never confuse:

```text
OBSERVATION
```

with:

```text
PREDICTION
```

User-entered information has higher authority than algorithmic estimation.

Authority hierarchy:

```text
1. User-confirmed observation
2. Explicit user correction
3. Observed flow/history
4. Historical statistical pattern
5. Calendar-based prediction
6. Generic population assumptions
```

A prediction must NEVER overwrite an observation.

---

# 5. PHASE EXECUTION RULE

Implement this project in the phases below.

### VERY IMPORTANT

Do NOT implement all phases at once.

For every phase:

1. Inspect current implementation.
2. Identify affected files.
3. Explain root cause.
4. Explain proposed change.
5. Implement only that phase.
6. Run static analysis.
7. Run tests.
8. Run regression checks.
9. Verify existing functionality.
10. Report exact changes.
11. Report remaining risks.
12. STOP.

Do not automatically continue into the next phase.

---

# PHASE 0 — FORENSIC BASELINE

## Objective

Before changing code, inspect the complete existing menstrual-cycle implementation.

Inspect at minimum:

```text
lib/features/cycle/
lib/core/services/cycle_service.dart
```

and every consumer of:

```text
CycleCalculator
CycleStatus
CyclePredictions
CyclePhase
CycleProvider
CycleStateNotifier
streamCycleLogs
streamPeriodRecords
```

Also inspect:

- home workout recommendations
- notifications
- cycle-related Firestore reads/writes
- cycle UI
- onboarding/setup flow
- date utilities
- timezone/date handling

## Produce

Create a detailed baseline report containing:

```text
Affected files
Current data flow
Current calculation flow
Current Firestore flow
Current UI dependencies
Current prediction dependencies
Current workout dependencies
Current notification dependencies
Current tests
Potential breaking points
```

Do not modify code in Phase 0.

STOP after the report.

---

# PHASE 1 — DATA SEMANTICS AND OBSERVED-DATA INTEGRITY

## Objective

Strengthen the meaning of existing menstrual data without redesigning the UI.

The system must clearly distinguish:

```text
period start
period end
bleeding
spotting
prediction
user correction
```

## Critical rule

Do not automatically treat:

```text
spotting
```

as equivalent to:

```text
period start
```

unless the existing product specification explicitly defines that behavior.

## Period start priority

A period start should be based primarily on explicit user confirmation.

Existing:

```text
isPeriodStart
```

must remain functional.

If additional metadata is required, prefer additive fields.

Potential conceptual model:

```text
PeriodEvent
  startDate
  endDate
  source
  confidence
  createdAt
  updatedAt
```

Possible source values:

```text
user_confirmed
user_corrected
observed_flow
inferred
```

Do not migrate existing data destructively.

## Required tests

Test:

- normal period start
- spotting before period
- spotting after period
- user removes period-start flag
- user changes period-start date
- duplicate start dates
- missing start date
- overlapping periods
- future period dates

STOP after Phase 1.

---

# PHASE 2 — HISTORICAL CYCLE ANALYSIS ENGINE

## Objective

Replace the current simplistic:

```text
simple average + clamp
```

approach with a robust historical analysis layer.

Do NOT modify actual historical observations.

The engine must calculate:

```text
cycleCount
medianCycleLength
meanCycleLength
minimumCycleLength
maximumCycleLength
cycleVariability
recentCycleLengths
regularityClass
```

Potential regularity classifications:

```text
INSUFFICIENT_DATA
REGULAR
SLIGHTLY_VARIABLE
VARIABLE
HIGHLY_VARIABLE
```

Use robust statistics.

The median should be available as a primary estimator.

Do not blindly rely on arithmetic mean.

## Important

Do NOT do:

```text
actual cycle = clamp(actual cycle)
```

Instead:

```text
actual cycle remains actual
```

and classification/prediction logic handles unusual values.

Example:

```text
actual = 18 days
```

must remain:

```text
18
```

even if the prediction engine determines that this is outside the preferred prediction range.

## Recent history

Recent cycles should generally have greater influence than very old cycles, while avoiding overreaction to a single abnormal cycle.

Implement this as a deterministic, testable statistical strategy.

STOP after Phase 2.

---

# PHASE 3 — NEXT PERIOD PREDICTION ENGINE

## Objective

Create a stronger next-period prediction model.

Do NOT directly derive everything from:

```text
cycleLength - 14
```

That formula belongs to ovulation estimation, not general cycle prediction.

Next period prediction should use:

```text
confirmed period history
+
robust historical statistics
+
recent cycle behavior
+
cycle regularity
+
current cycle progress
```

The output should support uncertainty.

Conceptually:

```text
predictedDate
earliestDate
latestDate
confidence
```

Do not falsely imply that one date is guaranteed.

## Example

Instead of only:

```text
September 28
```

internally support:

```text
Estimated:
September 28

Likely range:
September 26 – September 30

Confidence:
medium
```

Do not change UI yet unless explicitly required.

The domain layer must become capable of producing this information first.

STOP after Phase 3.

---

# PHASE 4 — OVULATION ESTIMATION

## Objective

Correct the current deterministic ovulation implementation.

The existing approach:

```text
cycleLength - 14
+
hard clamp
```

must NOT be treated as a confirmed biological event.

The engine should explicitly model:

```text
estimatedOvulationDate
earliestPossibleDate
latestPossibleDate
confidence
basis
```

## CRITICAL RULE

NEVER solve an impossible biological estimate by forcing it through:

```text
clamp()
```

Example of forbidden behavior:

```text
raw ovulation = Day 7
minimum = Day 16
therefore ovulation = Day 16
```

That is not an acceptable biological inference.

Instead:

```text
prediction confidence decreases
```

or:

```text
prediction becomes insufficient
```

when the available data cannot support a meaningful estimate.

## Basis

Possible:

```text
calendar_estimate
historical_pattern
user_observation
```

Never call calendar estimation:

```text
confirmed ovulation
```

STOP after Phase 4.

---

# PHASE 5 — FERTILE WINDOW ENGINE

## Objective

Build fertile-window estimation on top of ovulation uncertainty.

Do NOT simply create a hardcoded arbitrary window around a single predicted date.

The fertile-window engine must understand:

```text
estimated ovulation
+
ovulation uncertainty
+
cycle variability
+
confidence
```

The domain output should support:

```text
fertileWindowStart
fertileWindowEnd
confidence
basis
```

Do not present this as guaranteed fertility status.

This is an estimation feature, not a contraceptive guarantee or fertility diagnosis.

STOP after Phase 5.

---

# PHASE 6 — CONFIDENCE ENGINE

## Objective

Introduce a unified confidence model.

Every prediction should internally have confidence.

Confidence should consider factors such as:

```text
number of confirmed cycles
cycle variability
data completeness
recent consistency
prediction history
current-cycle deviation
```

Use deterministic rules initially.

DO NOT introduce machine learning.

Example:

```text
INSUFFICIENT
LOW
MODERATE
HIGH
```

Avoid pretending that an arbitrary numeric value such as:

```text
0.8734
```

is medically validated.

If numeric scoring is used internally, document exactly what it represents.

## Example behavior

1 cycle:

```text
confidence = insufficient/low
```

8 highly consistent cycles:

```text
confidence = higher
```

highly variable cycles:

```text
confidence = low
```

Do not allow confidence to override actual user observations.

STOP after Phase 6.

---

# PHASE 7 — CYCLE PHASE ESTIMATION

## Objective

Improve:

```text
menstrual
follicular
ovulation
luteal
```

phase calculation.

The existing enum should remain compatible.

However, internally phase calculations should distinguish:

```text
observed
estimated
predicted
```

and ideally:

```text
phase
confidence
basis
startDate
endDate
```

## Important medical/product rule

The app does NOT directly measure:

```text
estrogen
progesterone
LH
follicle development
```

unless those measurements are explicitly integrated.

Therefore never generate UI claims equivalent to:

```text
Your estrogen is currently rising.
```

from calendar calculations alone.

Use:

```text
Estimated follicular phase
```

or equivalent safe terminology where appropriate.

STOP after Phase 7.

---

# PHASE 8 — LATE / MISSED / STALE PREDICTION HANDLING

## Objective

Introduce explicit behavior when the predicted period does not occur on time.

The system must not endlessly continue projecting:

```text
cycleDay++
phase = luteal
```

without reducing confidence.

Create an internal state model such as:

```text
ACTIVE
EXPECTED
LATE
CONFIRMED
IRREGULAR
INSUFFICIENT_DATA
```

When the expected date passes:

```text
prediction confidence decreases
```

rather than pretending the original prediction remains equally reliable.

When the user records a new period:

```text
prediction becomes historical
actual start becomes authoritative
```

STOP after Phase 8.

---

# PHASE 9 — PREDICTION RECONCILIATION

## Objective

Make the algorithm learn from historical prediction accuracy.

When:

```text
predicted period = September 15
actual period = September 18
```

record:

```text
prediction error = +3 days
```

Do NOT alter historical user observations.

Create an additive prediction-history model if necessary.

Potential structure:

```text
cycle_predictions/
```

containing:

```text
predictionId
generatedAt
algorithmVersion
predictedPeriodStart
predictedOvulation
fertileWindow
confidence
actualPeriodStart
errorDays
```

This is essential for evaluating whether future algorithm versions actually improve prediction quality.

STOP after Phase 9.

---

# PHASE 10 — ALGORITHM VERSIONING

## Objective

Introduce explicit algorithm versioning.

Example:

```text
algorithmVersion = "2.0"
```

Every prediction generated by the new engine should be traceable to its version.

Never silently change historical predictions.

Historical prediction records must remain associated with the algorithm version that generated them.

This allows:

```text
v1 accuracy
vs
v2 accuracy
```

comparison.

STOP after Phase 10.

---

# PHASE 11 — CALENDAR PROJECTION SAFETY

## Objective

Fix the current aggressive modular calendar fallback.

The current behavior:

```text
cycleDay % cycleLength
```

must not create false certainty when the current cycle deviates significantly from historical behavior.

Calendar projection may be used as a fallback, but:

```text
fallback ≠ confirmation
```

When current-cycle behavior deviates:

```text
reduce confidence
```

rather than forcing a phase/date.

Predictions should eventually become stale when sufficiently outside their expected range.

STOP after Phase 11.

---

# PHASE 12 — PERSONALIZED WORKOUT RECOMMENDATION ENGINE

## Objective

Improve workout recommendations without redesigning the workout system.

The existing phase mapping may remain as a baseline.

However, recommendations should consider:

```text
estimated phase
+
energy
+
symptoms
+
flow
+
user-reported discomfort
+
existing workout metadata
```

Do not make:

```text
phase → mandatory workout
```

the sole decision.

Example:

```text
estimated menstrual phase
+
low energy
+
cramps
```

should favor gentler options.

Whereas:

```text
estimated menstrual phase
+
good energy
+
no relevant discomfort
```

may allow broader recommendations.

Do not claim that a particular workout is medically required because of a hormonal phase.

Do not redesign workout screens.

Do not modify unrelated workout functionality.

STOP after Phase 12.

---

# PHASE 13 — NOTIFICATION SAFETY

## Objective

Ensure notifications use prediction confidence and current-cycle state.

Existing notifications:

```text
period reminder
cycle update
ovulation reminder
```

must not blindly trigger from stale predictions.

Before triggering:

```text
prediction exists
AND
prediction is not stale
AND
confidence meets notification threshold
AND
user has not already recorded the event
```

Do not spam users.

Do not change notification UI.

STOP after Phase 13.

---

# PHASE 14 — FIRESTORE PERFORMANCE AND DATA CONSISTENCY

## Objective

Ensure the improved algorithm does not create excessive Firestore reads.

Review:

```text
cycle_logs
periods
cycle_predictions
cycle_statistics
```

Do not repeatedly download the entire user's historical dataset unnecessarily.

Prefer:

```text
bounded historical queries
```

where safe.

Avoid:

```text
N+1 reads
```

Avoid:

```text
recalculating expensive statistics on every widget rebuild
```

Keep calculation logic pure and cacheable.

Do not redesign unrelated Firestore architecture.

STOP after Phase 14.

---

# PHASE 15 — COMPREHENSIVE TESTING

Create deterministic tests for every major rule.

At minimum test:

## Regular cycles

```text
28 / 28 / 28 / 28
```

## Mild variability

```text
27 / 28 / 29 / 28
```

## High variability

```text
23 / 34 / 27 / 39 / 25
```

## Outlier

```text
27 / 28 / 29 / 55
```

## Short cycle

```text
20 / 21 / 22
```

## Long cycle

```text
46 / 48 / 50
```

## Insufficient history

```text
1 confirmed cycle
```

## Spotting

```text
spotting
↓
true menstrual flow
```

## Late period

```text
expected date passes
↓
no period
```

## Actual period arrives late

```text
predicted Sep 15
actual Sep 18
```

## User correction

```text
Sep 15 → Sep 17
```

## Deleted period

Verify all predictions recalculate safely.

## Future dates

Verify no false historical classification.

## Timezones

Test local-date boundaries.

## Month boundaries

Test:

```text
January → February
February → March
```

## Leap year

Test February 29.

---

# PHASE 16 — REGRESSION TESTING

Before declaring the implementation complete, verify:

- authentication
- onboarding
- profile
- home screen
- workout system
- videos
- navigation
- notifications
- Firestore synchronization
- cycle history
- daily journal
- existing cycle UI
- existing settings
- logout/login
- offline/poor-network behavior where supported

No unrelated regression is acceptable.

---

# 17. UI PROTECTION RULE

Unless explicitly requested:

DO NOT change:

- layout
- spacing
- colors
- fonts
- icons
- navigation
- animations
- card structure
- screen structure
- existing workout UI

The algorithm should first become correct at the domain/data layer.

Only after domain correctness is verified may UI changes be proposed.

---

# 18. BACKWARD COMPATIBILITY RULE

Existing consumers may expect:

```text
CycleStatus
CyclePredictions
CyclePhase
```

Do not break them unnecessarily.

If new information is required, prefer:

```text
new fields
new value objects
new internal services
```

rather than destructive replacement.

If an API/model contract must change:

1. identify every consumer
2. document the change
3. provide compatibility where possible
4. test every consumer
5. stop and request approval if breaking behavior is unavoidable

---

# 19. MEDICAL SAFETY RULE

This application provides menstrual-cycle tracking and estimation.

The algorithm must NOT claim to:

- diagnose medical conditions
- guarantee ovulation
- guarantee fertility
- guarantee infertility
- guarantee contraception
- confirm hormonal levels
- replace clinical testing

Calendar-based predictions must be treated as estimates.

If data is insufficient:

> **It is better to say "insufficient data" than to generate a confident but unsupported date.**

---

# 20. NO MACHINE LEARNING IN THIS VERSION

Do not introduce:

- TensorFlow
- neural networks
- LLM predictions
- black-box models
- external AI APIs

for cycle prediction.

First establish a transparent deterministic statistical engine.

Every prediction must be explainable.

---

# 21. CODE QUALITY REQUIREMENTS

Use:

- immutable models where appropriate
- pure functions for mathematical calculations
- null-safe Dart
- explicit naming
- documented domain rules
- deterministic tests
- small focused services
- no duplicated formulas
- no magic numbers without named constants
- no hidden side effects in calculation functions

Avoid giant calculator classes.

Prefer focused domain services.

---

# 22. REQUIRED DOCUMENTATION

Document every important biological/statistical assumption.

For each formula explain:

```text
What it calculates
Why it exists
Input data
Output
Limitations
Edge cases
Confidence implications
```

Never hide important medical assumptions inside arbitrary constants.

---

# 23. REQUIRED AGENT REPORT AFTER EVERY PHASE

At the end of each phase output exactly:

```text
PHASE:
Status:

FILES INSPECTED:

FILES MODIFIED:

FILES ADDED:

ROOT CAUSE:

IMPLEMENTATION:

DATA/MODEL CHANGES:

ALGORITHM CHANGES:

TESTS ADDED:

TEST RESULTS:

REGRESSION RESULTS:

PRESERVED FUNCTIONALITY:

KNOWN RISKS:

REMAINING WORK:

NEXT PHASE:
NOT IMPLEMENTED
```

Do not claim success without actually running the relevant tests.

---

# 24. STOP CONDITIONS

Immediately stop and report instead of improvising if:

- a database migration is required
- existing user data could be altered
- existing APIs must break
- authentication must change
- existing UI must be redesigned
- unrelated files need modification
- medical behavior cannot be determined safely
- an existing feature conflicts with the new algorithm
- a breaking Firestore schema change is required
- the requested change exceeds the current phase

Never expand scope silently.

---

# 25. FINAL SUCCESS CRITERIA

The final system should achieve:

```text
Observed data
      ↓
Reliable historical analysis
      ↓
Personalized cycle statistics
      ↓
Robust prediction
      ↓
Uncertainty range
      ↓
Confidence
      ↓
Estimated phases
      ↓
Estimated fertile window
      ↓
Prediction reconciliation
      ↓
Improved personalization
```

The system should NOT behave like:

```text
cycleLength
     ↓
fixed formula
     ↓
exact date
     ↓
exact hormonal phase
     ↓
mandatory workout
```

The final implementation must be:

- production-ready
- deterministic
- testable
- explainable
- maintainable
- backward compatible
- conservative when data is insufficient
- explicit about uncertainty
- safe for a consumer health application
- performant for a mobile/Firestore architecture

# FINAL INSTRUCTION

Do not start implementation by rewriting `CycleCalculator`.

First complete **Phase 0** and show the forensic baseline.

After Phase 0, STOP and wait for approval.

Then implement exactly one phase at a time.

No shortcuts.
No unrelated refactoring.
No UI redesign.
No destructive migration.
No speculative medical logic.
No hidden behavior changes.
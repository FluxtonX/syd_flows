# ROLE

Act as a Senior Flutter/Dart Engineer, Full-Stack Engineer, Software Architect, Algorithm Engineer, UX Engineer, QA Engineer, and menstrual-cycle tracking domain-aware engineer.

You are modifying an EXISTING production Flutter application called **SYD FLOW**.

Your task is to improve the EXISTING menstrual-cycle tracking system based on the current codebase and the audit report.

This is a **controlled production fix**, NOT a rewrite.

---

# 🚨 EXTREMELY IMPORTANT — SCOPE BOUNDARIES

Before changing anything:

1. Read the existing implementation completely.
2. Read all relevant cycle files.
3. Understand the current data flow.
4. Run/inspect the existing cycle tests.
5. Verify the audit findings against the actual code.
6. Do not blindly trust the audit report if the actual code behaves differently.
7. Make the smallest safe changes required.

## DO NOT MODIFY ANYTHING OUTSIDE THE CYCLE-TRACKING SCOPE

Do NOT change:

* Authentication
* Google Sign-In
* Apple Sign-In
* Onboarding screens except cycle/period date interaction if directly required
* Home screen
* Workout features
* Yoga
* Pilates
* Strength
* Mobility
* Video playback
* Favorites
* Achievements
* Progress features unrelated to cycle tracking
* Profile features unrelated to cycle tracking
* Subscription/Premium logic
* Firebase authentication
* Firebase Storage
* Cloudinary
* Navigation architecture
* App theme
* Global typography
* Global spacing system
* Global component design
* Unrelated Firestore collections
* Unrelated backend code
* Unrelated services
* Unrelated models
* Existing layouts outside the cycle feature

Do NOT perform a broad refactor.

Do NOT migrate the entire Firestore architecture.

Do NOT replace GetX/MVVM/Clean Architecture.

Do NOT introduce a new state-management framework.

Do NOT replace existing calendar libraries unless absolutely impossible.

Do NOT redesign the entire Cycle Screen.

---

# EXISTING ARCHITECTURE TO PRESERVE

The current architecture includes:

* Clean Architecture / MVVM
* Flutter/Dart
* CycleCalculator
* NextPeriodPredictor
* HistoricalCycleAnalyzer
* CycleService
* CycleStateNotifier
* CycleScreen
* cycle_logs
* periods

Preserve this architecture unless a very small internal change is necessary to correctly separate actual and predicted calendar states.

---

# PRIMARY PRODUCT GOAL

The calendar must clearly communicate the difference between:

1. What the USER actually logged.
2. What the APP predicts.
3. What the APP estimates.
4. What is simply a normal cycle phase.

The user should never confuse an algorithm prediction with something she actually entered.

---

# CORE BUSINESS RULE

## ACTUAL USER DATA ALWAYS HAS HIGHER PRIORITY THAN PREDICTIONS.

This is the most important rule in the implementation.

If a user has explicitly logged bleeding for a date, that date must be rendered as ACTUAL bleeding even if:

* the typical period length is shorter,
* the predicted period ended earlier,
* the algorithm expects the period to have ended,
* the date is outside the predicted period window,
* the date falls into another calculated phase.

Example:

Typical period length:

5 days

Actual user-entered bleeding:

7 days

The final calendar state MUST be:

```text
Day 1 = ACTUAL BLEEDING
Day 2 = ACTUAL BLEEDING
Day 3 = ACTUAL BLEEDING
Day 4 = ACTUAL BLEEDING
Day 5 = ACTUAL BLEEDING
Day 6 = ACTUAL BLEEDING
Day 7 = ACTUAL BLEEDING
```

The typical 5-day duration must NOT truncate or visually override Day 6 or Day 7.

The typical period length is a prediction parameter, not an actual-data limit.

---

# IMPORTANT: VERIFY THE CURRENT BUG

The audit claims that the current implementation already renders 7 actual bleeding days correctly.

However, the real product behavior being reported is that when the user's typical period length is 5 days and she actually logs 7 days, the UI still behaves visually like 5 days.

Therefore:

DO NOT ASSUME THE AUDIT IS CORRECT.

Trace the actual execution path.

Find exactly:

```text
User period log
    ↓
Firestore write
    ↓
CycleStateNotifier
    ↓
CycleCalculator
    ↓
Cycle phase/day state
    ↓
CycleScreen
    ↓
_buildDayCell
```

Determine where the 6th and 7th actual days lose their ACTUAL status.

If the backend/model already contains the correct actual data but the calendar renders it incorrectly, fix the presentation/view-model mapping rather than rewriting the algorithm.

If the actual data itself is incorrect, identify the smallest necessary data-layer correction.

---

# ACTUAL VS PREDICTED STATE

The UI must have an explicit distinction between:

## ACTUAL PERIOD

Meaning:

> The user explicitly recorded bleeding.

Visual direction:

* Deep pink/red
* Blood icon
* Strong/solid visual treatment

This is the strongest period visual state.

---

## PREDICTED PERIOD

Meaning:

> The algorithm expects a period around this date, but the user has not confirmed bleeding.

Visual direction:

* Soft/light pink
* Visually lighter than actual
* Clearly distinguishable from actual
* Do NOT use the same solid visual weight as actual bleeding

A subtle outline, lighter fill, or other existing-design-compatible treatment is acceptable.

Choose the implementation that best fits the EXISTING SYD FLOW design.

Do NOT introduce an unrelated visual style.

---

# ESTIMATED OVULATION

Ovulation calculated from calendar/cycle data must be treated as:

> ESTIMATED OVULATION

Not confirmed ovulation.

It must have a separate visual state from:

* Actual bleeding
* Predicted bleeding
* Normal phase colors

Use the existing design language and theme.

Do not make it visually confusing with period colors.

Do not imply medical certainty.

---

# NORMAL DAYS / PHASE DAYS

If the user has not logged bleeding for a date and there is no special predicted event:

Render the appropriate normal cycle phase.

Examples:

```text
Follicular → existing follicular styling
Luteal → existing luteal styling
Other normal phase → existing appropriate styling
```

Do NOT show a period color simply because the algorithm previously predicted a period unless the date is actually a predicted period.

---

# REQUIRED DAY-STATE PRIORITY

Create or improve the internal day-state resolution so the UI can determine the final state deterministically.

The conceptual priority must be:

```text
1. ACTUAL USER BLEEDING
2. OTHER ACTUAL USER LOGS
3. PREDICTED PERIOD
4. ESTIMATED OVULATION
5. NORMAL CYCLE PHASE
6. NORMAL CALENDAR DAY
```

If the existing product has another legitimate higher-priority actual event, preserve it appropriately.

The key requirement is:

```text
ACTUAL > PREDICTED
```

An actual period log must never be visually replaced by a prediction.

---

# DO NOT PUT BUSINESS LOGIC INSIDE THE DAY CELL

The calendar day cell should not independently calculate menstrual biology.

Prefer:

```text
CycleStateNotifier / appropriate ViewModel
        ↓
Resolved Calendar Day State
        ↓
CycleScreen
        ↓
Day Cell
```

The day cell should primarily render the already-resolved state.

However:

DO NOT perform a large architectural rewrite.

If introducing a small `CalendarDayState` / presentation model is useful, keep it local to the cycle feature and compatible with the existing architecture.

---

# SELECTED-DAY BUG

Current behavior:

Selecting a calendar day can turn the cell white and hide the underlying phase/period color.

Fix this.

A selected day must preserve its underlying semantic state.

For example:

```text
Selected + Actual Period
→ remains Deep Pink/Red
→ add selected border/highlight

Selected + Predicted Period
→ remains predicted styling
→ add selected border/highlight

Selected + Ovulation
→ remains ovulation styling
→ add selected border/highlight

Selected + Follicular
→ remains follicular styling
→ add selected border/highlight
```

DO NOT replace the background with plain white merely because the day is selected.

The selection indicator should be layered ON TOP of the semantic state.

Use the existing brown/brand selection language if compatible.

Do not redesign the entire calendar.

---

# TODAY STATE

Today must also preserve its underlying semantic meaning.

Examples:

```text
Today + Actual Period
→ actual period styling

Today + Predicted Period
→ predicted period styling

Today + Normal Phase
→ normal phase styling
```

Today/selection indicators must not hide the underlying state.

---

# PERIOD START UX

Improve the current period-start experience while keeping the existing Cycle Screen structure and visual design.

The user should clearly understand:

> "I am starting a real period."

For TODAY:

The flow should be simple and obvious.

Avoid unnecessary duplicate controls where possible.

For PAST DATE:

Allow historical period recording without confusing it with starting a currently active period.

Do not remove functionality that users currently rely on.

---

# PERIOD END UX

Improve the active-period ending flow.

The user must clearly understand:

> "My period has ended."

Validation must ensure:

```text
endDate >= startDate
```

Do not allow invalid ranges.

Handle same-day start/end safely.

Do not allow a future end date unless the existing product explicitly requires it.

Do not silently alter user-entered dates.

---

# ACTIVE PERIOD

Do NOT use the predicted period length as the sole source of truth for whether an actual period is active.

If actual period data indicates the user is still in an active period, the active state should respect that actual information.

However:

DO NOT redesign the entire period state architecture.

Make the smallest safe change required.

---

# IMPORTANT: DO NOT SILENTLY CAP ACTUAL BLEEDING

The algorithm may use safety limits for predictions or UI protection.

But:

An actual user-entered bleeding record must not be silently deleted or truncated simply because it exceeds the typical period length.

If the existing system has a maximum duration used for calculation, separate:

```text
Actual recorded data
```

from:

```text
Prediction/calculation safety limits
```

Do not destroy actual user data.

For unusually long bleeding, preserve the data and, if the current product already supports health guidance, use an appropriate non-alarming informational state.

Do not invent medical diagnoses.

---

# SPOTTING

Inspect how spotting is currently represented.

Do NOT automatically redesign spotting in this task unless the current implementation clearly causes actual period corruption.

The immediate requirement is:

A spotting log must not accidentally become an actual new period start unless the existing product explicitly defines spotting as period bleeding.

If a safe minimal correction is required, implement it carefully.

Do not delete or reinterpret existing historical user data.

---

# OVULATION

Do not make broad changes to the cycle algorithm in this task.

Do not rewrite the entire ovulation model.

However, ensure that the UI describes calendar-derived ovulation as an estimate rather than a confirmed biological event.

Do not present calculated ovulation as medically certain.

---

# FIRESTORE BOUNDARY

## DO NOT MIGRATE FIRESTORE.

Do not merge:

```text
cycle_logs
periods
```

in this task.

Do not rename collections.

Do not migrate existing users.

Do not change unrelated Firestore schemas.

Do not change security rules unless a directly required cycle bug cannot otherwise be fixed.

The existing dual-collection architecture must remain backward compatible.

If synchronization between `cycle_logs` and `periods` must be corrected, make the smallest compatible change possible.

Existing users' historical cycle data MUST remain readable.

---

# BACKWARD COMPATIBILITY

Existing user data must continue working.

Test with:

* new user
* existing user
* user with historical periods
* user with active period
* user with multiple cycles
* user with existing cycle logs

Do not require users to reinstall or recreate their cycle history.

---

# ONBOARDING BOUNDARY

Only touch onboarding if a cycle/period date-selection bug is directly involved.

Do not redesign onboarding.

The goal is only to make period start/date entry less confusing and safer.

Preserve:

* existing layout
* existing components
* existing typography
* existing navigation
* existing onboarding flow

---

# VISUAL DESIGN BOUNDARY

This is NOT a visual redesign.

Keep:

* current Cycle Screen layout
* current calendar dimensions
* current spacing
* current typography
* current navigation
* current theme
* current component structure

Only change the minimum visual properties needed to communicate:

```text
Actual
Predicted
Estimated Ovulation
Normal Phase
Selected
Today
```

Do not introduce unnecessary animations.

Do not add new screens unless absolutely necessary.

Do not change the overall design language.

---

# TESTING REQUIREMENTS

Before declaring completion, add/update tests for the actual behavior.

At minimum test:

### Test 1

Typical period = 5 days.

Actual bleeding = 5 days.

Expected:

5 actual bleeding days.

### Test 2

Typical period = 5 days.

Actual bleeding = 7 days.

Expected:

7 actual bleeding days.

Days 6 and 7 MUST remain actual bleeding.

### Test 3

Typical period = 7 days.

Actual bleeding = 5 days.

Expected:

5 actual bleeding days.

### Test 4

No actual bleeding.

Future predicted period exists.

Expected:

Predicted styling only.

### Test 5

Actual period overlaps predicted period.

Expected:

ACTUAL styling wins.

### Test 6

Selected actual-period day.

Expected:

Actual period color remains visible.

### Test 7

Selected predicted day.

Expected:

Predicted styling remains visible.

### Test 8

Selected ovulation day.

Expected:

Ovulation styling remains visible.

### Test 9

Today is an actual period day.

Expected:

Actual styling remains visible.

### Test 10

Historical actual period.

Expected:

Historical actual data renders correctly.

### Test 11

Period start date > end date.

Expected:

Validation prevents invalid period.

### Test 12

Same start/end date.

Expected:

Handled safely.

### Test 13

User starts a period and does not end it.

Expected:

Actual active-period state remains consistent with stored data.

### Test 14

Spotting is logged.

Expected:

It does not accidentally create a new period unless explicitly intended by existing product rules.

### Test 15

Late period.

Expected:

Prediction does not become an actual period automatically.

---

# IMPORTANT REGRESSION TESTING

Run the existing test suite before and after changes.

Do not remove existing tests simply because they conflict with the new implementation.

If an existing test fails because it encodes an incorrect old behavior:

1. Explain why.
2. Update only that test.
3. Preserve the underlying intended behavior.
4. Report the change.

Do not weaken tests just to make the build pass.

---

# IMPLEMENTATION PROCESS

Follow this exact sequence:

## STEP 1 — Inspect

Read all relevant cycle files.

## STEP 2 — Map

Document the current data flow internally.

## STEP 3 — Reproduce

Reproduce the 5-day typical / 7-day actual scenario.

## STEP 4 — Identify

Find the exact point where actual state is lost, overridden, or rendered incorrectly.

## STEP 5 — Design minimally

Choose the smallest compatible fix.

## STEP 6 — Implement

Modify only relevant cycle files.

## STEP 7 — Test

Run targeted tests.

## STEP 8 — Regression test

Run the broader existing test suite.

## STEP 9 — Inspect UI

Verify actual, predicted, ovulation, normal, selected, and today states.

## STEP 10 — Final review

Check the scope boundaries again.

---

# FILE-SCOPE PREFERENCE

Prefer changes only within:

```text
lib/features/cycle/**
lib/core/services/cycle_service.dart
```

and the minimum required cycle tests.

Do NOT modify unrelated directories.

If you believe another file must be changed, STOP before modifying it and explain:

1. File path
2. Why it is required
3. What will change
4. Why the cycle issue cannot be fixed without it

Only proceed if the change is clearly necessary and directly related to cycle tracking.

---

# CODE QUALITY REQUIREMENTS

Maintain:

* Clean Architecture
* MVVM
* existing state management
* null safety
* existing naming conventions
* existing error handling
* existing dependency structure

Avoid:

* duplicated business logic
* magic numbers
* unnecessary abstractions
* unnecessary dependencies
* broad refactors
* dead code
* temporary hacks

Do not introduce a new package unless absolutely necessary.

---

# DATA SAFETY REQUIREMENTS

Never:

* delete user cycle history
* rewrite historical periods without explicit reason
* migrate existing collections
* silently change dates
* silently change period lengths
* silently convert spotting to periods
* silently convert predictions to actual periods

Actual user-entered data must remain recoverable.

---

# FINAL DELIVERABLE

After implementation, provide a concise engineering report:

## 1. Root Cause

Exactly why the 5-day vs 7-day problem occurred.

## 2. Files Changed

List every changed file.

## 3. What Changed

Describe each change.

## 4. Actual vs Predicted Behavior

Explain the final precedence.

## 5. Start/End UX Changes

Explain what changed.

## 6. Calendar Visual States

Explain:

* Actual
* Predicted
* Ovulation
* Normal
* Selected
* Today

## 7. Firestore Impact

Explicitly state whether schema/data migration occurred.

Expected:

`NO MIGRATION`

unless absolutely unavoidable.

## 8. Tests Added/Updated

List them.

## 9. Existing Tests

Report pass/fail.

## 10. Regression Check

Confirm that unrelated features were not modified.

## 11. Remaining Risks

List anything that should be addressed separately rather than expanding this task.

---

# FINAL HARD BOUNDARY

This task is ONLY about:

```text
MENSTRUAL CYCLE TRACKING
+
ACTUAL PERIOD LOGGING
+
PREDICTION VISUALIZATION
+
OVULATION VISUALIZATION
+
CALENDAR DAY STATE
+
PERIOD START/END UX
```

Nothing else.

Do not use this task as an opportunity to "clean up" unrelated code.

Do not redesign the application.

Do not rewrite the cycle system.

Do not migrate the database.

Do not change unrelated layouts.

Do not change unrelated business logic.

**Make the smallest production-safe changes that produce the required behavior.**

Before finishing, inspect `git diff` and verify that every changed file is directly related to this task.

If unrelated files were modified accidentally, revert those unrelated changes before completing the task.

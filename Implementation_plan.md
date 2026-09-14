# Period Tracking Algorithm Bug Fix Plan

## Goal Description
The current period tracking algorithm automatically wraps into a new cycle when the predicted `cycleLength` is exceeded. This occurs because the cycle day is calculated using a modulo operator `(rawDiff % cycleLength) + 1`. 
As a result, if a user's period is late, the app automatically assumes a new cycle has started based purely on the prediction, treating the predicted date as actual data and overriding the actual state of the cycle.
This violates the core business rules: "A predicted period date must never override an actual logged period date" and "Prediction must never become actual data".

The fix requires stopping the cycle day and phase calculations from wrapping automatically for the *current* and *past* cycles, while still allowing accurate future predictions. 
Actual logged periods should be the only way a new cycle officially begins.

## User Review Required
No major UI changes, strictly enforcing the pure domain rules for cycle math.
Legacy duplicate calculations in the UI (`CycleScreen`) will be removed to ensure a Single Source of Truth.

## Open Questions
None. The rules provided by the user are highly specific and deterministic.

## Proposed Changes

### `lib/features/cycle/domain/cycle_calculator.dart`
#### [MODIFY] `cycle_calculator.dart`(file:///Users/mc/projects/syd_flow/lib/features/cycle/domain/cycle_calculator.dart)
- Update `CycleCalculator.compute` so that `cycleDay` does NOT wrap around using modulo for the current active cycle. It should simply be `rawDiff + 1`. The current cycle continues indefinitely until the user logs a new period start.
- Update `_computePhase` to handle days beyond `cycleLength`. If `cycleDay > cycleLength`, it remains in the `luteal` phase (the period is late), rather than returning to `menstrual`.
- Ensure `_computePredictions` uses `anchor` and `safeCycleLength` instead of relying on a wrapped `cycleDay`. The next predicted period should be `anchor.add(Duration(days: safeCycleLength))`. If `today` is past the predicted date, `daysUntilNextPeriod` should be negative (indicating late period), or `nextPeriodStart` should just remain the predicted date in the past.
- Update `CycleCalculator.cycleDayForDate` and `CycleCalculator.phaseForDate` to use the same non-wrapping logic for dates after the most recent `anchor`.

### `lib/features/cycle/presentation/screens/cycle_screen.dart`
#### [MODIFY] `cycle_screen.dart`(file:///Users/mc/projects/syd_flow/lib/features/cycle/presentation/screens/cycle_screen.dart)
- Remove `_getPeriodStartDay` and legacy prediction calculation inside `_buildPredictionsCard`. Ensure `CycleProvider.of(context)` (or nullable with proper fallback to `CycleStatus.empty`) is the sole source of truth for all calendar, phase, and prediction math.

### `test/period_algorithm_test.dart`
#### [MODIFY] `period_algorithm_test.dart`(file:///Users/mc/projects/syd_flow/test/period_algorithm_test.dart)
- Add a specific test case (e.g. Test 12.1) ensuring that if today is *after* the predicted next period date, but no period has been logged, the `cycleDay` continues counting up (e.g., Day 30) instead of wrapping to Day 1 or Day 2.

## Verification Plan

### Automated Tests
- `flutter test test/period_algorithm_test.dart`
- All 17 business rule tests must pass without any drift or date wrapping.

### Manual Verification
- N/A (Business rules are validated purely via automated logic tests).

# Prediction implementation and evaluation

CycleCare estimates period dates locally. It has no validated probability of
being correct, and this release makes no population accuracy claim.

## Recorded history and exclusions

`CycleEvent.excludeFromPredictions` defaults to false for existing records.
`predictionExclusionReason` is optional. Both survive storage and JSON backups.
The Calendar period editor sets or clears them. Exclusion affects the completed
cycle beginning at that period start, up to the next actual start. Its bleeding
record remains visible. Excluding an interval never joins the surrounding starts.

The shared `CycleSamples` selector feeds forecasts and Insights. It deduplicates
calendar dates, ignores starts after the forecast reference date, and retains all
real boundaries. Only included intervals between 15 and 90 days inform learning;
that is an algorithm input filter, not a statement that other records are invalid.
The cycle-length estimator keeps its existing 21–45 day clamp. All records remain
available even when a gap does not inform that estimate.

Home and Insights explain whether the average comes from settings or completed
recorded cycles, give the included count, and show observed standard deviation
and range when at least two included cycles exist. Variation describes the input
history; it is not a forecast interval. The next-period date stays anchored to the
latest actual period when late, including when that cycle is excluded from
learning. It does not invent a new start to roll the date forward.

## Retrospective checks

`PredictionEvaluation.run` walks forward through consecutive recorded starts.
At each start it calls the same live prediction service with only the starts
available then and end dates no later than that reference date. It compares the
predicted next start with the subsequent actual start, retaining date error and
training count. Excluded target cycles are skipped. The Insights comparison
requires at least two prior included completed cycles per evaluated forecast.

Preferences and exclusion annotations are their current values: their historical
edit timestamps are not stored. This is a reproducible retrospective replay,
not an audit of forecasts that the user actually saw. Mean absolute date error
and count within two days describe only the evaluated records. No measured
ovulation label is available, so this does not evaluate fertility or contraception.

## Gate for a replacement estimator

Keep the current estimator until a candidate has all of the following evidence:

1. A versioned, consented or synthetic dataset manifest and fixed replay code;
   no personal records committed to Git. Compare candidate and baseline on the
   same chronological splits, with no future starts or measurements in training.
2. Report number of people, completed cycles, excluded/filtered intervals and
   missing-history cases. Separate results by available training count, observed
   variation and gap lengths; do not silently omit difficult histories.
3. Report mean and median absolute error, signed error, the 90th percentile
   absolute error and counts within one, two and three days. Compare by person
   as well as by cycle so prolific loggers cannot dominate the result.
4. Predeclare the candidate's acceptance threshold before evaluating held-out
   data: lower mean absolute error than baseline, no worse 90th percentile error,
   and no material regression in a prespecified subgroup. Report uncertainty and
   sample size; insufficient evidence means keep the existing model.
5. If introducing a prediction interval, specify nominal coverage and test its
   empirical coverage/width separately. Do not relabel the internal confidence
   heuristic as a probability. Preserve late anchoring, reversible exclusions,
   offline operation, backup migration and shared Home/Calendar/Insights dates.

These are engineering release criteria, not evidence of clinical validation.
Current regression tests demonstrate deterministic behavior and data preservation;
they do not establish real-world prediction accuracy.

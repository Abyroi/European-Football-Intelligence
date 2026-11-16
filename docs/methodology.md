# Methodology and interpretation

## Dataset and scope
Historical European Soccer Database, seasons 2008/09–2015/16. Analysis covers 11 leagues, subject to availability and completeness of match and attribute records. Imported table and column names follow the original SQL.

## Data quality
The SQL audits missing/duplicate identifiers, foreign-key readiness, timestamps, and season completeness. A 30-match minimum is used in the Leicester analyses, but **30 matches does not guarantee a complete season**. Some league formats include playoffs or nonstandard match totals; a simple double round-robin expectation may not apply.

## Elo model
Chronological, match-by-match updates using an initial rating of 1500, K-factor 20 and a +65 home-field adjustment. Ties count as 0.5. Elo is derived from observed results; its parameters were not independently calibrated or externally validated.

## Leicester Paradox
- Baseline strength: previous-season points per match (PPM).
- Late momentum: final 10 PPM minus first 10 PPM in the previous season.
- Target: next-season ΔPPM ≥ +0.5, **not** title-winning.
- For the 2014/15 preseason ranking, all 131 incumbent teams with PPM < 1.5 and ≥30 matches are ranked before joining 2015/16 outcomes.
- The comparison of ranking methods uses 106 teams with eligible records in both seasons. Thus results are conditional on remaining in the same top-flight league and being present in the data.
- Retrospective choice of indicators, cutoffs and evaluation seasons can bias apparent predictive value. The 2014/15-to-2015/16 comparison is not a pristine out-of-sample test.
- Momentum is not a sufficient explanation for every breakthrough: Piast Gliwice and FC Arouca were not in the top 10.

## Interpretation
These are exploratory associations and ranking diagnostics. They do not establish causation, robust generalization, or the probability of winning a championship. Future work could use predefined thresholds, rolling-origin validation, promotion/relegation-aware outcomes, and uncertainty intervals.

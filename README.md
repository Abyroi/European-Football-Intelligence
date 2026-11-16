# European Football Intelligence

SQL analytics portfolio | PostgreSQL · DBeaver · Window Functions · CTEs · PL/pgSQL

## Overview

Exploratory and hypothesis-driven analysis of the European Soccer Database (2008–2016), spanning 11 European leagues. Topics include league performance, home advantage, player ratings, chronological Elo modelling, tactical attributes, and the **Leicester Paradox**: whether late-season form contains a signal of next-season improvement.

This repository reorganizes the author's original exploratory SQL script. The original, unmodified file is retained as `original_backup.sql` for traceability.

## Research highlights

- **Leicester City (2014/15):** last-ten minus first-ten points per match (PPM) = **+1.30**. Ranked **4th of 131** eligible incumbent teams in a 2014/15-only candidate ranking.
- **Historical association:** the top momentum quintile had **9.81%** next-season large improvements (defined as ΔPPM ≥ 0.5) versus **1.86%** in the bottom quintile (1,074 consecutive team-season pairs). This is an association, not causal proof.
- **2015/16 diagnostic comparison:** among **106** incumbent teams with eligible results in both seasons, a momentum ranking found **2 of 4** breakthroughs in its top ten (Precision@10 = **20%**, Recall@10 = **50%**); a previous-season PPM ranking found **0 of 4**. The original pre-season list included **131** teams, of which **25** lacked an eligible next-season same-league record.
- The exercise **does not establish that Leicester's league title could have been predicted**. The evaluated outcome is a large improvement in PPM, not a championship; the analysis is retrospective, and the 2015/16 comparison is small and survivor-selected.

Numbers above come from the author's previously executed SQL results; they have **not been independently rerun** in this packaged environment.

## Repository structure

```text
sql/
  01_setup_and_validation.sql       # Keys, integrity checks, timestamp verification
  02_league_and_team_analysis.sql   # Home advantage, standings, data completeness
  03_player_analysis.sql            # Player ratings, development, Messi/Ronaldo
  04_elo_and_upsets.sql             # Chronological Elo and giant-killer metrics
  05_tactical_intelligence.sql      # Tactical attributes and as-of analysis
  06_leicester_paradox.sql          # Momentum hypothesis and ranking comparisons
docs/
  methodology.md
  audit_notes.md
original_backup.sql                 # Original source; do not execute blindly
```

## Dataset source and download instructions

- **Dataset:** [European Soccer Database on Kaggle](https://www.kaggle.com/datasets/hugomathien/soccer)
- **Dataset publisher:** Hugo Mathien (Kaggle username `hugomathien`).
- **Coverage:** 11 European leagues, seasons 2008–2016, with match results, teams, players, player/team attributes and other fields.
- **Attribution:** The football data was collected and assembled by the dataset publisher from multiple original sources. See the Kaggle dataset description for provenance, licensing and usage restrictions. This repository contains analytical SQL, **not** the original dataset.

To obtain the data:

1. Open the [Kaggle dataset page](https://www.kaggle.com/datasets/hugomathien/soccer).
2. Sign in to Kaggle if prompted, then use the **Download** option.
3. Extract the downloaded archive. The published dataset includes a SQLite database (`database.sqlite`), **not** a ready-to-import PostgreSQL dump.
4. Convert/import the SQLite tables into PostgreSQL using a migration tool or a verified export/import workflow. Ensure the resulting PostgreSQL tables use the lowercase names `country`, `league`, `team`, `player`, `matches`, `player_attributes`, and `team_attributes` in the `public` schema. In particular, the source SQLite `Match` table is expected as `matches` by this project.
5. Check the resulting column types, keys and row counts before executing the SQL. See the validation module for checks. This repository does not include an automated SQLite-to-PostgreSQL migration script; conversion details depend on the import method.

The dataset publisher credits external sources for match information, betting odds and FIFA-based player/team attributes. Respect the original data providers' rights and the usage terms listed on Kaggle.

## Getting started and safe execution order

**Requirements:** PostgreSQL and the imported European Soccer Database, with the tables `country`, `league`, `team`, `player`, `matches`, `player_attributes`, and `team_attributes` in schema `public`. The SQL is organized into numbered blocks (#01–#53). This repository is **not** a single-click deployment script.

1. **Back up the database** before executing any DDL or PL/pgSQL. In DBeaver, explicitly select the intended PostgreSQL connection and database.
2. **`sql/01_setup_and_validation.sql` (#01–#14):** inspect existing primary keys, foreign keys and date types first. Some blocks create constraints. Do not run the entire file without reviewing the commands. The date checks in this curated version expect timestamp columns.
3. **`sql/02_league_and_team_analysis.sql` (#15–#28):** run individual analytical SELECT statements to examine leagues, team performance and home advantage.
4. **`sql/03_player_analysis.sql` (#29–#36):** run individual SELECT statements for player analysis.
5. **`sql/04_elo_and_upsets.sql` (#37–#41):** block #38 creates Elo tables with `CREATE TABLE IF NOT EXISTS` and runs a chronological PL/pgSQL calculation. When a nonempty Elo history already exists with the expected row count, the calculation is skipped; a partial history raises an exception. **This is not a complete freshness check:** source data changes can invalidate existing results even if row counts match. Blocks #39–#41 depend on Elo outputs. Never uncomment the DROP statements without planning a deliberate rebuild.
6. **`sql/05_tactical_intelligence.sql` (#42–#44):** block #42 creates or replaces a view. Review its dependencies and existing view definition before executing; the following queries depend on the view and/or Elo outputs.
7. **`sql/06_leicester_paradox.sql` (#45–#53):** run the retrospective momentum analyses individually, reviewing the season filters and research limitations.

**For a live presentation:** use a connected DBeaver SQL editor, select one analytical `SELECT` at a time, and execute with `Ctrl+Enter`. Avoid running all six files as a single script. The 49-query batch `EXPLAIN` check passed in the author's database, and the corrected #40 and #41 statements were subsequently reported to execute successfully in DBeaver. `EXPLAIN` checks planning rather than complete execution or the accuracy of all results. Structural and Elo tests also passed in that environment; they are not substitutes for an end-to-end rebuild.

**Original source:** `original_backup.sql` is kept unchanged for traceability; do not run it wholesale against an already initialized database.

## Methods

- **PPM:** total league points divided by matches played (3 for a win, 1 for a draw).
- **Momentum:** PPM in the last 10 league matches minus PPM in the first 10 matches of the same season.
- **Breakthrough:** next-season PPM − current-season PPM ≥ 0.5, for teams with eligible records in both seasons.
- **Elo:** sequential updates with starting rating 1500, K = 20 and home advantage = 65 Elo points; these are modelling choices, not calibrated optimal parameters.

See [methodology](docs/methodology.md) and [audit notes](docs/audit_notes.md) for limitations and reproducibility caveats.

## Status

Organized for portfolio review. In the author’s existing PostgreSQL database, 49 analytical statements passed a batch planning check, separate structural/Elo checks reported no tested violations, and corrected blocks #40–#41 were reported to run successfully. This does **not** establish that all blocks execute end-to-end on a fresh database, nor does it independently verify every analytical conclusion. A clean-database reproducibility run remains outstanding.

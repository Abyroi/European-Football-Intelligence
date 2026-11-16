# Static code review — changes and remaining risks

## Changes in the curated version
1. Removed the second, unnumbered duplicate block of `UNIQUE` and `FOREIGN KEY` creation that followed original section 8 (now #08). The original remains in `original_backup.sql`.
2. Wrapped constraint creation in original sections 3, 7 and 8 (now #03, #07 and #08) in PostgreSQL `DO` blocks that check for an existing **same-named** constraint before creating it. This is not a general schema migration framework: an equivalent constraint with a different name may still exist.
3. Commented out the two `DROP TABLE IF EXISTS` statements before Elo model creation. Stage 3 subsequently added `CREATE TABLE IF NOT EXISTS` and a guard that skips recalculation when the existing history has the expected number of rows. A full rebuild still requires deliberate cleanup; row-count equality does not prove the history is current.
4. Changed tactical view creation to `CREATE OR REPLACE VIEW` without an unconditional drop. PostgreSQL may reject replacement if the existing view has an incompatible column signature.
5. Reorganized numbered analytical blocks by topic, renumbering the 53 existing headings consecutively from #01 to #53. Original missing numbers (9, 10, 39, 48) were not fabricated; the original headings are preserved in `original_backup.sql`.

## Risks not silently changed
- Stage 2 changed #10–#13 to timestamp-compatible checks. These checks assume the imported date columns already have timestamp types, as in the author’s tested database.
- Original SQL uses some hard-coded season exclusions and simplistic completeness tests. These require domain review rather than automatic rewriting.
- Many analytics share similar CTEs; duplication was retained when changing it could change results.
- The model and view DDL have dependencies and must be run in the right order.
- The file was statically reviewed and reorganized, **not** tested against a running PostgreSQL database in this environment.

## Recommended validation
1. Restore a fresh copy of the source database in a test schema/database.
2. Execute the setup statements in order, checking constraints and timestamp types.
3. Build Elo and tactical views, then run dependent queries.
4. Compare key row counts and metrics with the author's original outputs.
5. Confirm no unexpected NULLs, joins that multiply rows, or season incompleteness affecting conclusions.


## Stage 2: timestamp compatibility

In `sql/01_setup_and_validation.sql`, sections #10-#12 now use timestamp-compatible NULL checks instead of text functions/regular expressions or `pg_input_is_valid`. Section #13 now verifies timestamp types without re-running ALTER TABLE. No other SQL file was changed. These edits are static fixes; full execution against PostgreSQL has not been verified.


## Stage 3: Elo safe repeat execution
- Block #38: CREATE TABLE IF NOT EXISTS; skip Elo calculation if a complete match history already exists.
- Reject partial history and noninitial ratings with empty history.
- No Elo mathematical formulas or analytics queries changed.
- This does not verify that existing Elo results are current after source-data changes.

## Stage 4: documentation alignment
- Updated README execution order for #01–#53 and Stage 3 Elo safeguards.
- Clarified that existing-history row counts are not a freshness check and that `EXPLAIN` PASS does not prove complete runtime correctness.
- No SQL files or original backup changed in Stage 4.


## Stage 5: home-field adjustment in underdog comparisons

In blocks #40 and #41, the home-team perspective now uses `away_elo_before - 65 AS opponent_effective_elo` instead of `away_elo_before + 65`. The away-team perspective retains `home_elo_before + 65`. This aligns the underdog threshold with the home advantage used by the Elo model. Original backup and all other SQL files are unchanged. This change has not been executed against PostgreSQL yet.


## Final packaging note

The final ZIP is based on Stage 5. No SQL statements were changed during final packaging. The README was updated to reflect the reported successful DBeaver execution of blocks #40 and #41. The project has not been fully rebuilt and executed from scratch on a clean PostgreSQL database.

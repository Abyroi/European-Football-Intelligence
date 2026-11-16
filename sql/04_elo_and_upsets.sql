-- European Football Intelligence | 04_elo_and_upsets.sql
-- PostgreSQL | Execute statements individually as needed.

-- #37. GIANT KILLERS: ELO DATA VALIDATION
-- Check chronological match data before Elo modeling
-- ==================================================

WITH match_data AS (
    SELECT
        m.id AS match_id,
        l.name AS league,
        m.season,
        m.date AS match_date,
        m.home_team_api_id,
        m.away_team_api_id,
        m.home_team_goal,
        m.away_team_goal
    FROM matches m
    JOIN league l
        ON m.league_id = l.id
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
      AND m.date IS NOT NULL
      AND m.home_team_api_id IS NOT NULL
      AND m.away_team_api_id IS NOT NULL
),

date_groups AS (
    SELECT
        league,
        match_date,
        COUNT(*) AS matches_on_timestamp
    FROM match_data
    GROUP BY league, match_date
),

team_appearances AS (
    SELECT
        league,
        match_date,
        home_team_api_id AS team_api_id
    FROM match_data

    UNION ALL

    SELECT
        league,
        match_date,
        away_team_api_id AS team_api_id
    FROM match_data
),

duplicate_appearances AS (
    SELECT
        league,
        match_date,
        team_api_id,
        COUNT(*) AS appearances
    FROM team_appearances
    GROUP BY league, match_date, team_api_id
    HAVING COUNT(*) > 1
)

SELECT
    (SELECT COUNT(*) FROM match_data)
        AS usable_matches,

    (SELECT MIN(match_date) FROM match_data)
        AS earliest_match,

    (SELECT MAX(match_date) FROM match_data)
        AS latest_match,

    (SELECT COUNT(*)
     FROM date_groups
     WHERE matches_on_timestamp > 1)
        AS shared_timestamps,

    (SELECT COUNT(*)
     FROM duplicate_appearances)
        AS duplicate_team_timestamps,

    (SELECT COUNT(*)
     FROM match_data
     WHERE home_team_api_id = away_team_api_id)
        AS self_matches;


-- ==================================================

-- #38. BUILD HISTORICAL FOOTBALL ELO MODEL
-- Sequential Elo updates using PL/pgSQL
-- ==================================================

-- CAUTION: Rebuild deletes existing Elo outputs. Uncomment both DROP lines intentionally.
-- DROP TABLE IF EXISTS elo_match_history;
-- DROP TABLE IF EXISTS elo_team_ratings;

CREATE TABLE IF NOT EXISTS elo_team_ratings (
    team_api_id BIGINT PRIMARY KEY,
    elo_rating DOUBLE PRECISION NOT NULL DEFAULT 1500
);

CREATE TABLE IF NOT EXISTS elo_match_history (
    match_id BIGINT PRIMARY KEY,
    league_id BIGINT,
    season TEXT,
    match_date TIMESTAMP,
    home_team_api_id BIGINT,
    away_team_api_id BIGINT,
    home_goals INTEGER,
    away_goals INTEGER,
    home_elo_before DOUBLE PRECISION,
    away_elo_before DOUBLE PRECISION,
    expected_home_score DOUBLE PRECISION,
    actual_home_score DOUBLE PRECISION,
    home_elo_after DOUBLE PRECISION,
    away_elo_after DOUBLE PRECISION
);

DO $$
DECLARE
    match_record RECORD;

    home_rating DOUBLE PRECISION;
    away_rating DOUBLE PRECISION;

    expected_home DOUBLE PRECISION;
    actual_home DOUBLE PRECISION;

    rating_change DOUBLE PRECISION;

    k_factor DOUBLE PRECISION := 20;
    home_advantage DOUBLE PRECISION := 65;

BEGIN

    -- Do not overwrite or replay a previously calculated Elo history.
    -- If only part of the history exists, stop rather than silently accepting it.
    IF EXISTS (SELECT 1 FROM elo_match_history) THEN
        IF (SELECT COUNT(*) FROM elo_match_history) <>
           (SELECT COUNT(*) FROM matches
            WHERE home_team_goal IS NOT NULL
              AND away_team_goal IS NOT NULL
              AND date IS NOT NULL
              AND home_team_api_id IS NOT NULL
              AND away_team_api_id IS NOT NULL
              AND home_team_api_id <> away_team_api_id) THEN
            RAISE EXCEPTION 'Elo history exists but its row count differs from eligible matches. Review before rebuilding.';
        END IF;
        RAISE NOTICE 'Existing Elo history detected; calculation skipped. No ratings were changed.';
        RETURN;
    END IF;

    -- Empty history with noninitial team ratings is unsafe to replay.
    IF EXISTS (SELECT 1 FROM elo_team_ratings WHERE elo_rating <> 1500) THEN
        RAISE EXCEPTION 'Elo ratings are not initial, but history is empty. Review before rebuilding.';
    END IF;

    INSERT INTO elo_team_ratings (team_api_id)
    SELECT DISTINCT team_api_id
    FROM (
        SELECT home_team_api_id AS team_api_id
        FROM matches
        UNION
        SELECT away_team_api_id
        FROM matches
    ) teams
    WHERE team_api_id IS NOT NULL;

    FOR match_record IN
        SELECT
            id,
            league_id,
            season,
            date,
            home_team_api_id,
            away_team_api_id,
            home_team_goal,
            away_team_goal
        FROM matches
        WHERE home_team_goal IS NOT NULL
          AND away_team_goal IS NOT NULL
          AND date IS NOT NULL
          AND home_team_api_id IS NOT NULL
          AND away_team_api_id IS NOT NULL
          AND home_team_api_id <> away_team_api_id
        ORDER BY date, id
    LOOP

        SELECT elo_rating INTO home_rating
        FROM elo_team_ratings
        WHERE team_api_id = match_record.home_team_api_id;

        SELECT elo_rating INTO away_rating
        FROM elo_team_ratings
        WHERE team_api_id = match_record.away_team_api_id;

        expected_home :=
            1.0 / (
                1.0 + POWER(
                    10.0,
                    (
                        away_rating
                        - (home_rating + home_advantage)
                    ) / 400.0
                )
            );

        actual_home :=
            CASE
                WHEN match_record.home_team_goal >
                     match_record.away_team_goal
                THEN 1.0

                WHEN match_record.home_team_goal =
                     match_record.away_team_goal
                THEN 0.5

                ELSE 0.0
            END;

        rating_change :=
            k_factor * (actual_home - expected_home);

        INSERT INTO elo_match_history (
            match_id,
            league_id,
            season,
            match_date,
            home_team_api_id,
            away_team_api_id,
            home_goals,
            away_goals,
            home_elo_before,
            away_elo_before,
            expected_home_score,
            actual_home_score,
            home_elo_after,
            away_elo_after
        )
        VALUES (
            match_record.id,
            match_record.league_id,
            match_record.season,
            match_record.date,
            match_record.home_team_api_id,
            match_record.away_team_api_id,
            match_record.home_team_goal,
            match_record.away_team_goal,
            home_rating,
            away_rating,
            expected_home,
            actual_home,
            home_rating + rating_change,
            away_rating - rating_change
        );

        UPDATE elo_team_ratings
        SET elo_rating = home_rating + rating_change
        WHERE team_api_id = match_record.home_team_api_id;

        UPDATE elo_team_ratings
        SET elo_rating = away_rating - rating_change
        WHERE team_api_id = match_record.away_team_api_id;

    END LOOP;

END $$;

-- Validation
SELECT
    COUNT(*) AS processed_matches,
    ROUND(
        AVG(expected_home_score)::NUMERIC,
        4
    ) AS avg_expected_home_score,
    ROUND(
        MIN(home_elo_before)::NUMERIC,
        2
    ) AS min_home_elo,
    ROUND(
        MAX(home_elo_before)::NUMERIC,
        2
    ) AS max_home_elo
FROM elo_match_history;


-- ==================================================

-- #39. GIANT KILLERS: BIGGEST ELO UPSETS
-- Rank surprising victories using pre-match Elo
-- ==================================================

WITH match_upsets AS (
    SELECT
        e.match_id,
        e.match_date,
        e.season,
        l.name AS league,

        ht.team_long_name AS home_team,
        at.team_long_name AS away_team,

        e.home_goals,
        e.away_goals,

        ROUND(
            e.home_elo_before::NUMERIC, 2
        ) AS home_elo,

        ROUND(
            e.away_elo_before::NUMERIC, 2
        ) AS away_elo,

        CASE
            WHEN e.home_goals > e.away_goals
                THEN ht.team_long_name
            ELSE at.team_long_name
        END AS winner,

        CASE
            WHEN e.home_goals > e.away_goals
                THEN e.expected_home_score
            ELSE 1 - e.expected_home_score
        END AS winner_expected_score

    FROM elo_match_history e

    JOIN league l
        ON e.league_id = l.id

    JOIN team ht
        ON e.home_team_api_id = ht.team_api_id

    JOIN team at
        ON e.away_team_api_id = at.team_api_id

    WHERE e.home_goals <> e.away_goals
)

SELECT
    match_date::DATE AS match_date,
    league,
    home_team,
    away_team,
    home_goals,
    away_goals,
    winner,
    home_elo,
    away_elo,
    ROUND(
        winner_expected_score::NUMERIC, 4
    ) AS winner_expected_score,

    ROUND(
        (1 - winner_expected_score)::NUMERIC,
        4
    ) AS upset_score

FROM match_upsets

ORDER BY
    upset_score DESC,
    match_date

LIMIT 20;


-- ==================================================

-- #40. GIANT KILLER INDEX
-- Teams consistently defeating stronger opponents
-- ==================================================

WITH team_perspective AS (
    SELECT
        e.match_id,
        e.season,
        e.home_team_api_id AS team_api_id,
        e.home_elo_before AS team_elo,
        e.away_elo_before - 65 AS opponent_effective_elo,
        e.home_goals AS goals_for,
        e.away_goals AS goals_against
    FROM elo_match_history e

    UNION ALL

    SELECT
        e.match_id,
        e.season,
        e.away_team_api_id AS team_api_id,
        e.away_elo_before AS team_elo,
        e.home_elo_before + 65 AS opponent_effective_elo,
        e.away_goals AS goals_for,
        e.home_goals AS goals_against
    FROM elo_match_history e
),

underdog_matches AS (
    SELECT
        *,
        opponent_effective_elo - team_elo AS elo_disadvantage,
        CASE
            WHEN goals_for > goals_against THEN 1
            ELSE 0
        END AS won
    FROM team_perspective
    WHERE opponent_effective_elo - team_elo >= 100
),

giant_killers AS (
    SELECT
        team_api_id,
        COUNT(*) AS underdog_matches,
        SUM(won) AS upset_wins,
        ROUND(
            100.0 * SUM(won) / COUNT(*),
            2
        ) AS upset_win_rate,
        ROUND(
            AVG(elo_disadvantage)::NUMERIC,
            2
        ) AS avg_elo_disadvantage,
        ROUND(
            AVG(elo_disadvantage) FILTER (
                WHERE won = 1
            )::NUMERIC,
            2
        ) AS avg_gap_in_upset_wins
    FROM underdog_matches
    GROUP BY team_api_id
    HAVING COUNT(*) >= 15
)

SELECT
    t.team_long_name AS team,
    g.underdog_matches,
    g.upset_wins,
    g.upset_win_rate,
    g.avg_elo_disadvantage,
    g.avg_gap_in_upset_wins
FROM giant_killers g
JOIN team t
    ON g.team_api_id = t.team_api_id
ORDER BY
    g.upset_win_rate DESC,
    g.upset_wins DESC,
    g.avg_gap_in_upset_wins DESC NULLS LAST
LIMIT 20;



-- ==================================================

-- #41. GIANT KILLERS: ELO OVERPERFORMANCE
-- Compare actual vs expected match scores
-- for teams classified as underdogs
-- ==================================================

WITH team_perspective AS (
    SELECT
        match_id,
        home_team_api_id AS team_api_id,
        home_elo_before AS team_elo,
        away_elo_before - 65 AS opponent_effective_elo,
        expected_home_score AS expected_score,
        actual_home_score AS actual_score
    FROM elo_match_history

    UNION ALL

    SELECT
        match_id,
        away_team_api_id AS team_api_id,
        away_elo_before AS team_elo,
        home_elo_before + 65 AS opponent_effective_elo,
        1 - expected_home_score AS expected_score,
        1 - actual_home_score AS actual_score
    FROM elo_match_history
),

underdog_matches AS (
    SELECT
        *,
        actual_score - expected_score AS score_surprise
    FROM team_perspective
    WHERE opponent_effective_elo - team_elo >= 100
),

team_performance AS (
    SELECT
        team_api_id,
        COUNT(*) AS underdog_matches,

        ROUND(
            AVG(expected_score)::NUMERIC, 3
        ) AS avg_expected_score,

        ROUND(
            AVG(actual_score)::NUMERIC, 3
        ) AS avg_actual_score,

        ROUND(
            AVG(score_surprise)::NUMERIC, 3
        ) AS avg_overperformance,

        ROUND(
            SUM(score_surprise)::NUMERIC, 2
        ) AS total_overperformance

    FROM underdog_matches
    GROUP BY team_api_id
    HAVING COUNT(*) >= 20
)

SELECT
    t.team_long_name AS team,
    p.underdog_matches,
    p.avg_expected_score,
    p.avg_actual_score,
    p.avg_overperformance,
    p.total_overperformance
FROM team_performance p
JOIN team t
    ON p.team_api_id = t.team_api_id
ORDER BY
    p.avg_overperformance DESC,
    p.underdog_matches DESC
LIMIT 20;




-- ==================================================

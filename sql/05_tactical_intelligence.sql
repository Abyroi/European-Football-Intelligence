-- European Football Intelligence | 05_tactical_intelligence.sql
-- PostgreSQL | Execute statements individually as needed.

-- #42. TACTICAL DNA: MATCH INTELLIGENCE
-- Fixed PostgreSQL column names
-- ==================================================

-- Existing view is updated without dropping dependent objects.

CREATE OR REPLACE VIEW tactical_match_intelligence AS
SELECT
    e.match_id,
    e.match_date,
    e.season,
    l.name AS league,

    ht.team_long_name AS home_team,
    at.team_long_name AS away_team,

    e.home_goals,
    e.away_goals,

    e.home_elo_before,
    e.away_elo_before,
    e.expected_home_score,
    e.actual_home_score,

    e.actual_home_score - e.expected_home_score
        AS home_elo_overperformance,

    hta.date AS home_tactics_date,
    ata.date AS away_tactics_date,

    hta.buildupplayspeed AS home_build_up_speed,
    ata.buildupplayspeed AS away_build_up_speed,

    hta.buildupplaypassing AS home_passing,
    ata.buildupplaypassing AS away_passing,

    hta.chancecreationshooting AS home_shooting,
    ata.chancecreationshooting AS away_shooting,

    hta.defencepressure AS home_pressure,
    ata.defencepressure AS away_pressure,

    hta.defenceaggression AS home_aggression,
    ata.defenceaggression AS away_aggression,

    hta.defenceteamwidth AS home_defensive_width,
    ata.defenceteamwidth AS away_defensive_width

FROM elo_match_history e

JOIN league l
    ON e.league_id = l.id

JOIN team ht
    ON e.home_team_api_id = ht.team_api_id

JOIN team at
    ON e.away_team_api_id = at.team_api_id

LEFT JOIN LATERAL (
    SELECT *
    FROM team_attributes ta
    WHERE ta.team_api_id = e.home_team_api_id
      AND ta.date < e.match_date
    ORDER BY ta.date DESC, ta.id DESC
    LIMIT 1
) hta ON TRUE

LEFT JOIN LATERAL (
    SELECT *
    FROM team_attributes ta
    WHERE ta.team_api_id = e.away_team_api_id
      AND ta.date < e.match_date
    ORDER BY ta.date DESC, ta.id DESC
    LIMIT 1
) ata ON TRUE;

-- Validate tactical coverage

SELECT
    COUNT(*) AS total_matches,

    COUNT(*) FILTER (
        WHERE home_build_up_speed IS NOT NULL
    ) AS home_tactics_available,

    COUNT(*) FILTER (
        WHERE away_build_up_speed IS NOT NULL
    ) AS away_tactics_available,

    COUNT(*) FILTER (
        WHERE home_build_up_speed IS NOT NULL
          AND away_build_up_speed IS NOT NULL
    ) AS both_teams_available,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE home_build_up_speed IS NOT NULL
              AND away_build_up_speed IS NOT NULL
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS complete_coverage_pct,

    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (
                match_date - home_tactics_date
            )) / 86400
        )::NUMERIC,
        1
    ) AS avg_home_tactics_age_days

FROM tactical_match_intelligence;


-- ==================================================

-- #43. TACTICAL DNA: DATA FRESHNESS AUDIT
-- Evaluate historical tactical snapshot freshness
-- ==================================================

WITH tactical_freshness AS (
    SELECT
        match_id,
        match_date,
        league,
        home_tactics_date,
        away_tactics_date,

        EXTRACT(
            EPOCH FROM (match_date - home_tactics_date)
        ) / 86400.0 AS home_age_days,

        EXTRACT(
            EPOCH FROM (match_date - away_tactics_date)
        ) / 86400.0 AS away_age_days

    FROM tactical_match_intelligence
),

coverage AS (
    SELECT
        COUNT(*) AS total_matches,

        COUNT(*) FILTER (
            WHERE home_age_days IS NOT NULL
              AND away_age_days IS NOT NULL
        ) AS both_available,

        COUNT(*) FILTER (
            WHERE home_age_days <= 90
              AND away_age_days <= 90
        ) AS both_within_90_days,

        COUNT(*) FILTER (
            WHERE home_age_days <= 180
              AND away_age_days <= 180
        ) AS both_within_180_days,

        COUNT(*) FILTER (
            WHERE home_age_days <= 365
              AND away_age_days <= 365
        ) AS both_within_365_days

    FROM tactical_freshness
)

SELECT
    total_matches,
    both_available,
    both_within_90_days,
    both_within_180_days,
    both_within_365_days,

    ROUND(
        100.0 * both_within_90_days
        / NULLIF(total_matches, 0), 2
    ) AS coverage_90_pct,

    ROUND(
        100.0 * both_within_180_days
        / NULLIF(total_matches, 0), 2
    ) AS coverage_180_pct,

    ROUND(
        100.0 * both_within_365_days
        / NULLIF(total_matches, 0), 2
    ) AS coverage_365_pct

FROM coverage;




-- ==================================================

-- #44. TACTICAL DNA: PRESSING VS ELO EXPECTATIONS
-- Underdog performance by defensive pressure
-- Fresh tactical profiles: max 180 days
-- ==================================================

WITH team_matches AS (

    SELECT
        match_id,
        match_date,
        home_team AS team,
        home_pressure AS pressure,
        home_tactics_date AS tactics_date,

        home_elo_before AS team_elo,
        away_elo_before + 65 AS opponent_effective_elo,

        expected_home_score AS expected_score,
        actual_home_score AS actual_score

    FROM tactical_match_intelligence

    UNION ALL

    SELECT
        match_id,
        match_date,
        away_team AS team,
        away_pressure AS pressure,
        away_tactics_date AS tactics_date,

        away_elo_before AS team_elo,
        home_elo_before + 65 AS opponent_effective_elo,

        1 - expected_home_score AS expected_score,
        1 - actual_home_score AS actual_score

    FROM tactical_match_intelligence
),

fresh_underdogs AS (
    SELECT
        *,
        opponent_effective_elo - team_elo
            AS elo_disadvantage,

        actual_score - expected_score
            AS elo_overperformance

    FROM team_matches

    WHERE pressure IS NOT NULL

      AND tactics_date IS NOT NULL

      AND match_date - tactics_date
          BETWEEN INTERVAL '0 days'
              AND INTERVAL '180 days'

      AND opponent_effective_elo - team_elo >= 100
),

pressure_groups AS (
    SELECT
        *,
        NTILE(3) OVER (
            ORDER BY pressure, match_id, team
        ) AS pressure_group
    FROM fresh_underdogs
)

SELECT
    CASE pressure_group
        WHEN 1 THEN 'Low pressure'
        WHEN 2 THEN 'Medium pressure'
        WHEN 3 THEN 'High pressure'
    END AS pressing_style,

    COUNT(*) AS matches,

    ROUND(AVG(pressure)::NUMERIC, 2)
        AS avg_pressure,

    ROUND(AVG(elo_disadvantage)::NUMERIC, 2)
        AS avg_elo_disadvantage,

    ROUND(AVG(expected_score)::NUMERIC, 3)
        AS expected_elo_score,

    ROUND(AVG(actual_score)::NUMERIC, 3)
        AS actual_elo_score,

    ROUND(
        AVG(elo_overperformance)::NUMERIC, 3
    ) AS avg_overperformance,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE actual_score = 1
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS win_rate_pct

FROM pressure_groups

GROUP BY pressure_group
ORDER BY pressure_group;



-- ==================================================

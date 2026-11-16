-- European Football Intelligence | 02_league_and_team_analysis.sql
-- PostgreSQL | Execute statements individually as needed.

-- #15. FOOTBALL ANALYTICS
-- Matches played in each European league
-- ==================================================

SELECT
    c.name AS country,
    l.name AS league,
    COUNT(m.id) AS total_matches
FROM league l
JOIN country c
    ON l.country_id = c.id
LEFT JOIN matches m
    ON l.id = m.league_id
GROUP BY
    c.name,
    l.name
ORDER BY total_matches DESC;







-- ==================================================

-- #16. TEAM PERFORMANCE ANALYSIS
-- Top 15 teams by total wins
-- ==================================================

WITH team_results AS (
    SELECT
        home_team_api_id AS team_api_id,
        CASE
            WHEN home_team_goal > away_team_goal THEN 1
            ELSE 0
        END AS win
    FROM matches
    WHERE home_team_goal IS NOT NULL
      AND away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        away_team_api_id AS team_api_id,
        CASE
            WHEN away_team_goal > home_team_goal THEN 1
            ELSE 0
        END AS win
    FROM matches
    WHERE home_team_goal IS NOT NULL
      AND away_team_goal IS NOT NULL
)

SELECT
    t.team_long_name AS team,
    COUNT(*) AS matches_played,
    SUM(tr.win) AS total_wins,
    ROUND(
        100.0 * SUM(tr.win) / COUNT(*),
        2
    ) AS win_percentage
FROM team_results tr
JOIN team t
    ON tr.team_api_id = t.team_api_id
GROUP BY
    t.team_api_id,
    t.team_long_name
ORDER BY
    total_wins DESC,
    win_percentage DESC
LIMIT 15;



-- ==================================================

-- #17. HOME ADVANTAGE ANALYSIS
-- Research Question:
-- How does home advantage vary across European leagues?
-- ==================================================

WITH match_results AS (
    SELECT
        league_id,
        season,
        CASE
            WHEN home_team_goal > away_team_goal THEN 'Home Win'
            WHEN home_team_goal < away_team_goal THEN 'Away Win'
            ELSE 'Draw'
        END AS match_result
    FROM matches
    WHERE home_team_goal IS NOT NULL
      AND away_team_goal IS NOT NULL
)

SELECT
    l.name AS league,
    COUNT(*) AS total_matches,

    COUNT(*) FILTER (
        WHERE mr.match_result = 'Home Win'
    ) AS home_wins,

    COUNT(*) FILTER (
        WHERE mr.match_result = 'Away Win'
    ) AS away_wins,

    COUNT(*) FILTER (
        WHERE mr.match_result = 'Draw'
    ) AS draws,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE mr.match_result = 'Home Win'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS home_win_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE mr.match_result = 'Away Win'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS away_win_pct

FROM match_results mr
JOIN league l
    ON mr.league_id = l.id

GROUP BY l.name
ORDER BY home_win_pct DESC;



-- ==================================================

-- #18. HOME ADVANTAGE TREND ANALYSIS
-- Track home win rates across eight seasons
-- ==================================================

WITH seasonal_results AS (
    SELECT
        season,
        COUNT(*) AS total_matches,
        COUNT(*) FILTER (
            WHERE home_team_goal > away_team_goal
        ) AS home_wins,
        COUNT(*) FILTER (
            WHERE home_team_goal < away_team_goal
        ) AS away_wins,
        COUNT(*) FILTER (
            WHERE home_team_goal = away_team_goal
        ) AS draws
    FROM matches
    WHERE home_team_goal IS NOT NULL
      AND away_team_goal IS NOT NULL
    GROUP BY season
)

SELECT
    season,
    total_matches,
    home_wins,
    away_wins,
    draws,
    ROUND(
        100.0 * home_wins / NULLIF(total_matches, 0),
        2
    ) AS home_win_pct,
    ROUND(
        100.0 * away_wins / NULLIF(total_matches, 0),
        2
    ) AS away_win_pct
FROM seasonal_results
ORDER BY season;



-- ==================================================

-- #19. LEAGUE-LEVEL HOME ADVANTAGE TRENDS
-- Compare home win rates between first and last seasons
-- ==================================================

WITH league_seasons AS (
    SELECT
        l.name AS league,
        m.season,
        COUNT(*) AS total_matches,
        ROUND(
            100.0 * COUNT(*) FILTER (
                WHERE m.home_team_goal > m.away_team_goal
            ) / NULLIF(COUNT(*), 0),
            2
        ) AS home_win_pct
    FROM matches m
    JOIN league l
        ON m.league_id = l.id
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
    GROUP BY l.name, m.season
),
comparison AS (
    SELECT
        league,
        MAX(home_win_pct) FILTER (
            WHERE season = '2008/2009'
        ) AS first_season_pct,
        MAX(home_win_pct) FILTER (
            WHERE season = '2015/2016'
        ) AS last_season_pct
    FROM league_seasons
    GROUP BY league
)
SELECT
    league,
    first_season_pct,
    last_season_pct,
    ROUND(
        last_season_pct - first_season_pct,
        2
    ) AS change_pp
FROM comparison
WHERE first_season_pct IS NOT NULL
  AND last_season_pct IS NOT NULL
ORDER BY change_pp;



-- ==================================================

-- #20. HOME ADVANTAGE TREND REGRESSION
-- Measure the direction of seasonal trends
-- ==================================================

WITH seasonal_stats AS (
    SELECT
        l.name AS league,
        m.season,
        CAST(LEFT(m.season, 4) AS INTEGER)
            AS season_year,
        COUNT(*) AS total_matches,
        100.0 * COUNT(*) FILTER (
            WHERE m.home_team_goal > m.away_team_goal
        ) / NULLIF(COUNT(*), 0) AS home_win_pct
    FROM matches m
    JOIN league l
        ON m.league_id = l.id
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
    GROUP BY l.name, m.season
)

SELECT
    league,
    COUNT(*) AS seasons_analyzed,
    ROUND(
        REGR_SLOPE(
            home_win_pct,
            season_year
        )::NUMERIC,
        3
    ) AS trend_pp_per_year
FROM seasonal_stats
GROUP BY league
ORDER BY trend_pp_per_year;



-- ==================================================

-- #21. TEAM DOMINANCE AND CONSISTENCY
-- Calculate team performance across all seasons
-- ==================================================

WITH team_matches AS (
    SELECT
        season,
        home_team_api_id AS team_api_id,
        home_team_goal AS goals_scored,
        away_team_goal AS goals_conceded,
        CASE
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END AS points,
        CASE
            WHEN home_team_goal > away_team_goal THEN 1
            ELSE 0
        END AS win
    FROM matches
    WHERE home_team_goal IS NOT NULL
      AND away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        season,
        away_team_api_id,
        away_team_goal,
        home_team_goal,
        CASE
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END,
        CASE
            WHEN away_team_goal > home_team_goal THEN 1
            ELSE 0
        END
    FROM matches
    WHERE home_team_goal IS NOT NULL
      AND away_team_goal IS NOT NULL
),

seasonal_performance AS (
    SELECT
        team_api_id,
        season,
        COUNT(*) AS matches_played,
        SUM(points) AS total_points,
        SUM(win) AS total_wins,
        SUM(goals_scored) AS goals_scored,
        SUM(goals_conceded) AS goals_conceded,
        ROUND(
            SUM(points)::NUMERIC / COUNT(*),
            2
        ) AS points_per_match
    FROM team_matches
    GROUP BY team_api_id, season
)

SELECT
    t.team_long_name AS team,
    COUNT(*) AS seasons_played,
    SUM(sp.matches_played) AS total_matches,
    SUM(sp.total_wins) AS total_wins,
    SUM(sp.total_points) AS total_points,
    ROUND(
        SUM(sp.total_points)::NUMERIC
        / NULLIF(SUM(sp.matches_played), 0),
        2
    ) AS overall_ppm,
    ROUND(
        STDDEV_SAMP(sp.points_per_match),
        3
    ) AS consistency_stddev
FROM seasonal_performance sp
JOIN team t
    ON sp.team_api_id = t.team_api_id
GROUP BY t.team_api_id, t.team_long_name
HAVING COUNT(*) >= 5
ORDER BY overall_ppm DESC
LIMIT 15;



-- ==================================================

-- #22. SEASONAL LEAGUE LEADERS
-- Rank teams by points within each league and season
-- ==================================================

WITH team_results AS (
    SELECT
        league_id,
        season,
        home_team_api_id AS team_api_id,
        CASE
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END AS points,
        home_team_goal - away_team_goal AS goal_difference
    FROM matches
    WHERE home_team_goal IS NOT NULL
      AND away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        league_id,
        season,
        away_team_api_id,
        CASE
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END,
        away_team_goal - home_team_goal
    FROM matches
    WHERE home_team_goal IS NOT NULL
      AND away_team_goal IS NOT NULL
),

seasonal_points AS (
    SELECT
        league_id,
        season,
        team_api_id,
        COUNT(*) AS matches_played,
        SUM(points) AS total_points,
        SUM(goal_difference) AS goal_difference
    FROM team_results
    GROUP BY league_id, season, team_api_id
),

ranked_teams AS (
    SELECT
        l.name AS league,
        sp.season,
        t.team_long_name AS team,
        sp.matches_played,
        sp.total_points,
        sp.goal_difference,
        DENSE_RANK() OVER (
            PARTITION BY sp.league_id, sp.season
            ORDER BY sp.total_points DESC,
                     sp.goal_difference DESC
        ) AS league_rank
    FROM seasonal_points sp
    JOIN league l ON sp.league_id = l.id
    JOIN team t ON sp.team_api_id = t.team_api_id
)

SELECT
    league,
    season,
    team,
    matches_played,
    total_points,
    goal_difference
FROM ranked_teams
WHERE league_rank = 1
ORDER BY league, season;



-- ==================================================

-- #23. DATA QUALITY: SEASON COMPLETENESS
-- Check match counts by league and season
-- ==================================================

SELECT
    l.name AS league,
    m.season,
    COUNT(*) AS total_matches,
    COUNT(DISTINCT m.home_team_api_id)
        AS home_teams,
    COUNT(DISTINCT m.away_team_api_id)
        AS away_teams,
    COUNT(*) FILTER (
        WHERE m.home_team_goal IS NULL
           OR m.away_team_goal IS NULL
    ) AS missing_scores
FROM matches m
JOIN league l
    ON m.league_id = l.id
GROUP BY l.name, m.season
ORDER BY l.name, m.season;


-- ==================================================

-- #24. AUTOMATED SEASON COMPLETENESS CHECK
-- Compare each season with its league's maximum
-- ==================================================

WITH season_counts AS (
    SELECT
        l.name AS league,
        m.season,
        COUNT(*) AS actual_matches
    FROM matches m
    JOIN league l
        ON m.league_id = l.id
    GROUP BY l.name, m.season
),
season_quality AS (
    SELECT
        league,
        season,
        actual_matches,
        MAX(actual_matches) OVER (
            PARTITION BY league
        ) AS reference_matches
    FROM season_counts
)
SELECT
    league,
    season,
    actual_matches,
    reference_matches,
    reference_matches - actual_matches
        AS missing_vs_reference,
    ROUND(
        100.0 * actual_matches
        / NULLIF(reference_matches, 0),
        2
    ) AS completeness_pct,
    CASE
        WHEN actual_matches = reference_matches
            THEN 'REFERENCE MATCH COUNT'
        WHEN actual_matches >= reference_matches * 0.95
            THEN 'REVIEW - MINOR DIFFERENCE'
        ELSE 'REVIEW - LARGE DIFFERENCE'
    END AS quality_status
FROM season_quality
WHERE actual_matches < reference_matches
ORDER BY completeness_pct ASC;



-- ==================================================

-- #25. TEAM-LEVEL SEASON COMPLETENESS
-- Detect irregular match counts
-- Assumes a double round-robin format
-- ==================================================

WITH team_games AS (
    SELECT
        league_id,
        season,
        home_team_api_id AS team_api_id
    FROM matches

    UNION ALL

    SELECT
        league_id,
        season,
        away_team_api_id
    FROM matches
),
team_counts AS (
    SELECT
        league_id,
        season,
        team_api_id,
        COUNT(*) AS matches_played
    FROM team_games
    GROUP BY league_id, season, team_api_id
),
season_summary AS (
    SELECT
        league_id,
        season,
        COUNT(*) AS teams,
        MIN(matches_played) AS min_matches,
        MAX(matches_played) AS max_matches,
        SUM(matches_played) / 2 AS total_matches
    FROM team_counts
    GROUP BY league_id, season
)
SELECT
    l.name AS league,
    s.season,
    s.teams,
    s.total_matches,
    s.min_matches,
    s.max_matches,
    2 * (s.teams - 1)
        AS expected_per_team,
    CASE
        WHEN s.min_matches = 2 * (s.teams - 1)
         AND s.max_matches = 2 * (s.teams - 1)
            THEN 'MATCH COUNTS CONSISTENT'
        ELSE 'REQUIRES REVIEW'
    END AS quality_status
FROM season_summary s
JOIN league l
    ON s.league_id = l.id
WHERE s.min_matches <> 2 * (s.teams - 1)
   OR s.max_matches <> 2 * (s.teams - 1)
ORDER BY l.name, s.season;


-- ==================================================

-- #26. TEAM DOMINANCE: LEAGUE LEADERS
-- Exclude seasons flagged for data quality review
-- ==================================================

WITH valid_matches AS (
    SELECT m.*
    FROM matches m
    JOIN league l ON m.league_id = l.id
    WHERE NOT (
        (l.name = 'Belgium Jupiler League'
         AND m.season = '2013/2014')
        OR
        (l.name = 'Italy Serie A'
         AND m.season IN ('2011/2012', '2014/2015'))
        OR
        (l.name = 'Switzerland Super League'
         AND m.season = '2011/2012')
    )
    AND m.home_team_goal IS NOT NULL
    AND m.away_team_goal IS NOT NULL
),

team_results AS (
    SELECT
        league_id,
        season,
        home_team_api_id AS team_api_id,
        CASE
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END AS points,
        home_team_goal - away_team_goal AS goal_difference
    FROM valid_matches

    UNION ALL

    SELECT
        league_id,
        season,
        away_team_api_id,
        CASE
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END,
        away_team_goal - home_team_goal
    FROM valid_matches
),

seasonal_points AS (
    SELECT
        league_id,
        season,
        team_api_id,
        SUM(points) AS total_points,
        SUM(goal_difference) AS goal_difference
    FROM team_results
    GROUP BY league_id, season, team_api_id
),

ranked AS (
    SELECT
        league_id,
        season,
        team_api_id,
        DENSE_RANK() OVER (
            PARTITION BY league_id, season
            ORDER BY total_points DESC,
                     goal_difference DESC
        ) AS league_rank
    FROM seasonal_points
)

SELECT
    t.team_long_name AS team,
    l.name AS league,
    COUNT(*) AS first_place_finishes
FROM ranked r
JOIN team t
    ON r.team_api_id = t.team_api_id
JOIN league l
    ON r.league_id = l.id
WHERE r.league_rank = 1
GROUP BY t.team_api_id, t.team_long_name, l.name
ORDER BY first_place_finishes DESC, team
LIMIT 20;




-- ==================================================

-- #27. TEAM PERFORMANCE EVOLUTION
-- Season-over-season change using LAG()
-- ==================================================

WITH team_matches AS (
    SELECT
        season,
        home_team_api_id AS team_api_id,
        CASE
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM matches
    WHERE home_team_goal IS NOT NULL
      AND away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        season,
        away_team_api_id,
        CASE
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END
    FROM matches
    WHERE home_team_goal IS NOT NULL
      AND away_team_goal IS NOT NULL
),

seasonal_performance AS (
    SELECT
        team_api_id,
        season,
        COUNT(*) AS matches_played,
        ROUND(
            SUM(points)::NUMERIC / COUNT(*),
            3
        ) AS points_per_match
    FROM team_matches
    GROUP BY team_api_id, season
),

performance_trends AS (
    SELECT
        t.team_long_name AS team,
        sp.season,
        sp.matches_played,
        sp.points_per_match,
        LAG(sp.points_per_match) OVER (
            PARTITION BY sp.team_api_id
            ORDER BY sp.season
        ) AS previous_season_ppm
    FROM seasonal_performance sp
    JOIN team t
        ON sp.team_api_id = t.team_api_id
)

SELECT
    team,
    season,
    matches_played,
    points_per_match,
    previous_season_ppm,
    ROUND(
        points_per_match - previous_season_ppm,
        3
    ) AS ppm_change
FROM performance_trends
WHERE previous_season_ppm IS NOT NULL
ORDER BY ppm_change DESC
LIMIT 20;



-- ==================================================

-- #28. VALIDATED SEASON-OVER-SEASON IMPROVEMENT
-- Compare consecutive seasons with quality filters
-- ==================================================

WITH valid_matches AS (
    SELECT
        m.*
    FROM matches m
    JOIN league l ON m.league_id = l.id
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
      AND NOT (
          (l.name = 'Belgium Jupiler League'
           AND m.season = '2013/2014')
          OR
          (l.name = 'Italy Serie A'
           AND m.season IN ('2011/2012', '2014/2015'))
          OR
          (l.name = 'Switzerland Super League'
           AND m.season = '2011/2012')
      )
),

team_matches AS (
    SELECT
        league_id,
        season,
        home_team_api_id AS team_api_id,
        CASE
            WHEN home_team_goal > away_team_goal THEN 3
            WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM valid_matches

    UNION ALL

    SELECT
        league_id,
        season,
        away_team_api_id,
        CASE
            WHEN away_team_goal > home_team_goal THEN 3
            WHEN away_team_goal = home_team_goal THEN 1
            ELSE 0
        END
    FROM valid_matches
),

seasonal_performance AS (
    SELECT
        league_id,
        team_api_id,
        season,
        CAST(LEFT(season, 4) AS INTEGER)
            AS season_year,
        COUNT(*) AS matches_played,
        SUM(points)::NUMERIC / COUNT(*)
            AS points_per_match
    FROM team_matches
    GROUP BY league_id, team_api_id, season
),

previous_performance AS (
    SELECT
        *,
        LAG(season_year) OVER (
            PARTITION BY league_id, team_api_id
            ORDER BY season_year
        ) AS previous_year,
        LAG(matches_played) OVER (
            PARTITION BY league_id, team_api_id
            ORDER BY season_year
        ) AS previous_matches,
        LAG(points_per_match) OVER (
            PARTITION BY league_id, team_api_id
            ORDER BY season_year
        ) AS previous_ppm
    FROM seasonal_performance
)

SELECT
    t.team_long_name AS team,
    l.name AS league,
    p.season,
    p.matches_played,
    ROUND(p.previous_ppm, 3) AS previous_ppm,
    ROUND(p.points_per_match, 3) AS current_ppm,
    ROUND(
        p.points_per_match - p.previous_ppm,
        3
    ) AS ppm_improvement
FROM previous_performance p
JOIN team t
    ON p.team_api_id = t.team_api_id
JOIN league l
    ON p.league_id = l.id
WHERE p.previous_year = p.season_year - 1
  AND p.matches_played >= 20
  AND p.previous_matches >= 20
ORDER BY ppm_improvement DESC
LIMIT 15;


-- ==================================================

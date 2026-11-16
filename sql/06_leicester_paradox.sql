-- European Football Intelligence | 06_leicester_paradox.sql
-- PostgreSQL | Execute statements individually as needed.

-- #45. THE LEICESTER PARADOX
-- Historical season-to-season performance shifts
-- ==================================================

WITH team_matches AS (

    SELECT
        m.league_id,
        m.season,
        m.home_team_api_id AS team_api_id,
        m.date AS match_date,
        m.home_team_goal AS goals_for,
        m.away_team_goal AS goals_against,

        CASE
            WHEN m.home_team_goal > m.away_team_goal THEN 3
            WHEN m.home_team_goal = m.away_team_goal THEN 1
            ELSE 0
        END AS points

    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        m.league_id,
        m.season,
        m.away_team_api_id AS team_api_id,
        m.date AS match_date,
        m.away_team_goal AS goals_for,
        m.home_team_goal AS goals_against,

        CASE
            WHEN m.away_team_goal > m.home_team_goal THEN 3
            WHEN m.away_team_goal = m.home_team_goal THEN 1
            ELSE 0
        END AS points

    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
),

season_stats AS (

    SELECT
        league_id,
        season,
        team_api_id,

        COUNT(*) AS matches_played,
        SUM(points) AS total_points,

        ROUND(
            AVG(points)::NUMERIC, 3
        ) AS points_per_match,

        SUM(goals_for) AS goals_for,
        SUM(goals_against) AS goals_against,

        SUM(goals_for - goals_against)
            AS goal_difference

    FROM team_matches
    GROUP BY league_id, season, team_api_id
),

ranked_seasons AS (

    SELECT
        *,

        RANK() OVER (
            PARTITION BY league_id, season
            ORDER BY
                total_points DESC,
                goal_difference DESC,
                goals_for DESC
        ) AS league_position

    FROM season_stats
),

season_comparison AS (

    SELECT
        *,
        LAG(season) OVER (
            PARTITION BY team_api_id
            ORDER BY LEFT(season, 4)::INTEGER
        ) AS previous_season,

        LAG(points_per_match) OVER (
            PARTITION BY team_api_id
            ORDER BY LEFT(season, 4)::INTEGER
        ) AS previous_ppm,

        LAG(league_position) OVER (
            PARTITION BY team_api_id
            ORDER BY LEFT(season, 4)::INTEGER
        ) AS previous_position,

        LAG(matches_played) OVER (
            PARTITION BY team_api_id
            ORDER BY LEFT(season, 4)::INTEGER
        ) AS previous_matches

    FROM ranked_seasons
)

SELECT
    t.team_long_name AS team,
    l.name AS league,
    s.previous_season,
    s.season AS breakthrough_season,

    s.previous_position,
    s.league_position AS current_position,

    s.previous_ppm,
    s.points_per_match AS current_ppm,

    ROUND(
        (s.points_per_match - s.previous_ppm)::NUMERIC,
        3
    ) AS ppm_improvement,

    s.previous_matches,
    s.matches_played

FROM season_comparison s

JOIN team t
    ON s.team_api_id = t.team_api_id

JOIN league l
    ON s.league_id = l.id

WHERE s.previous_season IS NOT NULL

  -- Only consecutive seasons
  AND LEFT(s.season, 4)::INTEGER
      - LEFT(s.previous_season, 4)::INTEGER = 1

  -- Exclude short or incomplete team seasons
  AND s.previous_matches >= 30
  AND s.matches_played >= 30

ORDER BY
    ppm_improvement DESC,
    s.team_api_id

LIMIT 25;



-- ==================================================

-- #46. LEICESTER PARADOX: HIDDEN MOMENTUM
-- First 10 vs last 10 matches before title season
-- ==================================================

WITH team_matches AS (
    SELECT
        m.id AS match_id,
        m.season,
        m.date AS match_date,
        m.home_team_api_id AS team_api_id,
        CASE
            WHEN m.home_team_goal > m.away_team_goal THEN 3
            WHEN m.home_team_goal = m.away_team_goal THEN 1
            ELSE 0
        END AS points,
        m.home_team_goal - m.away_team_goal
            AS goal_difference
    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        m.id AS match_id,
        m.season,
        m.date AS match_date,
        m.away_team_api_id AS team_api_id,
        CASE
            WHEN m.away_team_goal > m.home_team_goal THEN 3
            WHEN m.away_team_goal = m.home_team_goal THEN 1
            ELSE 0
        END AS points,
        m.away_team_goal - m.home_team_goal
            AS goal_difference
    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
),

ordered_matches AS (
    SELECT
        tm.*,
        t.team_long_name AS team,

        ROW_NUMBER() OVER (
            PARTITION BY tm.team_api_id, tm.season
            ORDER BY tm.match_date, tm.match_id
        ) AS match_number,

        COUNT(*) OVER (
            PARTITION BY tm.team_api_id, tm.season
        ) AS season_matches

    FROM team_matches tm
    JOIN team t
        ON tm.team_api_id = t.team_api_id

    WHERE
        (
            t.team_long_name = 'Leicester City'
            AND tm.season = '2014/2015'
        )
        OR
        (
            t.team_long_name = 'Montpellier Hérault SC'
            AND tm.season = '2010/2011'
        )
),

form_comparison AS (
    SELECT
        team,
        season,
        season_matches,

        ROUND(
            AVG(points) FILTER (
                WHERE match_number <= 10
            )::NUMERIC, 3
        ) AS first_10_ppm,

        ROUND(
            AVG(points) FILTER (
                WHERE match_number > season_matches - 10
            )::NUMERIC, 3
        ) AS last_10_ppm,

        SUM(goal_difference) FILTER (
            WHERE match_number <= 10
        ) AS first_10_goal_difference,

        SUM(goal_difference) FILTER (
            WHERE match_number > season_matches - 10
        ) AS last_10_goal_difference

    FROM ordered_matches
    GROUP BY team, season, season_matches
)

SELECT
    *,
    ROUND(
        (last_10_ppm - first_10_ppm)::NUMERIC,
        3
    ) AS late_season_momentum

FROM form_comparison

ORDER BY late_season_momentum DESC;




-- ==================================================

-- #47. LEICESTER PARADOX
-- Was Leicester's pre-title momentum exceptional?
-- Premier League 2014/15
-- ==================================================

WITH team_matches AS (
    SELECT
        m.id AS match_id,
        m.date AS match_date,
        m.home_team_api_id AS team_api_id,
        CASE
            WHEN m.home_team_goal > m.away_team_goal THEN 3
            WHEN m.home_team_goal = m.away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM matches m
    JOIN league l ON m.league_id = l.id
    WHERE m.season = '2014/2015'
      AND l.name = 'England Premier League'
      AND m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        m.id AS match_id,
        m.date AS match_date,
        m.away_team_api_id AS team_api_id,
        CASE
            WHEN m.away_team_goal > m.home_team_goal THEN 3
            WHEN m.away_team_goal = m.home_team_goal THEN 1
            ELSE 0
        END AS points
    FROM matches m
    JOIN league l ON m.league_id = l.id
    WHERE m.season = '2014/2015'
      AND l.name = 'England Premier League'
      AND m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
),

ordered_matches AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY team_api_id
            ORDER BY match_date, match_id
        ) AS match_number,
        COUNT(*) OVER (
            PARTITION BY team_api_id
        ) AS total_matches
    FROM team_matches
),

team_form AS (
    SELECT
        team_api_id,
        COUNT(*) AS matches_played,

        ROUND(
            AVG(points) FILTER (
                WHERE match_number <= 10
            )::NUMERIC, 3
        ) AS first_10_ppm,

        ROUND(
            AVG(points) FILTER (
                WHERE match_number > total_matches - 10
            )::NUMERIC, 3
        ) AS last_10_ppm,

        ROUND(
            AVG(points) FILTER (
                WHERE match_number > total_matches - 10
            )::NUMERIC
            -
            AVG(points) FILTER (
                WHERE match_number <= 10
            )::NUMERIC,
            3
        ) AS momentum

    FROM ordered_matches
    GROUP BY team_api_id
    HAVING COUNT(*) = 38
)

SELECT
    RANK() OVER (
        ORDER BY f.momentum DESC
    ) AS momentum_rank,

    t.team_long_name AS team,
    f.first_10_ppm,
    f.last_10_ppm,
    f.momentum

FROM team_form f
JOIN team t
    ON f.team_api_id = t.team_api_id

ORDER BY momentum_rank, team;



-- ==================================================

-- #48. LEICESTER PARADOX
-- Does late-season momentum predict next-season growth?
-- ==================================================

WITH team_matches AS (
    SELECT
        m.id AS match_id,
        m.league_id,
        m.season,
        m.date AS match_date,
        m.home_team_api_id AS team_api_id,
        CASE
            WHEN m.home_team_goal > m.away_team_goal THEN 3
            WHEN m.home_team_goal = m.away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        m.league_id,
        m.season,
        m.date,
        m.away_team_api_id,
        CASE
            WHEN m.away_team_goal > m.home_team_goal THEN 3
            WHEN m.away_team_goal = m.home_team_goal THEN 1
            ELSE 0
        END
    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
),

ordered_matches AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY league_id, team_api_id, season
            ORDER BY match_date, match_id
        ) AS match_number,
        COUNT(*) OVER (
            PARTITION BY league_id, team_api_id, season
        ) AS season_matches
    FROM team_matches
),

season_form AS (
    SELECT
        league_id,
        team_api_id,
        season,
        LEFT(season, 4)::INTEGER AS season_year,
        COUNT(*) AS matches_played,
        AVG(points) AS season_ppm,

        AVG(points) FILTER (
            WHERE match_number <= 10
        ) AS first_10_ppm,

        AVG(points) FILTER (
            WHERE match_number > season_matches - 10
        ) AS last_10_ppm

    FROM ordered_matches
    GROUP BY league_id, team_api_id, season
    HAVING COUNT(*) >= 30
),

season_pairs AS (
    SELECT
        current_season.*,

        next_season.season_ppm AS next_ppm,

        next_season.season_ppm
            - current_season.season_ppm
            AS next_season_improvement,

        current_season.last_10_ppm
            - current_season.first_10_ppm
            AS momentum

    FROM season_form current_season

    JOIN season_form next_season
        ON current_season.team_api_id =
           next_season.team_api_id

       AND current_season.league_id =
           next_season.league_id

       AND next_season.season_year =
           current_season.season_year + 1
),

momentum_groups AS (
    SELECT
        *,
        NTILE(5) OVER (
            ORDER BY momentum, team_api_id, season_year
        ) AS momentum_quintile
    FROM season_pairs
)

SELECT
    momentum_quintile,

    COUNT(*) AS team_seasons,

    ROUND(
        AVG(momentum)::NUMERIC, 3
    ) AS avg_momentum,

    ROUND(
        AVG(next_season_improvement)::NUMERIC,
        3
    ) AS avg_next_season_ppm_change,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE next_season_improvement >= 0.5
        ) / COUNT(*),
        2
    ) AS major_improvement_rate_pct,

    ROUND(
        CORR(
            momentum,
            next_season_improvement
        )::NUMERIC,
        3
    ) AS within_group_correlation

FROM momentum_groups
GROUP BY momentum_quintile
ORDER BY momentum_quintile;



-- ==================================================

-- #49. LEICESTER PARADOX
-- Momentum vs baseline team performance
-- ==================================================

WITH team_matches AS (
    SELECT
        m.id AS match_id,
        m.league_id,
        m.season,
        m.date AS match_date,
        m.home_team_api_id AS team_api_id,
        CASE
            WHEN m.home_team_goal > m.away_team_goal THEN 3
            WHEN m.home_team_goal = m.away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        m.league_id,
        m.season,
        m.date,
        m.away_team_api_id,
        CASE
            WHEN m.away_team_goal > m.home_team_goal THEN 3
            WHEN m.away_team_goal = m.home_team_goal THEN 1
            ELSE 0
        END
    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
),

ordered_matches AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY league_id, team_api_id, season
            ORDER BY match_date, match_id
        ) AS match_number,

        COUNT(*) OVER (
            PARTITION BY league_id, team_api_id, season
        ) AS season_matches

    FROM team_matches
),

season_form AS (
    SELECT
        league_id,
        team_api_id,
        season,
        LEFT(season, 4)::INTEGER AS season_year,
        COUNT(*) AS matches_played,
        AVG(points) AS season_ppm,

        AVG(points) FILTER (
            WHERE match_number <= 10
        ) AS first_10_ppm,

        AVG(points) FILTER (
            WHERE match_number > season_matches - 10
        ) AS last_10_ppm

    FROM ordered_matches
    GROUP BY league_id, team_api_id, season
    HAVING COUNT(*) >= 30
),

season_pairs AS (
    SELECT
        a.league_id,
        a.team_api_id,
        a.season_year,
        a.season_ppm AS baseline_ppm,

        a.last_10_ppm - a.first_10_ppm
            AS momentum,

        b.season_ppm - a.season_ppm
            AS next_ppm_change

    FROM season_form a
    JOIN season_form b
        ON a.league_id = b.league_id
       AND a.team_api_id = b.team_api_id
       AND b.season_year = a.season_year + 1
),

classified AS (
    SELECT
        *,

        NTILE(3) OVER (
            ORDER BY baseline_ppm, team_api_id, season_year
        ) AS strength_group,

        NTILE(5) OVER (
            ORDER BY momentum, team_api_id, season_year
        ) AS momentum_group

    FROM season_pairs
)

SELECT
    CASE strength_group
        WHEN 1 THEN 'Weak baseline'
        WHEN 2 THEN 'Mid-table baseline'
        WHEN 3 THEN 'Strong baseline'
    END AS baseline_strength,

    CASE
        WHEN momentum_group = 5 THEN 'High momentum'
        WHEN momentum_group = 1 THEN 'Low momentum'
    END AS momentum_level,

    COUNT(*) AS team_seasons,

    ROUND(AVG(baseline_ppm)::NUMERIC, 3)
        AS avg_baseline_ppm,

    ROUND(AVG(momentum)::NUMERIC, 3)
        AS avg_momentum,

    ROUND(AVG(next_ppm_change)::NUMERIC, 3)
        AS avg_next_ppm_change,

    COUNT(*) FILTER (
        WHERE next_ppm_change >= 0.5
    ) AS major_breakthroughs,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE next_ppm_change >= 0.5
        ) / COUNT(*),
        2
    ) AS breakthrough_rate_pct

FROM classified
WHERE momentum_group IN (1, 5)

GROUP BY strength_group, momentum_group

ORDER BY strength_group, momentum_group DESC;




-- ==================================================

-- #50. LEICESTER PARADOX
-- Out-of-time momentum validation
-- ==================================================

WITH team_matches AS (
    SELECT
        m.id AS match_id,
        m.league_id,
        m.season,
        m.date AS match_date,
        m.home_team_api_id AS team_api_id,
        CASE
            WHEN m.home_team_goal > m.away_team_goal THEN 3
            WHEN m.home_team_goal = m.away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        m.league_id,
        m.season,
        m.date,
        m.away_team_api_id,
        CASE
            WHEN m.away_team_goal > m.home_team_goal THEN 3
            WHEN m.away_team_goal = m.home_team_goal THEN 1
            ELSE 0
        END
    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
),

ordered_matches AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY league_id, team_api_id, season
            ORDER BY match_date, match_id
        ) AS match_number,

        COUNT(*) OVER (
            PARTITION BY league_id, team_api_id, season
        ) AS season_matches

    FROM team_matches
),

season_form AS (
    SELECT
        league_id,
        team_api_id,
        season,
        LEFT(season, 4)::INTEGER AS season_year,
        COUNT(*) AS matches_played,
        AVG(points) AS season_ppm,

        AVG(points) FILTER (
            WHERE match_number <= 10
        ) AS first_10_ppm,

        AVG(points) FILTER (
            WHERE match_number > season_matches - 10
        ) AS last_10_ppm

    FROM ordered_matches
    GROUP BY league_id, team_api_id, season
    HAVING COUNT(*) >= 30
),

season_pairs AS (
    SELECT
        a.team_api_id,
        a.season_year,
        a.season_ppm AS baseline_ppm,

        a.last_10_ppm - a.first_10_ppm
            AS momentum,

        b.season_ppm - a.season_ppm
            AS next_ppm_change

    FROM season_form a
    JOIN season_form b
        ON a.league_id = b.league_id
       AND a.team_api_id = b.team_api_id
       AND b.season_year = a.season_year + 1
),

classified AS (
    SELECT
        CASE
            WHEN season_year < 2014
                THEN 'Historical'
            WHEN season_year = 2014
                THEN 'Test 2014/15'
        END AS dataset,

        CASE
            WHEN momentum >= 0.5
                THEN 'High momentum'
            WHEN momentum <= -0.5
                THEN 'Low momentum'
        END AS momentum_group,

        next_ppm_change

    FROM season_pairs
    WHERE season_year <= 2014
      AND baseline_ppm < 1.5
)

SELECT
    dataset,
    momentum_group,

    COUNT(*) AS team_seasons,

    COUNT(*) FILTER (
        WHERE next_ppm_change >= 0.5
    ) AS breakthroughs,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE next_ppm_change >= 0.5
        ) / COUNT(*),
        2
    ) AS breakthrough_rate_pct,

    ROUND(
        AVG(next_ppm_change)::NUMERIC,
        3
    ) AS avg_next_ppm_change

FROM classified

WHERE dataset IS NOT NULL
  AND momentum_group IS NOT NULL

GROUP BY dataset, momentum_group
ORDER BY dataset, momentum_group;



-- ==================================================

-- #51. LEICESTER PARADOX
-- Pre-season breakthrough candidate ranking
-- Prediction date: before 2015/16
-- ==================================================

WITH team_matches AS (
    SELECT
        m.id AS match_id,
        m.league_id,
        m.season,
        m.date AS match_date,
        m.home_team_api_id AS team_api_id,
        CASE
            WHEN m.home_team_goal > m.away_team_goal THEN 3
            WHEN m.home_team_goal = m.away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        m.league_id,
        m.season,
        m.date,
        m.away_team_api_id,
        CASE
            WHEN m.away_team_goal > m.home_team_goal THEN 3
            WHEN m.away_team_goal = m.home_team_goal THEN 1
            ELSE 0
        END
    FROM matches m
    WHERE m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
),

ordered_matches AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY league_id, team_api_id, season
            ORDER BY match_date, match_id
        ) AS match_number,

        COUNT(*) OVER (
            PARTITION BY league_id, team_api_id, season
        ) AS season_matches
    FROM team_matches
),

season_form AS (
    SELECT
        league_id,
        team_api_id,
        season,
        COUNT(*) AS matches_played,
        ROUND(AVG(points)::NUMERIC, 3) AS season_ppm,

        ROUND(
            (
                AVG(points) FILTER (
                    WHERE match_number > season_matches - 10
                )
                -
                AVG(points) FILTER (
                    WHERE match_number <= 10
                )
            )::NUMERIC, 3
        ) AS momentum

    FROM ordered_matches
    GROUP BY league_id, team_api_id, season
    HAVING COUNT(*) >= 30
),

candidates AS (
    SELECT
        a.league_id,
        a.team_api_id,
        a.season_ppm AS baseline_ppm,
        a.momentum,
        b.season_ppm AS next_ppm,

        ROUND(
            b.season_ppm - a.season_ppm, 3
        ) AS next_ppm_change

    FROM season_form a
    JOIN season_form b
        ON a.league_id = b.league_id
       AND a.team_api_id = b.team_api_id
       AND b.season = '2015/2016'

    WHERE a.season = '2014/2015'
      AND a.season_ppm < 1.5
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY c.momentum DESC, c.team_api_id
    ) AS momentum_rank,

    t.team_long_name AS team,
    l.name AS league,

    c.baseline_ppm,
    c.momentum,
    c.next_ppm,
    c.next_ppm_change,

    CASE
        WHEN c.next_ppm_change >= 0.5
            THEN 'BREAKTHROUGH'
        ELSE 'NO'
    END AS actual_outcome

FROM candidates c
JOIN team t ON c.team_api_id = t.team_api_id
JOIN league l ON c.league_id = l.id

ORDER BY momentum_rank;


-- ==================================================

-- #52. LEICESTER PARADOX
-- Leakage-free preseason candidate ranking
-- All 2014/15 incumbent teams
-- ==================================================

WITH team_matches AS (
    SELECT
        m.id AS match_id,
        m.league_id,
        m.season,
        m.date AS match_date,
        m.home_team_api_id AS team_api_id,
        CASE
            WHEN m.home_team_goal > m.away_team_goal THEN 3
            WHEN m.home_team_goal = m.away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM matches m
    WHERE m.season IN ('2014/2015', '2015/2016')
      AND m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        m.league_id,
        m.season,
        m.date,
        m.away_team_api_id,
        CASE
            WHEN m.away_team_goal > m.home_team_goal THEN 3
            WHEN m.away_team_goal = m.home_team_goal THEN 1
            ELSE 0
        END
    FROM matches m
    WHERE m.season IN ('2014/2015', '2015/2016')
      AND m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
),

ordered_matches AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY league_id, season, team_api_id
            ORDER BY match_date, match_id
        ) AS match_number,
        COUNT(*) OVER (
            PARTITION BY league_id, season, team_api_id
        ) AS season_matches
    FROM team_matches
),

season_form AS (
    SELECT
        league_id,
        team_api_id,
        season,
        COUNT(*) AS matches_played,
        AVG(points) AS season_ppm,
        AVG(points) FILTER (
            WHERE match_number > season_matches - 10
        ) -
        AVG(points) FILTER (
            WHERE match_number <= 10
        ) AS momentum
    FROM ordered_matches
    GROUP BY league_id, team_api_id, season
    HAVING COUNT(*) >= 30
),

preseason_candidates AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY momentum DESC, team_api_id
        ) AS preseason_rank
    FROM season_form
    WHERE season = '2014/2015'
      AND season_ppm < 1.5
),

evaluated AS (
    SELECT
        a.preseason_rank,
        a.team_api_id,
        a.league_id,
        a.season_ppm AS baseline_ppm,
        a.momentum,
        b.season_ppm AS next_ppm,
        b.season_ppm - a.season_ppm
            AS next_ppm_change,
        CASE
            WHEN b.team_api_id IS NULL
                THEN 'NO NEXT TOP-FLIGHT SEASON'
            WHEN b.season_ppm - a.season_ppm >= 0.5
                THEN 'BREAKTHROUGH'
            ELSE 'NO'
        END AS outcome
    FROM preseason_candidates a
    LEFT JOIN season_form b
        ON a.league_id = b.league_id
       AND a.team_api_id = b.team_api_id
       AND b.season = '2015/2016'
)

SELECT
    e.preseason_rank,
    t.team_long_name AS team,
    l.name AS league,
    ROUND(e.baseline_ppm::NUMERIC, 3)
        AS baseline_ppm,
    ROUND(e.momentum::NUMERIC, 3)
        AS momentum,
    ROUND(e.next_ppm_change::NUMERIC, 3)
        AS next_ppm_change,
    e.outcome
FROM evaluated e
JOIN team t
    ON e.team_api_id = t.team_api_id
JOIN league l
    ON e.league_id = l.id
ORDER BY e.preseason_rank;''


-- ==================================================

-- #53. LEICESTER PARADOX
-- Baseline PPM vs late-season momentum
-- Retrospective ranking comparison, 2015/16
-- ==================================================

WITH team_matches AS (
    SELECT
        m.id AS match_id,
        m.league_id,
        m.season,
        m.date AS match_date,
        m.home_team_api_id AS team_api_id,
        CASE
            WHEN m.home_team_goal > m.away_team_goal THEN 3
            WHEN m.home_team_goal = m.away_team_goal THEN 1
            ELSE 0
        END AS points
    FROM matches m
    WHERE m.season IN ('2014/2015', '2015/2016')
      AND m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL

    UNION ALL

    SELECT
        m.id, m.league_id, m.season, m.date,
        m.away_team_api_id,
        CASE
            WHEN m.away_team_goal > m.home_team_goal THEN 3
            WHEN m.away_team_goal = m.home_team_goal THEN 1
            ELSE 0
        END
    FROM matches m
    WHERE m.season IN ('2014/2015', '2015/2016')
      AND m.home_team_goal IS NOT NULL
      AND m.away_team_goal IS NOT NULL
),

ordered AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY league_id, season, team_api_id
            ORDER BY match_date, match_id
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY league_id, season, team_api_id
        ) AS n
    FROM team_matches
),

season_stats AS (
    SELECT
        league_id,
        team_api_id,
        season,
        AVG(points) AS ppm,
        AVG(points) FILTER (WHERE rn > n - 10)
        -
        AVG(points) FILTER (WHERE rn <= 10)
            AS momentum
    FROM ordered
    GROUP BY league_id, team_api_id, season
    HAVING COUNT(*) >= 30
),

candidates AS (
    SELECT
        a.team_api_id,
        a.ppm AS baseline_ppm,
        a.momentum,
        b.ppm - a.ppm AS improvement,

        CASE
            WHEN b.ppm - a.ppm >= 0.5 THEN 1
            ELSE 0
        END AS breakthrough

    FROM season_stats a
    JOIN season_stats b
        ON a.league_id = b.league_id
       AND a.team_api_id = b.team_api_id
       AND b.season = '2015/2016'

    WHERE a.season = '2014/2015'
      AND a.ppm < 1.5
),

rankings AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY baseline_ppm DESC, team_api_id
        ) AS baseline_rank,

        ROW_NUMBER() OVER (
            ORDER BY momentum DESC, team_api_id
        ) AS momentum_rank

    FROM candidates
),

model_results AS (
    SELECT
        'Baseline PPM' AS model,
        baseline_rank AS prediction_rank,
        breakthrough
    FROM rankings

    UNION ALL

    SELECT
        'Momentum',
        momentum_rank,
        breakthrough
    FROM rankings
)

SELECT
    model,
    COUNT(*) AS evaluated_teams,

    SUM(breakthrough) AS total_breakthroughs,

    SUM(breakthrough) FILTER (
        WHERE prediction_rank <= 10
    ) AS breakthroughs_top10,

    ROUND(
        100.0 * SUM(breakthrough) FILTER (
            WHERE prediction_rank <= 10
        ) / 10,
        2
    ) AS precision_at_10_pct,

    ROUND(
        100.0 * SUM(breakthrough) FILTER (
            WHERE prediction_rank <= 10
        ) / NULLIF(SUM(breakthrough), 0),
        2
    ) AS recall_at_10_pct

FROM model_results
GROUP BY model
ORDER BY model;

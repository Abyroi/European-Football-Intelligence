
-- ==================================================
-- FOOTBALL PERFORMANCE ANALYTICS
-- Database Validation and Primary Key Setup
-- ==================================================

-- 1. DATA OVERVIEW
-- Verify the number of records in each table.

SELECT 'country' AS table_name, COUNT(*) AS total_rows
FROM country
UNION ALL
SELECT 'league', COUNT(*) FROM league
UNION ALL
SELECT 'team', COUNT(*) FROM team
UNION ALL
SELECT 'player', COUNT(*) FROM player
UNION ALL
SELECT 'matches', COUNT(*) FROM matches
UNION ALL
SELECT 'player_attributes', COUNT(*) FROM player_attributes
UNION ALL
SELECT 'team_attributes', COUNT(*) FROM team_attributes;


-- 2. DATA QUALITY CHECK
-- Check for duplicate or missing IDs.

WITH all_ids AS (
    SELECT 'country' AS table_name,
           COUNT(*) AS total_rows,
           COUNT(DISTINCT id) AS unique_ids
    FROM country

    UNION ALL
    SELECT 'league', COUNT(*), COUNT(DISTINCT id)
    FROM league

    UNION ALL
    SELECT 'team', COUNT(*), COUNT(DISTINCT id)
    FROM team

    UNION ALL
    SELECT 'player', COUNT(*), COUNT(DISTINCT id)
    FROM player

    UNION ALL
    SELECT 'matches', COUNT(*), COUNT(DISTINCT id)
    FROM matches

    UNION ALL
    SELECT 'player_attributes', COUNT(*), COUNT(DISTINCT id)
    FROM player_attributes

    UNION ALL
    SELECT 'team_attributes', COUNT(*), COUNT(DISTINCT id)
    FROM team_attributes
)
SELECT
    table_name,
    total_rows,
    unique_ids,
    total_rows - unique_ids AS invalid_ids
FROM all_ids
ORDER BY table_name;


-- 3. PRIMARY KEY SETUP
-- Establish unique identifiers for all tables.
-- Run only once, after importing the data.

ALTER TABLE country
ADD CONSTRAINT pk_country PRIMARY KEY (id);

ALTER TABLE league
ADD CONSTRAINT pk_league PRIMARY KEY (id);

ALTER TABLE team
ADD CONSTRAINT pk_team PRIMARY KEY (id);

ALTER TABLE player
ADD CONSTRAINT pk_player PRIMARY KEY (id);

ALTER TABLE matches
ADD CONSTRAINT pk_matches PRIMARY KEY (id);

ALTER TABLE player_attributes
ADD CONSTRAINT pk_player_attributes PRIMARY KEY (id);

ALTER TABLE team_attributes
ADD CONSTRAINT pk_team_attributes PRIMARY KEY (id);


-- 4. CONSTRAINT VALIDATION
-- Verify that all primary keys were created.

SELECT
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public'
  AND constraint_type = 'PRIMARY KEY'
ORDER BY table_name;



-- ==================================================
-- 5. FOREIGN KEY VALIDATION
-- Check relationships before creating constraints
-- ==================================================

SELECT
    'League -> Country' AS relationship,
    COUNT(*) AS invalid_references
FROM league l
LEFT JOIN country c
    ON l.country_id = c.id
WHERE l.country_id IS NOT NULL
  AND c.id IS NULL

UNION ALL

SELECT
    'Matches -> League',
    COUNT(*)
FROM matches m
LEFT JOIN league l
    ON m.league_id = l.id
WHERE m.league_id IS NOT NULL
  AND l.id IS NULL

UNION ALL

SELECT
    'Matches -> Home Team',
    COUNT(*)
FROM matches m
LEFT JOIN team t
    ON m.home_team_api_id = t.team_api_id
WHERE m.home_team_api_id IS NOT NULL
  AND t.team_api_id IS NULL

UNION ALL

SELECT
    'Matches -> Away Team',
    COUNT(*)
FROM matches m
LEFT JOIN team t
    ON m.away_team_api_id = t.team_api_id
WHERE m.away_team_api_id IS NOT NULL
  AND t.team_api_id IS NULL

UNION ALL

SELECT
    'Player Attributes -> Player',
    COUNT(*)
FROM player_attributes pa
LEFT JOIN player p
    ON pa.player_api_id = p.player_api_id
WHERE pa.player_api_id IS NOT NULL
  AND p.player_api_id IS NULL

UNION ALL

SELECT
    'Team Attributes -> Team',
    COUNT(*)
FROM team_attributes ta
LEFT JOIN team t
    ON ta.team_api_id = t.team_api_id
WHERE ta.team_api_id IS NOT NULL
  AND t.team_api_id IS NULL;


-- ==================================================
-- 6. FOREIGN KEY READINESS CHECK
-- Verify uniqueness of referenced identifiers
-- ==================================================

SELECT
    'player' AS table_name,
    'player_api_id' AS column_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT player_api_id) AS unique_ids,
    COUNT(*) - COUNT(DISTINCT player_api_id) AS invalid_ids
FROM player

UNION ALL

SELECT
    'team',
    'team_api_id',
    COUNT(*),
    COUNT(DISTINCT team_api_id),
    COUNT(*) - COUNT(DISTINCT team_api_id)
FROM team;



-- ==================================================
-- 7. UNIQUE CONSTRAINTS
-- Ensure API identifiers can be referenced
-- ==================================================

ALTER TABLE player
ADD CONSTRAINT uq_player_api_id
UNIQUE (player_api_id);

ALTER TABLE team
ADD CONSTRAINT uq_team_api_id
UNIQUE (team_api_id);


-- ==================================================
-- 8. FOREIGN KEY CONSTRAINTS
-- Establish relationships between tables
-- ==================================================

-- League belongs to a country
ALTER TABLE league
ADD CONSTRAINT fk_league_country
FOREIGN KEY (country_id)
REFERENCES country(id);

-- Match belongs to a league
ALTER TABLE matches
ADD CONSTRAINT fk_matches_league
FOREIGN KEY (league_id)
REFERENCES league(id);

-- Match has a home team
ALTER TABLE matches
ADD CONSTRAINT fk_matches_home_team
FOREIGN KEY (home_team_api_id)
REFERENCES team(team_api_id);

-- Match has an away team
ALTER TABLE matches
ADD CONSTRAINT fk_matches_away_team
FOREIGN KEY (away_team_api_id)
REFERENCES team(team_api_id);

-- Player attributes belong to a player
ALTER TABLE player_attributes
ADD CONSTRAINT fk_player_attributes_player
FOREIGN KEY (player_api_id)
REFERENCES player(player_api_id);

-- Team attributes belong to a team
ALTER TABLE team_attributes
ADD CONSTRAINT fk_team_attributes_team
FOREIGN KEY (team_api_id)
REFERENCES team(team_api_id);



-- Add a unique constraint for team API identifiers

ALTER TABLE team
ADD CONSTRAINT uq_team_api_id
UNIQUE (team_api_id);


SELECT
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.team'::regclass
ORDER BY conname;



-- Ensure player API identifiers are unique

ALTER TABLE player
ADD CONSTRAINT uq_player_api_id
UNIQUE (player_api_id);


-- ==================================================
-- FOREIGN KEY CONSTRAINTS
-- Connect related tables
-- ==================================================

ALTER TABLE league
ADD CONSTRAINT fk_league_country
FOREIGN KEY (country_id)
REFERENCES country(id);

ALTER TABLE matches
ADD CONSTRAINT fk_matches_league
FOREIGN KEY (league_id)
REFERENCES league(id);

ALTER TABLE matches
ADD CONSTRAINT fk_matches_home_team
FOREIGN KEY (home_team_api_id)
REFERENCES team(team_api_id);

ALTER TABLE matches
ADD CONSTRAINT fk_matches_away_team
FOREIGN KEY (away_team_api_id)
REFERENCES team(team_api_id);

ALTER TABLE player_attributes
ADD CONSTRAINT fk_player_attributes_player
FOREIGN KEY (player_api_id)
REFERENCES player(player_api_id);

ALTER TABLE team_attributes
ADD CONSTRAINT fk_team_attributes_team
FOREIGN KEY (team_api_id)
REFERENCES team(team_api_id);


SELECT
    conrelid::regclass AS table_name,
    conname AS foreign_key,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE contype = 'f'
  AND connamespace = 'public'::regnamespace
ORDER BY table_name, foreign_key;



-- ==================================================
-- 11. FOOTBALL ANALYTICS
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
-- 12. TEAM PERFORMANCE ANALYSIS
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
-- 13. DATA TYPE AUDIT
-- Inspect column types before advanced analysis
-- ==================================================

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (
      column_name = 'date'
      OR column_name = 'birthday'
      OR column_name = 'season'
      OR column_name IN (
          'home_team_goal',
          'away_team_goal',
          'overall_rating',
          'potential'
      )
  )
ORDER BY table_name, column_name;




-- ==================================================
-- 14. DATE FORMAT VALIDATION
-- Inspect date values before type conversion
-- ==================================================

SELECT
    'matches' AS table_name,
    MIN(date) AS earliest_value,
    MAX(date) AS latest_value,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE date IS NULL OR TRIM(date) = ''
    ) AS missing_dates
FROM matches

UNION ALL

SELECT
    'player',
    MIN(birthday),
    MAX(birthday),
    COUNT(*),
    COUNT(*) FILTER (
        WHERE birthday IS NULL OR TRIM(birthday) = ''
    )
FROM player

UNION ALL

SELECT
    'player_attributes',
    MIN(date),
    MAX(date),
    COUNT(*),
    COUNT(*) FILTER (
        WHERE date IS NULL OR TRIM(date) = ''
    )
FROM player_attributes

UNION ALL

SELECT
    'team_attributes',
    MIN(date),
    MAX(date),
    COUNT(*),
    COUNT(*) FILTER (
        WHERE date IS NULL OR TRIM(date) = ''
    )
FROM team_attributes;



-- ==================================================
-- 15. DATE FORMAT QUALITY CHECK
-- Validate date strings before conversion
-- ==================================================

WITH all_dates AS (
    SELECT 'matches' AS table_name, date AS date_value
    FROM matches

    UNION ALL
    SELECT 'player', birthday
    FROM player

    UNION ALL
    SELECT 'player_attributes', date
    FROM player_attributes

    UNION ALL
    SELECT 'team_attributes', date
    FROM team_attributes
)
SELECT
    table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE date_value !~
        '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'
    ) AS invalid_format
FROM all_dates
GROUP BY table_name
ORDER BY table_name;



-- ==================================================
-- 16. DATE CONVERSION VALIDATION
-- Check whether all dates can be converted
-- ==================================================

WITH all_dates AS (
    SELECT 'matches' AS table_name, date AS date_value
    FROM matches

    UNION ALL
    SELECT 'player', birthday
    FROM player

    UNION ALL
    SELECT 'player_attributes', date
    FROM player_attributes

    UNION ALL
    SELECT 'team_attributes', date
    FROM team_attributes
)
SELECT
    table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE pg_input_is_valid(
            date_value, 'timestamp without time zone'
        ) = FALSE
    ) AS invalid_dates
FROM all_dates
GROUP BY table_name
ORDER BY table_name;


-- ==================================================
-- 17. DATA TYPE OPTIMIZATION
-- Convert text dates into PostgreSQL timestamps
-- ==================================================

BEGIN;

ALTER TABLE matches
ALTER COLUMN date TYPE TIMESTAMP
USING date::TIMESTAMP;

ALTER TABLE player
ALTER COLUMN birthday TYPE TIMESTAMP
USING birthday::TIMESTAMP;

ALTER TABLE player_attributes
ALTER COLUMN date TYPE TIMESTAMP
USING date::TIMESTAMP;

ALTER TABLE team_attributes
ALTER COLUMN date TYPE TIMESTAMP
USING date::TIMESTAMP;

COMMIT;


-- ==================================================
-- 18. DATA TYPE VERIFICATION
-- Confirm successful timestamp conversion
-- ==================================================

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (
      (table_name = 'matches' AND column_name = 'date')
      OR (table_name = 'player' AND column_name = 'birthday')
      OR (table_name = 'player_attributes' AND column_name = 'date')
      OR (table_name = 'team_attributes' AND column_name = 'date')
  )
ORDER BY table_name;



-- ==================================================
-- 19. HOME ADVANTAGE ANALYSIS
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
-- 20. HOME ADVANTAGE TREND ANALYSIS
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
-- 21. LEAGUE-LEVEL HOME ADVANTAGE TRENDS
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
-- 22. HOME ADVANTAGE TREND REGRESSION
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
-- 23. TEAM DOMINANCE AND CONSISTENCY
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
-- 24. SEASONAL LEAGUE LEADERS
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
-- 25. DATA QUALITY: SEASON COMPLETENESS
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
-- 26. AUTOMATED SEASON COMPLETENESS CHECK
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
-- 27. TEAM-LEVEL SEASON COMPLETENESS
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
-- 28. TEAM DOMINANCE: LEAGUE LEADERS
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
-- 29. TEAM PERFORMANCE EVOLUTION
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
-- 30. VALIDATED SEASON-OVER-SEASON IMPROVEMENT
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
-- 31. PLAYER DEVELOPMENT AND PEAK PERFORMANCE
-- Average FIFA overall rating by player age
-- ==================================================

WITH player_age_ratings AS (
    SELECT
        p.player_api_id,
        p.player_name,
        EXTRACT(
            YEAR FROM AGE(pa.date, p.birthday)
        )::INTEGER AS player_age,
        pa.overall_rating
    FROM player_attributes pa
    JOIN player p
        ON pa.player_api_id = p.player_api_id
    WHERE pa.overall_rating IS NOT NULL
      AND pa.date IS NOT NULL
      AND p.birthday IS NOT NULL
),

player_age_average AS (
    SELECT
        player_api_id,
        player_age,
        AVG(overall_rating) AS avg_rating
    FROM player_age_ratings
    WHERE player_age BETWEEN 16 AND 40
    GROUP BY player_api_id, player_age
)

SELECT
    player_age AS age,
    COUNT(*) AS players,
    ROUND(
        AVG(avg_rating)::NUMERIC,
        2
    ) AS average_rating,
    ROUND(
        STDDEV_SAMP(avg_rating)::NUMERIC,
        2
    ) AS rating_stddev
FROM player_age_average
GROUP BY player_age
ORDER BY player_age;



-- ==================================================
-- 32. INDIVIDUAL PLAYER PEAK AGE
-- Identify the highest-rated age for each player
-- ==================================================

WITH player_age_ratings AS (
    SELECT
        p.player_api_id,
        p.player_name,
        EXTRACT(
            YEAR FROM AGE(pa.date, p.birthday)
        )::INTEGER AS player_age,
        pa.overall_rating
    FROM player_attributes pa
    JOIN player p
        ON pa.player_api_id = p.player_api_id
    WHERE pa.overall_rating IS NOT NULL
      AND pa.date IS NOT NULL
      AND p.birthday IS NOT NULL
),

age_performance AS (
    SELECT
        player_api_id,
        player_name,
        player_age,
        COUNT(*) AS observations,
        AVG(overall_rating) AS avg_rating
    FROM player_age_ratings
    WHERE player_age BETWEEN 16 AND 40
    GROUP BY
        player_api_id,
        player_name,
        player_age
),

eligible_players AS (
    SELECT player_api_id
    FROM age_performance
    GROUP BY player_api_id
    HAVING COUNT(*) >= 4
),

ranked_peaks AS (
    SELECT
        ap.*,
        ROW_NUMBER() OVER (
            PARTITION BY ap.player_api_id
            ORDER BY ap.avg_rating DESC,
                     ap.player_age ASC
        ) AS peak_rank
    FROM age_performance ap
    JOIN eligible_players ep
        ON ap.player_api_id = ep.player_api_id
)

SELECT
    player_age AS peak_age,
    COUNT(*) AS players,
    ROUND(
        AVG(avg_rating)::NUMERIC,
        2
    ) AS average_peak_rating
FROM ranked_peaks
WHERE peak_rank = 1
GROUP BY player_age
ORDER BY players DESC, peak_age
LIMIT 15;



-- ==================================================
-- 33. BIGGEST YEAR-OVER-YEAR PLAYER IMPROVEMENTS
-- Compare average ratings in consecutive years
-- ==================================================

WITH yearly_ratings AS (
    SELECT
        p.player_api_id,
        p.player_name,
        EXTRACT(YEAR FROM pa.date)::INTEGER
            AS rating_year,
        ROUND(
            AVG(pa.overall_rating)::NUMERIC,
            2
        ) AS avg_rating,
        COUNT(*) AS observations
    FROM player_attributes pa
    JOIN player p
        ON pa.player_api_id = p.player_api_id
    WHERE pa.overall_rating IS NOT NULL
      AND pa.date IS NOT NULL
    GROUP BY
        p.player_api_id,
        p.player_name,
        EXTRACT(YEAR FROM pa.date)
),

rating_changes AS (
    SELECT
        *,
        LAG(rating_year) OVER (
            PARTITION BY player_api_id
            ORDER BY rating_year
        ) AS previous_year,
        LAG(avg_rating) OVER (
            PARTITION BY player_api_id
            ORDER BY rating_year
        ) AS previous_rating,
        LAG(observations) OVER (
            PARTITION BY player_api_id
            ORDER BY rating_year
        ) AS previous_observations
    FROM yearly_ratings
)

SELECT
    player_name,
    rating_year,
    previous_rating,
    avg_rating AS current_rating,
    ROUND(
        avg_rating - previous_rating,
        2
    ) AS rating_improvement,
    previous_observations,
    observations AS current_observations
FROM rating_changes
WHERE previous_year = rating_year - 1
  AND previous_observations >= 2
  AND observations >= 2
ORDER BY
    rating_improvement DESC,
    player_name
LIMIT 20;


-- ==================================================
-- 34. PLAYER RATING DATA COVERAGE
-- Check how many yearly player records
-- have enough observations for robust comparisons
-- ==================================================

WITH yearly_ratings AS (
    SELECT
        pa.player_api_id,
        EXTRACT(YEAR FROM pa.date)::INTEGER AS rating_year,
        COUNT(*) AS observations
    FROM player_attributes pa
    WHERE pa.overall_rating IS NOT NULL
      AND pa.date IS NOT NULL
    GROUP BY
        pa.player_api_id,
        EXTRACT(YEAR FROM pa.date)
)

SELECT
    rating_year,
    COUNT(*) AS players,
    ROUND(
        AVG(observations)::NUMERIC,
        2
    ) AS avg_observations,
    COUNT(*) FILTER (
        WHERE observations >= 2
    ) AS players_with_2plus,
    COUNT(*) FILTER (
        WHERE observations >= 4
    ) AS players_with_4plus,
    MAX(observations) AS max_observations
FROM yearly_ratings
GROUP BY rating_year
ORDER BY rating_year;



-- ==================================================
-- 35. MESSI VS RONALDO: FIFA RATING RIVALRY
-- Compare yearly ratings of two football legends
-- ==================================================

WITH yearly_ratings AS (
    SELECT
        p.player_name,
        EXTRACT(YEAR FROM pa.date)::INTEGER
            AS rating_year,
        ROUND(
            AVG(pa.overall_rating)::NUMERIC, 2
        ) AS avg_rating,
        MAX(pa.overall_rating) AS max_rating,
        MIN(pa.overall_rating) AS min_rating,
        COUNT(*) AS observations
    FROM player_attributes pa
    JOIN player p
        ON pa.player_api_id = p.player_api_id
    WHERE p.player_name IN (
        'Lionel Messi',
        'Cristiano Ronaldo'
    )
      AND pa.overall_rating IS NOT NULL
    GROUP BY
        p.player_name,
        EXTRACT(YEAR FROM pa.date)
)

SELECT
    rating_year,
    MAX(avg_rating) FILTER (
        WHERE player_name = 'Lionel Messi'
    ) AS messi_rating,
    MAX(avg_rating) FILTER (
        WHERE player_name = 'Cristiano Ronaldo'
    ) AS ronaldo_rating,
    ROUND(
        MAX(avg_rating) FILTER (
            WHERE player_name = 'Lionel Messi'
        )
        -
        MAX(avg_rating) FILTER (
            WHERE player_name = 'Cristiano Ronaldo'
        ),
        2
    ) AS rating_difference,
    CASE
        WHEN MAX(avg_rating) FILTER (
            WHERE player_name = 'Lionel Messi'
        )
        >
        MAX(avg_rating) FILTER (
            WHERE player_name = 'Cristiano Ronaldo'
        )
        THEN 'Messi'
        WHEN MAX(avg_rating) FILTER (
            WHERE player_name = 'Lionel Messi'
        )
        <
        MAX(avg_rating) FILTER (
            WHERE player_name = 'Cristiano Ronaldo'
        )
        THEN 'Ronaldo'
        ELSE 'Tie / Missing data'
    END AS yearly_leader
FROM yearly_ratings
GROUP BY rating_year
ORDER BY rating_year;



-- ==================================================
-- 36. FUTURE SUPERSTARS
-- Youngest players to reach FIFA rating 85+
-- ==================================================

WITH elite_ratings AS (
    SELECT
        p.player_api_id,
        p.player_name,
        pa.date AS rating_date,
        pa.overall_rating,
        EXTRACT(
            YEAR FROM AGE(pa.date, p.birthday)
        )::INTEGER AS player_age,
        ROW_NUMBER() OVER (
            PARTITION BY p.player_api_id
            ORDER BY pa.date ASC, pa.id ASC
        ) AS first_elite_rank
    FROM player p
    JOIN player_attributes pa
        ON p.player_api_id = pa.player_api_id
    WHERE pa.overall_rating >= 85
      AND pa.date IS NOT NULL
      AND p.birthday IS NOT NULL
)

SELECT
    player_name,
    player_age AS age_at_first_85,
    rating_date::DATE AS first_elite_date,
    overall_rating AS first_elite_rating
FROM elite_ratings
WHERE first_elite_rank = 1
  AND player_age BETWEEN 16 AND 30
ORDER BY
    age_at_first_85 ASC,
    first_elite_date ASC
LIMIT 20;



-- ==================================================
-- 37. FALLEN STARS: FIFA RATING DECLINE
-- Largest observed decline after reaching 85+
-- ==================================================

WITH player_history AS (
    SELECT
        p.player_api_id,
        p.player_name,
        pa.date AS rating_date,
        pa.overall_rating,
        MAX(pa.overall_rating) OVER (
            PARTITION BY p.player_api_id
            ORDER BY pa.date, pa.id
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND 1 PRECEDING
        ) AS previous_peak
    FROM player p
    JOIN player_attributes pa
        ON p.player_api_id = pa.player_api_id
    WHERE pa.overall_rating IS NOT NULL
      AND pa.date IS NOT NULL
),

declines AS (
    SELECT
        *,
        previous_peak - overall_rating AS rating_drop
    FROM player_history
    WHERE previous_peak >= 85
      AND previous_peak > overall_rating
),

ranked_declines AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY player_api_id
            ORDER BY rating_drop DESC,
                     rating_date ASC
        ) AS decline_rank
    FROM declines
)

SELECT
    player_name,
    previous_peak AS peak_rating,
    overall_rating AS later_rating,
    rating_drop,
    rating_date::DATE AS decline_date
FROM ranked_declines
WHERE decline_rank = 1
ORDER BY rating_drop DESC, player_name
LIMIT 20;



-- ==================================================
-- 38. FIFA RATING COMEBACKS
-- Players who recovered after a rating decline
-- ==================================================

WITH rating_history AS (
    SELECT
        p.player_api_id,
        p.player_name,
        pa.id AS attribute_id,
        pa.date AS rating_date,
        pa.overall_rating,

        MAX(pa.overall_rating) OVER (
            PARTITION BY p.player_api_id
            ORDER BY pa.date, pa.id
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND 1 PRECEDING
        ) AS previous_peak

    FROM player p
    JOIN player_attributes pa
        ON p.player_api_id = pa.player_api_id
    WHERE pa.overall_rating IS NOT NULL
      AND pa.date IS NOT NULL
),

rating_drops AS (
    SELECT
        player_api_id,
        player_name,
        attribute_id,
        rating_date AS drop_date,
        overall_rating AS low_rating,
        previous_peak AS peak_rating

    FROM rating_history
    WHERE previous_peak >= 80
      AND previous_peak - overall_rating >= 5
),

recoveries AS (
    SELECT
        d.player_api_id,
        d.player_name,
        d.peak_rating,
        d.low_rating,
        d.drop_date,
        MAX(pa.overall_rating) AS recovered_rating

    FROM rating_drops d
    JOIN player_attributes pa
        ON d.player_api_id = pa.player_api_id
       AND (
           pa.date > d.drop_date
           OR (
               pa.date = d.drop_date
               AND pa.id > d.attribute_id
           )
       )
    WHERE pa.overall_rating IS NOT NULL

    GROUP BY
        d.player_api_id,
        d.player_name,
        d.peak_rating,
        d.low_rating,
        d.drop_date

    HAVING MAX(pa.overall_rating) > d.low_rating
),

ranked_comebacks AS (
    SELECT
        *,
        recovered_rating - low_rating
            AS recovery_points,

        ROW_NUMBER() OVER (
            PARTITION BY player_api_id
            ORDER BY
                recovered_rating - low_rating DESC,
                drop_date ASC
        ) AS comeback_rank

    FROM recoveries
)

SELECT
    player_name,
    peak_rating,
    low_rating,
    recovered_rating,
    recovery_points,
    drop_date::DATE
FROM ranked_comebacks
WHERE comeback_rank = 1
ORDER BY recovery_points DESC, player_name
LIMIT 20;



-- ==================================================
-- 40. GIANT KILLERS: ELO DATA VALIDATION
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
-- 41. BUILD HISTORICAL FOOTBALL ELO MODEL
-- Sequential Elo updates using PL/pgSQL
-- ==================================================

DROP TABLE IF EXISTS elo_match_history;
DROP TABLE IF EXISTS elo_team_ratings;

CREATE TABLE elo_team_ratings (
    team_api_id BIGINT PRIMARY KEY,
    elo_rating DOUBLE PRECISION NOT NULL DEFAULT 1500
);

CREATE TABLE elo_match_history (
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
-- 42. GIANT KILLERS: BIGGEST ELO UPSETS
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
-- 43. GIANT KILLER INDEX
-- Teams consistently defeating stronger opponents
-- ==================================================

WITH team_perspective AS (
    SELECT
        e.match_id,
        e.season,
        e.home_team_api_id AS team_api_id,
        e.home_elo_before AS team_elo,
        e.away_elo_before + 65 AS opponent_effective_elo,
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
-- 44. GIANT KILLERS: ELO OVERPERFORMANCE
-- Compare actual vs expected match scores
-- for teams classified as underdogs
-- ==================================================

WITH team_perspective AS (
    SELECT
        match_id,
        home_team_api_id AS team_api_id,
        home_elo_before AS team_elo,
        away_elo_before + 65 AS opponent_effective_elo,
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
-- 45. TACTICAL DNA: MATCH INTELLIGENCE
-- Fixed PostgreSQL column names
-- ==================================================

DROP VIEW IF EXISTS tactical_match_intelligence;

CREATE VIEW tactical_match_intelligence AS
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
-- 46. TACTICAL DNA: DATA FRESHNESS AUDIT
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
-- 47. TACTICAL DNA: PRESSING VS ELO EXPECTATIONS
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
-- 49. THE LEICESTER PARADOX
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
-- 50. LEICESTER PARADOX: HIDDEN MOMENTUM
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
-- 51. LEICESTER PARADOX
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
-- 52. LEICESTER PARADOX
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
-- 53. LEICESTER PARADOX
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
-- 54. LEICESTER PARADOX
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
-- 55. LEICESTER PARADOX
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
-- 56. LEICESTER PARADOX
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
-- 57. LEICESTER PARADOX
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




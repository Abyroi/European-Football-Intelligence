-- European Football Intelligence | 01_setup_and_validation.sql
-- PostgreSQL | Execute statements individually as needed.

-- #01. DATA OVERVIEW
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

-- #02. DATA QUALITY CHECK
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

-- #03. PRIMARY KEY SETUP
-- Establish unique identifiers for all tables.
-- Run only once, after importing the data.

DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pk_country'
          AND conrelid = 'public.country'::regclass
    ) THEN
        ALTER TABLE country
ADD CONSTRAINT pk_country PRIMARY KEY (id);
    END IF;
END
$constraint$;

DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pk_league'
          AND conrelid = 'public.league'::regclass
    ) THEN
        ALTER TABLE league
ADD CONSTRAINT pk_league PRIMARY KEY (id);
    END IF;
END
$constraint$;

DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pk_team'
          AND conrelid = 'public.team'::regclass
    ) THEN
        ALTER TABLE team
ADD CONSTRAINT pk_team PRIMARY KEY (id);
    END IF;
END
$constraint$;

DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pk_player'
          AND conrelid = 'public.player'::regclass
    ) THEN
        ALTER TABLE player
ADD CONSTRAINT pk_player PRIMARY KEY (id);
    END IF;
END
$constraint$;

DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pk_matches'
          AND conrelid = 'public.matches'::regclass
    ) THEN
        ALTER TABLE matches
ADD CONSTRAINT pk_matches PRIMARY KEY (id);
    END IF;
END
$constraint$;

DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pk_player_attributes'
          AND conrelid = 'public.player_attributes'::regclass
    ) THEN
        ALTER TABLE player_attributes
ADD CONSTRAINT pk_player_attributes PRIMARY KEY (id);
    END IF;
END
$constraint$;

DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'pk_team_attributes'
          AND conrelid = 'public.team_attributes'::regclass
    ) THEN
        ALTER TABLE team_attributes
ADD CONSTRAINT pk_team_attributes PRIMARY KEY (id);
    END IF;
END
$constraint$;

-- #04. CONSTRAINT VALIDATION
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

-- #05. FOREIGN KEY VALIDATION
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

-- #06. FOREIGN KEY READINESS CHECK
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

-- #07. UNIQUE CONSTRAINTS
-- Ensure API identifiers can be referenced
-- ==================================================

DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_player_api_id'
          AND conrelid = 'public.player'::regclass
    ) THEN
        ALTER TABLE player
ADD CONSTRAINT uq_player_api_id
UNIQUE (player_api_id);
    END IF;
END
$constraint$;

DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_team_api_id'
          AND conrelid = 'public.team'::regclass
    ) THEN
        ALTER TABLE team
ADD CONSTRAINT uq_team_api_id
UNIQUE (team_api_id);
    END IF;
END
$constraint$;


-- ==================================================

-- #08. FOREIGN KEY CONSTRAINTS
-- Establish relationships between tables
-- ==================================================

-- League belongs to a country
DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_league_country'
          AND conrelid = 'public.league'::regclass
    ) THEN
        ALTER TABLE league
ADD CONSTRAINT fk_league_country
FOREIGN KEY (country_id)
REFERENCES country(id);
    END IF;
END
$constraint$;

-- Match belongs to a league
DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_matches_league'
          AND conrelid = 'public.matches'::regclass
    ) THEN
        ALTER TABLE matches
ADD CONSTRAINT fk_matches_league
FOREIGN KEY (league_id)
REFERENCES league(id);
    END IF;
END
$constraint$;

-- Match has a home team
DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_matches_home_team'
          AND conrelid = 'public.matches'::regclass
    ) THEN
        ALTER TABLE matches
ADD CONSTRAINT fk_matches_home_team
FOREIGN KEY (home_team_api_id)
REFERENCES team(team_api_id);
    END IF;
END
$constraint$;

-- Match has an away team
DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_matches_away_team'
          AND conrelid = 'public.matches'::regclass
    ) THEN
        ALTER TABLE matches
ADD CONSTRAINT fk_matches_away_team
FOREIGN KEY (away_team_api_id)
REFERENCES team(team_api_id);
    END IF;
END
$constraint$;

-- Player attributes belong to a player
DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_player_attributes_player'
          AND conrelid = 'public.player_attributes'::regclass
    ) THEN
        ALTER TABLE player_attributes
ADD CONSTRAINT fk_player_attributes_player
FOREIGN KEY (player_api_id)
REFERENCES player(player_api_id);
    END IF;
END
$constraint$;

-- Team attributes belong to a team
DO $constraint$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_team_attributes_team'
          AND conrelid = 'public.team_attributes'::regclass
    ) THEN
        ALTER TABLE team_attributes
ADD CONSTRAINT fk_team_attributes_team
FOREIGN KEY (team_api_id)
REFERENCES team(team_api_id);
    END IF;
END
$constraint$;

-- #09. DATA TYPE AUDIT
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

-- #10. DATE FORMAT VALIDATION
-- Inspect date values before type conversion
-- ==================================================

SELECT
    'matches' AS table_name,
    MIN(date) AS earliest_value,
    MAX(date) AS latest_value,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE date IS NULL
    ) AS missing_dates
FROM matches

UNION ALL

SELECT
    'player',
    MIN(birthday),
    MAX(birthday),
    COUNT(*),
    COUNT(*) FILTER (
        WHERE birthday IS NULL
    )
FROM player

UNION ALL

SELECT
    'player_attributes',
    MIN(date),
    MAX(date),
    COUNT(*),
    COUNT(*) FILTER (
        WHERE date IS NULL
    )
FROM player_attributes

UNION ALL

SELECT
    'team_attributes',
    MIN(date),
    MAX(date),
    COUNT(*),
    COUNT(*) FILTER (
        WHERE date IS NULL
    )
FROM team_attributes;



-- ==================================================

-- #11. DATE FORMAT QUALITY CHECK
-- Timestamp columns are already typed; check missing values instead
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
        WHERE date_value IS NULL
    ) AS missing_dates
FROM all_dates
GROUP BY table_name
ORDER BY table_name;



-- ==================================================

-- #12. DATE CONVERSION VALIDATION
-- Check timestamps for missing values; conversion is unnecessary
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
        WHERE date_value IS NULL
    ) AS missing_dates
FROM all_dates
GROUP BY table_name
ORDER BY table_name;


-- ==================================================

-- #13. DATA TYPE VERIFICATION (READ-ONLY)
-- The four source columns are already timestamps; no ALTER TABLE needed
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

-- #14. DATA TYPE VERIFICATION
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

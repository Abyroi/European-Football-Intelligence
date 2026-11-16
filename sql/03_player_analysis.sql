-- European Football Intelligence | 03_player_analysis.sql
-- PostgreSQL | Execute statements individually as needed.

-- #29. PLAYER DEVELOPMENT AND PEAK PERFORMANCE
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

-- #30. INDIVIDUAL PLAYER PEAK AGE
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

-- #31. BIGGEST YEAR-OVER-YEAR PLAYER IMPROVEMENTS
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

-- #32. PLAYER RATING DATA COVERAGE
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

-- #33. MESSI VS RONALDO: FIFA RATING RIVALRY
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

-- #34. FUTURE SUPERSTARS
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

-- #35. FALLEN STARS: FIFA RATING DECLINE
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

-- #36. FIFA RATING COMEBACKS
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

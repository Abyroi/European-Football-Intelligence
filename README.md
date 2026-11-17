
# ⚽ European Football Intelligence

### Exploring European Football Through PostgreSQL, Statistical Analysis & Elo Ratings

A SQL-based football analytics project examining European leagues, team performance, player development, unexpected match results, tactical characteristics, and historical performance trends.

The project uses the **European Soccer Database (2008–2016)** to investigate football through structured data analysis, advanced SQL queries, and an Elo rating model.

---

## 📌 Project Overview

| Category | Details |
|---|---|
| Project | European Football Intelligence |
| Database | European Soccer Database |
| Period | 2008–2016 |
| Coverage | 11 European leagues |
| Matches | 25,979 |
| Database Management System | PostgreSQL |
| SQL Environment | DBeaver |
| Main Language | SQL / PL/pgSQL |
| Analytical Modules | 6 |
| Numbered SQL Blocks | 53 |
| Main Research Topic | Leicester Paradox & Hidden Momentum |

### Research Objectives

This project aims to:

1. Compare football performance across European leagues.
2. Investigate home advantage and team consistency.
3. Explore player development and historical FIFA ratings.
4. Identify unexpected results using an Elo rating model.
5. Examine whether tactical characteristics are associated with performance.
6. Investigate Leicester City's remarkable improvement and the potential relationship between late-season momentum and subsequent performance.

---

## 📑 Table of Contents

- [Key Findings](#-key-findings)
- [Home Advantage](#-home-advantage)
- [Team Dominance](#-team-dominance)
- [Player Intelligence](#-player-intelligence)
- [Elo Upsets](#-elo-upsets)
- [Giant Killer Index](#-giant-killer-index)
- [Leicester Paradox](#-leicester-paradox)
- [SQL Skills Demonstrated](#-sql-skills-demonstrated)
- [Repository Structure](#-repository-structure)
- [Dataset and Setup](#-dataset-and-setup)
- [Methodology and Limitations](#-methodology-and-limitations)
- [Conclusion](#-conclusion)

---

## 🏆 Key Findings

The following results were obtained from the author's PostgreSQL queries.

| Analysis | Main Finding | SQL Block |
|---|---|---|
| Home Advantage | Spain recorded a 48.85% home win rate | #17 |
| Team Dominance | FC Barcelona averaged 2.45 points per game | #21 |
| Messi vs Ronaldo | Messi's average FIFA rating exceeded Ronaldo's from 2009 through 2015 | #33 |
| Early Elite Players | Messi and Cesc Fàbregas had recorded 85+ ratings at age 19 | Player Analysis |
| Biggest Elo Upset | Tondela defeated FC Porto 1–0 in April 2016 | #39 |
| Giant Killer Index | Manchester City led average Elo overperformance at +0.191 | #41 |
| Leicester Paradox | Leicester improved from 1.079 to 2.132 points per game | #45 |
| Hidden Momentum | Leicester's final-ten PPM exceeded its first-ten PPM by 1.30 in 2014/15 | #46 |

These findings are descriptive results from the historical dataset and should not be interpreted as proof of causation.

---

## 🏟 Home Advantage

**Research question:** Does playing at home provide a measurable advantage across European leagues?

### Selected Results

| League | Home Win Rate |
|---|---:|
| Spain — Liga BBVA | 48.85% |
| Netherlands — Eredivisie | 47.83% |
| Italy — Serie A | 46.64% |
| England — Premier League | 45.72% |
| Germany — Bundesliga | 45.22% |
| France — Ligue 1 | 44.70% |
| Scotland — Premier League | 41.67% |

### Interpretation

- Spain had the highest home win percentage among the 11 leagues.
- Scotland recorded the lowest home win percentage.
- The difference between Spain and Scotland was **7.18 percentage points**.
- Home wins were more frequent than away wins in every league examined.

**SQL techniques:** `JOIN`, `GROUP BY`, `COUNT`, `CASE`, `ROUND`, `ORDER BY`.

---

## 🥇 Team Dominance

**Research question:** Which European clubs demonstrated the strongest overall league performance?

Teams were compared using points per game (PPG), calculated as:

**PPG = Total Points / Matches Played**

A win awards three points, a draw one point, and a loss zero points.

### Top Teams

| Rank | Team | Points per Game |
|---|---|---:|
| 1 | FC Barcelona | 2.45 |
| 2 | FC Porto | 2.38 |
| 3 | SL Benfica | 2.38 |
| 4 | Real Madrid CF | 2.37 |
| 5 | Celtic | 2.32 |

FC Barcelona achieved the highest points-per-game average in this analysis.

The project also examines consistency by calculating the standard deviation of seasonal performance.

**SQL techniques:** `UNION ALL`, `GROUP BY`, `SUM`, `COUNT`, `STDDEV_SAMP`, `HAVING`.

---

## 🌟 Player Intelligence

### Messi vs Ronaldo: FIFA Rating Evolution

This analysis compares the historical average overall ratings recorded in the dataset.

| Year | Lionel Messi | Cristiano Ronaldo |
|---|---:|---:|
| 2007 | 85.50 | 89.00 |
| 2008 | 90.00 | 91.00 |
| 2009 | 90.00 | 89.50 |
| 2010 | 90.00 | 89.00 |
| 2011 | 92.00 | 90.50 |
| 2012 | 94.00 | 92.00 |
| 2013 | 94.00 | 92.00 |
| 2014 | 93.33 | 92.00 |
| 2015 | 93.43 | 92.60 |

### Main Observations

- Ronaldo had the higher average rating in 2007 and 2008.
- Messi had the higher average rating from 2009 through 2015.
- Messi's largest advantage in this comparison was 2.00 rating points in 2012 and 2013.

These are historical FIFA-based database ratings, not direct measures of real-world football ability.

### Youngest Players at Their First Recorded 85+ Rating

| Player | Age | First Recorded Rating |
|---|---:|---:|
| Lionel Messi | 19 | 85 |
| Cesc Fàbregas | 19 | 85 |
| Karim Benzema | 20 | 85 |
| Eden Hazard | 20 | 85 |
| Neymar | 20 | 85 |
| Wayne Rooney | 21 | 93 |
| Cristiano Ronaldo | 22 | 87 |

This analysis uses the following window function:

```sql
ROW_NUMBER() OVER (
    PARTITION BY p.player_api_id
    ORDER BY pa.date ASC, pa.id ASC
)
```

The function identifies the earliest available record for each player with an overall rating of at least 85.

**Important:** The result represents the first qualifying record available in the database, not necessarily the first time the player achieved that rating in their career.

---

## ⚡ Elo Upsets

**Research question:** Which match results were most surprising relative to the teams' pre-match Elo ratings?

The project implements a chronological Elo rating model to estimate the expected score for each team before a match.

### Selected Unexpected Results

| Date | Underdog | Opponent | Result | Expected Elo Score |
|---|---|---|---|---:|
| 2016-04-04 | Tondela | FC Porto | 1–0 | 0.0706 |
| 2015-12-19 | Motherwell | Celtic | 2–1 | 0.0839 |
| 2011-12-31 | Blackburn Rovers | Manchester United | 3–2 | 0.0959 |

All three underdogs won away from home.

### How Surprise Is Measured

```text
Surprise Score = Actual Elo Score - Expected Elo Score
```

In this model:

- Win = 1.0
- Draw = 0.5
- Loss = 0.0

**Important:** Elo expected score is not the same as the probability of winning in a three-outcome football match.

### Elo Model Parameters

| Parameter | Value |
|---|---:|
| Initial Elo Rating | 1500 |
| K-Factor | 20 |
| Home Advantage | 65 Elo points |

These parameters are modelling assumptions rather than universally optimal values.

---

## 🦁 Giant Killer Index

**Research question:** Which teams consistently performed better than expected when facing stronger opponents?

A team is classified as an underdog when its opponent has an effective Elo advantage of at least 100 points.

Only teams with at least 20 qualifying underdog matches are included.

### Selected Results

| Team | Underdog Matches | Expected Score | Actual Score | Avg. Overperformance |
|---|---:|---:|---:|---:|
| Manchester City | 28 | 0.380 | 0.571 | +0.191 |
| Liverpool | 49 | 0.379 | 0.541 | +0.162 |
| P. Warszawa | 34 | 0.393 | 0.529 | +0.136 |
| Pogoń Szczecin | 33 | 0.374 | 0.500 | +0.126 |
| Stade de Reims | 76 | 0.346 | 0.467 | +0.121 |
| Inter | 34 | 0.363 | 0.471 | +0.108 |

### Interpretation

Manchester City recorded the highest average overperformance among the qualifying teams.

However, Stade de Reims accumulated **+9.18 total Elo score units above expectation**, the highest total among the displayed top 20 teams.

This illustrates the distinction between average performance and cumulative performance across a different number of matches.

### Calculation

```text
Match Overperformance = Actual Score - Expected Score

Average Overperformance =
    SUM(Match Overperformance) / Underdog Matches
```

**SQL techniques:** `CTE`, `UNION ALL`, `GROUP BY`, `HAVING`, `AVG`, `SUM`, `JOIN`.

---

## 🏆 Leicester Paradox

### From 14th Place to Premier League Champions

One of the central research topics of this project is Leicester City's transformation between the 2014/15 and 2015/16 seasons.

| Metric | 2014/15 | 2015/16 |
|---|---:|---:|
| League Position | 14th | 1st |
| Matches | 38 | 38 |
| Points per Game | 1.079 | 2.132 |

### Performance Improvement

```text
Absolute PPG Improvement = 2.132 - 1.079
                         = 1.053

Relative PPG Improvement = (1.053 / 1.079) × 100
                         ≈ 97.6%
```

Leicester's points-per-game average almost doubled between the two seasons.

### Hidden Momentum: The Season Before the Title

The analysis also examines whether Leicester had already demonstrated improving form during 2014/15.

| 2014/15 Period | Points per Game | Goal Difference |
|---|---:|---:|
| First 10 Matches | 0.90 | -5 |
| Last 10 Matches | 2.20 | +11 |
| Change | +1.30 | +16 |

Leicester's final ten matches of 2014/15 showed substantially stronger performance than its opening ten matches.

### Broader Historical Comparison

The project extends this analysis to consecutive team-season pairs.

| Metric | Result |
|---|---:|
| Consecutive Team-Season Pairs | 1,074 |
| Large Improvement Rate — Top Momentum Quintile | 9.81% |
| Large Improvement Rate — Bottom Momentum Quintile | 1.86% |
| Breakthrough Definition | Next-season PPG increase ≥ 0.5 |

In the retrospective 2015/16 diagnostic comparison, the momentum ranking identified 2 of 4 qualifying breakthroughs within its top ten, compared with 0 of 4 for the previous-season PPG ranking.

These results suggest a historical association between late-season momentum and subsequent improvement.

However, they do **not** establish that Leicester's championship was predictable. The analysis is retrospective, the outcome is a large PPG improvement rather than a league title, and the diagnostic comparison involves a small, selected sample.

---

## 💻 SQL Skills Demonstrated

This project demonstrates practical application of SQL concepts across data validation, aggregation, relational analysis, and analytical modelling.

| SQL Concept | Application |
|---|---|
| `SELECT`, `WHERE` | Data retrieval and filtering |
| `ORDER BY`, `LIMIT` | Ranking teams and players |
| `DISTINCT` | Unique-value analysis |
| `JOIN`, `LEFT JOIN` | Combining relational tables |
| `GROUP BY` | League and team aggregation |
| `HAVING` | Minimum-match eligibility rules |
| `COUNT`, `SUM`, `AVG` | Statistical summaries |
| `MIN`, `MAX`, `ROUND` | Descriptive analysis |
| `CASE WHEN` | Match outcomes and point calculations |
| `UNION ALL` | Home and away team perspectives |
| `WITH` / CTEs | Multi-stage analytical queries |
| `ROW_NUMBER()` | First qualifying player records |
| `LAG()` | Previous-season comparisons |
| `PARTITION BY` | Group-specific window calculations |
| `STDDEV_SAMP()` | Team performance consistency |
| `CREATE TABLE` | Elo model data structures |
| `CREATE VIEW` | Tactical intelligence layer |
| PL/pgSQL | Chronological Elo processing |
| Date Functions | Player age and match chronology |

### Example: Window Function

```sql
SELECT
    team_api_id,
    season,
    points_per_match,
    LAG(points_per_match) OVER (
        PARTITION BY team_api_id
        ORDER BY season
    ) AS previous_season_ppm
FROM seasonal_performance;
```

This example illustrates how window functions compare a team's current season with its previous recorded season.

---

## 📁 Repository Structure

```text
European-Football-Intelligence/
│
├── README.md
│
├── original_backup.sql
│
├── sql/
│   ├── 01_setup_and_validation.sql
│   ├── 02_league_and_team_analysis.sql
│   ├── 03_player_analysis.sql
│   ├── 04_elo_and_upsets.sql
│   ├── 05_tactical_intelligence.sql
│   └── 06_leicester_paradox.sql
│
└── docs/
    ├── methodology.md
    └── audit_notes.md
```

### SQL Modules

| Module | Purpose | Blocks |
|---|---|---|
| Setup and Validation | Database structure, integrity and dates | #01–#14 |
| League and Team Analysis | Home advantage, standings and performance | #15–#28 |
| Player Analysis | Ratings and player development | #29–#36 |
| Elo and Upsets | Elo modelling and unexpected outcomes | #37–#41 |
| Tactical Intelligence | Tactical attributes and model comparisons | #42–#44 |
| Leicester Paradox | Momentum and retrospective evaluation | #45–#53 |

The original exploratory SQL script is preserved as `original_backup.sql` for traceability.

---

## 🗄 Dataset and Setup

### Data Source

**European Soccer Database**

Publisher: Hugo Mathien

Dataset URL:
https://www.kaggle.com/datasets/hugomathien/soccer

The source dataset includes match results, league information, teams, players, player ratings and tactical attributes.

The repository contains analytical SQL code rather than a copy of the original dataset.

### Requirements

- PostgreSQL
- DBeaver or another PostgreSQL-compatible SQL client
- European Soccer Database imported into PostgreSQL

### Required Tables

```text
country
league
team
player
matches
player_attributes
team_attributes
```

The published dataset is distributed as a SQLite database (`database.sqlite`), so it must be converted or imported into PostgreSQL before running this project's SQL.

The repository does not currently include an automated migration script.

### Recommended Execution Order

1. Download the European Soccer Database from Kaggle.
2. Import or migrate the tables into PostgreSQL.
3. Verify table names, date types and database integrity.
4. Review `sql/01_setup_and_validation.sql` before executing any schema-changing commands.
5. Run analytical queries from modules 02 and 03 individually.
6. Review and execute the Elo initialization in module 04 before running dependent analyses.
7. Create the tactical intelligence view in module 05 when required.
8. Execute the Leicester Paradox queries in module 06.

**Safety note:** Some SQL blocks create constraints, tables or views. Do not execute all files blindly against an existing database.

For a live demonstration in DBeaver, select an individual analytical query and execute it using `Ctrl+Enter`.

---

## 🔬 Methodology and Limitations

### Key Definitions

| Term | Definition |
|---|---|
| PPG / PPM | League points divided by matches played |
| Momentum | Last-ten PPM minus first-ten PPM |
| Breakthrough | Next-season PPM improvement of at least 0.5 |
| Elo Expected Score | Model-estimated expected result on a 0–1 scoring scale |
| Giant Killer Overperformance | Actual Elo score minus expected Elo score against stronger opponents |

### Research Limitations

1. The dataset covers historical seasons and does not represent current football performance.
2. FIFA ratings are game-based attributes, not objective measurements of football ability.
3. Elo results depend on selected model parameters.
4. Tactical associations should not be interpreted as causal effects.
5. Retrospective momentum analysis is not equivalent to a validated real-time prediction model.
6. Historical comparisons can be affected by missing data, eligibility rules and differences between leagues.

### Validation Status

The project was organized into numbered SQL blocks for inspection and testing.

In the author's PostgreSQL environment:

- 49 analytical statements passed a batch `EXPLAIN` planning check.
- Structural and Elo integrity checks were reported to pass.
- Corrected Giant Killer-related queries #40 and #41 were reported to execute successfully.

These checks do not establish that the project can be rebuilt end-to-end on a fresh database without additional setup, nor do they independently verify every analytical result.

A complete clean-database reproducibility test remains outstanding.

For more details, see:

- [Methodology](docs/methodology.md)
- [Audit Notes](docs/audit_notes.md)

---

## 🎯 Conclusion

European Football Intelligence demonstrates how PostgreSQL can be used to investigate complex football questions beyond basic match statistics.

The analysis identifies differences in home advantage, compares long-term team performance, examines player ratings, detects surprising match outcomes and evaluates historical patterns of underdog overperformance.

The Leicester Paradox provides a deeper research case by examining whether improving form at the end of one season is associated with stronger results in the next.

Together, these analyses demonstrate the use of relational SQL, common table expressions, window functions, statistical aggregation and procedural database programming in a practical sports analytics project.

---

### Data Attribution

Football data: [European Soccer Database — Hugo Mathien](https://www.kaggle.com/datasets/hugomathien/soccer).

Please refer to the dataset publisher's documentation for original data sources, licensing and usage restrictions.

### Project Status

University SQL analytics project — organized for review and live demonstration.


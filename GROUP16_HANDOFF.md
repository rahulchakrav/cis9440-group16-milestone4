# Group 16 dbt handoff

## What I’ve set up so far

I added the source definitions and three dimension models:

- `dim_date`
- `dim_time`
- `dim_crash_severity`

I also added six tests to check for duplicate or missing dimension keys, plus a query to get the column names and data types from both raw tables.

`dbt parse` passed, but I couldn’t finish the build because of my BigQuery sandbox settings. The models still need to be built and tested in your project.

## Raw data

The source definitions point to:

- **Project:** `szhu-baruch`
- **Dataset:** `group16_raw_data`
- **Tables:** `source_nyc_mv_collisions` and `source_nyc_311_streetlight_signal`

## How to add this to your dbt project

1. Create a new working branch.
2. Copy `models/group16` into your `models` folder.
3. Copy `analyses/inspect_raw_schema.sql` into your `analyses` folder.
4. Check any existing files with the same names before replacing them.
5. Keep your own project name, profile, and BigQuery connection.
6. In `dbt_project.yml`, add the `group16` configuration under `models` and your existing project name.
7. Save everything.

dbt normally adds your development dataset name before `group16_staging` and `group16_marts`. Check the build logs to see where the tables are created.

## Build and test

Run these commands one at a time:

```bash
dbt parse
```

```bash
dbt build --select dim_date dim_time dim_crash_severity
```

If everything works, you should get three tables and six passing tests.

The tables should contain:

- **`dim_time`:** 1,441 rows, including an `Unknown` row with key `-1`.
- **`dim_crash_severity`:** five severity categories.
- **`dim_date`:** one row per date from January 1, 2021 through the day you run the build, plus a `Not closed` row with key `0`.

The date table goes beyond June 2026 because some requests may close after our analysis period. We still need to apply the analysis-date filters when we build the staging and fact models.

## Get the raw-table columns

Run:

```bash
dbt show --select inspect_raw_schema --limit 200
```

Please copy the column names and data types from **System logs** and send them to me. I need those to make sure the staging SQL matches the tables you loaded.

## What we still need to do

- Build the two staging models to clean and filter the raw data.
- Add `dim_location`, `dim_complaint`, and `dim_request_status`.
- Build `fact_collision` and `fact_311_request`.
- Test the relationships and check the final counts against the cleaned source data.
- Run the full pipeline and collect the lineage screenshots and submission documentation.

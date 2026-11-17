# Group 16 dbt handoff

## What I’ve set up so far

I added the source definitions, `dim_date`, `dim_time`, and `dim_crash_severity`, along with six tests for duplicate or missing dimension keys.

I’ve now added `stg_nyc_collisions` and `stg_nyc_311_requests` using the raw-table columns you sent. They include data checks, row-count reconciliation, and four unit tests. [STAGING_SETUP.md](STAGING_SETUP.md) explains what to copy and what we need to confirm before running them.

The earlier dimension-only project passed `dbt parse` on my working branch. My own BigQuery sandbox blocked the warehouse build. The new staging work has not yet completed a dbt build or warehouse test run, and we still need the complete build/test results from the receiving project.

## Raw data

- **Project:** `szhu-baruch`
- **Dataset:** `group16_raw_data`
- **Tables:** `source_nyc_mv_collisions` and `source_nyc_311_streetlight_signal`

## Add the files to your project

1. Create a working branch in your dbt project.
2. Copy `models/group16` into `models`.
3. Copy `macros/group16` into `macros`, and `tests/group16` into `tests`.
4. Copy `analyses/inspect_raw_schema.sql` and `analyses/inspect_timestamp_encoding.sql` into `analyses`.
5. Compare existing files before replacing them. Keep your project name, profile, and BigQuery connection.
6. In `dbt_project.yml`, add the `group16` configuration under `models` and your existing project name if you haven't already.
7. Follow the timestamp checks in [STAGING_SETUP.md](STAGING_SETUP.md) before building staging. Save all files.

dbt normally adds your development dataset name before `group16_staging` and `group16_marts`. Check the build logs for the actual output locations.

## Check the first three dimensions

Run these separately:

```bash
dbt parse
```

```bash
dbt build --select dim_date dim_time dim_crash_severity
```

The expected result is three dimension tables and six passing tests:

- `dim_time`: 1,441 rows, including Unknown with key `-1`.
- `dim_crash_severity`: five categories.
- `dim_date`: January 1, 2021 through the day the build runs, plus Not closed with key `0`.

The calendar currently extends through the build date rather than a fixed extraction date. The staging models apply the analysis window to crash dates and request creation dates, but retain later request closures.

## Check the staging models

After confirming the timestamp settings, run:

```bash
dbt build --select stg_nyc_collisions stg_nyc_311_requests
```

```bash
dbt test --select path:tests/group16
```

Send me the build/test results and any errors. Duplicate IDs and invalid values should be reviewed instead of dropping records just to make the tests pass.

## What we still need to do

- Confirm the timestamp encoding, build staging, and review all test results.
- Resolve the missing original `loaded_at_utc` in the raw tables; `staged_at_utc` is a different timestamp.
- Add `dim_location`, `dim_complaint`, and `dim_request_status`.
- Build `fact_collision` and `fact_311_request`.
- Test relationships and reconcile the final fact counts with staging.
- Run the full pipeline and collect lineage screenshots and submission documentation.

# CIS 9440 — Group 16 Milestone 4

This repo has the dbt work I’ve put together for our NYC collision and 311 streetlight and traffic-signal project.

Start with [GROUP16_HANDOFF.md](GROUP16_HANDOFF.md) for the overall setup. If you already copied the first three dimensions, [STAGING_SETUP.md](STAGING_SETUP.md) explains the new staging files and how to check them.

## What’s here so far

- Source definitions for the two raw BigQuery tables.
- `dim_date`, `dim_time`, and `dim_crash_severity`, with six dimension-key tests.
- `stg_nyc_collisions` and `stg_nyc_311_requests`, written using the column names and types returned by our raw-schema query.
- Staging data checks and four unit tests covering date boundaries, severity, missing values, duplicate records, and late closures.
- Queries to inspect the raw schema and compare timestamp interpretations.

The staging models still need a successful build and test run in BigQuery. Before running them, we need to confirm how the Cloud Functions loaded the timestamps. We also need to resolve the missing original load timestamp before building the facts. The setup notes explain both points.

## Where to find everything

- `models/group16/` — the source definitions, models, and YAML tests.
- `macros/group16/` — the shared staging helpers.
- `tests/group16/` — data checks and row-count reconciliation.
- `analyses/` — queries for inspecting the source tables.
- `dbt_project.yml` — the project configuration. Keep your own project name and connection when adding this work to an existing project.

These models don’t need extra dbt packages. Use a BigQuery connection that can read the source data and create the output tables.

We still need `dim_location`, `dim_complaint`, `dim_request_status`, both fact tables, relationship tests, and full warehouse validation before Milestone 4 is complete.

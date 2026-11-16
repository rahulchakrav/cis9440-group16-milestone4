# CIS 9440 — Group 16 Milestone 4

This repo has the dbt work I’ve put together so far for our NYC collision and 311 streetlight and traffic-signal project.

If you’re adding these files to your dbt project, start with [GROUP16_HANDOFF.md](GROUP16_HANDOFF.md). It explains what to copy, how to run it, and what we still need to finish.

## What’s here so far

I’ve added the raw source definitions, three dimension models (`dim_date`, `dim_time`, and `dim_crash_severity`), and six tests to check for duplicate or missing dimension keys. There’s also a query to get the column names and data types from both raw tables.

`dbt parse` passed on my working branch, but my BigQuery sandbox settings blocked the build. The models still need to be built and tested in the project we’re using for the final warehouse.

## Where to find everything

- `models/group16/` — the source definitions, dimension models, and tests.
- `analyses/inspect_raw_schema.sql` — the query for checking the raw-table columns.
- `dbt_project.yml` — the project configuration. If you’re copying the files into your existing project, add the `group16` configuration under your own project name and keep your connection settings.
- [GROUP16_HANDOFF.md](GROUP16_HANDOFF.md) — the setup steps, expected results, and remaining work.

These models don’t need any extra dbt packages. Use your own BigQuery connection with permission to read the source data and create the output tables.

## Run the first three models

After following the setup steps in the handoff, run these commands one at a time:

```bash
dbt parse
```

```bash
dbt build --select dim_date dim_time dim_crash_severity
```

If everything works, you should get three dimension tables and six passing tests. We still need to add the staging models, the remaining dimensions, and both fact tables before the warehouse is complete.

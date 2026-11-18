# Group 16 dbt handoff

## What I've added

The repo now has the two staging models, all six dimensions, and both fact models from our updated design. I added `dim_location`, `dim_complaint`, `dim_request_status`, `fact_collision`, and `fact_311_request`, along with relationship and reconciliation tests.

The five new mart models passed local fixture checks. This doesn't replace a BigQuery build: we still need to confirm the timestamp settings, resolve the missing original load timestamp, and run the full build and tests in the receiving project.

## Raw data

- **Project:** `szhu-baruch`
- **Dataset:** `group16_raw_data`
- **Tables:** `source_nyc_mv_collisions` and `source_nyc_311_streetlight_signal`

## Add the update to your project

1. Create a working branch.
2. Compare and copy `models/group16`, `macros/group16`, and `tests/group16` into the matching folders.
3. Copy the two source-inspection queries from `analyses` if they aren't already there.
4. Keep your own project name, profile, and BigQuery connection.
5. Keep the `group16` settings under `models` and your existing project name in `dbt_project.yml`.
6. Follow [STAGING_SETUP.md](STAGING_SETUP.md) for date handling and [MARTS_SETUP.md](MARTS_SETUP.md) for the new tables and load-timestamp settings.
7. Save everything and rebuild staging as part of the full build. Its updated SQL now exposes `loaded_at_utc` for the facts.

dbt normally prefixes the custom datasets with your development dataset name. Check the build logs for the actual output locations.

## Run the full project

After resolving the settings above, run these separately:

```bash
dbt parse
```

```bash
dbt build --select path:models/group16
```

```bash
dbt test --select path:tests/group16
```

There are ten models: two staging tables, six dimensions, and two facts. dbt builds the dimensions before the facts through their references.

The small dimensions should still contain:

- `dim_time`: 1,441 rows, including Unknown with key `-1`.
- `dim_crash_severity`: five categories.
- `dim_date`: January 1, 2021 through the build date, plus Not closed with key `0`.

The other dimension counts depend on the staged data. Each fact must preserve the IDs and row counts from its staging model, and every foreign key must match a dimension row.

## What's still needed

- Confirm the source timestamp encoding from the Cloud Function code.
- Add trustworthy original `loaded_at_utc` values to the raw data and enable their staging flags. Fact not-null tests intentionally fail while these values are missing.
- Run the full build and tests, investigate errors, and document warnings.
- Confirm the calendar endpoint with our documentation; the current SQL uses the build date rather than a fixed extraction date.
- Collect the complete DAG and BigQuery screenshots, share the final datasets with the professor, and prepare the overview, ELT documentation, and meeting log for Brightspace.

Send me the build/test results and any errors so we can resolve them before submission.

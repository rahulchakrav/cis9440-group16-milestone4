# Group 16 dbt handoff

The repo contains two staging models, six dimensions, and two facts. The complete warehouse still needs a successful build and data-test run in BigQuery.

## Source data

- Project: `szhu-baruch`
- Dataset: `group16_raw_data`
- Tables: `source_nyc_mv_collisions` and `source_nyc_311_streetlight_signal`

## Add the files to your dbt project

1. Create a working branch.
2. Compare and copy `models/group16`, `macros/group16`, and `tests/group16` into the matching folders. Copy `analyses/inspect_timestamp_encoding.sql` into `analyses`.
3. Keep your own project name, profile, and BigQuery connection. Under `models` and your project name in `dbt_project.yml`, keep the `group16` configuration from this repo.
4. If you copied an earlier version, remove `staging_unit_tests.yml` and `marts_unit_tests.yml` from your project. They are optional checks that are no longer included. Keep `staging.yml`, `dimensions.yml`, and `facts.yml` because they test the actual warehouse data.
5. Confirm the settings below, save everything, and run the full build. Rebuild staging too, because the facts use its `loaded_at_utc` column.

If your dbt project uses a different repository, updating this GitHub repo alone does not update your project. Check the build logs for the actual output datasets; dbt normally adds your development dataset name before `group16_staging` and `group16_marts`.

## Confirm timestamp handling

The raw date columns are TIMESTAMPs, but our model uses NYC calendar dates and local DATETIMEs. Send me the Cloud Function code that loads both tables so we can confirm the encoding for each source, including both 311 date fields.

Merge these variables into one top-level `vars` section in your `dbt_project.yml`:

```yaml
vars:
  group16_collision_timestamp_timezone: UNCONFIRMED
  group16_311_timestamp_timezone: UNCONFIRMED
  group16_collision_has_loaded_at_utc: false
  group16_311_has_loaded_at_utc: false
```

`UNCONFIRMED` is a placeholder, not a working timezone. Staging compilation stops until we confirm the loader and replace each value:

- `UTC` recovers the original NYC clock values if they were loaded into TIMESTAMP unchanged.
- `America/New_York` converts actual stored instants back to NYC local time if the loader already applied the source timezone.

Do not infer this from the column type alone. Compare the loader and known source records, including winter and summer values. If 311 creation and closure fields were encoded differently, fix the loader or separate their settings before building.

This query shows both interpretations for a few records; the output alone doesn't prove which is correct:

```bash
dbt show --select inspect_timestamp_encoding --limit 10
```

## Supply the original load timestamp

Neither supplied raw schema includes `loaded_at_utc`, which our final model requires. For now, staging emits a typed null and the facts preserve it. **Their required not-null tests will fail until we resolve this.**

Add a real UTC load timestamp to each Cloud Function's output and reload the raw tables, or backfill from trustworthy metadata for the actual load. Once a source has a populated TIMESTAMP column named `loaded_at_utc`, set its corresponding `has_loaded_at_utc` variable above to `true` and rebuild.

Do not use `staged_at_utc` as a replacement: it records the dbt staging run, not the original load. If the group changes the model's load-time requirement instead, document that change and update the model and tests together.

## Build and check

After resolving those settings, run these separately:

```bash
dbt parse
```

```bash
dbt build --select path:models/group16
```

```bash
dbt test --select path:tests/group16
```

dbt builds the dimensions before the facts through their references. The last command also includes the source-only missing-date check. Investigate errors and document warnings; tables appearing in BigQuery does not mean all tests passed.

Expected small-dimension counts:

- `dim_time`: 1,441 rows, including Unknown with key `-1`.
- `dim_crash_severity`: five categories.
- `dim_date`: January 1, 2021 through the build date, plus Not closed with key `0`.

Other dimension counts depend on the staged data. Each fact must preserve its staging IDs, row counts, and measures, and all foreign keys must match dimension rows.

## Modeling notes

- Collisions use crash dates; requests use creation dates. June 30, 2026 is included, and later request closures are retained.
- Missing persons-injured/killed counts stay null. Missing subgroup counts become zero as specified in our model; invalid counts fail tests.
- Severity follows the Milestone 3 order: Fatal, Unknown, Multiple Injuries, Single Injury, No Injury.
- Location contains borough–ZIP pairs from both sources, including partially known locations. Unknown/Unknown has key `0`.
- Complaint includes descriptor 2; null stays different from literal text. Status includes Unknown with key `0`; only Closed sets `is_closed` to true.
- Other location, complaint, and status keys are stable signed INT64 fingerprints. Negative keys are valid, and uniqueness tests detect collisions.
- Missing crash times use key `-1`; missing closure dates use date key `0`. Contradictory statuses and closure dates are flagged for review.
- Facts use left joins so unmatched records remain visible and fail tests. Duplicate IDs remain visible too; the code does not arbitrarily choose a record.
- Resolution hours measure the difference between local DATETIMEs, not elapsed hours across daylight-saving changes.
- Aggregate each fact by borough and month before comparing them. Do not join the facts row by row.

## Still needed for submission

Confirm the settings, run and validate the full warehouse, and review the calendar endpoint against our documentation: the SQL currently uses the build date rather than a fixed extraction date. Collect the complete lineage and BigQuery screenshots, share the final datasets with the professor, and prepare the overview PDF, ELT documentation PDF, and meeting log for Brightspace.

# Adding the staging models

I used the column list from `inspect_raw_schema` to write the two staging models. They clean the collision and 311 data and keep records from January 1, 2021 through June 30, 2026. The SQL and tests are ready for warehouse validation; they have not been run against our BigQuery data yet.

## Copy these files

Keep your existing dbt project and connection. Add these folders to the same locations in your project:

- `models/group16/staging/` — keep the existing source definitions and add both SQL models and the two staging test YAML files.
- `macros/group16/` — shared date, location, and number-cleaning code.
- `tests/group16/` — checks for invalid values, source-to-staging row counts, and records that need review.
- `analyses/inspect_timestamp_encoding.sql` — a small query to help check the loaded dates.

The `group16` configuration from the original handoff still applies. Don't replace your own project name or connection.

## Confirm how the dates were loaded first

The raw `crash_date`, `created_date`, and `closed_date` columns are BigQuery TIMESTAMPs, while our model uses NYC calendar dates and local DATETIMEs. The column list alone doesn't tell us whether the loader converted the original NYC times into actual UTC instants or loaded the original clock values unchanged.

Send Rahul the Cloud Function code that parses and loads these dates. We need to check each source separately, including both 311 date fields. The staging models deliberately stop compilation if the matching timezone setting is unconfirmed. This avoids silently moving records into the wrong date or month.

After checking the loader, add these variables at the top level of your `dbt_project.yml`, alongside `name`, `profile`, and `models`. Merge them into an existing `vars` section if you already have one:

```yaml
vars:
  group16_collision_timestamp_timezone: UNCONFIRMED
  group16_311_timestamp_timezone: UNCONFIRMED
```

Those are intentional placeholders, not working settings. Rahul will replace them based on the loader:

- `UTC` if the original NYC date/time text was loaded into TIMESTAMP without changing the clock values. This recovers that text as a local DATETIME without an extra timezone shift.
- `America/New_York` if the loader interpreted the source as NYC local time and stored the corresponding real instant.

If creation and closure timestamps were loaded differently, fix the loader or give them separate settings before building. Do not guess based only on the TIMESTAMP data type. Compare known source records, including winter and summer records, with the loaded values.

This optional query shows both interpretations for a few IDs. It can help with the comparison, but cannot establish the right interpretation by itself:

```bash
dbt show --select inspect_timestamp_encoding --limit 10
```

## Build and check

Once the timestamp settings are confirmed, save the files and run these separately:

```bash
dbt parse
```

```bash
dbt build --select stg_nyc_collisions stg_nyc_311_requests
```

```bash
dbt test --select path:tests/group16
```

The build includes four fixture-based unit tests as well as the models' data tests. The extra test command includes the source-only missing-date check. Keep the results and investigate errors before using these models for facts. Warnings identify missing source dates or status/closure inconsistencies that need to be counted and documented.

## Decisions in the SQL

- Collisions use the crash date; requests use the creation date. June 30 is included. A qualifying request can still have a closure after June 2026.
- Boroughs use consistent labels, and valid five-digit ZIP codes stay as text. ZIP+4 is reduced to five digits. Unknown locations are retained; we don't infer a borough from a ZIP code.
- Missing persons-injured and persons-killed values stay null. Missing subgroup counts become zero as specified in our model. Nonempty invalid counts stay null, and invalid or negative counts fail a test.
- Severity follows our Milestone 3 order: Fatal first, then Unknown, Multiple Injuries, Single Injury, and No Injury.
- Missing crash times get key `-1`. Missing closure dates get key `0`. A closed status without a closure date is flagged for review.
- Request IDs are converted to INT64 to match the final model, with the original text kept in `raw_unique_key`. Invalid IDs fail tests.
- Duplicate IDs are retained and fail uniqueness tests. There is no reliable source update timestamp in the supplied schema, so the SQL does not pick an arbitrary version. Review duplicates before deciding how to deduplicate or reload them.
- `resolution_hours` is the difference between NYC local DATETIMEs, matching the model. It measures wall-clock hours, not timezone-aware elapsed hours across daylight-saving changes. Negative durations fail a test.

## Original load time is still missing

Neither supplied raw schema includes `loaded_at_utc`. The staging models add `staged_at_utc`, which means when dbt built the table. It is not the original Cloud Function load time and should not be renamed to imply that it is.

Before building the final facts, add a real load timestamp to the extraction pipeline and reload/backfill from trustworthy load metadata, or document an approved model change. We still need the remaining three dimensions, both fact models, relationships, and full warehouse validation.

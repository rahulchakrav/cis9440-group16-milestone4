# Building the remaining dimensions and facts

I added the remaining five models from our Milestone 3 design. They passed local fixture checks, but have not been built or validated against our BigQuery data yet.

## Where the models go

| Folder under `models/group16/marts/` | New files |
| --- | --- |
| `shared/` | `dim_location.sql` |
| `collisions/` | `fact_collision.sql` |
| `requests/` | `dim_complaint.sql`, `dim_request_status.sql`, `fact_311_request.sql` |

The date, time, and severity dimensions stay where they are. Each fact uses `ref()` for staging and all its dimensions, including both date roles for 311 requests. dbt will build the dimensions before the facts and show these dependencies in the DAG.

## Copy the update

On a working branch in your project, compare and copy all of `models/group16/`, `macros/group16/`, and `tests/group16/` to the matching folders. Keep your own project name, connection, and the existing `group16` materialization/schema settings.

The staging SQL changed too: it now exposes `loaded_at_utc` for the facts. Rebuild staging after copying this update so that column exists. If your dbt project uses a separate repository, updating this repository alone does not update your project.

## Two settings still need attention

First, confirm how the Cloud Functions encoded the raw timestamps. Follow [STAGING_SETUP.md](STAGING_SETUP.md). The existing timezone checks remain in place; do not guess the values just to get a build to run.

Second, the supplied raw schemas do not include the original `loaded_at_utc` required by our model. With the current sources, staging emits a typed null and the facts carry it through. **The fact not-null tests will fail until this is resolved. A table being created is not a successful final build.**

Add a real UTC load timestamp to each Cloud Function's output and reload the raw data, or backfill from trustworthy metadata for the actual load. After the corresponding raw tables contain populated TIMESTAMP columns named `loaded_at_utc`, merge these settings into your existing top-level `vars` section:

```yaml
vars:
  # Keep the two confirmed timezone variables here too.
  group16_collision_has_loaded_at_utc: true
  group16_311_has_loaded_at_utc: true
```

Enable each flag only when its source column exists. The default is false. Do not create a second `vars` section or remove the timezone settings. `staged_at_utc` records when dbt built staging and is not a substitute for the original load time.

If the group changes the model's load-time requirement instead, document the change and update the model and tests together before submission.

## Build and validate

Once the source data and settings are ready, run these separately:

```bash
dbt parse
```

```bash
dbt build --select path:models/group16
```

```bash
dbt test --select path:tests/group16
```

There are ten models: two staging tables, six dimensions, and two facts. dbt determines their order from the references. The final command also includes the source-only missing-date check. Investigate errors and document any remaining warnings before submission.

## Decisions in the models

- Location uses distinct borough–ZIP pairs from both staging tables. Unknown/Unknown has key `0`; a known borough with an unknown ZIP remains its own location.
- Complaint uses complaint type, descriptor, and descriptor 2. A missing descriptor 2 stays different from literal text such as `null`, and the fact join matches nulls correctly.
- Request status has one normalized status per row, plus Unknown with key `0`. Only Closed sets `is_closed` to true.
- Other dimension keys are deterministic signed INT64 fingerprints of JSON-encoded natural keys. Negative keys are valid. Uniqueness tests detect any hash collision; do not replace keys with row numbers or remove those tests.
- Collision facts preserve the staged measures, including missing persons-injured/killed values.
- Request facts preserve separate creation/closure date keys. No closure maps to date key `0`, and closures after June 2026 retain their actual dates.
- Facts use left joins. Missing matches remain visible and fail not-null tests rather than silently dropping records. Duplicate IDs or dimension members fail uniqueness or reconciliation tests.
- Never join the two facts row by row. Aggregate each by borough and month before comparing results.

## Checks included

The tests cover primary keys, required fields, foreign keys, count flags, unique natural keys, and Unknown members. Reconciliation compares row multiplicities per ID and measures with staging, so missing rows, multiplied rows, and null-to-zero changes cannot be hidden by equal overall totals.

Five new dbt unit-test scenarios cover the dimension and fact joins. They passed a local SQLite compatibility check, including deliberate join-fanout and measure-corruption cases. That check substitutes a local deterministic hash; it does not validate BigQuery syntax, FarmHash values, timestamp conversions, or live data. The actual dbt unit and data tests still need to run in BigQuery.

To repeat the local mart check with Python, Jinja2, and PyYAML installed:

```bash
python scripts/check_marts_locally.py
```

Keep the successful build/test results, complete lineage screenshot, and final BigQuery screenshots for Milestone 4.

## References

- [BigQuery hash functions](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/hash_functions)
- [dbt relationship tests](https://docs.getdbt.com/reference/resource-properties/data-tests)

# CIS 9440 — Group 16 Milestone 4

This repo has the dbt work for our NYC collision and 311 streetlight and traffic-signal project.

Start with [GROUP16_HANDOFF.md](GROUP16_HANDOFF.md) for the overall setup. [STAGING_SETUP.md](STAGING_SETUP.md) covers source cleaning and date handling, and [MARTS_SETUP.md](MARTS_SETUP.md) explains the dimensions, facts, and full build.

## What's here

- Source definitions for the two raw BigQuery tables.
- Two staging models that clean the data and apply our January 2021–June 2026 analysis window.
- Six dimensions: date, time, location, crash severity, complaint, and request status.
- Two facts: `fact_collision` and `fact_311_request`.
- Key, relationship, and reconciliation tests, plus nine dbt unit-test scenarios.
- Queries for inspecting the raw columns and timestamp encoding.

The five new mart models passed local fixture checks, but the complete warehouse has not been built or validated in BigQuery yet. We still need to confirm how the loader handled timestamps and supply the original `loaded_at_utc` required by the facts. The setup notes explain these remaining steps.

## Where to find everything

- `models/group16/staging/` — sources, staging models, and their YAML tests.
- `models/group16/marts/shared/` — date, time, and location dimensions.
- `models/group16/marts/collisions/` — crash severity and collision facts.
- `models/group16/marts/requests/` — complaint/status dimensions and 311 facts.
- `models/group16/marts/` — dimension/fact test definitions and mart unit tests.
- `macros/group16/` — staging helpers.
- `tests/group16/` — data quality and reconciliation queries.
- `analyses/` — source-inspection queries.
- `scripts/check_marts_locally.py` — a limited local check of the mart joins.

The dbt models don't need extra packages. Use your own BigQuery connection with permission to read the raw data and create output tables. When copying files into an existing project, keep your project name and connection settings.

After confirming the settings in the setup notes, run these separately:

```bash
dbt build --select path:models/group16
```

```bash
dbt test --select path:tests/group16
```

We still need a successful full build, review of the test results, lineage screenshots, and the Brightspace submission documents before calling Milestone 4 complete.

# CIS 9440 — Group 16 Milestone 4

This repo contains our dbt models for NYC motor vehicle collisions and 311 streetlight and traffic-signal requests. Our analysis window is January 1, 2021 through June 30, 2026.

## Project files

- `models/group16/staging/` — raw source definitions and two staging models.
- `models/group16/marts/shared/` — date, time, and location dimensions.
- `models/group16/marts/collisions/` — crash severity and collision facts.
- `models/group16/marts/requests/` — complaint/status dimensions and 311 facts.
- `macros/group16/` — helpers used by the staging models.
- `tests/group16/` and the model YAML files — checks on keys, relationships, values, and row counts.
- `analyses/inspect_timestamp_encoding.sql` — helps compare the loaded dates with the source values.

See [GROUP16_HANDOFF.md](GROUP16_HANDOFF.md) for setup and build instructions. The dbt models don't need extra packages.

All ten models are written, but the full BigQuery build is still unverified. We need to confirm the raw timestamp encoding and resolve the missing original `loaded_at_utc` before the warehouse can pass all checks.

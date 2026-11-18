"""Run mart SQL fixtures without a warehouse.

Requires Jinja2 and PyYAML. This executes the five mart models with SQLite,
translating UNION DISTINCT and substituting a deterministic test hash for
BigQuery's FARM_FINGERPRINT(TO_JSON_STRING(STRUCT(...))). It checks join/grain
behavior, not BigQuery compilation, hash values, or timestamp conversion.
The same fixture scenarios live in dbt's marts_unit_tests.yml for real validation.
"""
from collections import Counter
from pathlib import Path
import copy
import hashlib
import json
import re
import sqlite3

import jinja2
import yaml

ROOT = Path(__file__).resolve().parents[1]
MODELS = {p.stem: p for p in (ROOT / 'models').rglob('*.sql')}
COUNTS = [f'number_of_{who}_{measure}'
          for who in ('persons', 'pedestrians', 'cyclist', 'motorist')
          for measure in ('injured', 'killed')]
SCHEMAS = {
    'stg_nyc_collisions': ['collision_id', 'crash_date_key', 'crash_time_key',
        'borough', 'zip_code', 'severity_key', 'collision_count', *COUNTS, 'loaded_at_utc'],
    'stg_nyc_311_requests': ['unique_key', 'created_date_key', 'created_time_key',
        'closed_date_key', 'borough', 'zip_code', 'complaint_type', 'descriptor',
        'descriptor_2', 'status', 'request_count', 'created_datetime',
        'closed_datetime', 'resolution_hours', 'loaded_at_utc'],
    'dim_date': ['date_key'], 'dim_time': ['time_key'],
    'dim_location': ['location_key', 'borough', 'zip_code'],
    'dim_crash_severity': ['severity_key'],
    'dim_complaint': ['complaint_key', 'complaint_type', 'descriptor', 'descriptor_2'],
    'dim_request_status': ['status_key', 'status', 'is_closed'],
}


def test_hash(*values):
    data = json.dumps(values, ensure_ascii=False).encode()
    return int.from_bytes(hashlib.blake2b(data, digest_size=8).digest(), 'big', signed=True)


def render(path):
    env = jinja2.Environment(undefined=jinja2.StrictUndefined)
    return env.from_string(path.read_text()).render(
        config=lambda **kwargs: '', ref=lambda name: '"' + name + '"')


def sqlite_sql(sql):
    sql = re.sub(r'\bunion\s+distinct\b', 'union', sql, flags=re.I)
    return re.sub(
        r'farm_fingerprint\(to_json_string\(struct\(([^()]+)\)\)\)',
        r'test_hash(\1)', sql, flags=re.I)


def connection(inputs):
    db = sqlite3.connect(':memory:')
    db.row_factory = sqlite3.Row
    db.create_function('test_hash', -1, test_hash)
    for name, columns in SCHEMAS.items():
        db.execute(f'create table "{name}" ({", ".join(columns)})')
    for fixture in inputs:
        name = re.fullmatch(r"ref\('([^']+)'\)", fixture['input']).group(1)
        for row in fixture['rows']:
            assert set(row) <= set(SCHEMAS[name]), (name, row)
            db.execute(f'insert into "{name}" ({", ".join(row)}) '
                       f'values ({", ".join("?" for _ in row)})', list(row.values()))
    return db


def run_case(test):
    db = connection(test['given'])
    rows = list(db.execute(sqlite_sql(render(MODELS[test['model']]))))
    expected = test['expect']['rows']
    columns = list(expected[0])
    assert all(set(row) == set(columns) for row in expected)
    actual_values = Counter(tuple(row[c] for c in columns) for row in rows)
    expected_values = Counter(tuple(row[c] for c in columns) for row in expected)
    assert actual_values == expected_values, (test['name'], actual_values, expected_values)
    if test['model'].startswith('dim_'):
        key = {'dim_location': 'location_key', 'dim_complaint': 'complaint_key',
               'dim_request_status': 'status_key'}[test['model']]
        assert len({row[key] for row in rows}) == len(rows), 'Fixture keys collided'
    db.close()


def check_failure_detection(tests):
    # A duplicated lookup member must multiply rows and trigger reconciliation.
    case = copy.deepcopy(next(t for t in tests if t['model'] == 'fact_collision'))
    location = next(f for f in case['given'] if f['input'] == "ref('dim_location')")
    location['rows'].append(dict(location['rows'][0]))
    db = connection(case['given'])
    db.execute('create table fact_collision as ' + sqlite_sql(render(MODELS['fact_collision'])))
    db.execute('create table fact_311_request as ' + sqlite_sql(render(MODELS['fact_311_request'])))
    grain_test = ROOT / 'tests/group16/assert_fact_grains_match_staging.sql'
    assert list(db.execute(render(grain_test))), 'Join fanout was not detected'
    # Now repair the duplicate, confirm reconciliation passes, then mutate a measure.
    db.execute('delete from dim_location where rowid = (select max(rowid) from dim_location)')
    db.execute('drop table fact_collision')
    db.execute('create table fact_collision as ' + sqlite_sql(render(MODELS['fact_collision'])))
    assert not list(db.execute(render(grain_test)))
    # Missing lookup for collision 3 is deliberately still exposed as NULL in the fact.
    assert db.execute('select location_key from fact_collision where collision_id=3').fetchone()[0] is None
    value_test = ROOT / 'tests/group16/assert_fact_values_match_staging.sql'
    assert not list(db.execute(render(value_test)))
    db.execute('update fact_collision set number_of_persons_injured=0 where collision_id=1')
    assert list(db.execute(render(value_test))), 'Null-to-zero corruption was not detected'
    db.close()


def check_stable_location_keys(tests):
    case = next(t for t in tests if t['model'] == 'dim_location')
    db = connection(case['given'])
    sql = sqlite_sql(render(MODELS['dim_location']))
    before = {(r['borough'], r['zip_code']): r['location_key'] for r in db.execute(sql)}
    db.execute("insert into stg_nyc_collisions (borough, zip_code) values ('MANHATTAN','10002')")
    after = {(r['borough'], r['zip_code']): r['location_key'] for r in db.execute(sql)}
    assert all(after[natural] == key for natural, key in before.items())
    assert after[('Unknown', 'Unknown')] == 0
    db.close()


if __name__ == '__main__':
    tests = yaml.safe_load((ROOT / 'models/group16/marts/marts_unit_tests.yml').read_text())['unit_tests']
    for test in tests:
        run_case(test)
        print('PASS:', test['name'])
    check_failure_detection(tests)
    check_stable_location_keys(tests)
    print('PASS: join-fanout detection, null-preservation reconciliation, and key stability')
    print('Not checked here: BigQuery syntax/execution, FarmHash values, staging timestamp conversions, or live data.')

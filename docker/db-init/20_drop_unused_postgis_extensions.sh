#!/bin/bash
# The postgis/postgis image's own init script (10_postgis.sh) installs the
# full extension set — postgis, postgis_topology, fuzzystrmatch and the US
# census tiger geocoder — into every database it bootstraps. This app only
# uses postgis + pgcrypto (enabled by our own migration); the rest is dead
# weight that also breaks a fresh `structure.sql` load (it references the
# tiger/topology schemas, which don't exist on a database created later via
# plain `CREATE DATABASE`, e.g. the test database). Drop them right after
# the image's own script runs (only fires on first container init, when the
# data directory is empty).
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-SQL
  DROP EXTENSION IF EXISTS postgis_tiger_geocoder CASCADE;
  DROP EXTENSION IF EXISTS postgis_topology CASCADE;
  DROP EXTENSION IF EXISTS fuzzystrmatch CASCADE;
  DROP SCHEMA IF EXISTS tiger CASCADE;
  DROP SCHEMA IF EXISTS tiger_data CASCADE;
  DROP SCHEMA IF EXISTS topology CASCADE;
SQL

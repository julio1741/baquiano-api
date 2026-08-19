# The postgis/postgis base image pre-installs the US census tiger geocoder
# and topology extensions (irrelevant to this app) into whichever database
# it's told to bootstrap via POSTGRES_DB. Exclude those schemas from
# structure.sql so it only tracks what this app actually owns; keep
# CREATE EXTENSION statements (postgis, pgcrypto) by not scoping the dump
# to a single schema via schema_search_path, which would drop them too.
ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = [
  "--no-comments",
  "--exclude-schema=tiger",
  "--exclude-schema=tiger_data",
  "--exclude-schema=topology"
]

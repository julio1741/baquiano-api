# Every timestamp column is timestamptz, storing UTC (section 3 of the spec).
# Without this, t.timestamps / t.datetime generate "timestamp without time
# zone" columns.
require "active_record/connection_adapters/postgresql_adapter"
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = :timestamptz

# Every Postgres database already has a "public" schema, so replaying
# pg_dump's explicit `CREATE SCHEMA public;` on a freshly created database
# fails with "schema already exists". Strip that one statement after every
# dump; nothing else in structure.sql depends on it existing explicitly.
namespace :db do
  namespace :schema do
    task dump: :environment do
      path = Rails.root.join("db/structure.sql")
      next unless File.exist?(path)

      contents = File.read(path)
      cleaned = contents.gsub(/^--\n-- Name: public; Type: SCHEMA.*\n--\n\nCREATE SCHEMA public;\n\n/, "")
      File.write(path, cleaned) if cleaned != contents
    end
  end
end

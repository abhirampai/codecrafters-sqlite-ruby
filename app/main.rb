# frozen_string_literal: true

require_relative 'database'
require_relative 'database/sqlite_schema'

database_file_path = ARGV[0]
command = ARGV[1]

database = Database.new(database_file_path)
database_file = database.file
page_size = database.page_size
table_size = database.table_size

if command == '.dbinfo'
  puts "database page size: #{page_size}"
  puts "number of tables: #{table_size}"
end

if command == '.tables'
  database_file.seek(108)

  column_pointers = table_size.times.map { |_| database_file.read(2).unpack1('n') + 1 }

  sqlite_schema_rows = column_pointers.map do |pointers|
    database_file.seek(pointers)
    SqliteSchema.new(database_file)
  end

  puts sqlite_schema_rows.map(&:tbl_name).join(' ')
end

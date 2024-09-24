# frozen_string_literal: true

require_relative 'database'

database_file_path = ARGV[0]
command = ARGV[1]

database = Database.new(database_file_path)

if command == '.dbinfo'
  puts "database page size: #{database.page_size}"
  puts "number of tables: #{database.table_size}"
elsif command == '.tables'
  puts database.table_names
end

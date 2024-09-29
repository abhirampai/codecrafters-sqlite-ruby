# frozen_string_literal: true

require_relative 'database'
require_relative 'sql_parser'

database_file_path = ARGV[0]
command = ARGV[1]

database = Database.new(database_file_path)

if command == '.dbinfo'
  puts "database page size: #{database.page_size}"
  puts "number of tables: #{database.page_header.number_of_cells}"
elsif command == '.tables'
  puts database.table_names
else
  sql_command = SqlParser.new(command)

  return if sql_command.invalid_command?

  table_name = sql_command.tables.first

  database.fetch_query_results(sql_command, table_name)
end

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

  table_name = sql_command.tables.first

  return unless database.table_names.include?(table_name)

  page_header, table_info, page = database.load_table_details(table_name)

  if sql_command.columns.first.match(/COUNT\(\*\)/i)
    puts page_header.number_of_cells
  else
    rows = page.map(&:record)
    result = sql_command.columns.map do |column|
      table_info.columns.index(column)
    end

    rows.each do |row|
      puts row[result.first]
    end
  end
end

# frozen_string_literal: true

require_relative 'database'

database_file_path = ARGV[0]
command = ARGV[1]

database = Database.new(database_file_path)

if command == '.dbinfo'
  puts "database page size: #{database.page_size}"
  puts "number of tables: #{database.page_header.number_of_cells}"
elsif command == '.tables'
  puts database.table_names
else
  table_name = command.split(' ').last.strip

  return unless database.table_names.include?(table_name)

  page = database.load_table_details(table_name)

  puts page.number_of_cells
end

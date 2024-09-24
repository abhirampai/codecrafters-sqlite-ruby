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
else
  table_name = command.split(' ').last.strip

  return unless database.table_names.include?(table_name)

  database.load_table_details(table_name)

  puts database.file.read(2).unpack1('n')
end

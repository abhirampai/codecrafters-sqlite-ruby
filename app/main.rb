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

  return unless database.table_names.include?(table_name)

  page_header, table_info, page = database.load_table_details(table_name)

  if sql_command.columns.first.match(/COUNT\(\*\)/i)
    puts page_header.number_of_cells
  else
    rows = page.map do |row|
      if table_info.columns.include?('id')
        [row.row_id, *row.record.slice(1..)]
      else
        row.record
      end
    end

    columns_to_select = sql_command.columns.map do |column|
      table_info.columns.index(column)
    end

    result = rows.map do |row|
      columns_to_select.map do |column|
        row[column]
      end.join('|')
    end

    if sql_command.condition.nil?
      puts result
    else
      column_to_search = sql_command.condition.first.split('=').first.strip
      value = sql_command.condition.first.split('=').last.strip.gsub("'", '')
      column_index = table_info.columns.index(column_to_search)
      row_indexes = []
      rows.each_with_index { |row, index| row_indexes << index if row[column_index] == value }
      row_indexes.each do |index|
        puts result[index]
      end
    end
  end
end

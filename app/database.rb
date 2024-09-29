# frozen_string_literal: true

require_relative 'database/sqlite_schema'
require_relative 'database/page_header'

# Main database class
# returns the database file instance
class Database # rubocop:disable Metrics/ClassLength
  attr_reader :file, :page_size, :page_header, :table_names, :sqlite_schema_rows, :page

  def initialize(database_file_path)
    @file = File.open(database_file_path, 'rb')
    parse_database
  end

  def parse_database
    @page_size = load_page_size
    file.seek(100)
    @page_header = PageHeader.new(file)
    @page = load_sqlite_page
    @sqlite_schema_rows = load_sqlite_schema
    @table_names = load_table_names
  end

  def load_table_details(table_name)
    table_info = sqlite_schema_rows[table_name]

    return if table_info.nil?

    offset = (table_info.rootpage - 1) * page_size
    file.seek(offset)
    @page_header = PageHeader.new(file)
    [table_info, load_sqlite_page(table_info.rootpage - 1, number_of_columns: table_info.columns.size, is_first_page: false)]
  end

  def fetch_query_results(sql_command, table_name)
    return unless table_names.include?(table_name)

    table_info, page_info = load_table_details(table_name)

    if sql_command.columns.first.match(/COUNT\(\*\)/i)
      puts page_header.number_of_cells
    else
      execute_table_scan(sql_command, table_info, page_info)
    end
  end

  private

  def load_page_size
    file.seek(16)
    file.read(2).unpack1('n')
  end

  def load_sqlite_page(offset = 0, number_of_columns: 5, is_first_page: true)
    column_pointers = page_header.number_of_cells.times.map { |_| file.read(2).unpack1('n') }
    offset_size = is_first_page ? 0 : page_size * offset
    case page_header.page_type
    when 13
      load_column_data(column_pointers, offset_size, number_of_columns:, is_first_page:)
    when 5
      load_interior_btree(column_pointers, offset_size, number_of_columns:, is_first_page:)
    end
  end

  def load_column_data(column_pointers, offset_size, number_of_columns:, is_first_page:)
    column_pointers.map do |pointer|
      file.seek(pointer + offset_size)
      sqlite_schema = SqliteSchema.new(file, number_of_columns:, is_first_page:)
      sqlite_schema
    end
  end

  def load_sqlite_schema
    page.each_with_object({}) do |row, hash|
      hash[row.tbl_name] = row
    end
  end

  def load_table_names
    sqlite_schema_rows.values.map(&:tbl_name).join(' ')
  end

  def execute_table_scan(sql_command, table_info, page_info)
    columns_to_select = sql_command.columns.map do |column|
      table_info.columns.index(column)
    end
    rows, result = prepare_results(table_info, page_info, columns_to_select)

    if sql_command.condition.nil?
      puts result
    else
      execute_where_condition(sql_command, result, rows, table_info)
    end
  end

  def prepare_results(table_info, page_info, columns_to_select)
    rows = page_info.map do |row|
      prepare_row(row, table_info)
    end

    [rows, pretty_format_row(rows, columns_to_select)]
  end

  def prepare_row(row, table_info)
    if table_info.columns.include?('id')
      [row.row_id, *row.record.slice(1..)]
    else
      row.record
    end
  end

  def pretty_format_row(rows, columns_to_select)
    rows.map do |row|
      columns_to_select.map do |column|
        row[column]
      end.join('|')
    end
  end

  def execute_where_condition(sql_command, result, rows, table_info)
    column_to_search, value = format_where_condition(sql_command)
    column_index = table_info.columns.index(column_to_search)
    row_indexes = []
    rows.each_with_index { |row, index| row_indexes << index if row[column_index] == value }
    row_indexes.each do |index|
      puts result[index]
    end
  end

  def format_where_condition(sql_command)
    [sql_command.condition.first.split('=').first.strip,
     sql_command.condition.first.split('=').last.strip.gsub("'", '')]
  end

  def load_interior_btree(column_pointers, offset_size, number_of_columns:, is_first_page:) # rubocop:disable Metrics/AbcSize
    column_pointers.map do |pointer|
      file.seek(offset_size + pointer)
      page_number = file.read(4).unpack1('N')
      RecordParser.new(file, number_of_columns).parse_varint
      file.seek((page_number - 1) * page_size)
      @page_header = PageHeader.new(file)
      load_sqlite_page(page_number - 1, number_of_columns:, is_first_page:)
    end.flatten
  end
end

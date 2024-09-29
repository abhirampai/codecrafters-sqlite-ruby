# frozen_string_literal: true

require_relative 'database/sqlite_schema'
require_relative 'database/page_header'

# Main database class
# returns the database file instance
class Database
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
    [page_header, table_info, load_sqlite_page(table_info.rootpage - 1, number_of_columns: table_info.columns.size, is_first_page: false)]
  end

  private

  def load_page_size
    file.seek(16)
    file.read(2).unpack1('n')
  end

  def load_sqlite_page(offset = 0, number_of_columns: 5, is_first_page: true)
    column_pointers = page_header.number_of_cells.times.map { |_| file.read(2).unpack1('n') }
    offset_size = is_first_page ? 0 : page_size * offset
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
end

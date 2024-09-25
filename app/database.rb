# frozen_string_literal: true

require_relative 'database/sqlite_schema'
require_relative 'database/page_header'

# Main database class
# returns the database file instance
class Database
  attr_reader :file, :page_size, :page_header, :table_names, :sqlite_schema_rows

  def initialize(database_file_path)
    @file = File.open(database_file_path, 'rb')
    parse_database
  end

  def parse_database
    @page_size = load_page_size
    file.seek(100)
    @page_header = PageHeader.new(file)
    @sqlite_schema_rows = load_sqlite_schema
    @table_names = load_table_names
  end

  def load_table_details(table_name)
    table_info = sqlite_schema_rows[table_name]

    return if table_info.nil?

    file.seek((table_info.rootpage - 1) * page_size)
    PageHeader.new(file)
  end

  private

  def load_page_size
    file.seek(16)
    file.read(2).unpack1('n')
  end

  def load_sqlite_schema # rubocop:disable Metrics/AbcSize
    file.seek(108)
    column_pointers = page_header.number_of_cells.times.map { |_| file.read(2).unpack1('n') + 1 }
    column_pointers.each_with_object({}) do |pointers, hash|
      file.seek(pointers)
      sqlite_schema = SqliteSchema.new(file)
      hash[sqlite_schema.tbl_name] = sqlite_schema
    end
  end

  def load_table_names
    sqlite_schema_rows.values.map(&:tbl_name).join(' ')
  end
end

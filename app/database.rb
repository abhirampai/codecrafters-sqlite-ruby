# frozen_string_literal: true

require_relative 'database/sqlite_schema'

# Main database class
# returns the database file instance
class Database
  attr_reader :file, :page_size, :table_size, :table_names

  def initialize(database_file_path)
    @file = File.open(database_file_path, 'rb')
    load_database_header_details
  end

  def load_database_header_details
    @page_size = load_page_size
    @table_size = load_table_size
    @table_names = load_table_names
  end

  private

  def load_page_size
    file.seek(16)
    file.read(2).unpack1('n')
  end

  def load_table_size
    file.seek(103)
    file.read(2).unpack1('n')
  end

  def load_table_names
    file.seek(108)
    column_pointers = table_size.times.map { |_| file.read(2).unpack1('n') + 1 }
    sqlite_schema_rows = column_pointers.map do |pointers|
      file.seek(pointers)
      SqliteSchema.new(file)
    end

    sqlite_schema_rows.map(&:tbl_name).join(' ')
  end
end

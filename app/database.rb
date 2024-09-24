# frozen_string_literal: true

require_relative 'database/sqlite_schema'

# Main database class
# returns the database file instance
class Database
  attr_reader :file, :page_size, :table_size, :table_names, :sqlite_schema_rows

  def initialize(database_file_path)
    @file = File.open(database_file_path, 'rb')
    load_database_header_details
  end

  def load_database_header_details
    @page_size = load_page_size
    @table_size = load_table_size
    @sqlite_schema_rows = load_sqlite_schema
    @table_names = load_table_names
  end

  def load_table_details(table_name)
    table_info = sqlite_schema_rows[table_name]

    return if table_info.nil?

    file.seek((table_info.rootpage * page_size) - page_size + 3)
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

  def load_sqlite_schema
    file.seek(108)
    column_pointers = table_size.times.map { |_| file.read(2).unpack1('n') + 1 }
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

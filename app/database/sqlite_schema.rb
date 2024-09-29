# frozen_string_literal: true

require_relative 'record_parser'

# Sqlite schema for the database
class SqliteSchema
  attr_reader :type, :name, :tbl_name, :rootpage, :sql, :record_parser, :record, :row_id, :columns

  def initialize(database_file, number_of_columns: 5, is_first_page: true)
    @record_parser = RecordParser.new(database_file, number_of_columns)
    @is_first_page = is_first_page
    info
  end

  def info
    _ = record_parser.parse_varint
    @row_id = record_parser.parse_varint
    _ = record_parser.parse_varint
    @record = record_parser.parse_record
    @type, @name, @tbl_name, @rootpage, @sql = record
    @columns = parse_columns if @is_first_page
  end

  def parse_columns
    return if sql.nil?

    sql.split(Regexp.union(['(', ')']))[1].split(',').map { |col| col.split[0] }
  end
end

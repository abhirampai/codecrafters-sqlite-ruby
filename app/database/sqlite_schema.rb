# frozen_string_literal: true

require_relative 'record_parser'

# Sqlite schema for the database
class SqliteSchema
  attr_reader :type, :name, :tbl_name, :rootpage, :sql, :record_parser, :row_id

  def initialize(database_file)
    @record_parser = RecordParser.new(database_file, 5)
    info
  end

  def info
    _number_of_bytes_in_payload = record_parser.parse_varint
    @row_id = record_parser.parse_varint
    record = record_parser.parse_record
    @type, @name, @tbl_name, @root_page, @sql = record
  end
end
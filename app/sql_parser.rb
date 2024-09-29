# frozen_string_literal: true

# Parses sql command
class SqlParser
  PATTERN = /\ASELECT\s+(?<columns>\*|COUNT\(\*\)|[\w\s,]+)\s+FROM\s+(?<table>\w+)(?:\s+WHERE\s+(?<condition>.+))?\z/i

  attr_reader :sql_command, :columns, :tables, :condition, :invalid_command

  def initialize(command)
    @sql_command = command
    parse_sql_command
  end

  def parse_sql_command
    match = sql_command.match(PATTERN).to_a
    unless match.empty?
      @columns = match[1].split(',').map(&:strip)
      @tables = match[2].split(',').map(&:strip)
      @condition = match[3]&.split(',')&.map(&:strip)
      @invalid_command = false
    else
      @invalid_command = true
      puts "Invalid SQL command: #{sql_command}"
    end
  end

  def invalid_command?
    invalid_command
  end
end

# frozen_string_literal: true

# Parses sql command
class SqlParser
  PATTERN = /^(SELECT |INSERT |UPDATE |DELETE |DROP )?(.*)\s*(FROM|WHERE|JOIN)(.*)\s*(WHERE\s*(.*))?$/

  attr_reader :sql_command, :operation, :columns, :tables

  def initialize(command)
    @sql_command = command
    parse_sql_command
  end

  def parse_sql_command
    match = sql_command.match(PATTERN).to_a
    if match
      @operation = match[1].capitalize
      @columns = match[2].split(',').map(&:strip)
      @tables = match[4].split(',').map(&:strip)
    else
      puts "Invalid SQL command: #{sql_command}"
    end
  end
end

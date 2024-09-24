# frozen_string_literal: true

# Main database class
# returns the database file instance
class Database
  attr_reader :file

  def initialize(database_file_path)
    @file = File.open(database_file_path, 'rb')
  end

  def page_size
    file.seek(16)
    file.read(2).unpack1('n')
  end

  def table_size
    file.seek(103)
    file.read(2).unpack1('n')
  end
end

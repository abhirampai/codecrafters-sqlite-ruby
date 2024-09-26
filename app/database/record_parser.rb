# frozen_string_literal: true

# Parses the databse record
class RecordParser
  attr_reader :stream, :column_count

  IS_FIRST_BIT_ZERO_MASK = 0b10000000
  LAST_SEVEN_BITS_MASK = 0b01111111

  def initialize(stream, column_count)
    @stream = stream
    @column_count = column_count
  end

  def parse_record
    serial_types.map do |serial_type|
      parse_column_value(serial_type)
    end
  end

  def serial_types
    column_count.times.map do |_|
      parse_varint
    end
  end

  def parse_column_value(serial_type) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    case serial_type
    when 0
      nil
    when 1..4
      stream.read(serial_type).unpack1('C')
    when 5
      stream.read(6).unpack1('C')
    when 6, 7
      stream.read(8).unpack1('C')
    when 8, 9
      serial_type == 8 ? 0 : 1
    when 10, 11
      throw 'Serial types are not supported'
    else
      length = (serial_type - (serial_type.even? ? 12 : 13)) / 2
      stream.read(length)
    end
  end

  def parse_varint
    value = 0
    usable_bytes.each_with_index do |usable_byte, index|
      usable_size = index == 8 ? 8 : 7

      shifted = value << usable_size
      value = shifted + usable_value(usable_size, usable_byte)
    end
    value
  end

  def usable_value(usable_size, byte)
    usable_size == 8 ? byte : byte & LAST_SEVEN_BITS_MASK
  end

  def usable_bytes
    usable_bytes_array = []
    8.times do |_|
      byte = stream.read(1).unpack1('c2')
      usable_bytes_array.append(byte)
      break if starts_with_zero(byte)
    end
    usable_bytes_array
  end

  def starts_with_zero(byte)
    (byte & IS_FIRST_BIT_ZERO_MASK).zero?
  end
end

# frozen_string_literal: true

# Page Header in the sqlite database
class PageHeader
  attr_reader :page_type, :first_free_block_start, :number_of_cells, :start_of_content_area, :fragmented_free_bytes

  def initialize(file)
    @page_type = file.read(1).unpack1('c')
    @first_free_block_start = file.read(2).unpack1('n')
    @number_of_cells = file.read(2).unpack1('n')
    @start_of_content_area = file.read(2).unpack1('n')
    @first_free_block_start = file.read(2).unpack1('n')
  end
end

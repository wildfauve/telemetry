class StreamBase

  attr_accessor :blocks, :segments, :date, :op_code, :id, :channel_id, :t_node_id, :validation, :midnight_read

  def initialize
  end

  def read(use_line)
    parse(use_line)
  end


  def parse(use_line)
    raise
  end


  def parse_date(date)
    Time.parse(date)
  end

  def channel_id
    @channel_id
  end




end

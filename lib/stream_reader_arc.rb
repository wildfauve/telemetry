class StreamReaderArc < StreamBase

  def initialize
    super
  end

  def blockerate(use_line)
    super
  end

  # 0000000111XXAAA,60B08Eaaa063,60B08Eaaa063,1,1,IN20,A001,20150911,48,1,1207.1,0.1,0,0,0.1,0,0.1,0,0,0.1,0,0,0.1,0,0,0.1,0,0.1,0,0.6,0.2,0,0.1,0,0,0.1,0,0,0.2,0,0.1,0,0.1,0,0,0.1,0,0,0.1,0,0,0.1,0,0.2,0.8,0,0.1,0,0,1210.6

  def parse(use_line)
    load_properties(use_line.chomp.split(","))
    self
  end

  def load_properties(u)
    @id = u[0]
    @t_node_id = u[2]
    @channel_id = u[3]
    @multiplier = u[4]
    @op_code = parse_op(u[5])
    @date = parse_date(u[7])
    @validation = determine_valid(u[9])
    @midnight_read = BigDecimal.new(u[59], 4)
    #{id: u[1], final_state: u[3], date: u[4], seg: u[5], use: u[6], tariff_code: u[10] }
    @segments = generate_readings(u, @date)
    puts "===> Stream: id: #{id} t node id: #{t_node_id} channel_id: #{channel_id}"
    # actual_validated
    # actual_unvalidated
    # missing_unvalidated
  end

  def generate_readings(use, date)
    use[11..58].each.with_index.inject([]) {|readings, (use, i)| readings << {segment_pos: {date: date, pos: i, use: BigDecimal.new(use,4)} } }
  end


  def determine_valid(ind)
    case ind
    when "1"
      :valid
    when "0"
      :incomplete
    else
      :invalid
    end
  end

  def extract_meta
    {
      id: @id,
      t_node_id: @t_node_id,
      date: @date,
      op_code: @op_code,
      channel_id: channel_id(),
      validation: @validation,
      midnight_read: @midnight_read

    }
  end

  def parse_op(op)
    op.split('|')
  end


end

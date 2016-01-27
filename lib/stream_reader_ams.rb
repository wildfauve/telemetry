class StreamReaderAms < StreamBase
  
  def initialize
    super
  end
  
  def blockerate(use_line)
    super
  end
  
  
  # 0000032336TR326,11A000061,211035561,MAIN,001,UN24,20151006,P, 000000016827.380, 000000000000.390, 000000000000.305, 000000000000.311, 000000000000.309, 000000000000.318, 000000000000.292, 000000000000.294, 000000000000.318, 000000000000.306, 000000000000.318, 000000000000.294, 000000000000.293, 000000000000.306, 000000000000.308, 000000000000.359, 000000000000.362, 000000000000.352, 000000000000.438, 000000000000.355, 000000000000.341, 000000000000.307, 000000000000.426, 000000000000.429, 000000000000.455, 000000000000.456, 000000000000.454, 000000000000.433, 000000000000.470, 000000000000.462, 000000000000.462, 000000000000.442, 000000000000.533, 000000000000.567, 000000000000.511, 000000000000.490, 000000000000.466, 000000000000.476, 000000000000.362, 000000000000.322, 000000000000.298, 000000000000.407, 000000000000.325, 000000000000.319, 000000000000.326, 000000000000.312, 000000000000.358, 000000000000.389, 000000000000.323,,
  def parse(use_line)
    load_properties(use_line.split(","))
    self
  end
  
  def generate_readings(use, date)
    use[9..56].each.with_index.inject([]) {|readings, (use, i)| readings << {segment_pos: {date: date, pos: i, use: use.to_f} } }
  end
  
  def load_properties(u)
    @id = u[0]
    @t_node_id = u[1]
    @channel_id = u[4]
    @op_code = u[5]
    @date = parse_date(u[6])
    @validation = determine_valid(u[7])
    @midnight_read = u[8].to_f
    #{id: u[1], final_state: u[3], date: u[4], seg: u[5], use: u[6], tariff_code: u[10] }
    @segments = generate_readings(u, @date)
  end
  
  
  def determine_valid(ind)
    case ind
    when "P"
      :valid
    when "F"
      :invalid
    when "N"
      :incomplete
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
  
    
  
end
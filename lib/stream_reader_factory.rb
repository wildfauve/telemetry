class StreamReaderFactory
  
  class << self
    def get_reader(hrd)
      stream_reader(get_stream_type(paramise(hrd)))
    end
  
    def paramise(hrd)
      hrd.downcase.chomp.split(",")
    end
  
    def get_stream_type(items)
      if items[0] == "herm"
        :ams
      elsif items[2] == "arcs"
        :arc
      else
        raise
      end
    end
  
    def stream_reader(stream_type)
      case stream_type
      when :ams
        StreamReaderAms.new
      when :arc
        StreamReaderArc.new
      else
        raise
      end
    end
    
  end
  
  
end
class Segment

  attr_accessor :digest, :state, :time, :use


  def make(seg)
    update_seg(seg)
  end

  def update_seg(seg)
    @time = seg[:time]
    @digest = seg[:digest]
    @use = seg[:use]
    @state = determine_state(@use)
  end


  def determine_state(use)
    case use
    when use == 0
      :estimate
    else
      :actual
    end
  end

  def interval_time
    Time.at(t).utc.strftime("%H:%M:%S")
  end

end

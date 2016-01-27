class Telemetry

  include Celluloid

  attr_accessor :segs, :device_config

  def initialize
    @interval = 30
  end

  def write_telemetry(device_config, stream)
    @device_config = device_config
    @segs = create_segments(stream)
    TelemetryModel.new.update_segs(self)
    self
  end

  def create_segments(stream)
    stream.segments.inject([]) {|i, seg| i << make_seg(seg)}
  end

  def get_seg(seg)
    seg = @segs.find {|s| s.digest == seg_digest(seg[:time])}
    if !seg
      seg = Segment.new
      @segs << seg
    end
    seg
  end

  def make_seg(seg)
    started_at = to_datetime(seg[:segment_pos])
    ended_at = started_at + (60 * 30 - 1)
    {
      state: :final,
      started_at: started_at.utc,
      ended_at: ended_at.utc,
      digest: seg_digest(started_at, ended_at),
      use: seg[:segment_pos][:use]
    }
  end

  def to_datetime(pos)
    pos[:date].utc + interval_to_seconds(pos[:pos], @interval)
  end


  def interval_to_seconds(pos, interval)
    interval * pos * 60
  end

  def seg_digest(started, ended)
    #Digest::SHA1.hexdigest(started.to_s + ended.to_s)
  end

  def write_point(segment)
    DB.write_point("use", point_data(segment))
  end


end

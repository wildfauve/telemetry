class Telemetry

  #include Celluloid

  attr_accessor :segs, :device_config, :model

  def initialize
    @interval = 30
  end

  def write_telemetry(device_config, stream)
    @device_config = device_config
    self.per_day(create_segments(stream).collect {|m| to_measure(m)}).each {|day| find_or_update(day)}
    @model
  end

  def find_or_update(day_segments)
    @model = TelemetryModel.find({telemetry_id: @device_config.telemetry_id, channel_id: @device_config.channel.id, day: day_segments.first[:day]})
    if @model.new?
      init_params(@model, @device_config, day_segments)
      @model.insert()
    else
      fix_utc_bollocks(@model)
      update_seg_day(@model, day_segments)
    end
  end

  def init_params(m, device_config, segments)
    m.telemetry_id = device_config.telemetry_id
    m.channel_id = device_config.channel.id
    m.day = segments.first[:day]
    m.measurements = segments.inject({}) { |udts, segment|
      udts[segment[:started_at]] = Cassandra::UDT.new({started_at: segment[:started_at], ended_at: segment[:ended_at], read: segment[:value], state: "final"}); udts
    }
  end

  def update_params(model, device_config, segments)
    segments.each do |seg|
      if model.measurements.has_key?(seg.started_at)
        if seg.value != model.measurements[seg.started_at].read
          model.measurements[seg.started_at].read = seg.value
        end
      else
        model.measurements[seg.started_at] = Cassandra::UDT.new({started_at: seg.started_at, ended_at: seg.ended_at, read: seg.value, state: "final"})
      end
    end
  end

  def update_seg_day(model, day_segments)
    if !segment_same(model, day_segments)
      update_params(model, @device_config, day_segments)
      model.update
    end
  end

  def segment_same(model, day_segments)
    day_segments.all? do |seg|
      if model.measurements.has_key?(seg.started_at)
        seg.value == model.measurements[seg.started_at].read ? true : false
      else
        false
      end
    end
  end

  def create_segments(stream)
    stream.segments.inject([]) {|i, seg| i << make_seg(seg)}
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

  def to_measure(seg)
    m = Struct::Measurement.new
    m.started_at = to_time(seg[:started_at])
    m.ended_at = to_time(seg[:ended_at])
    m.value = seg[:use]
    m.day = day_from_time(m.started_at)
    m
  end

  def per_day(measures)
    days = measures.map(&:day).uniq!
    d = days.inject([]) {|i, day| i << measures.select {|d| d.day == day}; i}
  end

  def day_from_time(time)
    Time.new(time.year, time.month, time.day, 0,0,0,"+00:00").utc
  end

  def to_time(t)
    t.class == Time ? t : Time.parse(t)
  end

  def fix_utc_bollocks(model)
    model.measurements.keys.each {|k| k.gmtime}
    model.measurements.each {|k,v| v.started_at.gmtime}
    model.measurements.each {|k,v| v.ended_at.gmtime}
  end



end

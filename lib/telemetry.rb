class Telemetry

  Struct.new("Measurement", :started_at, :ended_at, :value, :unit_code, :state, :day)

  #include Celluloid

  attr_accessor :segs, :device_config, :model

  def initialize
    @interval = 30
  end

  def write_telemetry(device_config, stream)
    @device_config = device_config
    self.per_day(create_segments(stream).collect {|m| to_measure(m)}).each {|day| find_or_update(day)}
    self
  end

  def find_or_update(day_segments)
    @model = TelemetryModel.find({telemetry_id: @device_config.telemetry_id, channel_id: @device_config.channel.id, day: day_segments.first[:day]})
    if @model.new?
      init_params(@model, @device_config, day_segments)
      @model.insert()
    else
      update_seg_day(@model, day_segments)
    end
  end

  def init_params(m, device_config, segments)
    m.telemetry_id = device_config.telemetry_id
    m.channel_id = device_config.channel.id
    m.day = segments.first[:day]
    m.measurements = segments.inject({}) { |udts, segment|
      udts[segment[:started_at]] = create_segment(segment)
      udts
    }
  end

  def create_segment(segment)
    version_type = Cassandra::UDT.new({created_at: Time.now.utc.iso8601, read: segment[:value], op: "inc", op_value: segment[:value], state: "final" })
    version_set = Set.new([version_type])
    Cassandra::UDT.new({started_at: segment[:started_at], ended_at: segment[:ended_at], readings: version_set})
  end

  def update_seg_day(model, day_segments)
    day_segments.each do |seg|
      if model.measurements.has_key?(seg.started_at)
        model.measurements[seg.started_at].readings.add determine_change(seg, model.measurements[seg.started_at].readings)
      else
        model.measurements[seg.started_at] = create_segment(seg)
      end
    end
    model.update
  end

  def determine_change(seg, versions)
    last = versions.sort {|a,b| a.created_at <=> b.created_at}.last
    ops = op(last.read, seg.value)
    Cassandra::UDT.new({created_at: Time.now.utc.iso8601, read: seg.value, op: ops[:op], op_value: ops[:op_value], state: "final" })
  end

  def op(version_a, version_b)
    if version_b >= version_a
      {op: "inc", op_value: version_b - version_a}
    else
      {op: "dec", op_value: version_a - version_b}
    end
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
      started_at: iso_utc_time(started_at),
      ended_at: iso_utc_time(ended_at),
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
    m.started_at = seg[:started_at]
    m.ended_at = seg[:ended_at]
    m.value = seg[:use]
    m.day = day_from_time(m.started_at)
    m
  end

  def per_day(measures)
    days = measures.map(&:day).uniq!
    d = days.inject([]) {|i, day| i << measures.select {|d| d.day == day}; i}
    d
  end

  def day_from_time(time)
    #Time.new(time.year, time.month, time.day, 0,0,0,"+00:00").utc
    time[0..9]
  end

  def iso_utc_time(time)
    to_time(time).utc.iso8601
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

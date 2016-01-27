class DataStream

  def generate(telemetry)
    stream = {}
    stream = build_headers(stream, telemetry.device_config)
    stream = add_measures(stream, telemetry.segs)
    KafkaAdapter.new.send(stream)
  end

  def build_headers(stream, device_config)
    stream.merge!({
      kind: "telemetry_measurements",
      telemetry_device_id: device_config.id,
      id: device_config.channel.id
    })
    stream
  end

  def add_measures(stream, segs)
    stream[:measurements] = []
    segs.each {|seg| stream[:measurements] << build_measure(seg)}
    stream
  end

  def build_measure(seg)
    {
      started_at: seg[:started_at],
      ended_at: seg[:ended_at],
      value: seg[:use],
      unit_code: "KWH",
      state: seg[:state]
    }
  end

end

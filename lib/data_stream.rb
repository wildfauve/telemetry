class DataStream

  def generate(telemetry)
    stream = {}
    binding.pry
    stream = build_headers(stream, telemetry.device_config)
    stream = add_measures(stream, telemetry.segs)
    puts "device: #{stream[:telemetry_device_id]}, Channel: #{stream[:id]}, readings: #{stream[:measurements].inspect}}"
    KafkaAdapter.new.send(stream)
  end

  def build_headers(stream, device_config)
    stream.merge!({
      kind: "telemetry_measurements",
      telemetry_device_id: device_config.telemetry_id,
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

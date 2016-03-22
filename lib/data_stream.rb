class DataStream

  def generate(telemetry)
    stream = {}
    stream = build_headers(stream, telemetry)
    stream = add_measures(stream, telemetry.measurements)
    #puts "device: #{stream[:telemetry_device_id]}, Channel: #{stream[:id]}, readings: #{stream[:measurements].inspect}}"
    binding.pry
    KafkaPort.new.publish(stream)
  end

  def build_headers(stream, telemetry)
    stream.merge!({
      kind: "telemetry_measurements",
      id: SecureRandom.uuid,
      equipment_id: telemetry.telemetry_id,
      telemetry_device_id: telemetry.channel_id
    })
    stream
  end

  def add_measures(stream, measurements)
    stream[:measurements] = []
    measurements.each {|start, measure| stream[:measurements] << build_measure(measure)}
    stream
  end

  def build_measure(seg)
    # The reading that needs to be published is that with the latest created_at time.
    sorted = seg.readings.sort {|a, b| b.created_at <=> a.created_at}
    this_reading = sorted[0]
    {
      started_at: seg.started_at,
      ended_at: seg.ended_at,
      value: this_reading.read.to_f,
      unit_code: "KWH",
      state: this_reading.state,
      op: {
        op_code: this_reading.op,
        op_value: this_reading.op_value
      }
    }
  end

end

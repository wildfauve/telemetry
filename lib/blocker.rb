class Blocker

  attr_accessor :nodes
  def initialize(writer)
    @nodes = []
    @futures = []
    @writer = writer
    @log = []
  end

  def process_stream(reader,use_line)
    stream = reader.read(use_line)
    device_config = DeviceRegistry.register(DeviceConfig.new.build_meta(stream))
    tel = Telemetry.new.write_telemetry(device_config, stream)
    if @log.none? {|t| t.model.telemetry_id == tel.model.telemetry_id && t.model.channel_id == tel.model.channel_id}
      @log << tel
    end
    #@futures << Telemetry.new.future.write_telemetry(device_config, stream)
    #writer.generate(telemetry)
  end

  def write
    #v = @futures.first.value
    @log.each do |tel|
      day_model = TelemetryDayModel.find({telemetry_id: tel.model.telemetry_id, channel_id: tel.model.channel_id})
      day_model.days.each do |day|
        telemetry = TelemetryModel.find({telemetry_id: tel.model.telemetry_id, channel_id: tel.model.channel_id, day: day})
        @writer.generate telemetry
      end
    end
  end



end

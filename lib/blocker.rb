class Blocker

  attr_accessor :nodes
  def initialize(writer)
    @nodes = []
    @futures = []
    @writer = writer
  end

  def process_stream(reader,use_line)
    stream = reader.read(use_line)
    device_config = DeviceRegistry.register(DeviceConfig.new.build_meta(stream))
    @futures << Telemetry.new.future.write_telemetry(device_config, stream)
    #@futures << Telemetry.new.write_telemetry(device_config, stream)
    #binding.pry
    #writer.generate(telemetry)
  end

  def write
    binding.pry
    v = @futures.first.value
    @writer.generate v
    binding.pry
  end



end

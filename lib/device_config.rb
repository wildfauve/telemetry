class DeviceConfig

  attr_accessor :telemetry_id, :meta_channel_id, :op_code, :meta_id, :channel

  def initialize
    @channels = []
  end

  def build_meta(stream)
    @icp_id = stream.id
    @meta_id = stream.t_node_id
    @meta_channel_id = stream.channel_id
    @op_code = stream.op_code
    self
  end

  def build(reg_device)
    reg_device ? @telemetry_id = reg_device[:telemetry_id] : @telemetry_id = SecureRandom.uuid
    add_channel(reg_device)
    self
  end

  def add_channel(reg_device)
    inject_channels(reg_device) if reg_device
    @channel = Channel.new(@meta_channel_id, @op_code, nil)
    ch = @channels.find {|c| c.meta_id == channel.meta_id}
    ch ? @channel.id = ch.id : @channels << @channel
  end

  def inject_channels(reg_device)
    reg_device[:channels].inject(@channels) {|c, reg| c << Channel.new(reg[:meta_id], reg[:op_code], reg[:id]); c}
  end

  def to_h
    {
      telemetry_id: @telemetry_id,
      icp_id: @icp_id,
      meta_id: @meta_id,
      channels: @channels.map(&:to_h)
    }
  end

  def update
    binding.pry
  end

end

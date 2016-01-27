class Channel

  attr_accessor :id, :meta_id

  def initialize(meta_channel_id, op_code, id)
    @op_code = op_code
    @meta_id = meta_channel_id
    id ? @id = id : @id = SecureRandom.uuid
  end

  def to_h
    {
      op_code: @op_code,
      meta_id: @meta_id,
      id: @id
    }
  end
end

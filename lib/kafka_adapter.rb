class KafkaAdapter

  def initialize
=begin
    WaterDrop.setup do |config|
      config.send_messages = true
      config.connection_pool_size = 20
      config.connection_pool_timeout = 1
      config.kafka_hosts = ['localhost:9092']
      config.raise_on_failure = true
    end
=end
    @topic = "telemetry"
  end

  def send(msg)
    message = WaterDrop::Message.new(@topic, JSON.generate(msg))
    message.send!
  end

end

require 'pry'
require 'digest'
require 'json'
require 'time'
require 'cassandra'
require 'securerandom'
require 'mongo'
require 'celluloid'
require 'bigdecimal'
#require 'iso8601'
#require 'influxdb'
require 'waterdrop'
#require 'uuid'

$cluster = ::Cassandra.cluster
$session = $cluster.connect('telemetry')

$mongo = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'telemetry')

WaterDrop.setup do |config|
  config.send_messages = true
  config.connection_pool_size = 20
  config.connection_pool_timeout = 1
  config.kafka_hosts = ['localhost:9092']
  config.raise_on_failure = true
end


Struct.new("Measurement", :started_at, :ended_at, :value, :unit_code, :state, :day)

Dir["#{Dir.pwd}/lib/*.rb"].each {|file| require file }

telemetry = Blocker.new(DataStream.new)

Dir["data/*.csv"].each do |file|
  use_file = File.open(file)
  puts "====File: #{file}"
  stream_reader = StreamReaderFactory.get_reader(use_file.readline)
  use_file.readlines.each do |line|
    telemetry.process_stream(stream_reader, line)
  end
  telemetry.write
end

telemetry.nodes.map {|n| [n.id, n.days.map {|d| [d.day, d.t_nodes.count]}]}

telemetry.nodes.each {|n| n.days.each {|d| d.t_nodes.each {|t| t.channels.map {|c| [c.id, c.segs.count]}}}}


=begin

select coal from generation
select coal from generation where time > now() - 2h
select stddev(coal) from generation
select DERIVATIVE(coal) from generation

select usage from use where block_id = '0000000005TR971'

select mean(usage) from use where block_id = '0000000005TR971'


=end

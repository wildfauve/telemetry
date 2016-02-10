require 'pry'

class CrdtPn

  attr_accessor :total
  def initialize
    @total = 0
  end

  def process(msg)
    case msg[:op]
    when :p
      @total += msg[:diff]
    when :n
      @total -= msg[:diff]
    else
      raise
    end
  end

end

class Telemetry
  attr_accessor :interval, :current_state, :crdt

  def initialize
    @interval = 0
    @current_state = :none
    @crdt = CrdtPn.new
  end

  def record(readings)
    puts "Order: #{readings}"
    readings.each {|reading| best_reading(reading)}
    self
  end

  def best_reading(reading)
    # the "better reading test"
    state = reading[:state]
    read = reading[:read]
    #puts "Start===>   Interval: #{@interval} Current State: #{@current_state}, Read: #{read}, State: #{state} "
    if state == :estimate
      if [:none].include? current_state
        msg = update_interval(state, read)
      else
        #puts "didnt process reading"
      end
    elsif state == :update
      if [:none, :estimate].include? current_state
        msg = update_interval(state, read)
      else
        #puts "didnt process reading"
      end
    elsif state == :final
      if ![:final].include? current_state
        msg = update_interval(state, read)
      else
        #puts "didnt process reading"
      end
    else
      raise
    end
    #puts "PN Message: #{msg}"
    @crdt.process(msg) if msg
  end

  def update_interval(state, read)
    @current_state = state
    msg = diff(@interval, read)
    @interval = read
    msg
  end

  def diff(interval, read)
    diff = read - interval
    if diff < 0
      {diff: diff.abs, op: :n}
    else
      {diff: diff.abs, op: :p}
    end
  end


end

reads = []
#(1..4).each {|i| reads << BigDecimal.new(Random.new(1).rand,6) }
reads = [ {read: 1, state: :estimate},
          {read: 2, state: :update},
          {read: 4, state: :update},
          {read: 3, state: :final}
        ]
#total_reads = reads.inject(BigDecimal.new(0, 6)) {|total, read| total += read}
final_read = reads.last
#puts "Final Read: #{final_read[:read]}"


(1..100).each do |i|
  t = Telemetry.new.record(reads.shuffle)
  puts "Finish===>   Interval: #{t.interval} Current State: #{t.current_state} CRDT: #{t.crdt.total}"
  puts "Match: #{t.interval == t.crdt.total}"
end

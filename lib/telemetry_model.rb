class TelemetryModel
=begin

CREATE KEYSPACE Telemetry
  WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };

CREATE TYPE telemetry.measurement (
      started_at timestamp,
      ended_at timestamp,
      read decimal,
      state text
  );

CREATE TABLE telemetry_measures (
  telemetry_id text,
  channel_id text,
  day timestamp,
  measurements map<timestamp, frozen<measurement>>,
  PRIMARY KEY (telemetry_id, channel_id, day)
);
=end

  include Kaftan

  table :telemetry_measures, in_keyspace: :telemetry

  field :telemetry_id, type: :text, key: true
  field :channel_id, type: :text, key: true
  field :day, type: :time, with: :day_from_time, key: true
  field :measurements, type: :map, member_type: :udt

  after_save :manage_telemetry_day

  build_default_prepares

=begin
  prepare :insert_measures, "INSERT INTO telemetry_measures (telemetry_id, channel_id, day, measure)" \
                            "VALUES (:telemetry_id, :channel_id, :day, :measure)"

  prepare :update_set_item, "UPDATE telemetry_measures SET measure[?] = ? WHERE telemetry_id = ? AND channel_id = ? AND day = ?"

  prepare :add_set_item, "UPDATE telemetry_measures SET measure = measure + ? WHERE telemetry_id = ? AND channel_id = ? AND day = ?"
=end

  def initialize
  end

  def update_segs(telemetry)
    telemetry.segs.each do |seg|
      # TODO: cache the measure days
      measure_day = find_measures(telemetry, seg)
      if measure_day
        update_measure_set(measure_day, seg)
      else
        create_measures(telemetry, seg)
        manage_telemetry_day(telemetry, seg)
      end
    end
  end

  def manage_telemetry_day
    day_model = TelemetryDayModel.find({telemetry_id: self.telemetry_id, channel_id: self.channel_id})
    if day_model.new?
      TelemetryDayModel.new.create_params(self)
    else
      day_model.update_params(self)
    end

  end

  def find_measures(telemetry, seg)
    m = $session.execute(TelemetryModel.statement(:find_measures), arguments: [telemetry.device_config.telemetry_id, telemetry.device_config.channel.id , day_from_seg(seg)])
    raise if m.rows.size > 1
    m.rows.size == 1 ? m.rows.first : nil
  end

  def update_measure_set(record, seg)
    record["measure"].keys.include?(seg[:started_at]) ? update_set_item(record, seg) : add_set_item(record, seg)
  end

  def update_set_item(record, seg)
    m = $session.execute(TelemetryModel.statement(:update_set_item),
                        arguments: [ seg[:started_at],
                          measure_udt(seg),
                          record["telemetry_id"],
                          record["channel_id"],
                          record["day"]
                                  ]
                        )
  end

  def add_set_item(record, seg)
    m = $session.execute(TelemetryModel.statement(:add_set_item),
                          arguments: [ {seg[:started_at] => measure_udt(seg) },
                                    record["telemetry_id"],
                                    record["channel_id"],
                                    record["day"]
                                     ]
                        )
  end

  def create_measures(telemetry, seg)
    sd = seg[:started_at]
    m = $session.execute(TelemetryModel.statement(:insert_measures),
                          arguments: {telemetry_id: telemetry.device_config.telemetry_id,
                                      channel_id: telemetry.device_config.channel.id,
                                      day: day_from_seg(seg),
                                      measure: {sd => measure_udt(seg) } } )
  end

  def day_from_seg(seg)
    t = seg[:started_at]
    Time.new(t.year, t.month, t.day, 0,0,0,"+00:00")
  end

  def measure_udt(seg)
    raise if seg[:use].class != BigDecimal
    Cassandra::UDT.new({started_at: seg[:started_at], ended_at: seg[:ended_at], read: seg[:use], state: "final"})
  end

end

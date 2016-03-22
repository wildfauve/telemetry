class TelemetryModel
=begin

CREATE KEYSPACE Telemetry
  WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };


CREATE TYPE telemetry.measurement (
      started_at text,
      ended_at text,
      readings set<frozen<read_version>>
  );

CREATE TYPE telemetry.read_version (
      created_at text,
      read decimal,
      op text,
      op_value decimal,
      state text
  );


CREATE TABLE telemetry_measures (
  telemetry_id text,
  channel_id text,
  day text,
  measurements map<text, frozen<measurement>>,
  PRIMARY KEY (telemetry_id, channel_id, day)
);
=end

  include Kaftan

  table :telemetry_measures, in_keyspace: :telemetry

  field :telemetry_id, type: :text, key: true
  field :channel_id, type: :text, key: true
  field :day, type: :text, key: true
  field :measurements, type: :map, member_type: :udt

  after_save :manage_telemetry_day

  build_default_prepares


  def initialize
  end

  def manage_telemetry_day
    day_model = TelemetryDayModel.find({telemetry_id: self.telemetry_id, channel_id: self.channel_id})
    if day_model.new?
      TelemetryDayModel.new.create_params(self)
    else
      day_model.update_params(self)
    end

  end




end

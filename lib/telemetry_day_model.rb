class TelemetryDayModel
=begin

CREATE TABLE telemetry_days (
  telemetry_id text,
  channel_id text,
  days set<timestamp>,
  PRIMARY KEY (telemetry_id, channel_id)
);
=end

  include Kaftan

  table :telemetry_days, in_keyspace: :telemetry

  field :telemetry_id, type: :text, key: true
  field :channel_id, type: :text, key: true
  field :days, type: :set, member: {}

  build_default_prepares

  def create_params(tel_model)
    self.telemetry_id = tel_model.telemetry_id
    self.channel_id = tel_model.channel_id
    self.days = Set.new([tel_model.day])
    self.insert
  end

  def update_params(tel_model)
    # TODO: strange behaviour of cassandra driver leaves UTC times as NOT UTC
    if !self.days.to_a.map {|t| t.gmtime}.include? tel_model.day  # so if we dont already have the day
      self.days.add tel_model.day
      self.update
    end
  end

end

class DeviceRegistry

  class << self

    include Enumerable

    def each
      @reg.each {|d| yield d}
    end

    def register(device)
      init_registry if !@reg
      find_device(device)
    end

    def init_registry
      @reg = $mongo
    end

    def find_device(device)
      if device.telemetry_id
        reg_device = find(:telemetry_id, device.telemetry_id)
      else
        reg_device = find(:meta_id, device.meta_id)
      end
      reg_device ? update_registry(reg_device, device) : add_to_registry(device)
    end

    def find(prop, value)
      r = @reg[:devices].find(prop => value)
      r.each {|d| puts d["meta_id"]}
      binding.pry if r.count > 1
      r.first
    end

    def add_to_registry(device)
      result = @reg[:devices].insert_one(device.build(nil).to_h)
      binding.pry if !result.successful?
      device
    end

    def update_registry(reg_device, device)
      device.build(reg_device)
      result = reg_device.replace(device.to_h)
      device
    end

  end

end

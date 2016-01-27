class DeviceRegistry

  class << self

    include Enumerable

    def each
      @reg.each {|d| yield d}
    end

    def register(device)
      build_registry if !@reg
      find_device(device)
    end

    def build_registry
      @reg = $mongo
    end

    def find_device(device)
      if device.id
        #reg_device = @reg.find {|d| d.id == device.id}
        reg_device = find(:id, device.id)
      else
        #reg_device = @reg.find {|d| d.meta_id == device.meta_id}
        reg_device = find(:meta_id, device.meta_id)
      end
      reg_device ? update_registry(reg_device, device) : add_to_registry(device)
    end

    def find(prop, value)
      r = @reg[:devices].find(prop => value)
      raise if r.count > 1
      r.first
    end

    def add_to_registry(device)
      #@reg << device.build(device)
      result = @reg[:devices].insert_one(device.build(nil).to_h)
      binding.pry if !result.successful?
      device
    end

    def update_registry(reg_device, device)
      device.build(reg_device)
      result = @reg[:devices].find(id: reg_device[:id]).find_one_and_replace(device.to_h)
      device
    end

  end

end

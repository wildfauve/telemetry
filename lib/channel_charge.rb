class ChannelCharge
  
  attr_accessor :variable_charges
  
  def initialize(channel)
    @content_code = channel["registry_content_code"]
    set_variable_charges(channel["variable_charges"])
  end
  
  def set_variable_charges(variable)
    @variable_charges = []
    variable.each {|chr| @variable_charges << Charge.new(chr)}
  end
  
  
end
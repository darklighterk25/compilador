class Variable

  attr_accessor :lines, :location, :value, :type

  def initialize(location, line, value, type)
    @location, @value, @type = location, value, type
    @lines = []
    @lines.push(line)
  end

end
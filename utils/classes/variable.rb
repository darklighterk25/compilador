class Variable

  attr_reader :location, :type
  attr_accessor :lines, :value, :type

  def initialize(location, line, value, type)
    @location, @value, @type = location, value, type
    @lines = []
    @lines.push(line)
  end

end
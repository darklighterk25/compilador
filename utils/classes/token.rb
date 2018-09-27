class Token

  attr_accessor :type, :lexeme, :range, :location, :style

  def initialize(type, lexeme , range, location, style)
    @type, @lexeme, @range, @location, @style = type, lexeme, range, location, style
  end

  def to_s(error_type = :none)
    case error_type
      when :lexical
        "Lexema \"#{@lexeme}\" no válido [Fila #{@location[:row]}, Columna #{@location[:column]}].\n"
      when :syntactical
        "\n#{@type} [Fila: #{@location[:row]}, Columna: #{@location[:column]}]."
      when :none
        "Tipo: #{@type} | Lexema: #{@lexeme} | Range: #{@range} | Location: #{@location} | Style: #{@style}"
    end
  end

end
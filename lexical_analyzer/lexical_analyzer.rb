require_relative '../utils/modules/files'
require_relative '../utils/classes/token_types'
require_relative '../utils/classes/token'

class LexicalAnalyzer < TokenTypes

  include Files

  attr_reader :errors, :table, :tokens

  # El constructor recibe la tabla del entorno gráfico y define si la clase se correrá o no en modo de prueba.
  def initialize(table = nil, test = false)
    super()
    @iterator = -1
    @table = table
    @test = test
    @STATE_TYPE = {
        addition: 0, assign: 1, cl_brace: 2, cl_comment: 3, cl_parenthesis: 4, colon: 5, comma: 6,
        comment: 7, decrement: 8, division: 9, done: 10, dot: 11, equal: 12, equal_sign: 13, exclamation: 14,
        float: 15, float_ver: 16, greater: 17, greater_equal: 18, identifier: 19, increment: 20,
        integer: 21, less: 22, less_equal: 23, ml_comment: 24, module: 25, multiplication: 26, not_equal: 27,
        op_brace: 28, op_comment: 29, op_parenthesis: 30, semicolon: 31, sl_comment: 32, start: 33,
        string: 34, subtraction: 35
    }
  end

  # El método recibe un string para hacer el análisis léxico y devuelve los tokens en un array.
  def run(string)
    @column = '-' # Inicializa las el conteo de columnas.
    @file = '-' # Inicializa las el conteo de filas.
    @iterator = -1 # Se reinicia el iterador.
    @tokens = [] # Se limpian el array ya que solo existirá una instancia.
    identifier = '' # Guarda el string del identificador.
    string += ' ' # EOF.
    lexeme = ''
    state = @STATE_TYPE[:start]
    token = @TOKEN_TYPE[:eof]
    while (state != @STATE_TYPE[:done]) and (@iterator != string.length-1) do
      character = get_next_char(string)
      case state
        when @STATE_TYPE[:addition]
          if character == '+'
            lexeme += character
            state = @STATE_TYPE[:increment]
            token = @TOKEN_TYPE[:increment]
          else
            state = @STATE_TYPE[:done]
          end
        when @STATE_TYPE[:assign]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:cl_comment]
          if character == '/'
            state = @STATE_TYPE[:ml_comment]
          elsif character != '*' # Si no es asterisco, se vuelve al estado op_comment.
            state = @STATE_TYPE[:op_comment]
          end
          lexeme += character
        when @STATE_TYPE[:cl_brace]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:cl_parenthesis]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:colon]
          if character == '='
            lexeme += character
            state = @STATE_TYPE[:assign]
            token = @TOKEN_TYPE[:assign]
          else
            state = @STATE_TYPE[:done]
            token = @TOKEN_TYPE[:error]
          end
        when @STATE_TYPE[:comma]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:decrement]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:division]
          if character == '*'
            lexeme += character
            state = @STATE_TYPE[:op_comment]
            token = @TOKEN_TYPE[:comment]
          elsif character == '/'
            lexeme += character
            state = @STATE_TYPE[:sl_comment]
            token = @TOKEN_TYPE[:comment]
          else
            state = @STATE_TYPE[:done]
          end
        when @STATE_TYPE[:dot]
          if character.match(/\d/)
            lexeme += character
            state = @STATE_TYPE[:float]
            token = @TOKEN_TYPE[:float]
          else
            state = @STATE_TYPE[:done]
            token = @TOKEN_TYPE[:error]
          end
        when @STATE_TYPE[:equal]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:equal_sign]
          if character == '='
            lexeme += character
            state = @STATE_TYPE[:equal]
            token = @TOKEN_TYPE[:equal]
          else
            state = @STATE_TYPE[:done]
            token = @TOKEN_TYPE[:error]
          end
        when @STATE_TYPE[:exclamation]
          if character == '='
            lexeme += character
            state = @STATE_TYPE[:not_equal]
            token = @TOKEN_TYPE[:not_equal]
          else
            state = @STATE_TYPE[:done]
            token = @TOKEN_TYPE[:error]
          end
        when @STATE_TYPE[:float]
          if character.match(/\d/)
            lexeme += character
          else
            state = @STATE_TYPE[:done]
          end
        when @STATE_TYPE[:float_ver]
          if character.match(/\d/)
            lexeme += character
            state = @STATE_TYPE[:float]
            token = @TOKEN_TYPE[:float]
          else
            state = @STATE_TYPE[:done]
          end
        when @STATE_TYPE[:greater]
          if character != '='
            state = @STATE_TYPE[:done]
          else
            lexeme += character
            state = @STATE_TYPE[:greater_equal]
            token = @TOKEN_TYPE[:greater_equal]
          end
        when @STATE_TYPE[:greater_equal]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:identifier]
          if character.match(/[a-zA-Z]/) or character.match(/\d/) or character == '_'
            identifier += character
            state = @STATE_TYPE[:identifier]
            token = @TOKEN_TYPE[:identifier]
          else
            lexeme = identifier
            identifier = ''
            state = @STATE_TYPE[:done]
          end
        when @STATE_TYPE[:increment]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:integer]
          if character.match(/\d/) # Si es entero.
            lexeme += character
            state = @STATE_TYPE[:integer]
            token = @TOKEN_TYPE[:integer]
          elsif character == '.'
            lexeme += character
            state = @STATE_TYPE[:float_ver]
            token = @TOKEN_TYPE[:error]
          else
            state = @STATE_TYPE[:done]
          end
        when @STATE_TYPE[:less]
          if character == '='
            lexeme += character
            state = @STATE_TYPE[:less_equal]
            token = @TOKEN_TYPE[:less_equal]
          else
            state = @STATE_TYPE[:done]
          end
        when @STATE_TYPE[:less_equal]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:ml_comment]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:module]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:multiplication]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:not_equal]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:op_brace]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:op_comment]
          if character == '*'
            state = @STATE_TYPE[:cl_comment]
          end
          lexeme += character
        when @STATE_TYPE[:op_parenthesis]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:semicolon]
          state = @STATE_TYPE[:done]
        when @STATE_TYPE[:sl_comment]
          if character == "\n" # Cambia de estado hasta que sea un enter.
            state = @STATE_TYPE[:done]
            token = @TOKEN_TYPE[:comment]
          else
            lexeme += character
          end
        when @STATE_TYPE[:start]
          if character.match(/[a-zA-Z]/) # Si es caracter.
            identifier += character
            state = @STATE_TYPE[:identifier]
            token = @TOKEN_TYPE[:identifier]
          elsif character.match(/\d/) # Si es número.
            lexeme += character
            state = @STATE_TYPE[:integer]
            token = @TOKEN_TYPE[:integer]
          else
            case character
              when '%'
                state = @STATE_TYPE[:module]
                token = @TOKEN_TYPE[:module]
              when '*'
                state = @STATE_TYPE[:multiplication]
                token = @TOKEN_TYPE[:multiplication]
              when '('
                state = @STATE_TYPE[:op_parenthesis]
                token = @TOKEN_TYPE[:op_parenthesis]
              when ')'
                state = @STATE_TYPE[:cl_parenthesis]
                token = @TOKEN_TYPE[:cl_parenthesis]
              when '{'
                state = @STATE_TYPE[:op_brace]
                token = @TOKEN_TYPE[:op_brace]
              when '}'
                state = @STATE_TYPE[:cl_brace]
                token = @TOKEN_TYPE[:cl_brace]
              when '/'
                state = @STATE_TYPE[:division]
                token = @TOKEN_TYPE[:division]
              when '<'
                state = @STATE_TYPE[:less]
                token = @TOKEN_TYPE[:less]
              when '>'
                state = @STATE_TYPE[:greater]
                token = @TOKEN_TYPE[:greater]
              when '!'
                state = @STATE_TYPE[:exclamation]
                token = @TOKEN_TYPE[:error]
              when ':'
                state = @STATE_TYPE[:colon]
                token = @TOKEN_TYPE[:error]
              when '='
                state = @STATE_TYPE[:equal_sign]
                token = @TOKEN_TYPE[:error]
              when '-'
                state = @STATE_TYPE[:subtraction]
                token = @TOKEN_TYPE[:subtraction]
              when '+'
                state = @STATE_TYPE[:addition]
                token = @TOKEN_TYPE[:addition]
              when '"'
                state = @STATE_TYPE[:string]
                token = @TOKEN_TYPE[:error]
              when ','
                state = @STATE_TYPE[:comma]
                token = @TOKEN_TYPE[:comma]
              when ';'
                state = @STATE_TYPE[:semicolon]
                token = @TOKEN_TYPE[:semicolon]
              when '.'
                state = @STATE_TYPE[:dot]
                token = @TOKEN_TYPE[:error]
              else
                unless character == ' ' or character.include? "\n" or character.include? "\t" # Caracter vacío.
                  state = @STATE_TYPE[:start]
                  token = @TOKEN_TYPE[:error]
                end
            end
            unless state == @STATE_TYPE[:start]
              lexeme += character
            end
          end
        when @STATE_TYPE[:subtraction]
          if character == '-'
            lexeme += character
            state = @STATE_TYPE[:decrement]
            token = @TOKEN_TYPE[:decrement]
          else
            state = @STATE_TYPE[:done]
          end
        when @STATE_TYPE[:string]
          lexeme += character
          if character == '"'
            state = @STATE_TYPE[:done]
            token = @TOKEN_TYPE[:string]
            character = get_next_char(string)
          end
        else
          # Estado inexistente
      end
      if @RESERVED_WORDS.include? identifier # Verifica si es una palabra reservada.
        character = get_next_char(string)
        if character == ' ' or character == "\n" or character == '(' or character == '{'
          lexeme = identifier
          identifier = ''
          aux = "rw_#{lexeme}" # Concatemanos el nombre de la llave.
          token = @TOKEN_TYPE[aux.to_sym] # Convertimos el string en símbolo para acceder al tipo correspondiente.
          state = @STATE_TYPE[:done]
        else
          character = unget_char(string) # Si no es una palabra regresa al caracter en cuestion.
        end
      end
      if state == @STATE_TYPE[:done] # Estado final. Se ingresan los resultados al array y se reincian las variables.
        style = get_token_style(token)
        @tokens.push( Token.new(token, lexeme, {start: @iterator - lexeme.length, end: @iterator},
                                {file: @file, column: @column}, style) )
        character = unget_char(string)
        @column = '-'
        lexeme = ''
        state = @STATE_TYPE[:start]
        token = @TOKEN_TYPE[:eof]
      end
    end
    @tokens.push(Token.new(@TOKEN_TYPE[:eof], '', {start: @iterator, end: @iterator}, {file: @file, column: @column},
                           @TOKEN_STYLE[:eof])) # Token EOF.
    tokens, @errors = to_s
    if @test # Si se ejecuta en modo prueba generamos los archivos.
      save_file("files/tokens.txt", tokens)
      save_file("files/errors.txt", @errors)
    else # De lo contrario, generamos la tabla.
      generate_table
    end
  end

  # Genera la tabla para el entorno gráfico.
  private
  def generate_table
    @table.setTableSize(@tokens.length, 3)
    @tokens.each_with_index { | token, index |
      @table.setRowText(index, token.type)
      @table.setItemText(index, 0, token.lexeme)
      @table.setItemText(index, 1, token.location[:file].to_s)
      @table.setItemText(index, 2, token.location[:column].to_s)
      @table.setItemJustify(index, 1, FXTableItem::CENTER_X|FXTableItem::CENTER_Y)
      @table.setItemJustify(index, 2, FXTableItem::CENTER_X|FXTableItem::CENTER_Y)
    }
    @table.setColumnWidth(0, 192)
    @table.setColumnWidth(1, 15)
    @table.setColumnWidth(2, 15)
    @table.setColumnText(0, "Lexema")
    @table.setColumnText(1, 'F')
    @table.setColumnText(2, 'C')
  end

  # El método recibe un string y nos da el caracter anterior.
  private
  def get_next_char(string)
    @iterator += 1
    string[@iterator]
  end

  # Convierte el array de tokens en un array que contiene las cadenas de texto de tokens y errores.
  def to_s
    tokens = ''
    errors = ''
    header = false
    @tokens.each do | x |
      if x.type == @TOKEN_TYPE[:error]
        unless header # Se concatena el encabezado en la primer iteración.
          errors += "Errores léxicos:\n\n"
          header = true
        end
        errors += x.to_s(:lexical)
      else
        tokens += x.to_s
      end
    end
    return tokens, errors
  end

  # El método recibe un string y nos da el caracter anterior.
  private
  def unget_char(string)
    @iterator -= 1
    string[@iterator]
  end

end
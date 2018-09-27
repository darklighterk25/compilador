require_relative '../utils/classes/node'
require_relative '../utils/classes/token'
require_relative '../utils/classes/token_types'
require_relative '../utils/classes/variable'

class SemanticAnalyzer < TokenTypes

  attr_reader :errors, :hash_table, :tree_list

  def initialize(syntax_tree, tree_list, table)
    super()
    @errors = "Errores semánticos: \n" # En caso de que haya error, se concatenará en esta variable.
    @hash_table = { }
    @location = 0 # Simula direcciones de memoria.
    @syntax_tree = syntax_tree
    @table = table # Tabla del entorno gráfico.
    @tree_list = tree_list
    run
  end

  # Genera la tabla para el entorno gráfico.
  private
  def generate_table
    @table.setTableSize(@hash_table.length, 5)
    @table.setColumnWidth(0, 50)
    @table.setColumnWidth(1, 50)
    @table.setColumnWidth(2, 50)
    @table.setColumnWidth(3, 50)
    @table.setColumnWidth(4, 50)
    @table.setColumnText(0, "Nombre de la variable")
    @table.setColumnText(1, "Localidad")
    @table.setColumnText(2, "Línea")
    @table.setColumnText(3, "Valor")
    @table.setColumnText(4, "Tipo")
    @hash_table.each_with_index do | (key, variable), index | # Iteramos el hash para fijar valores en la tabla.
      @table.setItemText(index, 0, key.to_s) # Nombre de la variable.
      @table.setItemText(index, 1, variable.location) # Localidad.
      lines = ""
      variable.lines.each do | line | # Iteramos todas las lìneas.
        lines += " #{line}," # Y concatenamos.
      end
      lines.chop! # Remueve el último caracter (que siempre es una coma).
      @table.setItemText(index, 2, lines) # Fijamos el valor concatenado.
      @table.setItemText(index, 3, variable.value) # Valor.
      @table.setItemText(index, 4, variable.type) # Tipo.
    end
  end

  # Genera el árbol desplegable para el entorno gráfico.
  private
  def generate_tree(node, parent)
    content = "#{node.token.lexeme} (#{node.value})"
    aux = @tree_list.appendItem(parent, content) # El árbol semántico imprime el valor.
    @tree_list.expandTree(aux) # Expande el elemento.
    siblings = node.children
    siblings.each do | node |
      generate_tree(node, aux)
    end
  end

  # Inserta una variable nueva en la tabla hash.
  private
  def insert_variable(lexeme, variable)
    key = lexeme.to_sym
    @hash_table[key] = variable
  end

  # Actualiza los valores de una variable ya existente en la tabla hash.
  private
  def update_variable(lexeme, line, value)
    key = lexeme.to_sym
    @hash_table[key].lines.push(line)
    @hash_table[key].value = value
  end

  private
  def run
    generate_tree(@syntax_tree, @tree_list)
    generate_table
  end

  # Verifica si una tabla ya existe en la tabla hash.
  private
  def variable_exists?(lexeme)
    key = lexeme.to_sym
    return @hash_table.has_key? key
  end

end
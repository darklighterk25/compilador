require_relative 'semantic_rules'
require_relative '../utils/classes/node'
require_relative '../utils/classes/token'
require_relative '../utils/classes/token_types'
require_relative '../utils/classes/variable'

class SemanticAnalyzer < TokenTypes

  include SemanticRules
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

  # Inicia el análisis semántico
  private
  def run
    build_symtab # Construye e inicializa la tabla de símbolos
    check_type(@syntax_tree) # Establece el tipo de dato de las variables
    evaluate_tree(@syntax_tree) # Recorrido en orden del arbol para evaluar los nodos y detectar errores
    generate_tree(@syntax_tree, nil) # Genera el árbol gráfico.
    generate_table # Genera la tabla para el entorno gráfico.
  end

  # Construye la tabla de simbolos mediante un recorrido en pre-orden
  private
  def build_symtab
    pre_order(@syntax_tree)
  end

  # Recorrido en pre-orden para el arbol semantico
  private
  def pre_order(t)
    insert_node(t)
    children = t.children
    children.each do |child|
      pre_order(child)
    end
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
      @table.setItemText(index, 1, variable.location.to_s) # Localidad.
      lines = ""
      variable.lines.each do | line | # Iteramos todas las lìneas.
        lines += " #{line}," # Y concatenamos.
      end
      lines.chop! # Remueve el último caracter (que siempre es una coma).
      @table.setItemText(index, 2, lines.to_s) # Fijamos el valor concatenado.
      @table.setItemText(index, 3, variable.value.to_s) # Valor.
      @table.setItemText(index, 4, variable.type.to_s) # Tipo.
    end
  end

  # Genera el árbol desplegable para el entorno gráfico.
  private
  def generate_tree(node, parent)
    content = "#{node.token.lexeme}"
    if(node.kind.eql?("opK") || node.kind.eql?("idK"))
      content += " (#{node.value})"
    end
    aux = @tree_list.appendItem(parent, content) # El árbol semántico imprime el valor.
    @tree_list.expandTree(aux) # Expande el elemento.
    siblings = node.children
    siblings.each do | node |
      generate_tree(node, aux)
    end
  end

  # Cambia el tipo de dato de una variable
  private
  def set_type(lexeme, type)
    key = lexeme.to_sym
    @hash_table[key].type = type
  end

  # Regresa el tipo de dato de una variable
  private
  def get_type(lexeme)
    key = lexeme.to_sym
    @hash_table[key].type
  end

  # Cambia el valor de una variable
  private
  def set_value(lexeme, value)
    key = lexeme.to_sym
    @hash_table[key].value = value
  end

  # Regresa el valor de una variable
  private
  def get_value(lexeme)
    key = lexeme.to_sym
    @hash_table[key].value
  end

  # Inserta una variable nueva en la tabla hash.
  private
  def insert_variable(lexeme, variable)
    key = lexeme.to_sym
    @hash_table[key] = variable
    @location += 1
  end

  # Actualiza los valores de una variable ya existente en la tabla hash.
  private
  def update_variable(lexeme, line, value)
    key = lexeme.to_sym
    @hash_table[key].lines.push(line)
    @hash_table[key].value = value
  end

  # Verifica si una variable ya existe en la tabla hash.
  private
  def variable_exists?(lexeme)
    key = lexeme.to_sym
    return @hash_table.has_key? key
  end

  # Cadena de errores semanticos
  private
  def error(msj)
    @errors +=  msj
  end

  # Inserta los identificadores almacenados en t dentro de la tabla de simbolos
  private
  def insert_node(t)
    case t.nodekind
    when "identifier"
      if (variable_exists?(t.token.lexeme))
        msj = "La variable #{t.token.lexeme} ya fue declarada con anterioridad\n"
        error(msj)
      else
        insert_variable(t.token.lexeme, Variable.new(@location, t.token.location[:row], t.value, t.type))
      end
    else
      case t.kind
      when "idK"
        if (variable_exists?(t.token.lexeme))
          update_variable(t.token.lexeme, t.token.location[:row], t.value)
        else
          msj = "La variable #{t.token.lexeme} no existe\n"
          error(msj)
        end
      end
    end
  end

end
require_relative 'semantic_rules'
require_relative '../utils/classes/node'
require_relative '../utils/classes/token'
require_relative '../utils/classes/token_types'
require_relative '../utils/classes/variable'

class SemanticAnalyzer < TokenTypes

  include SemanticRules
  attr_reader :errors_text, :errors, :hash_table, :syntax_tree, :tree_list

  def initialize(syntax_tree, tree_list, table)
    super()
    @errors_text = "Errores semánticos: \n" # En caso de que haya error, se concatenará en esta variable.
    @errors = false
    @hash_table = { }
    @location = 1 # Simula direcciones de memoria.
    @syntax_tree = syntax_tree
    @table = table # Tabla del entorno gráfico.
    @tree_list = tree_list
    run
  end

  # Inicia el análisis semántico
  private
  def run
    @errors = false
    build_symtab(@syntax_tree) # Construye e inicializa la tabla de símbolos
    evaluate_tree(@syntax_tree) # Recorrido en orden del arbol para evaluar los nodos y detectar errores
    generate_tree(@syntax_tree, nil) # Genera el árbol gráfico.
    generate_table # Genera la tabla para el entorno gráfico.
  end

  # Construye la tabla de simbolos mediante un recorrido en pre-orden
  private
  def build_symtab(root)
    children = root.children
    children.each do |child|
      insert_node(child)
    end    
  end

  # Genera la tabla para el entorno gráfico.
  private
  def generate_table
    @table.setTableSize(@hash_table.length, 4)
    @hash_table.each_with_index do | (key, variable), index | # Iteramos el hash para fijar valores en la tabla.
      @table.setRowText(index, key.to_s) # Nombre de la variable.
      @table.setItemText(index, 0, variable.location.to_s) # Localidad.
      lines = ""
      variable.lines.each do | line | # Iteramos todas las lìneas.
        lines += " #{line}," # Y concatenamos.
      end
      lines.chop! # Remueve el último caracter (que siempre es una coma).
      @table.setItemText(index, 1, lines.to_s) # Fijamos el valor conscatenado.
      @table.setItemText(index, 2, variable.value.to_s) # Valor.
      @table.setItemText(index, 3, variable.type.to_s) # Tipo.
      @table.setItemJustify(index, 0, FXTableItem::CENTER_X)
      @table.setItemJustify(index, 1, FXTableItem::LEFT)
      @table.setItemJustify(index, 2, FXTableItem::LEFT)
      @table.setItemJustify(index, 3, FXTableItem::LEFT)
    end
    @table.setColumnWidth(0, 70)
    @table.setColumnWidth(1, 400)
    @table.setColumnWidth(2, 200)
    @table.setColumnWidth(3, 50)
    @table.setColumnText(0, "Localidad")
    @table.setColumnText(1, "Línea")
    @table.setColumnText(2, "Valor")
    @table.setColumnText(3, "Tipo")
  end

  # Genera el árbol desplegable para el entorno gráfico.
  private
  def generate_tree(node, parent)
    content = "#{node.token.lexeme}"
    if node.kind.eql?("opK") || node.kind.eql?("idK")
      content += " (#{node.value})"
    end
    aux = @tree_list.appendItem(parent, content) # El árbol semántico imprime el valor.
    @tree_list.expandTree(aux) # Expande el elemento.
    siblings = node.children
    siblings.each do | node |
      generate_tree(node, aux)
    end
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
  def update_variable(lexeme, line)
    key = lexeme.to_sym
    @hash_table[key].lines.push(line)
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
    @errors_text +=  msj
  end

  # Inserta los identificadores declarados en la tabla de simbolos
  private
  def insert_node(t)
    case t.nodekind
    when "declaration"
      identifiers = t.children
      identifiers.each do |id|
        if t.token.lexeme.eql?("integer") || t.token.lexeme.eql?("bool")
            id.value = 0
          else
            id.value = 0.0
          end
        if variable_exists?(id.token.lexeme)
          msj = "[ERROR] '#{id.token.lexeme}' variable was already declared. Line: #{id.token.location[:row]}\n"
          @errors = true
          error(msj)
        else
          new_id = Variable.new(@location, id.token.location[:row], id.value, t.token.lexeme)
          insert_variable(id.token.lexeme, new_id)
        end
      end
    end
  end

end
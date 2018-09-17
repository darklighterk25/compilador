require_relative '../utils/classes/node'
require_relative '../utils/classes/token'
require_relative '../utils/classes/token_types'

class SemanticAnalyzer

  attr_reader :errors

  def initialize(syntax_tree, tree_list, table)
    @errors = "Errores semánticos: \n" # En caso de que haya error, se concatenará en esta variable.
    @table = table
    @syntax_tree = syntax_tree
    @tree_list = tree_list
    run
  end

  # Genera la tabla para el entorno gráfico.
  private
  def generate_table
    @table.setTableSize(0, 5)
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

  private
  def run
    generate_tree(@syntax_tree, @tree_list)
  end

end
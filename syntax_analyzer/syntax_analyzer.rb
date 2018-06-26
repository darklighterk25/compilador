require_relative 'syntax_rules'
require_relative '../utils/classes/node'
require_relative '../utils/classes/token'
require_relative '../utils/classes/token_types'

class SyntaxAnalyzer < TokenTypes

  include SyntaxRules

  attr_reader :errors, :syntax_tree, :tree_list

  # La clase recibe el array de tokens generado por el analizador léxico.
  def initialize(tokens, tree_list)
    super()
    @iterator = -1 # Ubicación del token actual en el array.
    @name = -1 # Cada nodo del árbol debe llamarse diferente.
    @tokens = tokens # Array de tokens proveniente del analizador léxico.
    @token = get_token # Token actual.
    @tree_list = tree_list # Árbol del entorno gráfico.
    @errors = "Errores sintácticos:\n\n" # En caso de que haya error, se concatenará en esta variable.
    run
  end

  # Genera el árbol desplegable para el entorno gráfico.
  private
  def generate_tree(node, parent)
    aux = @tree_list.appendItem(parent, node.content.lexeme)
    @tree_list.expandTree(aux) # Expande el elemento.
    siblings = node.children
    siblings.each do | node |
      generate_tree(node, aux)
    end
  end

  # Nos regresa el siguiente token del array.
  private
  def get_token
    @iterator += 1
    @tokens[@iterator]
  end

  # Verifica que el token actual corresponde con el esperado por la gramática.
  private
  def match(expected)
    if @token.type == expected
      @token = get_token
    else
      syntax_error("Se esperaba: #{expected}.")
    end
  end

  # Genera un nuevo nodo.
  private
  def new_node(kind, token = @token)
    @name += 1
    Node.new(@name.to_s, kind, token)
  end

  # Corre el análisis.
  private
  def run
    @syntax_tree = program # Arranca de la regla gramatical inicial.
    @tree_list.clearItems # Limpia el contenido del árbol desplegable.
    generate_tree(@syntax_tree, nil) # Genera el árbol desplegable.
  end

  # Mantiene registro de todos los errores.
  private
  def syntax_error(expected = '')
    @errors += "#{@token.to_s(:syntax_error)} #{expected}"
  end

  # Retorna el árbol desde la raíz en forma de string.
  private
  def to_s
    @syntax_tree.to_s
  end

end
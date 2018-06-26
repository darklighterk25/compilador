class SemanticAnalyzer

  attr_reader :errors

  def initialize(syntax_tree)
    @errors = "Errores semánticos: \n" # En caso de que haya error, se concatenará en esta variable.
    @syntax_tree = syntax_tree
  end

end
class IntermediateCode

  def initialize(intermediate_code, output, semantic_tree)
    @intermediate_code = intermediate_code
    @output = output
    @semantic_tree = semantic_tree
    @intermediate_code.appendText("Código intermedio\n")
    run
  end

  def run
    @intermediate_code.appendText("")
    @output.appendText("")
  end

end
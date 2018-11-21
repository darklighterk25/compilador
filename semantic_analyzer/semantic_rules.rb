module SemanticRules

  # Evalua las sentencias que son hijos directos del main o que estan en un bloque de sentencias
  def evaluate_tree(t)
    children = t.children
    children.each do |child|
      case child.kind
      when "assignK"
        assign_eval(child)
      when "ifK"
        boolean_eval(child, 0)
        for i in 1..(child.children.length - 1) do
          evaluate_tree(child.children[i])
        end
      when "whileK"
        boolean_eval(child, 0)
        evaluate_tree(child.last_child)
      when "doK"
        evaluate_tree(child.first_child)
        boolean_eval(child, 1)
      when "readK"
        read_eval(child)
      when "writeK"
        write_eval(child)
      else
        evaluate_tree(child)
      end
    end
  end

  # Se usa cuando una expresión solo consta de un identificador
  def just_id(t)
    if t.kind.eql?("idK")
      if variable_exists?(t.token.lexeme)
        t.value = get_value(t.token.lexeme)
        update_variable(t.token.lexeme, t.token.location[:row])
      else
        t.value = "error"
        msj = "[ERROR] '#{identifier.token.lexeme}' variable is not declared. Line: #{identifier.token.location[:row]}\n"
        error(msj)
      end
    else
      post_eval(t)
    end
  end

  # Establece el valor de las expresiones y detecta errores como divisiones entre 0
  def post_eval(t)
    if t.kind.eql?("opK")
      left_operand = t.first_child
      right_operand = t.last_child
      post_eval(left_operand)
      post_eval(right_operand)
      if left_operand.kind.eql?("idK")
        if variable_exists?(left_operand.token.lexeme)
          left_operand.value = get_value(left_operand.token.lexeme)
          update_variable(left_operand.token.lexeme, left_operand.token.location[:row])
        else
          left_operand.value = "error"
          msj = "[ERROR] '#{left_operand.token.lexeme}' variable is not declared. Line: #{left_operand.token.location[:row]}\n"
          error(msj)
        end
      end
      if right_operand.kind.eql?("idK")
        if variable_exists?(right_operand.token.lexeme)
          right_operand.value = get_value(right_operand.token.lexeme)
          update_variable(right_operand.token.lexeme, right_operand.token.location[:row])
        else
          right_operand.value = "error"
          msj = "[ERROR] '#{right_operand.token.lexeme}' variable is not declared. Line: #{right_operand.token.location[:row]}\n"
          error(msj)
        end
      end
      if left_operand.value.eql?("error") || right_operand.value.eql?("error")
        t.value = "error"
      else
        case t.token.lexeme
        when "<="
          t.value = left_operand.value <= right_operand.value
        when "<"
          t.value = left_operand.value < right_operand.value
        when ">"
          t.value = left_operand.value > right_operand.value
        when ">="
          t.value = left_operand.value >= right_operand.value
        when "!="
          t.value = left_operand.value != right_operand.value
        when "=="
          t.value = left_operand.value == right_operand.value
        when "+"
          t.value = left_operand.value + right_operand.value
        when "-"
          t.value = left_operand.value - right_operand.value
        when "*"
          t.value = left_operand.value * right_operand.value
        when "/"
          if right_operand.value != 0
            t.value = left_operand.value / right_operand.value
          else
            t.value = "error"
            msj = "[WARNING] Division by zero. Line: #{right_operand.token.location[:row]}\n"
            error(msj)
          end
        when "%"
          if left_operand.value.is_a?(Integer) && right_operand.value.is_a?(Integer)
            if right_operand.value != 0
              t.value = left_operand.value % right_operand.value
            else
              t.value = "error"
              msj = "[WARNING] Division by zero. Line: #{right_operand.token.location[:row]}\n"
              error(msj)
            end
          else
            t.value = "error"
            msj = "[ERROR] Invalid operands, only integer operands are allowed for the binary operator '%'. Line: #{t.token.location[:row]}\n"
            error(msj)
          end
        else
          msj = "[BUG] Operator type '#{t.token.lexeme}' does not exist. Line #{t.token.location[:row]}\n"
          error(msj)
        end
      end
    end
  end

  # Establece el valor de las asignaciones y detecta errores
  def assign_eval(t)
    identifier = t.first_child
    expression = t.last_child
    just_id(expression)
    if variable_exists?(identifier.token.lexeme)
      update_variable(identifier.token.lexeme, identifier.token.location[:row])
      identifier.type = get_type(identifier.token.lexeme)
      if expression.value.eql?("error")
        msj = "[ERROR] Expression value in the assignment is invalid. Line: #{t.token.location[:row]}\n"
        error(msj)
      else
        case identifier.type
        when "integer"
          if !expression.value.is_a?(Integer)
            msj = "[ERROR] Cannot assign non-integer values to '#{identifier.token.lexeme}' variable. Line: #{identifier.token.location[:row]}\n"
            error(msj)
            identifier.value = get_value(identifier.token.lexeme)
          else
            identifier.value = expression.value
            set_value(identifier.token.lexeme, identifier.value)
          end
        when "float"
          if !(expression.value.is_a?(Float))
            msj = "[ERROR] Cannot assign non-float values to '#{identifier.token.lexeme}' variable. Line: #{identifier.token.location[:row]}\n"
            error(msj)
            identifier.value = get_value(identifier.token.lexeme)
          else
            identifier.value = expression.value
            set_value(identifier.token.lexeme, identifier.value)
          end
        when "bool"
          if expression.value != true && expression.value != false
            msj = "[ERROR] Cannot assign non-boolean values to '#{identifier.token.lexeme}' variable. Line: #{identifier.token.location[:row]}\n"
            error(msj)
            identifier.value = get_value(identifier.token.lexeme)
          else
            identifier.value = expression.value
            set_value(identifier.token.lexeme, identifier.value)
          end
        else
          msj = "[BUG] Data type of '#{identifier.token.lexeme}' variable is unknown. Line: #{identifier.token.location[:row]}\n"
          error(msj)
        end
      end
    else
      msj = "[ERROR] Unable to assign value to '#{identifier.token.lexeme}' variable since it is not declared. Line: #{identifier.token.location[:row]}\n"
      error(msj)
      identifier.value = "error"
    end
  end

  # Establece y detecta errores en las expresiones de sentencias if, while y do
  def boolean_eval(t, child_number)
    expression = t.children[child_number]
    just_id(expression)
    if expression.value != true && expression.value != false
      msj = "[ERROR] If expression is not boolean. Line: #{expression.token.location[:row]}\n"
      error(msj)
    end
  end

  # Detecta errores en sentencias read
  def read_eval(t)
    identifier = t.first_child
    if !variable_exists?(identifier.token.lexeme)
      identifier.value = "error"
      msj = "[ERROR] Unable to read '#{identifier.token.lexeme}' variable since it is not declared. Line: #{identifier.token.location[:row]}\n"
      error(msj)
    else
      update_variable(identifier.token.lexeme, identifier.token.location[:row])
    end
  end

  # Establece el valor de las expresiones en sentencias write
  def write_eval(t)
    expression = t.last_child
    just_id(expression)
  end

end
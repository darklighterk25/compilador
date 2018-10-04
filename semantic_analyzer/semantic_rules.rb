module SemanticRules

  # Establece el tipo de dato de las variables
  def check_type(t)
    children = t.children
    children.each do |child|
      if (t.nodekind.eql?("declaration"))
        child.type = t.token.lexeme
        set_type(child.token.lexeme, child.type)
      end
      check_type(child)
    end
  end

  # Recorrido en post-orden para la evaluación del arbol sintactico
  def evaluate_tree(t)
    children = t.children
    children.each do |child|
      if (child.kind.eql?("opK"))
        puts "Entré en opK"
        post_eval(child)
      elsif (child.kind.eql?("assignK"))
        assign_eval(child)
      elsif (child.kind.eql?("ifK"))
        boolean_eval(child, 0)
        for i in 1..(child.children.length - 1) do
          evaluate_tree(child.children[i])
        end
      elsif (child.kind.eql?("whileK"))
        boolean_eval(child, 0)
        evaluate_tree(child.last_child)
      elsif (child.kind.eql?("doK"))
        evaluate_tree(child.first_child)
        boolean_eval(child, 1)
      elsif (child.kind.eql?("readK"))
        read_eval(child)
      elsif (child.kind.eql?("writeK"))
        write_eval(child)
      else
        evaluate_tree(child)
      end
    end
  end

  # Establece el valor de las expresiones y detecta errores como divisiones entre 0
  def post_eval(t)
    if(t.kind.eql?("opK"))
      post_eval(t.first_child)
      post_eval(t.last_child)
      if(t.first_child.kind.eql?("idK"))
        if(variable_exists?(t.first_child.token.lexeme))
          t.first_child.value = get_value(t.first_child.token.lexeme)
        else
          t.first_child.value = "error"
        end
      end
      if(t.last_child.kind.eql?("idK"))
        if(variable_exists?(t.last_child.token.lexeme))
          t.last_child.value = get_value(t.last_child.token.lexeme)
        else
          t.last_child.value = "error"
        end
      end
      if(t.first_child.value.eql?("error") || t.last_child.value.eql?("error"))
        t.value = "error"
      else
        case t.token.lexeme
        when "<="
          t.value = t.first_child.value <= t.last_child.value
        when "<"
          t.value = t.first_child.value < t.last_child.value
        when ">"
          t.value = t.first_child.value > t.last_child.value
        when ">="
          t.value = t.first_child.value >= t.last_child.value
        when "!="
          t.value = t.first_child.value != t.last_child.value
        when "=="
          t.value = t.first_child.value == t.last_child.value
        when "+"
          t.value = t.first_child.value + t.last_child.value
        when "-"
          t.value = t.first_child.value - t.last_child.value
        when "*"
          t.value = t.first_child.value * t.last_child.value
        when "/"
          if t.last_child.value != 0
            t.value = t.first_child.value / t.last_child.value
          else
            t.value = "error"
            msj = "Error, división entre 0 en la línea #{t.last_child.token.location[:row]}\n"
            error(msj)
          end
        when "%"
          if t.last_child.value != 0
            t.value = t.first_child.value % t.last_child.value
          else
            t.value = "error"
            msj = "Error, modulo entre 0 en la linea #{t.last_child.token.location[:row]}\n"
            error(msj)
          end
        else
          msj = "El tipo de operador (#{t.token.lexeme}) no existe!!\n"
          error(msj)
        end
      end
    end
  end

  # Establece el valor de las asignaciones y detecta errores
  def assign_eval(t)
    identifier = t.first_child
    expression = t.last_child
    post_eval(expression)
    if(variable_exists?(identifier.token.lexeme))
      identifier.type = get_type(identifier.token.lexeme)
      if(expression.value.eql?("error"))
        msj = "El valor de la asignación en la línea #{expression.token.location[:row]} es erroneo\n"
        error(msj)
      else
        case identifier.type
        when "integer"
          if(!(expression.value.is_a? Integer))
            msj = "No se pueden asignar valores no enteros a la variable #{identifier.token.lexeme}. Linea #{identifier.token.location[:row]}\n"
            error(msj)
            identifier.value = get_value(identifier.token.lexeme)
          else
            identifier.value = expression.value
            set_value(identifier.token.lexeme, identifier.value)
          end
        when "float"
          if(!(expression.value.is_a? Float))
            msj = "No se pueden asignar valores no flotantes a la variable #{identifier.token.lexeme}. Linea #{identifier.token.location[:row]}\n"
            error(msj)
            identifier.value = get_value(identifier.token.lexeme)
          else
            identifier.value = expression.value
            set_value(identifier.token.lexeme, identifier.value)
          end
        when "bool"
          if(expression.value != true && expression.value != false)
            msj = "No se pueden asignar valores no booleanos a la variable #{identifier.token.lexeme}. Línea #{identifier.token.location[:row]}\n"
            error(msj)
            identifier.value = get_value(identifier.token.lexeme)
          else
            identifier.value = expression.value
            set_value(identifier.token.lexeme, identifier.value)
          end
        else
          msj = "El tipo de dato de la variable #{identifier.token.lexeme} es desconocido !!\n"
          error(msj)
        end
      end
    else
      msj = "No se puede asignar valor a la variable #{identifier.token.lexeme} ya que no existe. Linea #{t.token.location[:row]}\n"
      error(msj)
      identifier.value = "error"
    end
  end

  # Establece y detecta errores en las expresiones de sentencias if, while y do
  def boolean_eval(t, child_number)
    expression = t.children[child_number]
    post_eval(expression)
    if(expression.value != true && expression.value != false)
      msj = "Error, la expresion de la sentencia if de la linea #{expression.token.location[:row]} no es booleana\n"
      error(msj)
    end
  end

  # Detecta errores en sentencias read
  def read_eval(t)
    identifier = t.first_child
    if(!(variable_exists?(identifier.token.lexeme)))
      msj = "Error, la variable #{identifier.token.lexeme} no esta declarada y no se puede leer\n"
      error(msj)
    end
  end

  # Establece el valor de las expresiones en sentencias write
  def write_eval(t)
    expression = t.last_child
    post_eval(expression)
  end

end
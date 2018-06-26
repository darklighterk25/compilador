module SyntaxRules

  def program
    t = new_node("main")
    match(@TOKEN_TYPE[:rw_main])
    match(@TOKEN_TYPE[:op_brace])
    if t != nil
      while @token.type != @TOKEN_TYPE[:rw_integer] and @token.type != @TOKEN_TYPE[:rw_float]\
      and @token.type != @TOKEN_TYPE[:rw_bool]
        syntax_error
        @token = get_token
        if @token.type == @TOKEN_TYPE[:eof]
          t
        end
      end
      aux = declaration_list
      aux.each do | x |
        t << x
      end
      aux = sentence_list
      aux.each do | x |
        t << x
      end
    end
    match(@TOKEN_TYPE[:cl_brace])
    t
  end

  def declaration_list
    siblings = []
    i = 0
    t = declaration
    if t!= nil
      match(@TOKEN_TYPE[:semicolon])
      siblings[i] = t
      i += 1
    end
    while @token.type != @TOKEN_TYPE[:rw_if] and @token.type != @TOKEN_TYPE[:rw_while]\
    and @token.type != @TOKEN_TYPE[:rw_do] and @token.type != @TOKEN_TYPE[:rw_read]\
    and @token.type != @TOKEN_TYPE[:rw_write] and @token.type != @TOKEN_TYPE[:string]\
    and @token.type != @TOKEN_TYPE[:op_brace] and @token.type != @TOKEN_TYPE[:identifier]
      q = declaration
      if q != nil
        match(@TOKEN_TYPE[:semicolon])
        siblings[i] = q
        i += 1
      end
    end
    siblings
  end

  def declaration
    t = nil
    if @token.type == @TOKEN_TYPE[:rw_integer] or @token.type == @TOKEN_TYPE[:rw_float]\
    or @token.type == @TOKEN_TYPE[:rw_bool]
      t = new_node("statement")
      match(@token.type)
      aux = variable_list
      aux.each do | x |
        t << x
      end
    else
      syntax_error
      @token = get_token
    end
    t
  end

  def variable_list
    siblings = []
    i = 0
    while @token.type == @TOKEN_TYPE[:identifier]
      siblings[i] = new_node("expression")
      i += 1
      match(@token.type)
      if @token.type == @TOKEN_TYPE[:comma]
        match(@token.type)
      elsif @token.type == @TOKEN_TYPE[:semicolon]
        break
      else
        syntax_error
        @token = get_token
      end
    end
    siblings
  end

  def sentence_list
    siblings = []
    i = 0
    t = sentence
    if t != nil
      siblings[i] = t
      i += 1
    end
    while @token.type != @TOKEN_TYPE[:eof] and @token.type != @TOKEN_TYPE[:rw_end]\
    and @token.type != @TOKEN_TYPE[:rw_else] and @token.type != @TOKEN_TYPE[:rw_until]\
    and @token.type != @TOKEN_TYPE[:cl_brace]
      q = sentence
      if(q != nil)
        siblings[i] = q
        i += 1
      end
    end
    siblings
  end

  def sentence
    t = nil
    case @token.type
      when @TOKEN_TYPE[:rw_if]
        t = selection
      when @TOKEN_TYPE[:rw_while]
        t = iteration
      when @TOKEN_TYPE[:rw_do]
        t = repetition
      when @TOKEN_TYPE[:rw_read]
        t = sent_read
      when @TOKEN_TYPE[:rw_write]
        t = sent_write
      when @TOKEN_TYPE[:rw_string]
        t = sent_write
      when @TOKEN_TYPE[:op_brace]
        t = block
      when @TOKEN_TYPE[:identifier]
        t = assignation
      else
        syntax_error
        @token = get_token
    end
    t
  end

  def selection
    t = new_node("statement")
    match(@TOKEN_TYPE[:rw_if])
    match(@TOKEN_TYPE[:op_brace])
    if t != nil
      aux = expression
      if aux != nil
        t << aux
      end
    end
    match(@TOKEN_TYPE[:cl_brace])
    match(@TOKEN_TYPE[:rw_then])
    if t != nil
      t << block
    end
    if @token.type == @TOKEN_TYPE[:rw_else]
      match(@token.type)
      if t != nil
        t << block
      end
    end
    t
  end

  def iteration
    t = new_node("statement")
    match(@TOKEN_TYPE[:rw_while])
    match(@TOKEN_TYPE[:op_parenthesis])
    if t != nil
      aux = expression
      if aux != nil
        t << aux
      end
    end
    match(@TOKEN_TYPE[:cl_parenthesis])
    if t != nil
      t << block
    end
    t
  end

  def repetition
    t = new_node("statement")
    match(@TOKEN_TYPE[:rw_do])
    if t != nil
      t << block
    end
    match(@TOKEN_TYPE[:rw_until])
    match(@TOKEN_TYPE[:op_parenthesis])
    if t != nil
      aux = expression
      if aux != nil
        t << aux
      end
    end
    match(@TOKEN_TYPE[:cl_parenthesis])
    match(@TOKEN_TYPE[:semicolon])
    t
  end

  def sent_read
    t = new_node("statement")
    match(@TOKEN_TYPE[:rw_read])
    if t != nil
      t << new_node("expression")
      match(@TOKEN_TYPE[:identifier])
    end
    match(@TOKEN_TYPE[:semicolon])
    t
  end

  def sent_write
    if @token.type == @TOKEN_TYPE[:rw_write]
      t = new_node("statement")
      match(@TOKEN_TYPE[:rw_write])
      if t != nil
        t << new_node("expression")
        match(@TOKEN_TYPE[:string])
        t << expression
      end
    elsif @token.type == @TOKEN_TYPE[:string]
      t = new_node("expression")
      match(@TOKEN_TYPE[:string])
      match(@TOKEN_TYPE[:semicolon])
    end
    t
  end

  def block
    t = new_node("statement")
    match(@TOKEN_TYPE[:op_brace])
    if t != nil
      aux = sentence_list
      aux.each do | x |
        t << x
      end
    end
    match(@TOKEN_TYPE[:cl_brace])
    t
  end

  def assignation
    t = new_node("statement")
    match(@TOKEN_TYPE[:identifier])
    p = new_node("expression")
    if @token.type == @TOKEN_TYPE[:assign]
      aux = expression
    else
      # Si es incremento o decremento debemos crear el sub-árbol correspondiente.
      if @token.type == @TOKEN_TYPE[:increment]
        aux = new_node('', Token.new(@TOKEN_TYPE[:addition], '+', @token.range,
                                     @token.location, @TOKEN_STYLE[:addition]))
      elsif @token.type == @TOKEN_TYPE[:decrement]
        aux = new_node('', Token.new(@TOKEN_TYPE[:subtraction], '-', @token.range,
                                     @token.location, @TOKEN_STYLE[:subtraction]))
      end
      if aux != nil
        # Agregamos los hijos del sub-árbol.
        aux << new_node('', Token.new(@TOKEN_TYPE[:identifier], t.token.lexeme, @token.range,
                                      @token.location, @TOKEN_STYLE[:identifier]))
        aux << new_node('', Token.new(@TOKEN_TYPE[:integer], '1', @token.range,
                                      @token.location, @TOKEN_STYLE[:integer]))
        # Modificamos el token actual para que se vuelva uno de asignación.
        p.content = Token.new(@TOKEN_TYPE[:assign], ":=", @token.range, @token.location, @TOKEN_STYLE[:assign])
      end
    end
    if p != nil
      p << t
      t = p
      if aux != nil
        t << aux
      end
    end
    # Comparamos con asignación ya que si se tratase de un incremento o decremento, este se cambiará a uno de asignación.
    match(@TOKEN_TYPE[:assign])
    p = expression
    if p != nil
      t << p
    end
    match(@TOKEN_TYPE[:semicolon])
    t
  end

  def expression
    t = simple_expression
    if @token.type == @TOKEN_TYPE[:less_equal] or @token.type == @TOKEN_TYPE[:less]\
    or @token.type == @TOKEN_TYPE[:greater] or @token.type == @TOKEN_TYPE[:greater_equal]\
    or @token.type == @TOKEN_TYPE[:equal] or @token.type == @TOKEN_TYPE[:not_equal]
      p = new_node("expression")
      if p != nil
        p << t
        t = p
      end
      match(@token.type)
      if t != nil
        t << simple_expression
      end
    end
    t
  end

  def simple_expression
    t = term
    while @token.type == @TOKEN_TYPE[:addition] or @token.type == @TOKEN_TYPE[:subtraction]
      p = new_node("expression")
      if p != nil
        p << t
        t = p
        match(@token.type)
        t << term
      end
    end
    t
  end

  def term
    t = factor
    while @token.type == @TOKEN_TYPE[:multiplication] or @token.type == @TOKEN_TYPE[:division]\
    or @token.type == @TOKEN_TYPE[:module]
      p = new_node("expression")
      if p != nil
        p << t
        t = p
        match(@token.type)
        p << factor
      end
    end
    t
  end

  def factor
    t = nil
    case @token.type
      when @TOKEN_TYPE[:integer]
        t = new_node("expression")
        match(@token.type)
      when @TOKEN_TYPE[:float]
        t = new_node("expression")
        match(@token.type)
      when @TOKEN_TYPE[:identifier]
        t = new_node("expression")
        match(@token.type)
      when @TOKEN_TYPE[:op_parenthesis]
        match(@token.type)
        t = expression
        match(@TOKEN_TYPE[:cl_parenthesis])
      else
        syntax_error
        @token = get_token
    end
    t
  end

end
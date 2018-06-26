class TokenTypes

  def initialize
    @RESERVED_WORDS = %w[bool do else end float if integer main read repeat then until while write]
    @TOKEN_STYLE = {
        addition: 4, assign: 4, cl_brace: 4, cl_parenthesis: 4, colon: 2, comma: 2, comment: 7, decrement: 4,
        division: 4, eof: 0, equal: 4, error: 1, float: 5, greater: 4, greater_equal: 4, identifier: 2, increment: 4,
        integer: 5, less: 4, less_equal: 4, module: 4, multiplication: 4, not_equal: 4, op_brace: 4, op_parenthesis: 4,
        rw_bool: 3, rw_do: 3, rw_else: 3, rw_end: 3, rw_float: 3, rw_if: 3, rw_integer: 3, rw_main: 3, rw_read: 3,
        rw_repeat: 3, rw_then: 3, rw_until: 3, rw_while: 3, rw_write: 3, semicolon: 2, string: 6, subtraction: 4,
    }
    @TOKEN_TYPE = {
        addition: "Suma", assign: "Asignación", cl_brace: "Llave que cierra", cl_parenthesis: "Paréntesis que cierra",
        colon: "Dos puntos", comma: "Coma", comment: "Comentario", decrement: "Decremento",
        division: "División", eof: "Fin de archivo", equal: "Igual", error: "Error", float: "Flotante",
        greater: "Mayor que", greater_equal: "Mayor o igual", identifier: "Identificador", increment: "Incremento",
        integer: "Entero", less: "Menor que", less_equal: "Menor o igual", module: "Módulo",
        multiplication: "Multiplicación", not_equal: "Distinto", op_brace: "Llave abre",
        op_parenthesis: "Paréntesis que abre", rw_bool: "Palabra reservada (Bool)", rw_do: "Palabra reservada (Do)",
        rw_else: "Palabra reservada (Else)", rw_end: "Palabra reservada (Final)", rw_float: "Palabra reservada (Flot)",
        rw_if: "Palabra reservada (If)", rw_integer: "Palabra reservada (Integer)", rw_main: "Palabra reservada (Main)",
        rw_read: "Palabra reservada (Read)", rw_repeat: "Palabra reservada (Repeat)",
        rw_then: "Palabra reservada (Then)", rw_until: "Palabra reservada (Until)",
        rw_while: "Palabra reservada (While)", rw_write: "Palabra reservada (Write)", semicolon: "Punto y coma",
        string: "Cadena", subtraction: "Resta"
    }
  end

  # Recibe un tipo de token, busca su respectiva llave y la utiliza para retornar su estilo correspondiente.
  def get_token_style(token_type)
    @TOKEN_STYLE[@TOKEN_TYPE.key(token_type)]
  end

end
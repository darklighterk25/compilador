require_relative 'code'

class IntermediateCode

  def initialize(intermediate_code, output, semantic_tree, hash_table)
    @intermediate_code = intermediate_code
    @output = output
    @semantic_tree = semantic_tree
    @intermediate_code.appendText("Código intermedio\n")
    @tmp_offset = 0
    @code = Code.new()
    @hash_table = hash_table
    @break = false
    @loc_break = 0
    code_gen(semantic_tree)
    @code.write_code
  end

  private
  def get_loc(lexeme)
    key = lexeme.to_sym
    if @hash_table.has_key? key
      return @hash_table[key].location
    end
    -1
  end

  private
  def get_type(lexeme)
    key = lexeme.to_sym
    if @hash_table.has_key? key
      return @hash_table[key].type
    end
    -1
  end

  def gen_stmt(t)

    case t.kind

    when "assignK" # :=
      @code.emit_comment("-> assign")
      c_gen(t.children[1])
      loc = get_loc(t.children[0].token.lexeme)
      @code.emit_rm("ST", @code.ac, loc, @code.gp, "read: store value")
      @code.emit_comment("<- assign")

    when "doK"
      @code.emit_comment("-> do")
      p1 = t.children[0]
      p2 = t.children[1]
      saved_loc1 = @code.emit_skip(0)
      @code.emit_comment("do: jump after body comes back here")
      c_gen(p1)
      c_gen(p2)
      if @break
        current_loc = @code.emit_skip(0)
        @code.emit_backup(@loc_break)
        @code.emit_rm_abs("LDA", @code.pc, current_loc + 1, "do: jmp to end")
        @break = false
        @code.emit_restore
      end
      @code.emit_rm_abs("JEQ", @code.ac, saved_loc1, "do: jmp back to body")
      @code.emit_comment("<- do")

    when "ifK"
      @code.emit_comment("-> if")
      p1 = t.children[0]
      p2 = t.children[1]
      p3 = t.children[2]
      c_gen(p1)
      saved_loc1 = @code.emit_skip(1)
      @code.emit_comment("if: jump to else belongs here")
      c_gen(p2)
      saved_loc2 = @code.emit_skip(1)
      @code.emit_comment("if: jump to end belongs here")
      current_loc = @code.emit_skip(0)
      @code.emit_backup(saved_loc1)
      @code.emit_rm_abs("JEQ", @code.ac, current_loc, "if: jmp to else")
      @code.emit_restore
      c_gen(p3)
      current_loc = @code.emit_skip(0)
      @code.emit_backup(saved_loc2)
      @code.emit_rm_abs("LDA", @code.pc, current_loc, "jmp to end")
      @code.emit_restore
      @code.emit_comment("<- if")

    when "readK"
      @code.emit_ro("IN", @code.ac, 0, 0, get_type(t.children[0].token.lexeme))
      loc = get_loc(t.children[0].token.lexeme)
      @code.emit_rm("ST", @code.ac, loc, @code.gp, "read: store value")

    when "whileK"
      @code.emit_comment("-> while")
      p1 = t.children[0]
      p2 = t.children[1]
      saved_loc1 = @code.emit_skip(0)
      c_gen(p1)
      saved_loc2 = @code.emit_skip(1)
      @code.emit_backup(saved_loc2)
      c_gen(p2)
      current_loc = @code.emit_skip(0)
      @code.emit_backup(saved_loc2)
      @code.emit_rm_abs("JEQ", @code.ac, current_loc + 1, "while: jmp back to test")
      @code.emit_rm_abs("LDA", @code.pc, saved_loc1, "")
      @code.emit_comment("<- while")

    when "blockK"
      @code.emit_comment("-> block")
      t.children.each do | child |
        gen_stmt(child)
      end

    when "readK"
      @code.emit_ro("IN", @code.ac, 0, 0, "read: store value")
      loc = get_loc(t.token.lexeme)
      @code.emit_rm("ST", @code.ac, loc, @code.gp, "read: store value")

    when "writeK"
      c_gen(t.children[1])
      @code.emit_ro("OUT", @code.ac, 0, 0, "write ac")

    else
      puts "[ERROR] #{t}"

    end
  end

  def gen_exp(t)
    loc = 0
    p1 = nil
    p2 = nil

    case t.kind

    when "constK"
      @code.emit_comment("-> Const")
      @code.emit_rm("LDC", @code.ac, t.value, 0, "load const")
      @code.emit_comment("<- Const")

    when "idK"
      @code.emit_comment("-> Id")
      loc = get_loc(t.token.lexeme)
      @code.emit_rm("LD", @code.ac, loc, @code.gp, "load id value")
      @code.emit_comment("<- Id")

    when "opK"
      @code.emit_comment("-> Op")
      p1 = t.children[0]
      p2 = t.children[1]
      c_gen(p1)
      @code.emit_rm("ST", @code.ac, @tmp_offset, @code.mp, "op: push left")
      @tmp_offset = @tmp_offset - 1
      c_gen(p2)
      @tmp_offset = @tmp_offset + 1
      @code.emit_rm("LD", @code.ac1, @tmp_offset, @code.mp, "op: load left")
        case t.token.lexeme
        when "+"
          @code.emit_ro("ADD", @code.ac, @code.ac1, @code.ac, "op +")
        when "-"
          @code.emit_ro("SUB", @code.ac, @code.ac1, @code.ac, "op -")
        when "*"
          @code.emit_ro("MUL", @code.ac, @code.ac1, @code.ac, "op *")
        when "/"
          @code.emit_ro("DIV", @code.ac, @code.ac1, @code.ac, "op /")
        when "<"
          @code.emit_ro("SUB", @code.ac, @code.ac1, @code.ac, "op <=")
          @code.emit_rm("JLT", @code.ac, 2, @code.pc, "jump if true")
          @code.emit_rm("LDC", @code.ac, 0, @code.ac, "false case")
          @code.emit_rm("LDA", @code.pc, 1, @code.pc, "unconditional jmp")
          @code.emit_rm("LDC", @code.ac, 1, @code.ac, "true case")
        when "<="
          @code.emit_ro("SUB", @code.ac, @code.ac1, @code.ac, "op <")
          @code.emit_rm("JLE", @code.ac, 2, @code.pc, "jump if true")
          @code.emit_rm("LDC", @code.ac, 0, @code.ac, "false case")
          @code.emit_rm("LDA", @code.pc, 1, @code.pc, "unconditional jmp")
          @code.emit_rm("LDC", @code.ac, 1, @code.ac, "true case")
        when ">"
          @code.emit_ro("SUB", @code.ac, @code.ac1, @code.ac, "op >")
          @code.emit_rm("JGT", @code.ac, 2, @code.pc, "jump if true")
          @code.emit_rm("LDC", @code.ac, 0, @code.ac, "false case")
          @code.emit_rm("LDA", @code.pc, 1, @code.pc, "unconditional jmp")
          @code.emit_rm("LDC", @code.ac, 1, @code.ac, "true case")
        when ">="
          @code.emit_ro("SUB", @code.ac, @code.ac1, @code.ac, "op >=")
          @code.emit_rm("JGE", @code.ac, 2, @code.pc, "jump if true")
          @code.emit_rm("LDC", @code.ac, 0, @code.ac, "false case")
          @code.emit_rm("LDA", @code.pc, 1, @code.pc, "unconditional jmp")
          @code.emit_rm("LDC", @code.ac, 1, @code.ac, "true case")
        when "=="
          @code.emit_ro("SUB", @code.ac, @code.ac1, @code.ac, "op ==")
          @code.emit_rm("JEQ", @code.ac, 2, @code.pc, "jump if true")
          @code.emit_rm("LDC", @code.ac, 0, @code.ac, "false case")
          @code.emit_rm("LDA", @code.pc, 1, @code.pc, "unconditional jmp")
          @code.emit_rm("LDC", @code.ac, 1, @code.ac, "true case")
        when "!="
          @code.emit_ro("SUB", @code.ac, @code.ac1, @code.ac, "op !=")
          @code.emit_rm("JNE", @code.ac, 2, @code.pc, "jump if true")
          @code.emit_rm("LDC", @code.ac, 0, @code.ac, "false case")
          @code.emit_rm("LDA", @code.pc, 1, @code.pc, "unconditional jmp")
          @code.emit_rm("LDC", @code.ac, 1, @code.ac, "true case")
        else
          puts "[ERROR] #{t}"
        end

    else
      @code.emit_comment("Bug: Unknown operator")
    end

  end

  def c_gen(t)
    if t != nil
      case t.nodekind
      when "main"
        t.children.each do |child|
          c_gen(child)
        end
      when "statement"
        gen_stmt(t)
      when "expression"
        gen_exp(t)
      end
    end
  end

  def code_gen(t)
    @code.emit_comment("Compilacion a código intermedio")
    @code.emit_comment("Standar prelude: ")
    @code.emit_rm("LD", @code.mp, 0, @code.ac, "load max address from location 0")
    @code.emit_rm("ST", @code.ac, 0, @code.ac, "clear location 0")
    @code. emit_comment("End of standar prelude.")
    c_gen(t)
    @code.emit_comment("End of execution.")
    @code.emit_ro("HALT", 0, 0, 0, "")
  end

end
class Opclass
	attr_reader :opcl_rr, :opcl_rm, :opcl_ra
	def initialize
		@opcl_rr = 0
		@opcl_rm = 1
		@opcl_ra = 2
	end
end

class Opcode
	attr_reader :op_halt, :op_ini, :op_inf, :op_out, :op_outs, :op_add, :op_subb, :op_mul, :op_div,
				:op_rr_lim, :op_ld, :op_st, :op_rm_lim, :op_lda, :op_ldc, :op_jlt,
				:op_jle, :op_jgt, :op_jge, :op_jeq, :op_jne, :op_ra_lim
	def initialize
		@op_halt = 0
		@op_ini = 1
		@op_inf = 2
		@op_out = 3
		@op_outs = 4
		@op_add = 5
		@op_subb = 6
		@op_mul = 7
		@op_div = 8
		@op_rr_lim = 9
		@op_ld = 10
		@op_st = 11
		@op_rm_lim = 12
		@op_lda = 13
		@op_ldc = 14
		@op_jlt = 15
		@op_jle = 16
		@op_jgt = 17
		@op_jge = 18
		@op_jeq = 19
		@op_jne = 20
		@op_ra_lim = 21
	end
end

class StepResult
	attr_reader :sr_okay, :sr_halt, :sr_imem_err, :sr_dmem_err, :sr_zero_divide
	def initialize
		@sr_okay = 0
		@sr_halt = 1
		@sr_imem_err = 2
		@sr_dmem_err = 3
		@sr_zero_divide = 4
	end
end

class Instruction
	attr_accessor :iop, :iarg1, :iarg2, :iarg3
	def initialize(iop, iarg1, iarg2, iarg3)
		@iop = iop
		@iarg1 = iarg1
		@iarg2 = iarg2
		@iarg3 = iarg3
	end
end

class Machine
	def initialize(text_field)
		@text_field = text_field
		@iaddr_size = 1024
		@daddr_size = 1024
		@no_regs = 8
		@pc_reg = 7
		@i_mem = []
		@d_mem = []
		@reg = []
		@op_code_tab = %w[HALT INI INF OUT OUTS ADD SUB MUL DIV ???? LD ST ???? LDA LDC JLT JLE JGT JGE JEQ JNE ????]
		@step_result_tab = ["OK", "Halted", "Instruction Memory Fault",
							"Data Memory Fault", "Division by zero"]

		for i in(0..@iaddr_size)
			@i_mem.push(Instruction.new(0,0,0,0))
		end

		for i in(0..@no_regs)
			@reg.push(0)
		end

		@d_mem.push(@daddr_size-1)

		for i in(0..@daddr_size)
			@d_mem.push(0)
		end

		op_code = Opcode.new

		@i_mem.each do |i_mem|
			i_mem.iop = op_code.op_halt
			i_mem.iarg1 = 0
			i_mem.iarg2 = 0
			i_mem.iarg3 = 0
		end
	end

	def op_class(c)
		opcode = Opcode.new
		opclass = Opclass.new
		if c <= opcode.op_rr_lim
			return opclass.opcl_rr
		elsif c <= opcode.op_rm_lim
			return opclass.opcl_rm
		else
			return opclass.opcl_ra
		end
	end

	def error(msg, line, instruction)
		@text_field.appendText("Line: #{line}\n")
		if instruction >= 0
			@text_field.appendText("(Instruction #{instruction})\n")
		end
		@text_field.appendText("\n")
	end

	def get_op_code(opcode)
		for i in(0..@op_code_tab.length)
			if @op_code_tab[i] == opcode
				return i
			end
		end
		-1
	end

	def to_num(num)
		if num.include? "."
			return Float(num)
		end
		Integer(num)
	end

	def read_instruction
		op = 0
		line_number = 0
		ophalt = Opcode.new

		File.readlines("int_code.txt").each do |line|
			line_number += 1
			data = line.split(/ /)
			loc = data[0][0..data[0].length-2].to_i
			if loc > @iaddr_size
				error("Location too large", line_number, loc)
			end
			op = ophalt.op_halt
			if get_op_code(data[1]) == -1
				error("Ilegal opcode", line_number, loc)
			else
				op = get_op_code(data[1])
			end

			if op == ophalt.op_outs
				msg = line.split(/"([^"]*)"/)
				arg1 = msg[1]
				arg2 = 0
				arg3 = 0
			else
				arg1 = to_num(data[2])
				arg2 = to_num(data[3])
				arg3 = to_num(data[4])
				if arg1 < 0 || arg1 >= @no_regs
					error("Bad first register", line_number, loc)
				end
				if op < 9
					if arg2 < 0 || arg2 >= @no_regs
						error("Bad second register", line_number, loc)
					end
				end
				if arg3 < 0 || arg3 >= @no_regs
					error("Bad third register", line_number, loc)
				end
			end 
			
			@i_mem[loc].iop = op
			@i_mem[loc].iarg1 = arg1
			@i_mem[loc].iarg2 = arg2
			@i_mem[loc].iarg3 = arg3
		end
	end

	def step_tm
		pc = @reg[@pc_reg]
		opclass = Opclass.new
		opcode = Opcode.new
		step_result = StepResult.new
		if pc < 0 || pc > @iaddr_size
			return step_result.sr_imem_err
		end
		@reg[@pc_reg] = pc + 1
		current_instruction = @i_mem[pc]

		case op_class(current_instruction.iop)
		when opclass.opcl_rr
			r = current_instruction.iarg1
			s = current_instruction.iarg2
			t = current_instruction.iarg3
		when opclass.opcl_rm
			r = current_instruction.iarg1
			s = current_instruction.iarg3
			m = current_instruction.iarg2 + @reg[s]
			if m < 0 || m > @daddr_size
				return step_result.sr_dmem_err
			end
		when opclass.opcl_ra
			r = current_instruction.iarg1
			s = current_instruction.iarg3
			m = current_instruction.iarg2 + @reg[s]
		end

		case current_instruction.iop
		when opcode.op_halt
			return step_result.sr_halt
		when opcode.op_ini
			input = gets.chomp
			begin  
			    @reg[r] = Integer(input)  
			    @text_field.appendText("#{@reg[r]}\n")
			rescue
			    @text_field.appendText("TM ERROR: Ilegal integer value\n")
			    return step_result.sr_halt
			end
		when opcode.op_inf
			input = gets.chomp
			begin  
			    @reg[r] = Float(input)  
			    @text_field.appendText("#{@reg[r]}\n")
			rescue  
			    @text_field.appendText("TM ERROR: Ilegal float value\n")
			    return step_result.sr_halt
			end
		when opcode.op_outs
			@text_field.appendText("#{current_instruction.iarg1}\n")
		when opcode.op_out
			@text_field.appendText("#{@reg[r]}\n")
		when opcode.op_add
			@reg[r] = @reg[s] + @reg[t]
		when opcode.op_subb
			@reg[r] = @reg[s] - @reg[t]
		when opcode.op_mul
			@reg[r] = @reg[s] * @reg[t]
		when opcode.op_div
			if @reg[t] != 0
				@reg[r] = @reg[s] / @reg[t]
			else
				return step_result.sr_zero_divide
			end
		when opcode.op_ld
			@reg[r] = @d_mem[m]
		when opcode.op_st
			@d_mem[m] = @reg[r]
		when opcode.op_lda
			@reg[r] = m
		when opcode.op_ldc
			@reg[r] = current_instruction.iarg2
		when opcode.op_jlt
			if @reg[r] < 0
				@reg[@pc_reg] = m
			end
		when opcode.op_jle
			if @reg[r] <= 0
				@reg[@pc_reg] = m
			end
		when opcode.op_jgt
			if @reg[r] > 0
				@reg[@pc_reg] = m
			end
		when opcode.op_jge
			if @reg[r] >= 0
				@reg[@pc_reg] = m
			end
		when opcode.op_jeq
			if @reg[r] == 0
				@reg[@pc_reg] = m
			end
		when opcode.op_jne
			if @reg[r] != 0
				@reg[@pc_reg] = m
			end
		end
		step_result.sr_okay
	end

	def run
		a = StepResult.new
		step_result = a.sr_okay
		while step_result == a.sr_okay
			step_result = step_tm
		end
		@text_field.appendText("Process Excited!\n")
	end
end
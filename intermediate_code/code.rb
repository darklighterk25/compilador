class Code

  attr_reader :ac, :ac1, :gp, :pc, :mp

	def initialize(intermediate_code)
		@intermediate_code = intermediate_code
		@emit_loc = 0
		@high_emit_loc = 0
		@pc = 7
		@mp = 6
		@gp = 5
		@ac = 0
		@ac1 = 1
		@file = ""
	end

	def emit_ro(op, r, s, t, c)
		@file += "#{@emit_loc}: #{op} #{r} #{s} #{t}\n"
		@intermediate_code.appendText("#{@emit_loc}: #{op} #{r} #{s} #{t}\n")
		@emit_loc += 1
		if @high_emit_loc < @emit_loc
			@high_emit_loc =  @emit_loc
		end
	end

	def emit_write(op, text)
		@file += "#{@emit_loc}: #{op} #{text}\n"
		@intermediate_code.appendText("#{@emit_loc}: #{op} #{text}\n")
		@emit_loc += 1
		if @high_emit_loc < @emit_loc
			@high_emit_loc =  @emit_loc
		end
	end

	def emit_rm(op, r, d, s, c)
		@file += "#{@emit_loc}: #{op} #{r} #{d} #{s}\n"
		@intermediate_code.appendText("#{@emit_loc}: #{op} #{r} #{d} #{s}\n")
		@emit_loc += 1
		if @high_emit_loc < @emit_loc
			@high_emit_loc =  @emit_loc
		end
	end

	def emit_skip(quantity)
		i = @emit_loc
		@emit_loc += quantity
		if @high_emit_loc < @emit_loc
			@high_emit_loc =  @emit_loc
		end
		i
	end

	def emit_backup(loc)
		if loc > @high_emit_loc
			puts "[BUG] emit_backup"
		end
		@emit_loc = loc
	end

	def emit_restore
		@emit_loc = @high_emit_loc
	end

	def emit_rm_abs(op, r, a, c)
		@file += "#{@emit_loc}: #{op} #{r} #{a - (@emit_loc + 1)} #{pc}\n"
		@intermediate_code.appendText("#{@emit_loc}: #{op} #{r} #{a - (@emit_loc + 1)} #{pc}\n")
		@emit_loc += 1
		if @high_emit_loc < @emit_loc
			@high_emit_loc =  @emit_loc
		end
	end

	def write_code
		out_file = File.new("int_code.txt", "w")
		out_file.puts(@file)
		out_file.close
	end

	def emit_comment(comment)
		puts comment
	end
end
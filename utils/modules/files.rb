module Files

  def load_file(filename)
    string = ''
    File.open(filename, 'r') do | reader |
      while line = reader.gets
        string += line
      end
    end
    return string
  end

  def save_file(filename, string)
    File.open(filename, 'w') do | writer |
      writer.puts string
    end
  end

end
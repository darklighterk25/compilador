module Icons

  def load_icon(filename)
    begin
      filename = File.join("./utils/icons", filename)
      icon = nil
      File.open(filename, "rb") { | file |
        icon = FXPNGIcon.new(getApp(), file.read)
      }
      icon
    rescue
      raise RuntimeError, "No se pudo cargar el ícono: #{filename}"
    end
  end

end
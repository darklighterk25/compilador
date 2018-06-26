require 'fox16'
require_relative '../lexical_analyzer/lexical_analyzer'
require_relative '../semantic_analyzer/semantic_analyzer'
require_relative '../syntax_analyzer/syntax_analyzer'
require_relative '../utils/modules/files'
require_relative '../utils/modules/icons'

class IDE < FXMainWindow

  include Files
  include Fox
  include Icons

  def create
    super
    show(PLACEMENT_SCREEN) # Por defecto las ventanas en FXRuby están ocultas, el método show las muestra y PLACEMENT_SCREEN la centra en la pantalla.
  end

  def initialize(app)
    super(app, "IDE", :width => 1152, :height => 648)

    # Íconos.
    @compile_icon = load_icon("compile.png")
    @exit_icon = load_icon("exit.png")
    @icon = load_icon("icon.png") # Ícono que aparece en la barra de tareas.
    @menu_icon = load_icon("menu.png")
    @mini_icon = load_icon("mini.png") # Ícono que aparece en la ventana.
    @new_icon = load_icon("new.png")
    @open_icon = load_icon("open.png")
    @save_icon = load_icon("save.png")
    @save_as_icon = load_icon("save_as.png")
    setIcon(@icon)
    setMiniIcon(@mini_icon)

    # Variables de control.
    @filename = ''
    @loaded = false
    @saved = false

    # Inicialización de componentes de la ventana.
    init_menu_bar
    init_contents
    init_text_styles

    # El analizador léxico se inicializa en el constructor ya que este corre en tiempo real.
    @lexical_analyzer = LexicalAnalyzer.new(@lexical_table)

    # Control de estilos de texto.
    @code_length = 0
  end

  # Utiliza el array generado por el analizador léxico para definir los estilos de texto.
  private
  def change_style
    @code.changeStyle(0, @code.getText.length, 1) # Pinta todo el texto del estilo predeterminado.
    tokens = @lexical_analyzer.tokens
    tokens.each do | token | # Itera todos los tokens para extraer la posición y estilo correspondiente.
      @code.changeStyle(token.range[:start], (token.range[:end] - token.range[:start]), token.style)
    end
  end

  # Reinicia los campos.
  private
  def clear_contents
    @loaded = false
    @saved = false
    @filename = ''
    @code.setText('')
    @results_text.setText('')
    @errors_text.setText('')
    @lexical_table.clearItems
    @syntax_tree_list.clearItems
    @semantic_text.setText('')
  end

  # Inicia el proceso de compilación.
  private
  def compile
    text_control
    lexical_analysis
    syntax_analysis
    semantic_analysis
  end

  # Actualiza el contador de filas/columnas.
  private
  def cursor_position
    @cur_pos_x.setText((@code.getCursorColumn + 1).to_s)
    @cur_pos_y.setText((@code.getCursorRow + 1).to_s)
  end

  # Genera el contenido de la ventana.
  private
  def init_contents
    contents = FXHorizontalFrame.new(self,  LAYOUT_FILL_X|LAYOUT_FILL_Y,
                                     :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0,
                                     :hSpacing => 0, :vSpacing => 0)
    # Spring análisis (Anchura absoluta).
    FXSpring.new(contents, LAYOUT_FILL_Y, :width => 5) do | spring |
      # Salidas del análisis.
      analysis_tabs = FXTabBook.new(spring, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_BOTTOM)
      analysis_tabs.setBackColor(FXRGB(50, 50, 50))
      analysis_tabs.tabStyle = TABBOOK_BOTTOMTABS
      # Primer pestaña (Léxico).
      lexical_tab = FXTabItem.new(analysis_tabs, "Léxico", nil)
      lexical_tab.setBackColor(FXRGB(50, 50, 50))
      lexical_tab.setTextColor(FXRGB(255, 255, 255))
      lexical_frame = FXHorizontalFrame.new(analysis_tabs)
      lexical_frame.setBackColor(FXRGB(50, 50, 50))
      @lexical_table = FXTable.new(lexical_frame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|\
                                                          TABLE_NO_COLSELECT|TABLE_NO_ROWSELECT)
      # Segunda pestaña (Sintáctico).
      syntax_tab = FXTabItem.new(analysis_tabs, "Sintáctico", nil)
      syntax_tab.setBackColor(FXRGB(50, 50, 50))
      syntax_tab.setTextColor(FXRGB(255, 255, 255))
      syntax_frame = FXHorizontalFrame.new(analysis_tabs)
      syntax_frame.setBackColor(FXRGB(50, 50, 50))
      @syntax_tree_list = FXTreeList.new(syntax_frame, :opts => TREELIST_NORMAL|TREELIST_SHOWS_LINES|\
                                                                TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|LAYOUT_FILL)
      @syntax_tree_list.setBackColor(FXRGB(50, 50, 50))
      @syntax_tree_list.setTextColor(FXRGB(200, 200, 200))
      # Tercer pestaña (Semántico).
      semantic_tab = FXTabItem.new(analysis_tabs, "Semántico", nil)
      semantic_tab.setBackColor(FXRGB(50, 50, 50))
      semantic_tab.setTextColor(FXRGB(255, 255, 255))
      semantic_frame = FXHorizontalFrame.new(analysis_tabs)
      semantic_frame.setBackColor(FXRGB(50, 50, 50))
      @semantic_text = FXText.new(semantic_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_READONLY)
      @semantic_text.setBackColor(FXRGB(50, 50, 50))
      @semantic_text.setTextColor(FXRGB(200, 200, 200))
      # Cuarta pestaña (Tabla Hash).
      hash_tab = FXTabItem.new(analysis_tabs, "Tabla Hash", nil)
      hash_tab.setBackColor(FXRGB(50, 50, 50))
      hash_tab.setTextColor(FXRGB(255, 255, 255))
      hash_frame = FXHorizontalFrame.new(analysis_tabs)
      hash_frame.setBackColor(FXRGB(50, 50, 50))
      @hash_text = FXText.new(hash_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_READONLY)
      @hash_text.setBackColor(FXRGB(50, 50, 50))
      @hash_text.setTextColor(FXRGB(200, 200, 200))
      # Quinta pestaña (Código intermedio).
      intermediate_tab = FXTabItem.new(analysis_tabs, "Código Intermedio", nil)
      intermediate_tab.setBackColor(FXRGB(50, 50, 50))
      intermediate_tab.setTextColor(FXRGB(255, 255, 255))
      intermediate_frame = FXHorizontalFrame.new(analysis_tabs)
      intermediate_frame.setBackColor(FXRGB(50, 50, 50))
      @intermediate_text = FXText.new(intermediate_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_READONLY)
      @intermediate_text.setBackColor(FXRGB(50, 50, 50))
      @intermediate_text.setTextColor(FXRGB(200, 200, 200))
    end
    # Spring texto (Anchura relativa 60%).
    FXSpring.new(contents, LAYOUT_FILL_X|LAYOUT_FILL_Y, :relw => 60) do |spring|
      @code = FXText.new(spring, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_SHOWACTIVE)
      @code.setMarginLeft(10)
      @code.setBackColor(FXRGB(50, 50, 50))
      @code.setTextColor(FXRGB(200, 200, 200))
      @code.setActiveBackColor(FXRGB(70, 70, 70))
      @code.setCursorColor(FXRGB(250, 250, 250))
      @code.barColumns = 5 # Contador de líneas.
      @code.setBarColor(FXRGB(220, 220, 220))
      @code.connect(SEL_CHANGED) do
        cursor_position
        text_control
      end
    end
    # Spring resultados (Anchura relativa 40%).
    FXSpring.new(contents, LAYOUT_FILL_X|LAYOUT_FILL_Y, :relw => 40) do | spring |
      # Salidas del código.
      output_tabs = FXTabBook.new(spring, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP)
      output_tabs.setBackColor(FXRGB(50, 50, 50))
      output_tabs.tabStyle = TABBOOK_BOTTOMTABS
      # Primer Pestaña (Resultados).
      results_tab = FXTabItem.new(output_tabs, "Salida ", nil)
      results_tab.setBackColor(FXRGB(50, 50, 50))
      results_tab.setTextColor(FXRGB(255, 255, 255))
      results_frame = FXHorizontalFrame.new(output_tabs)
      results_frame.setBackColor(FXRGB(50, 50, 50))
      @results_text = FXText.new(results_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_READONLY)
      @results_text.setBackColor(FXRGB(50, 50, 50))
      @results_text.setTextColor(FXRGB(0, 255, 0))
      @results_text.setCursorColor(FXRGB(50, 50, 50))
      # Segunda pestaña (Errores).
      errors_tab = FXTabItem.new(output_tabs, "Errores", nil)
      errors_tab.setBackColor(FXRGB(50, 50, 50))
      errors_tab.setTextColor(FXRGB(255, 255, 255))
      errors_frame = FXHorizontalFrame.new(output_tabs)
      errors_frame.setBackColor(FXRGB(50, 50, 50))
      @errors_text = FXText.new(errors_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_READONLY)
      @errors_text.setBackColor(FXRGB(50, 50, 50))
      @errors_text.setTextColor(FXRGB(255, 0, 0))
      @errors_text.setCursorColor(FXRGB(50, 50, 50))
    end
  end

  # Genera la barra de menú.
  private
  def init_menu_bar
    menu_frame = FXHorizontalFrame.new(self, LAYOUT_SIDE_TOP | LAYOUT_FILL_X)
    menu_frame.setBackColor(FXRGB(50, 50, 50))
    # Menú desplegable.
    menu_bar = FXMenuBar.new(menu_frame, :width => 30, :height => 30)
    menu_bar.setBackColor(FXRGB(50, 50, 50))
    menu_pane = FXMenuPane.new(menu_frame) # Menu Pane es una ventana pop-up.
    menu_pane.setBackColor(FXRGB(50, 50, 50))
    menu_title = FXMenuTitle.new(menu_bar, '', @menu_icon, :popupMenu => menu_pane) # FXMenuTitle es un hijo de FXMenuBar, :popupMenu le indica que activará a file_menu.
    menu_title.setBackColor(FXRGB(50, 50, 50))
    new = FXMenuCommand.new(menu_pane, "Nuevo", @new_icon)
    new.connect(SEL_COMMAND) do # El método connect asociamos un bloque de código a load_cmd.
      new_dialog
    end
    load = FXMenuCommand.new(menu_pane, "Cargar", @open_icon)
    load.connect(SEL_COMMAND) do
      load_dialog
    end
    save = FXMenuCommand.new(menu_pane, "Guardar", @save_icon)
    save.connect(SEL_COMMAND) do
      save_changes
    end
    save_as = FXMenuCommand.new(menu_pane, "Guardar como", @save_as_icon)
    save_as.connect(SEL_COMMAND) do
      save_as_dialog
    end
    FXMenuSeparator.new(menu_pane)
    quit = FXMenuCommand.new(menu_pane, "Salir", @exit_icon)
    quit.connect(SEL_COMMAND) do
      exit
    end
    # Botones.
    new_button = FXButton.new(menu_bar, '', @new_icon, :opts => BUTTON_TOOLBAR,
                              :width => 30, :height => 30)
    new_button.setBackColor(FXRGB(50, 50, 50))
    new_button.connect(SEL_COMMAND) do
      new_dialog
    end
    load_button = FXButton.new(menu_bar, '', @open_icon, :opts => BUTTON_TOOLBAR,
                               :width => 30, :height => 30)
    load_button.setBackColor(FXRGB(50, 50, 50))
    load_button.connect(SEL_COMMAND) do
      load_dialog
    end
    save_button = FXButton.new(menu_bar, '', @save_icon, :opts => BUTTON_TOOLBAR,
                               :width => 30, :height => 30)
    save_button.setBackColor(FXRGB(50, 50, 50))
    save_button.connect(SEL_COMMAND) do
      save_changes
    end
    compile_button = FXButton.new(menu_bar, '', @compile_icon, :opts => BUTTON_TOOLBAR,
                                  :width => 30, :height => 30)
    compile_button.setBackColor(FXRGB(50, 50, 50))
    compile_button.connect(SEL_COMMAND) do
      compile
    end
    # Contador de líneas/columnas.
    @cur_pos_x = FXButton.new(menu_bar, '1', :opts => LAYOUT_RIGHT, :width => 30, :height => 30)
    @cur_pos_x.setBackColor(FXRGB(50, 50, 50))
    @cur_pos_x.setTextColor(FXRGB(255, 255, 255))
    column = FXLabel.new(menu_bar, "Columna: ", :opts => LAYOUT_RIGHT)
    column.setBackColor(FXRGB(50, 50, 50))
    column.setTextColor(FXRGB(255, 255, 255))
    @cur_pos_y = FXButton.new(menu_bar, '1', :opts => LAYOUT_RIGHT, :width => 30, :height => 30)
    @cur_pos_y.setBackColor(FXRGB(50, 50, 50))
    @cur_pos_y.setTextColor(FXRGB(255, 255, 255))
    line = FXLabel.new(menu_bar, "Línea: ", :opts => LAYOUT_RIGHT)
    line.setBackColor(FXRGB(50, 50, 50))
    line.setTextColor(FXRGB(255, 255, 255))
  end

  # Genera el array de los estilos de texto.
  private
  def init_text_styles
    @code.styled = true
    # Valor por defecto (1).
    error = FXHiliteStyle.from_text(@code)
    error.normalForeColor = FXRGB(255, 50, 0) # Rojo.
    # Identificadores (2).
    id = FXHiliteStyle.from_text(@code)
    id.normalForeColor = FXRGB(0, 255, 255) # Turquesa.
    # Palabras reservadas (3).
    reserved = FXHiliteStyle.from_text(@code)
    reserved.normalForeColor = FXRGB(255, 77, 210) # Rosa.
    reserved.style = FXText::STYLE_BOLD
    # Caracteres especiales (4).
    special = FXHiliteStyle.from_text(@code)
    special.normalForeColor = FXRGB(220, 220, 220) # Gris claro.
    # Números (5).
    number = FXHiliteStyle.from_text(@code)
    number.normalForeColor = FXRGB(102, 179, 255) # Azul.
    # Cadenas (6).
    string = FXHiliteStyle.from_text(@code)
    string.normalForeColor = FXRGB(255, 255, 77) # Amarillo.
    # Comentarios (7).
    comments = FXHiliteStyle.from_text(@code)
    comments.normalForeColor = FXRGB(150, 150, 150) # Gris oscuro.
    # Se fijan los estilos al array.
    @code.hiliteStyles = [ error, id, reserved, special, number, string, comments]
  end

  # Inicia el análizador léxico, genera la tabla y concatena errores.
  private
  def lexical_analysis
    @lexical_analyzer.run(@code.getText) # Corremos el análisis léxico. Mandamos el contenido del campo de texto.
    @errors_text.setText(@lexical_analyzer.errors) # Se mandan los errores generados por el análisis léxico al campo de errores.
  end

  private
  def load_dialog
    dialog = FXFileDialog.new(self, "Cargar un archivo")
    dialog.selectMode = SELECTFILE_EXISTING
    dialog.patternList = ["*.txt", "*.rb", "Todos los archivos (*)"]
    if dialog.execute != 0
      @code.setText(load_file(dialog.filename)) # El contenido del archivo cargado se manda al campo de texto.
      lexical_analysis
      change_style
      @loaded = true
      @filename = dialog.filename
    end
  end

  # Crear nuevo archivo.
  private
  def new_dialog
    unless @saved
      answer = FXMessageBox.question(self, MBOX_YES_NO_CANCEL, "Advertencia", "¿Desea guardar los cambios?")
      case answer
        when MBOX_CLICKED_YES
          save_as_dialog
          clear_contents
        when MBOX_CLICKED_NO
          clear_contents
        when MBOX_CLICKED_CANCEL
          # No hace nada...
      end
    else
      clear_contents
    end
  end

  # Guarda cambios.
  private
  def save_changes
    if @loaded
      save_file(@filename, @code.text)
      @saved = true
    else
      save_as_dialog
    end
  end

  # Ventana de diálogo para "Guardar Como".
  private
  def save_as_dialog
    dialog = FXFileDialog.new(self, "Guardar un archivo")
    dialog.patternList = ["Todos los archivos (*)"]
    if dialog.execute != 0
      File.write(dialog.filename, @code.getText)
      @saved = true
    end
  end

  # Inicia el análizador semántico, genera el árbol y concatena errores.
  private
  def semantic_analysis
    if (@errors_text.text.length == 0) # Condición para comprobar que no hubo errores sintácticos.
      @semantic_analyzer = SemanticAnalyzer.new(@syntax_analyzer.syntax_tree)
      @errors_text.appendText(@semantic_analyzer.errors)
    else
      @errors_text.text += "\n\nNo se pudo iniciar el análisis semántico ya que existen errores en etapas previas."
    end
  end

  # Inicia el análizador sintáctico, genera el árbol y concatena errores.
  private
  def syntax_analysis
    if (@errors_text.text.length == 0) # Condición para comprobar que no hubo errores léxicos.
      @syntax_analyzer = SyntaxAnalyzer.new(@lexical_analyzer.tokens, @syntax_tree_list)
      @errors_text.appendText(@syntax_analyzer.errors)
    else
      @errors_text.text += "\n\nNo se pudo iniciar el análisis sintáctico ya que existen errores léxicos."
    end
  end

  # Manda llamar a los métodos que alteran los estilos de texto.
  private
  def text_control
    unless @code_length == @code.getText.length # Solamente si ha cambiado la longitud del texto.
      lexical_analysis
      change_style
      @code_length = @code.getText.length
    end
  end

end
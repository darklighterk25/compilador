# El propósito de este archivo es probar el analizador léxico independientemente del IDE.

require_relative 'lexical_analyzer'
require_relative '../utils/modules/files'

include Files

parameter = ARGV
string = load_file(parameter[0].to_s)
lexical = LexicalAnalyzer.new(nil, true)
lexical.run(string)
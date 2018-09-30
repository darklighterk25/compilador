require 'tree'
include Tree

class Node < TreeNode

  attr_reader :nodekind, :kind, :token 
  attr_accessor :value, :type

  def initialize(name, nodekind, kind, token)
    super(name, token)
    @nodekind = nodekind
    @kind = kind
    @string = ""
    @token = @content
    if (kind.eql?("constK"))
      @value = @token.lexeme.to_f
    else
      @value = 0
    end
  end

  def print_tree(level = self.node_depth, max_depth = nil,
                 block = lambda { |node, prefix|
                 @string += "#{prefix} #{node.token.lexeme}\n" })
    prefix = ''

    if is_root?
      prefix << '*'
    else
      prefix << '|' unless parent.is_last_sibling?
      prefix << (' ' * (level - 1) * 4)
      prefix << (is_last_sibling? ? '+' : '|')
      prefix << '---'
      prefix << (has_children? ? '+' : '>')
    end

    block.call(self, prefix)

    # Condición de salida.
    return unless max_depth.nil? || level < max_depth
      children { |child|
        child.print_tree(level + 1,
                         max_depth, block) if child }

  end

  def to_s
    self.print_tree
    @string
  end

end
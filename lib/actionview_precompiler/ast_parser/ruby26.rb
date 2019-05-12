module ActionviewPrecompiler
  module ASTParser
    class RubyVM::AbstractSyntaxTree::Node
      def argument_nodes
        children[1].children[0...-1]
      end

      def array?
        type == :ARRAY
      end

      def fcall?
        type == :FCALL
      end

      def hash?
        type == :HASH
      end

      def string?
        type == :STR && String === children[0]
      end

      def symbol?
        type == :LIT && Symbol === children[0]
      end

      def to_hash
        children[0].children[0..-2].each_slice(2).to_h
      end

      def to_string
        children[0]
      end

      def to_symbol
        children[0]
      end
    end

    def parse(code)
      RubyVM::AbstractSyntaxTree.parse(code)
    end

    def node?(node)
      RubyVM::AbstractSyntaxTree::Node === node
    end

    def fcall?(node, name)
      node.fcall? &&
        node.children[0] == name &&
        node.children[1] && node.children[1].array?
    end
  end
end

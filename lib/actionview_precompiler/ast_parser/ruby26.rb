module ActionviewPrecompiler
  module ASTParser
    class Node
      def self.wrap(node)
        if RubyVM::AbstractSyntaxTree::Node === node
          new(node)
        else
          node
        end
      end

      def initialize(node)
        @node = node
      end

      def children
        @children ||= @node.children.map do |child|
          self.class.wrap(child)
        end
      end

      def inspect
        "#<#{self.class} #{@node.inspect}>"
      end

      def argument_nodes
        children[1].children[0...-1]
      end

      def array?
        type == :ARRAY || type == :LIST
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

      def fcall_named?(name)
        fcall? &&
          children[0] == name &&
          children[1] &&
          children[1].array?
      end

      private

      def type
        @node.type
      end
    end

    def parse(code)
      Node.wrap(RubyVM::AbstractSyntaxTree.parse(code))
    end

    def node?(node)
      Node === node
    end

    def fcall?(node, name)
      node.fcall_named?(name)
    end
  end
end

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
        list = children[0]
        if list.nil?
          {}
        else
          list.children[0..-2].each_slice(2).to_h
        end
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

    def extract_render_nodes(node)
      return [] unless node?(node)
      renders = node.children.flat_map { |c| extract_render_nodes(c) }
      if render_call?(node)
        renders << node
      end
      renders
    end

    def render_call?(node)
      fcall?(node, :render)
    end
  end
end

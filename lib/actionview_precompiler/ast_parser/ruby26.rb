module ActionviewPrecompiler
  module Ruby26ASTParser
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
        if children[1].array?
          children[1].children[0...-1]
        elsif children[1].block_pass?
          children[1].children[0].children[0...-1]
        else
          raise "can't call argument_nodes on #{inspect}"
        end
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

      def block_pass?
        type == :BLOCK_PASS
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
          hash = list.children[0..-2].each_slice(2).to_h
          return nil if hash.key?(nil)
          hash
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
          (children[1].array? || (children[1].block_pass? && children[1].children[0].array?))
      end

      private

      def type
        @node.type
      end
    end

    extend self

    METHODS_TO_PARSE = %i(render render_to_string)

    def parse_render_nodes(code)
      renders = extract_render_nodes(parse(code))

      renders.group_by(&:first).collect do |method, nodes|
        [ method, nodes.collect { |v| v[1] } ]
      end.to_h
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

      is_render, method = render_call?(node)
      renders << [method, node] if is_render

      renders
    end

    def render_call?(node)
      METHODS_TO_PARSE.each { |m| return [true, m] if fcall?(node, m) }
      false
    end
  end
end

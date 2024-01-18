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

      def variable_reference?
        type == :IVAR || type == :GVAR || type == :CVAR
      end

      def variable_name
        children[0].to_s
      end

      def vcall?
        type == :VCALL
      end

      def call?
        type == :CALL
      end

      def call_method_name
        children[1].to_s
      end

      def symbol?
        (type == :SYM) || (type == :LIT && Symbol === children[0])
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

    METHODS_TO_PARSE = %i(render render_to_string layout)

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

    def extract_render_nodes(root)
      renders = []
      queue = [root]

      while node = queue.shift
        node.children.each do |child|
          queue << child if node?(child)
        end

        method_name = render_call?(node)
        renders << [method_name, node] if method_name
      end

      renders
    end

    def render_call?(node)
      METHODS_TO_PARSE.detect { |m| fcall?(node, m) }
    end
  end
end

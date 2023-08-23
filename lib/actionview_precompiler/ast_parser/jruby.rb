module ActionviewPrecompiler
  module JRubyASTParser
    class Node
      def self.wrap(node)
        if org::jruby::ast::Node === node
          new(node)
        else
          node
        end
      end

      def initialize(node)
        @node = node
      end

      def children
        @children ||= @node.child_nodes.map do |child|
          self.class.wrap(child)
        end
      end

      def array?;  org::jruby::ast::ArrayNode  === @node; end
      def fcall?;  org::jruby::ast::FCallNode  === @node; end
      def hash?;   org::jruby::ast::HashNode   === @node; end
      def string?; org::jruby::ast::StrNode    === @node; end
      def symbol?; org::jruby::ast::SymbolNode === @node; end

      def variable_reference?
        org::jruby::ast::InstVarNode === @node ||
          org::jruby::ast::GlobalVarNode === @node ||
          org::jruby::ast::ClassVarNode === @node
      end

      def vcall?
        org::jruby::ast::VCallNode === @node;
      end

      def call?
        org::jruby::ast::CallNode === @node;
      end

      def variable_name
        self[0][0]
      end

      def call_method_name
        self.last.first
      end

      def argument_nodes
        @node.args_node.children.to_a[0...@node.args_node.size].map do |arg|
          self.class.wrap(arg)
        end
      end

      def to_hash
        @node.pairs.each_with_object({}) do |pair, object|
          return nil if pair.key == nil
          object[self.class.wrap(pair.key)] = self.class.wrap(pair.value)
        end
      end

      def to_string
        @node.value
      end

      def variable_name
        @node.name.to_s
      end

      def call_method_name
        @node.name.to_s
      end

      def to_symbol
        @node.name
      end

      def fcall_named?(name)
        fcall? &&
          @node.name == name &&
          @node.args_node &&
          org::jruby::ast::ArrayNode === @node.args_node
      end
    end

    extend self

    METHODS_TO_PARSE = %i(render render_to_string layout)

    def parse_render_nodes(code)
      node = Node.wrap(JRuby.parse(code))

      renders = extract_render_nodes(node)
      renders.group_by(&:first).collect do |method, nodes|
        [ method, nodes.collect { |v| v[1] } ]
      end.to_h
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

      method_name = render_call?(node)
      renders << [method_name, node] if method_name

      renders
    end

    def render_call?(node)
      METHODS_TO_PARSE.detect { |m| fcall?(node, m) }
    end
  end
end

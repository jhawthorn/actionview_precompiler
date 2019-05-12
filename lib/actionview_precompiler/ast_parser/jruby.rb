module ActionviewPrecompiler
  module ASTParser
    class org::jruby::ast::Node
      alias children child_nodes
      alias type node_type

      def array?; false; end
      def hash?; false; end
      def fcall?; false; end
      def string?; false; end
      def symbol?; false; end
    end

    class org::jruby::ast::ArrayNode
      def array?
        true
      end
    end

    class org::jruby::ast::FCallNode
      def argument_nodes
        args_node.to_a[0...args_node.size]
      end

      def fcall?
        true
      end
    end

    class org::jruby::ast::HashNode
      def hash?
        true
      end

      def keys
        @keys ||= pairs.map { |k, v| v }
      end

      def to_hash
        pairs.each_with_object({}) do |pair, object|
          object[pair.key] = pair.value
        end
      end
    end

    class org::jruby::ast::StrNode
      def string?
        true
      end

      def to_string
        value
      end
    end

    class org::jruby::ast::SymbolNode
      def symbol?
        true
      end

      def to_symbol
        name
      end
    end

    def parse(code = compiled_source)
      JRuby.parse(code)
    end

    def node?(node)
      org.jruby.ast.Node === node
    end

    def fcall?(node, name)
      node.fcall? &&
        node.name == name &&
        node.args_node && node.args_node.array?
    end
  end
end

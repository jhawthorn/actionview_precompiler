module ActionviewPrecompiler
  module ASTParser
    if RUBY_ENGINE == 'jruby'
      require 'jruby'

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
    else
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
      
      def parse(code = compiled_source)
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
end

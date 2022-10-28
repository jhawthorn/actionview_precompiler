# frozen_string_literal: true

require "syntax_tree"

module ActionviewPrecompiler
  module SyntaxTreeASTParser
    # This error is raised whenever an assumption we made wasn't met by the AST.
    class CompilationError < StandardError
    end

    # Each call object is responsible for holding a list of arguments and should
    # respond to a single #arguments_node method that returns an array of
    # arguments.
    class RenderCall
      attr_reader :argument_nodes

      def initialize(argument_nodes)
        @argument_nodes = argument_nodes
      end
    end

    # This class represents a node in the tree that is returned by the parser
    # that corresponds to an argument to a render call, or a child of one of
    # those nodes.
    class RenderNode
      attr_reader :node

      def initialize(node)
        @node = node
      end

      def call?
        node.is_a?(SyntaxTree::Call)
      end

      def call_method_name
        node.message.value
      end

      def hash?
        node.is_a?(SyntaxTree::HashLiteral) || node.is_a?(SyntaxTree::BareAssocHash)
      end

      def string?
        node.is_a?(SyntaxTree::StringLiteral)
      end

      def symbol?
        node.is_a?(SyntaxTree::Label) || node.is_a?(SyntaxTree::SymbolLiteral)
      end

      def variable_reference?
        node.is_a?(SyntaxTree::VarRef)
      end

      def variable_name
        node.value.value
      end

      def vcall?
        node.is_a?(SyntaxTree::VCall)
      end

      # Converts the node into a hash where the keys and values are nodes. This
      # will raise an error if the hash doesn't match the format we expect or
      # if the hash contains any splats.
      def to_hash
        case node
        in SyntaxTree::HashLiteral[assocs:]
        in SyntaxTree::BareAssocHash[assocs:]
        else
          raise CompilationError, "Unexpected node type: #{node.class.name}"
        end

        assocs.to_h do |assoc|
          case assoc
          in SyntaxTree::Assoc[key:, value:]
            [RenderNode.new(key), RenderNode.new(value)]
          else
            raise CompilationError, "Unexpected node type: #{node.class.name}"
          end
        end
      end

      # Converts the node into a string value. Only handles plain string
      # content, and will raise an error if the node contains interpolation.
      def to_string
        case node
        in SyntaxTree::StringLiteral[parts: [SyntaxTree::TStringContent[value:]]]
          value
        in SyntaxTree::StringLiteral[parts:]
          raise CompilationError, "Unexpected string parts type: #{parts.inspect}"
        else
          raise CompilationError, "Unexpected node type: #{node.class.name}"
        end
      end

      # Converts the node into a symbol value. Only handles labels and plain
      # symbols, and will raise an error if the node contains interpolation.
      def to_symbol
        case node
        in SyntaxTree::Label[value:]
          value.chomp(":").to_sym
        in SyntaxTree::SymbolLiteral[value: SyntaxTree::Ident[value:]]
          value.to_sym
        in SyntaxTree::SymbolLiteral[value:]
          raise CompilationError, "Unexpected symbol value type: #{value.inspect}"
        else
          raise CompilationError, "Unexpected node type: #{node.class.name}"
        end
      end
    end

    # This visitor is responsible for visiting the parsed tree and extracting
    # out the render calls. After visiting the tree, the #render_calls method
    # will return the hash expected by the #parse_render_nodes method.
    class RenderVisitor < SyntaxTree::Visitor
      MESSAGE = /\A(render|render_to_string|layout)\z/

      attr_reader :render_calls

      def initialize
        @render_calls = Hash.new { |hash, key| hash[key] = [] }
      end

      visit_method def visit_command(node)
        case node
        in SyntaxTree::Command[
             message: SyntaxTree::Ident[value: MESSAGE],
             arguments: SyntaxTree::Args[parts:]
           ]
          argument_nodes = parts.map { |part| RenderNode.new(part) }
          render_calls[$1.to_sym] << RenderCall.new(argument_nodes)
        else
        end

        super
      end

      visit_method def visit_fcall(node)
        case node
        in SyntaxTree::FCall[
             value: SyntaxTree::Ident[value: MESSAGE],
             arguments: SyntaxTree::ArgParen[arguments: SyntaxTree::Args[parts:]]
           ]
          argument_nodes = parts.map { |part| RenderNode.new(part) }
          render_calls[$1.to_sym] << RenderCall.new(argument_nodes)
        else
        end

        super
      end
    end

    # Main entrypoint into this AST parser variant. It's responsible for
    # returning a hash of render calls. The keys are the method names, and the
    # values are arrays of call objects.
    def self.parse_render_nodes(code)
      visitor = RenderVisitor.new
      SyntaxTree.parse(code).accept(visitor)
      visitor.render_calls
    rescue SyntaxTree::Parser::ParseError
      raise CompilationError, "Unable to parse the template"
    end
  end
end

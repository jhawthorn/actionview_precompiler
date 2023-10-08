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
        node.is_a?(SyntaxTree::CallNode)
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

      def vcall?
        node.is_a?(SyntaxTree::VCall)
      end

      def call_method_name
        node.message.value
      end

      def variable_name
        node.value.value
      end

      # Converts the node into a hash where the keys and values are nodes. This
      # will raise an error if the hash doesn't match the format we expect or
      # if the hash contains any splats.
      def to_hash
        if hash?
          if node.assocs.all? { |assoc| assoc.is_a?(SyntaxTree::Assoc) }
            node.assocs.to_h { |assoc| [RenderNode.new(assoc.key), RenderNode.new(assoc.value)] }
          end
        else
          raise CompilationError, "Unexpected node type: #{node.class.name}"
        end
      end

      # Converts the node into a string value. Only handles plain string
      # content, and will raise an error if the node contains interpolation.
      def to_string
        if string?
          parts = node.parts
          if parts.length != 1 || !parts[0].is_a?(SyntaxTree::TStringContent)
            raise CompilationError, "Unexpected string parts type: #{parts.inspect}"
          end

          node.parts[0].value
        else
          raise CompilationError, "Unexpected node type: #{node.class.name}"
        end
      end

      # Converts the node into a symbol value. Only handles labels and plain
      # symbols, and will raise an error if the node contains interpolation.
      def to_symbol
        if node.is_a?(SyntaxTree::Label)
          node.value.chomp(":").to_sym
        elsif node.is_a?(SyntaxTree::SymbolLiteral)
          if !node.value.is_a?(SyntaxTree::Ident)
            raise CompilationError, "Unexpected symbol value type: #{node.value.inspect}"
          end

          node.value.value.to_sym
        else
          raise CompilationError, "Unexpected node type: #{node.class.name}"
        end
      end
    end

    # This visitor is responsible for visiting the parsed tree and extracting
    # out the render calls. After visiting the tree, the #render_calls method
    # will return the hash expected by the #parse_render_nodes method.
    class RenderVisitor < SyntaxTree::Visitor
      MESSAGE = /\A(?:render|render_to_string|layout)\z/

      attr_reader :render_calls

      def initialize
        @render_calls = Hash.new { |hash, key| hash[key] = [] }
      end

      visit_method def visit_command(node)
        if node.message.is_a?(SyntaxTree::Ident) &&
           node.message.value.match?(MESSAGE) &&
           node.arguments.is_a?(SyntaxTree::Args)
          render_call(node, node.arguments)
        end

        super
      end

      visit_method def visit_call(node)
        if node.message.is_a?(SyntaxTree::Ident) &&
           node.message.value.match?(MESSAGE) &&
           node.arguments.is_a?(SyntaxTree::ArgParen) &&
           node.arguments.arguments.is_a?(SyntaxTree::Args)
          render_call(node, node.arguments.arguments)
        end

        super
      end

      private

      def render_call(node, arguments)
        render_nodes =
          arguments.parts.map do |part|
            if part.is_a?(SyntaxTree::Paren) && !part.contents.is_a?(SyntaxTree::Statements)
              RenderNode.new(part.contents)
            else
              RenderNode.new(part)
            end
          end

        render_nodes.pop if arguments.parts.last.is_a?(SyntaxTree::ArgBlock)
        render_calls[node.message.value.to_sym] << RenderCall.new(render_nodes)
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

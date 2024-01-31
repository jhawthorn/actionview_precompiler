# frozen_string_literal: true

require "prism"

module ActionviewPrecompiler
  module PrismASTParser
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
        node.is_a?(Prism::CallNode)
      end

      def hash?
        node.is_a?(Prism::HashNode) || node.is_a?(Prism::KeywordHashNode)
      end

      def string?
        node.is_a?(Prism::StringNode)
      end

      def symbol?
        node.is_a?(Prism::SymbolNode)
      end

      def variable_reference?
        case node.type
        when :class_variable_read_node, :instance_variable_read_node,
             :global_variable_read_node, :local_variable_read_node
          true
        else
          false
        end
      end

      def vcall?
        node.is_a?(Prism::CallNode) && node.variable_call?
      end

      def call_method_name
        node.message
      end

      def variable_name
        case node.type
        when :class_variable_read_node, :instance_variable_read_node,
             :global_variable_read_node, :local_variable_read_node
          node.name.name
        when :call_node
          node.message
        end
      end

      # Converts the node into a hash where the keys and values are nodes. This
      # will raise an error if the hash doesn't match the format we expect or
      # if the hash contains any splats.
      def to_hash
        if hash?
          if node.elements.all? { |assoc| assoc.is_a?(Prism::AssocNode) && assoc.key.is_a?(Prism::SymbolNode) }
            node.elements.to_h { |assoc| [RenderNode.new(assoc.key), RenderNode.new(assoc.value)] }
          end
        else
          raise CompilationError, "Unexpected node type: #{node.inspect}"
        end
      end

      # Converts the node into a string value. Only handles plain string
      # content, and will raise an error if the node contains interpolation.
      def to_string
        if string?
          node.unescaped
        else
          raise CompilationError, "Unexpected node type: #{node.inspect}"
        end
      end

      # Converts the node into a symbol value. Only handles labels and plain
      # symbols, and will raise an error if the node contains interpolation.
      def to_symbol
        if symbol?
          node.unescaped.to_sym
        else
          raise CompilationError, "Unexpected node type: #{node.inspect}"
        end
      end
    end

    # This visitor is responsible for visiting the parsed tree and extracting
    # out the render calls. After visiting the tree, the #render_calls method
    # will return the hash expected by the #parse_render_nodes method.
    class RenderVisitor < Prism::Visitor
      MESSAGE = /\A(render|render_to_string|layout)\z/

      attr_reader :render_calls

      def initialize
        @render_calls = Hash.new { |hash, key| hash[key] = [] }
      end

      def visit_call_node(node)
        if node.name.match?(MESSAGE) && !node.receiver && node.arguments
          args =
            node.arguments.arguments.map do |arg|
              if arg.is_a?(Prism::ParenthesesNode) && arg.body && arg.body.body.length == 1
                RenderNode.new(arg.body.body.first)
              else
                RenderNode.new(arg)
              end
            end

          render_calls[node.name.to_sym] << RenderCall.new(args)
        end

        super
      end
    end

    # Main entrypoint into this AST parser variant. It's responsible for
    # returning a hash of render calls. The keys are the method names, and the
    # values are arrays of call objects.
    def self.parse_render_nodes(code)
      visitor = RenderVisitor.new
      result = Prism.parse(code)

      if result.success?
        result.value.accept(visitor)
        visitor.render_calls
      else
        raise CompilationError, "Unable to parse the template"
      end
    end
  end
end

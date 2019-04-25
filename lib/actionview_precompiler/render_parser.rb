require "parser/current"

module ActionviewPrecompiler
  RenderCall = Struct.new(:render_type, :template, :locals, :locals_keys) do
    def virtual_path
      if render_type == :partial
        @virtual_path ||= template.gsub(%r{/([^/]*)\z}, '/_\1')
      else
        template
      end
    end
  end

  class RenderParser
    def initialize(code)
      @code = code
      @code = Parser::CurrentRuby.parse(code) if code.is_a?(String)
    end

    def render_calls
      render_nodes = extract_render_nodes(@code)
      render_nodes.map do |node|
        parse_render(node)
      end.compact
    end

    private

    def parse_render(node)
      node = node.to_a
      if (node.length == 3 || node.length == 4) && node[2].type == :str
        # FIXME: from template vs controller
        options = {}
        options[:partial] = node[2]
        if node.length == 4
          return unless node[3].type == :hash
          options[:locals] = node[3]
        end
        return parse_render_from_options(options)
      elsif node.length == 3 && node[2].type == :hash
        options = parse_hash_to_symbols(node[2])
        return parse_render_from_options(options)
      else
        nil
      end
    end

    def parse_hash(node)
      return nil unless node.type == :hash

      node.children.map do |pair|
        return nil unless pair.type == :pair
        pair.children
      end.to_h
    end

    def parse_hash_to_symbols(node)
      hash = parse_hash(node)
      return unless hash
      hash.transform_keys do |node|
        key = parse_sym(node)
        return unless key
        key
      end
    end

    RENDER_TYPE_KEYS = [:partial, :template, :layout]
    IGNORED_KEYS = [:formats]
    ALL_KNOWN_KEYS = [*RENDER_TYPE_KEYS, *IGNORED_KEYS, :locals]

    def parse_render_from_options(options_hash)
      keys = options_hash.keys

      unless (keys & RENDER_TYPE_KEYS).one?
        # Must have one of partial:, template:, or layout:
        return nil
      end

      unless (keys - ALL_KNOWN_KEYS).empty?
        # de-opt in case of unknown option
        return nil
      end

      render_type = (RENDER_TYPE_KEYS & RENDER_TYPE_KEYS)[0]
      template = parse_str(options_hash[render_type])

      if options_hash.key?(:locals)
        locals = options_hash[:locals]
        parsed_locals = parse_hash(locals)
        locals_keys = parsed_locals.keys.map do |local|
          return nil unless local.type == :str || local.type == :sym
          local.children[0]
        end
      else
        locals = Parser::AST::Node.new(:hash)
        locals_keys = []
      end

      RenderCall.new(render_type, template, locals, locals_keys)
    end

    def parse_str(node)
      node.children[0] if node.type == :str
    end

    def parse_sym(node)
      node.children[0] if node.type == :sym
    end

    def debug(message)
      warn message
    end

    def extract_render_nodes(node)
      return [] unless Parser::AST::Node === node
      renders = node.children.flat_map { |c| extract_render_nodes(c) }
      if node.type == :send && node.children[0] == nil && node.children[1] == :render
        renders << node
      end
      renders
    end
  end
end

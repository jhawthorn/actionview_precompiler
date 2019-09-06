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
    include ASTParser

    def initialize(code)
      @code = code
      @code = parse(code) if code.is_a?(String)
    end

    def render_calls
      render_nodes = extract_render_nodes(@code)
      render_nodes.map do |node|
        parse_render(node)
      end.compact
    end

    private

    def parse_render(node)
      node = node.argument_nodes
      if (node.length == 1 || node.length == 2) && node[0].string?
        # FIXME: from template vs controller
        options = {}
        options[:partial] = node[0]
        if node.length == 2
          return unless node[1].hash?
          options[:locals] = node[1]
        end
        return parse_render_from_options(options)
      elsif node.length == 1 && node[0].hash?
        options = parse_hash_to_symbols(node[0])
        return parse_render_from_options(options)
      else
        nil
      end
    end

    def parse_hash(node)
      node.hash? && node.to_hash
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
    ALL_KNOWN_KEYS = [*RENDER_TYPE_KEYS, *IGNORED_KEYS, :locals, :object, :collection, :as]

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

      render_type = (keys & RENDER_TYPE_KEYS)[0]
      template = parse_str(options_hash[render_type])
      return unless template

      if options_hash.key?(:locals)
        locals = options_hash[:locals]
        parsed_locals = parse_hash(locals)
        return nil unless parsed_locals
        locals_keys = parsed_locals.keys.map do |local|
          return nil unless local.symbol?
          local.to_symbol
        end
      else
        locals = nil
        locals_keys = []
      end

      if options_hash.key?(:object) || options_hash.key?(:collection)
        return nil if options_hash.key?(:object) && options_hash.key?(:collection)
        return nil unless options_hash.key?(:partial)

        as = if options_hash.key?(:as)
               parse_str(options_hash[:as]) || parse_sym(options_hash[:as])
             elsif File.basename(template) =~ /\A_?(.*?)(?:\.\w+)*\z/
               $1
             end

        return nil unless as

        locals_keys << as.to_sym
        if options_hash.key?(:collection)
          locals_keys << :"#{as}_counter"
          locals_keys << :"#{as}_iteration"
        end
      end

      RenderCall.new(render_type, template, locals, locals_keys)
    end

    def parse_str(node)
      node.string? && node.to_string
    end

    def parse_sym(node)
      node.symbol? && node.to_symbol
    end

    def debug(message)
      warn message
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

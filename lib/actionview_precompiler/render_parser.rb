module ActionviewPrecompiler
  RenderCall = Struct.new(:virtual_path, :locals_keys)

  class RenderParser
    def initialize(code, parser: ASTParser, from_controller: false)
      @code = code
      @parser = parser
      @from_controller = from_controller
    end

    def render_calls
      render_nodes = @parser.parse_render_nodes(@code)
      render_nodes.map do |method, nodes|
        parse_method = case method
        when :layout
          :parse_layout
        else
          :parse_render
        end

        nodes.map { |n| send(parse_method, n) }
      end.flatten.compact
    end

    private

    # Convert
    #   render("foo", ...)
    # into either
    #   render(template: "foo", ...)
    # or
    #   render(partial: "foo", ...)
    # depending on controller or view context
    def normalize_args(string, options_hash)
      if @from_controller
        if options_hash
          options = parse_hash_to_symbols(options_hash)
        else
          options = {}
        end
        return nil unless options
        options.merge(template: string)
      else
        if options_hash
          { partial: string, locals: options_hash }
        else
          { partial: string }
        end
      end
    end

    def parse_render(node)
      node = node.argument_nodes
      if (node.length == 1 || node.length == 2) && !node[0].hash?
        if node.length == 1
          options = normalize_args(node[0], nil)
        elsif node.length == 2
          return unless node[1].hash?
          options = normalize_args(node[0], node[1])
        end
        return nil unless options
        return parse_render_from_options(options)
      elsif node.length == 1 && node[0].hash?
        options = parse_hash_to_symbols(node[0])
        return nil unless options
        return parse_render_from_options(options)
      else
        nil
      end
    end

    def parse_layout(node)
      return nil unless from_controller?

      template = parse_str(node.argument_nodes[0])
      return nil unless template

      virtual_path = layout_to_virtual_path(template)
      RenderCall.new(virtual_path, [])
    end

    def parse_hash(node)
      node.hash? && node.to_hash
    end

    def parse_hash_to_symbols(node)
      hash = parse_hash(node)
      return unless hash
      hash.transform_keys do |key_node|
        key = parse_sym(key_node)
        return unless key
        key
      end
    end

    ALL_KNOWN_KEYS = [:partial, :template, :layout, :formats, :locals, :object, :collection, :as, :status, :content_type, :location, :spacer_template]

    def parse_render_from_options(options_hash)
      renders = []
      keys = options_hash.keys

      render_type_keys =
        if from_controller?
          [:partial, :template]
        else
          [:partial, :template, :layout]
        end

      if (keys & render_type_keys).size < 1
        # Must have at least one of render keys
        return nil
      end

      unless (keys - ALL_KNOWN_KEYS).empty?
        # de-opt in case of unknown option
        return nil
      end

      render_type = (keys & render_type_keys)[0]

      node = options_hash[render_type]
      if node.string?
        template = node.to_string
      else
        if node.variable_reference?
          dependency = node.variable_name.sub(/\A(?:\$|@{1,2})/, "")
        elsif node.vcall?
          dependency = node.variable_name
        elsif node.call?
          dependency = node.call_method_name
          return unless dependency.is_a? String
        else
          return
        end
        object_template = true
        template = "#{dependency.pluralize}/#{dependency.singularize}"
      end

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

      if spacer_template = render_template_with_spacer?(options_hash)
        virtual_path = partial_to_virtual_path(:partial, spacer_template)
        # Locals keys should not include collection keys
        renders << RenderCall.new(virtual_path, locals_keys.dup)
      end

      if options_hash.key?(:object) || options_hash.key?(:collection) || object_template
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

      virtual_path = partial_to_virtual_path(render_type, template)
      renders << RenderCall.new(virtual_path, locals_keys)

      # Support for rendering multiple templates (i.e. a partial with a layout)
      if layout_template = render_template_with_layout?(render_type, options_hash)
        virtual_path = if from_controller?
          layout_to_virtual_path(layout_template)
        else
          if !layout_template.include?("/") &&
            partial_prefix = template.match(%r{(.*)/([^/]*)\z})
            # TODO: use the file path that this render call was found in to
            # generate the partial prefix instead of rendered partial.
            partial_prefix = partial_prefix[1]
            layout_template = "#{partial_prefix}/#{layout_template}"
          end
          partial_to_virtual_path(:layout, layout_template)
        end

        renders << RenderCall.new(virtual_path, locals_keys)
      end

      renders
    end

    def parse_str(node)
      node.string? && node.to_string
    end

    def parse_sym(node)
      node.symbol? && node.to_symbol
    end

    private

    def debug(message)
      warn message
    end

    def from_controller?
      @from_controller
    end

    def render_template_with_layout?(render_type, options_hash)
      if render_type != :layout && options_hash.key?(:layout)
        parse_str(options_hash[:layout])
      end
    end

    def render_template_with_spacer?(options_hash)
      if !from_controller? && options_hash.key?(:spacer_template)
        parse_str(options_hash[:spacer_template])
      end
    end

    def partial_to_virtual_path(render_type, partial_path)
      if render_type == :partial || render_type == :layout
        partial_path.gsub(%r{(/|^)([^/]*)\z}, '\1_\2')
      else
        partial_path
      end
    end

    def layout_to_virtual_path(layout_path)
      "layouts/#{layout_path}"
    end
  end
end

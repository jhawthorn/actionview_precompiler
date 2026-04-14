require "actionview_precompiler/cache"

module ActionviewPrecompiler
  class TemplateLoader
    VIRTUAL_PATH_REGEX = %r{\A(?:(?<prefix>.*)\/)?(?<partial>_)?(?<action>[^\/\.]+)}

    attr_reader :compiled_templates

    def initialize(verbose: false)
      target = ActionController::Base
      @lookup_context = ActionView::LookupContext.new(target.view_paths)
      @view_context_class = target.view_context_class
      @compiled_templates = {}
      @verbose = verbose
    end

    def load_template(virtual_path, locals, compiled_cache: nil, eval_enabled: true)
      templates = find_all_templates(virtual_path, locals)
      templates.each do |template|
        next if compiled_cache && use_cached_source(template, compiled_cache)

        build(template, eval_enabled: eval_enabled)
      end
    end

    private

    def find_all_templates(virtual_path, locals)
      match = virtual_path.match(VIRTUAL_PATH_REGEX)
      if match
        action = match[:action]
        prefix = match[:prefix] ? [match[:prefix]] : []
        partial = !!match[:partial]

        # Assume templates with different details take same locals
        details = {}

        @lookup_context.find_all(action, prefix, partial, locals, details)
      else
        []
      end
    end

    def build(template, eval_enabled: true)
      return if template.instance_variable_get(:@compiled)

      identifier = template.identifier

      # Capture handler output by calling the handler directly
      handler_output = begin
        template.handler.call(template, template.source)
      rescue => e
        debug "  handler capture error for #{identifier}: #{e.class}: #{e.message}"
        nil
      end

      if File.exist?(identifier) && handler_output
        @compiled_templates[identifier] = {
          "handler_output" => handler_output
        }
      end

      return unless eval_enabled

      source = template.send(:compiled_source)

      mod = @view_context_class.compiled_method_container

      ActiveSupport::Notifications.instrument(
        "!compile_template.action_view",
        virtual_path: template.virtual_path,
        identifier: identifier
      ) do
        mod.module_eval(source, identifier, 0)
      end
      template.instance_variable_set(:@compiled, true)
    end

    def debug(msg)
      puts msg if @verbose
    end

    def use_cached_source(template, compiled_cache)
      identifier = template.identifier
      cached = compiled_cache[identifier]
      unless cached
        debug "  cache miss (no entry): #{identifier}"
        return false
      end
      unless cached["handler_output"]
        debug "  cache miss (nil handler_output): #{identifier}"
        return false
      end

      # Swap handler to return cached output, letting Rails
      # generate compiled_source with the correct method_name
      original_handler = template.handler
      template.instance_variable_set(:@handler, ->(_t, _s) { cached["handler_output"] })

      begin
        source = template.send(:compiled_source)
        mod = @view_context_class.compiled_method_container
        mod.module_eval(source, identifier, 0)
      rescue SyntaxError
        template.instance_variable_set(:@handler, original_handler)
        return false
      end

      template.instance_variable_set(:@handler, original_handler)
      template.instance_variable_set(:@compiled, true)

      true
    end
  end
end

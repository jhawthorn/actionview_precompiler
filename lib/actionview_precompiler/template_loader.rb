module ActionviewPrecompiler
  class TemplateLoader
    VIRTUAL_PATH_REGEX = %r{\A(?:(?<prefix>.*)\/)?(?<partial>_)?(?<action>[^\/]+)}

    def initialize
      target = ActionController::Base
      @lookup_context = ActionView::LookupContext.new(target.view_paths)
      @view_context_class = target.view_context_class
    end

    def load_template(virtual_path, locals)
      # Assume templates with different details take same locals
      details = {}

      m = virtual_path.match(VIRTUAL_PATH_REGEX)
      action = m[:action]
      prefix = m[:prefix] ? [m[:prefix]] : []
      partial = !!m[:partial]

      templates = @lookup_context.find_all(action, prefix, partial, locals, details)
      templates.each do |template|
        template.send(:compile!, @view_context_class)
      end
    end
  end
end

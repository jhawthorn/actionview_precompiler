module ActionviewPrecompiler
  class TemplateLoader
    def initialize
      target = ActionController::Base
      @lookup_context = ActionView::LookupContext.new(target.view_paths)
      @view_context_class = target.view_context_class
    end

    def load_template(template, locals)
      details = {
        locale: Array(template.details[:locale]),
        variants: Array(template.details[:variant]),
        formats: Array(template.details[:format]),
        handlers: Array(template.details[:handler])
      }

      args = [template.action, template.prefix, template.partial?, locals, details]

      templates = @lookup_context.find_all(*args)
      templates.each do |template|
        template.send(:compile!, @view_context_class)
      end
    end
  end
end

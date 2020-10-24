require "actionview_precompiler/scanner"

module ActionviewPrecompiler
  class Precompiler
    def initialize(view_dirs)
      @scanner = Scanner.new(view_dirs)
    end

    def each_lookup_args
      return enum_for(__method__) unless block_given?

      each_template_render do |template, locals|
        details = {
          locale: Array(template.details[:locale]),
          variants: Array(template.details[:variant]),
          formats: Array(template.details[:format]),
          handlers: Array(template.details[:handler])
        }

        yield [template.action, template.prefix, template.partial?, locals, details]
      end

      nil
    end

    def each_template_render
      return enum_for(__method__) unless block_given?

      @scanner.templates.each do |template|
        locals_set = @scanner.locals_sets[template.virtual_path]
        if locals_set
          locals_set.each do |locals|
            yield template, locals
          end
        elsif !template.partial?
          # For now, guess that non-partials we haven't seen take no locals
          yield template, []
        else
          # Locals unknown
        end
      end
    end
  end
end

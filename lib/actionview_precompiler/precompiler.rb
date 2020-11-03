require "actionview_precompiler/scanner"
require "actionview_precompiler/template_loader"

module ActionviewPrecompiler
  class Precompiler
    def initialize(view_dirs, verbose: false)
      @scanner = Scanner.new(view_dirs)
      @loader = TemplateLoader.new
      @verbose = verbose
    end

    def run
      count = 0
      each_template_render do |template, locals|
        debug "precompiling: #{template.inspect}"
        count += 1

        @loader.load_template(template, locals)
      end

      debug "Precompiled #{count} Templates"
    end

    def debug(msg)
      puts msg if @verbose
    end

    def each_template_render
      return enum_for(__method__) unless block_given?

      @scanner.templates.each do |template|
        locals_set = @scanner.locals_sets[template.virtual_path]
        if locals_set
          locals_set.each do |locals|
            yield template, locals
          end
        else
          # Locals unknown
        end
      end
    end
  end
end

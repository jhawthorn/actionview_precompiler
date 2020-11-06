require "actionview_precompiler/template_scanner"
require "actionview_precompiler/template_loader"

module ActionviewPrecompiler
  class Precompiler
    attr_accessor :no_locals_paths

    def initialize(view_dirs, verbose: false)
      @scanner = TemplateScanner.new(view_dirs)
      @loader = TemplateLoader.new
      @verbose = verbose
      @no_locals_paths = []
      @template_renders = nil
    end

    def run
      count = 0
      template_renders.each do |template, locals|
        debug "precompiling: #{template.inspect}"
        count += 1

        @loader.load_template(template, locals)
      end

      debug "Precompiled #{count} Templates"
    end

    def debug(msg)
      puts msg if @verbose
    end

    def template_renders
      return @template_renders if @template_renders

      template_renders = Set.new

      @scanner.locals_sets.each do |virtual_path, locals_set|
        locals_set.each do |locals|
          template_renders << [virtual_path, locals]
        end
      end

      no_locals_paths.each do |template|
        template_renders << [template, []]
      end

      @template_renders = template_renders.to_a
    end
  end
end

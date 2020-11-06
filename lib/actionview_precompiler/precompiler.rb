require "actionview_precompiler/template_scanner"
require "actionview_precompiler/controller_scanner"
require "actionview_precompiler/template_loader"

module ActionviewPrecompiler
  class Precompiler
    attr_accessor :no_locals_paths

    def initialize(verbose: false)
      @scanners = []
      @loader = TemplateLoader.new
      @verbose = verbose
      @no_locals_paths = []
      @template_renders = nil
    end

    def scan_view_dir(view_dir)
      @scanners << TemplateScanner.new(view_dir)
    end

    def scan_controller_dir(controller_dir)
      @scanners << ControllerScanner.new(controller_dir)
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

    def template_renders
      return @template_renders if @template_renders

      template_renders = []

      @scanners.each do |scanner|
        template_renders.concat scanner.template_renders
      end

      no_locals_paths.each do |template|
        template_renders << [template, []]
      end

      template_renders.uniq!

      @template_renders = template_renders
    end

    private

    def debug(msg)
      puts msg if @verbose
    end
  end
end

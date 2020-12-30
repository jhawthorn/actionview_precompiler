require "actionview_precompiler/template_scanner"
require "actionview_precompiler/controller_scanner"
require "actionview_precompiler/helper_scanner"
require "actionview_precompiler/template_loader"

module ActionviewPrecompiler
  class Precompiler
    def initialize(verbose: false)
      @scanners = []
      @loader = TemplateLoader.new
      @verbose = verbose
      @static_templates = []
      @template_renders = nil
    end

    def scan_view_dir(view_dir)
      @scanners << TemplateScanner.new(view_dir)
    end

    def scan_controller_dir(controller_dir)
      @scanners << ControllerScanner.new(controller_dir)
    end

    def scan_helper_dir(controller_dir)
      @scanners << HelperScanner.new(controller_dir)
    end

    def add_template(virtual_path, locals = [])
      locals = locals.map(&:to_s).sort
      @static_templates << [virtual_path, locals]
    end

    def run
      count = 0
      template_renders.each do |virtual_path, locals|
        debug "precompiling: #{virtual_path}"

        templates = @loader.load_template(virtual_path, locals)
        count += templates.count

        debug "  No templates found at #{virtual_path}" if templates.empty?
      end

      debug "Precompiled #{count} Templates"
    end

    def template_renders
      return @template_renders if @template_renders

      template_renders = []

      @scanners.each do |scanner|
        template_renders.concat scanner.template_renders
      end

      template_renders.concat @static_templates

      template_renders.uniq!

      @template_renders = template_renders
    end

    private

    def debug(msg)
      puts msg if @verbose
    end
  end
end

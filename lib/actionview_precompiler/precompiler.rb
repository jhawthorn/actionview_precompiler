require "actionview_precompiler/template_scanner"
require "actionview_precompiler/controller_scanner"
require "actionview_precompiler/helper_scanner"
require "actionview_precompiler/template_loader"
require "actionview_precompiler/cache"

module ActionviewPrecompiler
  class Precompiler
    def initialize(verbose: false, cache_path: nil)
      @scanners = []
      @loader = TemplateLoader.new(verbose: verbose)
      @verbose = verbose
      @static_templates = []
      @template_renders = nil
      @cache_path = cache_path
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
      if @cache_path
        cache = Cache.new(@cache_path, verbose: @verbose)
        if cache_data = cache.read
          debug "Cache hit: #{@cache_path}"
          run_from_cache(cache_data)
        else
          debug "Cache miss: #{@cache_path}"
          run_fresh(eval_enabled: false)
          write_cache(cache)
        end
      else
        debug "No cache path configured"
        run_fresh
      end
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

    def run_fresh(eval_enabled: true)
      count = 0
      template_renders.each do |virtual_path, locals|
        debug "precompiling: #{virtual_path}"

        templates = @loader.load_template(virtual_path, locals, eval_enabled: eval_enabled)
        count += templates.count

        debug "  No templates found at #{virtual_path}" if templates.empty?
      end

      debug "Precompiled #{count} Templates"
    end

    def run_from_cache(cache_data)
      cached_renders = cache_data["template_renders"]
      compiled_templates = cache_data["compiled_templates"] || {}

      count = 0
      cached_renders.each do |virtual_path, locals|
        debug "precompiling (cached): #{virtual_path}"

        templates = @loader.load_template(virtual_path, locals, compiled_cache: compiled_templates)
        count += templates.count

        debug "  No templates found at #{virtual_path}" if templates.empty?
      end

      debug "Precompiled #{count} Templates (from cache)"
    end

    def write_cache(cache)
      cache.write(
        template_renders: template_renders,
        compiled_templates: @loader.compiled_templates
      )

      debug "Wrote precompiler cache to #{cache.cache_path}"
    end

    def debug(msg)
      puts msg if @verbose
    end
  end
end

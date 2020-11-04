require "actionview_precompiler/template_file"

module ActionviewPrecompiler
  class TemplateScanner
    def initialize(view_dirs)
      @view_dirs = view_dirs
      @locals_sets = nil
    end

    def templates
      @templates ||=
        @view_dirs.flat_map do |view_dir|
          Dir["**/*", base: view_dir].sort.map do |file|
            fullpath = File.expand_path(file, view_dir)
            next if File.directory?(fullpath)

            TemplateFile.new(fullpath, file)
          end.compact
        end
    end

    def locals_sets
      return @locals_sets if @locals_sets

      @locals_sets = {}

      templates.each do |template|
        parser = TemplateParser.new(template.fullpath)
        parser.render_calls.each do |render_call|
          virtual_path = render_call.virtual_path
          unless virtual_path.include?("/")
            # Not necessarily true, since the perfix is based on the current
            # controller, but is a safe bet most of the time.
            virtual_path = "#{template.prefix}/#{virtual_path}"
          end
          @locals_sets[virtual_path] ||= []
          @locals_sets[virtual_path] << render_call.locals_keys.map(&:to_s).sort
        end
      end

      @locals_sets.each_value(&:uniq!)

      @locals_sets
    end
  end
end

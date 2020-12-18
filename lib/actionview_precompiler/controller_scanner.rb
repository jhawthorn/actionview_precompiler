module ActionviewPrecompiler
  class ControllerScanner
    attr_reader :controller_dir

    def initialize(controller_dir)
      @controller_dir = controller_dir
    end

    def template_renders
      template_renders = []

      each_controller do |path, fullpath|
        parser = ControllerParser.new(fullpath)

        if path =~ /\A(.*)_controller\.rb\z/
          controller_prefix = $1
        end

        parser.render_calls.each do |render_call|
          virtual_path = render_call.virtual_path

          unless virtual_path.include?("/")
            next unless controller_prefix

            virtual_path = "#{controller_prefix}/#{virtual_path}"
          end

          locals = render_call.locals_keys.map(&:to_s).sort

          template_renders << [virtual_path, locals]
        end
      end

      template_renders.uniq
    end

    private

    def each_controller
      Dir["**/*.rb", base: controller_dir].sort.map do |file|
        fullpath = File.expand_path(file, controller_dir)
        next if File.directory?(fullpath)

        yield file, fullpath
      end
    end
  end
end

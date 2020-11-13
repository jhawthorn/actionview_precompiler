module ActionviewPrecompiler
  class HelperScanner
    def initialize(dir)
      @dir = dir
    end

    def template_renders
      template_renders = []

      each_helper do |fullpath|
        parser = HelperParser.new(fullpath)
        parser.render_calls.each do |render_call|
          virtual_path = render_call.virtual_path

          locals = render_call.locals_keys.map(&:to_s).sort

          template_renders << [virtual_path, locals]
        end
      end

      template_renders.uniq
    end

    private

    def each_helper
      Dir["#{@dir}/**/*_helper.rb"].sort.map do |fullpath|
        next if File.directory?(fullpath)

        yield fullpath
      end
    end
  end
end

require "actionview_precompiler/version"
require "actionview_precompiler/template_parser"
require "actionview_precompiler/render_parser"
require "actionview_precompiler/precompiler"
require "actionview_precompiler/parsed_filename"

module ActionviewPrecompiler
  class Error < StandardError; end

  def self.precompile
    target = ActionController::Base # fixme
    view_paths = target.view_paths
    paths = view_paths.map(&:path)
    precompiler = Precompiler.new(paths)
    precompiler.each_lookup_args do |args|
      puts "preloading: #{args.inspect}"
      templates = view_paths.find_all(*args)
    end
  end
end

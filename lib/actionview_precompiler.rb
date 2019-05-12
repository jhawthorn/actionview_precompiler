require "actionview_precompiler/version"
require "actionview_precompiler/ast_parser"
require "actionview_precompiler/template_parser"
require "actionview_precompiler/render_parser"
require "actionview_precompiler/precompiler"
require "actionview_precompiler/parsed_filename"

module ActionviewPrecompiler
  class Error < StandardError; end

  def self.precompile(verbose: false)
    target = ActionController::Base # fixme
    view_paths = target.view_paths
    lookup_context = ActionView::LookupContext.new(view_paths)
    paths = view_paths.map(&:path)
    precompiler = Precompiler.new(paths)

    mod = target.view_context_class
    count = 0
    precompiler.each_lookup_args do |args|
      templates = lookup_context.find_all(*args)
      templates.each do |template|
        puts "precompiling: #{template.inspect}" if verbose
        count += 1
        template.send(:compile!, mod)
      end
    end

    if verbose
      puts "Precompiled #{count} Templates"
    end
  end
end

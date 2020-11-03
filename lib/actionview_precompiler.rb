require "action_controller"
require "action_view"

require "actionview_precompiler/version"
require "actionview_precompiler/ast_parser"
require "actionview_precompiler/template_parser"
require "actionview_precompiler/render_parser"
require "actionview_precompiler/precompiler"
require "actionview_precompiler/parsed_filename"

module ActionviewPrecompiler
  class Error < StandardError; end

  # Allow overriding from ActionView default handlers if necessary
  HANDLERS_FOR_EXTENSION = Hash.new do |h, ext|
    h[ext] = ActionView::Template.handler_for_extension(ext)
  end

  def self.precompile(verbose: false)
    paths = ActionController::Base.view_paths.map(&:path)
    precompiler = Precompiler.new(paths, verbose: verbose)
    precompiler.run
  end
end

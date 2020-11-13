require "action_controller"
require "action_view"

require "actionview_precompiler/version"
require "actionview_precompiler/ast_parser"
require "actionview_precompiler/template_parser"
require "actionview_precompiler/render_parser"
require "actionview_precompiler/controller_parser"
require "actionview_precompiler/helper_parser"
require "actionview_precompiler/precompiler"
require "actionview_precompiler/parsed_filename"

module ActionviewPrecompiler
  class Error < StandardError; end

  # Allow overriding from ActionView default handlers if necessary
  HANDLERS_FOR_EXTENSION = Hash.new do |h, ext|
    h[ext] = ActionView::Template.handler_for_extension(ext)
  end

  def self.precompile(verbose: false)
    precompiler = Precompiler.new(verbose: verbose)

    if block_given?
      # Custom configuration
      yield precompiler
    else
      # Scan view dirs
      ActionController::Base.view_paths.each do |view_path|
        precompiler.scan_view_dir view_path.path
      end

      # If we have an application, scan controllers
      if Rails.respond_to?(:application)
        Rails.application.paths["app/controllers"].each do |path|
          precompiler.scan_controller_dir path.to_s
        end

        Rails.application.paths["app/helpers"].each do |path|
          precompiler.scan_helper_dir path.to_s
        end
      end
    end

    precompiler.run
  end
end

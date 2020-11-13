$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "actionview_precompiler"

FIXTURES_DIR = File.expand_path("./fixtures/", __dir__)
FIXTURES_VIEW_DIR = File.join(FIXTURES_DIR, "views")
FIXTURES_CONTROLLER_DIR = File.join(FIXTURES_DIR, "controllers")
FIXTURES_HELPER_DIR = File.join(FIXTURES_DIR, "helpers")

require "minitest/autorun"
require "pry"

ActionController::Base.view_paths = FIXTURES_VIEW_DIR

class Minitest::Test
  def reset_action_view!
    ActionView::LookupContext::DetailsKey.clear
  end
end

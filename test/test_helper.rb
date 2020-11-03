$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "actionview_precompiler"

FIXTURES_DIR = File.expand_path("./fixtures/", __dir__)

require "minitest/autorun"
require "pry"

ActionController::Base.view_paths = FIXTURES_DIR

class Minitest::Test
  def reset_action_view!
    ActionView::LookupContext::DetailsKey.clear
  end
end

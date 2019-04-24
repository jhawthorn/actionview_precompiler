require "test_helper"

module ActionviewPrecompiler
  class RenderParserTest < Minitest::Test
    def test_finds_no_renders
      assert_equal [], RenderParser.new("1 + 1").render_calls
    end
  end
end

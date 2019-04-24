require "test_helper"

module ActionviewPrecompiler
  class RenderParserTest < Minitest::Test
    def test_finds_no_renders
      assert_equal [], parse_render_calls("1 + 1")
    end

    def test_finds_no_renders_from_invalid_calls
      assert_equal [], parse_render_calls(%q{render()})
      assert_equal [], parse_render_calls(%q{render(123)})
      assert_equal [], parse_render_calls(%q{render("foo", 123)})
      assert_equal [], parse_render_calls(%q{render("foo", {}, {})})
    end

    def test_finds_simple_render
      renders = parse_render_calls(%q{render "users/user"})
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal "users/user", render.template
    end

    def test_finds_simple_render_hash
      renders = parse_render_calls(%q{render partial: "users/user"})
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal "users/user", render.template
    end

    private

    def parse_render_calls(code)
      RenderParser.new(code).render_calls
    end
  end
end

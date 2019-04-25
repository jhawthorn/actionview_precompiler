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
      assert_equal "users/_user", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_simple_render_hash
      renders = parse_render_calls(%q{render partial: "users/user"})
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal "users/user", render.template
      assert_equal "users/_user", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_render_template
      renders = parse_render_calls(%q{render template: "users/show"})
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal :template, render.render_type
      assert_equal "users/show", render.template
      assert_equal "users/show", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_render_layout
      renders = parse_render_calls(%q{render layout: "users/user_layout"})
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal :layout, render.render_type
      assert_equal "users/user_layout", render.template
      assert_equal "users/user_layout", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_simple_render_with_locals
      renders = parse_render_calls(%q{render "users/user", user: @user})
      assert_equal 1, renders.length
      assert_equal "users/user", renders[0].template
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_finds_simple_render_hash_with_locals
      renders = parse_render_calls(%q{render partial: "users/user", locals: { user: @user } })
      assert_equal 1, renders.length
      assert_equal "users/user", renders[0].template
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    private

    def parse_render_calls(code)
      RenderParser.new(code).render_calls
    end
  end
end
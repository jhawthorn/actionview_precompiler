require "test_helper"

module ActionviewPrecompiler
  class RenderParserTest < Minitest::Test
    def test_finds_no_renders
      assert_equal [], parse_render_calls("x = x = 1 + 1")
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
      assert_equal "users/_user_layout", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_render_layout_with_block
      renders = parse_render_calls(<<~RUBY)
        render layout: "users/user_layout" do
        end
      RUBY
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal :layout, render.render_type
      assert_equal "users/user_layout", render.template
      assert_equal "users/_user_layout", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_render_layout_with_ampersand_proc
      renders = parse_render_calls(%q{render layout: "users/user_layout", &my_proc})
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal :layout, render.render_type
      assert_equal "users/user_layout", render.template
      assert_equal "users/_user_layout", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_simple_render_with_locals
      renders = parse_render_calls(%q{render "users/user", user: @user})
      assert_equal 1, renders.length
      assert_equal "users/user", renders[0].template
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_finds_simple_render_hash_with_empty_locals
      renders = parse_render_calls(%q{render partial: "users/user", locals: { } })
      assert_equal 1, renders.length
      assert_equal "users/user", renders[0].template
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [], renders[0].locals_keys
    end

    def test_finds_simple_render_hash_with_locals
      renders = parse_render_calls(%q{render partial: "users/user", locals: { user: @user } })
      assert_equal 1, renders.length
      assert_equal "users/user", renders[0].template
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_render_object
      renders = parse_render_calls(%q{render partial: "users/user", object: @user })
      assert_equal 1, renders.length
      assert_equal "users/user", renders[0].template
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_render_object_as
      renders = parse_render_calls(%q{render partial: "users/user", object: @user, as: :customer })
      assert_equal 1, renders.length
      assert_equal "users/user", renders[0].template
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:customer], renders[0].locals_keys
    end

    def test_render_object_and_locals
      renders = parse_render_calls(%q{render partial: "users/user", object: @user, locals: { admin: true } })
      assert_equal 1, renders.length
      assert_equal "users/user", renders[0].template
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:admin, :user], renders[0].locals_keys
    end

    def test_render_collection
      renders = parse_render_calls(%q{render partial: "users/user", collection: @users })
      assert_equal 1, renders.length
      assert_equal "users/user", renders[0].template
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user, :user_counter, :user_iteration], renders[0].locals_keys
    end

    def test_render_collection_as
      renders = parse_render_calls(%q{render partial: "users/user", collection: @users, as: :customer })
      assert_equal 1, renders.length
      assert_equal "users/user", renders[0].template
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:customer, :customer_counter, :customer_iteration], renders[0].locals_keys
    end

    def test_render_collection_and_locals
      renders = parse_render_calls(%q{render partial: "users/user", collection: @users, locals: { admin: true } })
      assert_equal 1, renders.length
      assert_equal "users/user", renders[0].template
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:admin, :user, :user_counter, :user_iteration], renders[0].locals_keys
    end

    private

    def parse_render_calls(code)
      RenderParser.new(code).render_calls
    end
  end
end

require "test_helper"

module ActionviewPrecompiler
  module RenderParserTests
    def test_finds_no_renders
      assert_equal [], parse_render_calls("x = x = 1 + 1")
    end

    def test_finds_no_renders_from_invalid_calls
      assert_equal [], parse_render_calls(%q{render()})
      assert_equal [], parse_render_calls(%q{render(123)})
      assert_equal [], parse_render_calls(%q{render("foo", 123)})
      assert_equal [], parse_render_calls(%q{render("foo", {}, {})})
      assert_equal [], parse_render_calls(%q{render("foo", locals)})
      assert_equal [], parse_render_calls(%q{render("foo", **locals)})
      assert_equal [], parse_render_calls(%q{render("foo", { **locals })})
      assert_equal [], parse_render_calls(%q{render("foo", name: "John", **locals)})
      assert_equal [], parse_render_calls(%q{render(partial: "foo", **options)})
    end

    def test_finds_simple_render
      renders = parse_render_calls(%q{render "users/user"})
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal "users/_user", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_simple_render_hash
      renders = parse_render_calls(%q{render partial: "users/user"})
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal "users/_user", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_simple_render_hash_explicit
      renders = parse_render_calls(%q{render({partial: "users/user"})})
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal "users/_user", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_render_template
      renders = parse_render_calls(%q{render template: "users/show"})
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal "users/show", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_render_layout
      renders = parse_render_calls(%q{render layout: "users/user_layout"})
      assert_equal 1, renders.length
      render = renders[0]
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
      assert_equal "users/_user_layout", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_finds_render_layout_with_ampersand_proc
      renders = parse_render_calls(%q{render layout: "users/user_layout", &my_proc})
      assert_equal 1, renders.length
      render = renders[0]
      assert_equal "users/_user_layout", render.virtual_path
      assert_equal [], render.locals_keys
    end

    def test_render_partial_with_layout
      renders = parse_render_calls(%q{render partial: "users/user", layout: "foobar", locals: { buzz: true }})
      assert_equal 2, renders.length
      assert_equal ["users/_user", "users/_foobar"], renders.map(&:virtual_path)
      assert_equal [[:buzz], [:buzz]], renders.map(&:locals_keys)
    end

    def test_render_partial_with_layout_in_different_directory
      renders = parse_render_calls(%q{render partial: "users/user", layout: "foo/bar", locals: { buzz: true }})
      assert_equal 2, renders.length
      assert_equal ["users/_user", "foo/_bar"], renders.map(&:virtual_path)
      assert_equal [[:buzz], [:buzz]], renders.map(&:locals_keys)
    end

    def test_ignores_layout_outside_of_render_calls
      renders = parse_render_calls(%q{layout "foobar" }, from_controller: false)
      assert_equal 0, renders.length
    end

    def test_ignores_layout_when_symbol
      renders = parse_render_calls(%q{render partial: "users/user", layout: :foobar, locals: { buzz: true }})
      assert_equal 1, renders.length
      assert_equal ["users/_user"], renders.map(&:virtual_path)
      assert_equal [[:buzz]], renders.map(&:locals_keys)
    end

    def test_finds_simple_render_with_locals
      renders = parse_render_calls(%q{render "users/user", user: @user})
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_finds_render_with_instance_variables
      renders = parse_render_calls(%q{render @user})
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_finds_render_with_global_variables
      renders = parse_render_calls(%q{render $user})
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_finds_render_with_class_variables
      renders = parse_render_calls(%q{render @@user})
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_finds_render_with_local_variables
      renders = parse_render_calls(%q{render user})
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_finds_render_with_method_call
      renders = parse_render_calls(%q{render user.posts})
      assert_equal 1, renders.length
      assert_equal "posts/_post", renders[0].virtual_path
      assert_equal [:post], renders[0].locals_keys
    end

    def test_finds_simple_render_hash_with_empty_locals
      renders = parse_render_calls(%q{render partial: "users/user", locals: { } })
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [], renders[0].locals_keys
    end

    def test_finds_simple_render_hash_with_locals
      renders = parse_render_calls(%q{render partial: "users/user", locals: { user: @user } })
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_render_object
      renders = parse_render_calls(%q{render partial: "users/user", object: @user })
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_render_object_as
      renders = parse_render_calls(%q{render partial: "users/user", object: @user, as: :customer })
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:customer], renders[0].locals_keys
    end

    def test_render_object_and_locals
      renders = parse_render_calls(%q{render partial: "users/user", object: @user, locals: { admin: true } })
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:admin, :user], renders[0].locals_keys
    end

    def test_render_collection
      renders = parse_render_calls(%q{render partial: "users/user", collection: @users })
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user, :user_counter, :user_iteration], renders[0].locals_keys
    end

    def test_render_collection_as
      renders = parse_render_calls(%q{render partial: "users/user", collection: @users, as: :customer })
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:customer, :customer_counter, :customer_iteration], renders[0].locals_keys
    end

    def test_render_collection_and_locals
      renders = parse_render_calls(%q{render partial: "users/user", collection: @users, locals: { admin: true } })
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:admin, :user, :user_counter, :user_iteration], renders[0].locals_keys
    end

    def test_render_from_controller
      renders = parse_render_calls(%q{render "users/show"}, from_controller: true)
      assert_equal 1, renders.length
      assert_equal "users/show", renders[0].virtual_path
      assert_equal [], renders[0].locals_keys
    end

    def test_render_partial_from_controller
      renders = parse_render_calls(%q{render partial: "users/user"}, from_controller: true)
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [], renders[0].locals_keys
    end

    def test_render_with_locals_from_controller
      renders = parse_render_calls(%q{render "users/show", locals: { user: user }}, from_controller: true)
      assert_equal 1, renders.length
      assert_equal "users/show", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_render_partial_with_locals_from_controller
      renders = parse_render_calls(%q{render partial: "users/user", locals: { user: user }}, from_controller: true)
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_render_to_string
      renders = parse_render_calls(%q{render_to_string(partial: "users/user", locals: { user: user })}, from_controller: true)
      assert_equal 1, renders.length
      assert_equal "users/_user", renders[0].virtual_path
      assert_equal [:user], renders[0].locals_keys
    end

    def test_layout_from_controller
      renders = parse_render_calls(%q{layout "foobar" }, from_controller: true)
      assert_equal 1, renders.length
      assert_equal "layouts/foobar", renders[0].virtual_path
      assert_equal [], renders[0].locals_keys
    end

    def test_layout_ignores_symbols_from_controller
      renders = parse_render_calls(%q{layout :foobar }, from_controller: true)
      assert_equal 0, renders.length
    end

    def test_render_with_layout_from_controller
      renders = parse_render_calls(%q{render "site/index", layout: "site", locals: { foo: "bar" }}, from_controller: true)
      assert_equal 2, renders.length
      assert_equal ["site/index", "layouts/site"], renders.map(&:virtual_path)
      assert_equal [[:foo], [:foo]], renders.map(&:locals_keys)
    end

    def test_render_with_layout_bool_from_controller
      renders = parse_render_calls(%q{render "site/index", layout: false, locals: { foo: "bar" }}, from_controller: true)
      assert_equal 1, renders.length
      assert_equal "site/index", renders[0].virtual_path
      assert_equal [:foo], renders[0].locals_keys
    end

    def test_render_with_dynamic_layout_from_controller
      renders = parse_render_calls(%q{render "site/index", layout: my_special_layout, locals: { foo: "bar" }}, from_controller: true)
      assert_equal 1, renders.length
      assert_equal "site/index", renders[0].virtual_path
      assert_equal [:foo], renders[0].locals_keys
    end

    def test_render_with_status_from_controller
      renders = parse_render_calls(%q{render "site/404", status: :not_found}, from_controller: true)
      assert_equal 1, renders.length
      assert_equal "site/404", renders[0].virtual_path
      assert_equal [], renders[0].locals_keys
    end

    def test_render_with_spacer_template
      renders = parse_render_calls(%q{render partial: "books/book", collection: books, spacer_template: "books/book_spacer", locals: {foo: 123}})
      assert_equal 2, renders.length
      assert_equal "books/_book_spacer", renders[0].virtual_path
      assert_equal [:foo], renders[0].locals_keys
      assert_equal "books/_book", renders[1].virtual_path
      assert_equal [:foo, :book, :book_counter, :book_iteration], renders[1].locals_keys
    end

    private

    def parse_render_calls(code, **options)
      RenderParser.new(code, parser: self.class::Parser, **options).render_calls
    end
  end

  class RipperASTRenderParserTest < Minitest::Test
    include RenderParserTests

    require "actionview_precompiler/ast_parser/ripper"
    Parser = RipperASTParser
  end

  if RUBY_ENGINE == "ruby"
    class RubyASTRenderParserTest < Minitest::Test
      include RenderParserTests

      require "actionview_precompiler/ast_parser/ruby26"
      Parser = Ruby26ASTParser
    end
  end

  if RUBY_ENGINE == "jruby"
    class JRubyASTRenderParserTest < Minitest::Test
      include RenderParserTests

      require "actionview_precompiler/ast_parser/jruby"
      Parser = JRubyASTParser
    end
  end
end

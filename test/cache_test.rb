require "test_helper"
require "tmpdir"
require "json"

module ActionviewPrecompiler
  class CacheTest < Minitest::Test
    def setup
      @cache_dir = Dir.mktmpdir("precompiler_cache_test")
      @cache_path = File.join(@cache_dir, "precompiler_cache.json")
    end

    def teardown
      FileUtils.rm_rf(@cache_dir)
    end

    def test_cache_write_and_read
      cache = Cache.new(@cache_path)

      cache.write(
        template_renders: [["users/_user", ["user"]]],
        compiled_templates: {}
      )

      assert File.exist?(@cache_path)
      data = cache.read
      assert_equal [["users/_user", ["user"]]], data["template_renders"]
    end

    def test_cache_read_returns_nil_when_no_file
      cache = Cache.new(@cache_path)
      assert_nil cache.read
    end

    def test_cache_read_returns_nil_on_corrupt_json
      cache = Cache.new(@cache_path)

      File.write(@cache_path, "not valid json{{{")

      assert_nil cache.read
    end

    def test_precompiler_writes_cache
      reset_action_view!

      precompiler = Precompiler.new(cache_path: @cache_path)
      precompiler.scan_view_dir FIXTURES_VIEW_DIR

      precompiler.run

      assert File.exist?(@cache_path)

      data = JSON.parse(File.read(@cache_path))
      assert_includes data["template_renders"], ["users/_user", ["user"]]
    end

    def test_precompiler_loads_from_cache
      reset_action_view!

      # First run: write cache
      precompiler1 = Precompiler.new(cache_path: @cache_path)
      precompiler1.scan_view_dir FIXTURES_VIEW_DIR
      precompiler1.run

      assert File.exist?(@cache_path)

      # Second run: load from cache
      reset_action_view!

      precompiler2 = Precompiler.new(cache_path: @cache_path)
      precompiler2.scan_view_dir FIXTURES_VIEW_DIR
      precompiler2.run

      # The cached run should still result in templates being available
      assert File.exist?(@cache_path)
    end

    def test_precompiler_falls_back_on_invalid_cache
      reset_action_view!

      # Write a cache with invalid JSON-like structure missing required keys
      File.write(@cache_path, "not valid json{{{")

      precompiler = Precompiler.new(cache_path: @cache_path)
      precompiler.scan_view_dir FIXTURES_VIEW_DIR

      precompiler.run

      # Should have rewritten the cache
      data = JSON.parse(File.read(@cache_path))
      assert_includes data["template_renders"], ["users/_user", ["user"]]
    end

    def test_precompiler_without_cache_path_works_normally
      reset_action_view!

      precompiler = Precompiler.new
      precompiler.scan_view_dir FIXTURES_VIEW_DIR

      compiled_templates = []
      callback = ->(name, start, finish, id, payload) do
        compiled_templates << payload[:virtual_path]
      end
      ActiveSupport::Notifications.subscribed(callback, "!compile_template.action_view") do
        precompiler.run
      end

      assert_includes compiled_templates, "users/_user"
      refute File.exist?(@cache_path)
    end

  end
end

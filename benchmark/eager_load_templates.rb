# frozen_string_literal: true

# Benchmarks ActionviewPrecompiler.precompile with and without the internal
# use of ActionView::FileSystemResolver#eager_load_templates, on a synthetic
# app with 1,000 templates.
#
# Run with:
#
#     bundle exec ruby benchmark/eager_load_templates.rb
#
# Optional env vars:
#   TEMPLATE_COUNT  - number of templates to generate (default: 1000)
#   PARTIAL_RATIO   - fraction of templates that are partials (default: 0.5)
#
# Example run on Ruby 4.0.6 + Rails 8.2.0.alpha (main), 1,000 templates,
# Apple Silicon:
#
#   precompile (no resolver prewarm, existing behavior):
#     scan + compile                         1.281 s   267,033 objects allocated
#   precompile (with eager_load_templates prewarm):
#     scan + compile                         0.357 s   347,363 objects allocated
#   Baseline (glob + read, no compile):
#     Dir.glob + File.read                   0.084 s     4,008 objects allocated
#
# The prewarmed path is ~3.6x faster because Rails' eager_load_templates
# populates every FileSystemResolver's unbound-template cache in a single
# directory walk, replacing one glob-per-virtual-path lookup with one glob
# for the whole tree. Allocations go up slightly because eager_load_templates
# also compiles an empty-locals variant of every template on top of the
# AST-inferred locals variants precompile already produces.

require "fileutils"
require "tmpdir"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "benchmark"
require "action_controller"
require "action_view"
require "actionview_precompiler"

TEMPLATE_COUNT = Integer(ENV.fetch("TEMPLATE_COUNT", "1000"))
PARTIAL_RATIO  = Float(ENV.fetch("PARTIAL_RATIO", "0.5"))

def generate_fixtures(root, count:, partial_ratio:)
  FileUtils.mkdir_p(root)

  partials = []
  templates = []

  count.times do |i|
    dir = File.join(root, "resource_#{i / 25}")
    FileUtils.mkdir_p(dir)

    if rand < partial_ratio
      name = "_item_#{i}.html.erb"
      File.write(File.join(dir, name), <<~ERB)
        <li id="item-<%= item.id %>">
          <%= item.name %> (<%= index %>)
        </li>
      ERB
      partials << [File.basename(dir), "item_#{i}"]
    else
      name = "show_#{i}.html.erb"
      partial_ref = partials.sample
      render_line = partial_ref ? %(<%= render "#{partial_ref[0]}/#{partial_ref[1]}", item: @item, index: 0 %>) : ""
      File.write(File.join(dir, name), <<~ERB)
        <h1><%= @item.title %></h1>
        <p><%= @item.body %></p>
        #{render_line}
      ERB
      templates << [File.basename(dir), "show_#{i}"]
    end
  end

  { partials: partials.size, templates: templates.size }
end

def reset_action_view!(view_dir)
  ActionView::LookupContext::DetailsKey.clear if defined?(ActionView::LookupContext::DetailsKey)
  ActionController::Base.view_paths = [view_dir]
end

def measure(label)
  GC.start
  before = GC.stat
  elapsed = Benchmark.realtime { yield }
  after = GC.stat
  allocated = after[:total_allocated_objects] - before[:total_allocated_objects]
  printf("  %-38s %8.3f s   %12d objects allocated\n", label, elapsed, allocated)
end

Dir.mktmpdir("actionview_precompiler_bench") do |tmp|
  view_dir = File.join(tmp, "views")
  puts "Generating #{TEMPLATE_COUNT} templates in #{view_dir} ..."
  stats = generate_fixtures(view_dir, count: TEMPLATE_COUNT, partial_ratio: PARTIAL_RATIO)
  puts "  #{stats[:templates]} action templates, #{stats[:partials]} partials"
  puts

  puts "Ruby: #{RUBY_DESCRIPTION}"
  puts "Rails (actionview): #{ActionView::VERSION::STRING}"
  eager_load_available = defined?(ActionView::FileSystemResolver) &&
    ActionView::FileSystemResolver.method_defined?(:eager_load_templates)
  puts "FileSystemResolver#eager_load_templates: #{eager_load_available ? "available" : "NOT available (prewarm will be a no-op)"}"
  puts

  # --- Existing behavior: precompile without the resolver prewarm ---
  # Stub eager_load_resolvers! to a no-op for this run so we can measure the
  # old code path even on Rails versions that ship eager_load_templates.
  original = ActionviewPrecompiler::TemplateLoader.instance_method(:eager_load_resolvers!)
  ActionviewPrecompiler::TemplateLoader.define_method(:eager_load_resolvers!) { }
  begin
    reset_action_view!(view_dir)
    puts "precompile (no resolver prewarm, existing behavior):"
    measure("scan + compile") { ActionviewPrecompiler.precompile }
    puts
  ensure
    ActionviewPrecompiler::TemplateLoader.define_method(:eager_load_resolvers!, original)
  end

  # --- New behavior: precompile with the resolver prewarm ---
  reset_action_view!(view_dir)
  puts "precompile (with eager_load_templates prewarm):"
  measure("scan + compile") { ActionviewPrecompiler.precompile }
  puts

  # --- Baseline: no precompilation ---
  reset_action_view!(view_dir)
  puts "Baseline (glob + read, no compile):"
  measure("Dir.glob + File.read") do
    Dir.glob(File.join(view_dir, "**", "*.erb")) { |f| File.read(f) }
  end
end

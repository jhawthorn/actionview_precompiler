if RUBY_ENGINE == 'jruby'
  require "actionview_precompiler/ast_parser/jruby"
else
  require "actionview_precompiler/ast_parser/ruby26"
end

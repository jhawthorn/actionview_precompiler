module ActionviewPrecompiler
  parser = ENV["PRECOMPILER_PARSER"]
  parser ||= "jruby" if RUBY_ENGINE == 'jruby'
  parser ||= "rubyvm_ast" if RUBY_ENGINE == 'ruby'

  case parser
  when "rubyvm_ast"
    require "actionview_precompiler/ast_parser/ruby26"
    ASTParser = Ruby26ASTParser
  when "jruby"
    require "actionview_precompiler/ast_parser/jruby"
    ASTParser = JRubyASTParser
  else
    require "actionview_precompiler/ast_parser/ripper"
    ASTParser = RipperASTParser
  end
end

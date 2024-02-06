module ActionviewPrecompiler
  parser = ENV["PRECOMPILER_PARSER"]

  begin
    require "prism"
    parser ||= "prism"
  rescue LoadError
    parser ||= "jruby" if RUBY_ENGINE == 'jruby'
    parser ||= "rubyvm_ast" if RUBY_ENGINE == 'ruby'
  end

  case parser
  when "rubyvm_ast"
    require "actionview_precompiler/ast_parser/ruby26"
    ASTParser = Ruby26ASTParser
  when "jruby"
    require "actionview_precompiler/ast_parser/jruby"
    ASTParser = JRubyASTParser
  when "prism"
    require "actionview_precompiler/ast_parser/prism"
    ASTParser = PrismASTParser
  else
    require "actionview_precompiler/ast_parser/ripper"
    ASTParser = RipperASTParser
  end
end

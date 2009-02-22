class Packr
  class Parser < RegexpGroup
    
    def put(expression, replacement)
      expression = DICTIONARY.exec(expression) if expression.is_a?(String)
      super(expression, replacement)
    end
    
    # STRING1 requires backslashes to fix concat bug
    DICTIONARY = RegexpGroup.new.
      put(:OPERATOR,    /return|typeof|[\[(\^=,{}:;&|!*?]/.source).
      put(:CONDITIONAL, /\/\*@\w*|\w*@\*\/|\/\/@\w*|@\w+/.source).
      put(:COMMENT1,    /\/\/[^\n]*/.source).
      put(:COMMENT2,    /\/\*[^*]*\*+([^\/][^*]*\*+)*\//.source).
      put(:REGEXP,      /\/(\\[\/\\]|[^*\/])(\\.|[^\/\n\\])*\/[gim]*/.source).
      put(:STRING1,     /\'(\\.|[^\'\\])*\'/.source).
      put(:STRING2,     /"(\\.|[^"\\])*"/.source)
    
  end
end


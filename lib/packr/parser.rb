class Packr
  class Parser < RegexpGroup
    
    def put(expression, replacement)
      expression = DICTIONARY.exec(expression) if expression.is_a?(String)
      super(expression, replacement)
    end
    
    DICTIONARY = RegexpGroup.new({
      :OPERATOR =>    /return|typeof|[\[(\^=,{}:;&|!*?]/.source,
      :CONDITIONAL => /\/\*@\w*|\w*@\*\/|\/\/@\w*|@\w+/.source,
      :COMMENT1 =>    /\/\/[^\n]*/.source,
      :COMMENT2 =>    /\/\*[^*]*\*+([^\/][^*]*\*+)*\//.source,
      :REGEXP =>      /\/(\\[\/\\]|[^*\/])(\\.|[^\/\n\\])*\/[gim]*/.source,
      :STRING1 =>     /'(\\.|[^'\\])*'/.source,
      :STRING2 =>     /"(\\.|[^"\\])*"/.source
    })
    
  end
end


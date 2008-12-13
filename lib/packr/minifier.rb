class Packr
  class Minifier
    
    def self.conditional_comments
      @@conditional_comments
    end
    
    def initialize
      @concat = CONCAT.union(DATA)
      
      def @concat.exec(script)
        parsed = super(script)
        while parsed != script
          script = parsed
          parsed = super(script)
        end
        parsed
      end
      
      @comments = DATA.union(COMMENTS)
      @clean = DATA.union(CLEAN)
      @whitespace = DATA.union(WHITESPACE)
      
      @@conditional_comments = @comments.copy
      @@conditional_comments.put_at(-1, " \\3")
      @whitespace.remove_at(2) # conditional comments
      @comments.remove_at(2)
    end
    
    def minify(script)
      # packing with no additional options
      script += "\n"
      script = script.gsub(CONTINUE, "")
      script = @comments.exec(script)
      script = @clean.exec(script)
      script = @whitespace.exec(script)
      script = @concat.exec(script)
      script
    end
    
    CONTINUE = /\\\r?\n/
    
    CLEAN = Parser.new.
      put("\\(\\s*([^;)]*)\\s*;\\s*([^;)]*)\\s*;\\s*([^;)]*)\\)", "(\\1;\\2;\\3)"). # for (;;) loops
      put("throw[^};]+[};]", IGNORE). # a safari 1.3 bug
      put(";+\\s*([};])", "\\1")
    
    COMMENTS = Parser.new.
      put(";;;[^\\n]*\\n", REMOVE).
      put("(COMMENT1)\\n\\s*(REGEXP)?", "\n\\3").
      put("(COMMENT2)\\s*(REGEXP)?", lambda do |*args|
        match, comment, b, regexp = args[0..3]
        if comment =~ /^\/\*@/ and comment =~ /@\*\/$/
        #  comments = Minifier.conditional_comments.exec(comment)
        else
          comment = ""
        end
        comment + " " + (regexp || "")
      end)
    
    CONCAT = Parser.new.
      put("(STRING1)\\+(STRING1)", lambda { |*args| args[1][0...-1] + args[3][1..-1] }).
      put("(STRING2)\\+(STRING2)", lambda { |*args| args[1][0...-1] + args[3][1..-1] })
    
    WHITESPACE = Parser.new.
      put("/\\/\\/@[^\\n]*\\n", IGNORE).
      put("@\\s+\\b", "@ "). # protect conditional comments
      put("\\b\\s+@", " @").
      put("(\\d)\\s+(\\.\\s*[a-z\\$_\\[(])", "\\1 \\2"). # http://dean.edwards.name/weblog/2007/04/packer3/#comment84066
      put("([+-])\\s+([+-])", "\\1 \\2"). # c = a++ +b;
      put("\\b\\s+\\$\\s+\\b", " $ "). # var $ in
      put("\\$\\s+\\b", "$ "). # object$ in
      put("\\b\\s+\\$", " $"). # return $object
    # put("\\b\\s+#", " #").   # CSS
      put("\\b\\s+\\b", SPACE).
      put("\\s+", REMOVE)
    
  end
end


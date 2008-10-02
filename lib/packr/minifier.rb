class Packr
  class Minifier
    
    def initialize
      @concat = Parser.new(CONCAT).merge(DATA)
      
      def @concat.exec(script)
        parsed = super(script)
        while parsed != script
          script = parsed
          parsed = super(script)
        end
        parsed
      end
      
      @comments = DATA.union(Parser.new(COMMENTS))
      @clean = DATA.union(Parser.new(CLEAN))
      @whitespace = DATA.union(Parser.new(WHITESPACE))
      
      @conditional_comments = @comments.copy
      @conditional_comments.put_at(-1, " \\3")
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
    
    CLEAN = {
      "\\(\\s*([^;)]*)\\s*;\\s*([^;)]*)\\s*;\\s*([^;)]*)\\)" => "(\\1;\\2;\\3)", # for (;;) loops
      "throw[^};]+[};]" => IGNORE, # a safari 1.3 bug
      ";+\\s*([};])" => "\\1"
    }
    
    COMMENTS = {
      ";;;[^\\n]*\\n" => REMOVE,
      "(COMMENT1)\\n\\s*(REGEXP)?" => "\n\\3",
      "(COMMENT2)\\s*(REGEXP)?" => lambda do |*args|
        match, comment, b, regexp = args[0..3]
        if comment =~ /^\/\*@/ and comment =~ /@\*\/$/
          comments = @@conditional_comments.exec(comment)
        else
          comment = ""
        end
        comment + " " + (regexp || "")
      end
    }
    
    CONCAT = {
      "(STRING1)\\+(STRING1)" => lambda { |*args| args[1][0...-1] + args[3][1..-1] },
      "(STRING2)\\+(STRING2)" => lambda { |*args| args[1][0...-1] + args[3][1..-1] }
    }
    
    WHITESPACE = {
      "/\\/\\/@[^\\n]*\\n" => IGNORE,
      "@\\s+\\b" => "@ ", # protect conditional comments
      "\\b\\s+@" => " @",
      "(\\d)\\s+(\\.\\s*[a-z\\$_\\[(])" => "\\1 \\2", # http://dean.edwards.name/weblog/2007/04/packer3/#comment84066
      "([+-])\\s+([+-])" => "\\1 \\2", # c = a++ +b;
      "\\b\\s+\\$\\s+\\b" => " $ ", # var $ in
      "\\$\\s+\\b" => "$ ", # object$ in
      "\\b\\s+\\$" => " $", # return $object
    # "\\b\\s+#" => " #",   # CSS
      "\\b\\s+\\b" => SPACE,
      "\\s+" => REMOVE
    }
    
  end
end


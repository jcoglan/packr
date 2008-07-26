# PackR -- a Ruby port of Packer by Dean Edwards
# Packer version 3.1 (alpha 3) - copyright 2004-2007, Dean Edwards
# http://www.opensource.org/licenses/mit-license

require File.dirname(__FILE__) + '/string'
require File.dirname(__FILE__) + '/packr/map'
require File.dirname(__FILE__) + '/packr/collection'
require File.dirname(__FILE__) + '/packr/regexp_group'
require File.dirname(__FILE__) + '/packr/words'
require File.dirname(__FILE__) + '/packr/base62'

class Packr
  
  VERSION = '3.1.0'
  
  class << self
    def protect_vars(*args)
      @packr ||= self.new
      @packr.protect_vars(*args)
    end
    
    def minify(script)
      @packr ||= self.new
      @packr.minify(script)
    end
    
    def pack(script, options = {})
      @packr ||= self.new
      @packr.pack(script, options)
    end
  end
  
  def self.y(&f)
    lambda { |g| g[g] } [
      lambda do |h|
        lambda { |*args| f[h[h]][*args] }
      end
    ]
  end
  
  IGNORE  = RegexpGroup::IGNORE
  KEYS    = "~"
  REMOVE  = ""
  SPACE   = " "
  
  CONTINUE = /\\\r?\n/
  ENCODED  = /~\^(\d+)\^~/
  PRIVATES = /\b_[\da-zA-Z$][\w$]*\b/
  SHRUNK   = /@\d+\b/
  WORDS    = /\b[\da-zA-Z]\b|\w{2,}/
  
  ENCODE10 = "String"
  ENCODE36 = "function(c){return c.toString(36)}"
  ENCODE62 = "function(c){return(c<62?'':e(parseInt(c/62)))+((c=c%62)>35?String.fromCharCode(c+29):c.toString(36))}"
  
  ENCODE = y do |rec|
    lambda do |c|
      (c < 62 ? '' : rec.call((c / 62.0).to_i)) +
          ((c = c % 62) > 35 ? (c+29).chr : c.to_s(36))
    end
  end
  
  def self.encode52(c)
    # Base52 encoding (a-Z)
    encode = lambda do |d|
      (d < 52 ? '' : encode.call((d / 52.0).to_i)) +
          ((d = d % 52) > 25 ? (d + 39).chr : (d + 97).chr)
    end
    encoded = encode.call(c.to_i)
    encoded = encoded[1..-1] + '0' if encoded =~ /^(do|if|in)$/
    encoded
  end
  
  UNPACK = lambda do |p,a,c,k,e,r|
    "eval(function(p,a,c,k,e,r){e=#{e};if('0'.replace(0,e)==0){while(c--)r[e(c)]=k[c];" +
        "k=[function(e){return r[e]||e}];e=function(){return'#{r}'};c=1};while(c--)if(k[c])p=p." +
        "replace(new RegExp('\\\\b'+e(c)+'\\\\b','g'),k[c]);return p}('#{p}',#{a},#{c},'#{k}'.split('|'),0,{}))"
  end
  
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
  
  DATA = {
    "STRING1" => IGNORE,
    'STRING2' => IGNORE,
    "CONDITIONAL" => IGNORE, # conditional comments
    "(OPERATOR)\\s*(REGEXP)" => "\\1\\2"
  }
  
  JAVASCRIPT = RegexpGroup.new(
    :OPERATOR =>    /return|typeof|[\[(\^=,{}:;&|!*?]/.source,
    :CONDITIONAL => /\/\*@\w*|\w*@\*\/|\/\/@\w*|@\w+/.source,
    :COMMENT1 =>    /\/\/[^\n]*/.source,
    :COMMENT2 =>    /\/\*[^*]*\*+([^\/][^*]*\*+)*\//.source,
    :REGEXP =>      /\/(\\[\/\\]|[^*\/])(\\.|[^\/\n\\])*\/[gim]*/.source,
    :STRING1 =>     /'(\\.|[^'\\])*'/.source,
    :STRING2 =>     /"(\\.|[^"\\])*"/.source
  )
  
  WHITESPACE = {
    "/\\/\\/@[^\\n]*\\n" => IGNORE,
    "@\\s+\\b" => "@ ", # protect conditional comments
    "\\b\\s+@" => " @",
    "(\\d)\\s+(\\.\\s*[a-z\\$_\\[(])" => "\\1 \\2", # http://dean.edwards.name/weblog/2007/04/packer3/#comment84066
    "([+-])\\s+([+-])" => "\\1 \\2", # c = a++ +b;
    "\\b\\s+\\$\\s+\\b" => " $ ", # var $ in
    "\\$\\s+\\b" => "$ ", # object$ in
    "\\b\\s+\\$" => " $", # return $object
#   "\\b\\s+#" => " #",   # CSS
    "\\b\\s+\\b" => SPACE,
    "\\s+" => REMOVE
  }
  
  def self.build(group)
    group.inject(RegexpGroup.new({})) do |data, item|
      expression, replacement = *item
      data.put(JAVASCRIPT.exec(expression), replacement)
      data
    end
  end
  
  def initialize
    @data = self.class.build(DATA)
    @concat = self.class.build(CONCAT)
    
    def @concat.exec(script)
      parsed = super(script)
      while parsed != script
        script = parsed
        parsed = super(script)
      end
      parsed
    end
    
    @comments = @data.union(self.class.build(COMMENTS))
    @@conditional_comments = @comments.copy
    @@conditional_comments.put_at(-1, " \\3")
    @comments.remove_at(2)
    
    @clean = @data.union(self.class.build(CLEAN))
    @whitespace = @data.union(self.class.build(WHITESPACE))
    @whitespace.remove_at(2) # conditional comments
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
  
  def pack(script, options = {})
    script = minify(script)
    script = shrink_variables(script, options[:base62], options[:protect]) if options[:shrink_vars]
    script = encode_private_variables(script) if options[:private]
    script = base62_encode(script, options[:shrink_vars]) if options[:base62]
    @strings = nil
    script
  end
  
private
  
  def base62_encode(script, shrink = nil)
    words = Base62.new
    pattern = WORDS
    pattern = Regexp.new(SHRUNK.source + "|" + pattern.source) if shrink
    
    # build the packed script
    
    p = escape(words.exec(script, pattern))
    a = "[]"
    c = (s = words.size).zero? ? 1 : s
    k = words.get_key_words
    e = self.class.const_get("ENCODE#{c > 10 ? (c > 36 ? 62 : 36) : 10}")
    d = words.get_decoder
    
    # the whole thing
    UNPACK[p,a,c,k,e,d]
  end
  
  def decode(script)
    # put strings and regular expressions back
    script.gsub(ENCODED) { |match| @strings[$1.to_i] }
  end
  
  def encode(script)
    # encode strings and regular expressions
    @strings = [] # encoded strings and regular expressions
    @data.exec(script, lambda { |match, *args|
      operator, regexp = args[0].to_s, args[1].to_s
      replacement = "~^#{@strings.length}^~"
      unless regexp.empty?
        replacement = operator + replacement
        match = regexp
      end
      @strings << match
      replacement
    })
  end
  
  def encode_private_variables(script, words = nil)
    index = 0
    encoder = self.class.build({
      :CONDITIONAL  => IGNORE,
      "(OPERATOR)(REGXEP)" => IGNORE
    })
    private_vars = Words.new
    encoder.put(PRIVATES, lambda { |word, *args|
      private_vars.add(word)
    })
    encoder.exec(script)
    private_vars.encode! { |i| '_' + ENCODE.call(i) }
    
    script.gsub(PRIVATES) do |word|
      private_vars.has?(word) ? private_vars.get(word).replacement : word
    end
  end
  
  def escape(script)
    # Single quotes wrap the final string so escape them.
    # Also, escape new lines (required by conditional comments).
    script.gsub(/([\\'])/) { |match| "\\#{$1}" }.gsub(/[\r\n]+/, "\\n")
  end
  
  def shrink_variables(script, base62 = nil, protected_names = [])
    script = encode(script)
    protected_names ||= []
    protected_names = protected_names.map { |s| s.to_s }
    
    # identify blocks, particularly identify function blocks (which define scope)
    __block       = /((catch|do|if|while|with|function)\b[^~{};]*(\(\s*[^{};]*\s*\))\s*)?(\{[^{}]*\})/
    __brackets    = /\{[^{}]*\}|\[[^\[\]]*\]|\([^\(\)]*\)|~[^~]+~/
    __encoded     = /~#?(\d+)~/
    __identifier  = /[a-zA-Z_$][\w\$]*/
    __scoped      = /~#(\d+)~/
    __var         = /\bvar\b/
    __vars        = /\bvar\s+[\w$]+[^;#]*|\bfunction\s+[\w$]+/
    __var_tidy    = /\b(var|function)\b|\sin\s+[^;]+/
    __var_equal   = /\s*=[^,;]*/
    
    blocks = [] # store program blocks (anything between braces {})
    total = 0
    # decoder for program blocks
    decoder = lambda do |script, encoded|
      script = script.gsub(encoded) { |match| blocks[$1.to_i] } while script =~ encoded
      script
    end
    
    # encoder for program blocks
    encoder = lambda do |match|
      prefix, block_type, args, block = $1 || "", $2, $3, $4
      if block_type == 'function'
        # decode the function block (THIS IS THE IMPORTANT BIT)
        # We are retrieving all sub-blocks and will re-parse them in light
        # of newly shrunk variables
        block = args + decoder.call(block, __scoped)
        prefix = prefix.gsub(__brackets, "")
        
        # create the list of variable and argument names
        args = args[1...-1]
        
        if args != '_no_shrink_'
          vars = block.scan(__vars).join(";").gsub(__var, ";var")
          vars = vars.gsub(__brackets, "") while vars =~ __brackets
          vars = vars.gsub(__var_tidy, "").gsub(__var_equal, "")
        end
        block = decoder.call(block, __encoded)
        
        pre = "@"
        
        # process each identifier
        if args != '_no_shrink_'
          count, short_id = 0, nil
          ids = [args, vars].join(",").scan(__identifier)
          processed = {}
          ids.each do |id|
            if !processed[id] and !protected_names.include?(id)
              processed[id] = true
              id = id.rescape
              # encode variable names
              count += 1 while block =~ Regexp.new("#{pre}#{count}\\b")
              reg = Regexp.new("([^\\w$.])#{id}([^\\w$:])")
              block = block.gsub(reg, "\\1#{pre}#{count}\\2") while block =~ reg
              reg = Regexp.new("([^{,\\w$.])#{id}:")
              block = block.gsub(reg, "\\1#{pre}#{count}:")
              count += 1
            end
          end
          total = [total, count].max
        end
        replacement = "#{prefix}~#{blocks.length}~"
        blocks << block
      else
        replacement = "~##{blocks.length}~"
        blocks << (prefix + block)
      end
      replacement
    end
    
    # encode blocks, as we encode we replace variable and argument names
    script = script.gsub(__block, &encoder) while script =~ __block
    
    # put the blocks back
    script = decoder.call(script, __encoded)
    
    unless base62
      shrunk = Words.new(script, SHRUNK)
      short_id, count = nil, 0
      shrunk.encode! do |object|
        # find the next free short name
        begin
          short_id = self.class.encode52(count)
          count += 1
        end while script =~ Regexp.new("[^\\w$.]#{short_id}[^\\w$:]")
        short_id
      end
      script = script.gsub(SHRUNK) do |word|
        shrunk.get(word).replacement
      end
    end
    
    decode(script)
  end
end

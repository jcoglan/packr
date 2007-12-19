# PackR -- a Ruby port of Packer by Dean Edwards
# Packer version 3.1 (alpha 3) - copyright 2004-2007, Dean Edwards
# http://www.opensource.org/licenses/mit-license

require File.dirname(__FILE__) + '/string'
require File.dirname(__FILE__) + '/packr/map'
require File.dirname(__FILE__) + '/packr/collection'
require File.dirname(__FILE__) + '/packr/regexp_group'
require File.dirname(__FILE__) + '/packr/words'

class Packr
  
  PROTECTED_NAMES = %w($super)
  
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
    
    def pack_file(path, options = {})
      @packr ||= self.new
      @packr.pack_file(path, options)
    end
  end
  
  IGNORE = RegexpGroup::IGNORE
  REMOVE = ""
  SPACE = " "
  WORDS = /\w+/
  
  CONTINUE = /\\\r?\n/
  PRIVATE = /\b_[A-Za-z\d$][\w$]*\b/
  
  ENCODE10 = "String"
  ENCODE36 = "function(c){return c.toString(36)}"
  ENCODE62 = "function(c){return(c<62?'':e(parseInt(c/62)))+((c=c%62)>35?String.fromCharCode(c+29):c.toString(36))}"
  
  UNPACK = lambda do |p,a,c,k,e,r|
    "eval(function(p,a,c,k,e,r){e=#{e};if(!''.replace(/^/,String)){while(c--)r[e(c)]=k[c];" +
        "k=[function(e){return r[e]||e}];e=function(){return'\\\\w#{r}'};c=1};while(c--)if(k[c])p=p." +
        "replace(new RegExp('\\\\b'+e(c)+'\\\\b','g'),k[c]);return p}('#{p}',#{a},#{c},'#{k}'.split('|'),0,{}))"
  end
  
  CLEAN = {
    "\\(\\s*([^;]*)\\s*;\\s*([^;]*)\\s*;\\s*([^)]*)\\)" => "(\\1;\\2;\\3)", # for (;;) loops
    "throw[^};]+[};]" => IGNORE, # a safari 1.3 bug
    ";+\\s*([};])" => "\\1"
  }
  
  COMMENTS = {
    "(COMMENT1)\\n\\s*(REGEXP)?" => "\n\\3",
    "(COMMENT2)\\s*(REGEXP)?" => " \\3"
  }
  
  PRIVATES = { # conditional comments
    "STRING1" => IGNORE,
    'STRING2' => IGNORE,
    "@\\w+" => IGNORE,
    "\\w+@" => IGNORE,
    "([\\[(\\^=,{}:;&|!*?])\\s*(REGEXP)" => "\\1\\2"
  }
  
  DATA = {
    # strings
    "STRING1" => IGNORE,
    'STRING2' => IGNORE,
    "CONDITIONAL" => IGNORE, # conditional comments
    "([\\[(\\^=,{}:;&|!*?])\\s*(REGEXP)" => "\\1\\2"
  }
  
  JAVASCRIPT = RegexpGroup.new(
    :CONDITIONAL  => /\/\*@\w*|\w*@\*\/|\/\/@\w*[^\n]*\n/.source,
    :COMMENT1     => /(\/\/|;;;)[^\n]*/.source,
    :COMMENT2     => /\/\*[^*]*\*+([^\/][^*]*\*+)*\//.source,
    :REGEXP       => /\/(\\[\/\\]|[^*\/])(\\.|[^\/\n\\])*\/[gim]*/.source,
    :STRING1      => /'(\\.|[^'\\])*'/.source,
    :STRING2      => /"(\\.|[^"\\])*"/.source
  )
  
  WHITESPACE = {
    "(\\d)\\s+(\\.\\s*[a-z\\$_\\[(])" => "\\1 \\2", # http://dean.edwards.name/weblog/2007/04/packer3/#comment84066
    "([+-])\\s+([+-])" => "\\1 \\2", # c = a++ +b;
    "\\b\\s+\\$\\s+\\b" => " $ ", # var $ in
    "\\$\\s+\\b" => "$ ", # object$ in
    "\\b\\s+\\$" => " $", # return $object
    "\\b\\s+#" => " #",
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
    @comments = @data.union(self.class.build(COMMENTS))
    @privates = self.class.build(PRIVATES)
    @clean = @data.union(CLEAN)
    @whitespace = @data.union(WHITESPACE)
    @protected_names = PROTECTED_NAMES.dup
  end
  
  def protect_vars(*args)
    args = args.map { |arg| arg.to_s.strip }.select { |arg| arg =~ /^[a-z\_\$][a-z0-9\_\$]*$/i }
    @protected_names = (@protected_names + args).uniq
  end
  
  def minify(script)
    # packing with no additional options
    pack(script)
  end
  
  def pack(script, options = {})
    script += "\n"
    script = script.gsub(CONTINUE, "")
    script = @comments.exec(script)
    script = @clean.exec(script)
    script = shrink_variables(script) if options[:shrink]
    script = @whitespace.exec(script)
    script = @clean.exec(script) if options[:shrink]
    script = encode_private_variables if options[:private]
    script = base62_encode(script) if options[:base62]
    script
  end
  
  def pack_file(path, options = {})
    path = path.gsub(Regexp.new("^((#{RAILS_ROOT.gsub(/\./, "\\.")})?/)?"), RAILS_ROOT + '/')
    script = File.read(path)
    script = pack(script, options)
    File.open(path, 'wb') { |f| f.write(script) }
  end
  
private
  
  def base62_encode(script)
    words = Words.new(script)
    words.encode!
    
    # build the packed script
    
    encode = lambda do |c|
      (c < 62 ? '' : encode.call((c.to_f / 62).to_i) ) +
          ((c = c % 62) > 35 ? (c+29).chr : c.to_s(36))
    end
    
    p = escape(words.exec(script))
    a = "[]"
    c = (s = words.size).zero? ? 1 : s
    k = words.get_words.join("|").gsub(/\|+$/, "")
    e = self.class.const_get("ENCODE#{c > 10 ? (c > 36 ? 62 : 36) : 10}")
    r = (c > 62) ? "{1,#{encode.call(c).length}}" : ""
    
    # the whole thing
    UNPACK.call(p,a,c,k,e,r)
  end
  
  def encode_private_variables(script, words = nil)
    index, encoded = 0, {}
    @privates.put(PRIVATE, lambda do |id|
      if encoded[id].nil?
        encoded[id] = index
        index += 1
      end
      "_#{encoded[id]}"
    end)
    @privates.exec(script)
  end
  
  def escape(script)
    # Single quotes wrap the final string so escape them.
    # Also, escape new lines (required by conditional comments).
    script.gsub(/([\\'])/) { |match| "\\#{$1}" }.gsub(/[\r\n]+/, "\\n")
  end
  
  def shrink_variables(script)
    data = [] # encoded strings and regular expressions
    regexp= /^[^'"]\//
    
    store = lambda do |string|
      replacement = "@#{data.length}"
      if string =~ regexp
        replacement = string[0].chr + replacement
        string = string[1..-1]
      end
      data << string
      replacement
    end
    
    # Base52 encoding (a-Z)
    encode52 = lambda do |c|
      (c < 52 ? '' : encode52.call((c.to_f / 52).to_i) ) +
          ((c = c % 52) > 25 ? (c + 39).chr : (c + 97).chr)
    end
    
    # identify blocks, particularly identify function blocks (which define scope)
    __block     = /((catch|do|if|while|with|function)\b\s*[^~{;]*\s*(\(\s*[^{;]*\s*\))\s*)?(\{([^{}]*)\})/
    __brackets  = /\{[^{}]*\}|\[[^\[\]]*\]|\([^\(\)]*\)|~[^~]+~/
    __encoded   = /~#?(\d+)~/
    __scoped    = /~#(\d+)~/
    __vars      = /\bvar\s+[\w$]+[^;#]*|\bfunction\s+[\w$]+/
    __var_tidy  = /\b(var|function)\b|\sin\s+[^;]+/
    __var_equal = /\s*=[^,;]*/
    __list      = /[^\s,;]+/
    
    blocks = [] # store program blocks (anything between braces {})
    
    # decoder for program blocks
    decode = lambda do |script, encoded|
      script = script.gsub(encoded) { |match| blocks[$1.to_i] } while script =~ encoded
      script
    end
    
    # encoder for program blocks
    encode = lambda do |match|
      prefix, block_type, args, block = $1 || "", $2, $3, $4
      case block_type
      when "function"
        # decode the function block (THIS IS THE IMPORTANT BIT)
        # We are retrieving all sub-blocks and will re-parse them in light
        # of newly shrunk variables
        block = args + decode.call(block, __scoped)
        prefix = prefix.gsub(__brackets, "")
        
        # create the list of variable and argument names
        args = args[1...-1]
        vars = block.scan(__vars).join(";")
        vars = vars.gsub(__brackets, "") while vars =~ __brackets
        vars = vars.gsub(__var_tidy, "").gsub(__var_equal, "")
        
        block = decode.call(block, __encoded)
        
        # process each identifier
        count, short_id = 0, nil
        ids = [args, vars].join(",").scan(__list)
        ids.each do |id|
          if id.length > 1 and !@protected_names.include?(id) # > 1 char
            id = id.rescape
            # find the next free short name (check everything in the current scope)
            while block =~ %r{[^\w$.@]#{short_id}[^\w$:@]}
              short_id = encode52.call(count)
              count += 1
            end
            # replace the long name with the short name
            reg = %r{([^\w$.@])#{id}([^\w$:@])}
            block = block.gsub(reg, "\\1#{short_id}\\2") while block =~ reg
            reg = Regexp.new("([^{,\\w$.])#{id}:")
            block = block.gsub(reg, "\\1#{short_id}:")
          end
        end
      else
        # remove unnecessary braces
      #  if block_type.to_s =~ /do|else|else\s+if|if|while|with/ and block !~ /[;~]/
      #    block = " #{block[1...-1]};"
      #  end
      end
      block_type = (block_type == "function") ? "" : "#"
      replacement = "~#{block_type}#{blocks.length}~"
      blocks << prefix + block
      replacement
    end
    
    # encode strings and regular expressions
    script = @data.exec(script, &store)
    
    # remove closures (this is for base2 namespaces only)
    script = script.gsub(/new function\(_\)\s*\{/, "{;#;")
    
    # encode blocks, as we encode we replace variable and argument names
    script = script.gsub(__block, &encode) while script =~ __block
    
    # put the blocks back
    script = decode.call(script, __encoded)
    
    # put back the closure (for base2 namespaces only)
    script = script.gsub(/\{;#;/, "new function(_){")
    
    # put strings and regular expressions back
    script = script.gsub(/@(\d+)/) { |match| data[$1.to_i] }
    
    script
  end
end

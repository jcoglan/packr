# PackR -- a Ruby port of Packer by Dean Edwards
# Packer version 3.0 (final) - copyright 2004-2007, Dean Edwards
# http://www.opensource.org/licenses/mit-license

require 'regexp'
require 'string'
require 'strscan'
require 'packr/regexp_group'

class Packr
  
  IGNORE = RegexpGroup::IGNORE
  REMOVE = ""
  SPACE = " "
  WORDS = /\w+/
  
  CONTINUE = /\\\r?\n/
  
  ENCODE10 = "String"
  ENCODE36 = "function(c){return c.toString(a)}"
  ENCODE62 = "function(c){return(c<a?'':e(parseInt(c/a)))+((c=c%a)>35?String.fromCharCode(c+29):c.toString(36))}"
  
  UNPACK = "eval(function(p,a,c,k,e,r){e=%5;if(!''.replace(/^/,String)){while(c--)r[%6]=k[c]" +
      "||%6;k=[function(e){return r[e]}];e=function(){return'\\\\w+'};c=1};while(c--)if(k[c])p=p." +
      "replace(new RegExp('\\\\b'+e(c)+'\\\\b','g'),k[c]);return p}('%1',%2,%3,'%4'.split('|'),0,{}))"
  
  CLEAN = RegexpGroup.new(
    "\\(\\s*;\\s*;\\s*\\)" => "(;;)", # for (;;) loops
    "throw[^};]+[};]" => IGNORE, # a safari 1.3 bug
    ";+\\s*([};])" => "\\1"
  )
  
  DATA = RegexpGroup.new(
    # strings
    "STRING1" => IGNORE,
    'STRING2' => IGNORE,
    "CONDITIONAL" => IGNORE, # conditional comments
    "(COMMENT1)\\n\\s*(REGEXP)?" => "\n\\3",
    "(COMMENT2)\\s*(REGEXP)?" => " \\3",
    "([\\[(\\^=,{}:;&|!*?])\\s*(REGEXP)" => "\\1\\2"
  )
  
  JAVASCRIPT = RegexpGroup.new(
    :COMMENT1 =>    /(\/\/|;;;)[^\n]*/.source,
    :COMMENT2 =>    /\/\*[^*]*\*+([^\/][^*]*\*+)*\//.source,
    :CONDITIONAL => /\/\*@|@\*\/|\/\/@[^\n]*\n/.source,
    :REGEXP =>      /\/(\\[\/\\]|[^*\/])(\\.|[^\/\n\\])*\/[gim]*/.source,
    :STRING1 =>     /'(\\.|[^'\\])*'/.source,
    :STRING2 =>     /"(\\.|[^"\\])*"/.source
  )
  
  WHITESPACE = RegexpGroup.new(
    "(\\d)\\s+(\\.\\s*[a-z\\$_\\[(])" => "\\1 \\2", # http://dean.edwards.name/weblog/2007/04/packer3/#comment84066
    "([+-])\\s+([+-])" => "\\1 \\2", # c = a++ +b;
    "\\b\\s+\\$\\s+\\b" => " $ ", # var $ in
    "\\$\\s+\\b" => "$ ", # object$ in
    "\\b\\s+\\$" => " $", # return $object
    "\\b\\s+\\b" => SPACE,
    "\\s+" => REMOVE
  )
  
  def initialize
    @data = {}
    DATA.values.each { |item| @data[JAVASCRIPT.exec(item.expression)] = item.replacement }
    @data = RegexpGroup.new(@data)
    @whitespace = @data.union(WHITESPACE)
    @clean = @data.union(CLEAN)
  end
  
  def minify(script)
    script = script.gsub(CONTINUE, "")
    script = @data.exec(script)
    script = @whitespace.exec(script)
    script = @clean.exec(script)
    script
  end
  
  def pack(script, options = {})
    script = minify(script + "\n")
    script = shrink_variables(script) if options[:shrink_vars]
    script
  end
  
private
  
  def shrink_variables(script)
    data = [] # encoded strings and regular expressions
    regexp= /^[^'"]\//
    store = lambda do |string|
      replacement = "##{data.length}"
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
    __block = /(function\s*[\w$]*\s*\(\s*([^\)]*)\s*\)\s*)?(\{([^{}]*)\})/
    __var = /var\s+/
    __var_name = /var\s+[\w$]+/
    __comma = /\s*,\s*/
    blocks = [] # store program blocks (anything between braces {})
    
    # decoder for program blocks
    encoded = /~(\d+)~/
    decode = lambda do |script|
      script = script.gsub(encoded) { |match| blocks[$1.to_i] } while script =~ encoded
      script
    end
    
    # encoder for program blocks
    encode = lambda do |match|
      block, func, args = match, $1, $2
      if func # the block is a function block
        
        # decode the function block (THIS IS THE IMPORTANT BIT)
        # We are retrieving all sub-blocks and will re-parse them in light
        # of newly shrunk variables
        block = decode.call(block)
        
        # create the list of variable and argument names
        vars = block.scan(__var_name).join(",").gsub(__var, "")
        ids = (args.split(__comma) + vars.split(__comma)).uniq
        
        #process each identifier
        count = 0
        ids.each do |id|
          id = id.strip
          if id and id.length > 1 # > 1 char
            id = id.rescape
            # find the next free short name (check everything in the current scope)
            short_id = encode52.call(count)
            while block =~ Regexp.new("[^\\w$.]#{short_id}[^\\w$:]")
              count += 1
              short_id = encode52.call(count)
            end
            # replace the long name with the short name
            reg = Regexp.new("([^\\w$.])#{id}([^\\w$:])")
            block = block.gsub(reg, "\\1#{short_id}\\2") while block =~ reg
            reg = Regexp.new("([^{,\\w$.])#{id}:")
            block = block.gsub(reg, "\\1#{short_id}:")
          end
        end
      end
      replacement = "~#{blocks.length}~"
      blocks << block
      replacement
    end
    
    # encode strings and regular expressions
    script = @data.exec(script, &store)
    
    # remove closures (this is for base2 namespaces only)
    script = script.gsub(/new function\(_\)\s*\{/, "{;#;")
    
    # encode blocks, as we encode we replace variable and argument names
    script = script.gsub(__block, &encode) while script =~ __block
    
    # put the blocks back
    script = decode.call(script)
    
    # put back the closure (for base2 namespaces only)
    script = script.gsub(/\{;#;/, "new function(_){")
    
    # put strings and regular expressions back
    script = script.gsub(/#(\d+)/) { |match| data[$1.to_i] }
    
    script
  end
end

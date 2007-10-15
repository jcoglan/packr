# PackR -- a Ruby port of Packer by Dean Edwards
# Packer version 3.0 (final) - copyright 2004-2007, Dean Edwards
# http://www.opensource.org/licenses/mit-license

require 'regexp'
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
    script
  end
end

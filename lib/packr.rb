# PackR -- a Ruby port of Packer by Dean Edwards
# Packer version 3.1 (alpha 3) - copyright 2004-2007, Dean Edwards
# http://www.opensource.org/licenses/mit-license

require File.dirname(__FILE__) + '/string'
require File.dirname(__FILE__) + '/packr/map'
require File.dirname(__FILE__) + '/packr/collection'
require File.dirname(__FILE__) + '/packr/regexp_group'
require File.dirname(__FILE__) + '/packr/constants'
require File.dirname(__FILE__) + '/packr/encoder'
require File.dirname(__FILE__) + '/packr/minifier'
require File.dirname(__FILE__) + '/packr/parser'
require File.dirname(__FILE__) + '/packr/privates'
require File.dirname(__FILE__) + '/packr/shrinker'
require File.dirname(__FILE__) + '/packr/words'
require File.dirname(__FILE__) + '/packr/base62'

class Packr
  
  VERSION = '3.1.0'
  
  DATA = Parser.new({
    "STRING1" => IGNORE,
    'STRING2' => IGNORE,
    "CONDITIONAL" => IGNORE, # conditional comments
    "(OPERATOR)\\s*(REGEXP)" => "\\1\\2"
  })
  
  class << self
    def pack(script, options = {})
      @packr ||= self.new
      @packr.pack(script, options)
    end
  end
  
  def initialize
    @minifier = Minifier.new
    @shrinker = Shrinker.new
    @privates = Privates.new
  end
  
  def pack(script, options = {})
    script = @minifier.minify(script)
    script = @shrinker.shrink(script, options[:protect]) if options[:shrink_vars]
    script = @privates.encode(script) if options[:private]
    script
  end
  
end


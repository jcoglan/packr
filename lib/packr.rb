# PackR -- a Ruby port of Packer by Dean Edwards
# Packer version 3.1 copyright 2004-2009, Dean Edwards
# http://www.opensource.org/licenses/mit-license

[ '/string',
  '/packr/map',
  '/packr/collection',
  '/packr/regexp_group',
  '/packr/constants',
  '/packr/encoder',
  '/packr/parser',
  '/packr/minifier',
  '/packr/privates',
  '/packr/shrinker',
  '/packr/words',
  '/packr/base62'
].each do |path|
  require File.dirname(__FILE__) + path
end

class Packr
  
  VERSION = '3.1.0'
  
  DATA = Parser.new.
    put("STRING1", IGNORE).
    put('STRING2', IGNORE).
    put("CONDITIONAL", IGNORE). # conditional comments
    put("(OPERATOR)\\s*(REGEXP)", "\\1\\2")
  
  def self.encode62(c)
    (c < 62 ? '' : encode62((c / 62.0).to_i)) +
        ((c = c % 62) > 35 ? (c+29).chr : c.to_s(36))
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
  
  def self.pack(script, options = {})
    @packr ||= self.new
    @packr.pack(script, options)
  end
  
  def initialize
    @minifier = Minifier.new
    @shrinker = Shrinker.new
    @privates = Privates.new
    @base62   = Base62.new
  end
  
  def pack(script, options = {})
    script = @minifier.minify(script)
    script = @shrinker.shrink(script, options[:protect]) if options[:shrink_vars]
    script = @privates.encode(script) if options[:private]
    script = @base62.encode(script) if options[:base62]
    script
  end
  
end


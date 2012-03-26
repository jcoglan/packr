require 'erb'
require 'fileutils'
require 'forwardable'
require 'set'
require 'strscan'

class Packr
  dir = File.expand_path('../packr', __FILE__)
  autoload :Base62,      dir + '/base62'
  autoload :Collection,  dir + '/collection'
  autoload :Encoder,     dir + '/encoder'
  autoload :FileSystem,  dir + '/file_system'
  autoload :Map,         dir + '/map'
  autoload :Minifier,    dir + '/minifier'
  autoload :Parser,      dir + '/parser'
  autoload :Privates,    dir + '/privates'
  autoload :RegexpGroup, dir + '/regexp_group'
  autoload :Shrinker,    dir + '/shrinker'
  autoload :SourceMap,   dir + '/source_map'
  autoload :Words,       dir + '/words'
  
  IGNORE = RegexpGroup::IGNORE
  REMOVE = ""
  SPACE  = " "
  
  DATA = Parser.new.
    put("STRING1", IGNORE).
    put('STRING2', IGNORE).
    put("CONDITIONAL", IGNORE). # conditional comments
    put("(OPERATOR)\\s*(REGEXP)", "\\1\\2")
  
  module StringExtension
    attr_accessor :source_map, :code
    extend Forwardable
    def_delegators :source_map, :header, :footer
  end
  
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
    new.pack(script, options)
  end
  
  def self.bundle(options)
    FileSystem.bundle(options)
  end
  
  def initialize
    @minifier = Minifier.new
    @shrinker = Shrinker.new
    @privates = Privates.new
    @base62   = Base62.new
  end
  
  def pack(script, options = {})
    minify     = (options[:minify] != false)
    source_map = SourceMap.new(script, options)
    script     = source_map.source_code
    
    if minify
      script = @minifier.minify(script) { |sections| source_map.remove(sections) }
    end
    
    script = @shrinker.shrink(script, options[:protect]) if minify && options[:shrink_vars]
    script = @privates.encode(script) if minify && options[:private]
    
    source_map.update(script)
    script = @base62.encode(script) if minify && options[:base62]
    
    source_map.append_metadata(script)
  end 
end


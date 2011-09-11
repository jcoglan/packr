require 'string' # require File.dirname(__FILE__) + path

module Packr

  autoload :Map,         'packr/map'
  autoload :Collection,  'packr/collection'
  autoload :RegexpGroup, 'packr/regexp_group'
  autoload :Encoder,     'packr/encoder'
  autoload :Parser,      'packr/parser'
  autoload :Minifier,    'packr/minifier'
  autoload :Privates,    'packr/privates'
  autoload :Shrinker,    'packr/shrinker'
  autoload :Words,       'packr/words'
  autoload :Base62,      'packr/base62'
  autoload :Engine,      'packr/engine'

  IGNORE = RegexpGroup::IGNORE
  REMOVE = ""
  SPACE = " "

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
    @packr ||= Packr::Engine.new
    @packr.pack(script, options)
  end

end


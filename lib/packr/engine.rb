module Packr
  class Engine

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
end
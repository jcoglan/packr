class Packr
  class Words < Collection
    
    attr_accessor :words
    
    def initialize(script)
      super({})
      script.to_s.scan(WORDS).each { |word| add(word) }
      encode!
    end
    
    def add(word)
      super unless has?(word)
      word = get(word)
      word.count = word.count + 1
      word
    end
    
    def to_s
      @keys.map { |key| get(key) }.join('|')
    end
    
  private
    
    def encode!
      # sort by frequency
      sort! { |word1, word2| word2.count - word1.count }
      
      a = 62
      e = lambda do |c|
        (c < a ? '' : e.call((c.to_f / a).to_i) ) +
            ((c = c % a) > 35 ? (c+29).chr : c.to_s(36))
      end
      
      encoded = Collection.new({}) # a dictionary of base62 -> base10
      (0...size).each { |i| encoded.put(e.call(i), i) }
      
      index = 0
      each do |word, key|
        if encoded.has?(word)
          word.index = encoded.get(word)
          def word.to_s; ""; end
        else
          index += 1 while has?(e.call(index))
          word.index = index
          index += 1
        end
        word.encoded = e.call(word.index)
      end
      
      # sort by encoding
      sort! { |word1, word2| word1.index - word2.index }
    end
    
    class Item
      attr_accessor :word, :count, :encoded, :index
      
      def initialize(*args)
        @word = args.first
        @count = 0
        @encoded = ""
        @index = -1
      end
      
      def to_s
        @word
      end
    end
    
  end
end

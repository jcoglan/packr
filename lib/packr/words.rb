class Packr
  class Words < RegexpGroup
    
    def initialize(script)
      super({})
      script.to_s.scan(WORDS).each { |word| add(word) }
    end
    
    def add(word)
      super unless has?(word)
      word = get(word)
      word.count = word.count + 1
    end
    
    def encode!
      # sort by frequency
      sort! { |word1, word2| word2.count - word1.count }
      
      encode = lambda do |c|
        (c < 62 ? '' : encode.call((c.to_f / 62).to_i) ) +
            ((c = c % 62) < 36 ? c.to_s(36) : (c+29).chr)
      end
      
      encoded = Collection.new({}) # a dictionary of base62 -> base10
      (0...size).each { |i| encoded.put(encode.call(i), i) }
      
      index = 0
      each do |word, key|
        if encoded.has?(word)
          word.index = encoded.get(word)
          def word.to_s; ""; end
        else
          index += 1 while has?(encode.call(index))
          word.index = index
          index += 1
          if word.count == 1
            def word.to_s; ""; end
          end
        end
        word.replacement = encode.call(word.index)
        if word.replacement.length == word.to_s.length
          def word.to_s; ""; end
        end
      end
      
      # sort by encoding
      sort! { |word1, word2| word1.index - word2.index }
      
      # trim unencoded words
      @keys = @keys[0..( get_words.join("|").sub(/\|+$/, "").scan(/\|/).length + 1 )]
      
      self
    end
    
    def exec(script)
      return script if size.zero?
      script.gsub(Regexp.new(self.to_s)) { |word| get(word).replacement }
    end
    
    def get_words
      @keys.map { |word| get(word).to_s }
    end
    
    def to_s
      words = get_words.join("|").gsub(/\|{2,}/, "|").gsub(/^\|+|\|+$/, "")
      words = "\\x0" if words == ""
      "\\b(#{words})\\b"
    end
    
    class Item < RegexpGroup::Item
      attr_accessor :count, :encoded, :index
      
      def initialize(*args)
        super
        @count = 0
        @encoded = ""
        @index = -1
      end
    end
    
  end
end

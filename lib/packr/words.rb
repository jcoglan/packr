class Packr
  class Words < RegexpGroup
    
    attr_accessor :words
    
    def initialize(script)
      super({})
      script.to_s.scan(WORDS).each { |word| add(word) }
    end
    
    def add(word)
      super unless has?(word)
      word = get(word)
      word.count = word.count + 1
      word
    end
    
    def encode!
      # sort by frequency
      sort! { |word1, word2| word2.count - word1.count }
      
      encode = lambda do |c|
        (c < 62 ? '' : encode.call((c.to_f / 62).to_i) ) +
            ((c = c % 62) > 35 ? (c+29).chr : c.to_s(36))
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
      end
      
      # sort by encoding
      sort! { |word1, word2| word1.index - word2.index }
      
      self
    end
    
    def exec(script)
      return script if size.zero?
      script.gsub(value_of) { |word| get(word).replacement }
    end
    
    def to_s
      words = @keys.join("|").gsub(/\|{2,}/, "|").gsub(/^\|+|\|+$/, "\\x0")
      "\\b(#{words})\\b"
    end
    
    def value_of
      flag = @ignore_case ? Regexp::IGNORECASE : nil
      Regexp.new(self.to_s, flag)
    end
    
    class Item
      attr_accessor :word, :count, :encoded, :replacement, :index
      
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

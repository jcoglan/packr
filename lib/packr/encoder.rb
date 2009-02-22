class Packr
  class Encoder
    
    def initialize(pattern = nil, encoder = nil, ignore = nil)
      @parser = Parser.new(ignore)
      @parser.put(pattern, "") if pattern
      @encoder = encoder
    end
    
    def search(script)
      words = Words.new
      @parser.put_at(-1, lambda { |word, *args|
        words.add(word)
      })
      @parser.exec(script)
      words
    end
    
    def encode(script)
      words = search(script)
      words.sort!
      index = 0
      words.each do |word, key|
        word.encoded = @encoder.call(index)
        index += 1
      end
      @parser.put_at(-1, lambda { |word, *args|
        words.get(word).encoded
      })
      @parser.exec(script)
    end
    
  end
end


class Packr
  class Base62 < Words
    
    def exec(script = nil, pattern = nil)
      script.scan(pattern).each { |word| add(word) } if script
      
      return script if size.zero?
      
      sort!
      
      encoded = Collection.new({}) # a dictionary of base62 -> base10
      size.times { |i| encoded.put(ENCODE.call(i), i) }
      
      replacement = lambda { |word| get(word).replacement }
      
      index, letter, s = 0, 0, size
      each do |word, key|
        letter += 62 + s if index == 62
        if word.to_s[0].chr == "@"
          begin
            c = Packr.encode52(letter)
            letter += 1
          end while script =~ Regexp.new("[^\\w$.]" + c + "[^\\w$:]")
          if index < 62
            w = add(c)
            w.count += w.count - 1
          end
          word.count = 0
          word.index = s + 1
          def word.to_s; ""; end
          word.replacement = c
        end
        index += 1
      end
      
      script = script.gsub(SHRUNK, &replacement)
      
      sort!
      
      index = 0
      each do |word, key|
        next if word.index == 1.0/0.0
        if encoded.has?(word)
          word.index = encoded.get(word)
          def word.to_s; ""; end
        else
          index += 1 while has?(ENCODE.call(index))
          word.index = index
          index += 1
          if word.count == 1
            def word.to_s; ""; end
          end
        end
        word.replacement = ENCODE.call(word.index)
        if word.replacement.length == word.to_s.length
          def word.to_s; ""; end
        end
      end
      
      # sort by encoding
      sort! { |word1, word2| word1.index - word2.index }
      
      # trim unencoded words
      @keys = @keys[0..( get_key_words.split("|").length )]
      
      script.gsub(Regexp.new(to_s), &replacement)
    end
    
    def get_decoder
      # returns a pattern used for fast decoding of the packed script
      trim = RegexpGroup.new(
        "(\\d)(\\|\\d)+\\|(\\d)" => "\\1-\\3",
        "([a-z])(\\|[a-z])+\\|([a-z])" => "\\1-\\3",
        "([A-Z])(\\|[A-Z])+\\|([A-Z])" => "\\1-\\3",
        "\\|" => ""
      )
      pattern = trim.exec(@keys.map { |key|
        word = get(key)
        word.to_s.empty? ? "" : word.replacement
      }[0...62].join("|"))
      
      return "^$" if pattern.empty?
      
      pattern = "[#{pattern}]"
      
      if size > 62
        pattern = "(#{pattern}|"
        c = ENCODE.call(size)[0].chr
        if c > "9"
          pattern += "[\\\\d"
          if c >= "a"
            pattern += "a"
            if c >= "z"
              pattern += "-z"
              if c >= "A"
                pattern += "A"
                pattern += "-#{c}" if c > "A"
              end
            elsif c == "b"
              pattern += "-#{c}"
            end
          end
          pattern += "]"
        elsif c == "9"
          pattern += "\\\\d"
        elsif c == "2"
          pattern += "[12]"
        elsif c == "1"
          pattern += "1"
        else
          pattern += "[1-#{c}]"
        end
        
        pattern += "\\\\w)"
      end
      pattern
    end
    
    def get_key_words
      @keys.map { |word| get(word).to_s }.join("|").gsub(/\|+$/, "")
    end
    
    def to_s
      words = @keys.map { |word| get(word).to_s }.join("|").gsub(/\|{2,}/, "|").gsub(/^\|+|\|+$/, "")
      words = "\\x0" if words == ""
      "\\b(#{words})\\b"
    end
    
    class Item < Words::Item
      attr_accessor :encoded, :index
      
      def initialize(*args)
        super
        @encoded = ""
        @index = -1
      end
    end
    
  end
end

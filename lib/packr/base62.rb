class Packr
  class Base62 < Encoder
    
    WORDS    = /\b[\da-zA-Z]\b|\w{2,}/
  
    ENCODE10 = "String"
    ENCODE36 = "function(c){return c.toString(36)}"
    ENCODE62 = "function(c){return(c<62?'':e(parseInt(c/62)))+((c=c%62)>35?String.fromCharCode(c+29):c.toString(36))}"
    
    UNPACK = lambda do |p,a,c,k,e,r|
      "eval(function(p,a,c,k,e,r){e=#{e};if('0'.replace(0,e)==0){while(c--)r[e(c)]=k[c];" +
          "k=[function(e){return r[e]||e}];e=function(){return'#{r}'};c=1};while(c--)if(k[c])p=p." +
          "replace(new RegExp('\\\\b'+e(c)+'\\\\b','g'),k[c]);return p}('#{p}',#{a},#{c},'#{k}'.split('|'),0,{}))"
    end
    
    def encode(script)
      words = search(script)
      words.sort!
      
      encoded = Collection.new # a dictionary of base62 -> base10
      words.size.times { |i| encoded.put(Packr.encode62(i), i) }
      
      replacement = lambda { |word| words.get(word).replacement }
      
      index = 0
      words.each do |word, key|
        if encoded.has?(word)
          word.index = encoded.get(word)
          def word.to_s; ""; end
        else
          index += 1 while words.has?(Packr.encode62(index))
          word.index = index
          index += 1
          if word.count == 1
            def word.to_s; ""; end
          end
        end
        word.replacement = Packr.encode62(word.index)
        if word.replacement.length == word.to_s.length
          def word.to_s; ""; end
        end
      end
      
      # sort by encoding
      words.sort! { |word1, word2| word1.index - word2.index }
      
      # trim unencoded words
      words = words.slice(0, get_key_words(words).split("|").length)
      
      script = script.gsub(get_pattern(words), &replacement)
      
      # build the packed script
      
      p = escape(script)
      a = "[]"
      c = get_count(words)
      k = get_key_words(words)
      e = get_encoder(words)
      d = get_decoder(words)
      
      # the whole thing
      UNPACK.call(p,a,c,k,e,d)
    end
    
    def search(script)
      words = Words.new
      script.scan(WORDS).each { |word| words.add(word) }
      words
    end
    
    def escape(script)
      # Single quotes wrap the final string so escape them.
      # Also, escape new lines (required by conditional comments).
      script.gsub(/([\\'])/) { |match| "\\#{$1}" }.gsub(/[\r\n]+/, "\\n")
    end
    
    def get_count(words)
      size = words.size
      size.zero? ? 1 : size
    end
    
    def get_decoder(words)
      # returns a pattern used for fast decoding of the packed script
      trim = RegexpGroup.new.
        put("(\\d)(\\|\\d)+\\|(\\d)", "\\1-\\3").
        put("([a-z])(\\|[a-z])+\\|([a-z])", "\\1-\\3").
        put("([A-Z])(\\|[A-Z])+\\|([A-Z])", "\\1-\\3").
        put("\\|", "")
      
      pattern = trim.exec(words.map { |word, key|
        word.to_s.empty? ? "" : word.replacement
      }[0...62].join("|"))
      
      return "^$" if pattern.empty?
      
      pattern = "[#{pattern}]"
      
      size = words.size
      if size > 62
        pattern = "(#{pattern}|"
        c = Packr.encode62(size)[0].chr
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
    
    def get_encoder(words)
      c = words.size
      self.class.const_get("ENCODE#{c > 10 ? (c > 36 ? 62 : 36) : 10}")
    end
    
    def get_key_words(words)
      words.map { |word, key| word.to_s }.join("|").gsub(/\|+$/, "")
    end
    
    def get_pattern(words)
      words = words.map { |word, key| word.to_s }.join("|").gsub(/\|{2,}/, "|").gsub(/^\|+|\|+$/, "")
      words = "\\x0" if words == ""
      string = "\\b(#{words})\\b"
      %r{#{string}}
    end
        
  end
end


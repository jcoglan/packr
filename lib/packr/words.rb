class Packr
  class Words < RegexpGroup
    
    def initialize(script = nil, pattern = nil)
      super({})
      script.scan(pattern).each { |word| add(word) } if script
    end
    
    def add(word)
      super unless has?(word)
      word = get(word)
      word.count = word.count + 1
      word
    end
    
    def encode!(&encoder)
      sort!
      index = 0
      each { |word, key| word.replacement = encoder.call(index); index += 1 }
      self
    end
    
    def sort!(&sorter)
      return super if block_given?
      super do |word1, word2|
        # sort by frequency
        count = word2.count - word1.count
        length = word2.length - word1.length
        count.nonzero? ? count : (length.nonzero? ? length : 0)
      end
    end
    
    class Item < RegexpGroup::Item
      attr_accessor :count
      
      def initialize(*args)
        super
        @count = 0
      end
    end
    
  end
end

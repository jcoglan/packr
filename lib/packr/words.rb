class Packr
  class Words < Collection
    
    def add(word)
      super unless has?(word)
      word = get(word)
      word.index = size if word.index.zero?
      word.count = word.count + 1
      word
    end
    
    def sort!(&sorter)
      return super if block_given?
      super do |word1, word2|
        # sort by frequency
        count = word2.count - word1.count
        index = word1.index - word2.index
        count.nonzero? ? count : (index.nonzero? ? index : 0)
      end
    end
    
    class Item
      attr_accessor :index, :count, :encoded, :replacement
      
      def initialize(word, item)
        @word = word
        @index = 0
        @count = 0
        @encoded = ""
      end
      
      def to_s
        @word
      end
    end
    
  end
end


class Packr
  class RegexpGroup < Collection
    
    IGNORE          = "\\0"
    BACK_REF        = /\\(\d+)/
    ESCAPE_CHARS    = /\\./
    ESCAPE_BRACKETS = /\(\?[:=!]|\[[^\]]+\]/
    BRACKETS        = /\(/
    LOOKUP          = /\\(\d+)/
    LOOKUP_SIMPLE   = /^\\\d+$/
    
    def initialize(values = nil, ignore_case = false)
      super(values)
      @ignore_case = !!ignore_case
    end
    
    def exec(string, override = nil)
      string = string.to_s # type-safe
      return string if @keys.empty?
      override = 0 if override == IGNORE
      string.gsub(Regexp.new(self.to_s, @ignore_case && Regexp::IGNORECASE)) do |match|
        offset, i, result = 1, 0, match
        arguments = [match] + $~.captures + [$~.begin(0), string]
        # Loop through the items.
        each do |item, key|
          nxt = offset + item.length + 1
          if arguments[offset] # do we have a result?
            replacement = override.nil? ? item.replacement : override
            case replacement
            when Proc
              result = replacement.call(*arguments[offset...nxt])
            when Numeric
              result = arguments[offset + replacement]
            else
              result = replacement
            end
          end
          offset = nxt
        end
        result
      end
    end
    
    def insert_at(index, expression, replacement)
      expression = expression.is_a?(Regexp) ? expression.source : expression.to_s
      super(index, expression, replacement)
    end
    
    def test(string)
      exec(string) != string
    end
    
    def to_s
      offset = 1
      "(" + map { |item, key|
        # Fix back references.
        expression = item.to_s.gsub(BACK_REF) { |m| "\\" + (offset + $1.to_i) }
        offset += item.length + 1
        expression
      }.join(")|(") + ")"
    end
    
    class Item
      attr_accessor :expression, :length, :replacement
      
      def initialize(expression, replacement = nil)
        @expression = expression
        
        if replacement.nil?
          replacement = IGNORE
        elsif replacement.respond_to?(:replacement)
          replacement = replacement.replacement
        elsif !replacement.is_a?(Proc)
          replacement = replacement.to_s
        end
        
        # does the pattern use sub-expressions?
        if replacement.is_a?(String) and replacement =~ LOOKUP
          # a simple lookup? (e.g. "\2")
          if replacement.gsub(/\n/, " ") =~ LOOKUP_SIMPLE
            # store the index (used for fast retrieval of matched strings)
            replacement = replacement[1..-1].to_i
          else # a complicated lookup (e.g. "Hello \2 \1")
            # build a function to do the lookup
            # Improved version by Alexei Gorkov:
            q = '"'
            replacement_string = replacement.
                gsub(/\\/, "\\\\").
                gsub(/"/, "\\x22").
                gsub(/\n/, "\\n").
                gsub(/\r/, "\\r").
                gsub(/\\(\d+)/, q + "+(args[\\1]||" + q+q + ")+" + q).
                gsub(/(['"])\1\+(.*)\+\1\1$/, '\1')
            replacement = lambda { |*args| eval(q + replacement_string + q) }
            
            # My old crappy version:
            # q = (replacement.gsub(/\\./, "") =~ /'/) ? '"' : "'"
            # replacement = replacement.gsub(/\r/, "\\r").gsub(/\\(\d+)/,
            #     q + "+(args[\\1]||" + q+q + ")+" + q)
            # replacement_string = q + replacement.gsub(/(['"])\1\+(.*)\+\1\1$/, '\1') + q
            # replacement = lambda { |*args| eval(replacement_string) }
          end
        end
        
        @length = RegexpGroup.count(@expression)
        @replacement = replacement
      end
      
      def to_s
        @expression.respond_to?(:source) ? @expression.source : @expression.to_s
      end
    end
    
    def self.count(expression)
      # Count the number of sub-expressions in a Regexp/RegexpGroup::Item.
      expression = expression.to_s.gsub(ESCAPE_CHARS, "").gsub(ESCAPE_BRACKETS, "")
      expression.scan(BRACKETS).length
    end
    
  end
end


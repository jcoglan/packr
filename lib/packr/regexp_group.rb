class Packr
  class RegexpGroup < Collection
    
    IGNORE          = "\\0"
    BACK_REF        = /\\(\d+)/
    ESCAPE_CHARS    = /\\./
    ESCAPE_BRACKETS = /\(\?[:=!]|\[[^\]]+\]/
    BRACKETS        = /\(/
    LOOKUP          = /\\(\d+)/
    LOOKUP_SIMPLE   = /^\\\d+$/
    
    def initialize(values, flags = nil)#
      super(values)
      if flags.is_a?(String)
        @ignore_case = !!(flags =~ /i/)
      end
    end
    
    def exec(string, &replacement)
      flag = @ignore_case ? Regexp::IGNORECASE : nil
      string = string.to_s
      
      replacement ||= lambda do |match|
        return "" if match.nil?
        arguments = [match] + $~.captures + [$~.begin(0), string]
        offset, result = 1, ""
        @values.each do |key, item|
          nxt = offset + item.length + 1
          if arguments[offset] # do we have a result?
            rep = item.replacement
            if rep.is_a?(Proc)
              args = arguments[offset...nxt]
              result = rep.call *arguments[offset...nxt]
            else
              result = rep.is_a?(Numeric) ? arguments[offset + rep] : rep.to_s
            end
          end
          offset = nxt
        end
        result
      end
      
      regexp = Regexp.new(self.to_s, flag)
      replacement.is_a?(Proc) ? string.gsub(regexp, &replacement) :
          string.gsub(regexp, replacement.to_s)
    end
    
    def insert_at(index, expression, replacement)
      expression = expression.is_a?(Regexp) ? expression.source : expression.to_s
      super(index, expression, replacement)
    end
    
    def test(string)
      exec(string) != string
    end
    
    def to_s
      length = 0
      "(" + @values.map { |key, item|
        # Fix back references.
        ref = item.to_s.gsub(BACK_REF) { |m| "\\" + (1 + $1.to_i + length).to_s }
        length += item.length + 1
        ref
      }.join(")|(") + ")"
    end
    
    class Item
      attr_accessor :expression, :length, :replacement
      
      def initialize(expression, replacement)
        @expression = expression.respond_to?(:source) ? expression.source : expression.to_s
        
        if replacement.is_a?(Numeric)
          replacement = "\\" + replacement.to_s
        elsif replacement.nil?
          replacement = ""
        end
        
        # does the pattern use sub-expressions?
        if replacement.is_a?(String) and replacement =~ LOOKUP
          # a simple lookup? (e.g. "\2")
          if replacement.gsub(/\n/, " ") =~ LOOKUP_SIMPLE
            # store the index (used for fast retrieval of matched strings)
            replacement = replacement[1..-1].to_i
          else # a complicated lookup (e.g. "Hello \2 \1")
            # build a function to do the lookup
            q = (replacement.gsub(/\\./, "") =~ /'/) ? '"' : "'"
            replacement = replacement.gsub(/\r/, "\\r").gsub(/\\(\d+)/,
                q + "+(args[\\1]||" + q+q + ")+" + q)
            replacement_string = q + replacement.gsub(/(['"])\1\+(.*)\+\1\1$/, '\1') + q
            replacement = lambda { |*args| eval(replacement_string) }
          end
        end
        
        @length = RegexpGroup.count(@expression)
        @replacement = replacement
      end
      
      def to_s
        @expression
      end
    end
    
    def self.count(expression)
      # Count the number of sub-expressions in a Regexp/RegexpGroup::Item.
      expression = expression.to_s.gsub(ESCAPE_CHARS, "").gsub(ESCAPE_BRACKETS, "")
      expression.scan(BRACKETS).length
    end
    
  end
end

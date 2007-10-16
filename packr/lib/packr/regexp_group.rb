class Packr
  class RegexpGroup
    
    attr_accessor :values
    
    IGNORE = "\\0"
    BACK_REF = /\\(\d+)/
    ESCAPE_CHARS = /\\./
    ESCAPE_BRACKETS = /\(\?[:=!]|\[[^\]]+\]/
    BRACKETS = /\(/
    KEYS = "~"
    
    def initialize(values, flags = nil)
      @values = []
      values.each { |key, value| @values << Item.new(key, value) }
      if flags && flags.is_a(String)
        @ignore_case = !!(flags =~ /i/)
      end
    end
    
    def union(*args)
      values = {}
      @values.each { |item| values[item.expression] = item.replacement }
      args.each do |arg|
        arg.values.each { |item| values[item.expression] = item.replacement }
      end
      self.class.new(values)
    end
    
    def exec(string, replacement = nil)
      string = string.to_s
      regexp, n = value_of, self.class.count(to_s)
      scanner, indexes = StringScanner.new(string), []
      indexes << scanner.pointer while scanner.scan_until(regexp)
      
      replacement ||= lambda do |match|
        return "" if match.nil?
        arguments = [match] + (1..n).map { |i| eval("$#{i}") } + [indexes.shift - match.length, string]
        offset, result = 1, ""
        @values.each do |item|
          nxt = offset + item.length + 1
          if arguments[offset] # do we have a result?
            rep = item.replacement
            if rep =~ Item::PROC_REGEXP
              rep = rep.gsub(Item::PROC_REGEXP, "")
              args = arguments[offset...nxt]
              index = arguments[-2]
              proc = lambda { |*args| eval(rep) }
              result = proc.call *(args + [index, string])
            else
              result = rep.is_a?(Numeric) ? arguments[offset + rep] : rep.to_s
            end
          end
          offset = nxt
        end
        result
      end
      
      replacement.is_a?(Proc) ? string.gsub(regexp, &replacement) :
          string.gsub(regexp, replacement.to_s)
    end
    
    def test(string)
      exec(string) != string
    end
    
    def to_s
      length = 0
      "(" + @values.map { |item|
        # Fix back references.
        ref = item.to_s.gsub(BACK_REF) { |m| "\\" + (1 + $1.to_i + length).to_s }
        length += item.length + 1
        ref
      }.join(")|(") + ")"
    end
    
    def value_of(type = nil)
      return self if type == Object
      flag = @ignore_case ? Regexp::IGNORECASE : nil
      Regexp.new(self.to_s, flag)
    end
    
    class Item
      PROC_REGEXP = /^---IM_A_PROC---/
      attr_accessor :expression, :length, :replacement
      
      def initialize(expression, replacement)
        @expression = expression.is_a?(Regexp) ? expression.source : expression.to_s
        
        if replacement.is_a?(Numeric)
          replacement = "\\" + replacement.to_s
        elsif replacement.nil?
          replacement = ""
        end
        
        # does the pattern use sub-expressions?
        if replacement.is_a?(String) and replacement =~ /\\(\d+)/
          # a simple lookup? (e.g. "\2")
          if replacement.gsub(/\n/, " ") =~ /^\\\d+$/
            # store the index (used for fast retrieval of matched strings)
            replacement = replacement[1..-1].to_i
          else # a complicated lookup (e.g. "Hello \2 \1")
            # build a function to do the lookup
            q = (replacement.gsub(/\\./, "") =~ /'/) ? '"' : "'"
            replacement = replacement.gsub(/\r/, "\\r").gsub(/\\(\d+)/,
                q + "+(args[\\1]||" + q+q + ")+" + q)
            replacement = q + replacement.gsub(/(['"])\1\+(.*)\+\1\1$/, '\1') + q
            replacement = "#{PROC_REGEXP.source[1..-1]}#{replacement}"
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
      expression = expression.to_s.gsub(ESCAPE_CHARS, "").gsub(ESCAPE_BRACKETS, "")
      expression.scan(BRACKETS).length
    end
    
  end
end

class Packr
  class SourceMap
    
    module Ext
      attr_accessor :source_map
    end
    
    IDENTIFIER = /[a-zA-Z_$][\w\$]*/
    
    def initialize(script, options = {})
      script, lines = normalize(script)
      
      @source_script = script
      @source_lines  = lines
      @source_files  = options[:source_files]
      
      @tokens = tokenize(@source_script)
    end
    
    def update(script)
      return unless @source_files
      
      script, lines = normalize(script)
      @segments = []
      tokenize(script).each_with_index do |token, i|
        line, column = coords(token, lines)
        
        source_token = @tokens[i]
        source_line, source_column = coords(source_token, @source_lines)
        
        @segments << {
          :line     => line,
          :column   => column,
          :mapping  => {
            :line   => source_line,
            :column => source_column,
            :source => sources.first,
            :name   => source_token[:name]
          }
        }
      end
    end
    
    def names
      @names ||= @tokens.map { |n| n[:name] }.uniq.sort
    end
    
    def sources
      @sources ||= @source_files.keys.sort
    end
    
    def ==(other)
      return false unless Hash === other
      return false unless names == other[:names]
      return false unless sources == other[:sources]
      return false unless @segments == other[:segments]
      true
    end
    
  private
    
    def normalize(script)
      script = script.gsub(/\r\n|\r|\n/, "\n")
      lines  = script.split(/\n/).map { |line| "#{line}\n" }
      [script, lines]
    end
    
    def tokenize(script)
      tokens = []
      scanner = StringScanner.new(script)
      
      while scanner.scan_until(IDENTIFIER)
        name = scanner.matched
        offset = scanner.pointer - name.size
        tokens << {:name   => name, :offset => offset}
      end
      tokens
    end
    
    def coords(token, lines)
      offset = token[:offset]
      line = 0
      while lines[0..line].inject(0) { |s,l| s + l.size } <= offset
        line += 1
      end
      column = offset - lines[0...line].inject(0) { |s,l| s + l.size }
      [line, column]
    end
    
  end
end

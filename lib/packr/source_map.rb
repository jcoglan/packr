class Packr
  class SourceMap
    
    module Ext
      attr_accessor :source_map
    end
    
    IDENTIFIER = /[a-zA-Z_$][\w\$]*/
    
    def initialize(script, options = {})
      @source_script = script
      @source_files  = options[:source_files]
      
      return unless @source_files
      
      @tokens = tokenize(@source_script)
    end
    
    def update(script)
      return unless @source_files
      
      @segments = []
      tokenize(script).each_with_index do |token, i|
        source_token = @tokens[i]
        
        @segments << {
          :line     => token[:line],
          :column   => token[:column],
          :mapping  => {
            :line   => source_token[:line],
            :column => source_token[:column],
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
    
    def tokenize(script)
      script, boundaries = normalize(script)
      tokens = []
      scanner = StringScanner.new(script)
      
      while scanner.scan_until(IDENTIFIER)
        name = scanner.matched
        offset = scanner.pointer - name.size
        line, column = coords(offset, boundaries)
        tokens << {
          :name   => name,
          :offset => offset,
          :line   => line,
          :column => column
        }
      end
      tokens
    end
    
    def normalize(script)
      script = script.gsub(/\r\n|\r|\n/, "\n")
      lines = script.split(/\n/).map { |line| "#{line}\n" }
      boundaries = lines.inject([0]) { |a,l| a + [a.last + l.size] }
      [script, boundaries]
    end
    
    def coords(offset, boundaries)
      line   = boundaries.index { |b| b > offset } - 1
      column = offset - boundaries[line]
      [line, column]
    end
    
  end
end

class Packr
  class SourceMap
    
    module Ext
      attr_accessor :source_map
    end
    
    IDENTIFIER = /[a-zA-Z_$][\w\$]*/
    attr_reader :generated_file
    
    def initialize(script, options = {})
      @source_script  = script
      @source_files   = options[:source_files]
      @generated_file = options[:generated_file]
      
      return unless @source_files
      
      @tokens = tokenize(@source_script)
    end
    
    def update(script)
      return unless @source_files
      
      @segments = []
      @names = SortedSet.new
      
      tokenize(script).each_with_index do |token, i|
        source_token = @tokens[i]
        
        if source_token[:name] != token[:name]
          @names.add(source_token[:name])
          name = source_token[:name]
        else
          name = nil
        end
        
        @segments << {
          :line     => token[:line],
          :column   => token[:column],
          :mapping  => {
            :line   => source_token[:line],
            :column => source_token[:column],
            :source => sources.first,
            :name   => name
          }
        }
      end
      
      if @generated_file
        script << "\n//@ sourceMappingURL=#{@generated_file}.map"
      end
    end
    
    def names
      @names_array ||= @names.to_a
    end
    
    def sources
      @sources ||= @source_files.keys.sort
    end
    
    def segments
      @segments_objects ||= @segments.map { |s| Segment.new(s) }
    end
    
    def ==(other)
      return false unless Hash === other
      return false unless names == other[:names]
      return false unless sources == other[:sources]
      return false unless @segments == other[:segments]
      true
    end
    
    def to_json
      V3Encoder.new(self).serialize
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
    
    class Segment
      def initialize(data)
        @data = data
      end
      
      def source_line
        @data[:mapping][:line]
      end
      
      def source_column
        @data[:mapping][:column]
      end
      
      def source_file
        @data[:mapping][:source]
      end
      
      def source_name
        @data[:mapping][:name]
      end
      
      def generated_line
        @data[:line]
      end
      
      def generated_column
        @data[:column]
      end
    end
    
    class V3Encoder
      BASE64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      BASE64 << BASE64.downcase
      BASE64 << '0123456789+/'
      
      SHIFT = 5
      MASK  = 2**SHIFT
      BASE  = MASK - 1
      
      TEMPLATE = <<JSON
{
"version":3,
"file":<%= @source_map.generated_file.inspect %>,
"sourceRoot":"",
"sources":<%= @source_map.sources.inspect %>,
"names":<%= @source_map.names.inspect %>,
"mappings":"<%= mappings %>"
}
JSON
      def initialize(source_map)
        @source_map = source_map
      end
      
      def serialize
        ERB.new(TEMPLATE).result(binding)
      end
      
      def mappings
        max_line = @source_map.segments.map { |s| s.generated_line }.max
        
        lines = (0..max_line).map do |line_no|
          segments = @source_map.segments.
                     select { |s| s.generated_line == line_no }.
                     sort_by { |l| l.generated_column }
          
          previous_segment = nil
          previous_name    = nil
          strings          = []
          
          segments.each do |segment|
            strings << serialize_segment(segment, previous_segment, previous_name)
            previous_segment = segment
            previous_name = segment.source_name || previous_name
          end
          
          strings.join(',') + ';'
        end
        
        lines * ''
      end
      
      def serialize_segment(segment, previous, previous_name)
        pvalues = [
          previous ? previous.generated_column : 0,
          previous ? @source_map.sources.index(previous.source_file) : 0,
          previous ? previous.source_line : 0,
          previous ? previous.source_column : 0,
          previous_name ? @source_map.names.index(previous_name) : 0
        ]
        numbers = [
          segment.generated_column - pvalues[0],
          @source_map.sources.index(segment.source_file) - pvalues[1],
          segment.source_line - pvalues[2],
          segment.source_column - pvalues[3]
        ]
        if segment.source_name
          numbers << @source_map.names.index(segment.source_name) - pvalues[4]
        end
        numbers.map { |n| encode(n) } * ''
      end
      
    private
      
      def encode(number)
        bits = number.abs
        bits <<= 1
        bits |= 1 if number < 0
        string = ''
        while bits >= MASK
          index = (bits & BASE) | MASK
          string << BASE64[index].chr
          bits >>= SHIFT
        end
        string << BASE64[bits].chr
        string
      end
    end
    
  end
end

class Packr
  class SourceMap
    
    IDENTIFIER  = /[a-zA-Z_$][\w\$]*/
    LINE_ENDING = /\r\n|\r|\n/
    
    attr_reader :source_code, :generated_file
    
    def initialize(script, options = {})
      if options[:header]
        options[:header] += "\n" unless options[:minify] != false
        options[:header] += "\n"
      else
        options[:header] = ''
      end
      
      @source_code = script
      return if String === @source_code
      
      @generated_file = options[:output_file]
      @base_62        = options[:base62]
      @line_offset    = @base_62 ? 0 : options[:header].scan(LINE_ENDING).size
      @source_code    = ''
      @source_files   = []
      
      script.each do |section|
        @source_files << [@source_code.size, section[:source]]
        @source_code << section[:code] + "\n"
      end
      
      @source_files << [@source_code.size, nil]
      
      @tokens = tokenize(@source_code, true)
    end
    
    def enabled?
      !!@source_files
    end
    
    def remove(sections)
      return unless enabled?
      
      sections.each_with_index do |section, i|
        effect = section[2] - section[1]
        sections[(i+1)..-1].each { |moved| moved[0] += effect }
        
        range = section[0]...(section[0] + section[1])
        @tokens.delete_if { |t| range === t[:offset] }
        
        @tokens.each do |token|
          token[:offset] += effect if token[:offset] > section[0]
        end
      end
    end
    
    def update(script)
      return unless enabled?
      
      @segments = []
      @names = SortedSet.new
      
      tokenize(script, false).each_with_index do |token, i|
        source_token = @tokens[i]
        
        if source_token[:name] != token[:name]
          @names.add(source_token[:name])
          name = source_token[:name]
        else
          name = nil
        end
        
        @segments << {
          :line     => token[:line] + @line_offset,
          :column   => token[:column],
          :mapping  => {
            :source => source_token[:source],
            :line   => source_token[:line],
            :column => source_token[:column],
            :name   => name
          }
        }
      end
      
      if @generated_file and @base_62
        script << "\n//@ sourceURL=$$SOURCE_URL"
      end
    end
    
    def append_mapping_url(script)
      return '' unless enabled?
      footer = "\n//@ sourceMappingURL=#{File.basename(filename)}"
      script << footer
      footer
    end
    
    def names
      @names_array ||= @names.to_a
    end
    
    def sources
      @sources ||= @source_files.map { |pair| pair.last }.compact.sort
    end
    
    def segments
      @segments_objects ||= @segments.map { |s| Segment.new(s) }
    end
    
    def filename
      @generated_file && "#{@generated_file}.map"
    end
    
    def to_json
      V3Encoder.new(self).serialize
    end
    alias :to_s :to_json
    
    def ==(other)
      return false unless Hash === other
      return false unless names == other[:names]
      return false unless sources == other[:sources]
      return false unless @segments == other[:segments]
      true
    end
    
  private
    
    def tokenize(script, from_source)
      line_offsets = get_line_offsets(script)
      tokens = []
      scanner = StringScanner.new(script)
      
      while scanner.scan_until(IDENTIFIER)
        name   = scanner.matched
        offset = scanner.pointer - name.size
        source = @source_files.index { |p| p.first > offset } - 1
        
        source_offset = from_source ? @source_files[source].first : 0
        line, column = coords(offset, line_offsets, source_offset)
        
        tokens << {
          :name   => name,
          :offset => offset,
          :source => @source_files[source].last,
          :line   => line,
          :column => column
        }
      end
      tokens
    end
    
    def get_line_offsets(script)
      offsets = [0]
      scanner = StringScanner.new(script)
      offsets << scanner.pointer while scanner.scan_until(LINE_ENDING)
      offsets << script.size
      offsets
    end
    
    def coords(offset, line_offsets, file_offset)
      line_no = line_offsets.index { |b| b > offset } - 1
      line    = line_offsets.count { |b| b > file_offset && b <= offset }
      column  = offset - line_offsets[line_no]
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
  "version": 3,
  "file": <%= File.basename(@source_map.generated_file).inspect %>,
  "sourceRoot": "",
  "sources": <%= @source_map.sources.inspect %>,
  "names": <%= @source_map.names.inspect %>,
  "mappings": "<%= mappings %>"
}
JSON
      
      def initialize(source_map)
        @source_map = source_map
      end
      
      def serialize
        ERB.new(TEMPLATE).result(binding).strip
      end
      
      def mappings
        max_line = @source_map.segments.map { |s| s.generated_line }.max
        previous_segment = nil
        previous_name = nil
        
        (0..max_line).inject('') do |mappings, line_no|
          segments = @source_map.segments.
                     select { |s| s.generated_line == line_no }.
                     sort_by { |s| s.generated_column }
          
          previous_column = nil
          segment_strings = []
          
          segments.each do |segment|
            segment_strings << serialize_segment(segment, previous_segment, previous_column, previous_name)
            
            previous_segment = segment
            previous_column  = segment.generated_column
            previous_name    = segment.source_name || previous_name
          end
          
          mappings << segment_strings.join(',') << ';'
        end
      end
      
      def serialize_segment(segment, previous, previous_column, previous_name)
        pvalues = [
          previous_column ? previous_column : 0,
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

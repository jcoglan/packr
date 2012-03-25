class Packr
  module FileSystem
    
    def self.bundle(options)
      sources = options.keys.grep(Array).first
      output  = options[sources]
      
      sources = sources.map { |s| File.expand_path(s) }
      output  = File.expand_path(output)
      
      code    = ''
      offsets = {}
      
      sources.each do |source|
        offsets[relative_path(source, output)] = code.size
        code << File.read(source) + "\n"
      end
      
      packed = Packr.pack(code,
        :minify       => options[:minify],
        :shrink_vars  => options[:shrink_vars],
        :private      => options[:private],
        :base62       => options[:base62],
        :protect      => options[:protect],
        :header       => options[:header],
        :source_files => offsets,
        :output_file  => output
      )
      source_map = packed.source_map
      
      FileUtils.mkdir_p(File.dirname(output))
      File.open(output, 'w') { |f| f.write(packed) }
      File.open(source_map.filename, 'w') { |f| f.write(source_map.to_s) }
    end
    
    def self.relative_path(source, target)
      target_parts = target.split('/')
      source_parts = source.split('/')
      
      while target_parts.first == source_parts.first
        target_parts.shift
        source_parts.shift
      end
      
      ('../' * (target_parts.size-1)) + source_parts.join('/')
    end
    
  end
end

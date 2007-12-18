class Packr
  # This is effectively a wrapper for Hash instances - we're including it
  # to maintain similarity with the JavaScript version for easier maintainance.
  class Map
    
    HASH = "#"
    
    def initialize(values)
      @values = {}
      merge(values)
    end
    
    def copy
      self.class.new(@values)
    end
    
    def exists?(key)
      @values.has_key?("#{HASH}#{key}")
    end
    
    def fetch(key)
      @values["#{HASH}#{key}"]
    end
    
    def each(&block)
      @values.each { |key, value| block.call(value, key[1..-1]) }
    end
    
    def merge(*args)
      args.each do |values|
        values.each { |key, value| store(key, value) }
      end
      self
    end
    
    def remove(key)
      @values.delete("#{HASH}#{key}")
    end
    
    def store(key, value = nil)
      key = key.to_s.gsub(%r{^#{HASH}}, "")
      value ||= key
      # Create the new entry (or overwrite the old entry).
      @values["#{HASH}#{key}"] = value
    end
    
    def union(*values)
      copy.merge(*values)
    end
    
  end  
end

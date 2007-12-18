class Packr
  # This is effectively a wrapper for Hash instances - we're including it
  # to maintain similarity with the JavaScript version for easier maintainance.
  class Map
    
    def initialize(values)
      @values = {}
      merge(values)
    end
    
    def copy
      self.class.new(@values)
    end
    
    def exists?(key)
      @values.has_key?(key.to_s)
    end
    
    def fetch(key)
      @values[key.to_s]
    end
    
    def each(&block)
      @values.each { |key, value| block.call(value, key) }
    end
    
    def merge(*args)
      args.each do |values|
        values.each { |key, value| store(key, value) }
      end
      self
    end
    
    def remove(key)
      @values.delete(key.to_s)
    end
    
    def store(key, value = nil)
      value ||= key
      # Create the new entry (or overwrite the old entry).
      @values[key.to_s] = value
    end
    
    def union(*values)
      copy.merge(*values)
    end
    
  end  
end

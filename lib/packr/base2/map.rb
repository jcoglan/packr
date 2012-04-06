class Packr
  # This is effectively a wrapper for Hash instances - we're including it
  # to maintain similarity with the JavaScript version for easier maintainance.
  class Map
    
    def initialize(values = nil)
      @values = {}
      merge(values) unless values.nil?
    end
    
    def clear
      @values.clear
    end
    
    def copy
      self.class.new(@values)
    end
    
    def each
      @values.each { |key, value| yield(value, key) }
    end
    
    def get(key)
      @values[key.to_s]
    end
    
    def get_keys
      @values.keys
    end
    
    def get_values
      @values.values
    end
    
    def has?(key)
      @values.has_key?(key.to_s)
    end
    
    def merge(*args)
      args.each do |values|
        values = values.get_values if values.is_a?(Map)
        values.each { |key, value| put(key, value) }
      end
      self
    end
    
    def remove(key)
      @values.delete(key.to_s)
    end
    
    def put(key, value = nil)
      value ||= key
      # Create the new entry (or overwrite the old entry).
      @values[key.to_s] = value
    end
    
    def size
      @values.length
    end
    
    def union(*values)
      copy.merge(*values)
    end
    
  end  
end

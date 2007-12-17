class Packr
  # This is effectively a wrapper for Hash instances - we're including it
  # to maintain similarity with the JavaScript version for easier maintainance.
  class Map
    
    HASH    = '#'
    KEYS    = HASH + 'keys'
    VALUES  = HASH + 'values'
    
    def initialize(values)
      @keys = []
      @values = {}
      merge(values)
    end
    
    def copy
      self.class.new(@values)
    end
    
    def exists?(key)
      @values.has_key?(HASH + key.to_s)
    end
    
    def fetch(key)
      @values[HASH + key.to_s]
    end
    
    def each(&block)
      @keys.each do |key|
        block.call(fetch(key), key.to_s)
      end
    end
    
    def keys(*args)
      index, length = *args
      keys = @keys || []
      case args.length
      when 0 then return keys.dup
      when 1 then return keys[index]
      else return keys[index...length] 
      end
    end
    
    def merge(*args)
      args.each do |hash|
        hash.each { |key, value| store(key, value) }
      end
      return self
    end
    
    def remove(key)
      value = fetch(key)
      @keys.delete(key.to_s)
      @values.delete(HASH + key.to_s)
      value
    end
    
    def store(*args)
      key, value = *args
      key = key.to_s.gsub(%r{^#{HASH}}, '')
      value = key if args.length == 1
      # only store the key for a new entry
      @keys << key unless exists?(key)
      # create the new entry (or overwrite the old entry)
      @values[HASH + key] = value
    end
    
    def to_s
      @keys.to_s
    end
    
    def union(*args)
      copy.merge(*args)
    end
    
    def values(*args)
      index, length = *args
      values = @values.values || []
      case args.length
      when 0 then return values.dup
      when 1 then return values[index]
      else return values[index...length] 
      end
    end
    
  end  
end

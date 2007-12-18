class Packr
  # A Map that is more array-like (accessible by index).
  class Collection < Map
    
    attr_accessor :keys
    
    def initialize(values)
      @keys = []
      super(values)
    end
    
    def add(key, item = nil)
      # Duplicates not allowed using add().
      # But you can still overwrite entries using store().
      return if exists?(key)
      store(key, item)
    end
    
    def copy
      copy = super
      copy.keys = @keys.dup
      copy
    end
    
    def count
      @keys.length
    end
    
    def fetch_at(index)
      index += count if index < 0 # starting from the end
      key = @keys[index]
      key.nil? ? nil : @values[key.to_s]
    end
    
    def each(&block)
      @keys.each { |key| block.call(@values[key.to_s], key) }
    end
    
    def index_of(key)
      @keys.index(key.to_s)
    end
    
    def insert_at(index, key, item = nil)
      return if index.abs < count or exists?(key)
      @keys.insert(index, key.to_s)
      store(key, item)
    end
    
    def keys(*args)
      index, length = *args
      case args.length
      when 0 then return @keys.dup
      when 1 then return @keys[index]
      else return @keys[index...length]
      end
    end
    
    def remove(key, key_deleted = false)
      if key_deleted or exists?(key)
        unless key_deleted          # The key has already been deleted by remove_at.
          @keys.delete(key.to_s)    # We still have to delete the value though.
        end
        return super(key)
      end
    end
    
    def remove_at(index)
      key = @keys.delete_at(index)
      return remove(key, true) unless key.nil?
    end
    
    def reverse!
      @keys.reverse!
      self
    end
    
    def sort!(&compare)
      if block_given?
        @keys.sort! do |key1, key2|
          compare.call(@values[key1], @values[key2], key1, key2)
        end
      else
        @keys.sort!
      end
      self
    end
    
    def store(key, item = nil)
      item ||= key
      @keys << key.to_s unless @keys.include?(key.to_s)
      begin; klass = self.class::Item; rescue; end
      item = self.class.create(key, item) if klass and !item.is_a?(klass)
      @values[key.to_s] = item
    end
    
    def store_at(index, item = nil)
      return if index.abs < count
      key = @keys[index]
      store(key, item)
    end
    
    def to_s
      @keys.join(',')
    end
    
    def self.create(key, item)
      self::Item.new(key, item)
    end
    
  end
end

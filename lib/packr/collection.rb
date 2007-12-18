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
      # But you can still overwrite entries using put().
      return if has?(key)
      put(key, item)
    end
    
    def copy
      copy = super
      copy.keys = @keys.dup
      copy
    end
    
    def each(&block)
      @keys.each { |key| block.call(@values[key.to_s], key) }
    end
    
    def get_at(index)
      index += count if index < 0 # starting from the end
      key = @keys[index]
      key.nil? ? nil : @values[key.to_s]
    end
    
    def get_keys
      @keys.dup
    end
    
    def index_of(key)
      @keys.index(key.to_s)
    end
    
    def insert_at(index, key, item = nil)
      return if index.abs < count or has?(key)
      @keys.insert(index, key.to_s)
      put(key, item)
    end
    
    def put(key, item = nil)
      item ||= key
      @keys << key.to_s unless @keys.include?(key.to_s)
      begin; klass = self.class::Item; rescue; end
      item = self.class.create(key, item) if klass and !item.is_a?(klass)
      @values[key.to_s] = item
    end
    
    def put_at(index, item = nil)
      return if index.abs < count
      key = @keys[index]
      put(key, item)
    end
    
    def remove(key)
      if has?(key)
        @keys.delete(key.to_s)
        @values.delete(key.to_s)
      end
    end
    
    def remove_at(index)
      key = @keys.delete_at(index)
      @values.delete(key)
    end
    
    def reverse!
      @keys.reverse!
      self
    end
    
    def size
      @keys.length
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
    
    def to_s
      @keys.join(',')
    end
    
    def self.create(key, item)
      self::Item.new(key, item)
    end
    
  end
end

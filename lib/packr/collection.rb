class Packr
  # A Map that is more array-like (accessible by index).
  class Collection < Map
    
    KEYS = "~"
    
    attr_accessor :keys
    
    def initialize(values)
      @keys = []
      super(values)
    end
    
    def add(key, item)
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
      key.nil? ? nil : @values["#{HASH}#{key}"]
    end
    
    def each(&block)
      @keys.each { |key| block.call(@values["#{HASH}#{key}"], key) }
    end
    
    def index_of(key)
      @keys.index(key.to_s)
    end
    
    def insert_at(index, key, item)
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
          compare.call(@values["#{HASH}#{key1}"], @values["#{HASH}#{key2}"], key1, key2)
        end
      else
        @keys.sort!
      end
      self
    end
    
    def store(key, item = nil)
      key = key.to_s.gsub(%r{^#{HASH}}, "")
      item ||= key
      @keys << key unless @keys.include?(key)
      item = self.class.create(key, item) unless item.is_a?(self.class::Item)
      @values["#{HASH}#{key}"] = item
    end
    
    def store_at(index, item)
      return if index.abs < count
      key = @keys[index]
      store(key, item)
    end
    
    def to_s
      @keys.join(',')
    end
    
    class Item
      def initialize(*args); end
    end
    
    def self.create(key, item)
      self::Item.new(key, item)
    end
    
  end
end

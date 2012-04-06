class Packr
  # A Map that is more array-like (accessible by index).
  class Collection < Map
    
    attr_reader :values
    attr_writer :keys
    
    def initialize(values = nil)
      @keys = []
      super(values)
    end
    
    def add(key, item = nil)
      # Duplicates not allowed using add().
      # But you can still overwrite entries using put().
      return if has?(key)
      put(key, item)
    end
    
    def clear
      super
      @keys.clear
    end
    
    def copy
      copy = super
      copy.keys = @keys.dup
      copy
    end
    
    def each
      @keys.each { |key| yield(get(key), key) }
    end
    
    def get_at(index)
      index += @keys.length if index < 0 # starting from the end
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
      return if @keys[index].nil?
      @keys.insert(index, key.to_s)
      @values[key.to_s] = nil # placeholder
      put(key, item)
    end
    
    def item(key_or_index)
      __send__(key_or_index.is_a?(Numeric) ? :get_at : :get, key_or_index)
    end
    
    def map
      @keys.map { |key| yield(get(key), key) }
    end
    
    def merge(*args)
      args.each do |values|
        values.is_a?(Collection) ?
            values.each { |item, key| put(key, item) } :
            super(values)
      end
      self
    end
    
    # TODO update this method
    def put(key, item = nil)
      item ||= key
      @keys << key.to_s unless has?(key.to_s)
      begin; klass = self.class::Item; rescue; end
      item = self.class.create(key, item) if klass and !item.is_a?(klass)
      @values[key.to_s] = item
      self
    end
    
    def put_at(index, item = nil)
      key = @keys[index]
      return if key.nil?
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
    
    def slice(start, fin)
      sliced = copy
      if start
        keys, removed = @keys, @keys
        sliced.keys = @keys[start...fin]
        if sliced.size.nonzero?
          removed = removed[0...start]
          removed = removed + keys[fin..-1] if fin
        end
        removed.each do |remov|
          sliced.values.delete(remov)
        end
      end
      sliced
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
      "(#{@keys.join(',')})"
    end
    
    def self.create(key, item)
      begin; klass = self::Item; rescue; end
      klass ? klass.new(key, item) : item
    end
    
  end
end

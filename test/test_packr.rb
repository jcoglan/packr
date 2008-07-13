require 'test/unit'
require 'packr'

class PackrTest < Test::Unit::TestCase
  
  def setup
    dir = File.dirname(__FILE__) + '/assets'
    @data = {
      :default => [{
        :source => File.read("#{dir}/src/controls.js"),
        :packed => File.read("#{dir}/packed/controls.js"),
        :output => "#{dir}/test/controls.js"
      }],
      :shrink => [{
        :source => File.read("#{dir}/src/dragdrop.js"),
        :packed => File.read("#{dir}/packed/dragdrop.js"),
        :output => "#{dir}/test/dragdrop.js"
      },
      { :source => File.read("#{dir}/src/prototype.js"),
        :packed => File.read("#{dir}/packed/prototype_shrunk.js"),
        :output => "#{dir}/test/prototype_shrunk.js"
      }],
      :base62 => [{
        :source => File.read("#{dir}/src/effects.js"),
        :packed => File.read("#{dir}/packed/effects.js"),
        :output => "#{dir}/test/effects.js"
      }],
      :base62_shrink => [{
        :source => File.read("#{dir}/src/prototype.js"),
        :packed => File.read("#{dir}/packed/prototype.js"),
        :output => "#{dir}/test/prototype.js"
      }]
    }
  end
  
  def test_basic_packing
    actual = Packr.pack(@data[:default][0][:source])
    File.open(@data[:default][0][:output], 'wb') { |f| f.write(actual) }
    assert_equal @data[:default][0][:packed], actual
  end
  
  def test_shrink_packing
    actual1 = Packr.pack(@data[:shrink][0][:source], :shrink_vars => true)
    File.open(@data[:shrink][0][:output], 'wb') { |f| f.write(actual1) }
    actual2 = Packr.pack(@data[:shrink][1][:source], :shrink_vars => true)
    File.open(@data[:shrink][1][:output], 'wb') { |f| f.write(actual2) }
    assert_equal @data[:shrink][0][:packed], actual1
    assert_equal @data[:shrink][1][:packed], actual2
  end
  
  def test_base62_packing
    expected = @data[:base62][0][:packed]
    actual = Packr.pack(@data[:base62][0][:source], :base62 => true)
    File.open(@data[:base62][0][:output], 'wb') { |f| f.write(actual) }
    assert_equal expected.size, actual.size
    expected_words = expected.scan(/'[\w\|]+'/)[-2].gsub(/^'(.*?)'$/, '\1').split("|").sort
    actual_words = actual.scan(/'[\w\|]+'/)[-2].gsub(/^'(.*?)'$/, '\1').split("|").sort
    assert expected_words.eql?(actual_words)
  end
  
  def test_base62_and_shrink_packing
    expected = @data[:base62_shrink][0][:packed]
    actual = Packr.pack(@data[:base62_shrink][0][:source], :base62 => true, :shrink_vars => true)
    File.open(@data[:base62_shrink][0][:output], 'wb') { |f| f.write(actual) }
    assert_equal expected.size, actual.size
    expected_words = expected.scan(/'[\w\|]+'/)[-2].gsub(/^'(.*?)'$/, '\1').split("|").sort
    actual_words = actual.scan(/'[\w\|]+'/)[-2].gsub(/^'(.*?)'$/, '\1').split("|").sort
    assert expected_words.eql?(actual_words)
  end
  
  def test_private_variable_packing
    script = "var _KEYS = true, _MY_VARS = []; (function() { var foo = _KEYS;  _MY_VARS.push({_KEYS: _KEYS}); var bar = 'something _KEYS  _MY_VARS' })();"
    expected = "var _0=true,_1=[];(function(){var a=_0;_1.push({_0:_0});var b='something _0  _1'})();"
    assert_equal expected, Packr.pack(script, :shrink_vars => true, :private => true)
  end
  
  def test_protected_names
    expected = /var func\=function\([a-z],[a-z],\$super,[a-z]\)\{return \$super\([a-z]\+[a-z]\)\}/
    actual = Packr.pack('var func = function(foo, bar, $super, baz) { return $super( foo + baz ); }', :shrink_vars => true)
    assert_match expected, actual
    packr = Packr.new
    packr.protect_vars *(%w(other) + [:method, :names] + ['some random stuff', 24])
    expected = /var func\=function\([a-z],other,\$super,[a-z],names\)\{return \$super\(\)\(other\.apply\(names,[a-z]\)\)\}/
    actual = packr.pack('var func = function(foo, other, $super, bar, names) { return $super()(other.apply(names, foo)); }', :shrink_vars => true)
    assert_match expected, actual
  end
  
  def test_object_properties
    expected = 'function(a,b){this.queue.push({func:a,args:b})}'
    actual = Packr.pack('function(method, args) { this.queue.push({func: method, args: args}); }', :shrink_vars => true)
    assert_equal expected, actual
  end
  
  def test_holly
    return unless File.file?(File.dirname(__FILE__) + '/../../holly/lib/holly.rb')
    script = "// @require prototype\n// @load style.css\nfunction something(foo, bar) { };"
    expected = "// @require /javascripts/prototype.js\n// @load /stylesheets/style.css\nfunction something(a,b){};"
    actual = Packr.pack(script, :shrink_vars => true, :holly => true)
    assert_equal expected, actual
    assert_equal "function something(a,b){};", Packr.pack(script, :shrink_vars => true)
  end
end

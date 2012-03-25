require 'rubygems'
require 'bundler/setup'
require 'test/unit'
require 'fileutils'

require File.expand_path('../../lib/packr', __FILE__)

class PackrTest < Test::Unit::TestCase
  
  def setup
    dir = File.dirname(__FILE__) + '/assets'
    FileUtils.mkdir_p(dir + '/test')
    @data = {
      :default => [{
        :source => File.read("#{dir}/src/controls.js"),
        :packed => File.read("#{dir}/packed/controls.js").gsub(/\r?\n?/, ''),
        :output => "#{dir}/test/controls.js"
      }],
      :shrink => [{
        :source => File.read("#{dir}/src/dragdrop.js"),
        :packed => File.read("#{dir}/packed/dragdrop.js").gsub(/\r?\n?/, ''),
        :output => "#{dir}/test/dragdrop.js"
      },
      { :source => File.read("#{dir}/src/prototype.js"),
        :packed => File.read("#{dir}/packed/prototype_shrunk.js").gsub(/\r?\n?/, ''),
        :output => "#{dir}/test/prototype_shrunk.js"
      }],
      :base62 => [{
        :source => File.read("#{dir}/src/effects.js"),
        :packed => File.read("#{dir}/packed/effects.js").gsub(/\r?\n?/, ''),
        :output => "#{dir}/test/effects.js"
      }],
      :base62_shrink => [{
        :source => File.read("#{dir}/src/prototype.js"),
        :packed => File.read("#{dir}/packed/prototype.js").gsub(/\r?\n?/, ''),
        :output => "#{dir}/test/prototype.js"
      }],
      :concat_bug => [{
        :source => File.read("#{dir}/src/selector.js"),
        :packed => File.read("#{dir}/packed/selector.js").gsub(/\r?\n?/, ''),
        :output => "#{dir}/test/selector.js"
      }],
      :conditional_comments => [{
        :source => File.read("#{dir}/src/domready.js"),
        :packed => File.read("#{dir}/packed/domready.js").gsub(/\r?\n?/, ''),
        :output => "#{dir}/test/domready.js"
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
    expected = 'var func=function(a,d,c,b){return c(a+b)}'
    actual = Packr.pack('var func = function(foo, bar, $super, baz) { return $super( foo + baz ); }', :shrink_vars => true)
    assert_equal expected.size, actual.size
    expected = 'var func=function(a,other,b,c,names){return b()(other.apply(names,a))}'
    actual = Packr.pack('var func = function(foo, other, $super, bar, names) { return $super()(other.apply(names, foo)); }', :shrink_vars => true, :protect => (%w(other) + [:method, :names] + ['some random stuff', 24]))
    assert_equal expected.size, actual.size
    expected = 'function(a,$super){}'
    assert_equal expected.size, Packr.pack('function(name, $super) { /* something */ }', :shrink_vars => true, :protect => %w($super)).size
  end
  
  def test_dollar_prefix
    expected = 'function(a,b){var c;happening()}'
    actual = Packr.pack('function(something, $nothing) { var is; happening(); }', :shrink_vars => true)
    assert_equal expected, actual
  end
  
  def test_object_properties
    expected = 'function(a,b){this.queue.push({func:a,args:b})}'
    actual = Packr.pack('function(method, args) { this.queue.push({func: method, args: args}); }', :shrink_vars => true)
    assert_equal expected, actual
  end
  
  def test_concat
    actual = Packr.pack(@data[:concat_bug][0][:source], :shrink_vars => true)
    File.open(@data[:concat_bug][0][:output], 'wb') { |f| f.write(actual) }
    assert_equal @data[:concat_bug][0][:packed], actual
    
    code = 'var a={"+":function(){}}'
    assert_equal Packr.pack(code), code
    
    code = "var a={'+':function(){}}"
    assert_equal Packr.pack(code), code
    
    code = 'var b="something"+"else",a={"+":function(){return"nothing"+"at all"}}'
    expected = 'var b="somethingelse",a={"+":function(){return"nothingat all"}}'
    actual = Packr.pack(code)
    assert_equal expected, actual
    
    code = "var b='something'+'else',a={'+':function(){return'nothing'+'at all'}}"
    expected = "var b='somethingelse',a={'+':function(){return'nothingat all'}}"
    actual = Packr.pack(code)
    assert_equal expected, actual
  end
  
  def test_conditional_comments
    expected = @data[:conditional_comments][0][:packed]
    actual = Packr.pack(@data[:conditional_comments][0][:source], :shrink_vars => true)
    File.open(@data[:conditional_comments][0][:output], 'wb') { |f| f.write(actual) }
    assert_equal expected, actual
  end
  
  def test_source_maps
    code = <<JS
(function(config) {
var foo = "something";
  for (var i = 0; i < 10; i++) {
    if (console) console.log(foo + i);
  }
})()
JS
    packed = Packr.pack([{:code => code, :source => 'src.js'}], 
      :shrink_vars  => true,
      :output_file  => 'foo.js')
    
    expected = "(function(c){var b=\"something\";for(var a=0;a<10;a++){if(console)console.log(b+a)}})()\n//@ sourceMappingURL=foo.js.map"
    assert_equal expected, packed
    assert_equal '', packed.header
    
    assert_equal packed.source_map,
      :sources  => %w[src.js],
      :names    => %w[config foo i],
      :segments => [
        {:line => 0, :column => 1,  :mapping => {:source => 'src.js', :line => 0, :column => 1,  :name => nil}},
        {:line => 0, :column => 10, :mapping => {:source => 'src.js', :line => 0, :column => 10, :name => 'config'}},
        {:line => 0, :column => 13, :mapping => {:source => 'src.js', :line => 1, :column => 0,  :name => nil}},
        {:line => 0, :column => 17, :mapping => {:source => 'src.js', :line => 1, :column => 4,  :name => 'foo'}},
        {:line => 0, :column => 20, :mapping => {:source => 'src.js', :line => 1, :column => 11, :name => nil}},
        {:line => 0, :column => 31, :mapping => {:source => 'src.js', :line => 2, :column => 2,  :name => nil}},
        {:line => 0, :column => 35, :mapping => {:source => 'src.js', :line => 2, :column => 7,  :name => nil}},
        {:line => 0, :column => 39, :mapping => {:source => 'src.js', :line => 2, :column => 11, :name => 'i'}},
        {:line => 0, :column => 43, :mapping => {:source => 'src.js', :line => 2, :column => 18, :name => 'i'}},
        {:line => 0, :column => 48, :mapping => {:source => 'src.js', :line => 2, :column => 26, :name => 'i'}},
        {:line => 0, :column => 53, :mapping => {:source => 'src.js', :line => 3, :column => 4,  :name => nil}},
        {:line => 0, :column => 56, :mapping => {:source => 'src.js', :line => 3, :column => 8,  :name => nil}},
        {:line => 0, :column => 64, :mapping => {:source => 'src.js', :line => 3, :column => 17, :name => nil}},
        {:line => 0, :column => 72, :mapping => {:source => 'src.js', :line => 3, :column => 25, :name => nil}},
        {:line => 0, :column => 76, :mapping => {:source => 'src.js', :line => 3, :column => 29, :name => 'foo'}},
        {:line => 0, :column => 78, :mapping => {:source => 'src.js', :line => 3, :column => 35, :name => 'i'}}
      ]
    
      assert_equal <<JSON.strip, packed.source_map.to_json
{
  "version": 3,
  "file": "foo.js",
  "sourceRoot": "",
  "sources": ["src.js"],
  "names": ["config", "foo", "i"],
  "mappings": "CAAC,SAASA,GACV,IAAIC,GAAO,WACT,IAAK,IAAIC,IAAOA,KAAQA,KACtB,GAAI,QAAS,QAAQ,IAAID,EAAMC;"
}
JSON
  end
  
  def test_multisource_source_maps
    code_b = <<JS
// This is file B
alert("hello");
JS
    code_a = <<JS
// This is file A
console.log("nothing");

Math.round(4.0);
JS
    packed = Packr.pack([
        {:code => code_b, :source => 'b.js'},
        {:code => code_a, :source => 'a.js'}
      ],
      :shrink_vars  => true,
      :output_file  => 'foo.js',
      :header       => '/* Copyright 2012 */')
    
    expected = "/* Copyright 2012 */\nalert(\"hello\");console.log(\"nothing\");Math.round(4.0);\n//@ sourceMappingURL=foo.js.map"
    assert_equal expected, packed
    
    assert_equal "/* Copyright 2012 */\n", packed.header
    assert_equal "alert(\"hello\");console.log(\"nothing\");Math.round(4.0);", packed.code
    assert_equal "\n//@ sourceMappingURL=foo.js.map", packed.footer
    
    assert_equal packed.source_map,
      :sources  => %w[a.js b.js],
      :names    => %w[],
      :segments => [
        {:line => 1, :column => 0,  :mapping => {:source => 'b.js', :line => 1, :column => 0,  :name => nil}},
        {:line => 1, :column => 7,  :mapping => {:source => 'b.js', :line => 1, :column => 7,  :name => nil}},
        {:line => 1, :column => 15, :mapping => {:source => 'a.js', :line => 1, :column => 0,  :name => nil}},
        {:line => 1, :column => 23, :mapping => {:source => 'a.js', :line => 1, :column => 8,  :name => nil}},
        {:line => 1, :column => 28, :mapping => {:source => 'a.js', :line => 1, :column => 13, :name => nil}},
        {:line => 1, :column => 38, :mapping => {:source => 'a.js', :line => 3, :column => 0,  :name => nil}},
        {:line => 1, :column => 43, :mapping => {:source => 'a.js', :line => 3, :column => 5,  :name => nil}}
      ]
  end
  
  def test_unminified_source_maps
    code_b = <<JS
// This is file B
alert("hello");
JS
    code_a = <<JS
// This is file A
console.log("nothing");

Math.round(4.0);
JS
    packed = Packr.pack([
        {:code => code_b, :source => 'b.js'},
        {:code => code_a, :source => 'a.js'}
      ],
      :minify       => false,
      :shrink_vars  => true, # no-minify takes precedence 
      :output_file  => 'foo.js',
      :header       => '/* Copyright 2012 */')
    
    assert_equal <<JS.strip, packed
/* Copyright 2012 */

// This is file B
alert("hello");

// This is file A
console.log("nothing");

Math.round(4.0);


//@ sourceMappingURL=foo.js.map
JS
    
    assert_equal <<JSON.strip, packed.source_map.to_json
{
  "version": 3,
  "file": "foo.js",
  "sourceRoot": "",
  "sources": ["a.js", "b.js"],
  "names": [],
  "mappings": ";;GCAG,KAAK,GAAG,KAAK;AAChB,OAAO;;GDDJ,KAAK,GAAG,KAAK;AAChB,QAAQ,KAAK;;AAEb,KAAK;"
}
JSON
  end
end

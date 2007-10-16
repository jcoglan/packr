require 'test/unit'
require 'packr'

class PackrTest < Test::Unit::TestCase
  
  def setup
    @packr = Packr.new
    dir = File.dirname(__FILE__) + '/assets'
    @data = {
      :default => {
        :source => File.read("#{dir}/src/controls.js"),
        :packed => File.read("#{dir}/packed/controls.js")
      },
      :shrink_vars => {
        :source => File.read("#{dir}/src/dragdrop.js"),
        :packed => File.read("#{dir}/packed/dragdrop.js")
      },
      :base62 => {
        :source => File.read("#{dir}/src/effects.js"),
        :packed => File.read("#{dir}/packed/effects.js")
      },
      :base62_shrink_vars => {
        :source => File.read("#{dir}/src/prototype.js"),
        :packed => File.read("#{dir}/packed/prototype.js")
      }
    }
  end
  
  def test_basic_packing
    assert_equal @data[:default][:packed], @packr.pack(@data[:default][:source])
  end
  
  def test_shrink_vars_packing
    assert_equal @data[:shrink_vars][:packed], @packr.pack(@data[:shrink_vars][:source], :shrink_vars => true)
  end
  
  def test_base62_packing
    expected = @data[:base62][:packed]
    actual = @packr.pack(@data[:base62][:source], :base62 => true)
    assert_equal expected.size, actual.size
    expected_words = expected.scan(/'[\w\|]+'/)[-2].gsub(/^'(.*?)'$/, '\1').split("|").sort
    actual_words = actual.scan(/'[\w\|]+'/)[-2].gsub(/^'(.*?)'$/, '\1').split("|").sort
    assert expected_words.eql?(actual_words)
  end
end

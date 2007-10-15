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
  
  def test_packing
    assert_equal @data[:default][:packed], @packr.pack(@data[:default][:source])
    #assert_equal @data[:shrink_vars][:packed], @packr.pack(@data[:shrink_vars][:source], :shrink_vars => true)
    #assert_equal @data[:base62][:packed], @packr.pack(@data[:base62][:source], :base62 => true)
    #assert_equal @data[:base62_shrink_vars][:packed], @packr.pack(@data[:base62_shrink_vars][:source], :shrink_vars => true, :base62 => true)
  end
end

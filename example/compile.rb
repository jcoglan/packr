require 'rubygems'
require File.expand_path('../../lib/packr', __FILE__)

dir    = File.expand_path('..', __FILE__)
code   = File.read(dir + '/example.js')

packed = Packr.pack(code,
  :shrink_vars    => true,
  :private        => true,
  :source_files   => {'example.js' => 0},
  :generated_file => 'example-min.js'
)

File.open(dir + '/example-min.js', 'w') do |f|
  f.write(packed)
end

File.open(dir + '/example-min.js.map', 'w') do |f|
  f.write(packed.source_map.to_s)
end

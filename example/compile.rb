require 'rubygems'
require File.expand_path('../../lib/packr', __FILE__)
require 'fileutils'

dir    = File.expand_path('..', __FILE__)
code   = File.read(dir + '/example.js')

packed = Packr.pack(code,
  :shrink_vars  => true,
  :private      => true,
  :source_files => {'../example.js' => 0},
  :output_file  => 'example-min.js',
  :line_offset  => 1 # for header comment in packed file
)

FileUtils.mkdir_p(dir + '/min')

File.open(dir + '/min/example-min.js', 'w') do |f|
  f.write("/* Copyright 2012 some guy */\n" + packed)
end

File.open(dir + '/min/example-min.js.map', 'w') do |f|
  f.write(packed.source_map.to_s)
end

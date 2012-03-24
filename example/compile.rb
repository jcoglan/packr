require 'rubygems'
require File.expand_path('../../lib/packr', __FILE__)
require 'fileutils'

dir    = File.expand_path('..', __FILE__)
code_a = File.read(dir + '/example_a.js')
code_b = File.read(dir + '/example_b.js')

packed = Packr.pack([code_a, code_b] * "\n",
  :shrink_vars  => true,
  :private      => true,
  :source_files => {'../example_a.js' => 0, '../example_b.js' => code_a.size + 1},
  :output_file  => 'example-min.js',
  :line_offset  => 1 # for header comment in packed file
)

FileUtils.mkdir_p(dir + '/min')

File.open("#{dir}/min/example-min.js", 'w') do |f|
  f.write("/* Copyright 2012 some guy */\n" + packed)
end

File.open("#{dir}/min/#{packed.source_map.filename}", 'w') do |f|
  f.write(packed.source_map.to_s)
end

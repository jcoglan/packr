require 'rubygems'
require File.expand_path('../../lib/packr', __FILE__)
require 'fileutils'

dir = File.expand_path('..', __FILE__)
sources = ["#{dir}/example_a.js", "#{dir}/example_b.js"]

Packr.bundle(sources => "#{dir}/min/example-min.js",
  :shrink_vars => true,
  :private     => true,
  :header      => '/* Copyright 2012 some guy */'
)

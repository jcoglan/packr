require 'rubygems'
require File.expand_path('../../lib/packr', __FILE__)

dir = File.expand_path('..', __FILE__)
sources = ["#{dir}/script_a.js", "#{dir}/script_b.js"]

Packr.bundle(sources => "#{dir}/min/script-min.js",
  :shrink_vars => true,
  :private     => true,
  :header      => '/* Copyright 2012 some guy */'
)

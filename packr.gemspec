Gem::Specification.new do |s|
  s.name              = "grimen-packr"
  s.version           = "3.1.2"
  s.summary           = "Ruby version of Dean Edwards' JavaScript compressor"
  s.author            = "James Coglan"
  s.email             = "jcoglan@gmail.com"
  s.homepage          = "http://github.com/grimen/packr"

  s.extra_rdoc_files  = %w[README.rdoc]
  s.rdoc_options      = %w[--main README.rdoc]

  s.files             = %w[History.txt README.rdoc] + Dir.glob("{bin,lib,test}/**/*")

  s.executables       = Dir.glob("bin/**").map { |f| File.basename(f) }
  s.require_paths     = ["lib"]

  s.add_dependency "oyster", ">= 0.9.5"

  s.add_development_dependency "test-unit"
  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
end

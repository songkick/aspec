Gem::Specification.new do |s|
  s.name              = "aspec"
  s.version           = "0.2.0"
  s.summary           = "Testing for API external surfaces"
  s.author            = "Daniel Lucraft"
  s.email             = "dan@songkick.com"
  s.homepage          = "http://github.com/songkick/aspec"

  s.extra_rdoc_files  = %w[README.md]
  s.rdoc_options      = %w[--main README.md]
  s.require_paths     = %w[lib]
  s.bindir            = "bin"
  s.default_executable = "bin/aspec"
  s.executables        = "aspec"

  s.files = %w[README.md] +
            Dir.glob("{bin,lib,spec}/**/*.rb")

  s.add_dependency "rspec", ">= 2.11.0"
  s.add_dependency "term-ansicolor"
  s.add_dependency "rack-test"
  s.add_dependency "json-compare"
end


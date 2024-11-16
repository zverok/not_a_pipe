Gem::Specification.new do |s|
  s.name     = 'not_a_pipe'
  s.version  = '0.0.1'
  s.authors  = ['Victor Shepelev']
  s.email    = 'zverok.offline@gmail.com'
  s.homepage = 'https://github.com/zverok/not_a_pipe'

  s.summary = 'Elixir-style pipes in Ruby (yes, again)'
  s.description = <<-EOF
    Experimental/demo library. Not to be used in production.
  EOF
  s.licenses = ['MIT']

  s.required_ruby_version = '>= 3.0.0'

  s.files = `git ls-files lib LICENSE.txt *.md`.split($RS)
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'parser'
  s.add_runtime_dependency 'unparser'
  s.add_runtime_dependency 'method_source'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubygems-tasks'
end

Gem::Specification.new do |s|
  s.name        = 'phoenix_rails'
  s.version     = '0.0.1'
  s.date        = '2017-04-22'
  s.summary     = 'Rails gem for Phoenix integration'
  s.description = 'Gem for pushing event to a Phoenix server for realtime'
  s.authors     = ['Nguyen Le']
  s.email       = 'nathanle89@gmail.com'
  s.files       = [
    'lib/phoenix_rails.rb',
    'lib/phoenix_rails/channel.rb',
    'lib/phoenix_rails/client.rb',
    'lib/phoenix_rails/request.rb',
    'lib/phoenix_rails/resource.rb'
  ]
  s.add_runtime_dependency 'httpclient', '~> 2.7'
  s.add_runtime_dependency 'multi_json', '~> 1.0'
  s.homepage    = 'http://rubygems.org/gems/phoenix_rails'
  s.license       = 'MIT'
end

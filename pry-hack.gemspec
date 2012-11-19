$:.unshift File.expand_path("../lib", __FILE__)
require "pry/hack"

Gem::Specification.new do |g|
  g.name     = "pry-hack"
  g.version  = Pry::Hackage::VERSION
  g.authors  = ["Matthew Carey"]
  g.email    = "matthew.b.carey@gmail.com"
  g.homepage = "https://github.com/swarley/pry-hack"
  g.summary  = "Change the syntax of your pry session with minimal side effects"
  g.description = <<DESCRIPTION
Using a lexical parser, this gem allows you to add hacks to your REPL session allowing you to
have shortcut syntax. Things such as
[0] pry(main)> object.@ivar
=> :im_the_return_of_an_instance_variable

Or

[0] pry(main)> %S{hello symbol world}
=> [:hello, :symbol, :world]

And even the most desired ruby syntax of all is planned to come, that's right. Increment and decrement operators.

[0] pry(main)> i++
=> 1
[1] pry(main)> i--
=> 0
DESCRIPTION
  
  g.add_development_dependency "rubylexer"
  g.add_development_dependency "pry"
  g.add_development_dependency "minitest"
  
  g.files = Dir.glob("{lib,examples}/**/*") + %w{README.md}
  
  g.require_path = 'lib'
end

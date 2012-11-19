require "pry/hack"

Pry.add_hack(:method, :instance_variable_peek,
  Pry::Hackage::Hack.new(/^@([A-Za-z_][A-Za-z0-9_]*[A-za-z0-9_\?\!])$/) { replace_with "instance_variable_get(:@#{capture 1})" }
)

Pry.config.hack.enabled = true

#class Test
#  def initialize
#    @hello = :world
#  end
#end
#
#object = Test.new
#puts object.@hello

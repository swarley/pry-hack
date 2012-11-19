require "pry/hack"
require "find"

alias __load__ load 

module Kernel
  def load(path, wrap=false)
    if File.exists? path
      fname = path
    else
      fname = ($:.each_with_object([]) {|x,a| if File.exists?(x + "/" + path) then a << x end }).last
    end
    if fname.nil?
      __load__ path, wrap
    else
      t = Tempfile.new("pry-hack")
      t.write(Pry::Hackage.hack_line(File.read(path)))
      t.close
      r = __load__ t.path, wrap
      t.unlink
      return r
    end
  end
end

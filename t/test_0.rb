require "bacon"
require "pry"
$:.unshift File.expand_path("../../lib", __FILE__)
require "pry/hack"
load File.expand_path("../helper.rb", __FILE__)

describe "Pry Syntax Hacks" do
  before do
    Pry.add_hack(:method, :test_hack, Pry::Hackage::Hack.new(/^@(.+?)$/) { replace_with "instance_variable_get(:@#{capture 1})" })
    Pry.config.hack.enabled = true
  end 
  
  it 'should not change a line unless it is enabled' do
    Pry.config.hack.enabled = false
    lambda do
      eval Pry::Hackage.hack_line("hi.@ivar")
    end.should.raise SyntaxError
    Pry.config.hack.enabled = true
  end

  it 'should follow syntax adjustments given when enabled' do
    str = ""
    redirect_pry_io(InputTester.new(%<class Test; def initialize; @ivar = :defined; end; end>, %<obj = Test.new>, %<obj.@ivar>), StringIO.new(str)) do
      Pry.start
    end
    str.should.match /defined/
  end
end 

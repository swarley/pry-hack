require "pry/hack.rb"

Pry.add_hack(:%, :symbol_array, Pry::Hackage::ModOpHack.new('S') { replace_with "%w#{delimiter.open}#{content}#{delimiter.close}.map(&:to_sym)" })

Pry.config.hack.enabled = true

# [0] pry(main)> %S{hello symbol world!}
# => [:hello, :symbol, :world!]

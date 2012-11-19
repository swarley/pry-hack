require "pry"
require "rubylexer"

class Pry
  
  # Configuration block for the plugin
  # - _s_            A cute way to joke at `hacks', also holds the structures
  #                  that contain the {Pry::Hackage::Hack} objects.
  # - _implications_ Aliases for use in {Pry::Hackage::Hack#initialize}.
  # - _enabled_      Whether or not the hacks are being used.
  self.config.hack = 
    OpenStruct.new(
      :s => OpenStruct.new(
        :meth           => {},
        :symbol_prefix  => {},
        :modop          => {}
        #:operator       => {},
        #:unary          => {},
        #:identifier     => {},
        #:magic_variable => {},
        #:unicode        => {},
      ),
      :implications => OpenStruct.new(
        :method => :meth,
        :symbol => :symbol_prefix,
        :%      => :modop
      ),
      :enabled => false
    )

  # Adds a hack to pry for use in the REPL.
  #
  # @param  [Symbol]             type The type of hack which is being added, this decides the placement
  #                              of the object in Pry.config.hack.s
  #
  # @param  [Object]             handle A name to give to the hack, this is needed to remove the hack from
  #                              the environment as well.
  #
  # @param  [Pry::Hackage::Hack] hack The hack that will be added to Pry. See {Pry::Hackage::Hack}
  #
  # @return [Pry::Hackage::Hack] The hack that was passed as the last argument of the method.
  def self.add_hack(type, handle, hack)
    (eval "self.config.hack.s.#{self.config.hack.implications.send(:method_missing, type)||type}")[handle] = hack
    return hack
  end
  
  # Removes a method from use in the REPL, added by {Pry#add_hack}
  #
  # @param  [Object]  type The name that was assigned to the hack at the time it was added.
  #
  # @return [Fixnum]  handle The number of hacks with the name given that were removed from
  #                   the environment.
  def self.remove_hack(type, handle)
    si = self.config.hack.collect(&:size).reduce(0,:+)
    self.config.hack.each {|hash| hash.delete(handle)}
    return si - self.config.hack.collect(&:size).reduce(0,:+)
  end

  # The main module containing the hack code
  module Hackage

    VERSION = 0.1

    # Regular expressions kept constant for optimization and intended for use to match
    # patterns that may be used by a hack in the future.
    REGEX_REGEX = [%r/\A\/(.+?)\/(.+?)*\Z/, %r/%r(.)([^\1\\]|\\.)*\1/]
    SYMBOL_REGEX = %r/\A\:(.+?)\Z/
    
    KEYWORDS = %w[BEGIN END alias and begin break case class def defined? do else elsif end ensure for
                  if in module next not or redo rescue retry return super then when while yield]
    # The base class from which all Hacks extend
    class Hack

      # Object initialization.
      #
      # @param [Regexp] regex The regular expression that matches the hack
      #
      # @param [Proc]   block The block passed to the method detailing the hack's action.
      def initialize(regex, &block)
        @PATTERN = regex
        @CODE    = block
        define_singleton_method(:capture) do |x|
          [][x]
        end
      end

      # Lexical score of a string in relation to the regular expression of the hack.
      #
      # @param  [String]  text The text to be tested for a numerical matching score.
      #
      # @return [Fixnum]  The score given, or characters matched by the regular expression. 
      def score(text)
        md = @PATTERN.match(text)
        return if md.nil?
        cap = md.captures
        define_singleton_method(:capture) do |x|
          cap[x-1]
        end
        return cap.join.length
      end
 
      def run(where)
        instance_exec(nil, where, &@CODE)
      end

     # DSL function that replaces the entire string with the one provided.
     def replace_with(text)
       return text
     end
  
     # DSL function that acts like String#sub
     #
     # @param  [String]       text The text that will be subject to the sub.
     #
     # @param  [Hash,String]  hash If a hash, you must use the format :with => "text"
     #                        and you may also supply :global? => true to apply
     #                        a global substitution. See String#gsub
     #
     # @return [String]       The string post operations.
     def replace(text, hash)
       if hash.is_a? Hash
         if hash[:global?].nil? || hash[:global?]
           return text.gsub(@PATTERN, hash[:with])
         else
           return text.sub(@PATTERN, hash[:with])
         end
       else
         return text.gsub(@PATTERN, hash)
       end
     end
  
     def ignore
       return nil
     end
      
    end

    class ModOpHack < Hack
      def initialize(char, &block)
        @CHAR = char
        @CODE    = block
        define_singleton_method(:capture) do |x|
          [][x]
        end
      end

       PAIR_MATCHES = {'[' => ']', '{' => '}', '(' => ')', '<' => '>'}
      def score(str)
        str.strip!
        char = Regexp.escape(str[1])
        char_to_match = Regexp.escape(PAIR_MATCHES[str[1]]||str[1])
        @PATTERN = /^#{@CHAR}(#{char})(.*)(#{char_to_match})$/
        scr = super str
        define_singleton_method(:delimiter) { Struct.new(:open,:close).new(capture(1), capture(3)) }
        define_singleton_method(:content) { capture(2) }
        return scr
      end
    end
  
    def self.hack_line(str)
      # A dirty syntax hack used to enable and disable pry-hack when a hack goes
      # wrong and you are unable to fix it because of a side effect. The syntax is as follows
      # -*- pry-hack: disable -*-
      # or to enable
      # -*- pry-hack: enable -*-
      if str =~ /#\s*-\*-\s*pry-hack:\s*(disable|enable)\s*-\*-\s*/
        self.config.hack.enabled = ($1 == "enable") ? true : false
      end
      return str unless ::Pry.config.hack.enabled      
      stack  = []
      tstack = []
      state  = nil

      lexer = RubyLexer.new("(pry)", str)
      tstack = lexer.to_set.to_a[1..-2].select {|x| !(x.is_a? RubyLexer::FileAndLineToken) }
      tstack.map!(&:to_s)
        while c = tstack.shift
          if state.nil?
            state= case c
                   when '.'
                     # self.config.hack.s.meth
                     :meth
                   when '%'
                     # self.config.hack.s.modop
                     :modop
                   when Hackage::SYMBOL_REGEX
                     # self.config.hack.s.symbol_prefix
                     :symbol_prefix
                   when *Hackage::REGEX_REGEX
                     # self.config.hack.s.regex
                     :regex
                   end
           stack.push c
           next 
         else
           if state == :modop && tstack[0] =~ /[^A-Za-z0-9#]/
              char = Regexp.escape(tstack[0])
              char_to_match = Regexp.escape(ModOpHack::PAIR_MATCHES[tstack[0]] || char) 
              c += (tstack.shift + " ") until c =~ /^.#{char}.*#{char_to_match}/ 
           end
           hacks = (self.config.hack.s.send(state).values.sort_by {|x| x.score(c) })
           if hacks.nil?
            stack.push c
            next
           end 
           hacks.compact!
           hacks.reject! {|x| x.score(c).nil? }
           if hacks.any? && stack.last == '%' then stack.pop end   # Do this so that you can make sure not to have a double modulo occurance
           c = (hacks.any?) ? hacks.last.run(binding) : c
           state = nil
           stack.push c
         end
       end  
       return stack.join
     end
   end

  alias_method :old_retrieve_line, :retrieve_line

  def retrieve_line(eval_string, *args)
    old_retrieve_line(eval_string, *args)
    puts eval_string.sub!(/^.+?$/, Hackage.hack_line(eval_string))
  end

end

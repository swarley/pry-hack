require "pry/hack"
alias __eval__ eval
def eval(code, *args)
  __eval__(Pry::Hackage.hack_line(code), *args)
end

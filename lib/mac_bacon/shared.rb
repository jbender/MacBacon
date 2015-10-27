module Bacon
  Shared = Hash.new { |_, name|
    raise NameError, "no such context: #{name.inspect}"
  }
end

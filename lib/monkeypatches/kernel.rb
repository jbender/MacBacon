module Kernel
  private

  def describe(*args, &block)
    Bacon::Context.init_context(args.join(' '), 1, &block)
  end
  # alias_method :context, :describe
  def context(*args, &block)
    describe(*args, block)
  end

  def shared(name, &block)
    Bacon::Shared[name] = block
  end
end

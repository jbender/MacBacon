class Object
  def true?; false; end

  def false?; false; end

  def should(*args, &block)
    Should.new(self).be(*args, &block)
  end
end

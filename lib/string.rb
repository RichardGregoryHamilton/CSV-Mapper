class String
  # Checks if a string represents an Integer.
  def is_integer?
		self =~ /\A[-]?[\d]+\z/
  end

  # Checks if a string represents a Float.
  def is_float?
		self =~ /\A[-]?[\d]+\.[\d]+\z/
  end

  def is_numeric?
     self.is_f? || self.is_i?
  end
end

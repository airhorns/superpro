class Types::AbstractKey < Types::BaseScalar
  def self.coerce_input(input_value, _context)
    input_value
  end

  def self.coerce_result(ruby_value, _context)
    ruby_value.to_s
  end
end

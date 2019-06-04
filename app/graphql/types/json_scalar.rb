class Types::JSONScalar < GraphQL::Schema::Scalar
  description "Untyped JSON output useful for bags of values who's keys or types can't be predicted ahead of time."

  def self.coerce_input(val, _ctx)
    val
  end

  def self.coerce_result(val, _ctx)
    val
  end
end

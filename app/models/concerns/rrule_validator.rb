class RRuleValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    RRule.parse(value)
  rescue RRule::InvalidRRule
    record.errors[attribute] << (options[:message] || "is not a valid recurrence rule")
  end
end

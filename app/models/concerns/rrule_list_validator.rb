class RRuleListValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    value.each do |rule_string|
      RRule.parse(rule_string)
    end
  rescue RRule::InvalidRRule
    record.errors[attribute] << (options[:message] || "is not a valid list of recurrence rules")
  end
end

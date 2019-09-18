# frozen_string_literal: true

if Rails.env.development?
  ActiveRecordQueryTrace.colorize = :light_purple
  ActiveRecordQueryTrace.enabled = ENV["TRACE_QUERIES"].present?
end

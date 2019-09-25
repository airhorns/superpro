# frozen_string_literal: true

class Traffic::SessionFacts < DataModel::FactTable
  self.table = "warehouse.fct_snowplow_sessions"
  include Traffic::Common

  measure :page_views, DataModel::Types::Number
  measure :time_engaged_in_s, DataModel::Types::Number

  dimension :min_tstamp, DataModel::Types::DateTime
  dimension :max_tstamp, DataModel::Types::DateTime

  dimension :device, DataModel::Types::String
  dimension :device_is_mobile, DataModel::Types::Boolean

  dimension :first_page_title, DataModel::Types::String
  dimension :first_page_url, DataModel::Types::String
  dimension :first_page_url_fragment, DataModel::Types::String
  dimension :first_page_url_host, DataModel::Types::String
  dimension :first_page_url_path, DataModel::Types::String
  dimension :first_page_url_query, DataModel::Types::String
  dimension :first_page_url_scheme, DataModel::Types::String

  dimension :exit_page_url, DataModel::Types::String

  dimension :session_start, DataModel::Types::DateTime
  dimension :session_start_local, DataModel::Types::DateTime
  dimension :session_end, DataModel::Types::DateTime
  dimension :session_end_local, DataModel::Types::DateTime

  dimension :session_cookie_index, DataModel::Types::Number
  dimension :time_engaged_in_s_tier, DataModel::Types::String

  dimension :user_bounced, DataModel::Types::Boolean

  dimension :session_index, DataModel::Types::Number
end

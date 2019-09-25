# frozen_string_literal: true

class Traffic::PageViewFacts < DataModel::FactTable
  self.table = "warehouse.fct_snowplow_page_views"
  include Traffic::Common

  measure :time_engaged_in_s, DataModel::Types::Number

  measure :vertical_pixels_scrolled, DataModel::Types::Number
  measure :horizontal_pixels_scrolled, DataModel::Types::Number
  measure :vertical_percentage_scrolled, DataModel::Types::Number
  measure :horizontal_percentage_scrolled, DataModel::Types::Number

  measure :redirect_time_in_ms, DataModel::Types::Number
  measure :unload_time_in_ms, DataModel::Types::Number
  measure :app_cache_time_in_ms, DataModel::Types::Number
  measure :dns_time_in_ms, DataModel::Types::Number
  measure :tcp_time_in_ms, DataModel::Types::Number
  measure :request_time_in_ms, DataModel::Types::Number
  measure :response_time_in_ms, DataModel::Types::Number
  measure :processing_time_in_ms, DataModel::Types::Number
  measure :dom_loading_to_interactive_time_in_ms, DataModel::Types::Number
  measure :dom_interactive_to_complete_time_in_ms, DataModel::Types::Number
  measure :onload_time_in_ms, DataModel::Types::Number
  measure :total_time_in_ms, DataModel::Types::Number

  dimension :page_view_id, DataModel::Types::String
  dimension :page_view_index, DataModel::Types::Number
  dimension :page_view_in_session_index, DataModel::Types::Number
  dimension :max_session_page_view_index, DataModel::Types::Number

  dimension :session_id, DataModel::Types::String
  dimension :session_index, DataModel::Types::Number

  dimension :page_view_start, DataModel::Types::DateTime
  dimension :page_view_end, DataModel::Types::DateTime
  dimension :page_view_start_local, DataModel::Types::DateTime
  dimension :page_view_end_local, DataModel::Types::DateTime

  dimension :page_title, DataModel::Types::String
  dimension :page_url, DataModel::Types::String
  dimension :page_url_fragment, DataModel::Types::String
  dimension :page_url_host, DataModel::Types::String
  dimension :page_url_path, DataModel::Types::String
  dimension :page_url_query, DataModel::Types::String
  dimension :page_url_scheme, DataModel::Types::String
  dimension :page_width, DataModel::Types::Number
  dimension :page_height, DataModel::Types::Number

  dimension :vertical_percentage_scrolled_tier, DataModel::Types::String

  dimension :user_engaged, DataModel::Types::Boolean
  dimension :time_engaged_in_s_tier, DataModel::Types::String
  dimension :is_internal, DataModel::Types::Boolean

  dimension :browser_window_width, DataModel::Types::Number
  dimension :browser_window_height, DataModel::Types::Number

  dimension :last_page_view_in_session, DataModel::Types::Number
end

# frozen_string_literal: true

class Traffic::PageViewFacts < DataModel::FactTable
  self.table = "warehouse.fct_snowplow_page_views"
  include Traffic::Common

  measure :time_engaged_in_s, DataModel::Types::Number

  measure :vertical_pixels_scrolled, DataModel::Types::Number
  measure :horizontal_pixels_scrolled, DataModel::Types::Number
  measure :vertical_percentage_scrolled, DataModel::Types::Number
  measure :horizontal_percentage_scrolled, DataModel::Types::Number

  measure :redirect_time_in_ms, DataModel::Types::Duration
  measure :unload_time_in_ms, DataModel::Types::Duration
  measure :app_cache_time_in_ms, DataModel::Types::Duration
  measure :dns_time_in_ms, DataModel::Types::Duration
  measure :tcp_time_in_ms, DataModel::Types::Duration
  measure :request_time_in_ms, DataModel::Types::Duration
  measure :response_time_in_ms, DataModel::Types::Duration
  measure :processing_time_in_ms, DataModel::Types::Duration
  measure :dom_loading_to_interactive_time_in_ms, DataModel::Types::Duration
  measure :dom_interactive_to_complete_time_in_ms, DataModel::Types::Duration
  measure :onload_time_in_ms, DataModel::Types::Duration
  measure :total_time_in_ms, DataModel::Types::Duration

  measure :bounce_pct, DataModel::Types::Percentage do
    table_node[:is_bounce].count / table_node[:session_id].count(true)
  end

  dimension :page_view_id, DataModel::Types::String
  dimension :page_view_index, DataModel::Types::Number
  dimension :page_view_in_session_index, DataModel::Types::Number
  dimension :max_session_page_view_index, DataModel::Types::Number

  dimension :min_tstamp, DataModel::Types::DateTime
  dimension :max_tstamp, DataModel::Types::DateTime

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

  dimension :referrer_medium, DataModel::Types::String
  dimension :referrer_source, DataModel::Types::String
  dimension :referrer_term, DataModel::Types::String

  dimension :ecommerce_function, DataModel::Types::String
  dimension :is_shopify, DataModel::Types::Boolean
  dimension :shopify_area, DataModel::Types::String

  dimension :is_bounce, DataModel::Types::Boolean
end

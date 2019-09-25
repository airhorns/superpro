module Traffic::Common
  extend ActiveSupport::Concern
  included do
    dimension :app_id, DataModel::Types::String
    dimension :user_id, DataModel::Types::String, sql: table_node[:user_snowplow_domain_id]
    dimension :session_id, DataModel::Types::String
    dimension :crossdomain_user_id, DataModel::Types::String, sql: table_node[:user_snowplow_crossdomain_id]

    dimension :device, DataModel::Types::String
    dimension :device_engine, DataModel::Types::String
    dimension :device_is_mobile, DataModel::Types::Boolean

    dimension :browser, DataModel::Types::String
    dimension :browser_name, DataModel::Types::String
    dimension :browser_language, DataModel::Types::String
    dimension :os, DataModel::Types::String
    dimension :os_name, DataModel::Types::String
    dimension :os_timezone, DataModel::Types::String

    dimension :ip_address, DataModel::Types::String

    dimension :geo_city, DataModel::Types::String
    dimension :geo_region_name, DataModel::Types::String
    dimension :geo_country, DataModel::Types::String
    dimension :geo_timezone, DataModel::Types::String
    dimension :geo_zipcode, DataModel::Types::String

    dimension :marketing_campaign, DataModel::Types::String
    dimension :marketing_click_id, DataModel::Types::String
    dimension :marketing_content, DataModel::Types::String
    dimension :marketing_medium, DataModel::Types::String
    dimension :marketing_network, DataModel::Types::String
    dimension :marketing_source, DataModel::Types::String
    dimension :marketing_term, DataModel::Types::String

    dimension :referrer_medium, DataModel::Types::String
    dimension :referrer_source, DataModel::Types::String
    dimension :referrer_term, DataModel::Types::String
    dimension :referrer_url, DataModel::Types::String
    dimension :referrer_url_fragment, DataModel::Types::String
    dimension :referrer_url_host, DataModel::Types::String
    dimension :referrer_url_path, DataModel::Types::String
    dimension :referrer_url_query, DataModel::Types::String
  end
end

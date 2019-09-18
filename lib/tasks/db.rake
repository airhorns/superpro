# frozen_string_literal: true

namespace :db do
  desc "Truncate all existing data"
  task :truncate => "db:load_config" do
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection.tables.each do |table|
      next if table == "schema_migrations"
      ActiveRecord::Base.connection.execute("TRUNCATE #{table} CASCADE")
    end
  end
end

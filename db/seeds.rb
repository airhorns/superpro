require "factory_bot_rails"
require "faker"
Rails.logger = ActiveSupport::Logger.new(STDOUT)
Rails.logger.info("Starting seed")

user = User.new(full_name: "Smart Developer", email: "dev@superpro.io", password: "developer", password_confirmation: "developer")
user.skip_confirmation!
user.save!

FactoryBot.create :account, creator: user, business_epoch: 30.days.ago

# Enable all feature flags for developers
BaseClientSideAppSettings::EXPORTED_FLAGS.each do |flag|
  Flipper[flag].enable
end

Rails.logger.info "DB Seeded!"
[Account, User].each do |klass|
  Rails.logger.info "#{klass.name} count: #{klass.all.count}"
end

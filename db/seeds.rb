require "factory_bot_rails"
require "faker"
Rails.logger = ActiveSupport::Logger.new(STDOUT)
Rails.logger.info("Starting seed")

user = User.new(full_name: "Smart Developer", email: "dev@flurish.dev", password: "developer", password_confirmation: "developer")
user.skip_confirmation!
user.save!

FactoryBot.create :account, creator: user

Rails.logger.info "DB Seeded!"
[Account, User, BudgetLine, Series, Cell].each do |klass|
  Rails.logger.info "#{klass.name} count: #{klass.all.count}"
end

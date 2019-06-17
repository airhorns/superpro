require "factory_bot_rails"
require "faker"
Rails.logger = ActiveSupport::Logger.new(STDOUT)
Rails.logger.info("Starting seed")

user = User.new(full_name: "Smart Developer", email: "dev@gapp.fun", password: "developer", password_confirmation: "developer")
user.skip_confirmation!
user.save!

account = FactoryBot.create :account, creator: user
FactoryBot.create(:base_operational_budget, account: account, creator: account.creator)

Rails.logger.info "DB Seeded!"
[Account, User, BudgetLine, Series, Cell].each do |klass|
  Rails.logger.info "#{klass.name} count: #{klass.all.count}"
end

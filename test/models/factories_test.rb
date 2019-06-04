
require "test_helper"

class FactoriesTest < ActiveSupport::TestCase
  test "all factories pass lint" do
    FactoryBot.lint traits: true
  end

  # Because factory_bot magically materializes associations, unless the tree of all the stuff this creates
  # is very careful to pass the account instance down to each subresource created, those subresources will create
  # their own account instance, breaking the fixture and making things confusing. Hunting down which subresource
  # creates the extra account is tricky and at this point is mostly done by guessing.
  test "big account fixtures create only one account" do
    create(:account)
    assert_equal 1, Account.all.size
  end
end

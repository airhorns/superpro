# frozen_string_literal: true

require "test_helper"

class Identity::GenerateJwtTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
  end

  test "it can generate a jwt for a user" do
    assert_not_nil Identity::GenerateJwt.new(@account).generate(@account.creator)
  end
end

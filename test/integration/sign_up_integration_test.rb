require "test_helper"

class SignUpIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    host! Rails.configuration.x.domains.app
  end

  test "can create a new user and account" do
    post "/auth/api/sign_up.json", params: { sign_up: {
                                     user: {
                                       full_name: "Testy Testerson",
                                       email: "test@gmail.com",
                                       password: "secrets",
                                       password_confirmation: "secrets",
                                     },
                                     account: {
                                       name: "Test Inc",
                                     },
                                   } }
    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_nil json["redirect_url"]
  end

  test "validates user email" do
    post "/auth/api/sign_up.json", params: { sign_up: {
                                     user: {
                                       full_name: "Testy Testerson",
                                       email: "",
                                       password: "secrets",
                                       password_confirmation: "secrets",
                                     },
                                     account: {
                                       name: "Test Inc",
                                     },
                                   } }
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_not_nil json["errors"]
  end

  test "validates passwords match" do
    post "/auth/api/sign_up.json", params: { sign_up: {
                                     user: {
                                       full_name: "Testy Testerson",
                                       email: "test@gmail.com",
                                       password: "secrets",
                                       password_confirmation: "oopsietypo",
                                     },
                                     account: {
                                       name: "Test Inc",
                                     },
                                   } }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_not_nil json["errors"]
  end
end

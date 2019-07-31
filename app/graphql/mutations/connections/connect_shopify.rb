class Mutations::Connections::ConnectShopify < Mutations::BaseMutation
  argument :api_key, String, required: true
  argument :password, String, required: true
  argument :domain, String, required: true

  field :shopify_shop, Types::Connections::ShopifyShopType, null: true
  field :errors, [String], null: true

  def resolve(domain:, api_key:, password:)
    shop, errors = Connections::ConnectShopify.new(context[:current_account], context[:current_user]).connect_private_app(api_key, password, domain)

    {
      shopify_shop: shop,
      errors: errors,
    }
  end
end

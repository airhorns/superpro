class Infrastructure::SingerImporterClient
  def self.client
    @client ||= self.new(Rails.configuration.singer_importer[:api_url], Rails.configuration.singer_importer[:auth_token])
  end

  def initialize(base_api_url, auth_token)
    @base_url = base_api_url
    @auth_token = auth_token
  end

  def import(importer, config)
    RestClient::Request.execute(
      method: :post,
      url: @base_url + "/import/#{importer}",
      payload: { singer_config: config, singer_state: {} }.to_json,
      headers: { :Authorization => "Token #{@auth_token}", content_type: :json },
      block_response: proc { |response|
        Infrastructure::LineWiseHttpResponseReader.new(response).each_line do |line|
          blob = JSON.parse(line)
          if blob["stream"] == "STDOUT" && blob["tag"] == "target"
            message = JSON.parse(blob["message"])
            if message["type"] == "STATE"
              yield message
            end
          end
        end
      },
    )
  end
end

class Infrastructure::SingerImporterClient
  class UncleanExitException < RuntimeError; end

  def self.client
    @client ||= self.new(Rails.configuration.singer_importer[:api_url], Rails.configuration.singer_importer[:auth_token])
  end

  def initialize(base_api_url, auth_token)
    @base_url = base_api_url
    @auth_token = auth_token
  end

  def import(importer, config:, state: {}, url_params: {}, transform: {}, on_state_message: nil)
    RestClient::Request.execute(
      method: :post,
      url: @base_url + "/import/#{importer}?#{url_params.to_query}",
      payload: { singer_config: config, singer_state: state, transform: transform }.to_json,
      headers: { :Authorization => "Token #{@auth_token}", content_type: :json },
      read_timeout: nil,
      block_response: proc { |response|
        Infrastructure::LineWiseHttpResponseReader.new(response).each_line do |line|
          blob = JSON.parse(line)

          if blob["stream"] == "STDOUT" && blob["tag"] == "target"
            message = JSON.parse(blob["message"])
            if on_state_message.present?
              on_state_message.call(message)
            end
          end

          if blob["stream"] == "SYSTEM"
            if !blob["success"].nil? && !blob["success"]
              raise UncleanExitException.new("Process #{blob["tag"]} exited with exit code #{blob["exit_code"]}")
            end
          end
        end
      },
    )
  end
end

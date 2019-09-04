require "test_helper"

class Infrastructure::KubernetesClientTest < ActiveSupport::TestCase
  setup do
    @client = Infrastructure::KubernetesClient.new
  end

  test "it can create a job resource" do
    @client.create_long_running_rails_job("foo-#{Time.now.utc.to_i}", ["echo", "hello world"])
  end

  test "it can perform a Que job in K8S" do
    @client.run_background_job_in_k8s(Infrastructure::TestExceptionJob, [])
  end
end

require "digest"
require "subprocess"
require "test_helper"

class UncommittedChangesTest < ActiveSupport::TestCase
  test "graphql components can be built and doesn't have uncommitted changes" do
    skip("no dev server running") unless dev_server_running?
    assert_no_filesystem_changes(Rails.root.join("app", "assets", "javascript").to_s) do
      Subprocess.check_output(%W{yarn generate-graphql})
    end
  end

  private

  def assert_no_filesystem_changes(dir)
    before_checksum = checksum(dir)
    yield
    assert_equal before_checksum, checksum(dir), "Files in #{dir} changed after block invocation"
  end

  def checksum(dir)
    md5 = Digest::MD5.new
    Dir["#{dir}/**/*"].reject { |f| File.directory?(f) }.sort.each do |_file|
      md5 << File.read(f)
    end
    md5.hexdigest
  end

  def dev_server_running?
    @dev_server_running ||= begin
                              TCPSocket.new("app.supo.dev", 443)
                              true
                            rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
                              false
                            end
  end
end

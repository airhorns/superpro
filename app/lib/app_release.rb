# frozen_string_literal: true

module AppRelease
  def self.current
    @current ||= begin
      release_file = Rails.root.join("RELEASE").to_s

      if File.exist?(release_file)
        File.read(release_file).chomp
      elsif ENV["RELEASE"]
        ENV["RELEASE"]
      else
        "unknown"
      end
    end
  end
end

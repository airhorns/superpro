# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Debug an issue on circle where trestle admin names were coming out as mangled strings
unless ENV["CI"]
  require "bootsnap/setup" # Speed up boot time by caching expensive operations.
end

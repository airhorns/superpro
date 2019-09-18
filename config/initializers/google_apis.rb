# frozen_string_literal: true

require "google/apis"
Google::Apis.logger = SemanticLogger[Google::Apis]

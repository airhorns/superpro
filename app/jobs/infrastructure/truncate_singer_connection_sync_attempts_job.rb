# frozen_string_literal: true

class Infrastructure::TruncateSingerConnectionSyncAttemptsJob < Que::Job
  def run
    SingerSyncAttempt.where("created_at < ?", 30.days.ago).delete_all
  end

  def log_level(_elapsed)
    :info
  end
end

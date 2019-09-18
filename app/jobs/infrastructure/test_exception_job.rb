# frozen_string_literal: true

class Infrastructure::TestExceptionJob < Que::Job
  def run
    1 / 0
  end
end

class Todos::DiscardScratchpad
  def initialize(account, user)
    @account = account
    @user = user
  end

  def discard(scratchpad)
    success = Scratchpad.transaction do
      scratchpad.discard
      true
    end

    if success
      return scratchpad, nil
    else
      return nil, scratchpad.errors
    end
  end
end

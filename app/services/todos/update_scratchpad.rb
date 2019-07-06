class Todos::UpdateScratchpad
  def initialize(account, user)
    @account = account
    @user = user
  end

  def update(scratchpad, attributes)
    success = Scratchpad.transaction do
      scratchpad.assign_attributes(attributes)
      Todos::StatsTracker.track_all(scratchpad)
      infer_scratchpad_name(scratchpad)
      scratchpad.save
    end

    if success
      return scratchpad, nil
    else
      return nil, scratchpad.errors
    end
  end

  private

  def infer_scratchpad_name(scratchpad)
    doc = Slate::Doc.parse(scratchpad.document)
    first_text = nil
    first_node = doc.root["nodes"][0]
    if first_node.present?
      doc.visit(first_node) do |child|
        if child["object"] == "text"
          first_text ||= child["text"]
          false
        end
      end
    end

    first_text = "Scratchpad" if first_text.blank?
    scratchpad.name = first_text
  end
end

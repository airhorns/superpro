# frozen_string_literal: true

Trestle.resource(:snowplow_enrichment_errors) do
  menu do
    item :snowplow_enrichment_errors, icon: "fa fa-star"
  end
  scopes do
    scope :all, -> { SnowplowEnrichmentError.order("failure_tstamp DESC") }, default: true
  end

  table do
    column :failure_tstamp
    column :messages do |errors|
      content_tag :ul do
        errors.messages.each do |message|
          concat content_tag :li, message
        end
      end
    end
  end
end

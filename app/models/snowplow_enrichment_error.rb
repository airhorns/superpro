# frozen_string_literal: true

class SnowplowEnrichmentError < ApplicationRecord
  self.table_name = "warehouse.stg_snowplow_enrichment_errors"
  self.primary_key = "_sdc_primary_key"

  def readonly?
    true
  end
end

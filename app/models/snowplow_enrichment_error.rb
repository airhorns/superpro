# frozen_string_literal: true

# == Schema Information
#
# Table name: warehouse.stg_snowplow_enrichment_errors
#
#  _sdc_batched_at    :datetime
#  _sdc_primary_key   :text             primary key
#  _sdc_received_at   :datetime
#  _sdc_sequence      :bigint(8)
#  _sdc_table_version :bigint(8)
#  failure_tstamp     :datetime
#  line               :text
#  messages           :text             is an Array
#


class SnowplowEnrichmentError < ApplicationRecord
  self.table_name = "warehouse.stg_snowplow_enrichment_errors"
  self.primary_key = "_sdc_primary_key"

  def readonly?
    true
  end
end

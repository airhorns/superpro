# frozen_string_literal: true

module SingerSyncAttemptsHelper
  def self.logs_url(attempt)
    "https://console.cloud.google.com/logs/viewer?interval=NO_LIMIT&project=superpro-production&folder&organizationId&minLogLevel=0&expandAll=false&&customFacets=jsonPayload.event&limitCustomFacetWidth=false&advancedFilter=resource.type%3D%22container%22%0Aresource.labels.cluster_name%3D%22alpha%22%0Aresource.labels.namespace_id%3D%22singer-importer-production%22%0Aresource.labels.project_id%3D%22superpro-production%22%0Aresource.labels.zone:%22us-central1-a%22%0Aresource.labels.container_name%3D%22web%22%0AjsonPayload.import_id%3D%22#{attempt.id}%22&"
  end

  def self.global_logs_url(attempt)
    "https://console.cloud.google.com/logs/viewer?interval=NO_LIMIT&project=superpro-production&folder&organizationId&minLogLevel=0&expandAll=false&&customFacets=jsonPayload.event&limitCustomFacetWidth=false&advancedFilter=resource.type%3D%22container%22%0Aresource.labels.cluster_name%3D%22alpha%22%0Aresource.labels.namespace_id%3D%22singer-importer-production%22%0Aresource.labels.project_id%3D%22superpro-production%22%0Aresource.labels.zone:%22us-central1-a%22%0Aresource.labels.container_name%3D%22web%22%0AjsonPayload.global_import_id%3D%22#{attempt.id}%22&"
  end
end

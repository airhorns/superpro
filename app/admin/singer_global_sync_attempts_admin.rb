Trestle.resource(:singer_global_sync_attempts) do
  menu do
    item :singer_global_sync_attempts, icon: "fa fa-star"
  end

  scopes do
    scope :all, -> { SingerGlobalSyncAttempt.order("created_at DESC") }, default: true
    scope :failed, -> { SingerGlobalSyncAttempt.where("success IS NULL or success = false").order("created_at DESC") }
  end

  table do
    column :id
    column :key
    column :success
    column :started_at
    column :last_progress_at
    column :finished_at
    column :failure_reason
    column :links do |attempt|
      link_to "Logs", SingerSyncAttemptsHelper.logs_url(attempt), target: "_blank", rel: "noopener"
    end
  end
end

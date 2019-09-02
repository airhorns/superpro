Trestle.resource(:singer_sync_attempts) do
  menu do
    item :singer_sync_attempts, icon: "fa fa-star"
  end

  table do
    column :id
    column :account
    column :connection
    column :success
    column :started_at
    column :finished_at
    column :failure_reason
    column :links do |attempt|
      link_to "Logs", SingerSyncAttemptsHelper.logs_url(attempt), target: "_blank", rel: "noopener"
    end
  end
end

Trestle.resource(:connections) do
  menu do
    item :connections, icon: "fa fa-star"
  end

  table do
    column :id, link: true
    column :display_name, link: true
    column :enabled, link: false
    column :integration_type, link: false
    column :integration_id, link: false
    column :integration, link: false
    column :created_at, link: false
  end

  form do |connection|
    tab :connection do
      text_field :display_name
      static_field :strategy, connection.strategy
      static_field :integration_type, connection.integration_type
      static_field :integration_id, connection.integration_id
      static_field :created_at, connection.created_at
      static_field :updated_at, connection.updated_at
    end

    tab :attempts, badge: connection.singer_sync_attempts.size do
      table connection.singer_sync_attempts.order("created_at DESC"), admin: :singer_sync_attempts do
        column :started_at
        column :finished_at
        column :success
        column :failure_reason
        column :links do |attempt|
          link_to "Logs", SingerSyncAttemptsHelper.logs_url(attempt), target: "_blank", rel: "noopener"
        end
      end
    end
  end
end

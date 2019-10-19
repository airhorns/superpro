Trestle.admin(:infrastructure, path: "infrastructure") do
  menu do
    item :infrastructure, icon: "fa fa-flag"
  end

  controller do
    def run_periodic_global_sync
      Infrastructure::PeriodicSyncAllGlobalConnectionsJob.enqueue
      flash[:message] = "Global connection sync job enqueued"
      redirect_to admin.path
    end

    def run_periodic_connection_sync
      Infrastructure::PeriodicSyncAllConnectionsJob.enqueue
      flash[:message] = "All connections sync job enqueued"
      redirect_to admin.path
    end
  end

  routes do
    post :run_periodic_global_sync
    post :run_periodic_connection_sync
  end
end

Trestle.admin(:sidekiq, path: "sidekiq") do
  menu do
    group :linkies, priority: 100 do
      item :sidekiq, icon: "fa fa-server"
    end
  end
end

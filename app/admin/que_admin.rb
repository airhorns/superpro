# frozen_string_literal: true

Trestle.admin(:que, path: "que") do
  menu do
    group :linkies, priority: 100 do
      item :que, icon: "fa fa-server"
    end
  end
end

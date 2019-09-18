# frozen_string_literal: true

Trestle.admin(:flipper, path: "flipper") do
  menu do
    group :linkies, priority: 100 do
      item :flipper, icon: "fa fa-flag"
    end
  end
end

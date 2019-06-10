# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_06_10_221752) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_user_permissions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "creator_id", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["discarded_at"], name: "index_accounts_on_discarded_at"
  end

  create_table "budget_line_scenarios", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "budget_line_id", null: false
    t.string "scenario", null: false
    t.string "currency", null: false
    t.bigint "amount_subunits", null: false
    t.bigint "series_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id", "budget_line_id"], name: "index_budget_line_scenarios_on_account_id_and_budget_line_id"
  end

  create_table "budget_lines", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "creator_id", null: false
    t.bigint "budget_id", null: false
    t.string "description", null: false
    t.string "section", null: false
    t.string "recurrence_rules", array: true
    t.integer "sort_order", default: 1, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "budgets", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "creator_id", null: false
    t.string "name", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "cells", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "series_id", null: false
    t.decimal "x_number"
    t.string "x_string"
    t.datetime "x_datetime"
    t.integer "y_money_subunits"
    t.decimal "y_number"
    t.string "y_string"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id", "series_id"], name: "index_cells_on_account_id_and_series_id"
  end

# Could not dump table "series" because of following StandardError
#   Unknown type 'series_x_type' for column 'x_type'

  create_table "users", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "account_user_permissions", "accounts"
  add_foreign_key "account_user_permissions", "users"
  add_foreign_key "accounts", "users", column: "creator_id"
  add_foreign_key "budget_line_scenarios", "accounts"
  add_foreign_key "budget_line_scenarios", "budget_lines"
  add_foreign_key "budget_lines", "accounts"
  add_foreign_key "budget_lines", "budgets"
  add_foreign_key "budget_lines", "users", column: "creator_id"
  add_foreign_key "budgets", "accounts"
  add_foreign_key "budgets", "users", column: "creator_id"
  add_foreign_key "cells", "accounts"
  add_foreign_key "cells", "series"
  add_foreign_key "series", "accounts"
  add_foreign_key "series", "users", column: "creator_id"
end

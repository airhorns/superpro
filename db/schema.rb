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

ActiveRecord::Schema.define(version: 2019_06_13_215004) do

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
    t.datetime "occurs_at", null: false
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

  create_table "series", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "scenario", null: false
    t.string "x_type", null: false
    t.string "y_type", null: false
    t.string "currency"
    t.bigint "creator_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id", "scenario"], name: "index_series_on_account_id_and_scenario"
  end

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

  create_view "budget_forecast_totals", sql_definition: <<-SQL
      WITH cell_details AS (
           SELECT cells.x_datetime AS cell_at,
              cells.y_money_subunits AS amount_subunits,
              (budget_line_scenarios.amount_subunits > 0) AS is_revenue,
              series.id AS series_id,
              budget_line_scenarios.scenario,
              budget_lines.id AS budget_line_id,
              budget_lines.budget_id
             FROM (((cells
               JOIN series ON ((series.id = cells.series_id)))
               JOIN budget_line_scenarios ON ((budget_line_scenarios.series_id = series.id)))
               JOIN budget_lines ON ((budget_lines.id = budget_line_scenarios.budget_line_id)))
          ), active_scenarios AS (
           SELECT DISTINCT cell_details.scenario,
              cell_details.budget_id
             FROM cell_details
          ), running_totals AS (
           SELECT cell_details.cell_at,
              cell_details.scenario,
              cell_details.series_id,
              cell_details.budget_id,
              sum(
                  CASE cell_details.is_revenue
                      WHEN true THEN cell_details.amount_subunits
                      ELSE 0
                  END) OVER (PARTITION BY cell_details.scenario ORDER BY cell_details.cell_at) AS running_revenue_total,
              sum(
                  CASE cell_details.is_revenue
                      WHEN false THEN cell_details.amount_subunits
                      ELSE 0
                  END) OVER (PARTITION BY cell_details.scenario ORDER BY cell_details.cell_at) AS running_expenses_total,
              sum(cell_details.amount_subunits) OVER (PARTITION BY cell_details.scenario ORDER BY cell_details.cell_at) AS cash_on_hand
             FROM cell_details
          ), weeks AS (
           SELECT (date_trunc('week'::text, t.week_start))::date AS week_start
             FROM generate_series(('2019-01-01 00:00:00'::timestamp without time zone)::timestamp with time zone, (now() + '2 years'::interval), '7 days'::interval) t(week_start)
          ), totals_by_week AS (
           SELECT active_scenarios.budget_id,
              active_scenarios.scenario,
              weeks.week_start,
              (array_agg(running_totals.cash_on_hand))[1] AS cash_on_hand,
              (array_agg(running_totals.running_revenue_total))[1] AS running_revenue_total,
              (array_agg(running_totals.running_expenses_total))[1] AS running_expenses_total
             FROM ((weeks
               CROSS JOIN active_scenarios)
               LEFT JOIN running_totals ON ((((date_trunc('week'::text, running_totals.cell_at))::date = weeks.week_start) AND (running_totals.budget_id = active_scenarios.budget_id) AND ((running_totals.scenario)::text = (active_scenarios.scenario)::text))))
            GROUP BY active_scenarios.budget_id, active_scenarios.scenario, weeks.week_start
            ORDER BY weeks.week_start
          ), gapfilled_totals_by_week AS (
           SELECT totals_by_week.budget_id,
              totals_by_week.scenario,
              totals_by_week.week_start,
              COALESCE(gapfill(totals_by_week.cash_on_hand) OVER (PARTITION BY totals_by_week.budget_id, totals_by_week.scenario ORDER BY totals_by_week.week_start), (0)::bigint) AS cash_on_hand,
              COALESCE(gapfill(totals_by_week.running_revenue_total) OVER (PARTITION BY totals_by_week.budget_id, totals_by_week.scenario ORDER BY totals_by_week.week_start), (0)::bigint) AS running_revenue_total,
              COALESCE(gapfill(totals_by_week.running_expenses_total) OVER (PARTITION BY totals_by_week.budget_id, totals_by_week.scenario ORDER BY totals_by_week.week_start), (0)::bigint) AS running_expenses_total
             FROM totals_by_week
          )
   SELECT gapfilled_totals_by_week.budget_id,
      gapfilled_totals_by_week.scenario,
      gapfilled_totals_by_week.week_start,
      gapfilled_totals_by_week.cash_on_hand,
      gapfilled_totals_by_week.running_revenue_total,
      gapfilled_totals_by_week.running_expenses_total
     FROM gapfilled_totals_by_week;
  SQL
  create_view "cell_details", sql_definition: <<-SQL
      SELECT cells.x_datetime AS cell_at,
      cells.y_money_subunits AS amount_subunits,
      (cells.y_money_subunits > 0) AS is_revenue,
      cells.updated_at,
      series.id AS series_id,
      budget_line_scenarios.scenario,
      budget_lines.id AS budget_line_id,
      budget_lines.section,
      budget_lines.description AS line_name,
      budget_lines.budget_id,
      budget_lines.account_id
     FROM (((cells
       JOIN series ON ((series.id = cells.series_id)))
       JOIN budget_line_scenarios ON ((budget_line_scenarios.series_id = series.id)))
       JOIN budget_lines ON ((budget_lines.id = budget_line_scenarios.budget_line_id)));
  SQL
  create_view "budget_forecasts", sql_definition: <<-SQL
      WITH active_scenarios AS (
           SELECT DISTINCT cell_details.scenario,
              cell_details.budget_id,
              cell_details.account_id
             FROM cell_details
          ), running_totals AS (
           SELECT cell_details.cell_at,
              cell_details.scenario,
              cell_details.series_id,
              cell_details.budget_id,
              cell_details.account_id,
              sum(
                  CASE cell_details.is_revenue
                      WHEN true THEN cell_details.amount_subunits
                      ELSE 0
                  END) OVER (PARTITION BY cell_details.scenario ORDER BY cell_details.cell_at) AS running_revenue_total,
              sum(
                  CASE cell_details.is_revenue
                      WHEN false THEN cell_details.amount_subunits
                      ELSE 0
                  END) OVER (PARTITION BY cell_details.scenario ORDER BY cell_details.cell_at) AS running_expenses_total,
              sum(cell_details.amount_subunits) OVER (PARTITION BY cell_details.scenario ORDER BY cell_details.cell_at) AS cash_on_hand
             FROM cell_details
          ), weeks AS (
           SELECT (date_trunc('week'::text, t.week_start))::date AS week_start
             FROM generate_series(('2019-01-01 00:00:00'::timestamp without time zone)::timestamp with time zone, (now() + '2 years'::interval), '7 days'::interval) t(week_start)
          ), totals_by_week AS (
           SELECT active_scenarios.scenario,
              weeks.week_start,
              (array_agg(running_totals.cash_on_hand))[1] AS cash_on_hand,
              (array_agg(running_totals.running_revenue_total))[1] AS running_revenue_total,
              (array_agg(running_totals.running_expenses_total))[1] AS running_expenses_total,
              active_scenarios.account_id,
              active_scenarios.budget_id
             FROM ((weeks
               CROSS JOIN active_scenarios)
               LEFT JOIN running_totals ON ((((date_trunc('week'::text, running_totals.cell_at))::date = weeks.week_start) AND (running_totals.budget_id = active_scenarios.budget_id) AND ((running_totals.scenario)::text = (active_scenarios.scenario)::text))))
            GROUP BY active_scenarios.budget_id, active_scenarios.account_id, active_scenarios.scenario, weeks.week_start
            ORDER BY weeks.week_start
          ), gapfilled_totals_by_week AS (
           SELECT totals_by_week.budget_id,
              totals_by_week.account_id,
              totals_by_week.scenario,
              totals_by_week.week_start,
              COALESCE(gapfill(totals_by_week.cash_on_hand) OVER (PARTITION BY totals_by_week.budget_id, totals_by_week.scenario ORDER BY totals_by_week.week_start), (0)::bigint) AS cash_on_hand,
              COALESCE(gapfill(totals_by_week.running_revenue_total) OVER (PARTITION BY totals_by_week.budget_id, totals_by_week.scenario ORDER BY totals_by_week.week_start), (0)::bigint) AS running_revenue_total,
              COALESCE(gapfill(totals_by_week.running_expenses_total) OVER (PARTITION BY totals_by_week.budget_id, totals_by_week.scenario ORDER BY totals_by_week.week_start), (0)::bigint) AS running_expenses_total
             FROM totals_by_week
          )
   SELECT gapfilled_totals_by_week.budget_id,
      gapfilled_totals_by_week.account_id,
      gapfilled_totals_by_week.scenario,
      gapfilled_totals_by_week.week_start,
      gapfilled_totals_by_week.cash_on_hand,
      gapfilled_totals_by_week.running_revenue_total,
      gapfilled_totals_by_week.running_expenses_total
     FROM gapfilled_totals_by_week
    ORDER BY gapfilled_totals_by_week.week_start;
  SQL
  create_view "budget_problem_spots", sql_definition: <<-SQL
      WITH spot_grouped AS (
           SELECT budget_forecasts_flagged.budget_id,
              budget_forecasts_flagged.account_id,
              budget_forecasts_flagged.scenario,
              budget_forecasts_flagged.week_start,
              budget_forecasts_flagged.cash_on_hand,
              budget_forecasts_flagged.running_revenue_total,
              budget_forecasts_flagged.running_expenses_total,
              budget_forecasts_flagged.group_flag,
              sum(budget_forecasts_flagged.group_flag) OVER (ORDER BY budget_forecasts_flagged.week_start) AS spot_group
             FROM ( SELECT budget_forecasts.budget_id,
                      budget_forecasts.account_id,
                      budget_forecasts.scenario,
                      budget_forecasts.week_start,
                      budget_forecasts.cash_on_hand,
                      budget_forecasts.running_revenue_total,
                      budget_forecasts.running_expenses_total,
                          CASE
                              WHEN (lag(budget_forecasts.week_start) OVER (ORDER BY budget_forecasts.week_start) = (budget_forecasts.week_start - '7 days'::interval)) THEN NULL::integer
                              ELSE 1
                          END AS group_flag
                     FROM budget_forecasts
                    WHERE (budget_forecasts.cash_on_hand < 0)) budget_forecasts_flagged
          )
   SELECT spot_grouped.budget_id,
      spot_grouped.scenario,
      spot_grouped.spot_group AS spot_number,
      min(spot_grouped.week_start) AS start_date,
      max(spot_grouped.week_start) AS end_date,
      min(spot_grouped.cash_on_hand) AS min_cash_on_hand
     FROM spot_grouped
    GROUP BY spot_grouped.budget_id, spot_grouped.scenario, spot_grouped.spot_group;
  SQL
end

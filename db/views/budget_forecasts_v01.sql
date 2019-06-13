WITH

active_scenarios AS (
  SELECT DISTINCT scenario, budget_id from cell_details
),

running_totals AS (
  SELECT
    cell_at
    , scenario
    , series_id
    , budget_id
    , SUM(CASE is_revenue WHEN TRUE THEN amount_subunits ELSE 0 END) OVER (PARTITION BY scenario ORDER BY cell_at ASC) as running_revenue_total
    , SUM(CASE is_revenue WHEN FALSE THEN amount_subunits ELSE 0 END) OVER (PARTITION BY scenario ORDER BY cell_at ASC) as running_expenses_total
    , SUM(amount_subunits) OVER (PARTITION BY scenario ORDER BY cell_at ASC) AS cash_on_hand
  FROM cell_details
),

weeks AS (
  SELECT date_trunc('week', week_start)::date as week_start FROM generate_series(timestamp '2019-01-01', NOW() + interval '2 years', interval '1 week') AS t(week_start)
),

totals_by_week as (
  SELECT
    active_scenarios.budget_id
    , active_scenarios.scenario
    ,  week_start
    , (array_agg(cash_on_hand))[1] as cash_on_hand
    , (array_agg(running_revenue_total))[1] as running_revenue_total
    , (array_agg(running_expenses_total))[1] as running_expenses_total
  FROM weeks
  CROSS JOIN active_scenarios
  LEFT JOIN running_totals ON date_trunc('week', running_totals.cell_at)::date = week_start AND running_totals.budget_id = active_scenarios.budget_id AND running_totals.scenario = active_scenarios.scenario
  GROUP BY active_scenarios.budget_id, active_scenarios.scenario, week_start
  ORDER BY week_start
),

gapfilled_totals_by_week as (
  SELECT
    budget_id
    , scenario
    , week_start
    , COALESCE(gapfill(cash_on_hand) OVER (PARTITION BY budget_id, scenario ORDER BY week_start ASC), 0) as cash_on_hand
    , COALESCE(gapfill(running_revenue_total) OVER (PARTITION BY budget_id, scenario ORDER BY week_start ASC), 0) as running_revenue_total
    , COALESCE(gapfill(running_expenses_total) OVER (PARTITION BY budget_id, scenario ORDER BY week_start ASC), 0) as running_expenses_total
  FROM totals_by_week
)

SELECT * from gapfilled_totals_by_week ORDER BY week_start
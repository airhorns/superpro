SELECT
  cells.x_datetime AS cell_at
  , cells.y_money_subunits AS amount_subunits
  , cells.y_money_subunits > 0 AS is_revenue
  , cells.updated_at as updated_at
  , series.id AS series_id
  , budget_line_scenarios.scenario AS scenario
  , budget_lines.id AS budget_line_id
  , budget_lines.section as section
  , budget_lines.description as line_name
  , budget_lines.budget_id AS budget_id
FROM cells
INNER JOIN series ON series.id = cells.series_id
INNER JOIN budget_line_scenarios ON budget_line_scenarios.series_id = series.id
INNER JOIN budget_lines ON budget_lines.id = budget_line_scenarios.budget_line_id
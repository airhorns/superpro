SELECT
  cells.x_datetime AS cell_at
  , cells.y_money_subunits AS amount_subunits
  , cells.y_money_subunits > 0 AS is_revenue
  , cells.updated_at as updated_at
  , cells.scenario AS scenario
  , series.id AS series_id
  , budget_lines.id AS budget_line_id
  , budget_lines.section as section
  , budget_lines.description as line_name
  , budget_lines.budget_id AS budget_id
  , budget_lines.account_id AS account_id
FROM cells
INNER JOIN series ON series.id = cells.series_id
INNER JOIN budget_lines ON budget_lines.series_id = series.id
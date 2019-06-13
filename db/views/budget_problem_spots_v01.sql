WITH spot_grouped AS (
  SELECT
    budget_forecasts_flagged.*
    , SUM(group_flag) OVER (ORDER BY week_start) as spot_group
  FROM (
    SELECT *, CASE
    WHEN lag(week_start) over (ORDER BY week_start) = week_start - interval '1 week' THEN NULL
      ELSE 1
    END AS group_flag
    FROM budget_forecasts WHERE cash_on_hand < 0
  ) budget_forecasts_flagged
)

SELECT
  budget_id
  , scenario
  , spot_group as spot_number
  , MIN(week_start) AS start_date
  , MAX(week_start) AS end_date
  , MIN(cash_on_hand) AS min_cash_on_hand
FROM spot_grouped
GROUP BY budget_id, scenario, spot_group
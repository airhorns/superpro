(
  SELECT
    CONCAT('process_execution-', id) as id
    , account_id AS account_id
    , 'public' as access_mode
    , creator_id
    , name
    , 'ProcessExecution' AS todo_source_type
    , id AS todo_source_id
    , created_at
    , updated_at
    , started_at
  FROM
    process_executions
  WHERE
    started_at IS NOT NULL
    AND discarded_at IS NULL
)
UNION
(
  SELECT
    CONCAT('scratchpad-', id) as id
    , account_id AS account_id
    , access_mode
    , creator_id
    , name
    , 'Scratchpad' AS todo_source_type
    , id AS todo_source_id
    , created_at
    , updated_at
    , created_at AS started_at
  FROM
    scratchpads
  WHERE
    discarded_at IS NULL
)
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: dbt_harry; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA dbt_harry;


--
-- Name: tap_google_analytics; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tap_google_analytics;


--
-- Name: tap_shopify; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tap_shopify;


--
-- Name: warehouse; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA warehouse;


--
-- Name: gapfillinternal(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gapfillinternal(s anyelement, v anyelement) RETURNS anyelement
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  RETURN COALESCE(v,s);
END;
$$;


--
-- Name: que_validate_tags(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.que_validate_tags(tags_array jsonb) RETURNS boolean
    LANGUAGE sql
    AS $$
  SELECT bool_and(
    jsonb_typeof(value) = 'string'
    AND
    char_length(value::text) <= 100
  )
  FROM jsonb_array_elements(tags_array)
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: que_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.que_jobs (
    priority smallint DEFAULT 100 NOT NULL,
    run_at timestamp with time zone DEFAULT now() NOT NULL,
    id bigint NOT NULL,
    job_class text NOT NULL,
    error_count integer DEFAULT 0 NOT NULL,
    last_error_message text,
    queue text DEFAULT 'default'::text NOT NULL,
    last_error_backtrace text,
    finished_at timestamp with time zone,
    expired_at timestamp with time zone,
    args jsonb DEFAULT '[]'::jsonb NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT error_length CHECK (((char_length(last_error_message) <= 500) AND (char_length(last_error_backtrace) <= 10000))),
    CONSTRAINT job_class_length CHECK ((char_length(
CASE job_class
    WHEN 'ActiveJob::QueueAdapters::QueAdapter::JobWrapper'::text THEN ((args -> 0) ->> 'job_class'::text)
    ELSE job_class
END) <= 200)),
    CONSTRAINT queue_length CHECK ((char_length(queue) <= 100)),
    CONSTRAINT valid_args CHECK ((jsonb_typeof(args) = 'array'::text)),
    CONSTRAINT valid_data CHECK (((jsonb_typeof(data) = 'object'::text) AND ((NOT (data ? 'tags'::text)) OR ((jsonb_typeof((data -> 'tags'::text)) = 'array'::text) AND (jsonb_array_length((data -> 'tags'::text)) <= 5) AND public.que_validate_tags((data -> 'tags'::text))))))
)
WITH (fillfactor='90');


--
-- Name: TABLE que_jobs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.que_jobs IS '4';


--
-- Name: que_determine_job_state(public.que_jobs); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.que_determine_job_state(job public.que_jobs) RETURNS text
    LANGUAGE sql
    AS $$
  SELECT
    CASE
    WHEN job.expired_at  IS NOT NULL    THEN 'expired'
    WHEN job.finished_at IS NOT NULL    THEN 'finished'
    WHEN job.error_count > 0            THEN 'errored'
    WHEN job.run_at > CURRENT_TIMESTAMP THEN 'scheduled'
    ELSE                                     'ready'
    END
$$;


--
-- Name: que_job_notify(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.que_job_notify() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    locker_pid integer;
    sort_key json;
  BEGIN
    -- Don't do anything if the job is scheduled for a future time.
    IF NEW.run_at IS NOT NULL AND NEW.run_at > now() THEN
      RETURN null;
    END IF;

    -- Pick a locker to notify of the job's insertion, weighted by their number
    -- of workers. Should bounce pseudorandomly between lockers on each
    -- invocation, hence the md5-ordering, but still touch each one equally,
    -- hence the modulo using the job_id.
    SELECT pid
    INTO locker_pid
    FROM (
      SELECT *, last_value(row_number) OVER () + 1 AS count
      FROM (
        SELECT *, row_number() OVER () - 1 AS row_number
        FROM (
          SELECT *
          FROM public.que_lockers ql, generate_series(1, ql.worker_count) AS id
          WHERE listening AND queues @> ARRAY[NEW.queue]
          ORDER BY md5(pid::text || id::text)
        ) t1
      ) t2
    ) t3
    WHERE NEW.id % count = row_number;

    IF locker_pid IS NOT NULL THEN
      -- There's a size limit to what can be broadcast via LISTEN/NOTIFY, so
      -- rather than throw errors when someone enqueues a big job, just
      -- broadcast the most pertinent information, and let the locker query for
      -- the record after it's taken the lock. The worker will have to hit the
      -- DB in order to make sure the job is still visible anyway.
      SELECT row_to_json(t)
      INTO sort_key
      FROM (
        SELECT
          'job_available' AS message_type,
          NEW.queue       AS queue,
          NEW.priority    AS priority,
          NEW.id          AS id,
          -- Make sure we output timestamps as UTC ISO 8601
          to_char(NEW.run_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS run_at
      ) t;

      PERFORM pg_notify('que_listener_' || locker_pid::text, sort_key::text);
    END IF;

    RETURN null;
  END
$$;


--
-- Name: que_state_notify(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.que_state_notify() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    row record;
    message json;
    previous_state text;
    current_state text;
  BEGIN
    IF TG_OP = 'INSERT' THEN
      previous_state := 'nonexistent';
      current_state  := public.que_determine_job_state(NEW);
      row            := NEW;
    ELSIF TG_OP = 'DELETE' THEN
      previous_state := public.que_determine_job_state(OLD);
      current_state  := 'nonexistent';
      row            := OLD;
    ELSIF TG_OP = 'UPDATE' THEN
      previous_state := public.que_determine_job_state(OLD);
      current_state  := public.que_determine_job_state(NEW);

      -- If the state didn't change, short-circuit.
      IF previous_state = current_state THEN
        RETURN null;
      END IF;

      row := NEW;
    ELSE
      RAISE EXCEPTION 'Unrecognized TG_OP: %', TG_OP;
    END IF;

    SELECT row_to_json(t)
    INTO message
    FROM (
      SELECT
        'job_change' AS message_type,
        row.id       AS id,
        row.queue    AS queue,

        coalesce(row.data->'tags', '[]'::jsonb) AS tags,

        to_char(row.run_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS run_at,
        to_char(now()      AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS time,

        CASE row.job_class
        WHEN 'ActiveJob::QueueAdapters::QueAdapter::JobWrapper' THEN
          coalesce(
            row.args->0->>'job_class',
            'ActiveJob::QueueAdapters::QueAdapter::JobWrapper'
          )
        ELSE
          row.job_class
        END AS job_class,

        previous_state AS previous_state,
        current_state  AS current_state
    ) t;

    PERFORM pg_notify('que_state', message::text);

    RETURN null;
  END
$$;


--
-- Name: gapfill(anyelement); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.gapfill(anyelement) (
    SFUNC = public.gapfillinternal,
    STYPE = anyelement
);


--
-- Name: account_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_user_permissions (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: account_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_user_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_user_permissions_id_seq OWNED BY public.account_user_permissions.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id bigint NOT NULL,
    name character varying NOT NULL,
    creator_id bigint NOT NULL,
    discarded_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: budget_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budget_lines (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    budget_id bigint NOT NULL,
    description character varying NOT NULL,
    section character varying NOT NULL,
    sort_order integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    series_id bigint NOT NULL,
    fixed_budget_line_descriptor_id bigint,
    value_type character varying NOT NULL
);


--
-- Name: cells; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cells (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    series_id bigint NOT NULL,
    scenario character varying NOT NULL,
    x_number numeric,
    x_string character varying,
    x_datetime timestamp without time zone,
    y_money_subunits integer,
    y_number numeric,
    y_string character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: series; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.series (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    x_type character varying NOT NULL,
    y_type character varying NOT NULL,
    currency character varying,
    creator_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cell_details; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.cell_details AS
 SELECT cells.x_datetime AS cell_at,
    cells.y_money_subunits AS amount_subunits,
    (cells.y_money_subunits > 0) AS is_revenue,
    cells.updated_at,
    cells.scenario,
    series.id AS series_id,
    budget_lines.id AS budget_line_id,
    budget_lines.section,
    budget_lines.description AS line_name,
    budget_lines.budget_id,
    budget_lines.account_id
   FROM ((public.cells
     JOIN public.series ON ((series.id = cells.series_id)))
     JOIN public.budget_lines ON ((budget_lines.series_id = series.id)));


--
-- Name: budget_forecasts; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.budget_forecasts AS
 WITH active_scenarios AS (
         SELECT DISTINCT cell_details.scenario,
            cell_details.budget_id,
            cell_details.account_id
           FROM public.cell_details
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
           FROM public.cell_details
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
            COALESCE(public.gapfill(totals_by_week.cash_on_hand) OVER (PARTITION BY totals_by_week.budget_id, totals_by_week.scenario ORDER BY totals_by_week.week_start), (0)::bigint) AS cash_on_hand,
            COALESCE(public.gapfill(totals_by_week.running_revenue_total) OVER (PARTITION BY totals_by_week.budget_id, totals_by_week.scenario ORDER BY totals_by_week.week_start), (0)::bigint) AS running_revenue_total,
            COALESCE(public.gapfill(totals_by_week.running_expenses_total) OVER (PARTITION BY totals_by_week.budget_id, totals_by_week.scenario ORDER BY totals_by_week.week_start), (0)::bigint) AS running_expenses_total
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


--
-- Name: budget_line_scenarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budget_line_scenarios (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    fixed_budget_line_descriptor_id bigint NOT NULL,
    scenario character varying NOT NULL,
    currency character varying NOT NULL,
    amount_subunits bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: budget_line_scenarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.budget_line_scenarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: budget_line_scenarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.budget_line_scenarios_id_seq OWNED BY public.budget_line_scenarios.id;


--
-- Name: budget_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.budget_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: budget_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.budget_lines_id_seq OWNED BY public.budget_lines.id;


--
-- Name: budget_problem_spots; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.budget_problem_spots AS
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
                   FROM public.budget_forecasts
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


--
-- Name: budgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budgets (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    name character varying NOT NULL,
    discarded_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: budgets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.budgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: budgets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.budgets_id_seq OWNED BY public.budgets.id;


--
-- Name: cells_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cells_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cells_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cells_id_seq OWNED BY public.cells.id;


--
-- Name: connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connections (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    integration_id bigint NOT NULL,
    integration_type character varying NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    display_name character varying NOT NULL,
    strategy character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: connections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.connections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connections_id_seq OWNED BY public.connections.id;


--
-- Name: fixed_budget_line_descriptors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fixed_budget_line_descriptors (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    occurs_at timestamp without time zone NOT NULL,
    recurrence_rules character varying[],
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: fixed_budget_line_descriptors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fixed_budget_line_descriptors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fixed_budget_line_descriptors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fixed_budget_line_descriptors_id_seq OWNED BY public.fixed_budget_line_descriptors.id;


--
-- Name: flipper_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_features (
    id bigint NOT NULL,
    key character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: flipper_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_features_id_seq OWNED BY public.flipper_features.id;


--
-- Name: flipper_gates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_gates (
    id bigint NOT NULL,
    feature_key character varying NOT NULL,
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_gates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_gates_id_seq OWNED BY public.flipper_gates.id;


--
-- Name: google_analytics_credentials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.google_analytics_credentials (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    token character varying NOT NULL,
    refresh_token character varying NOT NULL,
    expires_at timestamp without time zone,
    grantor_name character varying NOT NULL,
    grantor_email character varying NOT NULL,
    configured boolean DEFAULT false NOT NULL,
    view_id bigint,
    view_name character varying,
    property_id bigint,
    property_name character varying,
    ga_account_id bigint,
    ga_account_name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: google_analytics_credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.google_analytics_credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: google_analytics_credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.google_analytics_credentials_id_seq OWNED BY public.google_analytics_credentials.id;


--
-- Name: plaid_item_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plaid_item_accounts (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    plaid_item_id bigint NOT NULL,
    plaid_account_identifier character varying NOT NULL,
    name character varying NOT NULL,
    type character varying NOT NULL,
    subtype character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: plaid_item_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plaid_item_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plaid_item_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plaid_item_accounts_id_seq OWNED BY public.plaid_item_accounts.id;


--
-- Name: plaid_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plaid_items (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    access_token character varying NOT NULL,
    item_id bigint NOT NULL,
    initial_update_complete boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: plaid_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plaid_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plaid_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plaid_items_id_seq OWNED BY public.plaid_items.id;


--
-- Name: plaid_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plaid_transactions (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    plaid_item_id bigint NOT NULL,
    plaid_account_identifier character varying NOT NULL,
    plaid_transaction_identifier character varying NOT NULL,
    category character varying[],
    category_id character varying,
    transaction_type character varying NOT NULL,
    name character varying NOT NULL,
    amount character varying NOT NULL,
    iso_currency_code character varying,
    unofficial_currency_code character varying,
    date date NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: plaid_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plaid_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plaid_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plaid_transactions_id_seq OWNED BY public.plaid_transactions.id;


--
-- Name: process_execution_involved_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_execution_involved_users (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    process_execution_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: process_execution_involved_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.process_execution_involved_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: process_execution_involved_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.process_execution_involved_users_id_seq OWNED BY public.process_execution_involved_users.id;


--
-- Name: process_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_executions (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    process_template_id bigint,
    name character varying NOT NULL,
    document json NOT NULL,
    started_at timestamp without time zone,
    discarded_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    closest_future_deadline timestamp without time zone,
    open_todo_count integer DEFAULT 0 NOT NULL,
    closed_todo_count integer DEFAULT 0 NOT NULL,
    total_todo_count integer DEFAULT 0 NOT NULL
);


--
-- Name: process_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.process_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: process_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.process_executions_id_seq OWNED BY public.process_executions.id;


--
-- Name: process_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_templates (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    name character varying NOT NULL,
    document json NOT NULL,
    discarded_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: process_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.process_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: process_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.process_templates_id_seq OWNED BY public.process_templates.id;


--
-- Name: que_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.que_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: que_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.que_jobs_id_seq OWNED BY public.que_jobs.id;


--
-- Name: que_lockers; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE public.que_lockers (
    pid integer NOT NULL,
    worker_count integer NOT NULL,
    worker_priorities integer[] NOT NULL,
    ruby_pid integer NOT NULL,
    ruby_hostname text NOT NULL,
    queues text[] NOT NULL,
    listening boolean NOT NULL,
    CONSTRAINT valid_queues CHECK (((array_ndims(queues) = 1) AND (array_length(queues, 1) IS NOT NULL))),
    CONSTRAINT valid_worker_priorities CHECK (((array_ndims(worker_priorities) = 1) AND (array_length(worker_priorities, 1) IS NOT NULL)))
);


--
-- Name: que_scheduler_audit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.que_scheduler_audit (
    scheduler_job_id bigint NOT NULL,
    executed_at timestamp with time zone NOT NULL
);


--
-- Name: TABLE que_scheduler_audit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.que_scheduler_audit IS '4';


--
-- Name: que_scheduler_audit_enqueued; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.que_scheduler_audit_enqueued (
    scheduler_job_id bigint NOT NULL,
    job_class character varying(255) NOT NULL,
    queue character varying(255),
    priority integer,
    args jsonb NOT NULL,
    job_id bigint,
    run_at timestamp with time zone
);


--
-- Name: que_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.que_values (
    key text NOT NULL,
    value jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT valid_value CHECK ((jsonb_typeof(value) = 'object'::text))
)
WITH (fillfactor='90');


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: scratchpads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scratchpads (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    name character varying NOT NULL,
    document json NOT NULL,
    open_todo_count integer DEFAULT 0 NOT NULL,
    closed_todo_count integer DEFAULT 0 NOT NULL,
    total_todo_count integer DEFAULT 0 NOT NULL,
    access_mode character varying NOT NULL,
    closest_future_deadline timestamp without time zone,
    discarded_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: scratchpads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scratchpads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scratchpads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scratchpads_id_seq OWNED BY public.scratchpads.id;


--
-- Name: series_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.series_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: series_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.series_id_seq OWNED BY public.series.id;


--
-- Name: shopify_shops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shopify_shops (
    id bigint NOT NULL,
    shopify_domain character varying NOT NULL,
    api_key character varying NOT NULL,
    password character varying NOT NULL,
    name character varying NOT NULL,
    shop_id bigint NOT NULL,
    account_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: shopify_shops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shopify_shops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shopify_shops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shopify_shops_id_seq OWNED BY public.shopify_shops.id;


--
-- Name: singer_sync_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.singer_sync_attempts (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    connection_id bigint NOT NULL,
    success boolean,
    started_at timestamp without time zone NOT NULL,
    finished_at timestamp without time zone,
    failure_reason character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    last_progress_at timestamp without time zone DEFAULT '2019-01-01 01:01:00'::timestamp without time zone NOT NULL
);


--
-- Name: singer_sync_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.singer_sync_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: singer_sync_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.singer_sync_attempts_id_seq OWNED BY public.singer_sync_attempts.id;


--
-- Name: singer_sync_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.singer_sync_states (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    connection_id bigint NOT NULL,
    state jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: singer_sync_states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.singer_sync_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: singer_sync_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.singer_sync_states_id_seq OWNED BY public.singer_sync_states.id;


--
-- Name: todo_feed_items; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.todo_feed_items AS
 SELECT concat('process_execution-', process_executions.id) AS id,
    process_executions.account_id,
    'public'::character varying AS access_mode,
    process_executions.creator_id,
    process_executions.name,
    'ProcessExecution'::text AS todo_source_type,
    process_executions.id AS todo_source_id,
    process_executions.created_at,
    process_executions.updated_at,
    process_executions.started_at
   FROM public.process_executions
  WHERE ((process_executions.started_at IS NOT NULL) AND (process_executions.discarded_at IS NULL))
UNION
 SELECT concat('scratchpad-', scratchpads.id) AS id,
    scratchpads.account_id,
    scratchpads.access_mode,
    scratchpads.creator_id,
    scratchpads.name,
    'Scratchpad'::text AS todo_source_type,
    scratchpads.id AS todo_source_id,
    scratchpads.created_at,
    scratchpads.updated_at,
    scratchpads.created_at AS started_at
   FROM public.scratchpads
  WHERE (scratchpads.discarded_at IS NULL);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    full_name character varying,
    email character varying NOT NULL,
    encrypted_password character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    invitation_token character varying,
    invitation_created_at timestamp without time zone,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_type character varying,
    invited_by_id bigint,
    invitations_count integer DEFAULT 0
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: daily_active_users; Type: TABLE; Schema: tap_google_analytics; Owner: -
--

CREATE TABLE tap_google_analytics.daily_active_users (
    ga_date text NOT NULL,
    ga_1dayusers bigint,
    report_start_date text NOT NULL,
    report_end_date text NOT NULL,
    account_id bigint NOT NULL,
    view_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE daily_active_users; Type: COMMENT; Schema: tap_google_analytics; Owner: -
--

COMMENT ON TABLE tap_google_analytics.daily_active_users IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["daily_active_users"], "to": "daily_active_users"}], "key_properties": ["ga_date"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_1dayusers": {"type": ["integer", "null"], "from": ["ga_1dayUsers"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: devices; Type: TABLE; Schema: tap_google_analytics; Owner: -
--

CREATE TABLE tap_google_analytics.devices (
    ga_date text NOT NULL,
    ga_devicecategory text NOT NULL,
    ga_operatingsystem text NOT NULL,
    ga_browser text NOT NULL,
    ga_users bigint,
    ga_newusers bigint,
    ga_sessions bigint,
    ga_sessionsperuser double precision,
    ga_avgsessionduration double precision,
    ga_pageviews bigint,
    ga_pageviewspersession double precision,
    ga_avgtimeonpage double precision,
    ga_bouncerate double precision,
    ga_exitrate double precision,
    report_start_date text NOT NULL,
    report_end_date text NOT NULL,
    account_id bigint NOT NULL,
    view_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE devices; Type: COMMENT; Schema: tap_google_analytics; Owner: -
--

COMMENT ON TABLE tap_google_analytics.devices IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["devices"], "to": "devices"}], "key_properties": ["ga_date", "ga_deviceCategory", "ga_operatingSystem", "ga_browser"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_devicecategory": {"type": ["string"], "from": ["ga_deviceCategory"]}, "ga_operatingsystem": {"type": ["string"], "from": ["ga_operatingSystem"]}, "ga_browser": {"type": ["string"], "from": ["ga_browser"]}, "ga_users": {"type": ["integer", "null"], "from": ["ga_users"]}, "ga_newusers": {"type": ["integer", "null"], "from": ["ga_newUsers"]}, "ga_sessions": {"type": ["integer", "null"], "from": ["ga_sessions"]}, "ga_sessionsperuser": {"type": ["number", "null"], "from": ["ga_sessionsPerUser"]}, "ga_avgsessionduration": {"type": ["number", "null"], "from": ["ga_avgSessionDuration"]}, "ga_pageviews": {"type": ["integer", "null"], "from": ["ga_pageviews"]}, "ga_pageviewspersession": {"type": ["number", "null"], "from": ["ga_pageviewsPerSession"]}, "ga_avgtimeonpage": {"type": ["number", "null"], "from": ["ga_avgTimeOnPage"]}, "ga_bouncerate": {"type": ["number", "null"], "from": ["ga_bounceRate"]}, "ga_exitrate": {"type": ["number", "null"], "from": ["ga_exitRate"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: locations; Type: TABLE; Schema: tap_google_analytics; Owner: -
--

CREATE TABLE tap_google_analytics.locations (
    ga_date text NOT NULL,
    ga_continent text NOT NULL,
    ga_subcontinent text NOT NULL,
    ga_country text NOT NULL,
    ga_region text NOT NULL,
    ga_metro text NOT NULL,
    ga_city text NOT NULL,
    ga_users bigint,
    ga_newusers bigint,
    ga_sessions bigint,
    ga_sessionsperuser double precision,
    ga_avgsessionduration double precision,
    ga_pageviews bigint,
    ga_pageviewspersession double precision,
    ga_avgtimeonpage double precision,
    ga_bouncerate double precision,
    ga_exitrate double precision,
    report_start_date text NOT NULL,
    report_end_date text NOT NULL,
    account_id bigint NOT NULL,
    view_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE locations; Type: COMMENT; Schema: tap_google_analytics; Owner: -
--

COMMENT ON TABLE tap_google_analytics.locations IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["locations"], "to": "locations"}], "key_properties": ["ga_date", "ga_continent", "ga_subContinent", "ga_country", "ga_region", "ga_metro", "ga_city"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_continent": {"type": ["string"], "from": ["ga_continent"]}, "ga_subcontinent": {"type": ["string"], "from": ["ga_subContinent"]}, "ga_country": {"type": ["string"], "from": ["ga_country"]}, "ga_region": {"type": ["string"], "from": ["ga_region"]}, "ga_metro": {"type": ["string"], "from": ["ga_metro"]}, "ga_city": {"type": ["string"], "from": ["ga_city"]}, "ga_users": {"type": ["integer", "null"], "from": ["ga_users"]}, "ga_newusers": {"type": ["integer", "null"], "from": ["ga_newUsers"]}, "ga_sessions": {"type": ["integer", "null"], "from": ["ga_sessions"]}, "ga_sessionsperuser": {"type": ["number", "null"], "from": ["ga_sessionsPerUser"]}, "ga_avgsessionduration": {"type": ["number", "null"], "from": ["ga_avgSessionDuration"]}, "ga_pageviews": {"type": ["integer", "null"], "from": ["ga_pageviews"]}, "ga_pageviewspersession": {"type": ["number", "null"], "from": ["ga_pageviewsPerSession"]}, "ga_avgtimeonpage": {"type": ["number", "null"], "from": ["ga_avgTimeOnPage"]}, "ga_bouncerate": {"type": ["number", "null"], "from": ["ga_bounceRate"]}, "ga_exitrate": {"type": ["number", "null"], "from": ["ga_exitRate"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: monthly_active_users; Type: TABLE; Schema: tap_google_analytics; Owner: -
--

CREATE TABLE tap_google_analytics.monthly_active_users (
    ga_date text NOT NULL,
    ga_30dayusers bigint,
    report_start_date text NOT NULL,
    report_end_date text NOT NULL,
    account_id bigint NOT NULL,
    view_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE monthly_active_users; Type: COMMENT; Schema: tap_google_analytics; Owner: -
--

COMMENT ON TABLE tap_google_analytics.monthly_active_users IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["monthly_active_users"], "to": "monthly_active_users"}], "key_properties": ["ga_date"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_30dayusers": {"type": ["integer", "null"], "from": ["ga_30dayUsers"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: pages; Type: TABLE; Schema: tap_google_analytics; Owner: -
--

CREATE TABLE tap_google_analytics.pages (
    ga_date text NOT NULL,
    ga_hostname text NOT NULL,
    ga_pagepath text NOT NULL,
    ga_pageviews bigint,
    ga_uniquepageviews bigint,
    ga_avgtimeonpage double precision,
    ga_entrances bigint,
    ga_entrancerate double precision,
    ga_bouncerate double precision,
    ga_exits bigint,
    ga_exitrate double precision,
    report_start_date text NOT NULL,
    report_end_date text NOT NULL,
    account_id bigint NOT NULL,
    view_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE pages; Type: COMMENT; Schema: tap_google_analytics; Owner: -
--

COMMENT ON TABLE tap_google_analytics.pages IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["pages"], "to": "pages"}], "key_properties": ["ga_date", "ga_hostname", "ga_pagePath"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_hostname": {"type": ["string"], "from": ["ga_hostname"]}, "ga_pagepath": {"type": ["string"], "from": ["ga_pagePath"]}, "ga_pageviews": {"type": ["integer", "null"], "from": ["ga_pageviews"]}, "ga_uniquepageviews": {"type": ["integer", "null"], "from": ["ga_uniquePageviews"]}, "ga_avgtimeonpage": {"type": ["number", "null"], "from": ["ga_avgTimeOnPage"]}, "ga_entrances": {"type": ["integer", "null"], "from": ["ga_entrances"]}, "ga_entrancerate": {"type": ["number", "null"], "from": ["ga_entranceRate"]}, "ga_bouncerate": {"type": ["number", "null"], "from": ["ga_bounceRate"]}, "ga_exits": {"type": ["integer", "null"], "from": ["ga_exits"]}, "ga_exitrate": {"type": ["number", "null"], "from": ["ga_exitRate"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: traffic_sources; Type: TABLE; Schema: tap_google_analytics; Owner: -
--

CREATE TABLE tap_google_analytics.traffic_sources (
    ga_date text NOT NULL,
    ga_source text NOT NULL,
    ga_medium text NOT NULL,
    ga_socialnetwork text NOT NULL,
    ga_users bigint,
    ga_newusers bigint,
    ga_sessions bigint,
    ga_sessionsperuser double precision,
    ga_avgsessionduration double precision,
    ga_pageviews bigint,
    ga_pageviewspersession double precision,
    ga_avgtimeonpage double precision,
    ga_bouncerate double precision,
    ga_exitrate double precision,
    report_start_date text NOT NULL,
    report_end_date text NOT NULL,
    account_id bigint NOT NULL,
    view_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE traffic_sources; Type: COMMENT; Schema: tap_google_analytics; Owner: -
--

COMMENT ON TABLE tap_google_analytics.traffic_sources IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["traffic_sources"], "to": "traffic_sources"}], "key_properties": ["ga_date", "ga_source", "ga_medium", "ga_socialNetwork"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_source": {"type": ["string"], "from": ["ga_source"]}, "ga_medium": {"type": ["string"], "from": ["ga_medium"]}, "ga_socialnetwork": {"type": ["string"], "from": ["ga_socialNetwork"]}, "ga_users": {"type": ["integer", "null"], "from": ["ga_users"]}, "ga_newusers": {"type": ["integer", "null"], "from": ["ga_newUsers"]}, "ga_sessions": {"type": ["integer", "null"], "from": ["ga_sessions"]}, "ga_sessionsperuser": {"type": ["number", "null"], "from": ["ga_sessionsPerUser"]}, "ga_avgsessionduration": {"type": ["number", "null"], "from": ["ga_avgSessionDuration"]}, "ga_pageviews": {"type": ["integer", "null"], "from": ["ga_pageviews"]}, "ga_pageviewspersession": {"type": ["number", "null"], "from": ["ga_pageviewsPerSession"]}, "ga_avgtimeonpage": {"type": ["number", "null"], "from": ["ga_avgTimeOnPage"]}, "ga_bouncerate": {"type": ["number", "null"], "from": ["ga_bounceRate"]}, "ga_exitrate": {"type": ["number", "null"], "from": ["ga_exitRate"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: website_overview; Type: TABLE; Schema: tap_google_analytics; Owner: -
--

CREATE TABLE tap_google_analytics.website_overview (
    ga_date text NOT NULL,
    ga_users bigint,
    ga_newusers bigint,
    ga_sessions bigint,
    ga_sessionsperuser double precision,
    ga_avgsessionduration double precision,
    ga_pageviews bigint,
    ga_pageviewspersession double precision,
    ga_avgtimeonpage double precision,
    ga_bouncerate double precision,
    ga_exitrate double precision,
    report_start_date text NOT NULL,
    report_end_date text NOT NULL,
    account_id bigint NOT NULL,
    view_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE website_overview; Type: COMMENT; Schema: tap_google_analytics; Owner: -
--

COMMENT ON TABLE tap_google_analytics.website_overview IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["website_overview"], "to": "website_overview"}], "key_properties": ["ga_date"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_users": {"type": ["integer", "null"], "from": ["ga_users"]}, "ga_newusers": {"type": ["integer", "null"], "from": ["ga_newUsers"]}, "ga_sessions": {"type": ["integer", "null"], "from": ["ga_sessions"]}, "ga_sessionsperuser": {"type": ["number", "null"], "from": ["ga_sessionsPerUser"]}, "ga_avgsessionduration": {"type": ["number", "null"], "from": ["ga_avgSessionDuration"]}, "ga_pageviews": {"type": ["integer", "null"], "from": ["ga_pageviews"]}, "ga_pageviewspersession": {"type": ["number", "null"], "from": ["ga_pageviewsPerSession"]}, "ga_avgtimeonpage": {"type": ["number", "null"], "from": ["ga_avgTimeOnPage"]}, "ga_bouncerate": {"type": ["number", "null"], "from": ["ga_bounceRate"]}, "ga_exitrate": {"type": ["number", "null"], "from": ["ga_exitRate"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: weekly_active_users; Type: TABLE; Schema: tap_google_analytics; Owner: -
--

CREATE TABLE tap_google_analytics.weekly_active_users (
    ga_date text NOT NULL,
    ga_7dayusers bigint,
    report_start_date text NOT NULL,
    report_end_date text NOT NULL,
    account_id bigint NOT NULL,
    view_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE weekly_active_users; Type: COMMENT; Schema: tap_google_analytics; Owner: -
--

COMMENT ON TABLE tap_google_analytics.weekly_active_users IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["weekly_active_users"], "to": "weekly_active_users"}], "key_properties": ["ga_date"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_7dayusers": {"type": ["integer", "null"], "from": ["ga_7dayUsers"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: account_user_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_user_permissions ALTER COLUMN id SET DEFAULT nextval('public.account_user_permissions_id_seq'::regclass);


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: budget_line_scenarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_line_scenarios ALTER COLUMN id SET DEFAULT nextval('public.budget_line_scenarios_id_seq'::regclass);


--
-- Name: budget_lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_lines ALTER COLUMN id SET DEFAULT nextval('public.budget_lines_id_seq'::regclass);


--
-- Name: budgets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets ALTER COLUMN id SET DEFAULT nextval('public.budgets_id_seq'::regclass);


--
-- Name: cells id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cells ALTER COLUMN id SET DEFAULT nextval('public.cells_id_seq'::regclass);


--
-- Name: connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections ALTER COLUMN id SET DEFAULT nextval('public.connections_id_seq'::regclass);


--
-- Name: fixed_budget_line_descriptors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_budget_line_descriptors ALTER COLUMN id SET DEFAULT nextval('public.fixed_budget_line_descriptors_id_seq'::regclass);


--
-- Name: flipper_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features ALTER COLUMN id SET DEFAULT nextval('public.flipper_features_id_seq'::regclass);


--
-- Name: flipper_gates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates ALTER COLUMN id SET DEFAULT nextval('public.flipper_gates_id_seq'::regclass);


--
-- Name: google_analytics_credentials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.google_analytics_credentials ALTER COLUMN id SET DEFAULT nextval('public.google_analytics_credentials_id_seq'::regclass);


--
-- Name: plaid_item_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_item_accounts ALTER COLUMN id SET DEFAULT nextval('public.plaid_item_accounts_id_seq'::regclass);


--
-- Name: plaid_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_items ALTER COLUMN id SET DEFAULT nextval('public.plaid_items_id_seq'::regclass);


--
-- Name: plaid_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_transactions ALTER COLUMN id SET DEFAULT nextval('public.plaid_transactions_id_seq'::regclass);


--
-- Name: process_execution_involved_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_execution_involved_users ALTER COLUMN id SET DEFAULT nextval('public.process_execution_involved_users_id_seq'::regclass);


--
-- Name: process_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_executions ALTER COLUMN id SET DEFAULT nextval('public.process_executions_id_seq'::regclass);


--
-- Name: process_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_templates ALTER COLUMN id SET DEFAULT nextval('public.process_templates_id_seq'::regclass);


--
-- Name: que_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.que_jobs ALTER COLUMN id SET DEFAULT nextval('public.que_jobs_id_seq'::regclass);


--
-- Name: scratchpads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scratchpads ALTER COLUMN id SET DEFAULT nextval('public.scratchpads_id_seq'::regclass);


--
-- Name: series id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.series ALTER COLUMN id SET DEFAULT nextval('public.series_id_seq'::regclass);


--
-- Name: shopify_shops id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopify_shops ALTER COLUMN id SET DEFAULT nextval('public.shopify_shops_id_seq'::regclass);


--
-- Name: singer_sync_attempts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_sync_attempts ALTER COLUMN id SET DEFAULT nextval('public.singer_sync_attempts_id_seq'::regclass);


--
-- Name: singer_sync_states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_sync_states ALTER COLUMN id SET DEFAULT nextval('public.singer_sync_states_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: account_user_permissions account_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_user_permissions
    ADD CONSTRAINT account_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: budget_line_scenarios budget_line_scenarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_line_scenarios
    ADD CONSTRAINT budget_line_scenarios_pkey PRIMARY KEY (id);


--
-- Name: budget_lines budget_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_lines
    ADD CONSTRAINT budget_lines_pkey PRIMARY KEY (id);


--
-- Name: budgets budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets
    ADD CONSTRAINT budgets_pkey PRIMARY KEY (id);


--
-- Name: cells cells_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cells
    ADD CONSTRAINT cells_pkey PRIMARY KEY (id);


--
-- Name: connections connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (id);


--
-- Name: fixed_budget_line_descriptors fixed_budget_line_descriptors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_budget_line_descriptors
    ADD CONSTRAINT fixed_budget_line_descriptors_pkey PRIMARY KEY (id);


--
-- Name: flipper_features flipper_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features
    ADD CONSTRAINT flipper_features_pkey PRIMARY KEY (id);


--
-- Name: flipper_gates flipper_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates
    ADD CONSTRAINT flipper_gates_pkey PRIMARY KEY (id);


--
-- Name: google_analytics_credentials google_analytics_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.google_analytics_credentials
    ADD CONSTRAINT google_analytics_credentials_pkey PRIMARY KEY (id);


--
-- Name: plaid_item_accounts plaid_item_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_item_accounts
    ADD CONSTRAINT plaid_item_accounts_pkey PRIMARY KEY (id);


--
-- Name: plaid_items plaid_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_items
    ADD CONSTRAINT plaid_items_pkey PRIMARY KEY (id);


--
-- Name: plaid_transactions plaid_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_transactions
    ADD CONSTRAINT plaid_transactions_pkey PRIMARY KEY (id);


--
-- Name: process_execution_involved_users process_execution_involved_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_execution_involved_users
    ADD CONSTRAINT process_execution_involved_users_pkey PRIMARY KEY (id);


--
-- Name: process_executions process_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_executions
    ADD CONSTRAINT process_executions_pkey PRIMARY KEY (id);


--
-- Name: process_templates process_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_templates
    ADD CONSTRAINT process_templates_pkey PRIMARY KEY (id);


--
-- Name: que_jobs que_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.que_jobs
    ADD CONSTRAINT que_jobs_pkey PRIMARY KEY (id);


--
-- Name: que_lockers que_lockers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.que_lockers
    ADD CONSTRAINT que_lockers_pkey PRIMARY KEY (pid);


--
-- Name: que_scheduler_audit que_scheduler_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.que_scheduler_audit
    ADD CONSTRAINT que_scheduler_audit_pkey PRIMARY KEY (scheduler_job_id);


--
-- Name: que_values que_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.que_values
    ADD CONSTRAINT que_values_pkey PRIMARY KEY (key);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: scratchpads scratchpads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scratchpads
    ADD CONSTRAINT scratchpads_pkey PRIMARY KEY (id);


--
-- Name: series series_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.series
    ADD CONSTRAINT series_pkey PRIMARY KEY (id);


--
-- Name: shopify_shops shopify_shops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopify_shops
    ADD CONSTRAINT shopify_shops_pkey PRIMARY KEY (id);


--
-- Name: singer_sync_attempts singer_sync_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_sync_attempts
    ADD CONSTRAINT singer_sync_attempts_pkey PRIMARY KEY (id);


--
-- Name: singer_sync_states singer_sync_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_sync_states
    ADD CONSTRAINT singer_sync_states_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_scenarios_to_fixed_descriptors; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scenarios_to_fixed_descriptors ON public.budget_line_scenarios USING btree (account_id, fixed_budget_line_descriptor_id);


--
-- Name: index_accounts_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_discarded_at ON public.accounts USING btree (discarded_at);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_cells_on_account_id_and_series_id_and_scenario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cells_on_account_id_and_series_id_and_scenario ON public.cells USING btree (account_id, series_id, scenario);


--
-- Name: index_flipper_features_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_features_on_key ON public.flipper_features USING btree (key);


--
-- Name: index_flipper_gates_on_feature_key_and_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_gates_on_feature_key_and_key_and_value ON public.flipper_gates USING btree (feature_key, key, value);


--
-- Name: index_plaid_transactions_on_plaid_transaction_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_plaid_transactions_on_plaid_transaction_identifier ON public.plaid_transactions USING btree (plaid_transaction_identifier);


--
-- Name: index_que_scheduler_audit_on_scheduler_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_que_scheduler_audit_on_scheduler_job_id ON public.que_scheduler_audit USING btree (scheduler_job_id);


--
-- Name: index_shopify_shops_on_account_id_and_shopify_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shopify_shops_on_account_id_and_shopify_domain ON public.shopify_shops USING btree (account_id, shopify_domain);


--
-- Name: index_singer_sync_attempts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_singer_sync_attempts_on_created_at ON public.singer_sync_attempts USING btree (created_at);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_invitation_token ON public.users USING btree (invitation_token);


--
-- Name: index_users_on_invitations_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invitations_count ON public.users USING btree (invitations_count);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_id ON public.users USING btree (invited_by_id);


--
-- Name: index_users_on_invited_by_type_and_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_type_and_invited_by_id ON public.users USING btree (invited_by_type, invited_by_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: que_jobs_args_gin_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX que_jobs_args_gin_idx ON public.que_jobs USING gin (args jsonb_path_ops);


--
-- Name: que_jobs_data_gin_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX que_jobs_data_gin_idx ON public.que_jobs USING gin (data jsonb_path_ops);


--
-- Name: que_poll_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX que_poll_idx ON public.que_jobs USING btree (queue, priority, run_at, id) WHERE ((finished_at IS NULL) AND (expired_at IS NULL));


--
-- Name: que_scheduler_audit_enqueued_args; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX que_scheduler_audit_enqueued_args ON public.que_scheduler_audit_enqueued USING btree (args);


--
-- Name: que_scheduler_audit_enqueued_job_class; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX que_scheduler_audit_enqueued_job_class ON public.que_scheduler_audit_enqueued USING btree (job_class);


--
-- Name: que_scheduler_audit_enqueued_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX que_scheduler_audit_enqueued_job_id ON public.que_scheduler_audit_enqueued USING btree (job_id);


--
-- Name: que_jobs que_job_notify; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER que_job_notify AFTER INSERT ON public.que_jobs FOR EACH ROW EXECUTE PROCEDURE public.que_job_notify();


--
-- Name: que_jobs que_state_notify; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER que_state_notify AFTER INSERT OR DELETE OR UPDATE ON public.que_jobs FOR EACH ROW EXECUTE PROCEDURE public.que_state_notify();


--
-- Name: singer_sync_attempts fk_rails_04e4497db5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_sync_attempts
    ADD CONSTRAINT fk_rails_04e4497db5 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: cells fk_rails_14b7e22a0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cells
    ADD CONSTRAINT fk_rails_14b7e22a0a FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: budget_lines fk_rails_2f9acf8ea6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_lines
    ADD CONSTRAINT fk_rails_2f9acf8ea6 FOREIGN KEY (series_id) REFERENCES public.series(id);


--
-- Name: process_execution_involved_users fk_rails_3486d0e969; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_execution_involved_users
    ADD CONSTRAINT fk_rails_3486d0e969 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: singer_sync_states fk_rails_3c1c3bc797; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_sync_states
    ADD CONSTRAINT fk_rails_3c1c3bc797 FOREIGN KEY (connection_id) REFERENCES public.connections(id);


--
-- Name: series fk_rails_455c8d3820; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.series
    ADD CONSTRAINT fk_rails_455c8d3820 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: shopify_shops fk_rails_484f3cc7d7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopify_shops
    ADD CONSTRAINT fk_rails_484f3cc7d7 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: process_executions fk_rails_501396e88e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_executions
    ADD CONSTRAINT fk_rails_501396e88e FOREIGN KEY (process_template_id) REFERENCES public.process_templates(id);


--
-- Name: shopify_shops fk_rails_55ea274344; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopify_shops
    ADD CONSTRAINT fk_rails_55ea274344 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: google_analytics_credentials fk_rails_5640b900e5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.google_analytics_credentials
    ADD CONSTRAINT fk_rails_5640b900e5 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: account_user_permissions fk_rails_5c34e80f82; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_user_permissions
    ADD CONSTRAINT fk_rails_5c34e80f82 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: account_user_permissions fk_rails_63fd5df246; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_user_permissions
    ADD CONSTRAINT fk_rails_63fd5df246 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: process_executions fk_rails_69d610f2cd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_executions
    ADD CONSTRAINT fk_rails_69d610f2cd FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: budgets fk_rails_6bd295cc21; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets
    ADD CONSTRAINT fk_rails_6bd295cc21 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: budgets fk_rails_744b1d30a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets
    ADD CONSTRAINT fk_rails_744b1d30a8 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: budget_lines fk_rails_788211bd95; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_lines
    ADD CONSTRAINT fk_rails_788211bd95 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: plaid_item_accounts fk_rails_7f47dbb069; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_item_accounts
    ADD CONSTRAINT fk_rails_7f47dbb069 FOREIGN KEY (plaid_item_id) REFERENCES public.plaid_items(id);


--
-- Name: singer_sync_states fk_rails_7ffa223581; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_sync_states
    ADD CONSTRAINT fk_rails_7ffa223581 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: process_executions fk_rails_8312e93e59; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_executions
    ADD CONSTRAINT fk_rails_8312e93e59 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: budget_lines fk_rails_8948450cd1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_lines
    ADD CONSTRAINT fk_rails_8948450cd1 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: cells fk_rails_8b1af096c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cells
    ADD CONSTRAINT fk_rails_8b1af096c4 FOREIGN KEY (series_id) REFERENCES public.series(id);


--
-- Name: plaid_transactions fk_rails_91669f6ab9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_transactions
    ADD CONSTRAINT fk_rails_91669f6ab9 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: budget_line_scenarios fk_rails_9ab43f1055; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_line_scenarios
    ADD CONSTRAINT fk_rails_9ab43f1055 FOREIGN KEY (fixed_budget_line_descriptor_id) REFERENCES public.fixed_budget_line_descriptors(id);


--
-- Name: plaid_transactions fk_rails_a810b9b840; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_transactions
    ADD CONSTRAINT fk_rails_a810b9b840 FOREIGN KEY (plaid_item_id) REFERENCES public.plaid_items(id);


--
-- Name: connections fk_rails_b202e9a6e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT fk_rails_b202e9a6e9 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: process_templates fk_rails_b4aa9c64e1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_templates
    ADD CONSTRAINT fk_rails_b4aa9c64e1 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: scratchpads fk_rails_b513679b53; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scratchpads
    ADD CONSTRAINT fk_rails_b513679b53 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: budget_line_scenarios fk_rails_b67a79b20d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_line_scenarios
    ADD CONSTRAINT fk_rails_b67a79b20d FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: singer_sync_attempts fk_rails_b8f5d0f596; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_sync_attempts
    ADD CONSTRAINT fk_rails_b8f5d0f596 FOREIGN KEY (connection_id) REFERENCES public.connections(id);


--
-- Name: process_execution_involved_users fk_rails_b923e3df1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_execution_involved_users
    ADD CONSTRAINT fk_rails_b923e3df1e FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: process_execution_involved_users fk_rails_b9507c7210; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_execution_involved_users
    ADD CONSTRAINT fk_rails_b9507c7210 FOREIGN KEY (process_execution_id) REFERENCES public.process_executions(id);


--
-- Name: budget_lines fk_rails_bb40e0ae9f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_lines
    ADD CONSTRAINT fk_rails_bb40e0ae9f FOREIGN KEY (budget_id) REFERENCES public.budgets(id);


--
-- Name: accounts fk_rails_c0b1e2d9f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_c0b1e2d9f4 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: scratchpads fk_rails_c608ce4b4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scratchpads
    ADD CONSTRAINT fk_rails_c608ce4b4c FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: google_analytics_credentials fk_rails_c82cc36acf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.google_analytics_credentials
    ADD CONSTRAINT fk_rails_c82cc36acf FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: plaid_item_accounts fk_rails_cd76fab8e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_item_accounts
    ADD CONSTRAINT fk_rails_cd76fab8e2 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: plaid_items fk_rails_d063f9be8a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_items
    ADD CONSTRAINT fk_rails_d063f9be8a FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: plaid_items fk_rails_f3e129c887; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_items
    ADD CONSTRAINT fk_rails_f3e129c887 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: series fk_rails_f48c8ad918; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.series
    ADD CONSTRAINT fk_rails_f48c8ad918 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: process_templates fk_rails_f9659ce340; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_templates
    ADD CONSTRAINT fk_rails_f9659ce340 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: que_scheduler_audit_enqueued que_scheduler_audit_enqueued_scheduler_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.que_scheduler_audit_enqueued
    ADD CONSTRAINT que_scheduler_audit_enqueued_scheduler_job_id_fkey FOREIGN KEY (scheduler_job_id) REFERENCES public.que_scheduler_audit(scheduler_job_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20190117141829'),
('20190203190640'),
('20190203192200'),
('20190424181240'),
('20190605132833'),
('20190605133629'),
('20190610205409'),
('20190610212606'),
('20190610221752'),
('20190613211137'),
('20190613211138'),
('20190613215004'),
('20190620221343'),
('20190626154336'),
('20190628012359'),
('20190628213439'),
('20190702165742'),
('20190704185645'),
('20190705135949'),
('20190705140825'),
('20190705173411'),
('20190705180821'),
('20190709141711'),
('20190712152031'),
('20190712152310'),
('20190712202725'),
('20190717223839'),
('20190729180803'),
('20190729181220'),
('20190801011529'),
('20190801180723'),
('20190819140226'),
('20190821203957'),
('20190903210744');



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
-- Name: tap_shopify; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tap_shopify;


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
-- Name: custom_collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_collections (
    handle text,
    sort_order text,
    body_html text,
    title text,
    id bigint,
    published_scope text,
    admin_graphql_api_id text,
    updated_at text,
    image__alt text,
    image__src text,
    image__width bigint,
    image__created_at text,
    image__height bigint,
    published_at text,
    template_suffix text,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE custom_collections; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.custom_collections IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["custom_collections"], "to": "custom_collections"}], "key_properties": ["id"], "mappings": {"handle": {"type": ["string", "null"], "from": ["handle"]}, "sort_order": {"type": ["string", "null"], "from": ["sort_order"]}, "body_html": {"type": ["string", "null"], "from": ["body_html"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "published_scope": {"type": ["string", "null"], "from": ["published_scope"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"]}, "image__alt": {"type": ["string", "null"], "from": ["image", "alt"]}, "image__src": {"type": ["string", "null"], "from": ["image", "src"]}, "image__width": {"type": ["integer", "null"], "from": ["image", "width"]}, "image__created_at": {"type": ["string", "null"], "from": ["image", "created_at"]}, "image__height": {"type": ["integer", "null"], "from": ["image", "height"]}, "published_at": {"type": ["string", "null"], "from": ["published_at"]}, "template_suffix": {"type": ["string", "null"], "from": ["template_suffix"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: exchange_rate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_rate (
    date timestamp with time zone NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE exchange_rate; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.exchange_rate IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["exchange_rate"], "to": "exchange_rate"}], "key_properties": ["date"], "mappings": {"date": {"type": ["string"], "from": ["date"], "format": "date-time"}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


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
-- Name: metafields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metafields (
    owner_id bigint,
    admin_graphql_api_id text,
    owner_resource text,
    value_type text,
    key text,
    created_at timestamp with time zone,
    id bigint,
    namespace text,
    description text,
    value__i bigint,
    value__s text,
    updated_at timestamp with time zone,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE metafields; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.metafields IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["metafields"], "to": "metafields"}], "key_properties": ["id"], "mappings": {"owner_id": {"type": ["integer", "null"], "from": ["owner_id"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "owner_resource": {"type": ["string", "null"], "from": ["owner_resource"]}, "value_type": {"type": ["string", "null"], "from": ["value_type"]}, "key": {"type": ["string", "null"], "from": ["key"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "id": {"type": ["integer", "null"], "from": ["id"]}, "namespace": {"type": ["string", "null"], "from": ["namespace"]}, "description": {"type": ["string", "null"], "from": ["description"]}, "value__i": {"type": ["integer", "null"], "from": ["value"]}, "value__s": {"type": ["string", "null"], "from": ["value"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: my_first_dbt_model; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.my_first_dbt_model AS
 SELECT 1 AS id;


--
-- Name: order_refunds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_refunds (
    order_id bigint,
    restock boolean,
    processed_at text,
    user_id bigint,
    note text,
    id bigint,
    created_at timestamp with time zone,
    admin_graphql_api_id text,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE order_refunds; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.order_refunds IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["order_refunds"], "to": "order_refunds"}, {"type": "TABLE", "from": ["order_refunds", "order_adjustments"], "to": "order_refunds__order_adjustments"}, {"type": "TABLE", "from": ["order_refunds", "refund_line_items", "line_item", "tax_lines"], "to": "order_refunds__refund_line_items__line_item__tax_lines"}, {"type": "TABLE", "from": ["order_refunds", "refund_line_items", "line_item", "properties"], "to": "order_refunds__refund_line_items__line_item__properties"}, {"type": "TABLE", "from": ["order_refunds", "refund_line_items", "line_item", "discount_allocations"], "to": "order_refunds__refund_line_items__line_item__discount_allocatio"}, {"type": "TABLE", "from": ["order_refunds", "refund_line_items"], "to": "order_refunds__refund_line_items"}], "key_properties": ["id"], "mappings": {"order_id": {"type": ["integer", "null"], "from": ["order_id"]}, "restock": {"type": ["boolean", "null"], "from": ["restock"]}, "processed_at": {"type": ["string", "null"], "from": ["processed_at"]}, "user_id": {"type": ["integer", "null"], "from": ["user_id"]}, "note": {"type": ["string", "null"], "from": ["note"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: order_refunds__order_adjustments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_refunds__order_adjustments (
    order_id bigint,
    tax_amount double precision,
    refund_id bigint,
    amount double precision,
    kind text,
    id bigint,
    reason text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE order_refunds__order_adjustments; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.order_refunds__order_adjustments IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"order_id": {"type": ["integer", "null"], "from": ["order_id"]}, "tax_amount": {"type": ["number", "null"], "from": ["tax_amount"]}, "refund_id": {"type": ["integer", "null"], "from": ["refund_id"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "kind": {"type": ["string", "null"], "from": ["kind"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "reason": {"type": ["string", "null"], "from": ["reason"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: order_refunds__refund_line_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_refunds__refund_line_items (
    location_id bigint,
    subtotal_set__shop_money__currency_code text,
    subtotal_set__shop_money__amount text,
    subtotal_set__presentment_money__currency_code text,
    subtotal_set__presentment_money__amount text,
    total_tax_set__shop_money__currency_code text,
    total_tax_set__shop_money__amount text,
    total_tax_set__presentment_money__currency_code text,
    total_tax_set__presentment_money__amount text,
    line_item_id bigint,
    total_tax double precision,
    quantity bigint,
    id bigint,
    line_item__gift_card boolean,
    line_item__price text,
    line_item__fulfillment_service text,
    line_item__sku text,
    line_item__fulfillment_status text,
    line_item__quantity bigint,
    line_item__variant_id bigint,
    line_item__grams bigint,
    line_item__requires_shipping boolean,
    line_item__vendor text,
    line_item__price_set__shop_money__currency_code text,
    line_item__price_set__shop_money__amount text,
    line_item__price_set__presentment_money__currency_code text,
    line_item__price_set__presentment_money__amount text,
    line_item__variant_inventory_management text,
    line_item__pre_tax_price text,
    line_item__variant_title text,
    line_item__total_discount_set__shop_money__currency_code text,
    line_item__total_discount_set__shop_money__amount text,
    line_item__total_discount_set__presentment_money__currency_code text,
    line_item__total_discount_set__presentment_money__amount text,
    line_item__pre_tax_price_set__shop_money__currency_code text,
    line_item__pre_tax_price_set__shop_money__amount text,
    line_item__pre_tax_price_set__presentment_money__currency_code text,
    line_item__pre_tax_price_set__presentment_money__amount text,
    line_item__fulfillable_quantity bigint,
    line_item__id bigint,
    line_item__admin_graphql_api_id text,
    line_item__total_discount text,
    line_item__name text,
    line_item__product_exists boolean,
    line_item__taxable boolean,
    line_item__product_id bigint,
    line_item__title text,
    subtotal double precision,
    restock_type text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE order_refunds__refund_line_items; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.order_refunds__refund_line_items IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"location_id": {"type": ["integer", "null"], "from": ["location_id"]}, "subtotal_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["subtotal_set", "shop_money", "currency_code"]}, "subtotal_set__shop_money__amount": {"type": ["string", "null"], "from": ["subtotal_set", "shop_money", "amount"]}, "subtotal_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["subtotal_set", "presentment_money", "currency_code"]}, "subtotal_set__presentment_money__amount": {"type": ["string", "null"], "from": ["subtotal_set", "presentment_money", "amount"]}, "total_tax_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["total_tax_set", "shop_money", "currency_code"]}, "total_tax_set__shop_money__amount": {"type": ["string", "null"], "from": ["total_tax_set", "shop_money", "amount"]}, "total_tax_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["total_tax_set", "presentment_money", "currency_code"]}, "total_tax_set__presentment_money__amount": {"type": ["string", "null"], "from": ["total_tax_set", "presentment_money", "amount"]}, "line_item_id": {"type": ["integer", "null"], "from": ["line_item_id"]}, "total_tax": {"type": ["number", "null"], "from": ["total_tax"]}, "quantity": {"type": ["integer", "null"], "from": ["quantity"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "line_item__gift_card": {"type": ["boolean", "null"], "from": ["line_item", "gift_card"]}, "line_item__price": {"type": ["string", "null"], "from": ["line_item", "price"]}, "line_item__fulfillment_service": {"type": ["string", "null"], "from": ["line_item", "fulfillment_service"]}, "line_item__sku": {"type": ["string", "null"], "from": ["line_item", "sku"]}, "line_item__fulfillment_status": {"type": ["string", "null"], "from": ["line_item", "fulfillment_status"]}, "line_item__quantity": {"type": ["integer", "null"], "from": ["line_item", "quantity"]}, "line_item__variant_id": {"type": ["integer", "null"], "from": ["line_item", "variant_id"]}, "line_item__grams": {"type": ["integer", "null"], "from": ["line_item", "grams"]}, "line_item__requires_shipping": {"type": ["boolean", "null"], "from": ["line_item", "requires_shipping"]}, "line_item__vendor": {"type": ["string", "null"], "from": ["line_item", "vendor"]}, "line_item__price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "price_set", "shop_money", "currency_code"]}, "line_item__price_set__shop_money__amount": {"type": ["string", "null"], "from": ["line_item", "price_set", "shop_money", "amount"]}, "line_item__price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "price_set", "presentment_money", "currency_code"]}, "line_item__price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["line_item", "price_set", "presentment_money", "amount"]}, "line_item__variant_inventory_management": {"type": ["string", "null"], "from": ["line_item", "variant_inventory_management"]}, "line_item__pre_tax_price": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price"]}, "line_item__variant_title": {"type": ["string", "null"], "from": ["line_item", "variant_title"]}, "line_item__total_discount_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "shop_money", "currency_code"]}, "line_item__total_discount_set__shop_money__amount": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "shop_money", "amount"]}, "line_item__total_discount_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "presentment_money", "currency_code"]}, "line_item__total_discount_set__presentment_money__amount": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "presentment_money", "amount"]}, "line_item__pre_tax_price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "shop_money", "currency_code"]}, "line_item__pre_tax_price_set__shop_money__amount": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "shop_money", "amount"]}, "line_item__pre_tax_price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "presentment_money", "currency_code"]}, "line_item__pre_tax_price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "presentment_money", "amount"]}, "line_item__fulfillable_quantity": {"type": ["integer", "null"], "from": ["line_item", "fulfillable_quantity"]}, "line_item__id": {"type": ["integer", "null"], "from": ["line_item", "id"]}, "line_item__admin_graphql_api_id": {"type": ["string", "null"], "from": ["line_item", "admin_graphql_api_id"]}, "line_item__total_discount": {"type": ["string", "null"], "from": ["line_item", "total_discount"]}, "line_item__name": {"type": ["string", "null"], "from": ["line_item", "name"]}, "line_item__product_exists": {"type": ["boolean", "null"], "from": ["line_item", "product_exists"]}, "line_item__taxable": {"type": ["boolean", "null"], "from": ["line_item", "taxable"]}, "line_item__product_id": {"type": ["integer", "null"], "from": ["line_item", "product_id"]}, "line_item__title": {"type": ["string", "null"], "from": ["line_item", "title"]}, "subtotal": {"type": ["number", "null"], "from": ["subtotal"]}, "restock_type": {"type": ["string", "null"], "from": ["restock_type"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: order_refunds__refund_line_items__line_item__discount_allocatio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_refunds__refund_line_items__line_item__discount_allocatio (
    amount text,
    amount_set__shop_money__currency_code text,
    amount_set__shop_money__amount text,
    amount_set__presentment_money__currency_code text,
    amount_set__presentment_money__amount text,
    discount_application_index bigint,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE order_refunds__refund_line_items__line_item__discount_allocatio; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.order_refunds__refund_line_items__line_item__discount_allocatio IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"amount": {"type": ["string", "null"], "from": ["amount"]}, "amount_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["amount_set", "shop_money", "currency_code"]}, "amount_set__shop_money__amount": {"type": ["string", "null"], "from": ["amount_set", "shop_money", "amount"]}, "amount_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["amount_set", "presentment_money", "currency_code"]}, "amount_set__presentment_money__amount": {"type": ["string", "null"], "from": ["amount_set", "presentment_money", "amount"]}, "discount_application_index": {"type": ["integer", "null"], "from": ["discount_application_index"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: order_refunds__refund_line_items__line_item__properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_refunds__refund_line_items__line_item__properties (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE order_refunds__refund_line_items__line_item__properties; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.order_refunds__refund_line_items__line_item__properties IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: order_refunds__refund_line_items__line_item__tax_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_refunds__refund_line_items__line_item__tax_lines (
    price_set__shop_money__currency_code text,
    price_set__shop_money__amount text,
    price_set__presentment_money__currency_code text,
    price_set__presentment_money__amount text,
    price text,
    title text,
    rate double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE order_refunds__refund_line_items__line_item__tax_lines; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.order_refunds__refund_line_items__line_item__tax_lines IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price": {"type": ["string", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


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
    updated_at timestamp(6) without time zone NOT NULL
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
    state json NOT NULL,
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
-- Name: collects; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.collects (
    id bigint,
    collection_id bigint,
    created_at timestamp with time zone,
    featured boolean,
    "position" bigint,
    product_id bigint,
    sort_value text,
    updated_at timestamp with time zone,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone,
    account_id bigint,
    foobar text
);


--
-- Name: TABLE collects; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.collects IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["collects"], "to": "collects"}], "key_properties": ["id"], "mappings": {"id": {"type": ["integer", "null"], "from": ["id"]}, "collection_id": {"type": ["integer", "null"], "from": ["collection_id"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "featured": {"type": ["boolean", "null"], "from": ["featured"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "product_id": {"type": ["integer", "null"], "from": ["product_id"]}, "sort_value": {"type": ["string", "null"], "from": ["sort_value"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}, "account_id": {"type": ["integer", "null"], "from": ["account_id"]}, "foobar": {"type": ["string", "null"], "from": ["foobar"]}}}';


--
-- Name: custom_collections; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.custom_collections (
    handle text,
    sort_order text,
    body_html text,
    title text,
    id bigint,
    published_scope text,
    admin_graphql_api_id text,
    updated_at text,
    image__alt text,
    image__src text,
    image__width bigint,
    image__created_at text,
    image__height bigint,
    published_at text,
    template_suffix text,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone,
    account_id bigint,
    foobar text
);


--
-- Name: TABLE custom_collections; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.custom_collections IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["custom_collections"], "to": "custom_collections"}], "key_properties": ["id"], "mappings": {"handle": {"type": ["string", "null"], "from": ["handle"]}, "sort_order": {"type": ["string", "null"], "from": ["sort_order"]}, "body_html": {"type": ["string", "null"], "from": ["body_html"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "published_scope": {"type": ["string", "null"], "from": ["published_scope"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"]}, "image__alt": {"type": ["string", "null"], "from": ["image", "alt"]}, "image__src": {"type": ["string", "null"], "from": ["image", "src"]}, "image__width": {"type": ["integer", "null"], "from": ["image", "width"]}, "image__created_at": {"type": ["string", "null"], "from": ["image", "created_at"]}, "image__height": {"type": ["integer", "null"], "from": ["image", "height"]}, "published_at": {"type": ["string", "null"], "from": ["published_at"]}, "template_suffix": {"type": ["string", "null"], "from": ["template_suffix"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}, "account_id": {"type": ["integer", "null"], "from": ["account_id"]}, "foobar": {"type": ["string", "null"], "from": ["foobar"]}}}';


--
-- Name: customers; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.customers (
    last_order_name text,
    currency text,
    email text,
    multipass_identifier text,
    default_address__city text,
    default_address__address1 text,
    default_address__zip text,
    default_address__id bigint,
    default_address__country_name text,
    default_address__province text,
    default_address__phone text,
    default_address__country text,
    default_address__first_name text,
    default_address__customer_id bigint,
    default_address__default boolean,
    default_address__last_name text,
    default_address__country_code text,
    default_address__name text,
    default_address__province_code text,
    default_address__address2 text,
    default_address__company text,
    orders_count bigint,
    state text,
    verified_email boolean,
    total_spent text,
    last_order_id bigint,
    first_name text,
    updated_at timestamp with time zone,
    note text,
    phone text,
    admin_graphql_api_id text,
    last_name text,
    tags text,
    tax_exempt boolean,
    id bigint,
    accepts_marketing boolean,
    created_at timestamp with time zone,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone,
    account_id bigint,
    foobar text
);


--
-- Name: TABLE customers; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.customers IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["customers"], "to": "customers"}, {"type": "TABLE", "from": ["customers", "addresses"], "to": "customers__addresses"}], "key_properties": ["id"], "mappings": {"last_order_name": {"type": ["string", "null"], "from": ["last_order_name"]}, "currency": {"type": ["string", "null"], "from": ["currency"]}, "email": {"type": ["string", "null"], "from": ["email"]}, "multipass_identifier": {"type": ["string", "null"], "from": ["multipass_identifier"]}, "default_address__city": {"type": ["string", "null"], "from": ["default_address", "city"]}, "default_address__address1": {"type": ["string", "null"], "from": ["default_address", "address1"]}, "default_address__zip": {"type": ["string", "null"], "from": ["default_address", "zip"]}, "default_address__id": {"type": ["integer", "null"], "from": ["default_address", "id"]}, "default_address__country_name": {"type": ["string", "null"], "from": ["default_address", "country_name"]}, "default_address__province": {"type": ["string", "null"], "from": ["default_address", "province"]}, "default_address__phone": {"type": ["string", "null"], "from": ["default_address", "phone"]}, "default_address__country": {"type": ["string", "null"], "from": ["default_address", "country"]}, "default_address__first_name": {"type": ["string", "null"], "from": ["default_address", "first_name"]}, "default_address__customer_id": {"type": ["integer", "null"], "from": ["default_address", "customer_id"]}, "default_address__default": {"type": ["boolean", "null"], "from": ["default_address", "default"]}, "default_address__last_name": {"type": ["string", "null"], "from": ["default_address", "last_name"]}, "default_address__country_code": {"type": ["string", "null"], "from": ["default_address", "country_code"]}, "default_address__name": {"type": ["string", "null"], "from": ["default_address", "name"]}, "default_address__province_code": {"type": ["string", "null"], "from": ["default_address", "province_code"]}, "default_address__address2": {"type": ["string", "null"], "from": ["default_address", "address2"]}, "default_address__company": {"type": ["string", "null"], "from": ["default_address", "company"]}, "orders_count": {"type": ["integer", "null"], "from": ["orders_count"]}, "state": {"type": ["string", "null"], "from": ["state"]}, "verified_email": {"type": ["boolean", "null"], "from": ["verified_email"]}, "total_spent": {"type": ["string", "null"], "from": ["total_spent"]}, "last_order_id": {"type": ["integer", "null"], "from": ["last_order_id"]}, "first_name": {"type": ["string", "null"], "from": ["first_name"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "note": {"type": ["string", "null"], "from": ["note"]}, "phone": {"type": ["string", "null"], "from": ["phone"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "last_name": {"type": ["string", "null"], "from": ["last_name"]}, "tags": {"type": ["string", "null"], "from": ["tags"]}, "tax_exempt": {"type": ["boolean", "null"], "from": ["tax_exempt"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "accepts_marketing": {"type": ["boolean", "null"], "from": ["accepts_marketing"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}, "account_id": {"type": ["integer", "null"], "from": ["account_id"]}, "foobar": {"type": ["string", "null"], "from": ["foobar"]}}}';


--
-- Name: customers__addresses; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.customers__addresses (
    city text,
    address1 text,
    zip text,
    id bigint,
    country_name text,
    province text,
    phone text,
    country text,
    first_name text,
    customer_id bigint,
    "default" boolean,
    last_name text,
    country_code text,
    name text,
    province_code text,
    address2 text,
    company text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE customers__addresses; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.customers__addresses IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"city": {"type": ["string", "null"], "from": ["city"]}, "address1": {"type": ["string", "null"], "from": ["address1"]}, "zip": {"type": ["string", "null"], "from": ["zip"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "country_name": {"type": ["string", "null"], "from": ["country_name"]}, "province": {"type": ["string", "null"], "from": ["province"]}, "phone": {"type": ["string", "null"], "from": ["phone"]}, "country": {"type": ["string", "null"], "from": ["country"]}, "first_name": {"type": ["string", "null"], "from": ["first_name"]}, "customer_id": {"type": ["integer", "null"], "from": ["customer_id"]}, "default": {"type": ["boolean", "null"], "from": ["default"]}, "last_name": {"type": ["string", "null"], "from": ["last_name"]}, "country_code": {"type": ["string", "null"], "from": ["country_code"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "province_code": {"type": ["string", "null"], "from": ["province_code"]}, "address2": {"type": ["string", "null"], "from": ["address2"]}, "company": {"type": ["string", "null"], "from": ["company"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: metafields; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.metafields (
    owner_id bigint,
    admin_graphql_api_id text,
    owner_resource text,
    value_type text,
    key text,
    created_at timestamp with time zone,
    id bigint,
    namespace text,
    description text,
    value__i bigint,
    value__s text,
    updated_at timestamp with time zone,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone,
    account_id bigint,
    foobar text
);


--
-- Name: TABLE metafields; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.metafields IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["metafields"], "to": "metafields"}], "key_properties": ["id"], "mappings": {"owner_id": {"type": ["integer", "null"], "from": ["owner_id"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "owner_resource": {"type": ["string", "null"], "from": ["owner_resource"]}, "value_type": {"type": ["string", "null"], "from": ["value_type"]}, "key": {"type": ["string", "null"], "from": ["key"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "id": {"type": ["integer", "null"], "from": ["id"]}, "namespace": {"type": ["string", "null"], "from": ["namespace"]}, "description": {"type": ["string", "null"], "from": ["description"]}, "value__i": {"type": ["integer", "null"], "from": ["value"]}, "value__s": {"type": ["string", "null"], "from": ["value"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}, "account_id": {"type": ["integer", "null"], "from": ["account_id"]}, "foobar": {"type": ["string", "null"], "from": ["foobar"]}}}';


--
-- Name: order_refunds; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.order_refunds (
    order_id bigint,
    restock boolean,
    processed_at text,
    user_id bigint,
    note text,
    id bigint,
    created_at timestamp with time zone,
    admin_graphql_api_id text,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone,
    account_id bigint,
    foobar text
);


--
-- Name: TABLE order_refunds; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.order_refunds IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["order_refunds"], "to": "order_refunds"}, {"type": "TABLE", "from": ["order_refunds", "order_adjustments"], "to": "order_refunds__order_adjustments"}, {"type": "TABLE", "from": ["order_refunds", "refund_line_items", "line_item", "tax_lines"], "to": "order_refunds__refund_line_items__line_item__tax_lines"}, {"type": "TABLE", "from": ["order_refunds", "refund_line_items", "line_item", "properties"], "to": "order_refunds__refund_line_items__line_item__properties"}, {"type": "TABLE", "from": ["order_refunds", "refund_line_items", "line_item", "discount_allocations"], "to": "order_refunds__refund_line_items__line_item__discount_allocatio"}, {"type": "TABLE", "from": ["order_refunds", "refund_line_items"], "to": "order_refunds__refund_line_items"}], "key_properties": ["id"], "mappings": {"order_id": {"type": ["integer", "null"], "from": ["order_id"]}, "restock": {"type": ["boolean", "null"], "from": ["restock"]}, "processed_at": {"type": ["string", "null"], "from": ["processed_at"]}, "user_id": {"type": ["integer", "null"], "from": ["user_id"]}, "note": {"type": ["string", "null"], "from": ["note"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}, "account_id": {"type": ["integer", "null"], "from": ["account_id"]}, "foobar": {"type": ["string", "null"], "from": ["foobar"]}}}';


--
-- Name: order_refunds__order_adjustments; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.order_refunds__order_adjustments (
    order_id bigint,
    tax_amount double precision,
    refund_id bigint,
    amount double precision,
    kind text,
    id bigint,
    reason text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE order_refunds__order_adjustments; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.order_refunds__order_adjustments IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"order_id": {"type": ["integer", "null"], "from": ["order_id"]}, "tax_amount": {"type": ["number", "null"], "from": ["tax_amount"]}, "refund_id": {"type": ["integer", "null"], "from": ["refund_id"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "kind": {"type": ["string", "null"], "from": ["kind"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "reason": {"type": ["string", "null"], "from": ["reason"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: order_refunds__refund_line_items; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.order_refunds__refund_line_items (
    location_id bigint,
    subtotal_set__shop_money__currency_code text,
    subtotal_set__shop_money__amount text,
    subtotal_set__presentment_money__currency_code text,
    subtotal_set__presentment_money__amount text,
    total_tax_set__shop_money__currency_code text,
    total_tax_set__shop_money__amount text,
    total_tax_set__presentment_money__currency_code text,
    total_tax_set__presentment_money__amount text,
    line_item_id bigint,
    total_tax double precision,
    quantity bigint,
    id bigint,
    line_item__gift_card boolean,
    line_item__price text,
    line_item__fulfillment_service text,
    line_item__sku text,
    line_item__fulfillment_status text,
    line_item__quantity bigint,
    line_item__variant_id bigint,
    line_item__grams bigint,
    line_item__requires_shipping boolean,
    line_item__vendor text,
    line_item__price_set__shop_money__currency_code text,
    line_item__price_set__shop_money__amount text,
    line_item__price_set__presentment_money__currency_code text,
    line_item__price_set__presentment_money__amount text,
    line_item__variant_inventory_management text,
    line_item__pre_tax_price text,
    line_item__variant_title text,
    line_item__total_discount_set__shop_money__currency_code text,
    line_item__total_discount_set__shop_money__amount text,
    line_item__total_discount_set__presentment_money__currency_code text,
    line_item__total_discount_set__presentment_money__amount text,
    line_item__pre_tax_price_set__shop_money__currency_code text,
    line_item__pre_tax_price_set__shop_money__amount text,
    line_item__pre_tax_price_set__presentment_money__currency_code text,
    line_item__pre_tax_price_set__presentment_money__amount text,
    line_item__fulfillable_quantity bigint,
    line_item__id bigint,
    line_item__admin_graphql_api_id text,
    line_item__total_discount text,
    line_item__name text,
    line_item__product_exists boolean,
    line_item__taxable boolean,
    line_item__product_id bigint,
    line_item__title text,
    subtotal double precision,
    restock_type text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE order_refunds__refund_line_items; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.order_refunds__refund_line_items IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"location_id": {"type": ["integer", "null"], "from": ["location_id"]}, "subtotal_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["subtotal_set", "shop_money", "currency_code"]}, "subtotal_set__shop_money__amount": {"type": ["string", "null"], "from": ["subtotal_set", "shop_money", "amount"]}, "subtotal_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["subtotal_set", "presentment_money", "currency_code"]}, "subtotal_set__presentment_money__amount": {"type": ["string", "null"], "from": ["subtotal_set", "presentment_money", "amount"]}, "total_tax_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["total_tax_set", "shop_money", "currency_code"]}, "total_tax_set__shop_money__amount": {"type": ["string", "null"], "from": ["total_tax_set", "shop_money", "amount"]}, "total_tax_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["total_tax_set", "presentment_money", "currency_code"]}, "total_tax_set__presentment_money__amount": {"type": ["string", "null"], "from": ["total_tax_set", "presentment_money", "amount"]}, "line_item_id": {"type": ["integer", "null"], "from": ["line_item_id"]}, "total_tax": {"type": ["number", "null"], "from": ["total_tax"]}, "quantity": {"type": ["integer", "null"], "from": ["quantity"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "line_item__gift_card": {"type": ["boolean", "null"], "from": ["line_item", "gift_card"]}, "line_item__price": {"type": ["string", "null"], "from": ["line_item", "price"]}, "line_item__fulfillment_service": {"type": ["string", "null"], "from": ["line_item", "fulfillment_service"]}, "line_item__sku": {"type": ["string", "null"], "from": ["line_item", "sku"]}, "line_item__fulfillment_status": {"type": ["string", "null"], "from": ["line_item", "fulfillment_status"]}, "line_item__quantity": {"type": ["integer", "null"], "from": ["line_item", "quantity"]}, "line_item__variant_id": {"type": ["integer", "null"], "from": ["line_item", "variant_id"]}, "line_item__grams": {"type": ["integer", "null"], "from": ["line_item", "grams"]}, "line_item__requires_shipping": {"type": ["boolean", "null"], "from": ["line_item", "requires_shipping"]}, "line_item__vendor": {"type": ["string", "null"], "from": ["line_item", "vendor"]}, "line_item__price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "price_set", "shop_money", "currency_code"]}, "line_item__price_set__shop_money__amount": {"type": ["string", "null"], "from": ["line_item", "price_set", "shop_money", "amount"]}, "line_item__price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "price_set", "presentment_money", "currency_code"]}, "line_item__price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["line_item", "price_set", "presentment_money", "amount"]}, "line_item__variant_inventory_management": {"type": ["string", "null"], "from": ["line_item", "variant_inventory_management"]}, "line_item__pre_tax_price": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price"]}, "line_item__variant_title": {"type": ["string", "null"], "from": ["line_item", "variant_title"]}, "line_item__total_discount_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "shop_money", "currency_code"]}, "line_item__total_discount_set__shop_money__amount": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "shop_money", "amount"]}, "line_item__total_discount_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "presentment_money", "currency_code"]}, "line_item__total_discount_set__presentment_money__amount": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "presentment_money", "amount"]}, "line_item__pre_tax_price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "shop_money", "currency_code"]}, "line_item__pre_tax_price_set__shop_money__amount": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "shop_money", "amount"]}, "line_item__pre_tax_price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "presentment_money", "currency_code"]}, "line_item__pre_tax_price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "presentment_money", "amount"]}, "line_item__fulfillable_quantity": {"type": ["integer", "null"], "from": ["line_item", "fulfillable_quantity"]}, "line_item__id": {"type": ["integer", "null"], "from": ["line_item", "id"]}, "line_item__admin_graphql_api_id": {"type": ["string", "null"], "from": ["line_item", "admin_graphql_api_id"]}, "line_item__total_discount": {"type": ["string", "null"], "from": ["line_item", "total_discount"]}, "line_item__name": {"type": ["string", "null"], "from": ["line_item", "name"]}, "line_item__product_exists": {"type": ["boolean", "null"], "from": ["line_item", "product_exists"]}, "line_item__taxable": {"type": ["boolean", "null"], "from": ["line_item", "taxable"]}, "line_item__product_id": {"type": ["integer", "null"], "from": ["line_item", "product_id"]}, "line_item__title": {"type": ["string", "null"], "from": ["line_item", "title"]}, "subtotal": {"type": ["number", "null"], "from": ["subtotal"]}, "restock_type": {"type": ["string", "null"], "from": ["restock_type"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: order_refunds__refund_line_items__line_item__discount_allocatio; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.order_refunds__refund_line_items__line_item__discount_allocatio (
    amount text,
    amount_set__shop_money__currency_code text,
    amount_set__shop_money__amount text,
    amount_set__presentment_money__currency_code text,
    amount_set__presentment_money__amount text,
    discount_application_index bigint,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE order_refunds__refund_line_items__line_item__discount_allocatio; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.order_refunds__refund_line_items__line_item__discount_allocatio IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"amount": {"type": ["string", "null"], "from": ["amount"]}, "amount_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["amount_set", "shop_money", "currency_code"]}, "amount_set__shop_money__amount": {"type": ["string", "null"], "from": ["amount_set", "shop_money", "amount"]}, "amount_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["amount_set", "presentment_money", "currency_code"]}, "amount_set__presentment_money__amount": {"type": ["string", "null"], "from": ["amount_set", "presentment_money", "amount"]}, "discount_application_index": {"type": ["integer", "null"], "from": ["discount_application_index"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: order_refunds__refund_line_items__line_item__properties; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.order_refunds__refund_line_items__line_item__properties (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE order_refunds__refund_line_items__line_item__properties; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.order_refunds__refund_line_items__line_item__properties IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: order_refunds__refund_line_items__line_item__tax_lines; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.order_refunds__refund_line_items__line_item__tax_lines (
    price_set__shop_money__currency_code text,
    price_set__shop_money__amount text,
    price_set__presentment_money__currency_code text,
    price_set__presentment_money__amount text,
    price text,
    title text,
    rate double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE order_refunds__refund_line_items__line_item__tax_lines; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.order_refunds__refund_line_items__line_item__tax_lines IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price": {"type": ["string", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders (
    presentment_currency text,
    total_price double precision,
    processing_method text,
    order_number bigint,
    confirmed boolean,
    total_discounts double precision,
    total_line_items_price double precision,
    admin_graphql_api_id text,
    device_id bigint,
    cancel_reason text,
    currency text,
    source_identifier text,
    id bigint,
    processed_at timestamp with time zone,
    referring_site text,
    contact_email text,
    location_id bigint,
    customer__last_order_name text,
    customer__currency text,
    customer__email text,
    customer__multipass_identifier text,
    customer__default_address__city text,
    customer__default_address__address1 text,
    customer__default_address__zip text,
    customer__default_address__id bigint,
    customer__default_address__country_name text,
    customer__default_address__province text,
    customer__default_address__phone text,
    customer__default_address__country text,
    customer__default_address__first_name text,
    customer__default_address__customer_id bigint,
    customer__default_address__default boolean,
    customer__default_address__last_name text,
    customer__default_address__country_code text,
    customer__default_address__name text,
    customer__default_address__province_code text,
    customer__default_address__address2 text,
    customer__default_address__company text,
    customer__orders_count bigint,
    customer__state text,
    customer__verified_email boolean,
    customer__total_spent text,
    customer__last_order_id bigint,
    customer__first_name text,
    customer__updated_at timestamp with time zone,
    customer__note text,
    customer__phone text,
    customer__admin_graphql_api_id text,
    customer__last_name text,
    customer__tags text,
    customer__tax_exempt boolean,
    customer__id bigint,
    customer__accepts_marketing boolean,
    customer__created_at timestamp with time zone,
    test boolean,
    total_tax double precision,
    payment_details__avs_result_code text,
    payment_details__credit_card_company text,
    payment_details__cvv_result_code text,
    payment_details__credit_card_bin text,
    payment_details__credit_card_number text,
    number bigint,
    email text,
    source_name text,
    landing_site_ref text,
    shipping_address__phone text,
    shipping_address__country text,
    shipping_address__name text,
    shipping_address__address1 text,
    shipping_address__longitude double precision,
    shipping_address__address2 text,
    shipping_address__last_name text,
    shipping_address__first_name text,
    shipping_address__province text,
    shipping_address__city text,
    shipping_address__company text,
    shipping_address__latitude double precision,
    shipping_address__country_code text,
    shipping_address__province_code text,
    shipping_address__zip text,
    total_price_usd double precision,
    closed_at timestamp with time zone,
    name text,
    note text,
    user_id bigint,
    source_url text,
    subtotal_price double precision,
    billing_address__phone text,
    billing_address__country text,
    billing_address__name text,
    billing_address__address1 text,
    billing_address__longitude double precision,
    billing_address__address2 text,
    billing_address__last_name text,
    billing_address__first_name text,
    billing_address__province text,
    billing_address__city text,
    billing_address__company text,
    billing_address__latitude double precision,
    billing_address__country_code text,
    billing_address__province_code text,
    billing_address__zip text,
    landing_site text,
    taxes_included boolean,
    token text,
    app_id bigint,
    total_tip_received text,
    browser_ip text,
    phone text,
    fulfillment_status text,
    order_status_url text,
    client_details__session_hash text,
    client_details__accept_language text,
    client_details__browser_width bigint,
    client_details__user_agent text,
    client_details__browser_ip text,
    client_details__browser_height bigint,
    buyer_accepts_marketing boolean,
    checkout_token text,
    tags text,
    financial_status text,
    customer_locale text,
    checkout_id bigint,
    total_weight bigint,
    gateway text,
    cart_token text,
    cancelled_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    reference text,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone,
    account_id bigint,
    foobar text
);


--
-- Name: TABLE orders; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["orders"], "to": "orders"}, {"type": "TABLE", "from": ["orders", "line_items", "properties"], "to": "orders__line_items__properties"}, {"type": "TABLE", "from": ["orders", "line_items", "discount_allocations"], "to": "orders__line_items__discount_allocations"}, {"type": "TABLE", "from": ["orders", "line_items", "tax_lines"], "to": "orders__line_items__tax_lines"}, {"type": "TABLE", "from": ["orders", "line_items"], "to": "orders__line_items"}, {"type": "TABLE", "from": ["orders", "order_adjustments"], "to": "orders__order_adjustments"}, {"type": "TABLE", "from": ["orders", "shipping_lines", "tax_lines"], "to": "orders__shipping_lines__tax_lines"}, {"type": "TABLE", "from": ["orders", "shipping_lines", "discount_allocations"], "to": "orders__shipping_lines__discount_allocations"}, {"type": "TABLE", "from": ["orders", "shipping_lines"], "to": "orders__shipping_lines"}, {"type": "TABLE", "from": ["orders", "payment_gateway_names"], "to": "orders__payment_gateway_names"}, {"type": "TABLE", "from": ["orders", "fulfillments", "line_items", "properties"], "to": "orders__fulfillments__line_items__properties"}, {"type": "TABLE", "from": ["orders", "fulfillments", "line_items", "discount_allocations"], "to": "orders__fulfillments__line_items__discount_allocations"}, {"type": "TABLE", "from": ["orders", "fulfillments", "line_items", "tax_lines"], "to": "orders__fulfillments__line_items__tax_lines"}, {"type": "TABLE", "from": ["orders", "fulfillments", "line_items"], "to": "orders__fulfillments__line_items"}, {"type": "TABLE", "from": ["orders", "fulfillments", "tracking_urls"], "to": "orders__fulfillments__tracking_urls"}, {"type": "TABLE", "from": ["orders", "fulfillments", "tracking_numbers"], "to": "orders__fulfillments__tracking_numbers"}, {"type": "TABLE", "from": ["orders", "fulfillments"], "to": "orders__fulfillments"}, {"type": "TABLE", "from": ["orders", "customer", "addresses"], "to": "orders__customer__addresses"}, {"type": "TABLE", "from": ["orders", "discount_applications"], "to": "orders__discount_applications"}, {"type": "TABLE", "from": ["orders", "discount_codes"], "to": "orders__discount_codes"}, {"type": "TABLE", "from": ["orders", "tax_lines"], "to": "orders__tax_lines"}, {"type": "TABLE", "from": ["orders", "note_attributes"], "to": "orders__note_attributes"}, {"type": "TABLE", "from": ["orders", "refunds", "refund_line_items", "line_item", "properties"], "to": "orders__refunds__refund_line_items__line_item__properties"}, {"type": "TABLE", "from": ["orders", "refunds", "refund_line_items", "line_item", "discount_allocations"], "to": "orders__refunds__refund_line_items__line_item__discount_allocat"}, {"type": "TABLE", "from": ["orders", "refunds", "refund_line_items", "line_item", "tax_lines"], "to": "orders__refunds__refund_line_items__line_item__tax_lines"}, {"type": "TABLE", "from": ["orders", "refunds", "refund_line_items"], "to": "orders__refunds__refund_line_items"}, {"type": "TABLE", "from": ["orders", "refunds", "order_adjustments"], "to": "orders__refunds__order_adjustments"}, {"type": "TABLE", "from": ["orders", "refunds"], "to": "orders__refunds"}], "key_properties": ["id"], "mappings": {"presentment_currency": {"type": ["string", "null"], "from": ["presentment_currency"]}, "total_price": {"type": ["number", "null"], "from": ["total_price"]}, "processing_method": {"type": ["string", "null"], "from": ["processing_method"]}, "order_number": {"type": ["integer", "null"], "from": ["order_number"]}, "confirmed": {"type": ["boolean", "null"], "from": ["confirmed"]}, "total_discounts": {"type": ["number", "null"], "from": ["total_discounts"]}, "total_line_items_price": {"type": ["number", "null"], "from": ["total_line_items_price"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "device_id": {"type": ["integer", "null"], "from": ["device_id"]}, "cancel_reason": {"type": ["string", "null"], "from": ["cancel_reason"]}, "currency": {"type": ["string", "null"], "from": ["currency"]}, "source_identifier": {"type": ["string", "null"], "from": ["source_identifier"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "processed_at": {"type": ["string", "null"], "from": ["processed_at"], "format": "date-time"}, "referring_site": {"type": ["string", "null"], "from": ["referring_site"]}, "contact_email": {"type": ["string", "null"], "from": ["contact_email"]}, "location_id": {"type": ["integer", "null"], "from": ["location_id"]}, "customer__last_order_name": {"type": ["string", "null"], "from": ["customer", "last_order_name"]}, "customer__currency": {"type": ["string", "null"], "from": ["customer", "currency"]}, "customer__email": {"type": ["string", "null"], "from": ["customer", "email"]}, "customer__multipass_identifier": {"type": ["string", "null"], "from": ["customer", "multipass_identifier"]}, "customer__default_address__city": {"type": ["string", "null"], "from": ["customer", "default_address", "city"]}, "customer__default_address__address1": {"type": ["string", "null"], "from": ["customer", "default_address", "address1"]}, "customer__default_address__zip": {"type": ["string", "null"], "from": ["customer", "default_address", "zip"]}, "customer__default_address__id": {"type": ["integer", "null"], "from": ["customer", "default_address", "id"]}, "customer__default_address__country_name": {"type": ["string", "null"], "from": ["customer", "default_address", "country_name"]}, "customer__default_address__province": {"type": ["string", "null"], "from": ["customer", "default_address", "province"]}, "customer__default_address__phone": {"type": ["string", "null"], "from": ["customer", "default_address", "phone"]}, "customer__default_address__country": {"type": ["string", "null"], "from": ["customer", "default_address", "country"]}, "customer__default_address__first_name": {"type": ["string", "null"], "from": ["customer", "default_address", "first_name"]}, "customer__default_address__customer_id": {"type": ["integer", "null"], "from": ["customer", "default_address", "customer_id"]}, "customer__default_address__default": {"type": ["boolean", "null"], "from": ["customer", "default_address", "default"]}, "customer__default_address__last_name": {"type": ["string", "null"], "from": ["customer", "default_address", "last_name"]}, "customer__default_address__country_code": {"type": ["string", "null"], "from": ["customer", "default_address", "country_code"]}, "customer__default_address__name": {"type": ["string", "null"], "from": ["customer", "default_address", "name"]}, "customer__default_address__province_code": {"type": ["string", "null"], "from": ["customer", "default_address", "province_code"]}, "customer__default_address__address2": {"type": ["string", "null"], "from": ["customer", "default_address", "address2"]}, "customer__default_address__company": {"type": ["string", "null"], "from": ["customer", "default_address", "company"]}, "customer__orders_count": {"type": ["integer", "null"], "from": ["customer", "orders_count"]}, "customer__state": {"type": ["string", "null"], "from": ["customer", "state"]}, "customer__verified_email": {"type": ["boolean", "null"], "from": ["customer", "verified_email"]}, "customer__total_spent": {"type": ["string", "null"], "from": ["customer", "total_spent"]}, "customer__last_order_id": {"type": ["integer", "null"], "from": ["customer", "last_order_id"]}, "customer__first_name": {"type": ["string", "null"], "from": ["customer", "first_name"]}, "customer__updated_at": {"type": ["string", "null"], "from": ["customer", "updated_at"], "format": "date-time"}, "customer__note": {"type": ["string", "null"], "from": ["customer", "note"]}, "customer__phone": {"type": ["string", "null"], "from": ["customer", "phone"]}, "customer__admin_graphql_api_id": {"type": ["string", "null"], "from": ["customer", "admin_graphql_api_id"]}, "customer__last_name": {"type": ["string", "null"], "from": ["customer", "last_name"]}, "customer__tags": {"type": ["string", "null"], "from": ["customer", "tags"]}, "customer__tax_exempt": {"type": ["boolean", "null"], "from": ["customer", "tax_exempt"]}, "customer__id": {"type": ["integer", "null"], "from": ["customer", "id"]}, "customer__accepts_marketing": {"type": ["boolean", "null"], "from": ["customer", "accepts_marketing"]}, "customer__created_at": {"type": ["string", "null"], "from": ["customer", "created_at"], "format": "date-time"}, "test": {"type": ["boolean", "null"], "from": ["test"]}, "total_tax": {"type": ["number", "null"], "from": ["total_tax"]}, "payment_details__avs_result_code": {"type": ["string", "null"], "from": ["payment_details", "avs_result_code"]}, "payment_details__credit_card_company": {"type": ["string", "null"], "from": ["payment_details", "credit_card_company"]}, "payment_details__cvv_result_code": {"type": ["string", "null"], "from": ["payment_details", "cvv_result_code"]}, "payment_details__credit_card_bin": {"type": ["string", "null"], "from": ["payment_details", "credit_card_bin"]}, "payment_details__credit_card_number": {"type": ["string", "null"], "from": ["payment_details", "credit_card_number"]}, "number": {"type": ["integer", "null"], "from": ["number"]}, "email": {"type": ["string", "null"], "from": ["email"]}, "source_name": {"type": ["string", "null"], "from": ["source_name"]}, "landing_site_ref": {"type": ["string", "null"], "from": ["landing_site_ref"]}, "shipping_address__phone": {"type": ["string", "null"], "from": ["shipping_address", "phone"]}, "shipping_address__country": {"type": ["string", "null"], "from": ["shipping_address", "country"]}, "shipping_address__name": {"type": ["string", "null"], "from": ["shipping_address", "name"]}, "shipping_address__address1": {"type": ["string", "null"], "from": ["shipping_address", "address1"]}, "shipping_address__longitude": {"type": ["number", "null"], "from": ["shipping_address", "longitude"]}, "shipping_address__address2": {"type": ["string", "null"], "from": ["shipping_address", "address2"]}, "shipping_address__last_name": {"type": ["string", "null"], "from": ["shipping_address", "last_name"]}, "shipping_address__first_name": {"type": ["string", "null"], "from": ["shipping_address", "first_name"]}, "shipping_address__province": {"type": ["string", "null"], "from": ["shipping_address", "province"]}, "shipping_address__city": {"type": ["string", "null"], "from": ["shipping_address", "city"]}, "shipping_address__company": {"type": ["string", "null"], "from": ["shipping_address", "company"]}, "shipping_address__latitude": {"type": ["number", "null"], "from": ["shipping_address", "latitude"]}, "shipping_address__country_code": {"type": ["string", "null"], "from": ["shipping_address", "country_code"]}, "shipping_address__province_code": {"type": ["string", "null"], "from": ["shipping_address", "province_code"]}, "shipping_address__zip": {"type": ["string", "null"], "from": ["shipping_address", "zip"]}, "total_price_usd": {"type": ["number", "null"], "from": ["total_price_usd"]}, "closed_at": {"type": ["string", "null"], "from": ["closed_at"], "format": "date-time"}, "name": {"type": ["string", "null"], "from": ["name"]}, "note": {"type": ["string", "null"], "from": ["note"]}, "user_id": {"type": ["integer", "null"], "from": ["user_id"]}, "source_url": {"type": ["string", "null"], "from": ["source_url"]}, "subtotal_price": {"type": ["number", "null"], "from": ["subtotal_price"]}, "billing_address__phone": {"type": ["string", "null"], "from": ["billing_address", "phone"]}, "billing_address__country": {"type": ["string", "null"], "from": ["billing_address", "country"]}, "billing_address__name": {"type": ["string", "null"], "from": ["billing_address", "name"]}, "billing_address__address1": {"type": ["string", "null"], "from": ["billing_address", "address1"]}, "billing_address__longitude": {"type": ["number", "null"], "from": ["billing_address", "longitude"]}, "billing_address__address2": {"type": ["string", "null"], "from": ["billing_address", "address2"]}, "billing_address__last_name": {"type": ["string", "null"], "from": ["billing_address", "last_name"]}, "billing_address__first_name": {"type": ["string", "null"], "from": ["billing_address", "first_name"]}, "billing_address__province": {"type": ["string", "null"], "from": ["billing_address", "province"]}, "billing_address__city": {"type": ["string", "null"], "from": ["billing_address", "city"]}, "billing_address__company": {"type": ["string", "null"], "from": ["billing_address", "company"]}, "billing_address__latitude": {"type": ["number", "null"], "from": ["billing_address", "latitude"]}, "billing_address__country_code": {"type": ["string", "null"], "from": ["billing_address", "country_code"]}, "billing_address__province_code": {"type": ["string", "null"], "from": ["billing_address", "province_code"]}, "billing_address__zip": {"type": ["string", "null"], "from": ["billing_address", "zip"]}, "landing_site": {"type": ["string", "null"], "from": ["landing_site"]}, "taxes_included": {"type": ["boolean", "null"], "from": ["taxes_included"]}, "token": {"type": ["string", "null"], "from": ["token"]}, "app_id": {"type": ["integer", "null"], "from": ["app_id"]}, "total_tip_received": {"type": ["string", "null"], "from": ["total_tip_received"]}, "browser_ip": {"type": ["string", "null"], "from": ["browser_ip"]}, "phone": {"type": ["string", "null"], "from": ["phone"]}, "fulfillment_status": {"type": ["string", "null"], "from": ["fulfillment_status"]}, "order_status_url": {"type": ["string", "null"], "from": ["order_status_url"]}, "client_details__session_hash": {"type": ["string", "null"], "from": ["client_details", "session_hash"]}, "client_details__accept_language": {"type": ["string", "null"], "from": ["client_details", "accept_language"]}, "client_details__browser_width": {"type": ["integer", "null"], "from": ["client_details", "browser_width"]}, "client_details__user_agent": {"type": ["string", "null"], "from": ["client_details", "user_agent"]}, "client_details__browser_ip": {"type": ["string", "null"], "from": ["client_details", "browser_ip"]}, "client_details__browser_height": {"type": ["integer", "null"], "from": ["client_details", "browser_height"]}, "buyer_accepts_marketing": {"type": ["boolean", "null"], "from": ["buyer_accepts_marketing"]}, "checkout_token": {"type": ["string", "null"], "from": ["checkout_token"]}, "tags": {"type": ["string", "null"], "from": ["tags"]}, "financial_status": {"type": ["string", "null"], "from": ["financial_status"]}, "customer_locale": {"type": ["string", "null"], "from": ["customer_locale"]}, "checkout_id": {"type": ["integer", "null"], "from": ["checkout_id"]}, "total_weight": {"type": ["integer", "null"], "from": ["total_weight"]}, "gateway": {"type": ["string", "null"], "from": ["gateway"]}, "cart_token": {"type": ["string", "null"], "from": ["cart_token"]}, "cancelled_at": {"type": ["string", "null"], "from": ["cancelled_at"], "format": "date-time"}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "reference": {"type": ["string", "null"], "from": ["reference"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}, "account_id": {"type": ["integer", "null"], "from": ["account_id"]}, "foobar": {"type": ["string", "null"], "from": ["foobar"]}}}';


--
-- Name: orders__customer__addresses; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__customer__addresses (
    city text,
    address1 text,
    zip text,
    id bigint,
    country_name text,
    province text,
    phone text,
    country text,
    first_name text,
    customer_id bigint,
    "default" boolean,
    last_name text,
    country_code text,
    name text,
    province_code text,
    address2 text,
    company text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__customer__addresses; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__customer__addresses IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"city": {"type": ["string", "null"], "from": ["city"]}, "address1": {"type": ["string", "null"], "from": ["address1"]}, "zip": {"type": ["string", "null"], "from": ["zip"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "country_name": {"type": ["string", "null"], "from": ["country_name"]}, "province": {"type": ["string", "null"], "from": ["province"]}, "phone": {"type": ["string", "null"], "from": ["phone"]}, "country": {"type": ["string", "null"], "from": ["country"]}, "first_name": {"type": ["string", "null"], "from": ["first_name"]}, "customer_id": {"type": ["integer", "null"], "from": ["customer_id"]}, "default": {"type": ["boolean", "null"], "from": ["default"]}, "last_name": {"type": ["string", "null"], "from": ["last_name"]}, "country_code": {"type": ["string", "null"], "from": ["country_code"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "province_code": {"type": ["string", "null"], "from": ["province_code"]}, "address2": {"type": ["string", "null"], "from": ["address2"]}, "company": {"type": ["string", "null"], "from": ["company"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__discount_applications; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__discount_applications (
    target_type text,
    code text,
    description text,
    type text,
    target_selection text,
    allocation_method text,
    title text,
    value_type text,
    value double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__discount_applications; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__discount_applications IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"target_type": {"type": ["string", "null"], "from": ["target_type"]}, "code": {"type": ["string", "null"], "from": ["code"]}, "description": {"type": ["string", "null"], "from": ["description"]}, "type": {"type": ["string", "null"], "from": ["type"]}, "target_selection": {"type": ["string", "null"], "from": ["target_selection"]}, "allocation_method": {"type": ["string", "null"], "from": ["allocation_method"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "value_type": {"type": ["string", "null"], "from": ["value_type"]}, "value": {"type": ["number", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__discount_codes; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__discount_codes (
    code text,
    amount double precision,
    type text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__discount_codes; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__discount_codes IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"code": {"type": ["string", "null"], "from": ["code"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "type": {"type": ["string", "null"], "from": ["type"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__fulfillments; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__fulfillments (
    location_id bigint,
    receipt__testcase boolean,
    receipt__authorization text,
    tracking_number text,
    created_at timestamp with time zone,
    shipment_status text,
    tracking_url text,
    service text,
    status text,
    admin_graphql_api_id text,
    name text,
    id bigint,
    tracking_company text,
    updated_at timestamp with time zone,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__fulfillments IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"location_id": {"type": ["integer", "null"], "from": ["location_id"]}, "receipt__testcase": {"type": ["boolean", "null"], "from": ["receipt", "testcase"]}, "receipt__authorization": {"type": ["string", "null"], "from": ["receipt", "authorization"]}, "tracking_number": {"type": ["string", "null"], "from": ["tracking_number"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "shipment_status": {"type": ["string", "null"], "from": ["shipment_status"]}, "tracking_url": {"type": ["string", "null"], "from": ["tracking_url"]}, "service": {"type": ["string", "null"], "from": ["service"]}, "status": {"type": ["string", "null"], "from": ["status"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "tracking_company": {"type": ["string", "null"], "from": ["tracking_company"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__fulfillments__line_items; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__fulfillments__line_items (
    grams bigint,
    compare_at_price text,
    destination_location_id bigint,
    key text,
    line_price text,
    origin_location_id bigint,
    applied_discount bigint,
    fulfillable_quantity bigint,
    variant_title text,
    tax_code text,
    admin_graphql_api_id text,
    pre_tax_price double precision,
    sku text,
    product_exists boolean,
    total_discount double precision,
    name text,
    fulfillment_status text,
    gift_card boolean,
    id__i bigint,
    id__s text,
    taxable boolean,
    vendor text,
    origin_location__country_code text,
    origin_location__name text,
    origin_location__address1 text,
    origin_location__city text,
    origin_location__id bigint,
    origin_location__address2 text,
    origin_location__province_code text,
    origin_location__zip text,
    price double precision,
    requires_shipping boolean,
    fulfillment_service text,
    variant_inventory_management text,
    title text,
    destination_location__country_code text,
    destination_location__name text,
    destination_location__address1 text,
    destination_location__city text,
    destination_location__id bigint,
    destination_location__address2 text,
    destination_location__province_code text,
    destination_location__zip text,
    quantity bigint,
    product_id bigint,
    variant_id bigint,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments__line_items; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__fulfillments__line_items IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"grams": {"type": ["integer", "null"], "from": ["grams"]}, "compare_at_price": {"type": ["string", "null"], "from": ["compare_at_price"]}, "destination_location_id": {"type": ["integer", "null"], "from": ["destination_location_id"]}, "key": {"type": ["string", "null"], "from": ["key"]}, "line_price": {"type": ["string", "null"], "from": ["line_price"]}, "origin_location_id": {"type": ["integer", "null"], "from": ["origin_location_id"]}, "applied_discount": {"type": ["integer", "null"], "from": ["applied_discount"]}, "fulfillable_quantity": {"type": ["integer", "null"], "from": ["fulfillable_quantity"]}, "variant_title": {"type": ["string", "null"], "from": ["variant_title"]}, "tax_code": {"type": ["string", "null"], "from": ["tax_code"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "pre_tax_price": {"type": ["number", "null"], "from": ["pre_tax_price"]}, "sku": {"type": ["string", "null"], "from": ["sku"]}, "product_exists": {"type": ["boolean", "null"], "from": ["product_exists"]}, "total_discount": {"type": ["number", "null"], "from": ["total_discount"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "fulfillment_status": {"type": ["string", "null"], "from": ["fulfillment_status"]}, "gift_card": {"type": ["boolean", "null"], "from": ["gift_card"]}, "id__i": {"type": ["integer", "null"], "from": ["id"]}, "id__s": {"type": ["string", "null"], "from": ["id"]}, "taxable": {"type": ["boolean", "null"], "from": ["taxable"]}, "vendor": {"type": ["string", "null"], "from": ["vendor"]}, "origin_location__country_code": {"type": ["string", "null"], "from": ["origin_location", "country_code"]}, "origin_location__name": {"type": ["string", "null"], "from": ["origin_location", "name"]}, "origin_location__address1": {"type": ["string", "null"], "from": ["origin_location", "address1"]}, "origin_location__city": {"type": ["string", "null"], "from": ["origin_location", "city"]}, "origin_location__id": {"type": ["integer", "null"], "from": ["origin_location", "id"]}, "origin_location__address2": {"type": ["string", "null"], "from": ["origin_location", "address2"]}, "origin_location__province_code": {"type": ["string", "null"], "from": ["origin_location", "province_code"]}, "origin_location__zip": {"type": ["string", "null"], "from": ["origin_location", "zip"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "requires_shipping": {"type": ["boolean", "null"], "from": ["requires_shipping"]}, "fulfillment_service": {"type": ["string", "null"], "from": ["fulfillment_service"]}, "variant_inventory_management": {"type": ["string", "null"], "from": ["variant_inventory_management"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "destination_location__country_code": {"type": ["string", "null"], "from": ["destination_location", "country_code"]}, "destination_location__name": {"type": ["string", "null"], "from": ["destination_location", "name"]}, "destination_location__address1": {"type": ["string", "null"], "from": ["destination_location", "address1"]}, "destination_location__city": {"type": ["string", "null"], "from": ["destination_location", "city"]}, "destination_location__id": {"type": ["integer", "null"], "from": ["destination_location", "id"]}, "destination_location__address2": {"type": ["string", "null"], "from": ["destination_location", "address2"]}, "destination_location__province_code": {"type": ["string", "null"], "from": ["destination_location", "province_code"]}, "destination_location__zip": {"type": ["string", "null"], "from": ["destination_location", "zip"]}, "quantity": {"type": ["integer", "null"], "from": ["quantity"]}, "product_id": {"type": ["integer", "null"], "from": ["product_id"]}, "variant_id": {"type": ["integer", "null"], "from": ["variant_id"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__fulfillments__line_items__discount_allocations; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__fulfillments__line_items__discount_allocations (
    discount_application_index bigint,
    amount double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments__line_items__discount_allocations; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__fulfillments__line_items__discount_allocations IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"discount_application_index": {"type": ["integer", "null"], "from": ["discount_application_index"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__fulfillments__line_items__properties; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__fulfillments__line_items__properties (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments__line_items__properties; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__fulfillments__line_items__properties IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__fulfillments__line_items__tax_lines; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__fulfillments__line_items__tax_lines (
    price double precision,
    title text,
    rate double precision,
    compare_at text,
    "position" bigint,
    source text,
    zone text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments__line_items__tax_lines; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__fulfillments__line_items__tax_lines IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__fulfillments__tracking_numbers; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__fulfillments__tracking_numbers (
    _sdc_value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments__tracking_numbers; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__fulfillments__tracking_numbers IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["string", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__fulfillments__tracking_urls; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__fulfillments__tracking_urls (
    _sdc_value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments__tracking_urls; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__fulfillments__tracking_urls IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["string", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__line_items; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__line_items (
    grams bigint,
    compare_at_price text,
    destination_location_id bigint,
    key text,
    line_price text,
    origin_location_id bigint,
    applied_discount bigint,
    fulfillable_quantity bigint,
    variant_title text,
    tax_code text,
    admin_graphql_api_id text,
    pre_tax_price double precision,
    sku text,
    product_exists boolean,
    total_discount double precision,
    name text,
    fulfillment_status text,
    gift_card boolean,
    id__i bigint,
    id__s text,
    taxable boolean,
    vendor text,
    origin_location__country_code text,
    origin_location__name text,
    origin_location__address1 text,
    origin_location__city text,
    origin_location__id bigint,
    origin_location__address2 text,
    origin_location__province_code text,
    origin_location__zip text,
    price double precision,
    requires_shipping boolean,
    fulfillment_service text,
    variant_inventory_management text,
    title text,
    destination_location__country_code text,
    destination_location__name text,
    destination_location__address1 text,
    destination_location__city text,
    destination_location__id bigint,
    destination_location__address2 text,
    destination_location__province_code text,
    destination_location__zip text,
    quantity bigint,
    product_id bigint,
    variant_id bigint,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__line_items; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__line_items IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"grams": {"type": ["integer", "null"], "from": ["grams"]}, "compare_at_price": {"type": ["string", "null"], "from": ["compare_at_price"]}, "destination_location_id": {"type": ["integer", "null"], "from": ["destination_location_id"]}, "key": {"type": ["string", "null"], "from": ["key"]}, "line_price": {"type": ["string", "null"], "from": ["line_price"]}, "origin_location_id": {"type": ["integer", "null"], "from": ["origin_location_id"]}, "applied_discount": {"type": ["integer", "null"], "from": ["applied_discount"]}, "fulfillable_quantity": {"type": ["integer", "null"], "from": ["fulfillable_quantity"]}, "variant_title": {"type": ["string", "null"], "from": ["variant_title"]}, "tax_code": {"type": ["string", "null"], "from": ["tax_code"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "pre_tax_price": {"type": ["number", "null"], "from": ["pre_tax_price"]}, "sku": {"type": ["string", "null"], "from": ["sku"]}, "product_exists": {"type": ["boolean", "null"], "from": ["product_exists"]}, "total_discount": {"type": ["number", "null"], "from": ["total_discount"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "fulfillment_status": {"type": ["string", "null"], "from": ["fulfillment_status"]}, "gift_card": {"type": ["boolean", "null"], "from": ["gift_card"]}, "id__i": {"type": ["integer", "null"], "from": ["id"]}, "id__s": {"type": ["string", "null"], "from": ["id"]}, "taxable": {"type": ["boolean", "null"], "from": ["taxable"]}, "vendor": {"type": ["string", "null"], "from": ["vendor"]}, "origin_location__country_code": {"type": ["string", "null"], "from": ["origin_location", "country_code"]}, "origin_location__name": {"type": ["string", "null"], "from": ["origin_location", "name"]}, "origin_location__address1": {"type": ["string", "null"], "from": ["origin_location", "address1"]}, "origin_location__city": {"type": ["string", "null"], "from": ["origin_location", "city"]}, "origin_location__id": {"type": ["integer", "null"], "from": ["origin_location", "id"]}, "origin_location__address2": {"type": ["string", "null"], "from": ["origin_location", "address2"]}, "origin_location__province_code": {"type": ["string", "null"], "from": ["origin_location", "province_code"]}, "origin_location__zip": {"type": ["string", "null"], "from": ["origin_location", "zip"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "requires_shipping": {"type": ["boolean", "null"], "from": ["requires_shipping"]}, "fulfillment_service": {"type": ["string", "null"], "from": ["fulfillment_service"]}, "variant_inventory_management": {"type": ["string", "null"], "from": ["variant_inventory_management"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "destination_location__country_code": {"type": ["string", "null"], "from": ["destination_location", "country_code"]}, "destination_location__name": {"type": ["string", "null"], "from": ["destination_location", "name"]}, "destination_location__address1": {"type": ["string", "null"], "from": ["destination_location", "address1"]}, "destination_location__city": {"type": ["string", "null"], "from": ["destination_location", "city"]}, "destination_location__id": {"type": ["integer", "null"], "from": ["destination_location", "id"]}, "destination_location__address2": {"type": ["string", "null"], "from": ["destination_location", "address2"]}, "destination_location__province_code": {"type": ["string", "null"], "from": ["destination_location", "province_code"]}, "destination_location__zip": {"type": ["string", "null"], "from": ["destination_location", "zip"]}, "quantity": {"type": ["integer", "null"], "from": ["quantity"]}, "product_id": {"type": ["integer", "null"], "from": ["product_id"]}, "variant_id": {"type": ["integer", "null"], "from": ["variant_id"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__line_items__discount_allocations; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__line_items__discount_allocations (
    discount_application_index bigint,
    amount double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__line_items__discount_allocations; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__line_items__discount_allocations IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"discount_application_index": {"type": ["integer", "null"], "from": ["discount_application_index"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__line_items__properties; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__line_items__properties (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__line_items__properties; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__line_items__properties IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__line_items__tax_lines; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__line_items__tax_lines (
    price double precision,
    title text,
    rate double precision,
    compare_at text,
    "position" bigint,
    source text,
    zone text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__line_items__tax_lines; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__line_items__tax_lines IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__note_attributes; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__note_attributes (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__note_attributes; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__note_attributes IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__order_adjustments; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__order_adjustments (
    order_id bigint,
    tax_amount double precision,
    refund_id bigint,
    amount double precision,
    kind text,
    id bigint,
    reason text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__order_adjustments; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__order_adjustments IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"order_id": {"type": ["integer", "null"], "from": ["order_id"]}, "tax_amount": {"type": ["number", "null"], "from": ["tax_amount"]}, "refund_id": {"type": ["integer", "null"], "from": ["refund_id"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "kind": {"type": ["string", "null"], "from": ["kind"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "reason": {"type": ["string", "null"], "from": ["reason"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__payment_gateway_names; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__payment_gateway_names (
    _sdc_value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__payment_gateway_names; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__payment_gateway_names IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["string", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__refunds; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__refunds (
    admin_graphql_api_id text,
    restock boolean,
    note text,
    id bigint,
    user_id bigint,
    created_at timestamp with time zone,
    processed_at timestamp with time zone,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__refunds; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__refunds IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "restock": {"type": ["boolean", "null"], "from": ["restock"]}, "note": {"type": ["string", "null"], "from": ["note"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "user_id": {"type": ["integer", "null"], "from": ["user_id"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "processed_at": {"type": ["string", "null"], "from": ["processed_at"], "format": "date-time"}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__refunds__order_adjustments; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__refunds__order_adjustments (
    order_id bigint,
    tax_amount double precision,
    refund_id bigint,
    amount double precision,
    kind text,
    id bigint,
    reason text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__refunds__order_adjustments; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__refunds__order_adjustments IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"order_id": {"type": ["integer", "null"], "from": ["order_id"]}, "tax_amount": {"type": ["number", "null"], "from": ["tax_amount"]}, "refund_id": {"type": ["integer", "null"], "from": ["refund_id"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "kind": {"type": ["string", "null"], "from": ["kind"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "reason": {"type": ["string", "null"], "from": ["reason"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__refunds__refund_line_items; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__refunds__refund_line_items (
    line_item__grams bigint,
    line_item__compare_at_price text,
    line_item__destination_location_id bigint,
    line_item__key text,
    line_item__line_price text,
    line_item__origin_location_id bigint,
    line_item__applied_discount bigint,
    line_item__fulfillable_quantity bigint,
    line_item__variant_title text,
    line_item__tax_code text,
    line_item__admin_graphql_api_id text,
    line_item__pre_tax_price double precision,
    line_item__sku text,
    line_item__product_exists boolean,
    line_item__total_discount double precision,
    line_item__name text,
    line_item__fulfillment_status text,
    line_item__gift_card boolean,
    line_item__id__i bigint,
    line_item__id__s text,
    line_item__taxable boolean,
    line_item__vendor text,
    line_item__origin_location__country_code text,
    line_item__origin_location__name text,
    line_item__origin_location__address1 text,
    line_item__origin_location__city text,
    line_item__origin_location__id bigint,
    line_item__origin_location__address2 text,
    line_item__origin_location__province_code text,
    line_item__origin_location__zip text,
    line_item__price double precision,
    line_item__requires_shipping boolean,
    line_item__fulfillment_service text,
    line_item__variant_inventory_management text,
    line_item__title text,
    line_item__destination_location__country_code text,
    line_item__destination_location__name text,
    line_item__destination_location__address1 text,
    line_item__destination_location__city text,
    line_item__destination_location__id bigint,
    line_item__destination_location__address2 text,
    line_item__destination_location__province_code text,
    line_item__destination_location__zip text,
    line_item__quantity bigint,
    line_item__product_id bigint,
    line_item__variant_id bigint,
    location_id bigint,
    line_item_id bigint,
    quantity bigint,
    id bigint,
    total_tax double precision,
    restock_type text,
    subtotal double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__refunds__refund_line_items; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__refunds__refund_line_items IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"line_item__grams": {"type": ["integer", "null"], "from": ["line_item", "grams"]}, "line_item__compare_at_price": {"type": ["string", "null"], "from": ["line_item", "compare_at_price"]}, "line_item__destination_location_id": {"type": ["integer", "null"], "from": ["line_item", "destination_location_id"]}, "line_item__key": {"type": ["string", "null"], "from": ["line_item", "key"]}, "line_item__line_price": {"type": ["string", "null"], "from": ["line_item", "line_price"]}, "line_item__origin_location_id": {"type": ["integer", "null"], "from": ["line_item", "origin_location_id"]}, "line_item__applied_discount": {"type": ["integer", "null"], "from": ["line_item", "applied_discount"]}, "line_item__fulfillable_quantity": {"type": ["integer", "null"], "from": ["line_item", "fulfillable_quantity"]}, "line_item__variant_title": {"type": ["string", "null"], "from": ["line_item", "variant_title"]}, "line_item__tax_code": {"type": ["string", "null"], "from": ["line_item", "tax_code"]}, "line_item__admin_graphql_api_id": {"type": ["string", "null"], "from": ["line_item", "admin_graphql_api_id"]}, "line_item__pre_tax_price": {"type": ["number", "null"], "from": ["line_item", "pre_tax_price"]}, "line_item__sku": {"type": ["string", "null"], "from": ["line_item", "sku"]}, "line_item__product_exists": {"type": ["boolean", "null"], "from": ["line_item", "product_exists"]}, "line_item__total_discount": {"type": ["number", "null"], "from": ["line_item", "total_discount"]}, "line_item__name": {"type": ["string", "null"], "from": ["line_item", "name"]}, "line_item__fulfillment_status": {"type": ["string", "null"], "from": ["line_item", "fulfillment_status"]}, "line_item__gift_card": {"type": ["boolean", "null"], "from": ["line_item", "gift_card"]}, "line_item__id__i": {"type": ["integer", "null"], "from": ["line_item", "id"]}, "line_item__id__s": {"type": ["string", "null"], "from": ["line_item", "id"]}, "line_item__taxable": {"type": ["boolean", "null"], "from": ["line_item", "taxable"]}, "line_item__vendor": {"type": ["string", "null"], "from": ["line_item", "vendor"]}, "line_item__origin_location__country_code": {"type": ["string", "null"], "from": ["line_item", "origin_location", "country_code"]}, "line_item__origin_location__name": {"type": ["string", "null"], "from": ["line_item", "origin_location", "name"]}, "line_item__origin_location__address1": {"type": ["string", "null"], "from": ["line_item", "origin_location", "address1"]}, "line_item__origin_location__city": {"type": ["string", "null"], "from": ["line_item", "origin_location", "city"]}, "line_item__origin_location__id": {"type": ["integer", "null"], "from": ["line_item", "origin_location", "id"]}, "line_item__origin_location__address2": {"type": ["string", "null"], "from": ["line_item", "origin_location", "address2"]}, "line_item__origin_location__province_code": {"type": ["string", "null"], "from": ["line_item", "origin_location", "province_code"]}, "line_item__origin_location__zip": {"type": ["string", "null"], "from": ["line_item", "origin_location", "zip"]}, "line_item__price": {"type": ["number", "null"], "from": ["line_item", "price"]}, "line_item__requires_shipping": {"type": ["boolean", "null"], "from": ["line_item", "requires_shipping"]}, "line_item__fulfillment_service": {"type": ["string", "null"], "from": ["line_item", "fulfillment_service"]}, "line_item__variant_inventory_management": {"type": ["string", "null"], "from": ["line_item", "variant_inventory_management"]}, "line_item__title": {"type": ["string", "null"], "from": ["line_item", "title"]}, "line_item__destination_location__country_code": {"type": ["string", "null"], "from": ["line_item", "destination_location", "country_code"]}, "line_item__destination_location__name": {"type": ["string", "null"], "from": ["line_item", "destination_location", "name"]}, "line_item__destination_location__address1": {"type": ["string", "null"], "from": ["line_item", "destination_location", "address1"]}, "line_item__destination_location__city": {"type": ["string", "null"], "from": ["line_item", "destination_location", "city"]}, "line_item__destination_location__id": {"type": ["integer", "null"], "from": ["line_item", "destination_location", "id"]}, "line_item__destination_location__address2": {"type": ["string", "null"], "from": ["line_item", "destination_location", "address2"]}, "line_item__destination_location__province_code": {"type": ["string", "null"], "from": ["line_item", "destination_location", "province_code"]}, "line_item__destination_location__zip": {"type": ["string", "null"], "from": ["line_item", "destination_location", "zip"]}, "line_item__quantity": {"type": ["integer", "null"], "from": ["line_item", "quantity"]}, "line_item__product_id": {"type": ["integer", "null"], "from": ["line_item", "product_id"]}, "line_item__variant_id": {"type": ["integer", "null"], "from": ["line_item", "variant_id"]}, "location_id": {"type": ["integer", "null"], "from": ["location_id"]}, "line_item_id": {"type": ["integer", "null"], "from": ["line_item_id"]}, "quantity": {"type": ["integer", "null"], "from": ["quantity"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "total_tax": {"type": ["number", "null"], "from": ["total_tax"]}, "restock_type": {"type": ["string", "null"], "from": ["restock_type"]}, "subtotal": {"type": ["number", "null"], "from": ["subtotal"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__refunds__refund_line_items__line_item__discount_allocat; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__refunds__refund_line_items__line_item__discount_allocat (
    discount_application_index bigint,
    amount double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__refunds__refund_line_items__line_item__discount_allocat; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__refunds__refund_line_items__line_item__discount_allocat IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"discount_application_index": {"type": ["integer", "null"], "from": ["discount_application_index"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__refunds__refund_line_items__line_item__properties; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__refunds__refund_line_items__line_item__properties (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__refunds__refund_line_items__line_item__properties; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__refunds__refund_line_items__line_item__properties IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__refunds__refund_line_items__line_item__tax_lines; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__refunds__refund_line_items__line_item__tax_lines (
    price double precision,
    title text,
    rate double precision,
    compare_at text,
    "position" bigint,
    source text,
    zone text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__refunds__refund_line_items__line_item__tax_lines; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__refunds__refund_line_items__line_item__tax_lines IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__shipping_lines; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__shipping_lines (
    phone text,
    price double precision,
    title text,
    delivery_category text,
    discounted_price double precision,
    code text,
    requested_fulfillment_service_id text,
    carrier_identifier text,
    id bigint,
    source text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__shipping_lines; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__shipping_lines IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"phone": {"type": ["string", "null"], "from": ["phone"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "delivery_category": {"type": ["string", "null"], "from": ["delivery_category"]}, "discounted_price": {"type": ["number", "null"], "from": ["discounted_price"]}, "code": {"type": ["string", "null"], "from": ["code"]}, "requested_fulfillment_service_id": {"type": ["string", "null"], "from": ["requested_fulfillment_service_id"]}, "carrier_identifier": {"type": ["string", "null"], "from": ["carrier_identifier"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__shipping_lines__discount_allocations; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__shipping_lines__discount_allocations (
    discount_application_index bigint,
    amount double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__shipping_lines__discount_allocations; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__shipping_lines__discount_allocations IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"discount_application_index": {"type": ["integer", "null"], "from": ["discount_application_index"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__shipping_lines__tax_lines; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__shipping_lines__tax_lines (
    price double precision,
    title text,
    rate double precision,
    compare_at text,
    "position" bigint,
    source text,
    zone text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__shipping_lines__tax_lines; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__shipping_lines__tax_lines IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__tax_lines; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.orders__tax_lines (
    price double precision,
    title text,
    rate double precision,
    compare_at text,
    "position" bigint,
    source text,
    zone text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__tax_lines; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.orders__tax_lines IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: products; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.products (
    published_at timestamp with time zone,
    created_at timestamp with time zone,
    published_scope text,
    vendor text,
    updated_at timestamp with time zone,
    body_html text,
    product_type text,
    tags text,
    image__updated_at timestamp with time zone,
    image__created_at timestamp with time zone,
    image__height bigint,
    image__alt text,
    image__src text,
    image__position bigint,
    image__id bigint,
    image__admin_graphql_api_id text,
    image__width bigint,
    handle text,
    template_suffix text,
    title text,
    admin_graphql_api_id text,
    id bigint,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone,
    account_id bigint,
    foobar text
);


--
-- Name: TABLE products; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.products IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["products"], "to": "products"}, {"type": "TABLE", "from": ["products", "options", "values"], "to": "products__options__values"}, {"type": "TABLE", "from": ["products", "options"], "to": "products__options"}, {"type": "TABLE", "from": ["products", "image", "variant_ids"], "to": "products__image__variant_ids"}, {"type": "TABLE", "from": ["products", "images", "variant_ids"], "to": "products__images__variant_ids"}, {"type": "TABLE", "from": ["products", "images"], "to": "products__images"}, {"type": "TABLE", "from": ["products", "variants"], "to": "products__variants"}], "key_properties": ["id"], "mappings": {"published_at": {"type": ["string", "null"], "from": ["published_at"], "format": "date-time"}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "published_scope": {"type": ["string", "null"], "from": ["published_scope"]}, "vendor": {"type": ["string", "null"], "from": ["vendor"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "body_html": {"type": ["string", "null"], "from": ["body_html"]}, "product_type": {"type": ["string", "null"], "from": ["product_type"]}, "tags": {"type": ["string", "null"], "from": ["tags"]}, "image__updated_at": {"type": ["string", "null"], "from": ["image", "updated_at"], "format": "date-time"}, "image__created_at": {"type": ["string", "null"], "from": ["image", "created_at"], "format": "date-time"}, "image__height": {"type": ["integer", "null"], "from": ["image", "height"]}, "image__alt": {"type": ["string", "null"], "from": ["image", "alt"]}, "image__src": {"type": ["string", "null"], "from": ["image", "src"]}, "image__position": {"type": ["integer", "null"], "from": ["image", "position"]}, "image__id": {"type": ["integer", "null"], "from": ["image", "id"]}, "image__admin_graphql_api_id": {"type": ["string", "null"], "from": ["image", "admin_graphql_api_id"]}, "image__width": {"type": ["integer", "null"], "from": ["image", "width"]}, "handle": {"type": ["string", "null"], "from": ["handle"]}, "template_suffix": {"type": ["string", "null"], "from": ["template_suffix"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}, "account_id": {"type": ["integer", "null"], "from": ["account_id"]}, "foobar": {"type": ["string", "null"], "from": ["foobar"]}}}';


--
-- Name: products__image__variant_ids; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.products__image__variant_ids (
    _sdc_value bigint,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE products__image__variant_ids; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.products__image__variant_ids IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["integer", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: products__images; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.products__images (
    updated_at timestamp with time zone,
    created_at timestamp with time zone,
    height bigint,
    alt text,
    src text,
    "position" bigint,
    id bigint,
    admin_graphql_api_id text,
    width bigint,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE products__images; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.products__images IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "height": {"type": ["integer", "null"], "from": ["height"]}, "alt": {"type": ["string", "null"], "from": ["alt"]}, "src": {"type": ["string", "null"], "from": ["src"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "width": {"type": ["integer", "null"], "from": ["width"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: products__images__variant_ids; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.products__images__variant_ids (
    _sdc_value bigint,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE products__images__variant_ids; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.products__images__variant_ids IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["integer", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: products__options; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.products__options (
    name text,
    product_id bigint,
    id bigint,
    "position" bigint,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE products__options; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.products__options IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "product_id": {"type": ["integer", "null"], "from": ["product_id"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: products__options__values; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.products__options__values (
    _sdc_value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE products__options__values; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.products__options__values IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["string", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: products__variants; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.products__variants (
    barcode text,
    tax_code text,
    created_at timestamp with time zone,
    weight_unit text,
    id bigint,
    "position" bigint,
    price double precision,
    image_id bigint,
    inventory_policy text,
    sku text,
    inventory_item_id bigint,
    fulfillment_service text,
    title text,
    weight double precision,
    inventory_management text,
    taxable boolean,
    admin_graphql_api_id text,
    option1 text,
    compare_at_price double precision,
    updated_at timestamp with time zone,
    option2 text,
    old_inventory_quantity bigint,
    requires_shipping boolean,
    inventory_quantity bigint,
    grams bigint,
    option3 text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE products__variants; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.products__variants IS '{"version": null, "schema_version": 1, "key_properties": ["_sdc_source_key_id"], "mappings": {"barcode": {"type": ["string", "null"], "from": ["barcode"]}, "tax_code": {"type": ["string", "null"], "from": ["tax_code"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "weight_unit": {"type": ["string", "null"], "from": ["weight_unit"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "image_id": {"type": ["integer", "null"], "from": ["image_id"]}, "inventory_policy": {"type": ["string", "null"], "from": ["inventory_policy"]}, "sku": {"type": ["string", "null"], "from": ["sku"]}, "inventory_item_id": {"type": ["integer", "null"], "from": ["inventory_item_id"]}, "fulfillment_service": {"type": ["string", "null"], "from": ["fulfillment_service"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "weight": {"type": ["number", "null"], "from": ["weight"]}, "inventory_management": {"type": ["string", "null"], "from": ["inventory_management"]}, "taxable": {"type": ["boolean", "null"], "from": ["taxable"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "option1": {"type": ["string", "null"], "from": ["option1"]}, "compare_at_price": {"type": ["number", "null"], "from": ["compare_at_price"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "option2": {"type": ["string", "null"], "from": ["option2"]}, "old_inventory_quantity": {"type": ["integer", "null"], "from": ["old_inventory_quantity"]}, "requires_shipping": {"type": ["boolean", "null"], "from": ["requires_shipping"]}, "inventory_quantity": {"type": ["integer", "null"], "from": ["inventory_quantity"]}, "grams": {"type": ["integer", "null"], "from": ["grams"]}, "option3": {"type": ["string", "null"], "from": ["option3"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: transactions; Type: TABLE; Schema: tap_shopify; Owner: -
--

CREATE TABLE tap_shopify.transactions (
    error_code text,
    device_id bigint,
    user_id bigint,
    parent_id bigint,
    test boolean,
    kind text,
    order_id bigint,
    amount double precision,
    "authorization" text,
    currency text,
    source_name text,
    message text,
    id bigint,
    created_at text,
    status text,
    payment_details__cvv_result_code text,
    payment_details__credit_card_bin text,
    payment_details__credit_card_company text,
    payment_details__credit_card_number text,
    payment_details__avs_result_code text,
    gateway text,
    admin_graphql_api_id text,
    receipt__fee_amount double precision,
    receipt__gross_amount double precision,
    receipt__tax_amount double precision,
    location_id bigint,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone,
    account_id bigint,
    foobar text
);


--
-- Name: TABLE transactions; Type: COMMENT; Schema: tap_shopify; Owner: -
--

COMMENT ON TABLE tap_shopify.transactions IS '{"version": null, "schema_version": 1, "table_mappings": [{"type": "TABLE", "from": ["transactions"], "to": "transactions"}], "key_properties": ["id"], "mappings": {"error_code": {"type": ["string", "null"], "from": ["error_code"]}, "device_id": {"type": ["integer", "null"], "from": ["device_id"]}, "user_id": {"type": ["integer", "null"], "from": ["user_id"]}, "parent_id": {"type": ["integer", "null"], "from": ["parent_id"]}, "test": {"type": ["boolean", "null"], "from": ["test"]}, "kind": {"type": ["string", "null"], "from": ["kind"]}, "order_id": {"type": ["integer", "null"], "from": ["order_id"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "authorization": {"type": ["string", "null"], "from": ["authorization"]}, "currency": {"type": ["string", "null"], "from": ["currency"]}, "source_name": {"type": ["string", "null"], "from": ["source_name"]}, "message": {"type": ["string", "null"], "from": ["message"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"]}, "status": {"type": ["string", "null"], "from": ["status"]}, "payment_details__cvv_result_code": {"type": ["string", "null"], "from": ["payment_details", "cvv_result_code"]}, "payment_details__credit_card_bin": {"type": ["string", "null"], "from": ["payment_details", "credit_card_bin"]}, "payment_details__credit_card_company": {"type": ["string", "null"], "from": ["payment_details", "credit_card_company"]}, "payment_details__credit_card_number": {"type": ["string", "null"], "from": ["payment_details", "credit_card_number"]}, "payment_details__avs_result_code": {"type": ["string", "null"], "from": ["payment_details", "avs_result_code"]}, "gateway": {"type": ["string", "null"], "from": ["gateway"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "receipt__fee_amount": {"type": ["number", "null"], "from": ["receipt", "fee_amount"]}, "receipt__gross_amount": {"type": ["number", "null"], "from": ["receipt", "gross_amount"]}, "receipt__tax_amount": {"type": ["number", "null"], "from": ["receipt", "tax_amount"]}, "location_id": {"type": ["integer", "null"], "from": ["location_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}, "account_id": {"type": ["integer", "null"], "from": ["account_id"]}, "foobar": {"type": ["string", "null"], "from": ["foobar"]}}}';


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
('20190624162800'),
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
('20190801180723');



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
-- Name: raw_tap_csv; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA raw_tap_csv;


--
-- Name: raw_tap_google_analytics; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA raw_tap_google_analytics;


--
-- Name: raw_tap_kafka; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA raw_tap_kafka;


--
-- Name: raw_tap_shopify; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA raw_tap_shopify;


--
-- Name: tap_csv; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tap_csv;


--
-- Name: warehouse; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA warehouse;


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
-- Name: convert_timezone(text, text, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.convert_timezone(in_tzname text, out_tzname text, in_t timestamp with time zone) RETURNS timestamp with time zone
    LANGUAGE plpgsql
    AS $$
declare
begin
  return in_t at time zone out_tzname at time zone in_tzname;
end;
$$;


--
-- Name: datediff(character varying, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.datediff(units character varying, start_t timestamp without time zone, end_t timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
    diff_interval interval;
    diff int = 0;
    years_diff int = 0;
begin
    if units in ('yy', 'yyyy', 'year', 'mm', 'm', 'month') then
        years_diff = date_part('year', end_t) - date_part('year', start_t);

        if units in ('yy', 'yyyy', 'year') then
            -- sql server does not count full years passed (only difference between year parts)
            return years_diff;
        else
            -- if end month is less than start month it will subtracted
            return years_diff * 12 + (date_part('month', end_t) - date_part('month', start_t));
        end if;
    end if;

    -- Minus operator returns interval 'DDD days HH:MI:SS'
    diff_interval = end_t - start_t;

    diff = diff + date_part('day', diff_interval);

    if units in ('wk', 'ww', 'week') then
        diff = diff/7;
        return diff;
    end if;

    if units in ('dd', 'd', 'day') then
        return diff;
    end if;

    diff = diff * 24 + date_part('hour', diff_interval);

    if units in ('hh', 'hour') then
        return diff;
    end if;

    diff = diff * 60 + date_part('minute', diff_interval);

    if units in ('mi', 'n', 'minute') then
        return diff;
    end if;

    diff = diff * 60 + date_part('second', diff_interval);

    return diff;
end;
$$;


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
-- Name: months_between(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: warehouse; Owner: -
--

CREATE FUNCTION warehouse.months_between(t_start timestamp with time zone, t_end timestamp with time zone) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
select ((extract('years' from $2)::int -  extract('years' from $1)::int) * 12)
    - extract('month' from $1)::int + extract('month' from $2)::int
$_$;


--
-- Name: gapfill(anyelement); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.gapfill(anyelement) (
    SFUNC = public.gapfillinternal,
    STYPE = anyelement
);


--
-- Name: dim_shopify_customers; Type: TABLE; Schema: dbt_harry; Owner: -
--

CREATE TABLE dbt_harry.dim_shopify_customers (
    customer_id bigint,
    account_id bigint,
    email text,
    verified_email boolean,
    first_name text,
    last_name text,
    accepts_marketing boolean,
    state text,
    tags text,
    tax_exempt boolean,
    default_address_id bigint,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    total_order_count bigint,
    total_successful_order_count bigint,
    total_cancelled_order_count bigint,
    total_spend double precision,
    previous_1_month_spend double precision,
    previous_3_month_spend double precision,
    previous_6_month_spend double precision,
    previous_12_month_spend double precision,
    most_recent_order_id bigint,
    most_recent_order_number bigint,
    most_recent_order_at timestamp with time zone,
    most_recent_order_total_price double precision,
    rfm_recency_quintile integer,
    rfm_frequency_quintile integer,
    rfm_monetary_quintile integer,
    rfm_score text,
    rfm_label text
);


--
-- Name: fct_shopify_orders; Type: TABLE; Schema: dbt_harry; Owner: -
--

CREATE TABLE dbt_harry.fct_shopify_orders (
    order_id bigint,
    account_id bigint,
    shop_id bigint,
    app_id bigint,
    order_name text,
    user_id bigint,
    customer_id bigint,
    checkout_id bigint,
    checkout_token text,
    cart_token text,
    token text,
    email text,
    contact_email text,
    buyer_accepts_marketing boolean,
    confirmed boolean,
    internal_number text,
    order_number bigint,
    currency text,
    presentment_currency text,
    financial_status text,
    fulfillment_status text,
    gateway text,
    processing_method text,
    total_tip_received text,
    total_weight bigint,
    total_discounts_base numeric,
    subtotal_price numeric(38,6),
    total_line_items_price double precision,
    total_price double precision,
    total_price_usd double precision,
    total_tax double precision,
    total_shipping_cost_base numeric(38,6),
    shipping_currency_code character varying(128),
    tags text,
    taxes_included boolean,
    order_status_url text,
    location_id bigint,
    shipping_city character varying(256),
    shipping_province character varying(256),
    shipping_province_code character varying(256),
    shipping_country character varying(256),
    shipping_country_code character varying(256),
    shipping_zip_code character varying(256),
    shipping_address_address1 character varying(256),
    shipping_address_address2 character varying(256),
    shipping_company character varying(256),
    shipping_first_name character varying(256),
    shipping_last_name character varying(256),
    shipping_latitude bigint,
    shipping_longitude bigint,
    shipping_name character varying(256),
    shipping_phone character varying(256),
    billing_city character varying(256),
    billing_province character varying(256),
    billing_province_code character varying(256),
    billing_country character varying(256),
    billing_country_code character varying(256),
    billing_zip_code character varying(256),
    billing_address_address1 character varying(256),
    billing_address_address2 character varying(256),
    billing_company character varying(256),
    billing_first_name character varying(256),
    billing_last_name character varying(256),
    billing_latitude bigint,
    billing_longitude bigint,
    billing_name character varying(256),
    billing_phone character varying(256),
    referring_site text,
    browser_ip text,
    landing_site text,
    source_name text,
    created_at timestamp with time zone,
    processed_at timestamp with time zone,
    closed_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    cancel_reason text,
    updated_at timestamp with time zone,
    discount_code text,
    discount_type text,
    shipping_discount double precision,
    final_discounts double precision,
    final_shipping_cost double precision,
    order_seq_number bigint,
    new_vs_repeat text,
    cancelled boolean
);


--
-- Name: stg_shopify_customer_order_aggregates; Type: TABLE; Schema: dbt_harry; Owner: -
--

CREATE TABLE dbt_harry.stg_shopify_customer_order_aggregates (
    customer_id bigint,
    account_id bigint,
    total_order_count bigint,
    total_successful_order_count bigint,
    total_cancelled_order_count bigint,
    total_spend double precision,
    previous_1_month_spend double precision,
    previous_3_month_spend double precision,
    previous_6_month_spend double precision,
    previous_12_month_spend double precision,
    most_recent_order_id bigint,
    most_recent_order_number bigint,
    most_recent_order_at timestamp with time zone,
    most_recent_order_total_price double precision
);


--
-- Name: stg_shopify_customer_rfm; Type: TABLE; Schema: dbt_harry; Owner: -
--

CREATE TABLE dbt_harry.stg_shopify_customer_rfm (
    customer_id bigint,
    total_order_count bigint,
    total_spend double precision,
    days_since_last_order double precision,
    recency_quintile integer,
    frequency_quintile integer,
    monetary_quintile integer,
    rfm_score text,
    rfm_label text
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
    updated_at timestamp(6) without time zone NOT NULL,
    business_epoch timestamp without time zone DEFAULT '2018-01-01 01:01:00'::timestamp without time zone
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
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp without time zone
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
-- Name: shopify_shops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shopify_shops (
    id bigint NOT NULL,
    shopify_domain character varying NOT NULL,
    api_key character varying,
    password character varying,
    name character varying NOT NULL,
    shop_id bigint NOT NULL,
    account_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    script_tag_setup_at timestamp without time zone,
    access_token character varying
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
-- Name: singer_global_sync_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.singer_global_sync_attempts (
    id bigint NOT NULL,
    key character varying NOT NULL,
    failure_reason character varying,
    finished_at timestamp without time zone,
    last_progress_at timestamp without time zone,
    started_at timestamp without time zone,
    success boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: singer_global_sync_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.singer_global_sync_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: singer_global_sync_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.singer_global_sync_attempts_id_seq OWNED BY public.singer_global_sync_attempts.id;


--
-- Name: singer_global_sync_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.singer_global_sync_states (
    id bigint NOT NULL,
    key character varying NOT NULL,
    state jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: singer_global_sync_states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.singer_global_sync_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: singer_global_sync_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.singer_global_sync_states_id_seq OWNED BY public.singer_global_sync_states.id;


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
-- Name: daily_active_users; Type: TABLE; Schema: raw_tap_google_analytics; Owner: -
--

CREATE TABLE raw_tap_google_analytics.daily_active_users (
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
-- Name: TABLE daily_active_users; Type: COMMENT; Schema: raw_tap_google_analytics; Owner: -
--

COMMENT ON TABLE raw_tap_google_analytics.daily_active_users IS '{"path": ["daily_active_users"], "version": null, "schema_version": 2, "key_properties": ["ga_date"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_1dayusers": {"type": ["integer", "null"], "from": ["ga_1dayUsers"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: devices; Type: TABLE; Schema: raw_tap_google_analytics; Owner: -
--

CREATE TABLE raw_tap_google_analytics.devices (
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
-- Name: TABLE devices; Type: COMMENT; Schema: raw_tap_google_analytics; Owner: -
--

COMMENT ON TABLE raw_tap_google_analytics.devices IS '{"path": ["devices"], "version": null, "schema_version": 2, "key_properties": ["ga_date", "ga_deviceCategory", "ga_operatingSystem", "ga_browser"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_devicecategory": {"type": ["string"], "from": ["ga_deviceCategory"]}, "ga_operatingsystem": {"type": ["string"], "from": ["ga_operatingSystem"]}, "ga_browser": {"type": ["string"], "from": ["ga_browser"]}, "ga_users": {"type": ["integer", "null"], "from": ["ga_users"]}, "ga_newusers": {"type": ["integer", "null"], "from": ["ga_newUsers"]}, "ga_sessions": {"type": ["integer", "null"], "from": ["ga_sessions"]}, "ga_sessionsperuser": {"type": ["number", "null"], "from": ["ga_sessionsPerUser"]}, "ga_avgsessionduration": {"type": ["number", "null"], "from": ["ga_avgSessionDuration"]}, "ga_pageviews": {"type": ["integer", "null"], "from": ["ga_pageviews"]}, "ga_pageviewspersession": {"type": ["number", "null"], "from": ["ga_pageviewsPerSession"]}, "ga_avgtimeonpage": {"type": ["number", "null"], "from": ["ga_avgTimeOnPage"]}, "ga_bouncerate": {"type": ["number", "null"], "from": ["ga_bounceRate"]}, "ga_exitrate": {"type": ["number", "null"], "from": ["ga_exitRate"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: locations; Type: TABLE; Schema: raw_tap_google_analytics; Owner: -
--

CREATE TABLE raw_tap_google_analytics.locations (
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
-- Name: TABLE locations; Type: COMMENT; Schema: raw_tap_google_analytics; Owner: -
--

COMMENT ON TABLE raw_tap_google_analytics.locations IS '{"path": ["locations"], "version": null, "schema_version": 2, "key_properties": ["ga_date", "ga_continent", "ga_subContinent", "ga_country", "ga_region", "ga_metro", "ga_city"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_continent": {"type": ["string"], "from": ["ga_continent"]}, "ga_subcontinent": {"type": ["string"], "from": ["ga_subContinent"]}, "ga_country": {"type": ["string"], "from": ["ga_country"]}, "ga_region": {"type": ["string"], "from": ["ga_region"]}, "ga_metro": {"type": ["string"], "from": ["ga_metro"]}, "ga_city": {"type": ["string"], "from": ["ga_city"]}, "ga_users": {"type": ["integer", "null"], "from": ["ga_users"]}, "ga_newusers": {"type": ["integer", "null"], "from": ["ga_newUsers"]}, "ga_sessions": {"type": ["integer", "null"], "from": ["ga_sessions"]}, "ga_sessionsperuser": {"type": ["number", "null"], "from": ["ga_sessionsPerUser"]}, "ga_avgsessionduration": {"type": ["number", "null"], "from": ["ga_avgSessionDuration"]}, "ga_pageviews": {"type": ["integer", "null"], "from": ["ga_pageviews"]}, "ga_pageviewspersession": {"type": ["number", "null"], "from": ["ga_pageviewsPerSession"]}, "ga_avgtimeonpage": {"type": ["number", "null"], "from": ["ga_avgTimeOnPage"]}, "ga_bouncerate": {"type": ["number", "null"], "from": ["ga_bounceRate"]}, "ga_exitrate": {"type": ["number", "null"], "from": ["ga_exitRate"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: monthly_active_users; Type: TABLE; Schema: raw_tap_google_analytics; Owner: -
--

CREATE TABLE raw_tap_google_analytics.monthly_active_users (
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
-- Name: TABLE monthly_active_users; Type: COMMENT; Schema: raw_tap_google_analytics; Owner: -
--

COMMENT ON TABLE raw_tap_google_analytics.monthly_active_users IS '{"path": ["monthly_active_users"], "version": null, "schema_version": 2, "key_properties": ["ga_date"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_30dayusers": {"type": ["integer", "null"], "from": ["ga_30dayUsers"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: pages; Type: TABLE; Schema: raw_tap_google_analytics; Owner: -
--

CREATE TABLE raw_tap_google_analytics.pages (
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
-- Name: TABLE pages; Type: COMMENT; Schema: raw_tap_google_analytics; Owner: -
--

COMMENT ON TABLE raw_tap_google_analytics.pages IS '{"path": ["pages"], "version": null, "schema_version": 2, "key_properties": ["ga_date", "ga_hostname", "ga_pagePath"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_hostname": {"type": ["string"], "from": ["ga_hostname"]}, "ga_pagepath": {"type": ["string"], "from": ["ga_pagePath"]}, "ga_pageviews": {"type": ["integer", "null"], "from": ["ga_pageviews"]}, "ga_uniquepageviews": {"type": ["integer", "null"], "from": ["ga_uniquePageviews"]}, "ga_avgtimeonpage": {"type": ["number", "null"], "from": ["ga_avgTimeOnPage"]}, "ga_entrances": {"type": ["integer", "null"], "from": ["ga_entrances"]}, "ga_entrancerate": {"type": ["number", "null"], "from": ["ga_entranceRate"]}, "ga_bouncerate": {"type": ["number", "null"], "from": ["ga_bounceRate"]}, "ga_exits": {"type": ["integer", "null"], "from": ["ga_exits"]}, "ga_exitrate": {"type": ["number", "null"], "from": ["ga_exitRate"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: traffic_sources; Type: TABLE; Schema: raw_tap_google_analytics; Owner: -
--

CREATE TABLE raw_tap_google_analytics.traffic_sources (
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
-- Name: TABLE traffic_sources; Type: COMMENT; Schema: raw_tap_google_analytics; Owner: -
--

COMMENT ON TABLE raw_tap_google_analytics.traffic_sources IS '{"path": ["traffic_sources"], "version": null, "schema_version": 2, "key_properties": ["ga_date", "ga_source", "ga_medium", "ga_socialNetwork"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_source": {"type": ["string"], "from": ["ga_source"]}, "ga_medium": {"type": ["string"], "from": ["ga_medium"]}, "ga_socialnetwork": {"type": ["string"], "from": ["ga_socialNetwork"]}, "ga_users": {"type": ["integer", "null"], "from": ["ga_users"]}, "ga_newusers": {"type": ["integer", "null"], "from": ["ga_newUsers"]}, "ga_sessions": {"type": ["integer", "null"], "from": ["ga_sessions"]}, "ga_sessionsperuser": {"type": ["number", "null"], "from": ["ga_sessionsPerUser"]}, "ga_avgsessionduration": {"type": ["number", "null"], "from": ["ga_avgSessionDuration"]}, "ga_pageviews": {"type": ["integer", "null"], "from": ["ga_pageviews"]}, "ga_pageviewspersession": {"type": ["number", "null"], "from": ["ga_pageviewsPerSession"]}, "ga_avgtimeonpage": {"type": ["number", "null"], "from": ["ga_avgTimeOnPage"]}, "ga_bouncerate": {"type": ["number", "null"], "from": ["ga_bounceRate"]}, "ga_exitrate": {"type": ["number", "null"], "from": ["ga_exitRate"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: website_overview; Type: TABLE; Schema: raw_tap_google_analytics; Owner: -
--

CREATE TABLE raw_tap_google_analytics.website_overview (
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
-- Name: TABLE website_overview; Type: COMMENT; Schema: raw_tap_google_analytics; Owner: -
--

COMMENT ON TABLE raw_tap_google_analytics.website_overview IS '{"path": ["website_overview"], "version": null, "schema_version": 2, "key_properties": ["ga_date"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_users": {"type": ["integer", "null"], "from": ["ga_users"]}, "ga_newusers": {"type": ["integer", "null"], "from": ["ga_newUsers"]}, "ga_sessions": {"type": ["integer", "null"], "from": ["ga_sessions"]}, "ga_sessionsperuser": {"type": ["number", "null"], "from": ["ga_sessionsPerUser"]}, "ga_avgsessionduration": {"type": ["number", "null"], "from": ["ga_avgSessionDuration"]}, "ga_pageviews": {"type": ["integer", "null"], "from": ["ga_pageviews"]}, "ga_pageviewspersession": {"type": ["number", "null"], "from": ["ga_pageviewsPerSession"]}, "ga_avgtimeonpage": {"type": ["number", "null"], "from": ["ga_avgTimeOnPage"]}, "ga_bouncerate": {"type": ["number", "null"], "from": ["ga_bounceRate"]}, "ga_exitrate": {"type": ["number", "null"], "from": ["ga_exitRate"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: weekly_active_users; Type: TABLE; Schema: raw_tap_google_analytics; Owner: -
--

CREATE TABLE raw_tap_google_analytics.weekly_active_users (
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
-- Name: TABLE weekly_active_users; Type: COMMENT; Schema: raw_tap_google_analytics; Owner: -
--

COMMENT ON TABLE raw_tap_google_analytics.weekly_active_users IS '{"path": ["weekly_active_users"], "version": null, "schema_version": 2, "key_properties": ["ga_date"], "mappings": {"ga_date": {"type": ["string"], "from": ["ga_date"]}, "ga_7dayusers": {"type": ["integer", "null"], "from": ["ga_7dayUsers"]}, "report_start_date": {"type": ["string"], "from": ["report_start_date"]}, "report_end_date": {"type": ["string"], "from": ["report_end_date"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "view_id": {"type": ["integer"], "from": ["view_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: snowplow_production_enriched; Type: TABLE; Schema: raw_tap_kafka; Owner: -
--

CREATE TABLE raw_tap_kafka.snowplow_production_enriched (
    app_id text,
    platform text,
    etl_tstamp timestamp with time zone,
    collector_tstamp timestamp with time zone,
    derived_tstamp timestamp with time zone,
    true_tstamp timestamp with time zone,
    event text,
    event_id text NOT NULL,
    event_vendor text,
    event_name text,
    event_format text,
    event_version text,
    event_fingerprint text,
    txn_id bigint,
    name_tracker text,
    v_tracker text,
    v_collector text,
    v_etl text,
    user_id text,
    user_ipaddress text,
    user_fingerprint text,
    domain_userid text,
    domain_sessionidx bigint,
    domain_sessionid text,
    network_userid text,
    geo_country text,
    geo_region text,
    geo_city text,
    geo_zipcode text,
    geo_latitude double precision,
    geo_longitude double precision,
    geo_region_name text,
    geo_location text,
    ip_isp text,
    ip_organization text,
    ip_domain text,
    ip_netspeed text,
    page_url text,
    page_title text,
    page_referrer text,
    page_urlscheme text,
    page_urlhost text,
    page_urlport bigint,
    page_urlpath text,
    page_urlquery text,
    page_urlfragment text,
    refr_urlscheme text,
    refr_urlhost text,
    refr_urlport bigint,
    refr_urlpath text,
    refr_urlquery text,
    refr_urlfragment text,
    refr_medium text,
    refr_source text,
    refr_term text,
    mkt_medium text,
    mkt_source text,
    mkt_term text,
    mkt_content text,
    mkt_campaign text,
    se_category text,
    se_action text,
    se_label text,
    se_property text,
    se_value text,
    tr_orderid text,
    tr_affiliation text,
    tr_total double precision,
    tr_tax double precision,
    tr_shipping double precision,
    tr_city text,
    tr_state text,
    tr_country text,
    ti_orderid text,
    ti_sku text,
    ti_name text,
    ti_category text,
    ti_price double precision,
    ti_quantity bigint,
    pp_xoffset_min bigint,
    pp_xoffset_max bigint,
    pp_yoffset_min bigint,
    pp_yoffset_max bigint,
    useragent text,
    br_name text,
    br_family text,
    br_version text,
    br_type text,
    br_renderengine text,
    br_lang text,
    br_features_pdf boolean,
    br_features_flash boolean,
    br_features_java boolean,
    br_features_director boolean,
    br_features_quicktime boolean,
    br_features_realplayer boolean,
    br_features_windowsmedia boolean,
    br_features_gears boolean,
    br_features_silverlight boolean,
    br_cookies boolean,
    br_colordepth text,
    br_viewwidth bigint,
    br_viewheight bigint,
    os_name text,
    os_family text,
    os_manufacturer text,
    os_timezone text,
    dvce_type text,
    dvce_ismobile boolean,
    dvce_screenwidth bigint,
    dvce_screenheight bigint,
    dvce_created_tstamp timestamp with time zone,
    doc_charset text,
    doc_width bigint,
    doc_height bigint,
    tr_currency text,
    tr_total_base double precision,
    tr_tax_base double precision,
    tr_shipping_base double precision,
    ti_currency text,
    ti_price_base double precision,
    base_currency text,
    geo_timezone text,
    mkt_clickid text,
    mkt_network text,
    etl_tags text,
    dvce_sent_tstamp timestamp with time zone,
    refr_domain_userid text,
    refr_dvce_tstamp timestamp with time zone,
    session_id text,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone,
    _sdc_primary_key text NOT NULL
);


--
-- Name: TABLE snowplow_production_enriched; Type: COMMENT; Schema: raw_tap_kafka; Owner: -
--

COMMENT ON TABLE raw_tap_kafka.snowplow_production_enriched IS '{"path": ["snowplow-production-enriched"], "version": null, "schema_version": 2, "key_properties": ["_sdc_primary_key"], "mappings": {"app_id": {"type": ["string", "null"], "from": ["app_id"]}, "platform": {"type": ["string", "null"], "from": ["platform"]}, "etl_tstamp": {"type": ["string", "null"], "from": ["etl_tstamp"], "format": "date-time"}, "collector_tstamp": {"type": ["string", "null"], "from": ["collector_tstamp"], "format": "date-time"}, "derived_tstamp": {"type": ["string", "null"], "from": ["derived_tstamp"], "format": "date-time"}, "true_tstamp": {"type": ["string", "null"], "from": ["true_tstamp"], "format": "date-time"}, "event": {"type": ["string", "null"], "from": ["event"]}, "event_id": {"type": ["string"], "from": ["event_id"]}, "event_vendor": {"type": ["string", "null"], "from": ["event_vendor"]}, "event_name": {"type": ["string", "null"], "from": ["event_name"]}, "event_format": {"type": ["string", "null"], "from": ["event_format"]}, "event_version": {"type": ["string", "null"], "from": ["event_version"]}, "event_fingerprint": {"type": ["string", "null"], "from": ["event_fingerprint"]}, "txn_id": {"type": ["integer", "null"], "from": ["txn_id"]}, "name_tracker": {"type": ["string", "null"], "from": ["name_tracker"]}, "v_tracker": {"type": ["string", "null"], "from": ["v_tracker"]}, "v_collector": {"type": ["string", "null"], "from": ["v_collector"]}, "v_etl": {"type": ["string", "null"], "from": ["v_etl"]}, "user_id": {"type": ["string", "null"], "from": ["user_id"]}, "user_ipaddress": {"type": ["string", "null"], "from": ["user_ipaddress"]}, "user_fingerprint": {"type": ["string", "null"], "from": ["user_fingerprint"]}, "domain_userid": {"type": ["string", "null"], "from": ["domain_userid"]}, "domain_sessionidx": {"type": ["integer", "null"], "from": ["domain_sessionidx"]}, "domain_sessionid": {"type": ["string", "null"], "from": ["domain_sessionid"]}, "network_userid": {"type": ["string", "null"], "from": ["network_userid"]}, "geo_country": {"type": ["string", "null"], "from": ["geo_country"]}, "geo_region": {"type": ["string", "null"], "from": ["geo_region"]}, "geo_city": {"type": ["string", "null"], "from": ["geo_city"]}, "geo_zipcode": {"type": ["string", "null"], "from": ["geo_zipcode"]}, "geo_latitude": {"type": ["number", "null"], "from": ["geo_latitude"]}, "geo_longitude": {"type": ["number", "null"], "from": ["geo_longitude"]}, "geo_region_name": {"type": ["string", "null"], "from": ["geo_region_name"]}, "geo_location": {"type": ["string", "null"], "from": ["geo_location"]}, "ip_isp": {"type": ["string", "null"], "from": ["ip_isp"]}, "ip_organization": {"type": ["string", "null"], "from": ["ip_organization"]}, "ip_domain": {"type": ["string", "null"], "from": ["ip_domain"]}, "ip_netspeed": {"type": ["string", "null"], "from": ["ip_netspeed"]}, "page_url": {"type": ["string", "null"], "from": ["page_url"]}, "page_title": {"type": ["string", "null"], "from": ["page_title"]}, "page_referrer": {"type": ["string", "null"], "from": ["page_referrer"]}, "page_urlscheme": {"type": ["string", "null"], "from": ["page_urlscheme"]}, "page_urlhost": {"type": ["string", "null"], "from": ["page_urlhost"]}, "page_urlport": {"type": ["integer", "null"], "from": ["page_urlport"]}, "page_urlpath": {"type": ["string", "null"], "from": ["page_urlpath"]}, "page_urlquery": {"type": ["string", "null"], "from": ["page_urlquery"]}, "page_urlfragment": {"type": ["string", "null"], "from": ["page_urlfragment"]}, "refr_urlscheme": {"type": ["string", "null"], "from": ["refr_urlscheme"]}, "refr_urlhost": {"type": ["string", "null"], "from": ["refr_urlhost"]}, "refr_urlport": {"type": ["integer", "null"], "from": ["refr_urlport"]}, "refr_urlpath": {"type": ["string", "null"], "from": ["refr_urlpath"]}, "refr_urlquery": {"type": ["string", "null"], "from": ["refr_urlquery"]}, "refr_urlfragment": {"type": ["string", "null"], "from": ["refr_urlfragment"]}, "refr_medium": {"type": ["string", "null"], "from": ["refr_medium"]}, "refr_source": {"type": ["string", "null"], "from": ["refr_source"]}, "refr_term": {"type": ["string", "null"], "from": ["refr_term"]}, "mkt_medium": {"type": ["string", "null"], "from": ["mkt_medium"]}, "mkt_source": {"type": ["string", "null"], "from": ["mkt_source"]}, "mkt_term": {"type": ["string", "null"], "from": ["mkt_term"]}, "mkt_content": {"type": ["string", "null"], "from": ["mkt_content"]}, "mkt_campaign": {"type": ["string", "null"], "from": ["mkt_campaign"]}, "se_category": {"type": ["string", "null"], "from": ["se_category"]}, "se_action": {"type": ["string", "null"], "from": ["se_action"]}, "se_label": {"type": ["string", "null"], "from": ["se_label"]}, "se_property": {"type": ["string", "null"], "from": ["se_property"]}, "se_value": {"type": ["string", "null"], "from": ["se_value"]}, "tr_orderid": {"type": ["string", "null"], "from": ["tr_orderid"]}, "tr_affiliation": {"type": ["string", "null"], "from": ["tr_affiliation"]}, "tr_total": {"type": ["number", "null"], "from": ["tr_total"]}, "tr_tax": {"type": ["number", "null"], "from": ["tr_tax"]}, "tr_shipping": {"type": ["number", "null"], "from": ["tr_shipping"]}, "tr_city": {"type": ["string", "null"], "from": ["tr_city"]}, "tr_state": {"type": ["string", "null"], "from": ["tr_state"]}, "tr_country": {"type": ["string", "null"], "from": ["tr_country"]}, "ti_orderid": {"type": ["string", "null"], "from": ["ti_orderid"]}, "ti_sku": {"type": ["string", "null"], "from": ["ti_sku"]}, "ti_name": {"type": ["string", "null"], "from": ["ti_name"]}, "ti_category": {"type": ["string", "null"], "from": ["ti_category"]}, "ti_price": {"type": ["number", "null"], "from": ["ti_price"]}, "ti_quantity": {"type": ["integer", "null"], "from": ["ti_quantity"]}, "pp_xoffset_min": {"type": ["integer", "null"], "from": ["pp_xoffset_min"]}, "pp_xoffset_max": {"type": ["integer", "null"], "from": ["pp_xoffset_max"]}, "pp_yoffset_min": {"type": ["integer", "null"], "from": ["pp_yoffset_min"]}, "pp_yoffset_max": {"type": ["integer", "null"], "from": ["pp_yoffset_max"]}, "useragent": {"type": ["string", "null"], "from": ["useragent"]}, "br_name": {"type": ["string", "null"], "from": ["br_name"]}, "br_family": {"type": ["string", "null"], "from": ["br_family"]}, "br_version": {"type": ["string", "null"], "from": ["br_version"]}, "br_type": {"type": ["string", "null"], "from": ["br_type"]}, "br_renderengine": {"type": ["string", "null"], "from": ["br_renderengine"]}, "br_lang": {"type": ["string", "null"], "from": ["br_lang"]}, "br_features_pdf": {"type": ["boolean", "null"], "from": ["br_features_pdf"]}, "br_features_flash": {"type": ["boolean", "null"], "from": ["br_features_flash"]}, "br_features_java": {"type": ["boolean", "null"], "from": ["br_features_java"]}, "br_features_director": {"type": ["boolean", "null"], "from": ["br_features_director"]}, "br_features_quicktime": {"type": ["boolean", "null"], "from": ["br_features_quicktime"]}, "br_features_realplayer": {"type": ["boolean", "null"], "from": ["br_features_realplayer"]}, "br_features_windowsmedia": {"type": ["boolean", "null"], "from": ["br_features_windowsmedia"]}, "br_features_gears": {"type": ["boolean", "null"], "from": ["br_features_gears"]}, "br_features_silverlight": {"type": ["boolean", "null"], "from": ["br_features_silverlight"]}, "br_cookies": {"type": ["boolean", "null"], "from": ["br_cookies"]}, "br_colordepth": {"type": ["string", "null"], "from": ["br_colordepth"]}, "br_viewwidth": {"type": ["integer", "null"], "from": ["br_viewwidth"]}, "br_viewheight": {"type": ["integer", "null"], "from": ["br_viewheight"]}, "os_name": {"type": ["string", "null"], "from": ["os_name"]}, "os_family": {"type": ["string", "null"], "from": ["os_family"]}, "os_manufacturer": {"type": ["string", "null"], "from": ["os_manufacturer"]}, "os_timezone": {"type": ["string", "null"], "from": ["os_timezone"]}, "dvce_type": {"type": ["string", "null"], "from": ["dvce_type"]}, "dvce_ismobile": {"type": ["boolean", "null"], "from": ["dvce_ismobile"]}, "dvce_screenwidth": {"type": ["integer", "null"], "from": ["dvce_screenwidth"]}, "dvce_screenheight": {"type": ["integer", "null"], "from": ["dvce_screenheight"]}, "dvce_created_tstamp": {"type": ["string", "null"], "from": ["dvce_created_tstamp"], "format": "date-time"}, "doc_charset": {"type": ["string", "null"], "from": ["doc_charset"]}, "doc_width": {"type": ["integer", "null"], "from": ["doc_width"]}, "doc_height": {"type": ["integer", "null"], "from": ["doc_height"]}, "tr_currency": {"type": ["string", "null"], "from": ["tr_currency"]}, "tr_total_base": {"type": ["number", "null"], "from": ["tr_total_base"]}, "tr_tax_base": {"type": ["number", "null"], "from": ["tr_tax_base"]}, "tr_shipping_base": {"type": ["number", "null"], "from": ["tr_shipping_base"]}, "ti_currency": {"type": ["string", "null"], "from": ["ti_currency"]}, "ti_price_base": {"type": ["number", "null"], "from": ["ti_price_base"]}, "base_currency": {"type": ["string", "null"], "from": ["base_currency"]}, "geo_timezone": {"type": ["string", "null"], "from": ["geo_timezone"]}, "mkt_clickid": {"type": ["string", "null"], "from": ["mkt_clickid"]}, "mkt_network": {"type": ["string", "null"], "from": ["mkt_network"]}, "etl_tags": {"type": ["string", "null"], "from": ["etl_tags"]}, "dvce_sent_tstamp": {"type": ["string", "null"], "from": ["dvce_sent_tstamp"], "format": "date-time"}, "refr_domain_userid": {"type": ["string", "null"], "from": ["refr_domain_userid"]}, "refr_dvce_tstamp": {"type": ["string", "null"], "from": ["refr_dvce_tstamp"], "format": "date-time"}, "session_id": {"type": ["string", "null"], "from": ["session_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}, "_sdc_primary_key": {"type": ["string"], "from": ["_sdc_primary_key"]}}}';


--
-- Name: snowplow_production_enriched__contexts_com_google_analytics_coo; Type: TABLE; Schema: raw_tap_kafka; Owner: -
--

CREATE TABLE raw_tap_kafka.snowplow_production_enriched__contexts_com_google_analytics_coo (
    _ga text,
    _sdc_source_key__sdc_primary_key text NOT NULL,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE snowplow_production_enriched__contexts_com_google_analytics_coo; Type: COMMENT; Schema: raw_tap_kafka; Owner: -
--

COMMENT ON TABLE raw_tap_kafka.snowplow_production_enriched__contexts_com_google_analytics_coo IS '{"path": ["snowplow-production-enriched", "contexts_com_google_analytics_cookies_1"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key__sdc_primary_key"], "mappings": {"_ga": {"type": ["string", "null"], "from": ["_ga"]}, "_sdc_source_key__sdc_primary_key": {"type": ["string"], "from": ["_sdc_source_key__sdc_primary_key"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: snowplow_production_enriched__contexts_com_snowplowanalytics__1; Type: TABLE; Schema: raw_tap_kafka; Owner: -
--

CREATE TABLE raw_tap_kafka.snowplow_production_enriched__contexts_com_snowplowanalytics__1 (
    useragentfamily text,
    useragentmajor text,
    useragentminor text,
    useragentpatch text,
    useragentversion text,
    osfamily text,
    osmajor text,
    osminor text,
    ospatch text,
    ospatchminor text,
    osversion text,
    devicefamily text,
    _sdc_source_key__sdc_primary_key text NOT NULL,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE snowplow_production_enriched__contexts_com_snowplowanalytics__1; Type: COMMENT; Schema: raw_tap_kafka; Owner: -
--

COMMENT ON TABLE raw_tap_kafka.snowplow_production_enriched__contexts_com_snowplowanalytics__1 IS '{"path": ["snowplow-production-enriched", "contexts_com_snowplowanalytics_snowplow_ua_parser_context_1"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key__sdc_primary_key"], "mappings": {"useragentfamily": {"type": ["string", "null"], "from": ["useragentFamily"]}, "useragentmajor": {"type": ["string", "null"], "from": ["useragentMajor"]}, "useragentminor": {"type": ["string", "null"], "from": ["useragentMinor"]}, "useragentpatch": {"type": ["string", "null"], "from": ["useragentPatch"]}, "useragentversion": {"type": ["string", "null"], "from": ["useragentVersion"]}, "osfamily": {"type": ["string", "null"], "from": ["osFamily"]}, "osmajor": {"type": ["string", "null"], "from": ["osMajor"]}, "osminor": {"type": ["string", "null"], "from": ["osMinor"]}, "ospatch": {"type": ["string", "null"], "from": ["osPatch"]}, "ospatchminor": {"type": ["string", "null"], "from": ["osPatchMinor"]}, "osversion": {"type": ["string", "null"], "from": ["osVersion"]}, "devicefamily": {"type": ["string", "null"], "from": ["deviceFamily"]}, "_sdc_source_key__sdc_primary_key": {"type": ["string"], "from": ["_sdc_source_key__sdc_primary_key"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: snowplow_production_enriched__contexts_com_snowplowanalytics_sn; Type: TABLE; Schema: raw_tap_kafka; Owner: -
--

CREATE TABLE raw_tap_kafka.snowplow_production_enriched__contexts_com_snowplowanalytics_sn (
    id text,
    _sdc_source_key__sdc_primary_key text NOT NULL,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE snowplow_production_enriched__contexts_com_snowplowanalytics_sn; Type: COMMENT; Schema: raw_tap_kafka; Owner: -
--

COMMENT ON TABLE raw_tap_kafka.snowplow_production_enriched__contexts_com_snowplowanalytics_sn IS '{"path": ["snowplow-production-enriched", "contexts_com_snowplowanalytics_snowplow_web_page_1"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key__sdc_primary_key"], "mappings": {"id": {"type": ["string", "null"], "from": ["id"]}, "_sdc_source_key__sdc_primary_key": {"type": ["string"], "from": ["_sdc_source_key__sdc_primary_key"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: snowplow_production_enriched__contexts_com_superpro_shopify___1; Type: TABLE; Schema: raw_tap_kafka; Owner: -
--

CREATE TABLE raw_tap_kafka.snowplow_production_enriched__contexts_com_superpro_shopify___1 (
    selectedvariantid text,
    currency text,
    product__id double precision,
    product__type text,
    product__vendor text,
    page__pagetype text,
    page__resourceid double precision,
    page__resourcetype text,
    _sdc_source_key__sdc_primary_key text NOT NULL,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE snowplow_production_enriched__contexts_com_superpro_shopify___1; Type: COMMENT; Schema: raw_tap_kafka; Owner: -
--

COMMENT ON TABLE raw_tap_kafka.snowplow_production_enriched__contexts_com_superpro_shopify___1 IS '{"path": ["snowplow-production-enriched", "contexts_com_superpro_shopify_page_meta_1"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key__sdc_primary_key"], "mappings": {"selectedvariantid": {"type": ["string", "null"], "from": ["selectedVariantId"]}, "currency": {"type": ["string", "null"], "from": ["currency"]}, "product__id": {"type": ["number", "null"], "from": ["product", "id"]}, "product__type": {"type": ["string", "null"], "from": ["product", "type"]}, "product__vendor": {"type": ["string", "null"], "from": ["product", "vendor"]}, "page__pagetype": {"type": ["string", "null"], "from": ["page", "pageType"]}, "page__resourceid": {"type": ["number", "null"], "from": ["page", "resourceId"]}, "page__resourcetype": {"type": ["string", "null"], "from": ["page", "resourceType"]}, "_sdc_source_key__sdc_primary_key": {"type": ["string"], "from": ["_sdc_source_key__sdc_primary_key"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: snowplow_production_enriched__contexts_com_superpro_shopify_pag; Type: TABLE; Schema: raw_tap_kafka; Owner: -
--

CREATE TABLE raw_tap_kafka.snowplow_production_enriched__contexts_com_superpro_shopify_pag (
    id double precision,
    price double precision,
    name text,
    public_title text,
    sku text,
    _sdc_source_key__sdc_primary_key text NOT NULL,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE snowplow_production_enriched__contexts_com_superpro_shopify_pag; Type: COMMENT; Schema: raw_tap_kafka; Owner: -
--

COMMENT ON TABLE raw_tap_kafka.snowplow_production_enriched__contexts_com_superpro_shopify_pag IS '{"path": ["snowplow-production-enriched", "contexts_com_superpro_shopify_page_meta_1", "product", "variants"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key__sdc_primary_key"], "mappings": {"id": {"type": ["number", "null"], "from": ["id"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "public_title": {"type": ["string", "null"], "from": ["public_title"]}, "sku": {"type": ["string", "null"], "from": ["sku"]}, "_sdc_source_key__sdc_primary_key": {"type": ["string"], "from": ["_sdc_source_key__sdc_primary_key"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: snowplow_production_enriched__contexts_org_w3_performance_timin; Type: TABLE; Schema: raw_tap_kafka; Owner: -
--

CREATE TABLE raw_tap_kafka.snowplow_production_enriched__contexts_org_w3_performance_timin (
    navigationstart double precision,
    unloadeventstart double precision,
    unloadeventend double precision,
    redirectstart double precision,
    redirectend double precision,
    fetchstart double precision,
    domainlookupstart double precision,
    domainlookupend double precision,
    connectstart double precision,
    connectend double precision,
    secureconnectionstart double precision,
    requeststart double precision,
    responsestart double precision,
    responseend double precision,
    domloading double precision,
    dominteractive double precision,
    domcontentloadedeventstart double precision,
    domcontentloadedeventend double precision,
    domcomplete double precision,
    loadeventstart double precision,
    loadeventend double precision,
    _sdc_source_key__sdc_primary_key text NOT NULL,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE snowplow_production_enriched__contexts_org_w3_performance_timin; Type: COMMENT; Schema: raw_tap_kafka; Owner: -
--

COMMENT ON TABLE raw_tap_kafka.snowplow_production_enriched__contexts_org_w3_performance_timin IS '{"path": ["snowplow-production-enriched", "contexts_org_w3_performance_timing_1"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key__sdc_primary_key"], "mappings": {"navigationstart": {"type": ["number", "null"], "from": ["navigationStart"]}, "unloadeventstart": {"type": ["number", "null"], "from": ["unloadEventStart"]}, "unloadeventend": {"type": ["number", "null"], "from": ["unloadEventEnd"]}, "redirectstart": {"type": ["number", "null"], "from": ["redirectStart"]}, "redirectend": {"type": ["number", "null"], "from": ["redirectEnd"]}, "fetchstart": {"type": ["number", "null"], "from": ["fetchStart"]}, "domainlookupstart": {"type": ["number", "null"], "from": ["domainLookupStart"]}, "domainlookupend": {"type": ["number", "null"], "from": ["domainLookupEnd"]}, "connectstart": {"type": ["number", "null"], "from": ["connectStart"]}, "connectend": {"type": ["number", "null"], "from": ["connectEnd"]}, "secureconnectionstart": {"type": ["number", "null"], "from": ["secureConnectionStart"]}, "requeststart": {"type": ["number", "null"], "from": ["requestStart"]}, "responsestart": {"type": ["number", "null"], "from": ["responseStart"]}, "responseend": {"type": ["number", "null"], "from": ["responseEnd"]}, "domloading": {"type": ["number", "null"], "from": ["domLoading"]}, "dominteractive": {"type": ["number", "null"], "from": ["domInteractive"]}, "domcontentloadedeventstart": {"type": ["number", "null"], "from": ["domContentLoadedEventStart"]}, "domcontentloadedeventend": {"type": ["number", "null"], "from": ["domContentLoadedEventEnd"]}, "domcomplete": {"type": ["number", "null"], "from": ["domComplete"]}, "loadeventstart": {"type": ["number", "null"], "from": ["loadEventStart"]}, "loadeventend": {"type": ["number", "null"], "from": ["loadEventEnd"]}, "_sdc_source_key__sdc_primary_key": {"type": ["string"], "from": ["_sdc_source_key__sdc_primary_key"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: snowplow_production_enriched_bad; Type: TABLE; Schema: raw_tap_kafka; Owner: -
--

CREATE TABLE raw_tap_kafka.snowplow_production_enriched_bad (
    line text,
    failure_tstamp timestamp with time zone,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone,
    _sdc_primary_key text NOT NULL
);


--
-- Name: TABLE snowplow_production_enriched_bad; Type: COMMENT; Schema: raw_tap_kafka; Owner: -
--

COMMENT ON TABLE raw_tap_kafka.snowplow_production_enriched_bad IS '{"path": ["snowplow-production-enriched-bad"], "version": null, "schema_version": 2, "key_properties": ["_sdc_primary_key"], "mappings": {"line": {"type": ["string", "null"], "from": ["line"]}, "failure_tstamp": {"type": ["string", "null"], "from": ["failure_tstamp"], "format": "date-time"}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}, "_sdc_primary_key": {"type": ["string"], "from": ["_sdc_primary_key"]}}}';


--
-- Name: snowplow_production_enriched_bad__errors; Type: TABLE; Schema: raw_tap_kafka; Owner: -
--

CREATE TABLE raw_tap_kafka.snowplow_production_enriched_bad__errors (
    level text,
    message text,
    _sdc_source_key__sdc_primary_key text NOT NULL,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE snowplow_production_enriched_bad__errors; Type: COMMENT; Schema: raw_tap_kafka; Owner: -
--

COMMENT ON TABLE raw_tap_kafka.snowplow_production_enriched_bad__errors IS '{"path": ["snowplow-production-enriched-bad", "errors"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key__sdc_primary_key"], "mappings": {"level": {"type": ["string", "null"], "from": ["level"]}, "message": {"type": ["string", "null"], "from": ["message"]}, "_sdc_source_key__sdc_primary_key": {"type": ["string"], "from": ["_sdc_source_key__sdc_primary_key"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: abandoned_checkouts; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts (
    location_id bigint,
    buyer_accepts_marketing boolean,
    currency text,
    completed_at timestamp with time zone,
    token text,
    billing_address__phone text,
    billing_address__country text,
    billing_address__first_name text,
    billing_address__name text,
    billing_address__latitude double precision,
    billing_address__zip text,
    billing_address__last_name text,
    billing_address__province text,
    billing_address__address2 text,
    billing_address__address1 text,
    billing_address__country_code text,
    billing_address__city text,
    billing_address__company text,
    billing_address__province_code text,
    billing_address__longitude double precision,
    email text,
    customer_locale text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    gateway text,
    referring_site text,
    source_identifier text,
    total_weight bigint,
    total_line_items_price double precision,
    closed_at timestamp with time zone,
    device_id bigint,
    phone text,
    source_name text,
    id bigint,
    name text,
    total_tax double precision,
    subtotal_price double precision,
    source_url text,
    total_discounts double precision,
    note text,
    presentment_currency text,
    user_id bigint,
    source text,
    shipping_address__phone text,
    shipping_address__country text,
    shipping_address__first_name text,
    shipping_address__name text,
    shipping_address__latitude double precision,
    shipping_address__zip text,
    shipping_address__last_name text,
    shipping_address__province text,
    shipping_address__address2 text,
    shipping_address__address1 text,
    shipping_address__country_code text,
    shipping_address__city text,
    shipping_address__company text,
    shipping_address__province_code text,
    shipping_address__longitude double precision,
    abandoned_checkout_url text,
    landing_site text,
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
    total_price double precision,
    cart_token text,
    taxes_included boolean,
    account_id bigint NOT NULL,
    shop_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE abandoned_checkouts; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts IS '{"path": ["abandoned_checkouts"], "version": null, "schema_version": 2, "key_properties": ["id"], "mappings": {"location_id": {"type": ["integer", "null"], "from": ["location_id"]}, "buyer_accepts_marketing": {"type": ["boolean", "null"], "from": ["buyer_accepts_marketing"]}, "currency": {"type": ["string", "null"], "from": ["currency"]}, "completed_at": {"type": ["string", "null"], "from": ["completed_at"], "format": "date-time"}, "token": {"type": ["string", "null"], "from": ["token"]}, "billing_address__phone": {"type": ["string", "null"], "from": ["billing_address", "phone"]}, "billing_address__country": {"type": ["string", "null"], "from": ["billing_address", "country"]}, "billing_address__first_name": {"type": ["string", "null"], "from": ["billing_address", "first_name"]}, "billing_address__name": {"type": ["string", "null"], "from": ["billing_address", "name"]}, "billing_address__latitude": {"type": ["number", "null"], "from": ["billing_address", "latitude"]}, "billing_address__zip": {"type": ["string", "null"], "from": ["billing_address", "zip"]}, "billing_address__last_name": {"type": ["string", "null"], "from": ["billing_address", "last_name"]}, "billing_address__province": {"type": ["string", "null"], "from": ["billing_address", "province"]}, "billing_address__address2": {"type": ["string", "null"], "from": ["billing_address", "address2"]}, "billing_address__address1": {"type": ["string", "null"], "from": ["billing_address", "address1"]}, "billing_address__country_code": {"type": ["string", "null"], "from": ["billing_address", "country_code"]}, "billing_address__city": {"type": ["string", "null"], "from": ["billing_address", "city"]}, "billing_address__company": {"type": ["string", "null"], "from": ["billing_address", "company"]}, "billing_address__province_code": {"type": ["string", "null"], "from": ["billing_address", "province_code"]}, "billing_address__longitude": {"type": ["number", "null"], "from": ["billing_address", "longitude"]}, "email": {"type": ["string", "null"], "from": ["email"]}, "customer_locale": {"type": ["string", "null"], "from": ["customer_locale"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "gateway": {"type": ["string", "null"], "from": ["gateway"]}, "referring_site": {"type": ["string", "null"], "from": ["referring_site"]}, "source_identifier": {"type": ["string", "null"], "from": ["source_identifier"]}, "total_weight": {"type": ["integer", "null"], "from": ["total_weight"]}, "total_line_items_price": {"type": ["number", "null"], "from": ["total_line_items_price"]}, "closed_at": {"type": ["string", "null"], "from": ["closed_at"], "format": "date-time"}, "device_id": {"type": ["integer", "null"], "from": ["device_id"]}, "phone": {"type": ["string", "null"], "from": ["phone"]}, "source_name": {"type": ["string", "null"], "from": ["source_name"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "total_tax": {"type": ["number", "null"], "from": ["total_tax"]}, "subtotal_price": {"type": ["number", "null"], "from": ["subtotal_price"]}, "source_url": {"type": ["string", "null"], "from": ["source_url"]}, "total_discounts": {"type": ["number", "null"], "from": ["total_discounts"]}, "note": {"type": ["string", "null"], "from": ["note"]}, "presentment_currency": {"type": ["string", "null"], "from": ["presentment_currency"]}, "user_id": {"type": ["integer", "null"], "from": ["user_id"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "shipping_address__phone": {"type": ["string", "null"], "from": ["shipping_address", "phone"]}, "shipping_address__country": {"type": ["string", "null"], "from": ["shipping_address", "country"]}, "shipping_address__first_name": {"type": ["string", "null"], "from": ["shipping_address", "first_name"]}, "shipping_address__name": {"type": ["string", "null"], "from": ["shipping_address", "name"]}, "shipping_address__latitude": {"type": ["number", "null"], "from": ["shipping_address", "latitude"]}, "shipping_address__zip": {"type": ["string", "null"], "from": ["shipping_address", "zip"]}, "shipping_address__last_name": {"type": ["string", "null"], "from": ["shipping_address", "last_name"]}, "shipping_address__province": {"type": ["string", "null"], "from": ["shipping_address", "province"]}, "shipping_address__address2": {"type": ["string", "null"], "from": ["shipping_address", "address2"]}, "shipping_address__address1": {"type": ["string", "null"], "from": ["shipping_address", "address1"]}, "shipping_address__country_code": {"type": ["string", "null"], "from": ["shipping_address", "country_code"]}, "shipping_address__city": {"type": ["string", "null"], "from": ["shipping_address", "city"]}, "shipping_address__company": {"type": ["string", "null"], "from": ["shipping_address", "company"]}, "shipping_address__province_code": {"type": ["string", "null"], "from": ["shipping_address", "province_code"]}, "shipping_address__longitude": {"type": ["number", "null"], "from": ["shipping_address", "longitude"]}, "abandoned_checkout_url": {"type": ["string", "null"], "from": ["abandoned_checkout_url"]}, "landing_site": {"type": ["string", "null"], "from": ["landing_site"]}, "customer__last_order_name": {"type": ["string", "null"], "from": ["customer", "last_order_name"]}, "customer__currency": {"type": ["string", "null"], "from": ["customer", "currency"]}, "customer__email": {"type": ["string", "null"], "from": ["customer", "email"]}, "customer__multipass_identifier": {"type": ["string", "null"], "from": ["customer", "multipass_identifier"]}, "customer__default_address__city": {"type": ["string", "null"], "from": ["customer", "default_address", "city"]}, "customer__default_address__address1": {"type": ["string", "null"], "from": ["customer", "default_address", "address1"]}, "customer__default_address__zip": {"type": ["string", "null"], "from": ["customer", "default_address", "zip"]}, "customer__default_address__id": {"type": ["integer", "null"], "from": ["customer", "default_address", "id"]}, "customer__default_address__country_name": {"type": ["string", "null"], "from": ["customer", "default_address", "country_name"]}, "customer__default_address__province": {"type": ["string", "null"], "from": ["customer", "default_address", "province"]}, "customer__default_address__phone": {"type": ["string", "null"], "from": ["customer", "default_address", "phone"]}, "customer__default_address__country": {"type": ["string", "null"], "from": ["customer", "default_address", "country"]}, "customer__default_address__first_name": {"type": ["string", "null"], "from": ["customer", "default_address", "first_name"]}, "customer__default_address__customer_id": {"type": ["integer", "null"], "from": ["customer", "default_address", "customer_id"]}, "customer__default_address__default": {"type": ["boolean", "null"], "from": ["customer", "default_address", "default"]}, "customer__default_address__last_name": {"type": ["string", "null"], "from": ["customer", "default_address", "last_name"]}, "customer__default_address__country_code": {"type": ["string", "null"], "from": ["customer", "default_address", "country_code"]}, "customer__default_address__name": {"type": ["string", "null"], "from": ["customer", "default_address", "name"]}, "customer__default_address__province_code": {"type": ["string", "null"], "from": ["customer", "default_address", "province_code"]}, "customer__default_address__address2": {"type": ["string", "null"], "from": ["customer", "default_address", "address2"]}, "customer__default_address__company": {"type": ["string", "null"], "from": ["customer", "default_address", "company"]}, "customer__orders_count": {"type": ["integer", "null"], "from": ["customer", "orders_count"]}, "customer__state": {"type": ["string", "null"], "from": ["customer", "state"]}, "customer__verified_email": {"type": ["boolean", "null"], "from": ["customer", "verified_email"]}, "customer__total_spent": {"type": ["string", "null"], "from": ["customer", "total_spent"]}, "customer__last_order_id": {"type": ["integer", "null"], "from": ["customer", "last_order_id"]}, "customer__first_name": {"type": ["string", "null"], "from": ["customer", "first_name"]}, "customer__updated_at": {"type": ["string", "null"], "from": ["customer", "updated_at"], "format": "date-time"}, "customer__note": {"type": ["string", "null"], "from": ["customer", "note"]}, "customer__phone": {"type": ["string", "null"], "from": ["customer", "phone"]}, "customer__admin_graphql_api_id": {"type": ["string", "null"], "from": ["customer", "admin_graphql_api_id"]}, "customer__last_name": {"type": ["string", "null"], "from": ["customer", "last_name"]}, "customer__tags": {"type": ["string", "null"], "from": ["customer", "tags"]}, "customer__tax_exempt": {"type": ["boolean", "null"], "from": ["customer", "tax_exempt"]}, "customer__id": {"type": ["integer", "null"], "from": ["customer", "id"]}, "customer__accepts_marketing": {"type": ["boolean", "null"], "from": ["customer", "accepts_marketing"]}, "customer__created_at": {"type": ["string", "null"], "from": ["customer", "created_at"], "format": "date-time"}, "total_price": {"type": ["number", "null"], "from": ["total_price"]}, "cart_token": {"type": ["string", "null"], "from": ["cart_token"]}, "taxes_included": {"type": ["boolean", "null"], "from": ["taxes_included"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "shop_id": {"type": ["integer"], "from": ["shop_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: abandoned_checkouts__customer__addresses; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__customer__addresses (
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
-- Name: TABLE abandoned_checkouts__customer__addresses; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__customer__addresses IS '{"path": ["abandoned_checkouts", "customer", "addresses"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"city": {"type": ["string", "null"], "from": ["city"]}, "address1": {"type": ["string", "null"], "from": ["address1"]}, "zip": {"type": ["string", "null"], "from": ["zip"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "country_name": {"type": ["string", "null"], "from": ["country_name"]}, "province": {"type": ["string", "null"], "from": ["province"]}, "phone": {"type": ["string", "null"], "from": ["phone"]}, "country": {"type": ["string", "null"], "from": ["country"]}, "first_name": {"type": ["string", "null"], "from": ["first_name"]}, "customer_id": {"type": ["integer", "null"], "from": ["customer_id"]}, "default": {"type": ["boolean", "null"], "from": ["default"]}, "last_name": {"type": ["string", "null"], "from": ["last_name"]}, "country_code": {"type": ["string", "null"], "from": ["country_code"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "province_code": {"type": ["string", "null"], "from": ["province_code"]}, "address2": {"type": ["string", "null"], "from": ["address2"]}, "company": {"type": ["string", "null"], "from": ["company"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: abandoned_checkouts__discount_codes; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__discount_codes (
    type text,
    amount double precision,
    code text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE abandoned_checkouts__discount_codes; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__discount_codes IS '{"path": ["abandoned_checkouts", "discount_codes"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"type": {"type": ["string", "null"], "from": ["type"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "code": {"type": ["string", "null"], "from": ["code"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: abandoned_checkouts__line_items; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__line_items (
    total_discount_set__shop_money__amount text,
    total_discount_set__shop_money__currency_code text,
    total_discount_set__presentment_money__amount text,
    total_discount_set__presentment_money__currency_code text,
    pre_tax_price_set__shop_money__amount text,
    pre_tax_price_set__shop_money__currency_code text,
    pre_tax_price_set__presentment_money__amount text,
    pre_tax_price_set__presentment_money__currency_code text,
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE abandoned_checkouts__line_items; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__line_items IS '{"path": ["abandoned_checkouts", "line_items"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"total_discount_set__shop_money__amount": {"type": ["string", "null"], "from": ["total_discount_set", "shop_money", "amount"]}, "total_discount_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["total_discount_set", "shop_money", "currency_code"]}, "total_discount_set__presentment_money__amount": {"type": ["string", "null"], "from": ["total_discount_set", "presentment_money", "amount"]}, "total_discount_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["total_discount_set", "presentment_money", "currency_code"]}, "pre_tax_price_set__shop_money__amount": {"type": ["string", "null"], "from": ["pre_tax_price_set", "shop_money", "amount"]}, "pre_tax_price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["pre_tax_price_set", "shop_money", "currency_code"]}, "pre_tax_price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["pre_tax_price_set", "presentment_money", "amount"]}, "pre_tax_price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["pre_tax_price_set", "presentment_money", "currency_code"]}, "price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "grams": {"type": ["integer", "null"], "from": ["grams"]}, "compare_at_price": {"type": ["string", "null"], "from": ["compare_at_price"]}, "destination_location_id": {"type": ["integer", "null"], "from": ["destination_location_id"]}, "key": {"type": ["string", "null"], "from": ["key"]}, "line_price": {"type": ["string", "null"], "from": ["line_price"]}, "origin_location_id": {"type": ["integer", "null"], "from": ["origin_location_id"]}, "applied_discount": {"type": ["integer", "null"], "from": ["applied_discount"]}, "fulfillable_quantity": {"type": ["integer", "null"], "from": ["fulfillable_quantity"]}, "variant_title": {"type": ["string", "null"], "from": ["variant_title"]}, "tax_code": {"type": ["string", "null"], "from": ["tax_code"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "pre_tax_price": {"type": ["number", "null"], "from": ["pre_tax_price"]}, "sku": {"type": ["string", "null"], "from": ["sku"]}, "product_exists": {"type": ["boolean", "null"], "from": ["product_exists"]}, "total_discount": {"type": ["number", "null"], "from": ["total_discount"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "fulfillment_status": {"type": ["string", "null"], "from": ["fulfillment_status"]}, "gift_card": {"type": ["boolean", "null"], "from": ["gift_card"]}, "id__i": {"type": ["integer", "null"], "from": ["id"]}, "id__s": {"type": ["string", "null"], "from": ["id"]}, "taxable": {"type": ["boolean", "null"], "from": ["taxable"]}, "vendor": {"type": ["string", "null"], "from": ["vendor"]}, "origin_location__country_code": {"type": ["string", "null"], "from": ["origin_location", "country_code"]}, "origin_location__name": {"type": ["string", "null"], "from": ["origin_location", "name"]}, "origin_location__address1": {"type": ["string", "null"], "from": ["origin_location", "address1"]}, "origin_location__city": {"type": ["string", "null"], "from": ["origin_location", "city"]}, "origin_location__id": {"type": ["integer", "null"], "from": ["origin_location", "id"]}, "origin_location__address2": {"type": ["string", "null"], "from": ["origin_location", "address2"]}, "origin_location__province_code": {"type": ["string", "null"], "from": ["origin_location", "province_code"]}, "origin_location__zip": {"type": ["string", "null"], "from": ["origin_location", "zip"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "requires_shipping": {"type": ["boolean", "null"], "from": ["requires_shipping"]}, "fulfillment_service": {"type": ["string", "null"], "from": ["fulfillment_service"]}, "variant_inventory_management": {"type": ["string", "null"], "from": ["variant_inventory_management"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "destination_location__country_code": {"type": ["string", "null"], "from": ["destination_location", "country_code"]}, "destination_location__name": {"type": ["string", "null"], "from": ["destination_location", "name"]}, "destination_location__address1": {"type": ["string", "null"], "from": ["destination_location", "address1"]}, "destination_location__city": {"type": ["string", "null"], "from": ["destination_location", "city"]}, "destination_location__id": {"type": ["integer", "null"], "from": ["destination_location", "id"]}, "destination_location__address2": {"type": ["string", "null"], "from": ["destination_location", "address2"]}, "destination_location__province_code": {"type": ["string", "null"], "from": ["destination_location", "province_code"]}, "destination_location__zip": {"type": ["string", "null"], "from": ["destination_location", "zip"]}, "quantity": {"type": ["integer", "null"], "from": ["quantity"]}, "product_id": {"type": ["integer", "null"], "from": ["product_id"]}, "variant_id": {"type": ["integer", "null"], "from": ["variant_id"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: abandoned_checkouts__line_items__applied_discounts; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__line_items__applied_discounts (
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE abandoned_checkouts__line_items__applied_discounts; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__line_items__applied_discounts IS '{"path": ["abandoned_checkouts", "line_items", "applied_discounts"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: abandoned_checkouts__line_items__discount_allocations; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__line_items__discount_allocations (
    discount_application_index bigint,
    amount double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE abandoned_checkouts__line_items__discount_allocations; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__line_items__discount_allocations IS '{"path": ["abandoned_checkouts", "line_items", "discount_allocations"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"discount_application_index": {"type": ["integer", "null"], "from": ["discount_application_index"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: abandoned_checkouts__line_items__properties; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__line_items__properties (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE abandoned_checkouts__line_items__properties; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__line_items__properties IS '{"path": ["abandoned_checkouts", "line_items", "properties"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: abandoned_checkouts__line_items__tax_lines; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__line_items__tax_lines (
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE abandoned_checkouts__line_items__tax_lines; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__line_items__tax_lines IS '{"path": ["abandoned_checkouts", "line_items", "tax_lines"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: abandoned_checkouts__note_attributes; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__note_attributes (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE abandoned_checkouts__note_attributes; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__note_attributes IS '{"path": ["abandoned_checkouts", "note_attributes"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: abandoned_checkouts__shipping_lines; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__shipping_lines (
    phone text,
    validation_context text,
    id text,
    carrier_identifier text,
    api_client_id bigint,
    price double precision,
    requested_fulfillment_service_id text,
    title text,
    code text,
    carrier_service_id bigint,
    delivery_category text,
    markup text,
    source text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE abandoned_checkouts__shipping_lines; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__shipping_lines IS '{"path": ["abandoned_checkouts", "shipping_lines"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"phone": {"type": ["string", "null"], "from": ["phone"]}, "validation_context": {"type": ["string", "null"], "from": ["validation_context"]}, "id": {"type": ["string", "null"], "from": ["id"]}, "carrier_identifier": {"type": ["string", "null"], "from": ["carrier_identifier"]}, "api_client_id": {"type": ["integer", "null"], "from": ["api_client_id"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "requested_fulfillment_service_id": {"type": ["string", "null"], "from": ["requested_fulfillment_service_id"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "code": {"type": ["string", "null"], "from": ["code"]}, "carrier_service_id": {"type": ["integer", "null"], "from": ["carrier_service_id"]}, "delivery_category": {"type": ["string", "null"], "from": ["delivery_category"]}, "markup": {"type": ["string", "null"], "from": ["markup"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: abandoned_checkouts__shipping_lines__applied_discounts; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__shipping_lines__applied_discounts (
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE abandoned_checkouts__shipping_lines__applied_discounts; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__shipping_lines__applied_discounts IS '{"path": ["abandoned_checkouts", "shipping_lines", "applied_discounts"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: abandoned_checkouts__shipping_lines__custom_tax_lines; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__shipping_lines__custom_tax_lines (
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE abandoned_checkouts__shipping_lines__custom_tax_lines; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__shipping_lines__custom_tax_lines IS '{"path": ["abandoned_checkouts", "shipping_lines", "custom_tax_lines"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: abandoned_checkouts__shipping_lines__tax_lines; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__shipping_lines__tax_lines (
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE abandoned_checkouts__shipping_lines__tax_lines; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__shipping_lines__tax_lines IS '{"path": ["abandoned_checkouts", "shipping_lines", "tax_lines"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: abandoned_checkouts__tax_lines; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.abandoned_checkouts__tax_lines (
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE abandoned_checkouts__tax_lines; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.abandoned_checkouts__tax_lines IS '{"path": ["abandoned_checkouts", "tax_lines"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: collects; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.collects (
    id bigint,
    collection_id bigint,
    created_at timestamp with time zone,
    featured boolean,
    "position" bigint,
    product_id bigint,
    sort_value text,
    updated_at timestamp with time zone,
    account_id bigint NOT NULL,
    shop_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE collects; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.collects IS '{"path": ["collects"], "version": null, "schema_version": 2, "key_properties": ["id"], "mappings": {"id": {"type": ["integer", "null"], "from": ["id"]}, "collection_id": {"type": ["integer", "null"], "from": ["collection_id"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "featured": {"type": ["boolean", "null"], "from": ["featured"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "product_id": {"type": ["integer", "null"], "from": ["product_id"]}, "sort_value": {"type": ["string", "null"], "from": ["sort_value"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "shop_id": {"type": ["integer"], "from": ["shop_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: custom_collections; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.custom_collections (
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
    account_id bigint NOT NULL,
    shop_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE custom_collections; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.custom_collections IS '{"path": ["custom_collections"], "version": null, "schema_version": 2, "key_properties": ["id"], "mappings": {"handle": {"type": ["string", "null"], "from": ["handle"]}, "sort_order": {"type": ["string", "null"], "from": ["sort_order"]}, "body_html": {"type": ["string", "null"], "from": ["body_html"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "published_scope": {"type": ["string", "null"], "from": ["published_scope"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"]}, "image__alt": {"type": ["string", "null"], "from": ["image", "alt"]}, "image__src": {"type": ["string", "null"], "from": ["image", "src"]}, "image__width": {"type": ["integer", "null"], "from": ["image", "width"]}, "image__created_at": {"type": ["string", "null"], "from": ["image", "created_at"]}, "image__height": {"type": ["integer", "null"], "from": ["image", "height"]}, "published_at": {"type": ["string", "null"], "from": ["published_at"]}, "template_suffix": {"type": ["string", "null"], "from": ["template_suffix"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "shop_id": {"type": ["integer"], "from": ["shop_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: customers; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.customers (
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
    account_id bigint NOT NULL,
    shop_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE customers; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.customers IS '{"path": ["customers"], "version": null, "schema_version": 2, "key_properties": ["id"], "mappings": {"last_order_name": {"type": ["string", "null"], "from": ["last_order_name"]}, "currency": {"type": ["string", "null"], "from": ["currency"]}, "email": {"type": ["string", "null"], "from": ["email"]}, "multipass_identifier": {"type": ["string", "null"], "from": ["multipass_identifier"]}, "default_address__city": {"type": ["string", "null"], "from": ["default_address", "city"]}, "default_address__address1": {"type": ["string", "null"], "from": ["default_address", "address1"]}, "default_address__zip": {"type": ["string", "null"], "from": ["default_address", "zip"]}, "default_address__id": {"type": ["integer", "null"], "from": ["default_address", "id"]}, "default_address__country_name": {"type": ["string", "null"], "from": ["default_address", "country_name"]}, "default_address__province": {"type": ["string", "null"], "from": ["default_address", "province"]}, "default_address__phone": {"type": ["string", "null"], "from": ["default_address", "phone"]}, "default_address__country": {"type": ["string", "null"], "from": ["default_address", "country"]}, "default_address__first_name": {"type": ["string", "null"], "from": ["default_address", "first_name"]}, "default_address__customer_id": {"type": ["integer", "null"], "from": ["default_address", "customer_id"]}, "default_address__default": {"type": ["boolean", "null"], "from": ["default_address", "default"]}, "default_address__last_name": {"type": ["string", "null"], "from": ["default_address", "last_name"]}, "default_address__country_code": {"type": ["string", "null"], "from": ["default_address", "country_code"]}, "default_address__name": {"type": ["string", "null"], "from": ["default_address", "name"]}, "default_address__province_code": {"type": ["string", "null"], "from": ["default_address", "province_code"]}, "default_address__address2": {"type": ["string", "null"], "from": ["default_address", "address2"]}, "default_address__company": {"type": ["string", "null"], "from": ["default_address", "company"]}, "orders_count": {"type": ["integer", "null"], "from": ["orders_count"]}, "state": {"type": ["string", "null"], "from": ["state"]}, "verified_email": {"type": ["boolean", "null"], "from": ["verified_email"]}, "total_spent": {"type": ["string", "null"], "from": ["total_spent"]}, "last_order_id": {"type": ["integer", "null"], "from": ["last_order_id"]}, "first_name": {"type": ["string", "null"], "from": ["first_name"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "note": {"type": ["string", "null"], "from": ["note"]}, "phone": {"type": ["string", "null"], "from": ["phone"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "last_name": {"type": ["string", "null"], "from": ["last_name"]}, "tags": {"type": ["string", "null"], "from": ["tags"]}, "tax_exempt": {"type": ["boolean", "null"], "from": ["tax_exempt"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "accepts_marketing": {"type": ["boolean", "null"], "from": ["accepts_marketing"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "shop_id": {"type": ["integer"], "from": ["shop_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: customers__addresses; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.customers__addresses (
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
-- Name: TABLE customers__addresses; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.customers__addresses IS '{"path": ["customers", "addresses"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"city": {"type": ["string", "null"], "from": ["city"]}, "address1": {"type": ["string", "null"], "from": ["address1"]}, "zip": {"type": ["string", "null"], "from": ["zip"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "country_name": {"type": ["string", "null"], "from": ["country_name"]}, "province": {"type": ["string", "null"], "from": ["province"]}, "phone": {"type": ["string", "null"], "from": ["phone"]}, "country": {"type": ["string", "null"], "from": ["country"]}, "first_name": {"type": ["string", "null"], "from": ["first_name"]}, "customer_id": {"type": ["integer", "null"], "from": ["customer_id"]}, "default": {"type": ["boolean", "null"], "from": ["default"]}, "last_name": {"type": ["string", "null"], "from": ["last_name"]}, "country_code": {"type": ["string", "null"], "from": ["country_code"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "province_code": {"type": ["string", "null"], "from": ["province_code"]}, "address2": {"type": ["string", "null"], "from": ["address2"]}, "company": {"type": ["string", "null"], "from": ["company"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: metafields; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.metafields (
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
    account_id bigint NOT NULL,
    shop_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE metafields; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.metafields IS '{"path": ["metafields"], "version": null, "schema_version": 2, "key_properties": ["id"], "mappings": {"owner_id": {"type": ["integer", "null"], "from": ["owner_id"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "owner_resource": {"type": ["string", "null"], "from": ["owner_resource"]}, "value_type": {"type": ["string", "null"], "from": ["value_type"]}, "key": {"type": ["string", "null"], "from": ["key"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "id": {"type": ["integer", "null"], "from": ["id"]}, "namespace": {"type": ["string", "null"], "from": ["namespace"]}, "description": {"type": ["string", "null"], "from": ["description"]}, "value__i": {"type": ["integer", "null"], "from": ["value"]}, "value__s": {"type": ["string", "null"], "from": ["value"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "shop_id": {"type": ["integer"], "from": ["shop_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: orders; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders (
    presentment_currency text,
    subtotal_price_set__shop_money__amount text,
    subtotal_price_set__shop_money__currency_code text,
    subtotal_price_set__presentment_money__amount text,
    subtotal_price_set__presentment_money__currency_code text,
    total_discounts_set__shop_money__amount text,
    total_discounts_set__shop_money__currency_code text,
    total_discounts_set__presentment_money__amount text,
    total_discounts_set__presentment_money__currency_code text,
    total_line_items_price_set__shop_money__amount text,
    total_line_items_price_set__shop_money__currency_code text,
    total_line_items_price_set__presentment_money__amount text,
    total_line_items_price_set__presentment_money__currency_code text,
    total_price_set__shop_money__amount text,
    total_price_set__shop_money__currency_code text,
    total_price_set__presentment_money__amount text,
    total_price_set__presentment_money__currency_code text,
    total_shipping_price_set__shop_money__amount text,
    total_shipping_price_set__shop_money__currency_code text,
    total_shipping_price_set__presentment_money__amount text,
    total_shipping_price_set__presentment_money__currency_code text,
    total_tax_set__shop_money__amount text,
    total_tax_set__shop_money__currency_code text,
    total_tax_set__presentment_money__amount text,
    total_tax_set__presentment_money__currency_code text,
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
    account_id bigint NOT NULL,
    shop_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE orders; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders IS '{"path": ["orders"], "version": null, "schema_version": 2, "key_properties": ["id"], "mappings": {"presentment_currency": {"type": ["string", "null"], "from": ["presentment_currency"]}, "subtotal_price_set__shop_money__amount": {"type": ["string", "null"], "from": ["subtotal_price_set", "shop_money", "amount"]}, "subtotal_price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["subtotal_price_set", "shop_money", "currency_code"]}, "subtotal_price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["subtotal_price_set", "presentment_money", "amount"]}, "subtotal_price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["subtotal_price_set", "presentment_money", "currency_code"]}, "total_discounts_set__shop_money__amount": {"type": ["string", "null"], "from": ["total_discounts_set", "shop_money", "amount"]}, "total_discounts_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["total_discounts_set", "shop_money", "currency_code"]}, "total_discounts_set__presentment_money__amount": {"type": ["string", "null"], "from": ["total_discounts_set", "presentment_money", "amount"]}, "total_discounts_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["total_discounts_set", "presentment_money", "currency_code"]}, "total_line_items_price_set__shop_money__amount": {"type": ["string", "null"], "from": ["total_line_items_price_set", "shop_money", "amount"]}, "total_line_items_price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["total_line_items_price_set", "shop_money", "currency_code"]}, "total_line_items_price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["total_line_items_price_set", "presentment_money", "amount"]}, "total_line_items_price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["total_line_items_price_set", "presentment_money", "currency_code"]}, "total_price_set__shop_money__amount": {"type": ["string", "null"], "from": ["total_price_set", "shop_money", "amount"]}, "total_price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["total_price_set", "shop_money", "currency_code"]}, "total_price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["total_price_set", "presentment_money", "amount"]}, "total_price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["total_price_set", "presentment_money", "currency_code"]}, "total_shipping_price_set__shop_money__amount": {"type": ["string", "null"], "from": ["total_shipping_price_set", "shop_money", "amount"]}, "total_shipping_price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["total_shipping_price_set", "shop_money", "currency_code"]}, "total_shipping_price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["total_shipping_price_set", "presentment_money", "amount"]}, "total_shipping_price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["total_shipping_price_set", "presentment_money", "currency_code"]}, "total_tax_set__shop_money__amount": {"type": ["string", "null"], "from": ["total_tax_set", "shop_money", "amount"]}, "total_tax_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["total_tax_set", "shop_money", "currency_code"]}, "total_tax_set__presentment_money__amount": {"type": ["string", "null"], "from": ["total_tax_set", "presentment_money", "amount"]}, "total_tax_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["total_tax_set", "presentment_money", "currency_code"]}, "total_price": {"type": ["number", "null"], "from": ["total_price"]}, "processing_method": {"type": ["string", "null"], "from": ["processing_method"]}, "order_number": {"type": ["integer", "null"], "from": ["order_number"]}, "confirmed": {"type": ["boolean", "null"], "from": ["confirmed"]}, "total_discounts": {"type": ["number", "null"], "from": ["total_discounts"]}, "total_line_items_price": {"type": ["number", "null"], "from": ["total_line_items_price"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "device_id": {"type": ["integer", "null"], "from": ["device_id"]}, "cancel_reason": {"type": ["string", "null"], "from": ["cancel_reason"]}, "currency": {"type": ["string", "null"], "from": ["currency"]}, "source_identifier": {"type": ["string", "null"], "from": ["source_identifier"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "processed_at": {"type": ["string", "null"], "from": ["processed_at"], "format": "date-time"}, "referring_site": {"type": ["string", "null"], "from": ["referring_site"]}, "contact_email": {"type": ["string", "null"], "from": ["contact_email"]}, "location_id": {"type": ["integer", "null"], "from": ["location_id"]}, "customer__last_order_name": {"type": ["string", "null"], "from": ["customer", "last_order_name"]}, "customer__currency": {"type": ["string", "null"], "from": ["customer", "currency"]}, "customer__email": {"type": ["string", "null"], "from": ["customer", "email"]}, "customer__multipass_identifier": {"type": ["string", "null"], "from": ["customer", "multipass_identifier"]}, "customer__default_address__city": {"type": ["string", "null"], "from": ["customer", "default_address", "city"]}, "customer__default_address__address1": {"type": ["string", "null"], "from": ["customer", "default_address", "address1"]}, "customer__default_address__zip": {"type": ["string", "null"], "from": ["customer", "default_address", "zip"]}, "customer__default_address__id": {"type": ["integer", "null"], "from": ["customer", "default_address", "id"]}, "customer__default_address__country_name": {"type": ["string", "null"], "from": ["customer", "default_address", "country_name"]}, "customer__default_address__province": {"type": ["string", "null"], "from": ["customer", "default_address", "province"]}, "customer__default_address__phone": {"type": ["string", "null"], "from": ["customer", "default_address", "phone"]}, "customer__default_address__country": {"type": ["string", "null"], "from": ["customer", "default_address", "country"]}, "customer__default_address__first_name": {"type": ["string", "null"], "from": ["customer", "default_address", "first_name"]}, "customer__default_address__customer_id": {"type": ["integer", "null"], "from": ["customer", "default_address", "customer_id"]}, "customer__default_address__default": {"type": ["boolean", "null"], "from": ["customer", "default_address", "default"]}, "customer__default_address__last_name": {"type": ["string", "null"], "from": ["customer", "default_address", "last_name"]}, "customer__default_address__country_code": {"type": ["string", "null"], "from": ["customer", "default_address", "country_code"]}, "customer__default_address__name": {"type": ["string", "null"], "from": ["customer", "default_address", "name"]}, "customer__default_address__province_code": {"type": ["string", "null"], "from": ["customer", "default_address", "province_code"]}, "customer__default_address__address2": {"type": ["string", "null"], "from": ["customer", "default_address", "address2"]}, "customer__default_address__company": {"type": ["string", "null"], "from": ["customer", "default_address", "company"]}, "customer__orders_count": {"type": ["integer", "null"], "from": ["customer", "orders_count"]}, "customer__state": {"type": ["string", "null"], "from": ["customer", "state"]}, "customer__verified_email": {"type": ["boolean", "null"], "from": ["customer", "verified_email"]}, "customer__total_spent": {"type": ["string", "null"], "from": ["customer", "total_spent"]}, "customer__last_order_id": {"type": ["integer", "null"], "from": ["customer", "last_order_id"]}, "customer__first_name": {"type": ["string", "null"], "from": ["customer", "first_name"]}, "customer__updated_at": {"type": ["string", "null"], "from": ["customer", "updated_at"], "format": "date-time"}, "customer__note": {"type": ["string", "null"], "from": ["customer", "note"]}, "customer__phone": {"type": ["string", "null"], "from": ["customer", "phone"]}, "customer__admin_graphql_api_id": {"type": ["string", "null"], "from": ["customer", "admin_graphql_api_id"]}, "customer__last_name": {"type": ["string", "null"], "from": ["customer", "last_name"]}, "customer__tags": {"type": ["string", "null"], "from": ["customer", "tags"]}, "customer__tax_exempt": {"type": ["boolean", "null"], "from": ["customer", "tax_exempt"]}, "customer__id": {"type": ["integer", "null"], "from": ["customer", "id"]}, "customer__accepts_marketing": {"type": ["boolean", "null"], "from": ["customer", "accepts_marketing"]}, "customer__created_at": {"type": ["string", "null"], "from": ["customer", "created_at"], "format": "date-time"}, "test": {"type": ["boolean", "null"], "from": ["test"]}, "total_tax": {"type": ["number", "null"], "from": ["total_tax"]}, "payment_details__avs_result_code": {"type": ["string", "null"], "from": ["payment_details", "avs_result_code"]}, "payment_details__credit_card_company": {"type": ["string", "null"], "from": ["payment_details", "credit_card_company"]}, "payment_details__cvv_result_code": {"type": ["string", "null"], "from": ["payment_details", "cvv_result_code"]}, "payment_details__credit_card_bin": {"type": ["string", "null"], "from": ["payment_details", "credit_card_bin"]}, "payment_details__credit_card_number": {"type": ["string", "null"], "from": ["payment_details", "credit_card_number"]}, "number": {"type": ["integer", "null"], "from": ["number"]}, "email": {"type": ["string", "null"], "from": ["email"]}, "source_name": {"type": ["string", "null"], "from": ["source_name"]}, "landing_site_ref": {"type": ["string", "null"], "from": ["landing_site_ref"]}, "shipping_address__phone": {"type": ["string", "null"], "from": ["shipping_address", "phone"]}, "shipping_address__country": {"type": ["string", "null"], "from": ["shipping_address", "country"]}, "shipping_address__name": {"type": ["string", "null"], "from": ["shipping_address", "name"]}, "shipping_address__address1": {"type": ["string", "null"], "from": ["shipping_address", "address1"]}, "shipping_address__longitude": {"type": ["number", "null"], "from": ["shipping_address", "longitude"]}, "shipping_address__address2": {"type": ["string", "null"], "from": ["shipping_address", "address2"]}, "shipping_address__last_name": {"type": ["string", "null"], "from": ["shipping_address", "last_name"]}, "shipping_address__first_name": {"type": ["string", "null"], "from": ["shipping_address", "first_name"]}, "shipping_address__province": {"type": ["string", "null"], "from": ["shipping_address", "province"]}, "shipping_address__city": {"type": ["string", "null"], "from": ["shipping_address", "city"]}, "shipping_address__company": {"type": ["string", "null"], "from": ["shipping_address", "company"]}, "shipping_address__latitude": {"type": ["number", "null"], "from": ["shipping_address", "latitude"]}, "shipping_address__country_code": {"type": ["string", "null"], "from": ["shipping_address", "country_code"]}, "shipping_address__province_code": {"type": ["string", "null"], "from": ["shipping_address", "province_code"]}, "shipping_address__zip": {"type": ["string", "null"], "from": ["shipping_address", "zip"]}, "total_price_usd": {"type": ["number", "null"], "from": ["total_price_usd"]}, "closed_at": {"type": ["string", "null"], "from": ["closed_at"], "format": "date-time"}, "name": {"type": ["string", "null"], "from": ["name"]}, "note": {"type": ["string", "null"], "from": ["note"]}, "user_id": {"type": ["integer", "null"], "from": ["user_id"]}, "source_url": {"type": ["string", "null"], "from": ["source_url"]}, "subtotal_price": {"type": ["number", "null"], "from": ["subtotal_price"]}, "billing_address__phone": {"type": ["string", "null"], "from": ["billing_address", "phone"]}, "billing_address__country": {"type": ["string", "null"], "from": ["billing_address", "country"]}, "billing_address__name": {"type": ["string", "null"], "from": ["billing_address", "name"]}, "billing_address__address1": {"type": ["string", "null"], "from": ["billing_address", "address1"]}, "billing_address__longitude": {"type": ["number", "null"], "from": ["billing_address", "longitude"]}, "billing_address__address2": {"type": ["string", "null"], "from": ["billing_address", "address2"]}, "billing_address__last_name": {"type": ["string", "null"], "from": ["billing_address", "last_name"]}, "billing_address__first_name": {"type": ["string", "null"], "from": ["billing_address", "first_name"]}, "billing_address__province": {"type": ["string", "null"], "from": ["billing_address", "province"]}, "billing_address__city": {"type": ["string", "null"], "from": ["billing_address", "city"]}, "billing_address__company": {"type": ["string", "null"], "from": ["billing_address", "company"]}, "billing_address__latitude": {"type": ["number", "null"], "from": ["billing_address", "latitude"]}, "billing_address__country_code": {"type": ["string", "null"], "from": ["billing_address", "country_code"]}, "billing_address__province_code": {"type": ["string", "null"], "from": ["billing_address", "province_code"]}, "billing_address__zip": {"type": ["string", "null"], "from": ["billing_address", "zip"]}, "landing_site": {"type": ["string", "null"], "from": ["landing_site"]}, "taxes_included": {"type": ["boolean", "null"], "from": ["taxes_included"]}, "token": {"type": ["string", "null"], "from": ["token"]}, "app_id": {"type": ["integer", "null"], "from": ["app_id"]}, "total_tip_received": {"type": ["string", "null"], "from": ["total_tip_received"]}, "browser_ip": {"type": ["string", "null"], "from": ["browser_ip"]}, "phone": {"type": ["string", "null"], "from": ["phone"]}, "fulfillment_status": {"type": ["string", "null"], "from": ["fulfillment_status"]}, "order_status_url": {"type": ["string", "null"], "from": ["order_status_url"]}, "client_details__session_hash": {"type": ["string", "null"], "from": ["client_details", "session_hash"]}, "client_details__accept_language": {"type": ["string", "null"], "from": ["client_details", "accept_language"]}, "client_details__browser_width": {"type": ["integer", "null"], "from": ["client_details", "browser_width"]}, "client_details__user_agent": {"type": ["string", "null"], "from": ["client_details", "user_agent"]}, "client_details__browser_ip": {"type": ["string", "null"], "from": ["client_details", "browser_ip"]}, "client_details__browser_height": {"type": ["integer", "null"], "from": ["client_details", "browser_height"]}, "buyer_accepts_marketing": {"type": ["boolean", "null"], "from": ["buyer_accepts_marketing"]}, "checkout_token": {"type": ["string", "null"], "from": ["checkout_token"]}, "tags": {"type": ["string", "null"], "from": ["tags"]}, "financial_status": {"type": ["string", "null"], "from": ["financial_status"]}, "customer_locale": {"type": ["string", "null"], "from": ["customer_locale"]}, "checkout_id": {"type": ["integer", "null"], "from": ["checkout_id"]}, "total_weight": {"type": ["integer", "null"], "from": ["total_weight"]}, "gateway": {"type": ["string", "null"], "from": ["gateway"]}, "cart_token": {"type": ["string", "null"], "from": ["cart_token"]}, "cancelled_at": {"type": ["string", "null"], "from": ["cancelled_at"], "format": "date-time"}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "reference": {"type": ["string", "null"], "from": ["reference"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "shop_id": {"type": ["integer"], "from": ["shop_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: orders__customer__addresses; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__customer__addresses (
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
-- Name: TABLE orders__customer__addresses; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__customer__addresses IS '{"path": ["orders", "customer", "addresses"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"city": {"type": ["string", "null"], "from": ["city"]}, "address1": {"type": ["string", "null"], "from": ["address1"]}, "zip": {"type": ["string", "null"], "from": ["zip"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "country_name": {"type": ["string", "null"], "from": ["country_name"]}, "province": {"type": ["string", "null"], "from": ["province"]}, "phone": {"type": ["string", "null"], "from": ["phone"]}, "country": {"type": ["string", "null"], "from": ["country"]}, "first_name": {"type": ["string", "null"], "from": ["first_name"]}, "customer_id": {"type": ["integer", "null"], "from": ["customer_id"]}, "default": {"type": ["boolean", "null"], "from": ["default"]}, "last_name": {"type": ["string", "null"], "from": ["last_name"]}, "country_code": {"type": ["string", "null"], "from": ["country_code"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "province_code": {"type": ["string", "null"], "from": ["province_code"]}, "address2": {"type": ["string", "null"], "from": ["address2"]}, "company": {"type": ["string", "null"], "from": ["company"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__discount_applications; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__discount_applications (
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
-- Name: TABLE orders__discount_applications; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__discount_applications IS '{"path": ["orders", "discount_applications"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"target_type": {"type": ["string", "null"], "from": ["target_type"]}, "code": {"type": ["string", "null"], "from": ["code"]}, "description": {"type": ["string", "null"], "from": ["description"]}, "type": {"type": ["string", "null"], "from": ["type"]}, "target_selection": {"type": ["string", "null"], "from": ["target_selection"]}, "allocation_method": {"type": ["string", "null"], "from": ["allocation_method"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "value_type": {"type": ["string", "null"], "from": ["value_type"]}, "value": {"type": ["number", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__discount_codes; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__discount_codes (
    code text,
    amount double precision,
    type text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__discount_codes; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__discount_codes IS '{"path": ["orders", "discount_codes"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"code": {"type": ["string", "null"], "from": ["code"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "type": {"type": ["string", "null"], "from": ["type"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__fulfillments; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__fulfillments (
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
-- Name: TABLE orders__fulfillments; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__fulfillments IS '{"path": ["orders", "fulfillments"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"location_id": {"type": ["integer", "null"], "from": ["location_id"]}, "receipt__testcase": {"type": ["boolean", "null"], "from": ["receipt", "testcase"]}, "receipt__authorization": {"type": ["string", "null"], "from": ["receipt", "authorization"]}, "tracking_number": {"type": ["string", "null"], "from": ["tracking_number"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "shipment_status": {"type": ["string", "null"], "from": ["shipment_status"]}, "tracking_url": {"type": ["string", "null"], "from": ["tracking_url"]}, "service": {"type": ["string", "null"], "from": ["service"]}, "status": {"type": ["string", "null"], "from": ["status"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "tracking_company": {"type": ["string", "null"], "from": ["tracking_company"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__fulfillments__line_items; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__fulfillments__line_items (
    total_discount_set__shop_money__amount text,
    total_discount_set__shop_money__currency_code text,
    total_discount_set__presentment_money__amount text,
    total_discount_set__presentment_money__currency_code text,
    pre_tax_price_set__shop_money__amount text,
    pre_tax_price_set__shop_money__currency_code text,
    pre_tax_price_set__presentment_money__amount text,
    pre_tax_price_set__presentment_money__currency_code text,
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE orders__fulfillments__line_items; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__fulfillments__line_items IS '{"path": ["orders", "fulfillments", "line_items"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"total_discount_set__shop_money__amount": {"type": ["string", "null"], "from": ["total_discount_set", "shop_money", "amount"]}, "total_discount_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["total_discount_set", "shop_money", "currency_code"]}, "total_discount_set__presentment_money__amount": {"type": ["string", "null"], "from": ["total_discount_set", "presentment_money", "amount"]}, "total_discount_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["total_discount_set", "presentment_money", "currency_code"]}, "pre_tax_price_set__shop_money__amount": {"type": ["string", "null"], "from": ["pre_tax_price_set", "shop_money", "amount"]}, "pre_tax_price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["pre_tax_price_set", "shop_money", "currency_code"]}, "pre_tax_price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["pre_tax_price_set", "presentment_money", "amount"]}, "pre_tax_price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["pre_tax_price_set", "presentment_money", "currency_code"]}, "price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "grams": {"type": ["integer", "null"], "from": ["grams"]}, "compare_at_price": {"type": ["string", "null"], "from": ["compare_at_price"]}, "destination_location_id": {"type": ["integer", "null"], "from": ["destination_location_id"]}, "key": {"type": ["string", "null"], "from": ["key"]}, "line_price": {"type": ["string", "null"], "from": ["line_price"]}, "origin_location_id": {"type": ["integer", "null"], "from": ["origin_location_id"]}, "applied_discount": {"type": ["integer", "null"], "from": ["applied_discount"]}, "fulfillable_quantity": {"type": ["integer", "null"], "from": ["fulfillable_quantity"]}, "variant_title": {"type": ["string", "null"], "from": ["variant_title"]}, "tax_code": {"type": ["string", "null"], "from": ["tax_code"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "pre_tax_price": {"type": ["number", "null"], "from": ["pre_tax_price"]}, "sku": {"type": ["string", "null"], "from": ["sku"]}, "product_exists": {"type": ["boolean", "null"], "from": ["product_exists"]}, "total_discount": {"type": ["number", "null"], "from": ["total_discount"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "fulfillment_status": {"type": ["string", "null"], "from": ["fulfillment_status"]}, "gift_card": {"type": ["boolean", "null"], "from": ["gift_card"]}, "id__i": {"type": ["integer", "null"], "from": ["id"]}, "id__s": {"type": ["string", "null"], "from": ["id"]}, "taxable": {"type": ["boolean", "null"], "from": ["taxable"]}, "vendor": {"type": ["string", "null"], "from": ["vendor"]}, "origin_location__country_code": {"type": ["string", "null"], "from": ["origin_location", "country_code"]}, "origin_location__name": {"type": ["string", "null"], "from": ["origin_location", "name"]}, "origin_location__address1": {"type": ["string", "null"], "from": ["origin_location", "address1"]}, "origin_location__city": {"type": ["string", "null"], "from": ["origin_location", "city"]}, "origin_location__id": {"type": ["integer", "null"], "from": ["origin_location", "id"]}, "origin_location__address2": {"type": ["string", "null"], "from": ["origin_location", "address2"]}, "origin_location__province_code": {"type": ["string", "null"], "from": ["origin_location", "province_code"]}, "origin_location__zip": {"type": ["string", "null"], "from": ["origin_location", "zip"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "requires_shipping": {"type": ["boolean", "null"], "from": ["requires_shipping"]}, "fulfillment_service": {"type": ["string", "null"], "from": ["fulfillment_service"]}, "variant_inventory_management": {"type": ["string", "null"], "from": ["variant_inventory_management"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "destination_location__country_code": {"type": ["string", "null"], "from": ["destination_location", "country_code"]}, "destination_location__name": {"type": ["string", "null"], "from": ["destination_location", "name"]}, "destination_location__address1": {"type": ["string", "null"], "from": ["destination_location", "address1"]}, "destination_location__city": {"type": ["string", "null"], "from": ["destination_location", "city"]}, "destination_location__id": {"type": ["integer", "null"], "from": ["destination_location", "id"]}, "destination_location__address2": {"type": ["string", "null"], "from": ["destination_location", "address2"]}, "destination_location__province_code": {"type": ["string", "null"], "from": ["destination_location", "province_code"]}, "destination_location__zip": {"type": ["string", "null"], "from": ["destination_location", "zip"]}, "quantity": {"type": ["integer", "null"], "from": ["quantity"]}, "product_id": {"type": ["integer", "null"], "from": ["product_id"]}, "variant_id": {"type": ["integer", "null"], "from": ["variant_id"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__fulfillments__line_items__applied_discounts; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__fulfillments__line_items__applied_discounts (
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments__line_items__applied_discounts; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__fulfillments__line_items__applied_discounts IS '{"path": ["orders", "fulfillments", "line_items", "applied_discounts"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__fulfillments__line_items__discount_allocations; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__fulfillments__line_items__discount_allocations (
    discount_application_index bigint,
    amount double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments__line_items__discount_allocations; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__fulfillments__line_items__discount_allocations IS '{"path": ["orders", "fulfillments", "line_items", "discount_allocations"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"discount_application_index": {"type": ["integer", "null"], "from": ["discount_application_index"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__fulfillments__line_items__properties; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__fulfillments__line_items__properties (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments__line_items__properties; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__fulfillments__line_items__properties IS '{"path": ["orders", "fulfillments", "line_items", "properties"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__fulfillments__line_items__tax_lines; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__fulfillments__line_items__tax_lines (
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE orders__fulfillments__line_items__tax_lines; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__fulfillments__line_items__tax_lines IS '{"path": ["orders", "fulfillments", "line_items", "tax_lines"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__fulfillments__tracking_numbers; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__fulfillments__tracking_numbers (
    _sdc_value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments__tracking_numbers; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__fulfillments__tracking_numbers IS '{"path": ["orders", "fulfillments", "tracking_numbers"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["string", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__fulfillments__tracking_urls; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__fulfillments__tracking_urls (
    _sdc_value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__fulfillments__tracking_urls; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__fulfillments__tracking_urls IS '{"path": ["orders", "fulfillments", "tracking_urls"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["string", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__line_items; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__line_items (
    total_discount_set__shop_money__amount text,
    total_discount_set__shop_money__currency_code text,
    total_discount_set__presentment_money__amount text,
    total_discount_set__presentment_money__currency_code text,
    pre_tax_price_set__shop_money__amount text,
    pre_tax_price_set__shop_money__currency_code text,
    pre_tax_price_set__presentment_money__amount text,
    pre_tax_price_set__presentment_money__currency_code text,
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE orders__line_items; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__line_items IS '{"path": ["orders", "line_items"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"total_discount_set__shop_money__amount": {"type": ["string", "null"], "from": ["total_discount_set", "shop_money", "amount"]}, "total_discount_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["total_discount_set", "shop_money", "currency_code"]}, "total_discount_set__presentment_money__amount": {"type": ["string", "null"], "from": ["total_discount_set", "presentment_money", "amount"]}, "total_discount_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["total_discount_set", "presentment_money", "currency_code"]}, "pre_tax_price_set__shop_money__amount": {"type": ["string", "null"], "from": ["pre_tax_price_set", "shop_money", "amount"]}, "pre_tax_price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["pre_tax_price_set", "shop_money", "currency_code"]}, "pre_tax_price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["pre_tax_price_set", "presentment_money", "amount"]}, "pre_tax_price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["pre_tax_price_set", "presentment_money", "currency_code"]}, "price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "grams": {"type": ["integer", "null"], "from": ["grams"]}, "compare_at_price": {"type": ["string", "null"], "from": ["compare_at_price"]}, "destination_location_id": {"type": ["integer", "null"], "from": ["destination_location_id"]}, "key": {"type": ["string", "null"], "from": ["key"]}, "line_price": {"type": ["string", "null"], "from": ["line_price"]}, "origin_location_id": {"type": ["integer", "null"], "from": ["origin_location_id"]}, "applied_discount": {"type": ["integer", "null"], "from": ["applied_discount"]}, "fulfillable_quantity": {"type": ["integer", "null"], "from": ["fulfillable_quantity"]}, "variant_title": {"type": ["string", "null"], "from": ["variant_title"]}, "tax_code": {"type": ["string", "null"], "from": ["tax_code"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "pre_tax_price": {"type": ["number", "null"], "from": ["pre_tax_price"]}, "sku": {"type": ["string", "null"], "from": ["sku"]}, "product_exists": {"type": ["boolean", "null"], "from": ["product_exists"]}, "total_discount": {"type": ["number", "null"], "from": ["total_discount"]}, "name": {"type": ["string", "null"], "from": ["name"]}, "fulfillment_status": {"type": ["string", "null"], "from": ["fulfillment_status"]}, "gift_card": {"type": ["boolean", "null"], "from": ["gift_card"]}, "id__i": {"type": ["integer", "null"], "from": ["id"]}, "id__s": {"type": ["string", "null"], "from": ["id"]}, "taxable": {"type": ["boolean", "null"], "from": ["taxable"]}, "vendor": {"type": ["string", "null"], "from": ["vendor"]}, "origin_location__country_code": {"type": ["string", "null"], "from": ["origin_location", "country_code"]}, "origin_location__name": {"type": ["string", "null"], "from": ["origin_location", "name"]}, "origin_location__address1": {"type": ["string", "null"], "from": ["origin_location", "address1"]}, "origin_location__city": {"type": ["string", "null"], "from": ["origin_location", "city"]}, "origin_location__id": {"type": ["integer", "null"], "from": ["origin_location", "id"]}, "origin_location__address2": {"type": ["string", "null"], "from": ["origin_location", "address2"]}, "origin_location__province_code": {"type": ["string", "null"], "from": ["origin_location", "province_code"]}, "origin_location__zip": {"type": ["string", "null"], "from": ["origin_location", "zip"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "requires_shipping": {"type": ["boolean", "null"], "from": ["requires_shipping"]}, "fulfillment_service": {"type": ["string", "null"], "from": ["fulfillment_service"]}, "variant_inventory_management": {"type": ["string", "null"], "from": ["variant_inventory_management"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "destination_location__country_code": {"type": ["string", "null"], "from": ["destination_location", "country_code"]}, "destination_location__name": {"type": ["string", "null"], "from": ["destination_location", "name"]}, "destination_location__address1": {"type": ["string", "null"], "from": ["destination_location", "address1"]}, "destination_location__city": {"type": ["string", "null"], "from": ["destination_location", "city"]}, "destination_location__id": {"type": ["integer", "null"], "from": ["destination_location", "id"]}, "destination_location__address2": {"type": ["string", "null"], "from": ["destination_location", "address2"]}, "destination_location__province_code": {"type": ["string", "null"], "from": ["destination_location", "province_code"]}, "destination_location__zip": {"type": ["string", "null"], "from": ["destination_location", "zip"]}, "quantity": {"type": ["integer", "null"], "from": ["quantity"]}, "product_id": {"type": ["integer", "null"], "from": ["product_id"]}, "variant_id": {"type": ["integer", "null"], "from": ["variant_id"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__line_items__applied_discounts; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__line_items__applied_discounts (
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__line_items__applied_discounts; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__line_items__applied_discounts IS '{"path": ["orders", "line_items", "applied_discounts"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__line_items__discount_allocations; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__line_items__discount_allocations (
    discount_application_index bigint,
    amount double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__line_items__discount_allocations; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__line_items__discount_allocations IS '{"path": ["orders", "line_items", "discount_allocations"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"discount_application_index": {"type": ["integer", "null"], "from": ["discount_application_index"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__line_items__properties; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__line_items__properties (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__line_items__properties; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__line_items__properties IS '{"path": ["orders", "line_items", "properties"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__line_items__tax_lines; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__line_items__tax_lines (
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE orders__line_items__tax_lines; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__line_items__tax_lines IS '{"path": ["orders", "line_items", "tax_lines"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__note_attributes; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__note_attributes (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__note_attributes; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__note_attributes IS '{"path": ["orders", "note_attributes"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__order_adjustments; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__order_adjustments (
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
-- Name: TABLE orders__order_adjustments; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__order_adjustments IS '{"path": ["orders", "order_adjustments"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"order_id": {"type": ["integer", "null"], "from": ["order_id"]}, "tax_amount": {"type": ["number", "null"], "from": ["tax_amount"]}, "refund_id": {"type": ["integer", "null"], "from": ["refund_id"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "kind": {"type": ["string", "null"], "from": ["kind"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "reason": {"type": ["string", "null"], "from": ["reason"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__payment_gateway_names; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__payment_gateway_names (
    _sdc_value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE orders__payment_gateway_names; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__payment_gateway_names IS '{"path": ["orders", "payment_gateway_names"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["string", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__refunds; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__refunds (
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
-- Name: TABLE orders__refunds; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__refunds IS '{"path": ["orders", "refunds"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "restock": {"type": ["boolean", "null"], "from": ["restock"]}, "note": {"type": ["string", "null"], "from": ["note"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "user_id": {"type": ["integer", "null"], "from": ["user_id"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "processed_at": {"type": ["string", "null"], "from": ["processed_at"], "format": "date-time"}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__refunds__order_adjustments; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__refunds__order_adjustments (
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
-- Name: TABLE orders__refunds__order_adjustments; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__refunds__order_adjustments IS '{"path": ["orders", "refunds", "order_adjustments"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"order_id": {"type": ["integer", "null"], "from": ["order_id"]}, "tax_amount": {"type": ["number", "null"], "from": ["tax_amount"]}, "refund_id": {"type": ["integer", "null"], "from": ["refund_id"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "kind": {"type": ["string", "null"], "from": ["kind"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "reason": {"type": ["string", "null"], "from": ["reason"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__refunds__refund_line_items; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__refunds__refund_line_items (
    line_item__total_discount_set__shop_money__amount text,
    line_item__total_discount_set__shop_money__currency_code text,
    line_item__total_discount_set__presentment_money__amount text,
    line_item__total_discount_set__presentment_money__currency_code text,
    line_item__pre_tax_price_set__shop_money__amount text,
    line_item__pre_tax_price_set__shop_money__currency_code text,
    line_item__pre_tax_price_set__presentment_money__amount text,
    line_item__pre_tax_price_set__presentment_money__currency_code text,
    line_item__price_set__shop_money__amount text,
    line_item__price_set__shop_money__currency_code text,
    line_item__price_set__presentment_money__amount text,
    line_item__price_set__presentment_money__currency_code text,
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
-- Name: TABLE orders__refunds__refund_line_items; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__refunds__refund_line_items IS '{"path": ["orders", "refunds", "refund_line_items"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"line_item__total_discount_set__shop_money__amount": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "shop_money", "amount"]}, "line_item__total_discount_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "shop_money", "currency_code"]}, "line_item__total_discount_set__presentment_money__amount": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "presentment_money", "amount"]}, "line_item__total_discount_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "total_discount_set", "presentment_money", "currency_code"]}, "line_item__pre_tax_price_set__shop_money__amount": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "shop_money", "amount"]}, "line_item__pre_tax_price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "shop_money", "currency_code"]}, "line_item__pre_tax_price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "presentment_money", "amount"]}, "line_item__pre_tax_price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "pre_tax_price_set", "presentment_money", "currency_code"]}, "line_item__price_set__shop_money__amount": {"type": ["string", "null"], "from": ["line_item", "price_set", "shop_money", "amount"]}, "line_item__price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "price_set", "shop_money", "currency_code"]}, "line_item__price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["line_item", "price_set", "presentment_money", "amount"]}, "line_item__price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["line_item", "price_set", "presentment_money", "currency_code"]}, "line_item__grams": {"type": ["integer", "null"], "from": ["line_item", "grams"]}, "line_item__compare_at_price": {"type": ["string", "null"], "from": ["line_item", "compare_at_price"]}, "line_item__destination_location_id": {"type": ["integer", "null"], "from": ["line_item", "destination_location_id"]}, "line_item__key": {"type": ["string", "null"], "from": ["line_item", "key"]}, "line_item__line_price": {"type": ["string", "null"], "from": ["line_item", "line_price"]}, "line_item__origin_location_id": {"type": ["integer", "null"], "from": ["line_item", "origin_location_id"]}, "line_item__applied_discount": {"type": ["integer", "null"], "from": ["line_item", "applied_discount"]}, "line_item__fulfillable_quantity": {"type": ["integer", "null"], "from": ["line_item", "fulfillable_quantity"]}, "line_item__variant_title": {"type": ["string", "null"], "from": ["line_item", "variant_title"]}, "line_item__tax_code": {"type": ["string", "null"], "from": ["line_item", "tax_code"]}, "line_item__admin_graphql_api_id": {"type": ["string", "null"], "from": ["line_item", "admin_graphql_api_id"]}, "line_item__pre_tax_price": {"type": ["number", "null"], "from": ["line_item", "pre_tax_price"]}, "line_item__sku": {"type": ["string", "null"], "from": ["line_item", "sku"]}, "line_item__product_exists": {"type": ["boolean", "null"], "from": ["line_item", "product_exists"]}, "line_item__total_discount": {"type": ["number", "null"], "from": ["line_item", "total_discount"]}, "line_item__name": {"type": ["string", "null"], "from": ["line_item", "name"]}, "line_item__fulfillment_status": {"type": ["string", "null"], "from": ["line_item", "fulfillment_status"]}, "line_item__gift_card": {"type": ["boolean", "null"], "from": ["line_item", "gift_card"]}, "line_item__id__i": {"type": ["integer", "null"], "from": ["line_item", "id"]}, "line_item__id__s": {"type": ["string", "null"], "from": ["line_item", "id"]}, "line_item__taxable": {"type": ["boolean", "null"], "from": ["line_item", "taxable"]}, "line_item__vendor": {"type": ["string", "null"], "from": ["line_item", "vendor"]}, "line_item__origin_location__country_code": {"type": ["string", "null"], "from": ["line_item", "origin_location", "country_code"]}, "line_item__origin_location__name": {"type": ["string", "null"], "from": ["line_item", "origin_location", "name"]}, "line_item__origin_location__address1": {"type": ["string", "null"], "from": ["line_item", "origin_location", "address1"]}, "line_item__origin_location__city": {"type": ["string", "null"], "from": ["line_item", "origin_location", "city"]}, "line_item__origin_location__id": {"type": ["integer", "null"], "from": ["line_item", "origin_location", "id"]}, "line_item__origin_location__address2": {"type": ["string", "null"], "from": ["line_item", "origin_location", "address2"]}, "line_item__origin_location__province_code": {"type": ["string", "null"], "from": ["line_item", "origin_location", "province_code"]}, "line_item__origin_location__zip": {"type": ["string", "null"], "from": ["line_item", "origin_location", "zip"]}, "line_item__price": {"type": ["number", "null"], "from": ["line_item", "price"]}, "line_item__requires_shipping": {"type": ["boolean", "null"], "from": ["line_item", "requires_shipping"]}, "line_item__fulfillment_service": {"type": ["string", "null"], "from": ["line_item", "fulfillment_service"]}, "line_item__variant_inventory_management": {"type": ["string", "null"], "from": ["line_item", "variant_inventory_management"]}, "line_item__title": {"type": ["string", "null"], "from": ["line_item", "title"]}, "line_item__destination_location__country_code": {"type": ["string", "null"], "from": ["line_item", "destination_location", "country_code"]}, "line_item__destination_location__name": {"type": ["string", "null"], "from": ["line_item", "destination_location", "name"]}, "line_item__destination_location__address1": {"type": ["string", "null"], "from": ["line_item", "destination_location", "address1"]}, "line_item__destination_location__city": {"type": ["string", "null"], "from": ["line_item", "destination_location", "city"]}, "line_item__destination_location__id": {"type": ["integer", "null"], "from": ["line_item", "destination_location", "id"]}, "line_item__destination_location__address2": {"type": ["string", "null"], "from": ["line_item", "destination_location", "address2"]}, "line_item__destination_location__province_code": {"type": ["string", "null"], "from": ["line_item", "destination_location", "province_code"]}, "line_item__destination_location__zip": {"type": ["string", "null"], "from": ["line_item", "destination_location", "zip"]}, "line_item__quantity": {"type": ["integer", "null"], "from": ["line_item", "quantity"]}, "line_item__product_id": {"type": ["integer", "null"], "from": ["line_item", "product_id"]}, "line_item__variant_id": {"type": ["integer", "null"], "from": ["line_item", "variant_id"]}, "location_id": {"type": ["integer", "null"], "from": ["location_id"]}, "line_item_id": {"type": ["integer", "null"], "from": ["line_item_id"]}, "quantity": {"type": ["integer", "null"], "from": ["quantity"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "total_tax": {"type": ["number", "null"], "from": ["total_tax"]}, "restock_type": {"type": ["string", "null"], "from": ["restock_type"]}, "subtotal": {"type": ["number", "null"], "from": ["subtotal"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__refunds__refund_line_items__line_item__applied_discount; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__refunds__refund_line_items__line_item__applied_discount (
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__refunds__refund_line_items__line_item__applied_discount; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__refunds__refund_line_items__line_item__applied_discount IS '{"path": ["orders", "refunds", "refund_line_items", "line_item", "applied_discounts"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__refunds__refund_line_items__line_item__discount_allocat; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__refunds__refund_line_items__line_item__discount_allocat (
    discount_application_index bigint,
    amount double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__refunds__refund_line_items__line_item__discount_allocat; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__refunds__refund_line_items__line_item__discount_allocat IS '{"path": ["orders", "refunds", "refund_line_items", "line_item", "discount_allocations"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"discount_application_index": {"type": ["integer", "null"], "from": ["discount_application_index"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__refunds__refund_line_items__line_item__properties; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__refunds__refund_line_items__line_item__properties (
    name text,
    value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL,
    _sdc_level_2_id bigint NOT NULL
);


--
-- Name: TABLE orders__refunds__refund_line_items__line_item__properties; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__refunds__refund_line_items__line_item__properties IS '{"path": ["orders", "refunds", "refund_line_items", "line_item", "properties"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "value": {"type": ["string", "null"], "from": ["value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__refunds__refund_line_items__line_item__tax_lines; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__refunds__refund_line_items__line_item__tax_lines (
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE orders__refunds__refund_line_items__line_item__tax_lines; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__refunds__refund_line_items__line_item__tax_lines IS '{"path": ["orders", "refunds", "refund_line_items", "line_item", "tax_lines"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}, "_sdc_level_2_id": {"type": ["integer"], "from": ["_sdc_level_2_id"]}}}';


--
-- Name: orders__shipping_lines; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__shipping_lines (
    phone text,
    discounted_price_set__shop_money__amount text,
    discounted_price_set__shop_money__currency_code text,
    discounted_price_set__presentment_money__amount text,
    discounted_price_set__presentment_money__currency_code text,
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE orders__shipping_lines; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__shipping_lines IS '{"path": ["orders", "shipping_lines"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"phone": {"type": ["string", "null"], "from": ["phone"]}, "discounted_price_set__shop_money__amount": {"type": ["string", "null"], "from": ["discounted_price_set", "shop_money", "amount"]}, "discounted_price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["discounted_price_set", "shop_money", "currency_code"]}, "discounted_price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["discounted_price_set", "presentment_money", "amount"]}, "discounted_price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["discounted_price_set", "presentment_money", "currency_code"]}, "price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "delivery_category": {"type": ["string", "null"], "from": ["delivery_category"]}, "discounted_price": {"type": ["number", "null"], "from": ["discounted_price"]}, "code": {"type": ["string", "null"], "from": ["code"]}, "requested_fulfillment_service_id": {"type": ["string", "null"], "from": ["requested_fulfillment_service_id"]}, "carrier_identifier": {"type": ["string", "null"], "from": ["carrier_identifier"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: orders__shipping_lines__discount_allocations; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__shipping_lines__discount_allocations (
    discount_application_index bigint,
    amount double precision,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE orders__shipping_lines__discount_allocations; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__shipping_lines__discount_allocations IS '{"path": ["orders", "shipping_lines", "discount_allocations"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"discount_application_index": {"type": ["integer", "null"], "from": ["discount_application_index"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__shipping_lines__tax_lines; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__shipping_lines__tax_lines (
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE orders__shipping_lines__tax_lines; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__shipping_lines__tax_lines IS '{"path": ["orders", "shipping_lines", "tax_lines"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: orders__tax_lines; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.orders__tax_lines (
    price_set__shop_money__amount text,
    price_set__shop_money__currency_code text,
    price_set__presentment_money__amount text,
    price_set__presentment_money__currency_code text,
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
-- Name: TABLE orders__tax_lines; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.orders__tax_lines IS '{"path": ["orders", "tax_lines"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"price_set__shop_money__amount": {"type": ["string", "null"], "from": ["price_set", "shop_money", "amount"]}, "price_set__shop_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "shop_money", "currency_code"]}, "price_set__presentment_money__amount": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "amount"]}, "price_set__presentment_money__currency_code": {"type": ["string", "null"], "from": ["price_set", "presentment_money", "currency_code"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "rate": {"type": ["number", "null"], "from": ["rate"]}, "compare_at": {"type": ["string", "null"], "from": ["compare_at"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "source": {"type": ["string", "null"], "from": ["source"]}, "zone": {"type": ["string", "null"], "from": ["zone"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: products; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.products (
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
    account_id bigint NOT NULL,
    shop_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE products; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.products IS '{"path": ["products"], "version": null, "schema_version": 2, "key_properties": ["id"], "mappings": {"published_at": {"type": ["string", "null"], "from": ["published_at"], "format": "date-time"}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "published_scope": {"type": ["string", "null"], "from": ["published_scope"]}, "vendor": {"type": ["string", "null"], "from": ["vendor"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "body_html": {"type": ["string", "null"], "from": ["body_html"]}, "product_type": {"type": ["string", "null"], "from": ["product_type"]}, "tags": {"type": ["string", "null"], "from": ["tags"]}, "image__updated_at": {"type": ["string", "null"], "from": ["image", "updated_at"], "format": "date-time"}, "image__created_at": {"type": ["string", "null"], "from": ["image", "created_at"], "format": "date-time"}, "image__height": {"type": ["integer", "null"], "from": ["image", "height"]}, "image__alt": {"type": ["string", "null"], "from": ["image", "alt"]}, "image__src": {"type": ["string", "null"], "from": ["image", "src"]}, "image__position": {"type": ["integer", "null"], "from": ["image", "position"]}, "image__id": {"type": ["integer", "null"], "from": ["image", "id"]}, "image__admin_graphql_api_id": {"type": ["string", "null"], "from": ["image", "admin_graphql_api_id"]}, "image__width": {"type": ["integer", "null"], "from": ["image", "width"]}, "handle": {"type": ["string", "null"], "from": ["handle"]}, "template_suffix": {"type": ["string", "null"], "from": ["template_suffix"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "shop_id": {"type": ["integer"], "from": ["shop_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: products__image__variant_ids; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.products__image__variant_ids (
    _sdc_value bigint,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE products__image__variant_ids; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.products__image__variant_ids IS '{"path": ["products", "image", "variant_ids"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["integer", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: products__images; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.products__images (
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
-- Name: TABLE products__images; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.products__images IS '{"path": ["products", "images"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "height": {"type": ["integer", "null"], "from": ["height"]}, "alt": {"type": ["string", "null"], "from": ["alt"]}, "src": {"type": ["string", "null"], "from": ["src"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "width": {"type": ["integer", "null"], "from": ["width"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: products__images__variant_ids; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.products__images__variant_ids (
    _sdc_value bigint,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE products__images__variant_ids; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.products__images__variant_ids IS '{"path": ["products", "images", "variant_ids"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["integer", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: products__options; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.products__options (
    name text,
    product_id bigint,
    id bigint,
    "position" bigint,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL
);


--
-- Name: TABLE products__options; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.products__options IS '{"path": ["products", "options"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"name": {"type": ["string", "null"], "from": ["name"]}, "product_id": {"type": ["integer", "null"], "from": ["product_id"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: products__options__values; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.products__options__values (
    _sdc_value text,
    _sdc_source_key_id bigint,
    _sdc_sequence bigint,
    _sdc_level_0_id bigint NOT NULL,
    _sdc_level_1_id bigint NOT NULL
);


--
-- Name: TABLE products__options__values; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.products__options__values IS '{"path": ["products", "options", "values"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"_sdc_value": {"type": ["string", "null"], "from": ["_sdc_value"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}, "_sdc_level_1_id": {"type": ["integer"], "from": ["_sdc_level_1_id"]}}}';


--
-- Name: products__variants; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.products__variants (
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
-- Name: TABLE products__variants; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.products__variants IS '{"path": ["products", "variants"], "version": null, "schema_version": 2, "key_properties": ["_sdc_source_key_id"], "mappings": {"barcode": {"type": ["string", "null"], "from": ["barcode"]}, "tax_code": {"type": ["string", "null"], "from": ["tax_code"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"], "format": "date-time"}, "weight_unit": {"type": ["string", "null"], "from": ["weight_unit"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "position": {"type": ["integer", "null"], "from": ["position"]}, "price": {"type": ["number", "null"], "from": ["price"]}, "image_id": {"type": ["integer", "null"], "from": ["image_id"]}, "inventory_policy": {"type": ["string", "null"], "from": ["inventory_policy"]}, "sku": {"type": ["string", "null"], "from": ["sku"]}, "inventory_item_id": {"type": ["integer", "null"], "from": ["inventory_item_id"]}, "fulfillment_service": {"type": ["string", "null"], "from": ["fulfillment_service"]}, "title": {"type": ["string", "null"], "from": ["title"]}, "weight": {"type": ["number", "null"], "from": ["weight"]}, "inventory_management": {"type": ["string", "null"], "from": ["inventory_management"]}, "taxable": {"type": ["boolean", "null"], "from": ["taxable"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "option1": {"type": ["string", "null"], "from": ["option1"]}, "compare_at_price": {"type": ["number", "null"], "from": ["compare_at_price"]}, "updated_at": {"type": ["string", "null"], "from": ["updated_at"], "format": "date-time"}, "option2": {"type": ["string", "null"], "from": ["option2"]}, "old_inventory_quantity": {"type": ["integer", "null"], "from": ["old_inventory_quantity"]}, "requires_shipping": {"type": ["boolean", "null"], "from": ["requires_shipping"]}, "inventory_quantity": {"type": ["integer", "null"], "from": ["inventory_quantity"]}, "grams": {"type": ["integer", "null"], "from": ["grams"]}, "option3": {"type": ["string", "null"], "from": ["option3"]}, "_sdc_source_key_id": {"type": ["integer", "null"], "from": ["_sdc_source_key_id"]}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_level_0_id": {"type": ["integer"], "from": ["_sdc_level_0_id"]}}}';


--
-- Name: transactions; Type: TABLE; Schema: raw_tap_shopify; Owner: -
--

CREATE TABLE raw_tap_shopify.transactions (
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
    account_id bigint NOT NULL,
    shop_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE transactions; Type: COMMENT; Schema: raw_tap_shopify; Owner: -
--

COMMENT ON TABLE raw_tap_shopify.transactions IS '{"path": ["transactions"], "version": null, "schema_version": 2, "key_properties": ["id"], "mappings": {"error_code": {"type": ["string", "null"], "from": ["error_code"]}, "device_id": {"type": ["integer", "null"], "from": ["device_id"]}, "user_id": {"type": ["integer", "null"], "from": ["user_id"]}, "parent_id": {"type": ["integer", "null"], "from": ["parent_id"]}, "test": {"type": ["boolean", "null"], "from": ["test"]}, "kind": {"type": ["string", "null"], "from": ["kind"]}, "order_id": {"type": ["integer", "null"], "from": ["order_id"]}, "amount": {"type": ["number", "null"], "from": ["amount"]}, "authorization": {"type": ["string", "null"], "from": ["authorization"]}, "currency": {"type": ["string", "null"], "from": ["currency"]}, "source_name": {"type": ["string", "null"], "from": ["source_name"]}, "message": {"type": ["string", "null"], "from": ["message"]}, "id": {"type": ["integer", "null"], "from": ["id"]}, "created_at": {"type": ["string", "null"], "from": ["created_at"]}, "status": {"type": ["string", "null"], "from": ["status"]}, "payment_details__cvv_result_code": {"type": ["string", "null"], "from": ["payment_details", "cvv_result_code"]}, "payment_details__credit_card_bin": {"type": ["string", "null"], "from": ["payment_details", "credit_card_bin"]}, "payment_details__credit_card_company": {"type": ["string", "null"], "from": ["payment_details", "credit_card_company"]}, "payment_details__credit_card_number": {"type": ["string", "null"], "from": ["payment_details", "credit_card_number"]}, "payment_details__avs_result_code": {"type": ["string", "null"], "from": ["payment_details", "avs_result_code"]}, "gateway": {"type": ["string", "null"], "from": ["gateway"]}, "admin_graphql_api_id": {"type": ["string", "null"], "from": ["admin_graphql_api_id"]}, "receipt__fee_amount": {"type": ["number", "null"], "from": ["receipt", "fee_amount"]}, "receipt__gross_amount": {"type": ["number", "null"], "from": ["receipt", "gross_amount"]}, "receipt__tax_amount": {"type": ["number", "null"], "from": ["receipt", "tax_amount"]}, "location_id": {"type": ["integer", "null"], "from": ["location_id"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "shop_id": {"type": ["integer"], "from": ["shop_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: sales; Type: TABLE; Schema: tap_csv; Owner: -
--

CREATE TABLE tap_csv.sales (
    region text NOT NULL,
    country text NOT NULL,
    item_type text NOT NULL,
    sales_channel text NOT NULL,
    order_priority text NOT NULL,
    order_date text NOT NULL,
    order_id text NOT NULL,
    ship_date text NOT NULL,
    units_sold text NOT NULL,
    unit_price text NOT NULL,
    unit_cost text NOT NULL,
    total_revenue text NOT NULL,
    total_cost text NOT NULL,
    total_profit text NOT NULL,
    account_id bigint NOT NULL,
    _sdc_received_at timestamp with time zone,
    _sdc_sequence bigint,
    _sdc_table_version bigint,
    _sdc_batched_at timestamp with time zone
);


--
-- Name: TABLE sales; Type: COMMENT; Schema: tap_csv; Owner: -
--

COMMENT ON TABLE tap_csv.sales IS '{"path": ["sales"], "version": null, "schema_version": 2, "key_properties": ["Order ID"], "mappings": {"region": {"type": ["string"], "from": ["Region"]}, "country": {"type": ["string"], "from": ["Country"]}, "item_type": {"type": ["string"], "from": ["Item Type"]}, "sales_channel": {"type": ["string"], "from": ["Sales Channel"]}, "order_priority": {"type": ["string"], "from": ["Order Priority"]}, "order_date": {"type": ["string"], "from": ["Order Date"]}, "order_id": {"type": ["string"], "from": ["Order ID"]}, "ship_date": {"type": ["string"], "from": ["Ship Date"]}, "units_sold": {"type": ["string"], "from": ["Units Sold"]}, "unit_price": {"type": ["string"], "from": ["Unit Price"]}, "unit_cost": {"type": ["string"], "from": ["Unit Cost"]}, "total_revenue": {"type": ["string"], "from": ["Total Revenue"]}, "total_cost": {"type": ["string"], "from": ["Total Cost"]}, "total_profit": {"type": ["string"], "from": ["Total Profit"]}, "account_id": {"type": ["integer"], "from": ["account_id"]}, "_sdc_received_at": {"type": ["string", "null"], "from": ["_sdc_received_at"], "format": "date-time"}, "_sdc_sequence": {"type": ["integer", "null"], "from": ["_sdc_sequence"]}, "_sdc_table_version": {"type": ["integer", "null"], "from": ["_sdc_table_version"]}, "_sdc_batched_at": {"type": ["string", "null"], "from": ["_sdc_batched_at"], "format": "date-time"}}}';


--
-- Name: base_shopify_orders; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.base_shopify_orders AS
 SELECT orders.account_id,
    orders.shop_id,
    orders.id AS order_id,
    orders.app_id,
    orders.name AS order_name,
    orders.user_id,
    orders.customer__id AS customer_id,
    orders.checkout_id,
    orders.checkout_token,
    orders.cart_token,
    orders.token,
    lower(orders.email) AS email,
    orders.contact_email,
    orders.buyer_accepts_marketing,
    orders.confirmed,
    'number'::text AS internal_number,
    orders.order_number,
    orders.currency,
    orders.presentment_currency,
    orders.financial_status,
    orders.fulfillment_status,
    orders.gateway,
    orders.processing_method,
    orders.total_tip_received,
    orders.total_weight,
    ((orders.total_discounts)::numeric(38,6) * ('-1'::integer)::numeric) AS total_discounts_base,
    (orders.subtotal_price)::numeric(38,6) AS subtotal_price,
    orders.total_line_items_price,
    orders.total_price,
    orders.total_price_usd,
    orders.total_tax,
    (orders.total_shipping_price_set__presentment_money__amount)::numeric(38,6) AS total_shipping_cost_base,
    (orders.total_shipping_price_set__presentment_money__currency_code)::character varying(128) AS shipping_currency_code,
    orders.tags,
    orders.taxes_included,
    orders.order_status_url,
    orders.location_id,
    (orders.shipping_address__city)::character varying(256) AS shipping_city,
    (orders.shipping_address__province)::character varying(256) AS shipping_province,
    (orders.shipping_address__province_code)::character varying(256) AS shipping_province_code,
    (orders.shipping_address__country)::character varying(256) AS shipping_country,
    (orders.shipping_address__country_code)::character varying(256) AS shipping_country_code,
    (orders.shipping_address__zip)::character varying(256) AS shipping_zip_code,
    (orders.shipping_address__address1)::character varying(256) AS shipping_address_address1,
    (orders.shipping_address__address2)::character varying(256) AS shipping_address_address2,
    (orders.shipping_address__company)::character varying(256) AS shipping_company,
    (orders.shipping_address__first_name)::character varying(256) AS shipping_first_name,
    (orders.shipping_address__last_name)::character varying(256) AS shipping_last_name,
    (orders.shipping_address__latitude)::bigint AS shipping_latitude,
    (orders.shipping_address__longitude)::bigint AS shipping_longitude,
    (orders.shipping_address__name)::character varying(256) AS shipping_name,
    (orders.shipping_address__phone)::character varying(256) AS shipping_phone,
    (orders.billing_address__city)::character varying(256) AS billing_city,
    (orders.billing_address__province)::character varying(256) AS billing_province,
    (orders.billing_address__province_code)::character varying(256) AS billing_province_code,
    (orders.billing_address__country)::character varying(256) AS billing_country,
    (orders.billing_address__country_code)::character varying(256) AS billing_country_code,
    (orders.billing_address__zip)::character varying(256) AS billing_zip_code,
    (orders.billing_address__address1)::character varying(256) AS billing_address_address1,
    (orders.billing_address__address2)::character varying(256) AS billing_address_address2,
    (orders.billing_address__company)::character varying(256) AS billing_company,
    (orders.billing_address__first_name)::character varying(256) AS billing_first_name,
    (orders.billing_address__last_name)::character varying(256) AS billing_last_name,
    (orders.billing_address__latitude)::bigint AS billing_latitude,
    (orders.billing_address__longitude)::bigint AS billing_longitude,
    (orders.billing_address__name)::character varying(256) AS billing_name,
    (orders.billing_address__phone)::character varying(256) AS billing_phone,
    orders.referring_site,
    orders.browser_ip,
    orders.landing_site,
    orders.source_name,
    orders.created_at,
    orders.processed_at,
    orders.closed_at,
    orders.cancelled_at,
    orders.cancel_reason,
    orders.updated_at
   FROM raw_tap_shopify.orders
  WHERE (orders.test = false);


--
-- Name: base_snowplow_web_events; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.base_snowplow_web_events AS
 WITH source AS (
         SELECT snowplow_production_enriched.app_id,
            snowplow_production_enriched.platform,
            snowplow_production_enriched.etl_tstamp,
            snowplow_production_enriched.collector_tstamp,
            snowplow_production_enriched.derived_tstamp,
            snowplow_production_enriched.true_tstamp,
            snowplow_production_enriched.event,
            snowplow_production_enriched.event_id,
            snowplow_production_enriched.event_vendor,
            snowplow_production_enriched.event_name,
            snowplow_production_enriched.event_format,
            snowplow_production_enriched.event_version,
            snowplow_production_enriched.event_fingerprint,
            snowplow_production_enriched.txn_id,
            snowplow_production_enriched.name_tracker,
            snowplow_production_enriched.v_tracker,
            snowplow_production_enriched.v_collector,
            snowplow_production_enriched.v_etl,
            snowplow_production_enriched.user_id,
            snowplow_production_enriched.user_ipaddress,
            snowplow_production_enriched.user_fingerprint,
            snowplow_production_enriched.domain_userid,
            snowplow_production_enriched.domain_sessionidx,
            snowplow_production_enriched.domain_sessionid,
            snowplow_production_enriched.network_userid,
            snowplow_production_enriched.geo_country,
            snowplow_production_enriched.geo_region,
            snowplow_production_enriched.geo_city,
            snowplow_production_enriched.geo_zipcode,
            snowplow_production_enriched.geo_latitude,
            snowplow_production_enriched.geo_longitude,
            snowplow_production_enriched.geo_region_name,
            snowplow_production_enriched.geo_location,
            snowplow_production_enriched.ip_isp,
            snowplow_production_enriched.ip_organization,
            snowplow_production_enriched.ip_domain,
            snowplow_production_enriched.ip_netspeed,
            snowplow_production_enriched.page_url,
            snowplow_production_enriched.page_title,
            snowplow_production_enriched.page_referrer,
            snowplow_production_enriched.page_urlscheme,
            snowplow_production_enriched.page_urlhost,
            snowplow_production_enriched.page_urlport,
            snowplow_production_enriched.page_urlpath,
            snowplow_production_enriched.page_urlquery,
            snowplow_production_enriched.page_urlfragment,
            snowplow_production_enriched.refr_urlscheme,
            snowplow_production_enriched.refr_urlhost,
            snowplow_production_enriched.refr_urlport,
            snowplow_production_enriched.refr_urlpath,
            snowplow_production_enriched.refr_urlquery,
            snowplow_production_enriched.refr_urlfragment,
            snowplow_production_enriched.refr_medium,
            snowplow_production_enriched.refr_source,
            snowplow_production_enriched.refr_term,
            snowplow_production_enriched.mkt_medium,
            snowplow_production_enriched.mkt_source,
            snowplow_production_enriched.mkt_term,
            snowplow_production_enriched.mkt_content,
            snowplow_production_enriched.mkt_campaign,
            snowplow_production_enriched.se_category,
            snowplow_production_enriched.se_action,
            snowplow_production_enriched.se_label,
            snowplow_production_enriched.se_property,
            snowplow_production_enriched.se_value,
            snowplow_production_enriched.tr_orderid,
            snowplow_production_enriched.tr_affiliation,
            snowplow_production_enriched.tr_total,
            snowplow_production_enriched.tr_tax,
            snowplow_production_enriched.tr_shipping,
            snowplow_production_enriched.tr_city,
            snowplow_production_enriched.tr_state,
            snowplow_production_enriched.tr_country,
            snowplow_production_enriched.ti_orderid,
            snowplow_production_enriched.ti_sku,
            snowplow_production_enriched.ti_name,
            snowplow_production_enriched.ti_category,
            snowplow_production_enriched.ti_price,
            snowplow_production_enriched.ti_quantity,
            snowplow_production_enriched.pp_xoffset_min,
            snowplow_production_enriched.pp_xoffset_max,
            snowplow_production_enriched.pp_yoffset_min,
            snowplow_production_enriched.pp_yoffset_max,
            snowplow_production_enriched.useragent,
            snowplow_production_enriched.br_name,
            snowplow_production_enriched.br_family,
            snowplow_production_enriched.br_version,
            snowplow_production_enriched.br_type,
            snowplow_production_enriched.br_renderengine,
            snowplow_production_enriched.br_lang,
            snowplow_production_enriched.br_features_pdf,
            snowplow_production_enriched.br_features_flash,
            snowplow_production_enriched.br_features_java,
            snowplow_production_enriched.br_features_director,
            snowplow_production_enriched.br_features_quicktime,
            snowplow_production_enriched.br_features_realplayer,
            snowplow_production_enriched.br_features_windowsmedia,
            snowplow_production_enriched.br_features_gears,
            snowplow_production_enriched.br_features_silverlight,
            snowplow_production_enriched.br_cookies,
            snowplow_production_enriched.br_colordepth,
            snowplow_production_enriched.br_viewwidth,
            snowplow_production_enriched.br_viewheight,
            snowplow_production_enriched.os_name,
            snowplow_production_enriched.os_family,
            snowplow_production_enriched.os_manufacturer,
            snowplow_production_enriched.os_timezone,
            snowplow_production_enriched.dvce_type,
            snowplow_production_enriched.dvce_ismobile,
            snowplow_production_enriched.dvce_screenwidth,
            snowplow_production_enriched.dvce_screenheight,
            snowplow_production_enriched.dvce_created_tstamp,
            snowplow_production_enriched.doc_charset,
            snowplow_production_enriched.doc_width,
            snowplow_production_enriched.doc_height,
            snowplow_production_enriched.tr_currency,
            snowplow_production_enriched.tr_total_base,
            snowplow_production_enriched.tr_tax_base,
            snowplow_production_enriched.tr_shipping_base,
            snowplow_production_enriched.ti_currency,
            snowplow_production_enriched.ti_price_base,
            snowplow_production_enriched.base_currency,
            snowplow_production_enriched.geo_timezone,
            snowplow_production_enriched.mkt_clickid,
            snowplow_production_enriched.mkt_network,
            snowplow_production_enriched.etl_tags,
            snowplow_production_enriched.dvce_sent_tstamp,
            snowplow_production_enriched.refr_domain_userid,
            snowplow_production_enriched.refr_dvce_tstamp,
            snowplow_production_enriched.session_id,
            snowplow_production_enriched._sdc_received_at,
            snowplow_production_enriched._sdc_sequence,
            snowplow_production_enriched._sdc_table_version,
            snowplow_production_enriched._sdc_batched_at,
            snowplow_production_enriched._sdc_primary_key
           FROM raw_tap_kafka.snowplow_production_enriched
        ), filtered AS (
         SELECT source.app_id,
            source.platform,
            source.etl_tstamp,
            source.collector_tstamp,
            source.derived_tstamp,
            source.true_tstamp,
            source.event,
            source.event_id,
            source.event_vendor,
            source.event_name,
            source.event_format,
            source.event_version,
            source.event_fingerprint,
            source.txn_id,
            source.name_tracker,
            source.v_tracker,
            source.v_collector,
            source.v_etl,
            source.user_id,
            source.user_ipaddress,
            source.user_fingerprint,
            source.domain_userid,
            source.domain_sessionidx,
            source.domain_sessionid,
            source.network_userid,
            source.geo_country,
            source.geo_region,
            source.geo_city,
            source.geo_zipcode,
            source.geo_latitude,
            source.geo_longitude,
            source.geo_region_name,
            source.geo_location,
            source.ip_isp,
            source.ip_organization,
            source.ip_domain,
            source.ip_netspeed,
            source.page_url,
            source.page_title,
            source.page_referrer,
            source.page_urlscheme,
            source.page_urlhost,
            source.page_urlport,
            source.page_urlpath,
            source.page_urlquery,
            source.page_urlfragment,
            source.refr_urlscheme,
            source.refr_urlhost,
            source.refr_urlport,
            source.refr_urlpath,
            source.refr_urlquery,
            source.refr_urlfragment,
            source.refr_medium,
            source.refr_source,
            source.refr_term,
            source.mkt_medium,
            source.mkt_source,
            source.mkt_term,
            source.mkt_content,
            source.mkt_campaign,
            source.se_category,
            source.se_action,
            source.se_label,
            source.se_property,
            source.se_value,
            source.tr_orderid,
            source.tr_affiliation,
            source.tr_total,
            source.tr_tax,
            source.tr_shipping,
            source.tr_city,
            source.tr_state,
            source.tr_country,
            source.ti_orderid,
            source.ti_sku,
            source.ti_name,
            source.ti_category,
            source.ti_price,
            source.ti_quantity,
            source.pp_xoffset_min,
            source.pp_xoffset_max,
            source.pp_yoffset_min,
            source.pp_yoffset_max,
            source.useragent,
            source.br_name,
            source.br_family,
            source.br_version,
            source.br_type,
            source.br_renderengine,
            source.br_lang,
            source.br_features_pdf,
            source.br_features_flash,
            source.br_features_java,
            source.br_features_director,
            source.br_features_quicktime,
            source.br_features_realplayer,
            source.br_features_windowsmedia,
            source.br_features_gears,
            source.br_features_silverlight,
            source.br_cookies,
            source.br_colordepth,
            source.br_viewwidth,
            source.br_viewheight,
            source.os_name,
            source.os_family,
            source.os_manufacturer,
            source.os_timezone,
            source.dvce_type,
            source.dvce_ismobile,
            source.dvce_screenwidth,
            source.dvce_screenheight,
            source.dvce_created_tstamp,
            source.doc_charset,
            source.doc_width,
            source.doc_height,
            source.tr_currency,
            source.tr_total_base,
            source.tr_tax_base,
            source.tr_shipping_base,
            source.ti_currency,
            source.ti_price_base,
            source.base_currency,
            source.geo_timezone,
            source.mkt_clickid,
            source.mkt_network,
            source.etl_tags,
            source.dvce_sent_tstamp,
            source.refr_domain_userid,
            source.refr_dvce_tstamp,
            source.session_id,
            source._sdc_received_at,
            source._sdc_sequence,
            source._sdc_table_version,
            source._sdc_batched_at,
            source._sdc_primary_key
           FROM source
          WHERE (true AND (source.domain_sessionid IS NOT NULL) AND (source.domain_sessionidx IS NOT NULL) AND (source.domain_userid IS NOT NULL))
        )
 SELECT filtered.app_id,
    filtered.platform,
    filtered.etl_tstamp,
    filtered.collector_tstamp,
    filtered.derived_tstamp,
    filtered.true_tstamp,
    filtered.event,
    filtered.event_id,
    filtered.event_vendor,
    filtered.event_name,
    filtered.event_format,
    filtered.event_version,
    filtered.event_fingerprint,
    filtered.txn_id,
    filtered.name_tracker,
    filtered.v_tracker,
    filtered.v_collector,
    filtered.v_etl,
    filtered.user_id,
    filtered.user_ipaddress,
    filtered.user_fingerprint,
    filtered.domain_userid,
    filtered.domain_sessionidx,
    filtered.domain_sessionid,
    filtered.network_userid,
    filtered.geo_country,
    filtered.geo_region,
    filtered.geo_city,
    filtered.geo_zipcode,
    filtered.geo_latitude,
    filtered.geo_longitude,
    filtered.geo_region_name,
    filtered.geo_location,
    filtered.ip_isp,
    filtered.ip_organization,
    filtered.ip_domain,
    filtered.ip_netspeed,
    filtered.page_url,
    filtered.page_title,
    filtered.page_referrer,
    filtered.page_urlscheme,
    filtered.page_urlhost,
    filtered.page_urlport,
    filtered.page_urlpath,
    filtered.page_urlquery,
    filtered.page_urlfragment,
    filtered.refr_urlscheme,
    filtered.refr_urlhost,
    filtered.refr_urlport,
    filtered.refr_urlpath,
    filtered.refr_urlquery,
    filtered.refr_urlfragment,
    filtered.refr_medium,
    filtered.refr_source,
    filtered.refr_term,
    filtered.mkt_medium,
    filtered.mkt_source,
    filtered.mkt_term,
    filtered.mkt_content,
    filtered.mkt_campaign,
    filtered.se_category,
    filtered.se_action,
    filtered.se_label,
    filtered.se_property,
    filtered.se_value,
    filtered.tr_orderid,
    filtered.tr_affiliation,
    filtered.tr_total,
    filtered.tr_tax,
    filtered.tr_shipping,
    filtered.tr_city,
    filtered.tr_state,
    filtered.tr_country,
    filtered.ti_orderid,
    filtered.ti_sku,
    filtered.ti_name,
    filtered.ti_category,
    filtered.ti_price,
    filtered.ti_quantity,
    filtered.pp_xoffset_min,
    filtered.pp_xoffset_max,
    filtered.pp_yoffset_min,
    filtered.pp_yoffset_max,
    filtered.useragent,
    filtered.br_name,
    filtered.br_family,
    filtered.br_version,
    filtered.br_type,
    filtered.br_renderengine,
    filtered.br_lang,
    filtered.br_features_pdf,
    filtered.br_features_flash,
    filtered.br_features_java,
    filtered.br_features_director,
    filtered.br_features_quicktime,
    filtered.br_features_realplayer,
    filtered.br_features_windowsmedia,
    filtered.br_features_gears,
    filtered.br_features_silverlight,
    filtered.br_cookies,
    filtered.br_colordepth,
    filtered.br_viewwidth,
    filtered.br_viewheight,
    filtered.os_name,
    filtered.os_family,
    filtered.os_manufacturer,
    filtered.os_timezone,
    filtered.dvce_type,
    filtered.dvce_ismobile,
    filtered.dvce_screenwidth,
    filtered.dvce_screenheight,
    filtered.dvce_created_tstamp,
    filtered.doc_charset,
    filtered.doc_width,
    filtered.doc_height,
    filtered.tr_currency,
    filtered.tr_total_base,
    filtered.tr_tax_base,
    filtered.tr_shipping_base,
    filtered.ti_currency,
    filtered.ti_price_base,
    filtered.base_currency,
    filtered.geo_timezone,
    filtered.mkt_clickid,
    filtered.mkt_network,
    filtered.etl_tags,
    filtered.dvce_sent_tstamp,
    filtered.refr_domain_userid,
    filtered.refr_dvce_tstamp,
    filtered.session_id,
    filtered._sdc_received_at,
    filtered._sdc_sequence,
    filtered._sdc_table_version,
    filtered._sdc_batched_at,
    filtered._sdc_primary_key
   FROM filtered;


--
-- Name: base_snowplow_web_page_context; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.base_snowplow_web_page_context AS
 SELECT snowplow_production_enriched__contexts_com_snowplowanalytics_sn.id,
    snowplow_production_enriched__contexts_com_snowplowanalytics_sn._sdc_source_key__sdc_primary_key,
    snowplow_production_enriched__contexts_com_snowplowanalytics_sn._sdc_sequence,
    snowplow_production_enriched__contexts_com_snowplowanalytics_sn._sdc_level_0_id,
    snowplow_production_enriched__contexts_com_snowplowanalytics_sn.id AS page_view_id
   FROM raw_tap_kafka.snowplow_production_enriched__contexts_com_snowplowanalytics_sn;


--
-- Name: base_snowplow_web_performance_timing_context; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.base_snowplow_web_performance_timing_context AS
 SELECT snowplow_production_enriched__contexts_org_w3_performance_timin._sdc_sequence,
    snowplow_production_enriched__contexts_org_w3_performance_timin._sdc_source_key__sdc_primary_key,
    snowplow_production_enriched__contexts_org_w3_performance_timin._sdc_level_0_id,
    snowplow_production_enriched__contexts_org_w3_performance_timin.navigationstart AS navigation_start,
    snowplow_production_enriched__contexts_org_w3_performance_timin.redirectstart AS redirect_start,
    snowplow_production_enriched__contexts_org_w3_performance_timin.redirectend AS redirect_end,
    snowplow_production_enriched__contexts_org_w3_performance_timin.fetchstart AS fetch_start,
    snowplow_production_enriched__contexts_org_w3_performance_timin.domainlookupstart AS domain_lookup_start,
    snowplow_production_enriched__contexts_org_w3_performance_timin.domainlookupend AS domain_lookup_end,
    snowplow_production_enriched__contexts_org_w3_performance_timin.secureconnectionstart AS secure_connection_start,
    snowplow_production_enriched__contexts_org_w3_performance_timin.connectstart AS connect_start,
    snowplow_production_enriched__contexts_org_w3_performance_timin.connectend AS connect_end,
    snowplow_production_enriched__contexts_org_w3_performance_timin.requeststart AS request_start,
    snowplow_production_enriched__contexts_org_w3_performance_timin.responsestart AS response_start,
    snowplow_production_enriched__contexts_org_w3_performance_timin.responseend AS response_end,
    snowplow_production_enriched__contexts_org_w3_performance_timin.unloadeventstart AS unload_event_start,
    snowplow_production_enriched__contexts_org_w3_performance_timin.unloadeventend AS unload_event_end,
    snowplow_production_enriched__contexts_org_w3_performance_timin.domloading AS dom_loading,
    snowplow_production_enriched__contexts_org_w3_performance_timin.dominteractive AS dom_interactive,
    snowplow_production_enriched__contexts_org_w3_performance_timin.domcontentloadedeventstart AS dom_content_loaded_event_start,
    snowplow_production_enriched__contexts_org_w3_performance_timin.domcontentloadedeventend AS dom_content_loaded_event_end,
    snowplow_production_enriched__contexts_org_w3_performance_timin.domcomplete AS dom_complete,
    snowplow_production_enriched__contexts_org_w3_performance_timin.loadeventstart AS load_event_start,
    snowplow_production_enriched__contexts_org_w3_performance_timin.loadeventend AS load_event_end
   FROM raw_tap_kafka.snowplow_production_enriched__contexts_org_w3_performance_timin;


--
-- Name: base_snowplow_web_ua_parser_context; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.base_snowplow_web_ua_parser_context AS
 SELECT snowplow_production_enriched__contexts_com_snowplowanalytics__1._sdc_sequence,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1._sdc_source_key__sdc_primary_key,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1._sdc_level_0_id,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.useragentfamily AS useragent_family,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.useragentmajor AS useragent_major,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.useragentminor AS useragent_minor,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.useragentpatch AS useragent_patch,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.useragentversion AS useragent_version,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.osfamily AS os_family,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.osmajor AS os_major,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.osminor AS os_minor,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.ospatch AS os_patch,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.ospatchminor AS os_patch_minor,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.osversion AS os_version,
    snowplow_production_enriched__contexts_com_snowplowanalytics__1.devicefamily AS device_family
   FROM raw_tap_kafka.snowplow_production_enriched__contexts_com_snowplowanalytics__1;


--
-- Name: base_superpro_accounts; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.base_superpro_accounts AS
 SELECT accounts.id AS account_id,
    accounts.name,
    accounts.created_at,
    accounts.updated_at,
    accounts.discarded_at
   FROM public.accounts;


--
-- Name: base_superpro_shopify_shops; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.base_superpro_shopify_shops AS
 SELECT shopify_shops.id,
    shopify_shops.account_id,
    shopify_shops.shop_id,
    shopify_shops.shopify_domain,
    shopify_shops.created_at,
    shopify_shops.updated_at
   FROM public.shopify_shops;


--
-- Name: dim_date; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.dim_date AS
 SELECT (to_char((dq.datum)::timestamp with time zone, 'yyyymmdd'::text))::integer AS id,
    dq.datum AS full_date,
    date_part('epoch'::text, dq.datum) AS epoch,
    to_char((dq.datum)::timestamp with time zone, 'fmDDth'::text) AS day_suffix,
    to_char((dq.datum)::timestamp with time zone, 'Day'::text) AS day_name,
    date_part('isodow'::text, dq.datum) AS day_of_week,
    date_part('day'::text, dq.datum) AS day_of_month,
    ((dq.datum - (date_trunc('quarter'::text, (dq.datum)::timestamp with time zone))::date) + 1) AS day_of_quarter,
    date_part('doy'::text, dq.datum) AS day_of_year,
    (to_char((dq.datum)::timestamp with time zone, 'W'::text))::integer AS week_of_month,
    date_part('week'::text, dq.datum) AS week_of_year,
    (to_char((dq.datum)::timestamp with time zone, 'YYYY"-W"IW-'::text) || date_part('isodow'::text, dq.datum)) AS week_of_year_iso,
    date_part('month'::text, dq.datum) AS month_actual,
    to_char((dq.datum)::timestamp with time zone, 'Month'::text) AS month_name,
    to_char((dq.datum)::timestamp with time zone, 'Mon'::text) AS month_name_abbreviated,
    date_part('quarter'::text, dq.datum) AS quarter_actual,
        CASE
            WHEN (date_part('quarter'::text, dq.datum) = (1)::double precision) THEN 'First'::text
            WHEN (date_part('quarter'::text, dq.datum) = (2)::double precision) THEN 'Second'::text
            WHEN (date_part('quarter'::text, dq.datum) = (3)::double precision) THEN 'Third'::text
            WHEN (date_part('quarter'::text, dq.datum) = (4)::double precision) THEN 'Fourth'::text
            ELSE NULL::text
        END AS quarter_name,
    date_part('isoyear'::text, dq.datum) AS year_actual,
    (dq.datum + (((1)::double precision - date_part('isodow'::text, dq.datum)))::integer) AS first_day_of_week,
    (dq.datum + (((7)::double precision - date_part('isodow'::text, dq.datum)))::integer) AS last_day_of_week,
    (dq.datum + (((1)::double precision - date_part('day'::text, dq.datum)))::integer) AS first_day_of_month,
    ((date_trunc('MONTH'::text, (dq.datum)::timestamp with time zone) + '1 mon -1 days'::interval))::date AS last_day_of_month,
    (date_trunc('quarter'::text, (dq.datum)::timestamp with time zone))::date AS first_day_of_quarter,
    ((date_trunc('quarter'::text, (dq.datum)::timestamp with time zone) + '3 mons -1 days'::interval))::date AS last_day_of_quarter,
    to_date((date_part('isoyear'::text, dq.datum) || '-01-01'::text), 'YYYY-MM-DD'::text) AS first_day_of_year,
    to_date((date_part('isoyear'::text, dq.datum) || '-12-31'::text), 'YYYY-MM-DD'::text) AS last_day_of_year,
    to_char((dq.datum)::timestamp with time zone, 'mmyyyy'::text) AS mmyyyy,
    to_char((dq.datum)::timestamp with time zone, 'mmddyyyy'::text) AS mmddyyyy,
        CASE
            WHEN (date_part('isodow'::text, dq.datum) = ANY (ARRAY[(6)::double precision, (7)::double precision])) THEN true
            ELSE false
        END AS weekend_indr
   FROM ( SELECT ('1970-01-01'::date + sequence.day) AS datum
           FROM generate_series(0, 29219) sequence(day)
          GROUP BY sequence.day) dq
  ORDER BY (to_char((dq.datum)::timestamp with time zone, 'yyyymmdd'::text))::integer;


--
-- Name: dim_shopify_customers; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.dim_shopify_customers (
    customer_id bigint,
    account_id bigint,
    email text,
    verified_email boolean,
    first_name text,
    last_name text,
    accepts_marketing boolean,
    state text,
    tax_exempt boolean,
    tags text[],
    default_address_id bigint,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    total_order_count bigint,
    total_successful_order_count bigint,
    total_cancelled_order_count bigint,
    total_spend double precision,
    previous_1_month_spend double precision,
    previous_3_month_spend double precision,
    previous_6_month_spend double precision,
    previous_12_month_spend double precision,
    most_recent_order_id bigint,
    most_recent_order_number bigint,
    most_recent_order_at timestamp with time zone,
    most_recent_order_total_price double precision,
    first_order_id bigint,
    first_order_number bigint,
    first_order_at timestamp with time zone,
    first_order_total_price double precision,
    rfm_recency_quintile integer,
    rfm_frequency_quintile integer,
    rfm_monetary_quintile integer,
    rfm_score text,
    rfm_label text,
    rfm_value_label text,
    rfm_desirability_score integer,
    business_line text
);


--
-- Name: fct_shopify_customer_pareto; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.fct_shopify_customer_pareto (
    account_id bigint,
    customer_id bigint,
    year double precision,
    sales double precision,
    business_line text,
    percent_of_sales double precision,
    cumulative_percent_of_sales double precision,
    customer_rank bigint
);


--
-- Name: fct_shopify_customer_retention; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.fct_shopify_customer_retention (
    total_customers bigint,
    total_active_customers bigint,
    total_orders numeric,
    total_spend double precision,
    months_since_genesis integer,
    genesis_month timestamp with time zone,
    account_id bigint,
    pct_active_customers numeric
);


--
-- Name: fct_shopify_orders; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.fct_shopify_orders (
    order_id bigint,
    account_id bigint,
    shop_id bigint,
    app_id bigint,
    order_name text,
    user_id bigint,
    customer_id bigint,
    checkout_id bigint,
    checkout_token text,
    cart_token text,
    token text,
    email text,
    contact_email text,
    buyer_accepts_marketing boolean,
    confirmed boolean,
    internal_number text,
    order_number bigint,
    currency text,
    presentment_currency text,
    financial_status text,
    fulfillment_status text,
    gateway text,
    processing_method text,
    total_tip_received text,
    total_weight bigint,
    total_discounts_base numeric,
    subtotal_price numeric(38,6),
    total_line_items_price double precision,
    total_price double precision,
    total_price_usd double precision,
    total_tax double precision,
    total_shipping_cost_base numeric(38,6),
    shipping_currency_code character varying(128),
    tags text,
    taxes_included boolean,
    order_status_url text,
    location_id bigint,
    shipping_city character varying(256),
    shipping_province character varying(256),
    shipping_province_code character varying(256),
    shipping_country character varying(256),
    shipping_country_code character varying(256),
    shipping_zip_code character varying(256),
    shipping_address_address1 character varying(256),
    shipping_address_address2 character varying(256),
    shipping_company character varying(256),
    shipping_first_name character varying(256),
    shipping_last_name character varying(256),
    shipping_latitude bigint,
    shipping_longitude bigint,
    shipping_name character varying(256),
    shipping_phone character varying(256),
    billing_city character varying(256),
    billing_province character varying(256),
    billing_province_code character varying(256),
    billing_country character varying(256),
    billing_country_code character varying(256),
    billing_zip_code character varying(256),
    billing_address_address1 character varying(256),
    billing_address_address2 character varying(256),
    billing_company character varying(256),
    billing_first_name character varying(256),
    billing_last_name character varying(256),
    billing_latitude bigint,
    billing_longitude bigint,
    billing_name character varying(256),
    billing_phone character varying(256),
    referring_site text,
    browser_ip text,
    landing_site text,
    source_name text,
    created_at timestamp with time zone,
    processed_at timestamp with time zone,
    closed_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    cancel_reason text,
    updated_at timestamp with time zone,
    discount_code text,
    discount_type text,
    shipping_discount double precision,
    final_discounts double precision,
    final_shipping_cost double precision,
    order_seq_number bigint,
    new_vs_repeat text,
    cancelled boolean
);


--
-- Name: fct_shopify_repurchase_intervals; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.fct_shopify_repurchase_intervals AS
 WITH orders AS (
         SELECT fct_shopify_orders.customer_id,
            fct_shopify_orders.account_id,
            fct_shopify_orders.total_price,
            fct_shopify_orders.created_at AS order_date,
            lag(fct_shopify_orders.created_at) OVER (PARTITION BY fct_shopify_orders.customer_id ORDER BY fct_shopify_orders.created_at) AS previous_order_date
           FROM warehouse.fct_shopify_orders
          WHERE (fct_shopify_orders.cancelled_at IS NULL)
        ), repurchases AS (
         SELECT orders.customer_id,
            orders.account_id,
            orders.order_date,
            orders.previous_order_date,
            date_part('day'::text, (orders.order_date - orders.previous_order_date)) AS days_since_previous_order,
            width_bucket(date_part('day'::text, (orders.order_date - orders.previous_order_date)), (0)::double precision, (600)::double precision, 30) AS days_since_previous_order_bucket,
            orders.total_price AS repeat_purchase_total_price
           FROM orders
          WHERE (orders.previous_order_date IS NOT NULL)
        )
 SELECT repurchases.customer_id,
    repurchases.account_id,
    repurchases.order_date,
    repurchases.previous_order_date,
    repurchases.days_since_previous_order,
    repurchases.days_since_previous_order_bucket,
    repurchases.repeat_purchase_total_price,
        CASE
            WHEN (repurchases.days_since_previous_order_bucket < 30) THEN concat(lpad(((repurchases.days_since_previous_order_bucket)::character varying)::text, 2, '0'::text), ': ', ((repurchases.days_since_previous_order_bucket - 1) * 20), ' - ', ((repurchases.days_since_previous_order_bucket * 20) - 1), ' days')
            ELSE '30: 580+ days'::text
        END AS days_since_previous_order_bucket_label
   FROM repurchases;


--
-- Name: stg_shopify_refund_items; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.stg_shopify_refund_items AS
 SELECT orders__refunds__refund_line_items.id AS refund_line_item_id,
    orders__refunds__refund_line_items._sdc_source_key_id AS refund_id,
    orders__refunds__refund_line_items.line_item_id,
    (orders__refunds__refund_line_items.subtotal * ('-1'::integer)::double precision) AS refund_amount,
    (orders__refunds__refund_line_items.total_tax * ('-1'::integer)::double precision) AS refund_tax_amount
   FROM raw_tap_shopify.orders__refunds__refund_line_items;


--
-- Name: stg_shopify_refunds; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.stg_shopify_refunds AS
 WITH refunds AS (
         SELECT orders__refunds.admin_graphql_api_id,
            orders__refunds.restock,
            orders__refunds.note,
            orders__refunds.id,
            orders__refunds.user_id,
            orders__refunds.created_at,
            orders__refunds.processed_at,
            orders__refunds._sdc_source_key_id,
            orders__refunds._sdc_sequence,
            orders__refunds._sdc_level_0_id
           FROM raw_tap_shopify.orders__refunds
        ), adjustments AS (
         SELECT orders__refunds__order_adjustments.order_id,
            orders__refunds__order_adjustments.tax_amount,
            orders__refunds__order_adjustments.refund_id,
            orders__refunds__order_adjustments.amount,
            orders__refunds__order_adjustments.kind,
            orders__refunds__order_adjustments.id,
            orders__refunds__order_adjustments.reason,
            orders__refunds__order_adjustments._sdc_source_key_id,
            orders__refunds__order_adjustments._sdc_sequence,
            orders__refunds__order_adjustments._sdc_level_0_id,
            orders__refunds__order_adjustments._sdc_level_1_id
           FROM raw_tap_shopify.orders__refunds__order_adjustments
        ), item_refunds AS (
         SELECT stg_shopify_refund_items.refund_id,
            sum(stg_shopify_refund_items.refund_amount) AS refund_amount,
            sum(stg_shopify_refund_items.refund_tax_amount) AS refund_tax_amount
           FROM warehouse.stg_shopify_refund_items
          GROUP BY stg_shopify_refund_items.refund_id
        ), joined AS (
         SELECT adjustments.order_id,
            adjustments.tax_amount,
            adjustments.refund_id,
            adjustments.amount,
            adjustments.kind,
            adjustments.id,
            adjustments.reason,
            adjustments._sdc_source_key_id,
            adjustments._sdc_sequence,
            adjustments._sdc_level_0_id,
            adjustments._sdc_level_1_id,
            (refunds.processed_at)::timestamp without time zone AS processed_at
           FROM (adjustments
             LEFT JOIN refunds ON ((refunds.id = adjustments.refund_id)))
        ), adjustments_flattened AS (
         SELECT DISTINCT joined.refund_id,
            joined._sdc_source_key_id AS order_id,
            sum(
                CASE
                    WHEN (joined.reason ~~* '%ship%'::text) THEN joined.amount
                    ELSE (0)::double precision
                END) OVER (PARTITION BY joined.refund_id ORDER BY joined.processed_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS refund_shipping_amount,
            sum(
                CASE
                    WHEN (joined.reason ~~* '%refund discrepancy%'::text) THEN joined.amount
                    ELSE (0)::double precision
                END) OVER (PARTITION BY joined.refund_id ORDER BY joined.processed_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS adjustment_refund_amount,
            sum(joined.tax_amount) OVER (PARTITION BY joined.refund_id ORDER BY joined.processed_at ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS refund_tax_amount,
            joined.processed_at AS refund_processed_at
           FROM joined
        ), final AS (
         SELECT adjustments_flattened.refund_id,
            adjustments_flattened.order_id,
            (COALESCE(adjustments_flattened.adjustment_refund_amount, (0)::double precision) + COALESCE(item_refunds.refund_amount, (0)::double precision)) AS refund_amount,
            (COALESCE(adjustments_flattened.refund_tax_amount, (0)::double precision) + COALESCE(item_refunds.refund_tax_amount, (0)::double precision)) AS refund_tax_amount,
            COALESCE(adjustments_flattened.refund_shipping_amount, (0)::double precision) AS refund_shipping_amount,
            adjustments_flattened.refund_processed_at
           FROM (adjustments_flattened
             LEFT JOIN item_refunds USING (refund_id))
        )
 SELECT final.refund_id,
    final.order_id,
    final.refund_amount,
    final.refund_tax_amount,
    final.refund_shipping_amount,
    final.refund_processed_at
   FROM final;


--
-- Name: fct_shopify_sales_daily_summary; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.fct_shopify_sales_daily_summary AS
 WITH orders AS (
         SELECT (fct_shopify_orders.created_at)::date AS date_day,
            count(*) AS total_orders,
            sum(fct_shopify_orders.total_line_items_price) AS total_gross_revenue,
            sum(fct_shopify_orders.final_discounts) AS total_discounts,
            sum(fct_shopify_orders.final_shipping_cost) AS total_shipping_cost,
            sum(fct_shopify_orders.total_tax) AS total_tax
           FROM warehouse.fct_shopify_orders
          GROUP BY ((fct_shopify_orders.created_at)::date)
        ), refunds AS (
         SELECT (stg_shopify_refunds.refund_processed_at)::date AS date_day,
            sum(stg_shopify_refunds.refund_amount) AS total_refund_amount,
            sum(stg_shopify_refunds.refund_tax_amount) AS total_refund_tax_amount,
            sum(stg_shopify_refunds.refund_shipping_amount) AS total_refund_shipping_amount
           FROM warehouse.stg_shopify_refunds
          GROUP BY ((stg_shopify_refunds.refund_processed_at)::date)
        ), calculated AS (
         SELECT md5(((concat(COALESCE((orders.date_day)::character varying, ''::character varying)))::character varying)::text) AS id,
            orders.date_day,
            orders.total_orders,
            orders.total_gross_revenue,
            orders.total_discounts,
            COALESCE(refunds.total_refund_amount, (0)::double precision) AS total_refund_amount,
            (COALESCE(refunds.total_refund_shipping_amount, (0)::double precision) + COALESCE(orders.total_shipping_cost, (0)::double precision)) AS total_shipping_costs,
            (COALESCE(refunds.total_refund_tax_amount, (0)::double precision) + COALESCE(orders.total_tax, (0)::double precision)) AS total_tax,
            ((COALESCE(orders.total_gross_revenue, (0)::double precision) + COALESCE(orders.total_discounts, (0)::double precision)) + COALESCE(refunds.total_refund_amount, (0)::double precision)) AS total_net_sales,
            ((((((COALESCE(orders.total_gross_revenue, (0)::double precision) + COALESCE(refunds.total_refund_amount, (0)::double precision)) + COALESCE(orders.total_discounts, (0)::double precision)) + COALESCE(refunds.total_refund_shipping_amount, (0)::double precision)) + COALESCE(orders.total_shipping_cost, (0)::double precision)) + COALESCE(refunds.total_refund_tax_amount, (0)::double precision)) + COALESCE(orders.total_tax, (0)::double precision)) AS total_sales
           FROM (orders
             LEFT JOIN refunds USING (date_day))
        )
 SELECT calculated.id,
    calculated.date_day,
    calculated.total_orders,
    calculated.total_gross_revenue,
    calculated.total_discounts,
    calculated.total_refund_amount,
    calculated.total_shipping_costs,
    calculated.total_tax,
    calculated.total_net_sales,
    calculated.total_sales
   FROM calculated;


--
-- Name: fct_snowplow_page_views; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.fct_snowplow_page_views (
    account_id bigint,
    user_custom_id text,
    user_snowplow_domain_id text,
    user_snowplow_crossdomain_id text,
    min_tstamp timestamp with time zone,
    max_tstamp timestamp with time zone,
    session_id text,
    session_index bigint,
    page_view_id text,
    page_view_index bigint,
    page_view_in_session_index bigint,
    max_session_page_view_index bigint,
    page_view_start timestamp with time zone,
    page_view_end timestamp with time zone,
    page_view_start_local timestamp with time zone,
    page_view_end_local timestamp with time zone,
    time_engaged_in_s bigint,
    time_engaged_in_s_tier text,
    horizontal_pixels_scrolled bigint,
    vertical_pixels_scrolled bigint,
    horizontal_percentage_scrolled double precision,
    vertical_percentage_scrolled double precision,
    vertical_percentage_scrolled_tier text,
    user_engaged boolean,
    page_url text,
    page_url_scheme text,
    page_url_host text,
    page_url_port bigint,
    page_url_path text,
    page_url_query text,
    page_url_fragment text,
    page_title text,
    page_width bigint,
    page_height bigint,
    referrer_url text,
    referrer_url_scheme text,
    referrer_url_host text,
    referrer_url_port bigint,
    referrer_url_path text,
    referrer_url_query text,
    referrer_url_fragment text,
    referrer_medium text,
    referrer_source text,
    referrer_term text,
    marketing_medium text,
    marketing_source text,
    marketing_term text,
    marketing_content text,
    marketing_campaign text,
    marketing_click_id text,
    marketing_network text,
    geo_country text,
    geo_region text,
    geo_region_name text,
    geo_city text,
    geo_zipcode text,
    geo_latitude double precision,
    geo_longitude double precision,
    geo_timezone text,
    ip_address text,
    ip_isp text,
    ip_organization text,
    ip_domain text,
    ip_net_speed text,
    app_id text,
    browser text,
    browser_name text,
    browser_major_version text,
    browser_minor_version text,
    browser_build_version text,
    os text,
    os_name text,
    os_major_version text,
    os_minor_version text,
    os_build_version text,
    device text,
    browser_window_width bigint,
    browser_window_height bigint,
    browser_language text,
    os_manufacturer text,
    os_timezone text,
    redirect_time_in_ms double precision,
    unload_time_in_ms double precision,
    app_cache_time_in_ms double precision,
    dns_time_in_ms double precision,
    tcp_time_in_ms double precision,
    request_time_in_ms double precision,
    response_time_in_ms double precision,
    processing_time_in_ms double precision,
    dom_loading_to_interactive_time_in_ms double precision,
    dom_interactive_to_complete_time_in_ms double precision,
    onload_time_in_ms double precision,
    total_time_in_ms double precision,
    browser_engine text,
    device_type text,
    device_is_mobile boolean,
    is_internal boolean,
    is_shopify boolean,
    shopify_area text,
    ecommerce_function text,
    last_page_view_in_session integer
);


--
-- Name: fct_snowplow_sessions; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.fct_snowplow_sessions (
    account_id bigint,
    user_custom_id text,
    inferred_user_id text,
    user_snowplow_domain_id text,
    user_snowplow_crossdomain_id text,
    app_id text,
    browser text,
    browser_build_version text,
    browser_engine text,
    browser_language text,
    browser_major_version text,
    browser_minor_version text,
    browser_name text,
    device text,
    device_is_mobile boolean,
    device_type text,
    first_page_title text,
    first_page_url text,
    first_page_url_fragment text,
    first_page_url_host text,
    first_page_url_path text,
    first_page_url_port bigint,
    first_page_url_query text,
    first_page_url_scheme text,
    exit_page_url text,
    geo_city text,
    geo_country text,
    geo_latitude double precision,
    geo_longitude double precision,
    geo_region text,
    geo_region_name text,
    geo_timezone text,
    geo_zipcode text,
    ip_address text,
    ip_domain text,
    ip_isp text,
    ip_net_speed text,
    ip_organization text,
    marketing_campaign text,
    marketing_click_id text,
    marketing_content text,
    marketing_medium text,
    marketing_network text,
    marketing_source text,
    marketing_term text,
    os text,
    os_build_version text,
    os_major_version text,
    os_manufacturer text,
    os_minor_version text,
    os_name text,
    os_timezone text,
    page_views bigint,
    referrer_medium text,
    referrer_source text,
    referrer_term text,
    referrer_url text,
    referrer_url_fragment text,
    referrer_url_host text,
    referrer_url_path text,
    referrer_url_port bigint,
    referrer_url_query text,
    referrer_url_scheme text,
    session_start timestamp with time zone,
    session_start_local timestamp with time zone,
    session_end timestamp with time zone,
    session_end_local timestamp with time zone,
    session_id text,
    session_cookie_index bigint,
    time_engaged_in_s numeric,
    time_engaged_in_s_tier text,
    user_bounced boolean,
    session_index bigint
);


--
-- Name: stg_shopify_customers; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.stg_shopify_customers AS
 WITH raw_customers AS (
         SELECT customers.last_order_name,
            customers.currency,
            customers.email,
            customers.multipass_identifier,
            customers.default_address__city,
            customers.default_address__address1,
            customers.default_address__zip,
            customers.default_address__id,
            customers.default_address__country_name,
            customers.default_address__province,
            customers.default_address__phone,
            customers.default_address__country,
            customers.default_address__first_name,
            customers.default_address__customer_id,
            customers.default_address__default,
            customers.default_address__last_name,
            customers.default_address__country_code,
            customers.default_address__name,
            customers.default_address__province_code,
            customers.default_address__address2,
            customers.default_address__company,
            customers.orders_count,
            customers.state,
            customers.verified_email,
            customers.total_spent,
            customers.last_order_id,
            customers.first_name,
            customers.updated_at,
            customers.note,
            customers.phone,
            customers.admin_graphql_api_id,
            customers.last_name,
            customers.tags,
            customers.tax_exempt,
            customers.id,
            customers.accepts_marketing,
            customers.created_at,
            customers.account_id,
            customers.shop_id,
            customers._sdc_received_at,
            customers._sdc_sequence,
            customers._sdc_table_version,
            customers._sdc_batched_at
           FROM raw_tap_shopify.customers
        ), trimmed_tags AS (
         SELECT t.id,
            array_agg(btrim(t.tag)) AS tags
           FROM ( SELECT raw_customers_1.id,
                    row_number() OVER () AS rn,
                    unnest(string_to_array(raw_customers_1.tags, ', '::text)) AS tag
                   FROM raw_customers raw_customers_1) t
          GROUP BY t.id, t.rn
        )
 SELECT raw_customers.id AS customer_id,
    raw_customers.account_id,
    NULLIF(lower(raw_customers.email), ''::text) AS email,
    raw_customers.verified_email,
    NULLIF(raw_customers.first_name, ''::text) AS first_name,
    NULLIF(raw_customers.last_name, ''::text) AS last_name,
    raw_customers.accepts_marketing,
    raw_customers.state,
    raw_customers.tax_exempt,
    trimmed_tags.tags,
    raw_customers.default_address__id AS default_address_id,
    raw_customers.created_at,
    raw_customers.updated_at
   FROM (raw_customers
     LEFT JOIN trimmed_tags ON ((trimmed_tags.id = raw_customers.id)));


--
-- Name: stg_shopify_business_lines; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.stg_shopify_business_lines AS
 WITH customers AS (
         SELECT stg_shopify_customers.customer_id,
            stg_shopify_customers.account_id,
            stg_shopify_customers.email,
            stg_shopify_customers.verified_email,
            stg_shopify_customers.first_name,
            stg_shopify_customers.last_name,
            stg_shopify_customers.accepts_marketing,
            stg_shopify_customers.state,
            stg_shopify_customers.tax_exempt,
            stg_shopify_customers.tags,
            stg_shopify_customers.default_address_id,
            stg_shopify_customers.created_at,
            stg_shopify_customers.updated_at
           FROM warehouse.stg_shopify_customers
        )
 SELECT customers.customer_id,
    customers.account_id,
        CASE
            WHEN ((customers.tags @> ARRAY['wholesale'::text]) OR (customers.tags @> ARRAY['Wholesale'::text])) THEN 'Wholesale'::text
            ELSE 'Direct to Consumer'::text
        END AS business_line
   FROM customers;


--
-- Name: stg_shopify_checkouts; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.stg_shopify_checkouts AS
 SELECT abandoned_checkouts.account_id,
    abandoned_checkouts.shop_id,
    abandoned_checkouts.id AS checkout_id,
    abandoned_checkouts.customer__id AS customer_id,
    NULLIF(lower(abandoned_checkouts.email), ''::text) AS email,
    NULLIF(abandoned_checkouts.cart_token, ''::text) AS cart_token,
    NULLIF(abandoned_checkouts.token, ''::text) AS token,
    abandoned_checkouts.abandoned_checkout_url,
    abandoned_checkouts.name,
    abandoned_checkouts.currency,
    abandoned_checkouts.gateway,
    abandoned_checkouts.landing_site,
    abandoned_checkouts.source_name,
    abandoned_checkouts.referring_site,
    abandoned_checkouts.subtotal_price,
    abandoned_checkouts.taxes_included,
    abandoned_checkouts.total_discounts,
    abandoned_checkouts.total_line_items_price,
    abandoned_checkouts.total_price,
    abandoned_checkouts.total_tax,
    abandoned_checkouts.total_weight,
    (abandoned_checkouts.billing_address__city)::character varying(256) AS billing_city,
    (abandoned_checkouts.billing_address__province)::character varying(256) AS billing_province,
    (abandoned_checkouts.billing_address__province_code)::character varying(256) AS billing_province_code,
    (abandoned_checkouts.billing_address__country)::character varying(256) AS billing_country,
    (abandoned_checkouts.billing_address__country_code)::character varying(256) AS billing_country_code,
    (abandoned_checkouts.billing_address__zip)::character varying(256) AS billing_zip_code,
    (abandoned_checkouts.billing_address__address1)::character varying(256) AS billing_address_address1,
    (abandoned_checkouts.billing_address__address2)::character varying(256) AS billing_address_address2,
    (abandoned_checkouts.billing_address__company)::character varying(256) AS billing_company,
    (abandoned_checkouts.billing_address__first_name)::character varying(256) AS billing_first_name,
    (abandoned_checkouts.billing_address__last_name)::character varying(256) AS billing_last_name,
    (abandoned_checkouts.billing_address__latitude)::bigint AS billing_latitude,
    (abandoned_checkouts.billing_address__longitude)::bigint AS billing_longitude,
    (abandoned_checkouts.billing_address__name)::character varying(256) AS billing_name,
    (abandoned_checkouts.billing_address__phone)::character varying(256) AS billing_phone,
    (abandoned_checkouts.shipping_address__city)::character varying(256) AS shipping_city,
    (abandoned_checkouts.shipping_address__province)::character varying(256) AS shipping_province,
    (abandoned_checkouts.shipping_address__province_code)::character varying(256) AS shipping_province_code,
    (abandoned_checkouts.shipping_address__country)::character varying(256) AS shipping_country,
    (abandoned_checkouts.shipping_address__country_code)::character varying(256) AS shipping_country_code,
    (abandoned_checkouts.shipping_address__zip)::character varying(256) AS shipping_zip_code,
    (abandoned_checkouts.shipping_address__address1)::character varying(256) AS shipping_address_address1,
    (abandoned_checkouts.shipping_address__address2)::character varying(256) AS shipping_address_address2,
    (abandoned_checkouts.shipping_address__company)::character varying(256) AS shipping_company,
    (abandoned_checkouts.shipping_address__first_name)::character varying(256) AS shipping_first_name,
    (abandoned_checkouts.shipping_address__last_name)::character varying(256) AS shipping_last_name,
    (abandoned_checkouts.shipping_address__latitude)::bigint AS shipping_latitude,
    (abandoned_checkouts.shipping_address__longitude)::bigint AS shipping_longitude,
    (abandoned_checkouts.shipping_address__name)::character varying(256) AS shipping_name,
    (abandoned_checkouts.shipping_address__phone)::character varying(256) AS shipping_phone,
    abandoned_checkouts.completed_at,
    abandoned_checkouts.created_at,
    abandoned_checkouts.updated_at
   FROM raw_tap_shopify.abandoned_checkouts;


--
-- Name: stg_shopify_customer_order_aggregates; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.stg_shopify_customer_order_aggregates (
    customer_id bigint,
    account_id bigint,
    total_order_count bigint,
    total_successful_order_count bigint,
    total_cancelled_order_count bigint,
    total_spend double precision,
    previous_1_month_spend double precision,
    previous_3_month_spend double precision,
    previous_6_month_spend double precision,
    previous_12_month_spend double precision,
    most_recent_order_id bigint,
    most_recent_order_number bigint,
    most_recent_order_at timestamp with time zone,
    most_recent_order_total_price double precision,
    first_order_id bigint,
    first_order_number bigint,
    first_order_at timestamp with time zone,
    first_order_total_price double precision
);


--
-- Name: stg_shopify_customer_rfm; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.stg_shopify_customer_rfm (
    customer_id bigint,
    account_id bigint,
    total_order_count bigint,
    total_spend double precision,
    days_since_last_order double precision,
    recency_quintile integer,
    frequency_quintile integer,
    monetary_quintile integer,
    rfm_score text,
    rfm_label text,
    rfm_desirability_score integer,
    rfm_value_label text
);


--
-- Name: stg_shopify_customer_rolling_rfm; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.stg_shopify_customer_rolling_rfm (
    customer_id bigint,
    week timestamp with time zone,
    account_id bigint,
    total_order_count bigint,
    total_spend double precision,
    frequency_quintile integer,
    monetary_quintile integer,
    previous_order_date timestamp with time zone,
    days_since_last_order double precision,
    recency_quintile integer,
    rfm_score text,
    rfm_label text,
    rfm_desirability_score integer,
    rfm_value_label text
);


--
-- Name: stg_shopify_discount_codes; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.stg_shopify_discount_codes AS
 SELECT orders__discount_codes._sdc_source_key_id AS order_id,
    orders__discount_codes.code,
    (orders__discount_codes.amount * ('-1'::integer)::double precision) AS amount,
    orders__discount_codes.type
   FROM raw_tap_shopify.orders__discount_codes;


--
-- Name: stg_shopify_order_items; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.stg_shopify_order_items AS
 SELECT orders__line_items.id__i AS order_item_id,
    orders__line_items._sdc_source_key_id AS order_id,
    orders__line_items._sdc_level_0_id AS item_id,
    orders__line_items.product_id,
    orders__line_items.sku,
    orders__line_items.name,
    orders__line_items.title,
    orders__line_items.vendor,
    orders__line_items.quantity,
    orders__line_items.pre_tax_price,
    orders__line_items.price,
    orders__line_items.taxable,
    orders__line_items.gift_card,
    orders__line_items.total_discount,
    orders__line_items.grams,
    orders__line_items.fulfillable_quantity,
    orders__line_items.fulfillment_service,
    orders__line_items.fulfillment_status,
    orders__line_items.product_exists,
    orders__line_items.requires_shipping,
    orders__line_items.variant_id,
    orders__line_items.variant_inventory_management,
    orders__line_items.variant_title
   FROM raw_tap_shopify.orders__line_items;


--
-- Name: stg_shopify_product_variants; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.stg_shopify_product_variants AS
 SELECT products__variants.id AS variant_id,
    products__variants._sdc_source_key_id AS product_id,
    products__variants.inventory_item_id,
    products__variants.barcode,
    products__variants.fulfillment_service,
    products__variants.grams,
    products__variants.inventory_policy,
    products__variants.inventory_quantity,
    products__variants.inventory_management,
    products__variants."position",
    products__variants.price,
    products__variants.requires_shipping,
    products__variants.sku,
    products__variants.taxable,
    products__variants.title,
    products__variants.weight,
    products__variants.weight_unit,
    products__variants.created_at,
    products__variants.updated_at
   FROM raw_tap_shopify.products__variants;


--
-- Name: stg_shopify_products; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.stg_shopify_products AS
 SELECT products.id AS product_id,
    NULLIF(lower(products.product_type), ''::text) AS product_type,
    NULLIF(lower(products.title), ''::text) AS title,
    products.handle,
    products.published_scope,
    products.tags,
    products.vendor,
    products.body_html,
    (products.image__src)::character varying(256) AS image_url,
    products.published_at,
    products.created_at,
    products.updated_at
   FROM raw_tap_shopify.products;


--
-- Name: stg_shopify_transactions; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.stg_shopify_transactions AS
 SELECT transactions.account_id,
    transactions.shop_id,
    transactions.id AS transaction_id,
    transactions.parent_id,
    transactions.order_id,
    transactions.status,
    transactions.error_code,
    transactions.message,
    transactions.kind,
    transactions.amount,
    'authorization'::text AS transaction_authorization,
    transactions.currency,
    transactions.gateway,
    transactions.source_name,
    transactions.created_at
   FROM raw_tap_shopify.transactions
  WHERE (transactions.test = false);


--
-- Name: stg_snowplow_enrichment_errors; Type: VIEW; Schema: warehouse; Owner: -
--

CREATE VIEW warehouse.stg_snowplow_enrichment_errors AS
 WITH __dbt__cte__base_snowplow_enrichment_errors AS (
         SELECT snowplow_production_enriched_bad.line,
            snowplow_production_enriched_bad.failure_tstamp,
            snowplow_production_enriched_bad._sdc_received_at,
            snowplow_production_enriched_bad._sdc_sequence,
            snowplow_production_enriched_bad._sdc_table_version,
            snowplow_production_enriched_bad._sdc_batched_at,
            snowplow_production_enriched_bad._sdc_primary_key
           FROM raw_tap_kafka.snowplow_production_enriched_bad
        ), __dbt__cte__base_snowplow_enrichment_error_messages AS (
         SELECT snowplow_production_enriched_bad__errors.level,
            snowplow_production_enriched_bad__errors.message,
            snowplow_production_enriched_bad__errors._sdc_source_key__sdc_primary_key,
            snowplow_production_enriched_bad__errors._sdc_sequence,
            snowplow_production_enriched_bad__errors._sdc_level_0_id
           FROM raw_tap_kafka.snowplow_production_enriched_bad__errors
        ), errors AS (
         SELECT __dbt__cte__base_snowplow_enrichment_errors.line,
            __dbt__cte__base_snowplow_enrichment_errors.failure_tstamp,
            __dbt__cte__base_snowplow_enrichment_errors._sdc_received_at,
            __dbt__cte__base_snowplow_enrichment_errors._sdc_sequence,
            __dbt__cte__base_snowplow_enrichment_errors._sdc_table_version,
            __dbt__cte__base_snowplow_enrichment_errors._sdc_batched_at,
            __dbt__cte__base_snowplow_enrichment_errors._sdc_primary_key
           FROM __dbt__cte__base_snowplow_enrichment_errors
        ), error_messages AS (
         SELECT __dbt__cte__base_snowplow_enrichment_error_messages._sdc_source_key__sdc_primary_key,
            array_agg(__dbt__cte__base_snowplow_enrichment_error_messages.message) AS messages
           FROM __dbt__cte__base_snowplow_enrichment_error_messages
          GROUP BY __dbt__cte__base_snowplow_enrichment_error_messages._sdc_source_key__sdc_primary_key
        ), joined AS (
         SELECT errors.line,
            errors.failure_tstamp,
            errors._sdc_received_at,
            errors._sdc_sequence,
            errors._sdc_table_version,
            errors._sdc_batched_at,
            errors._sdc_primary_key,
            error_messages.messages
           FROM (errors
             LEFT JOIN error_messages ON ((error_messages._sdc_source_key__sdc_primary_key = errors._sdc_primary_key)))
        )
 SELECT joined.line,
    joined.failure_tstamp,
    joined._sdc_received_at,
    joined._sdc_sequence,
    joined._sdc_table_version,
    joined._sdc_batched_at,
    joined._sdc_primary_key,
    joined.messages
   FROM joined;


--
-- Name: stg_snowplow_id_map; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.stg_snowplow_id_map (
    domain_userid text,
    user_id text,
    max_tstamp timestamp with time zone,
    idx bigint
);


--
-- Name: stg_snowplow_page_views; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.stg_snowplow_page_views (
    user_custom_id text,
    user_snowplow_domain_id text,
    user_snowplow_crossdomain_id text,
    min_tstamp timestamp with time zone,
    max_tstamp timestamp with time zone,
    session_id text,
    session_index bigint,
    page_view_id text,
    page_view_index bigint,
    page_view_in_session_index bigint,
    max_session_page_view_index bigint,
    page_view_start timestamp with time zone,
    page_view_end timestamp with time zone,
    page_view_start_local timestamp with time zone,
    page_view_end_local timestamp with time zone,
    time_engaged_in_s bigint,
    time_engaged_in_s_tier text,
    horizontal_pixels_scrolled bigint,
    vertical_pixels_scrolled bigint,
    horizontal_percentage_scrolled double precision,
    vertical_percentage_scrolled double precision,
    vertical_percentage_scrolled_tier text,
    user_engaged boolean,
    page_url text,
    page_url_scheme text,
    page_url_host text,
    page_url_port bigint,
    page_url_path text,
    page_url_query text,
    page_url_fragment text,
    page_title text,
    page_width bigint,
    page_height bigint,
    referer_url text,
    referer_url_scheme text,
    referer_url_host text,
    referer_url_port bigint,
    referer_url_path text,
    referer_url_query text,
    referer_url_fragment text,
    referer_medium text,
    referer_source text,
    referer_term text,
    marketing_medium text,
    marketing_source text,
    marketing_term text,
    marketing_content text,
    marketing_campaign text,
    marketing_click_id text,
    marketing_network text,
    geo_country text,
    geo_region text,
    geo_region_name text,
    geo_city text,
    geo_zipcode text,
    geo_latitude double precision,
    geo_longitude double precision,
    geo_timezone text,
    ip_address text,
    ip_isp text,
    ip_organization text,
    ip_domain text,
    ip_net_speed text,
    app_id text,
    browser text,
    browser_name text,
    browser_major_version text,
    browser_minor_version text,
    browser_build_version text,
    os text,
    os_name text,
    os_major_version text,
    os_minor_version text,
    os_build_version text,
    device text,
    browser_window_width bigint,
    browser_window_height bigint,
    browser_language text,
    os_manufacturer text,
    os_timezone text,
    redirect_time_in_ms double precision,
    unload_time_in_ms double precision,
    app_cache_time_in_ms double precision,
    dns_time_in_ms double precision,
    tcp_time_in_ms double precision,
    request_time_in_ms double precision,
    response_time_in_ms double precision,
    processing_time_in_ms double precision,
    dom_loading_to_interactive_time_in_ms double precision,
    dom_interactive_to_complete_time_in_ms double precision,
    onload_time_in_ms double precision,
    total_time_in_ms double precision,
    browser_engine text,
    device_type text,
    device_is_mobile boolean,
    is_internal boolean,
    last_page_view_in_session integer
);


--
-- Name: stg_snowplow_sessions_tmp; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.stg_snowplow_sessions_tmp (
    account_id bigint,
    user_custom_id text,
    user_snowplow_domain_id text,
    user_snowplow_crossdomain_id text,
    session_id text,
    session_index bigint,
    session_start timestamp with time zone,
    session_end timestamp with time zone,
    session_start_local timestamp with time zone,
    session_end_local timestamp with time zone,
    page_views bigint,
    engaged_page_views bigint,
    time_engaged_in_s numeric,
    time_engaged_in_s_tier text,
    user_bounced boolean,
    user_engaged boolean,
    first_page_url text,
    first_page_url_scheme text,
    first_page_url_host text,
    first_page_url_port bigint,
    first_page_url_path text,
    first_page_url_query text,
    first_page_url_fragment text,
    first_page_title text,
    exit_page_url text,
    referrer_url text,
    referrer_url_scheme text,
    referrer_url_host text,
    referrer_url_port bigint,
    referrer_url_path text,
    referrer_url_query text,
    referrer_url_fragment text,
    referrer_medium text,
    referrer_source text,
    referrer_term text,
    marketing_medium text,
    marketing_source text,
    marketing_term text,
    marketing_content text,
    marketing_campaign text,
    marketing_click_id text,
    marketing_network text,
    geo_country text,
    geo_region text,
    geo_region_name text,
    geo_city text,
    geo_zipcode text,
    geo_latitude double precision,
    geo_longitude double precision,
    geo_timezone text,
    ip_address text,
    ip_isp text,
    ip_organization text,
    ip_domain text,
    ip_net_speed text,
    app_id text,
    browser text,
    browser_name text,
    browser_major_version text,
    browser_minor_version text,
    browser_build_version text,
    browser_engine text,
    browser_language text,
    os text,
    os_name text,
    os_major_version text,
    os_minor_version text,
    os_build_version text,
    os_manufacturer text,
    os_timezone text,
    device text,
    device_type text,
    device_is_mobile boolean
);


--
-- Name: stg_snowplow_web_events; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.stg_snowplow_web_events (
    account_id bigint,
    event_id text,
    user_id text,
    domain_userid text,
    network_userid text,
    collector_tstamp timestamp with time zone,
    domain_sessionid text,
    domain_sessionidx bigint,
    page_view_id text,
    page_title text,
    page_urlscheme text,
    page_urlhost text,
    page_urlport bigint,
    page_urlpath text,
    page_urlquery text,
    page_urlfragment text,
    refr_urlscheme text,
    refr_urlhost text,
    refr_urlport bigint,
    refr_urlpath text,
    refr_urlquery text,
    refr_urlfragment text,
    refr_medium text,
    refr_source text,
    refr_term text,
    mkt_medium text,
    mkt_source text,
    mkt_term text,
    mkt_content text,
    mkt_campaign text,
    mkt_clickid text,
    mkt_network text,
    geo_country text,
    geo_region text,
    geo_region_name text,
    geo_city text,
    geo_zipcode text,
    geo_latitude double precision,
    geo_longitude double precision,
    geo_timezone text,
    user_ipaddress text,
    ip_isp text,
    ip_organization text,
    ip_domain text,
    ip_netspeed text,
    app_id text,
    useragent text,
    br_name text,
    br_family text,
    br_version text,
    br_type text,
    br_renderengine text,
    br_lang text,
    dvce_type text,
    dvce_ismobile boolean,
    os_name text,
    os_family text,
    os_manufacturer text,
    os_timezone text,
    name_tracker text,
    dvce_created_tstamp timestamp with time zone,
    _sdc_primary_key text,
    n bigint
);


--
-- Name: stg_snowplow_web_events_scroll_depth; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.stg_snowplow_web_events_scroll_depth (
    page_view_id text,
    max_tstamp timestamp with time zone,
    doc_width bigint,
    doc_height bigint,
    br_viewwidth bigint,
    br_viewheight bigint,
    hmin bigint,
    hmax bigint,
    vmin bigint,
    vmax bigint,
    relative_hmin double precision,
    relative_hmax double precision,
    relative_vmin double precision,
    relative_vmax double precision
);


--
-- Name: stg_snowplow_web_events_time; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.stg_snowplow_web_events_time (
    page_view_id text,
    min_tstamp timestamp with time zone,
    max_tstamp timestamp with time zone,
    pv_count bigint,
    pp_count bigint,
    time_engaged_in_s bigint
);


--
-- Name: stg_snowplow_web_performance_timing_context; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.stg_snowplow_web_performance_timing_context (
    page_view_id text,
    redirect_time_in_ms double precision,
    unload_time_in_ms double precision,
    app_cache_time_in_ms double precision,
    dns_time_in_ms double precision,
    tcp_time_in_ms double precision,
    request_time_in_ms double precision,
    response_time_in_ms double precision,
    processing_time_in_ms double precision,
    dom_loading_to_interactive_time_in_ms double precision,
    dom_interactive_to_complete_time_in_ms double precision,
    onload_time_in_ms double precision,
    total_time_in_ms double precision
);


--
-- Name: stg_snowplow_web_ua_parser_context; Type: TABLE; Schema: warehouse; Owner: -
--

CREATE TABLE warehouse.stg_snowplow_web_ua_parser_context (
    page_view_id text,
    useragent_family text,
    useragent_major text,
    useragent_minor text,
    useragent_patch text,
    useragent_version text,
    os_family text,
    os_major text,
    os_minor text,
    os_patch text,
    os_patch_minor text,
    os_version text,
    device_family text
);


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
-- Name: connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections ALTER COLUMN id SET DEFAULT nextval('public.connections_id_seq'::regclass);


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
-- Name: que_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.que_jobs ALTER COLUMN id SET DEFAULT nextval('public.que_jobs_id_seq'::regclass);


--
-- Name: shopify_shops id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopify_shops ALTER COLUMN id SET DEFAULT nextval('public.shopify_shops_id_seq'::regclass);


--
-- Name: singer_global_sync_attempts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_global_sync_attempts ALTER COLUMN id SET DEFAULT nextval('public.singer_global_sync_attempts_id_seq'::regclass);


--
-- Name: singer_global_sync_states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_global_sync_states ALTER COLUMN id SET DEFAULT nextval('public.singer_global_sync_states_id_seq'::regclass);


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
-- Name: connections connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connections
    ADD CONSTRAINT connections_pkey PRIMARY KEY (id);


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
-- Name: shopify_shops shopify_shops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopify_shops
    ADD CONSTRAINT shopify_shops_pkey PRIMARY KEY (id);


--
-- Name: singer_global_sync_attempts singer_global_sync_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_global_sync_attempts
    ADD CONSTRAINT singer_global_sync_attempts_pkey PRIMARY KEY (id);


--
-- Name: singer_global_sync_states singer_global_sync_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_global_sync_states
    ADD CONSTRAINT singer_global_sync_states_pkey PRIMARY KEY (id);


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
-- Name: dim_shopify_customers__index_on_customer_id; Type: INDEX; Schema: dbt_harry; Owner: -
--

CREATE INDEX dim_shopify_customers__index_on_customer_id ON dbt_harry.dim_shopify_customers USING btree (customer_id);


--
-- Name: fct_shopify_orders__index_on_customer_id; Type: INDEX; Schema: dbt_harry; Owner: -
--

CREATE INDEX fct_shopify_orders__index_on_customer_id ON dbt_harry.fct_shopify_orders USING btree (customer_id);


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
-- Name: tp_7cf5ac0c7c8b960afb4e37906bdd24ffc61c672f; Type: INDEX; Schema: raw_tap_google_analytics; Owner: -
--

CREATE INDEX tp_7cf5ac0c7c8b960afb4e37906bdd24ffc61c672f ON raw_tap_google_analytics.traffic_sources USING btree (ga_date, ga_source, ga_medium, ga_socialnetwork, _sdc_sequence);


--
-- Name: tp_8cfc1e515522600e54e5abde3cb2fbe9ab53c22a; Type: INDEX; Schema: raw_tap_google_analytics; Owner: -
--

CREATE INDEX tp_8cfc1e515522600e54e5abde3cb2fbe9ab53c22a ON raw_tap_google_analytics.locations USING btree (ga_date, ga_continent, ga_subcontinent, ga_country, ga_region, ga_metro, ga_city, _sdc_sequence);


--
-- Name: tp_c6f626f0dc64eb3e6d7c1628a57d7963e72cf547; Type: INDEX; Schema: raw_tap_google_analytics; Owner: -
--

CREATE INDEX tp_c6f626f0dc64eb3e6d7c1628a57d7963e72cf547 ON raw_tap_google_analytics.devices USING btree (ga_date, ga_devicecategory, ga_operatingsystem, ga_browser, _sdc_sequence);


--
-- Name: tp_daily_active_users_ga_date__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_google_analytics; Owner: -
--

CREATE INDEX tp_daily_active_users_ga_date__sdc_sequence_idx ON raw_tap_google_analytics.daily_active_users USING btree (ga_date, _sdc_sequence);


--
-- Name: tp_monthly_active_users_ga_date__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_google_analytics; Owner: -
--

CREATE INDEX tp_monthly_active_users_ga_date__sdc_sequence_idx ON raw_tap_google_analytics.monthly_active_users USING btree (ga_date, _sdc_sequence);


--
-- Name: tp_pages_ga_date_ga_hostname_ga_pagepath__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_google_analytics; Owner: -
--

CREATE INDEX tp_pages_ga_date_ga_hostname_ga_pagepath__sdc_sequence_idx ON raw_tap_google_analytics.pages USING btree (ga_date, ga_hostname, ga_pagepath, _sdc_sequence);


--
-- Name: tp_website_overview_ga_date__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_google_analytics; Owner: -
--

CREATE INDEX tp_website_overview_ga_date__sdc_sequence_idx ON raw_tap_google_analytics.website_overview USING btree (ga_date, _sdc_sequence);


--
-- Name: tp_weekly_active_users_ga_date__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_google_analytics; Owner: -
--

CREATE INDEX tp_weekly_active_users_ga_date__sdc_sequence_idx ON raw_tap_google_analytics.weekly_active_users USING btree (ga_date, _sdc_sequence);


--
-- Name: tp_1b9996ac3d9bfa38a194b7f90058d6267acc74be; Type: INDEX; Schema: raw_tap_kafka; Owner: -
--

CREATE INDEX tp_1b9996ac3d9bfa38a194b7f90058d6267acc74be ON raw_tap_kafka.snowplow_production_enriched USING btree (_sdc_primary_key, _sdc_sequence);


--
-- Name: tp_3d8ca016746ce7e1275030b1d188eb7e6d800968; Type: INDEX; Schema: raw_tap_kafka; Owner: -
--

CREATE INDEX tp_3d8ca016746ce7e1275030b1d188eb7e6d800968 ON raw_tap_kafka.snowplow_production_enriched_bad__errors USING btree (_sdc_source_key__sdc_primary_key, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_599bbd259081e52e887f982c90b4ff45f11cff32; Type: INDEX; Schema: raw_tap_kafka; Owner: -
--

CREATE INDEX tp_599bbd259081e52e887f982c90b4ff45f11cff32 ON raw_tap_kafka.snowplow_production_enriched__contexts_com_google_analytics_coo USING btree (_sdc_source_key__sdc_primary_key, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_6c96f3ad952ad90ff9006ba7f0f1c559875d3531; Type: INDEX; Schema: raw_tap_kafka; Owner: -
--

CREATE INDEX tp_6c96f3ad952ad90ff9006ba7f0f1c559875d3531 ON raw_tap_kafka.snowplow_production_enriched__contexts_com_superpro_shopify___1 USING btree (_sdc_source_key__sdc_primary_key, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_7b5fa05192875198b44852b01f3b063feddbf07b; Type: INDEX; Schema: raw_tap_kafka; Owner: -
--

CREATE INDEX tp_7b5fa05192875198b44852b01f3b063feddbf07b ON raw_tap_kafka.snowplow_production_enriched__contexts_com_snowplowanalytics_sn USING btree (_sdc_source_key__sdc_primary_key, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_807c2623971cf20a17f2b19f6ca84346a4cc1730; Type: INDEX; Schema: raw_tap_kafka; Owner: -
--

CREATE INDEX tp_807c2623971cf20a17f2b19f6ca84346a4cc1730 ON raw_tap_kafka.snowplow_production_enriched__contexts_com_superpro_shopify_pag USING btree (_sdc_source_key__sdc_primary_key, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_8706dd1d3912158bd94702756eadcdc8bc8a2857; Type: INDEX; Schema: raw_tap_kafka; Owner: -
--

CREATE INDEX tp_8706dd1d3912158bd94702756eadcdc8bc8a2857 ON raw_tap_kafka.snowplow_production_enriched_bad USING btree (_sdc_primary_key, _sdc_sequence);


--
-- Name: tp_94af6d94a5f7badcf685e70950c3fbc565914d17; Type: INDEX; Schema: raw_tap_kafka; Owner: -
--

CREATE INDEX tp_94af6d94a5f7badcf685e70950c3fbc565914d17 ON raw_tap_kafka.snowplow_production_enriched__contexts_com_snowplowanalytics__1 USING btree (_sdc_source_key__sdc_primary_key, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_c5053d20eb12c8f09f21a55c8c980cb1f1befc98; Type: INDEX; Schema: raw_tap_kafka; Owner: -
--

CREATE INDEX tp_c5053d20eb12c8f09f21a55c8c980cb1f1befc98 ON raw_tap_kafka.snowplow_production_enriched__contexts_org_w3_performance_timin USING btree (_sdc_source_key__sdc_primary_key, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_02f5aa7e40f0d2a893267f7cacf26c5570c0376b; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_02f5aa7e40f0d2a893267f7cacf26c5570c0376b ON raw_tap_shopify.products__images USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_05e8d3c0b03c6bb1a3a4043660574a35c5847d21; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_05e8d3c0b03c6bb1a3a4043660574a35c5847d21 ON raw_tap_shopify.products__image__variant_ids USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_06dea7a54012a5308443bd58a0ae23e631e9213c; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_06dea7a54012a5308443bd58a0ae23e631e9213c ON raw_tap_shopify.orders__refunds__refund_line_items__line_item__properties USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id, _sdc_level_2_id);


--
-- Name: tp_0d134550071deb758fed45722da81a359e65095a; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_0d134550071deb758fed45722da81a359e65095a ON raw_tap_shopify.abandoned_checkouts__shipping_lines USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_0fcaef769510b41365e6aaab8a8c3f1691b91c8b; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_0fcaef769510b41365e6aaab8a8c3f1691b91c8b ON raw_tap_shopify.abandoned_checkouts__tax_lines USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_1a1b7987ba58452a9ec9e8b8f64c92f478426dd8; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_1a1b7987ba58452a9ec9e8b8f64c92f478426dd8 ON raw_tap_shopify.orders__fulfillments__tracking_urls USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_2183e11468a71d813749c170d2f8410b35934905; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_2183e11468a71d813749c170d2f8410b35934905 ON raw_tap_shopify.orders__line_items USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_220e3ab4bc7660ea86b1a3960dc0a820957f1e9d; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_220e3ab4bc7660ea86b1a3960dc0a820957f1e9d ON raw_tap_shopify.orders__fulfillments__line_items USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_25584c9d792a8de2f3996715d2b97c87bb6c69a4; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_25584c9d792a8de2f3996715d2b97c87bb6c69a4 ON raw_tap_shopify.customers__addresses USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_29b4865579510d3dba4d7364ac9e042de473dacb; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_29b4865579510d3dba4d7364ac9e042de473dacb ON raw_tap_shopify.orders__refunds__refund_line_items USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_348929c22642c3e9ce40f7a6928e3d75a6af27e3; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_348929c22642c3e9ce40f7a6928e3d75a6af27e3 ON raw_tap_shopify.abandoned_checkouts__line_items USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_3ac284582230f9b20fc645e351caee93a43b440d; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_3ac284582230f9b20fc645e351caee93a43b440d ON raw_tap_shopify.abandoned_checkouts__discount_codes USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_40475734a450efe054a96f6ca605abecb086860a; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_40475734a450efe054a96f6ca605abecb086860a ON raw_tap_shopify.abandoned_checkouts__line_items__discount_allocations USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_4237d1de724455a0327c8c83889ec24084c7b970; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_4237d1de724455a0327c8c83889ec24084c7b970 ON raw_tap_shopify.abandoned_checkouts__shipping_lines__applied_discounts USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_5062ce8810e177ca85b12d609fb5277ab6e88d89; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_5062ce8810e177ca85b12d609fb5277ab6e88d89 ON raw_tap_shopify.abandoned_checkouts__line_items__properties USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_514d1fb82c6d6e02f067f46a80037d98d1968257; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_514d1fb82c6d6e02f067f46a80037d98d1968257 ON raw_tap_shopify.orders__refunds__refund_line_items__line_item__tax_lines USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id, _sdc_level_2_id);


--
-- Name: tp_52d61084f186e573b3872ff117f5a3af52b9f7fc; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_52d61084f186e573b3872ff117f5a3af52b9f7fc ON raw_tap_shopify.orders__line_items__tax_lines USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_5300c4449973fdca348558e86541954406fc3ca4; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_5300c4449973fdca348558e86541954406fc3ca4 ON raw_tap_shopify.orders__shipping_lines USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_54a8774e6cb5d883ef0b8712e0e2b26abe730f30; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_54a8774e6cb5d883ef0b8712e0e2b26abe730f30 ON raw_tap_shopify.orders__shipping_lines__discount_allocations USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_5f6b4c3cc3417b8927dd9fc02fd1b7bf4b2c6a3e; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_5f6b4c3cc3417b8927dd9fc02fd1b7bf4b2c6a3e ON raw_tap_shopify.orders__refunds__refund_line_items__line_item__discount_allocat USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id, _sdc_level_2_id);


--
-- Name: tp_639373d78fa2baa99e1e911485b5b92e92cfefd4; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_639373d78fa2baa99e1e911485b5b92e92cfefd4 ON raw_tap_shopify.orders__fulfillments__line_items__discount_allocations USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id, _sdc_level_2_id);


--
-- Name: tp_63f1892896bee03dd035335f4834b454f71e972f; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_63f1892896bee03dd035335f4834b454f71e972f ON raw_tap_shopify.products__options__values USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_63f7a6a3bfb813c26ca706d3d7949dbc5e0267e1; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_63f7a6a3bfb813c26ca706d3d7949dbc5e0267e1 ON raw_tap_shopify.orders__shipping_lines__tax_lines USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_69a380e1eb3dceffde4f2291d8aecf48c2ebcb51; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_69a380e1eb3dceffde4f2291d8aecf48c2ebcb51 ON raw_tap_shopify.orders__fulfillments__line_items__tax_lines USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id, _sdc_level_2_id);


--
-- Name: tp_6c1085a7cdeb2bd0b5acd4abc10ce083f2bd7d60; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_6c1085a7cdeb2bd0b5acd4abc10ce083f2bd7d60 ON raw_tap_shopify.orders__payment_gateway_names USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_7f13dbba0698ad6e4f2cd16d06aee80fec49ff42; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_7f13dbba0698ad6e4f2cd16d06aee80fec49ff42 ON raw_tap_shopify.abandoned_checkouts__shipping_lines__custom_tax_lines USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_81405f1ad56bf29106bbcc8fb6029548d1fd6da0; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_81405f1ad56bf29106bbcc8fb6029548d1fd6da0 ON raw_tap_shopify.orders__fulfillments__line_items__applied_discounts USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id, _sdc_level_2_id);


--
-- Name: tp_8360a630d3ce1ffd90169acf35b0744eda98d06d; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_8360a630d3ce1ffd90169acf35b0744eda98d06d ON raw_tap_shopify.orders__note_attributes USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_83b1ce62dd453dc5b10be9c7778037fe280e1f00; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_83b1ce62dd453dc5b10be9c7778037fe280e1f00 ON raw_tap_shopify.orders__line_items__properties USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_8bf12ce2c542c974e3f43f381dee7704fb1eafc0; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_8bf12ce2c542c974e3f43f381dee7704fb1eafc0 ON raw_tap_shopify.orders__line_items__applied_discounts USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_a457ad1efc229f3375947fdbdc0d22e3078d4bc5; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_a457ad1efc229f3375947fdbdc0d22e3078d4bc5 ON raw_tap_shopify.orders__customer__addresses USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_a595c62f58e079afbb78e785e92fddc11ce0fef1; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_a595c62f58e079afbb78e785e92fddc11ce0fef1 ON raw_tap_shopify.orders__tax_lines USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_a9226f6428024de41aec601c5f8fc0b4465dc04f; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_a9226f6428024de41aec601c5f8fc0b4465dc04f ON raw_tap_shopify.products__options USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_aa9b5f871029975e588e407f6148a0fc37e41150; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_aa9b5f871029975e588e407f6148a0fc37e41150 ON raw_tap_shopify.orders__discount_codes USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_aacbc66a197a6c0f9e05f30498626af57ca057e2; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_aacbc66a197a6c0f9e05f30498626af57ca057e2 ON raw_tap_shopify.products__variants USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_abandoned_checkouts_id__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_abandoned_checkouts_id__sdc_sequence_idx ON raw_tap_shopify.abandoned_checkouts USING btree (id, _sdc_sequence);


--
-- Name: tp_ae6bd4b63c40042f78199327ccfd7a2c0a91cc55; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_ae6bd4b63c40042f78199327ccfd7a2c0a91cc55 ON raw_tap_shopify.orders__fulfillments__line_items__properties USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id, _sdc_level_2_id);


--
-- Name: tp_b1e571db3b15820c9b9c9594e36e32568550240a; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_b1e571db3b15820c9b9c9594e36e32568550240a ON raw_tap_shopify.orders__fulfillments__tracking_numbers USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_c24c70790a6055f08734ab47cb0398711e8a4e33; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_c24c70790a6055f08734ab47cb0398711e8a4e33 ON raw_tap_shopify.orders__line_items__discount_allocations USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_c319c0c3e8d1f0538685b6218e0f75810a7414ce; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_c319c0c3e8d1f0538685b6218e0f75810a7414ce ON raw_tap_shopify.orders__fulfillments USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_c4c5a9c9997501715d8e6203cf592a66b3ccbdac; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_c4c5a9c9997501715d8e6203cf592a66b3ccbdac ON raw_tap_shopify.products__images__variant_ids USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_c8e8d7ef6baac72a152f76be15423abe9e0fbfbf; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_c8e8d7ef6baac72a152f76be15423abe9e0fbfbf ON raw_tap_shopify.orders__refunds__order_adjustments USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_cdf9a38e8cb995d6bfa62b1da979883210992284; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_cdf9a38e8cb995d6bfa62b1da979883210992284 ON raw_tap_shopify.orders__order_adjustments USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_collects_id__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_collects_id__sdc_sequence_idx ON raw_tap_shopify.collects USING btree (id, _sdc_sequence);


--
-- Name: tp_custom_collections_id__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_custom_collections_id__sdc_sequence_idx ON raw_tap_shopify.custom_collections USING btree (id, _sdc_sequence);


--
-- Name: tp_customers_id__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_customers_id__sdc_sequence_idx ON raw_tap_shopify.customers USING btree (id, _sdc_sequence);


--
-- Name: tp_d17f332af552a250aeae89e773d64a1abf6edb77; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_d17f332af552a250aeae89e773d64a1abf6edb77 ON raw_tap_shopify.abandoned_checkouts__line_items__tax_lines USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_dfb3867c00c9f9fd59cc1ccdafeef95859383308; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_dfb3867c00c9f9fd59cc1ccdafeef95859383308 ON raw_tap_shopify.abandoned_checkouts__shipping_lines__tax_lines USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_e423afdace0335f98d4ae2533d22142c0848d1d7; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_e423afdace0335f98d4ae2533d22142c0848d1d7 ON raw_tap_shopify.orders__refunds USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_eb95763da08061dc82c7ff1a826893a748483c07; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_eb95763da08061dc82c7ff1a826893a748483c07 ON raw_tap_shopify.abandoned_checkouts__line_items__applied_discounts USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id);


--
-- Name: tp_ece4e3db06b870c094f4de587d9daa8ba77bed1e; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_ece4e3db06b870c094f4de587d9daa8ba77bed1e ON raw_tap_shopify.abandoned_checkouts__customer__addresses USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_f3b7734ff8effcd7e45519c2545d01b5980688ad; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_f3b7734ff8effcd7e45519c2545d01b5980688ad ON raw_tap_shopify.orders__refunds__refund_line_items__line_item__applied_discount USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id, _sdc_level_1_id, _sdc_level_2_id);


--
-- Name: tp_f565755029e95b19fb6e93c515ade9cae5a7bacc; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_f565755029e95b19fb6e93c515ade9cae5a7bacc ON raw_tap_shopify.abandoned_checkouts__note_attributes USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_fe4f29bd8a700bc4199d00faf4207f0e52f2634c; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_fe4f29bd8a700bc4199d00faf4207f0e52f2634c ON raw_tap_shopify.orders__discount_applications USING btree (_sdc_source_key_id, _sdc_sequence, _sdc_level_0_id);


--
-- Name: tp_metafields_id__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_metafields_id__sdc_sequence_idx ON raw_tap_shopify.metafields USING btree (id, _sdc_sequence);


--
-- Name: tp_orders_id__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_orders_id__sdc_sequence_idx ON raw_tap_shopify.orders USING btree (id, _sdc_sequence);


--
-- Name: tp_products_id__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_products_id__sdc_sequence_idx ON raw_tap_shopify.products USING btree (id, _sdc_sequence);


--
-- Name: tp_transactions_id__sdc_sequence_idx; Type: INDEX; Schema: raw_tap_shopify; Owner: -
--

CREATE INDEX tp_transactions_id__sdc_sequence_idx ON raw_tap_shopify.transactions USING btree (id, _sdc_sequence);


--
-- Name: tp_sales_order_id__sdc_sequence_idx; Type: INDEX; Schema: tap_csv; Owner: -
--

CREATE INDEX tp_sales_order_id__sdc_sequence_idx ON tap_csv.sales USING btree (order_id, _sdc_sequence);


--
-- Name: dim_shopify_customers__index_on_customer_id; Type: INDEX; Schema: warehouse; Owner: -
--

CREATE INDEX dim_shopify_customers__index_on_customer_id ON warehouse.dim_shopify_customers USING btree (customer_id);


--
-- Name: fct_shopify_customer_pareto__index_on_account_id__year__custome; Type: INDEX; Schema: warehouse; Owner: -
--

CREATE INDEX fct_shopify_customer_pareto__index_on_account_id__year__custome ON warehouse.fct_shopify_customer_pareto USING btree (account_id, year, customer_rank);


--
-- Name: fct_shopify_orders__index_on_account_id__customer_id__created_a; Type: INDEX; Schema: warehouse; Owner: -
--

CREATE INDEX fct_shopify_orders__index_on_account_id__customer_id__created_a ON warehouse.fct_shopify_orders USING btree (account_id, customer_id, created_at);


--
-- Name: fct_shopify_orders__index_on_cancelled_at; Type: INDEX; Schema: warehouse; Owner: -
--

CREATE INDEX fct_shopify_orders__index_on_cancelled_at ON warehouse.fct_shopify_orders USING btree (cancelled_at);


--
-- Name: fct_shopify_orders__index_on_customer_id__created_at; Type: INDEX; Schema: warehouse; Owner: -
--

CREATE INDEX fct_shopify_orders__index_on_customer_id__created_at ON warehouse.fct_shopify_orders USING btree (customer_id, created_at);


--
-- Name: fct_snowplow_page_views__index_on_account_id__max_tstamp; Type: INDEX; Schema: warehouse; Owner: -
--

CREATE INDEX fct_snowplow_page_views__index_on_account_id__max_tstamp ON warehouse.fct_snowplow_page_views USING btree (account_id, max_tstamp);


--
-- Name: stg_shopify_customer_order_aggregates__index_on_account_id__cus; Type: INDEX; Schema: warehouse; Owner: -
--

CREATE INDEX stg_shopify_customer_order_aggregates__index_on_account_id__cus ON warehouse.stg_shopify_customer_order_aggregates USING btree (account_id, customer_id);


--
-- Name: stg_shopify_customer_order_aggregates__index_on_customer_id; Type: INDEX; Schema: warehouse; Owner: -
--

CREATE INDEX stg_shopify_customer_order_aggregates__index_on_customer_id ON warehouse.stg_shopify_customer_order_aggregates USING btree (customer_id);


--
-- Name: stg_shopify_customer_rfm__index_on_account_id__customer_id; Type: INDEX; Schema: warehouse; Owner: -
--

CREATE INDEX stg_shopify_customer_rfm__index_on_account_id__customer_id ON warehouse.stg_shopify_customer_rfm USING btree (account_id, customer_id);


--
-- Name: stg_shopify_customer_rolling_rfm__index_on_account_id__week__rf; Type: INDEX; Schema: warehouse; Owner: -
--

CREATE INDEX stg_shopify_customer_rolling_rfm__index_on_account_id__week__rf ON warehouse.stg_shopify_customer_rolling_rfm USING btree (account_id, week, rfm_label);


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
-- Name: singer_sync_states fk_rails_3c1c3bc797; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_sync_states
    ADD CONSTRAINT fk_rails_3c1c3bc797 FOREIGN KEY (connection_id) REFERENCES public.connections(id);


--
-- Name: shopify_shops fk_rails_484f3cc7d7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopify_shops
    ADD CONSTRAINT fk_rails_484f3cc7d7 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


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
-- Name: plaid_transactions fk_rails_91669f6ab9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plaid_transactions
    ADD CONSTRAINT fk_rails_91669f6ab9 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


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
-- Name: singer_sync_attempts fk_rails_b8f5d0f596; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.singer_sync_attempts
    ADD CONSTRAINT fk_rails_b8f5d0f596 FOREIGN KEY (connection_id) REFERENCES public.connections(id);


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
('20190903210744'),
('20190905191310'),
('20190910185603'),
('20190916215131'),
('20190917231914'),
('20190917231933'),
('20190925155649');



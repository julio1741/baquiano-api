SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.addresses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid NOT NULL,
    city_id uuid NOT NULL,
    label character varying,
    recipient_name character varying NOT NULL,
    contact_phone_encrypted text,
    original_text character varying NOT NULL,
    normalized_text character varying,
    building character varying,
    floor character varying,
    apartment character varying,
    landmark character varying,
    delivery_instructions character varying,
    location public.geography(Point,4326) NOT NULL,
    location_accuracy_meters double precision,
    validated_at timestamp with time zone,
    is_default boolean DEFAULT false NOT NULL,
    archived_at timestamp with time zone,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


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
-- Name: audit_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    actor_user_id uuid,
    actor_type character varying NOT NULL,
    action character varying NOT NULL,
    resource_type character varying NOT NULL,
    resource_id uuid,
    organization_id uuid,
    branch_id uuid,
    request_id character varying,
    correlation_id character varying,
    ip_address inet,
    user_agent character varying,
    change_details jsonb DEFAULT '{}'::jsonb NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    occurred_at timestamp with time zone NOT NULL,
    created_at timestamp(6) with time zone NOT NULL
);


--
-- Name: branches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    merchant_id uuid NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    phone_encrypted text,
    email_encrypted text,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    delivery_model character varying NOT NULL,
    address_text character varying NOT NULL,
    address_reference character varying,
    location public.geography(Point,4326) NOT NULL,
    preparation_time_minutes integer,
    minimum_order_amount bigint,
    minimum_order_currency character varying,
    accepts_cash boolean DEFAULT false NOT NULL,
    accepts_mobile_payment boolean DEFAULT true NOT NULL,
    accepts_pos_on_delivery boolean DEFAULT false NOT NULL,
    paused_at timestamp with time zone,
    pause_reason character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT branches_minimum_order_amount_non_negative CHECK (((minimum_order_amount IS NULL) OR (minimum_order_amount >= 0))),
    CONSTRAINT branches_preparation_time_minutes_positive CHECK (((preparation_time_minutes IS NULL) OR (preparation_time_minutes > 0)))
);


--
-- Name: business_hours; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_hours (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    day_of_week integer NOT NULL,
    opens_at time without time zone NOT NULL,
    closes_at time without time zone NOT NULL,
    crosses_midnight boolean DEFAULT false NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT business_hours_day_of_week_range CHECK (((day_of_week >= 0) AND (day_of_week <= 6)))
);


--
-- Name: cart_item_modifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cart_item_modifiers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cart_item_id uuid NOT NULL,
    modifier_id uuid NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    additional_price_amount_snapshot bigint NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT cart_item_modifiers_price_non_negative CHECK ((additional_price_amount_snapshot >= 0)),
    CONSTRAINT cart_item_modifiers_quantity_positive CHECK ((quantity > 0))
);


--
-- Name: cart_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cart_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cart_id uuid NOT NULL,
    product_id uuid NOT NULL,
    product_variant_id uuid,
    quantity integer NOT NULL,
    unit_price_amount_snapshot bigint NOT NULL,
    currency character varying NOT NULL,
    notes character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT cart_items_quantity_positive CHECK ((quantity > 0)),
    CONSTRAINT cart_items_unit_price_non_negative CHECK ((unit_price_amount_snapshot >= 0))
);


--
-- Name: carts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.carts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    currency character varying NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: cash_balances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cash_balances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    courier_id uuid NOT NULL,
    currency character varying NOT NULL,
    amount_held bigint DEFAULT 0 NOT NULL,
    exposure_limit bigint NOT NULL,
    blocked_for_cash_orders boolean DEFAULT false NOT NULL,
    calculated_at timestamp with time zone NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT cash_balances_amount_held_non_negative CHECK ((amount_held >= 0))
);


--
-- Name: cash_handovers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cash_handovers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    courier_id uuid NOT NULL,
    received_by_user_id uuid NOT NULL,
    amount bigint NOT NULL,
    currency character varying NOT NULL,
    evidence_attachment_reference character varying,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    idempotency_key character varying NOT NULL,
    handed_over_at timestamp with time zone NOT NULL,
    confirmed_at timestamp with time zone,
    notes text,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT cash_handovers_amount_positive CHECK ((amount > 0))
);


--
-- Name: catalogs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalogs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    name character varying NOT NULL,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    published_at timestamp with time zone,
    version integer DEFAULT 1 NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    catalog_id uuid NOT NULL,
    parent_category_id uuid,
    name character varying NOT NULL,
    description character varying,
    "position" integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    available_from timestamp with time zone,
    available_until timestamp with time zone,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: cities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    state_name character varying NOT NULL,
    country_code character varying NOT NULL,
    timezone character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: courier_availabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courier_availabilities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    courier_id uuid NOT NULL,
    status character varying NOT NULL,
    zone_id uuid,
    started_at timestamp with time zone NOT NULL,
    ended_at timestamp with time zone,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: courier_branch_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courier_branch_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    courier_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    active boolean DEFAULT true NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: courier_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courier_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    courier_id uuid NOT NULL,
    document_type character varying NOT NULL,
    attachment_reference character varying NOT NULL,
    document_number_encrypted text,
    document_number_digest character varying,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    expires_at timestamp with time zone,
    reviewed_by_user_id uuid,
    reviewed_at timestamp with time zone,
    rejection_reason character varying,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: couriers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.couriers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    organization_id uuid,
    courier_type character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    approval_status character varying DEFAULT 'pending'::character varying NOT NULL,
    risk_level character varying DEFAULT 'standard'::character varying NOT NULL,
    cash_enabled boolean DEFAULT false NOT NULL,
    maximum_cash_exposure bigint,
    approved_at timestamp with time zone,
    suspended_at timestamp with time zone,
    suspension_reason character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT couriers_maximum_cash_exposure_non_negative CHECK (((maximum_cash_exposure IS NULL) OR (maximum_cash_exposure >= 0)))
);


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    default_address_id uuid,
    risk_level character varying DEFAULT 'standard'::character varying NOT NULL,
    total_completed_orders integer DEFAULT 0 NOT NULL,
    last_order_at timestamp with time zone,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT customers_total_completed_orders_non_negative CHECK ((total_completed_orders >= 0))
);


--
-- Name: deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deliveries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    courier_id uuid,
    branch_id uuid NOT NULL,
    delivery_model character varying NOT NULL,
    status character varying DEFAULT 'pending_assignment'::character varying NOT NULL,
    pickup_location public.geography(Point,4326) NOT NULL,
    dropoff_location public.geography(Point,4326) NOT NULL,
    estimated_distance_meters integer,
    estimated_duration_seconds integer,
    estimated_pickup_at timestamp with time zone,
    estimated_delivery_at timestamp with time zone,
    assigned_at timestamp with time zone,
    accepted_at timestamp with time zone,
    arrived_at_merchant_at timestamp with time zone,
    picked_up_at timestamp with time zone,
    arrived_at_customer_at timestamp with time zone,
    delivered_at timestamp with time zone,
    failed_at timestamp with time zone,
    failure_reason character varying,
    delivery_pin_digest character varying,
    proof_of_pickup_attachment_reference character varying,
    proof_of_delivery_attachment_reference character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    delivery_pin_encrypted text,
    CONSTRAINT deliveries_estimated_distance_meters_non_negative CHECK (((estimated_distance_meters IS NULL) OR (estimated_distance_meters >= 0))),
    CONSTRAINT deliveries_estimated_duration_seconds_non_negative CHECK (((estimated_duration_seconds IS NULL) OR (estimated_duration_seconds >= 0)))
);


--
-- Name: delivery_fee_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delivery_fee_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    city_id uuid NOT NULL,
    zone_id uuid,
    name character varying NOT NULL,
    calculation_type character varying NOT NULL,
    base_amount bigint NOT NULL,
    per_kilometer_amount bigint,
    minimum_amount bigint,
    maximum_amount bigint,
    currency character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    valid_from date NOT NULL,
    valid_until date,
    configuration jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT delivery_fee_rules_base_amount_non_negative CHECK ((base_amount >= 0))
);


--
-- Name: delivery_incidents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delivery_incidents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    delivery_id uuid NOT NULL,
    order_id uuid NOT NULL,
    reported_by_user_id uuid NOT NULL,
    incident_type character varying NOT NULL,
    severity character varying NOT NULL,
    status character varying DEFAULT 'open'::character varying NOT NULL,
    description text NOT NULL,
    resolution text,
    resolved_by_user_id uuid,
    occurred_at timestamp with time zone NOT NULL,
    resolved_at timestamp with time zone,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.devices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    installation_id character varying NOT NULL,
    platform character varying NOT NULL,
    app_type character varying NOT NULL,
    app_version character varying,
    os_version character varying,
    device_model character varying,
    push_token_encrypted text,
    push_provider character varying,
    device_fingerprint_digest character varying,
    trusted_at timestamp with time zone,
    blocked_at timestamp with time zone,
    last_seen_at timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: dispatch_offers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dispatch_offers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    delivery_id uuid NOT NULL,
    courier_id uuid NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    offered_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    responded_at timestamp with time zone,
    rejection_reason character varying,
    score_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: domain_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.domain_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    aggregate_type character varying NOT NULL,
    aggregate_id uuid NOT NULL,
    event_type character varying NOT NULL,
    event_version integer DEFAULT 1 NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    occurred_at timestamp with time zone NOT NULL,
    correlation_id uuid NOT NULL,
    causation_id uuid,
    created_at timestamp(6) with time zone NOT NULL
);


--
-- Name: exchange_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_rates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    base_currency character varying NOT NULL,
    quote_currency character varying NOT NULL,
    rate_numerator bigint NOT NULL,
    rate_denominator bigint NOT NULL,
    source character varying NOT NULL,
    rate_type character varying NOT NULL,
    effective_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone,
    created_by_user_id uuid NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT exchange_rates_rate_denominator_positive CHECK ((rate_denominator > 0)),
    CONSTRAINT exchange_rates_rate_numerator_positive CHECK ((rate_numerator > 0))
);


--
-- Name: feature_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feature_flags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key character varying NOT NULL,
    description character varying,
    enabled boolean DEFAULT false NOT NULL,
    rules jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_by_user_id uuid NOT NULL,
    updated_by_user_id uuid NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: fraud_signals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fraud_signals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subject_type character varying NOT NULL,
    subject_id uuid NOT NULL,
    order_id uuid,
    payment_intent_id uuid,
    signal_type character varying NOT NULL,
    score numeric(5,2) NOT NULL,
    severity character varying NOT NULL,
    evidence jsonb DEFAULT '{}'::jsonb NOT NULL,
    detected_at timestamp with time zone NOT NULL,
    created_at timestamp(6) with time zone NOT NULL
);


--
-- Name: idempotency_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.idempotency_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key character varying NOT NULL,
    actor_type character varying NOT NULL,
    actor_id uuid NOT NULL,
    operation character varying NOT NULL,
    request_digest character varying NOT NULL,
    response_status integer,
    response_body_encrypted text,
    resource_type character varying,
    resource_id uuid,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: inventory_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    product_id uuid,
    product_variant_id uuid,
    availability_status character varying DEFAULT 'available'::character varying NOT NULL,
    quantity integer,
    track_quantity boolean DEFAULT false NOT NULL,
    unavailable_until timestamp with time zone,
    updated_by_user_id uuid NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT inventory_items_exactly_one_target CHECK ((((product_id IS NOT NULL) AND (product_variant_id IS NULL)) OR ((product_id IS NULL) AND (product_variant_id IS NOT NULL))))
);


--
-- Name: ledger_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ledger_accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    owner_type character varying,
    owner_id uuid,
    account_code character varying NOT NULL,
    account_type character varying NOT NULL,
    currency character varying NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: ledger_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ledger_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ledger_transaction_id uuid NOT NULL,
    ledger_account_id uuid NOT NULL,
    direction character varying NOT NULL,
    amount bigint NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT ledger_entries_amount_positive CHECK ((amount > 0))
);


--
-- Name: ledger_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ledger_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transaction_type character varying NOT NULL,
    reference_type character varying NOT NULL,
    reference_id uuid NOT NULL,
    description character varying,
    idempotency_key character varying NOT NULL,
    effective_at timestamp with time zone NOT NULL,
    posted_at timestamp with time zone NOT NULL,
    reversal_of_transaction_id uuid,
    created_by_user_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) with time zone NOT NULL
);


--
-- Name: location_pings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location_pings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    courier_id uuid NOT NULL,
    delivery_id uuid,
    location public.geography(Point,4326) NOT NULL,
    device_recorded_at timestamp with time zone NOT NULL,
    server_received_at timestamp with time zone NOT NULL,
    accuracy_meters numeric(8,2),
    speed_meters_per_second numeric(8,2),
    heading_degrees numeric(5,2),
    source character varying NOT NULL,
    simulated_location_suspected boolean DEFAULT false NOT NULL,
    anomaly_flags jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) with time zone NOT NULL
);


--
-- Name: merchants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merchants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    slug character varying NOT NULL,
    description character varying,
    vertical character varying NOT NULL,
    logo_attachment_reference character varying,
    cover_attachment_reference character varying,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    commission_type character varying,
    commission_rate_basis_points integer,
    commission_fixed_amount bigint,
    commission_currency character varying,
    accepts_baquiano_couriers boolean DEFAULT false NOT NULL,
    accepts_own_couriers boolean DEFAULT false NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT merchants_commission_rate_basis_points_range CHECK (((commission_rate_basis_points IS NULL) OR ((commission_rate_basis_points >= 0) AND (commission_rate_basis_points <= 10000))))
);


--
-- Name: mobile_payment_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mobile_payment_submissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    payment_intent_id uuid NOT NULL,
    origin_bank_code character varying,
    destination_bank_code character varying,
    reference character varying NOT NULL,
    reference_digest character varying NOT NULL,
    payer_document_masked character varying,
    payer_phone_masked character varying,
    amount bigint NOT NULL,
    currency character varying NOT NULL,
    paid_at timestamp with time zone NOT NULL,
    evidence_attachment_reference character varying,
    review_status character varying DEFAULT 'submitted'::character varying NOT NULL,
    reviewed_by_user_id uuid,
    reviewed_at timestamp with time zone,
    rejection_reason character varying,
    duplicate_of_submission_id uuid,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT mobile_payment_submissions_amount_non_negative CHECK ((amount >= 0))
);


--
-- Name: modifier_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modifier_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    name character varying NOT NULL,
    minimum_selections integer DEFAULT 0 NOT NULL,
    maximum_selections integer NOT NULL,
    required boolean DEFAULT false NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT modifier_groups_maximum_gte_minimum CHECK ((maximum_selections >= minimum_selections)),
    CONSTRAINT modifier_groups_minimum_selections_non_negative CHECK ((minimum_selections >= 0))
);


--
-- Name: modifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modifiers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    modifier_group_id uuid NOT NULL,
    name character varying NOT NULL,
    additional_price_amount bigint DEFAULT 0 NOT NULL,
    currency character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT modifiers_additional_price_amount_non_negative CHECK ((additional_price_amount >= 0))
);


--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_preferences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    notification_type character varying NOT NULL,
    push_enabled boolean DEFAULT true NOT NULL,
    sms_enabled boolean DEFAULT true NOT NULL,
    email_enabled boolean DEFAULT true NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    order_id uuid,
    channel character varying NOT NULL,
    template_code character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    destination_digest character varying,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    provider character varying DEFAULT 'log'::character varying NOT NULL,
    provider_message_id character varying,
    scheduled_at timestamp with time zone NOT NULL,
    sent_at timestamp with time zone,
    delivered_at timestamp with time zone,
    failed_at timestamp with time zone,
    failure_code character varying,
    attempt_count integer DEFAULT 0 NOT NULL,
    idempotency_key character varying NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: order_item_modifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_item_modifiers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_item_id uuid NOT NULL,
    source_modifier_id uuid,
    modifier_group_name_snapshot character varying NOT NULL,
    modifier_name_snapshot character varying NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    unit_price_amount bigint NOT NULL,
    total_amount bigint NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT order_item_modifiers_quantity_positive CHECK ((quantity > 0))
);


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    source_product_id uuid,
    source_variant_id uuid,
    sku_snapshot character varying NOT NULL,
    name_snapshot character varying NOT NULL,
    description_snapshot character varying,
    variant_name_snapshot character varying,
    quantity integer NOT NULL,
    unit_price_amount bigint NOT NULL,
    tax_amount bigint DEFAULT 0 NOT NULL,
    discount_amount bigint DEFAULT 0 NOT NULL,
    line_total_amount bigint NOT NULL,
    currency character varying NOT NULL,
    notes character varying,
    product_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT order_items_line_total_non_negative CHECK ((line_total_amount >= 0)),
    CONSTRAINT order_items_quantity_positive CHECK ((quantity > 0))
);


--
-- Name: order_status_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_status_histories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    from_status character varying,
    to_status character varying NOT NULL,
    actor_user_id uuid,
    actor_type character varying NOT NULL,
    reason_code character varying,
    notes character varying,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    occurred_at timestamp with time zone NOT NULL,
    created_at timestamp(6) with time zone NOT NULL
);


--
-- Name: order_transition_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_transition_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    requested_transition character varying NOT NULL,
    requested_by_user_id uuid NOT NULL,
    idempotency_key character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    failure_code character varying,
    failure_message character varying,
    processed_at timestamp with time zone,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    public_number character varying NOT NULL,
    customer_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    merchant_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    address_id uuid NOT NULL,
    quote_id uuid NOT NULL,
    delivery_id uuid,
    current_status character varying DEFAULT 'placed'::character varying NOT NULL,
    payment_status character varying NOT NULL,
    fulfillment_type character varying DEFAULT 'delivery'::character varying NOT NULL,
    delivery_model character varying NOT NULL,
    currency character varying NOT NULL,
    subtotal_amount bigint NOT NULL,
    discount_amount bigint DEFAULT 0 NOT NULL,
    tax_amount bigint DEFAULT 0 NOT NULL,
    delivery_fee_amount bigint DEFAULT 0 NOT NULL,
    service_fee_amount bigint DEFAULT 0 NOT NULL,
    total_amount bigint NOT NULL,
    exchange_rate_id uuid,
    exchange_rate_value numeric(20,10),
    customer_notes character varying,
    merchant_notes character varying,
    placed_at timestamp with time zone NOT NULL,
    merchant_accepted_at timestamp with time zone,
    ready_at timestamp with time zone,
    picked_up_at timestamp with time zone,
    delivered_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    cancellation_reason_code character varying,
    cancellation_notes character varying,
    pricing_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    address_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    merchant_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    idempotency_key character varying NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    payment_method character varying,
    CONSTRAINT orders_subtotal_amount_non_negative CHECK ((subtotal_amount >= 0)),
    CONSTRAINT orders_total_amount_non_negative CHECK ((total_amount >= 0))
);


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    legal_name character varying NOT NULL,
    display_name character varying NOT NULL,
    organization_type character varying NOT NULL,
    tax_identifier_encrypted text,
    tax_identifier_digest character varying,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    default_currency character varying NOT NULL,
    contact_phone_encrypted text,
    contact_email_encrypted text,
    onboarding_status character varying DEFAULT 'started'::character varying NOT NULL,
    approved_at timestamp with time zone,
    suspended_at timestamp with time zone,
    suspension_reason character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: otp_challenges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.otp_challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    phone_digest character varying NOT NULL,
    purpose character varying NOT NULL,
    code_digest character varying NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    consumed_at timestamp with time zone,
    attempt_count integer DEFAULT 0 NOT NULL,
    maximum_attempts integer DEFAULT 5 NOT NULL,
    requested_ip inet,
    device_fingerprint_digest character varying,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT otp_challenges_attempt_count_non_negative CHECK ((attempt_count >= 0)),
    CONSTRAINT otp_challenges_maximum_attempts_positive CHECK ((maximum_attempts > 0))
);


--
-- Name: outbox_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outbox_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_type character varying NOT NULL,
    aggregate_type character varying NOT NULL,
    aggregate_id uuid NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    available_at timestamp with time zone NOT NULL,
    published_at timestamp with time zone,
    attempt_count integer DEFAULT 0 NOT NULL,
    last_error character varying,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: payment_intents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_intents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    provider character varying DEFAULT 'manual'::character varying NOT NULL,
    payment_method character varying NOT NULL,
    status character varying DEFAULT 'created'::character varying NOT NULL,
    amount bigint NOT NULL,
    currency character varying NOT NULL,
    provider_reference character varying,
    idempotency_key character varying NOT NULL,
    expires_at timestamp with time zone,
    authorized_at timestamp with time zone,
    captured_at timestamp with time zone,
    failed_at timestamp with time zone,
    failure_code character varying,
    failure_message character varying,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT payment_intents_amount_non_negative CHECK ((amount >= 0))
);


--
-- Name: payment_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    payment_intent_id uuid NOT NULL,
    transaction_type character varying NOT NULL,
    status character varying NOT NULL,
    amount bigint NOT NULL,
    currency character varying NOT NULL,
    provider_transaction_id character varying,
    idempotency_key character varying NOT NULL,
    raw_response_encrypted text,
    occurred_at timestamp with time zone NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT payment_transactions_amount_non_negative CHECK ((amount >= 0))
);


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    resource character varying NOT NULL,
    action character varying NOT NULL,
    code character varying NOT NULL,
    description character varying,
    sensitive boolean DEFAULT false NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: pos_payment_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_payment_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    payment_intent_id uuid NOT NULL,
    terminal_owner_type character varying,
    terminal_owner_id uuid,
    terminal_identifier_encrypted text,
    acquiring_account_reference_encrypted text,
    receipt_reference character varying,
    amount bigint NOT NULL,
    currency character varying NOT NULL,
    status character varying DEFAULT 'confirmed'::character varying NOT NULL,
    confirmed_by_user_id uuid NOT NULL,
    confirmed_at timestamp with time zone NOT NULL,
    evidence_attachment_reference character varying,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT pos_payment_records_amount_non_negative CHECK ((amount >= 0))
);


--
-- Name: product_variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_variants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    sku character varying NOT NULL,
    name character varying NOT NULL,
    price_amount bigint NOT NULL,
    currency character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT product_variants_price_amount_non_negative CHECK ((price_amount >= 0))
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    catalog_id uuid NOT NULL,
    category_id uuid NOT NULL,
    sku character varying NOT NULL,
    name character varying NOT NULL,
    description character varying,
    product_type character varying NOT NULL,
    base_price_amount bigint NOT NULL,
    currency character varying NOT NULL,
    tax_rule_id uuid,
    image_attachment_reference character varying,
    active boolean DEFAULT true NOT NULL,
    age_restricted boolean DEFAULT false NOT NULL,
    prescription_required boolean DEFAULT false NOT NULL,
    preparation_time_minutes integer,
    available_from timestamp with time zone,
    available_until timestamp with time zone,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT products_base_price_amount_non_negative CHECK ((base_price_amount >= 0))
);


--
-- Name: quotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quotes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cart_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    address_id uuid NOT NULL,
    currency character varying NOT NULL,
    subtotal_amount bigint NOT NULL,
    discount_amount bigint DEFAULT 0 NOT NULL,
    tax_amount bigint DEFAULT 0 NOT NULL,
    delivery_fee_amount bigint DEFAULT 0 NOT NULL,
    service_fee_amount bigint DEFAULT 0 NOT NULL,
    total_amount bigint NOT NULL,
    exchange_rate_id uuid,
    exchange_rate_value numeric(20,10),
    pricing_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    consumed_at timestamp with time zone,
    idempotency_key character varying NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT quotes_subtotal_amount_non_negative CHECK ((subtotal_amount >= 0)),
    CONSTRAINT quotes_total_amount_non_negative CHECK ((total_amount >= 0))
);


--
-- Name: reconciliation_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reconciliation_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider character varying NOT NULL,
    payment_method character varying NOT NULL,
    currency character varying NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    status character varying DEFAULT 'open'::character varying NOT NULL,
    expected_amount bigint DEFAULT 0 NOT NULL,
    actual_amount bigint DEFAULT 0 NOT NULL,
    difference_amount bigint DEFAULT 0 NOT NULL,
    started_by_user_id uuid NOT NULL,
    completed_by_user_id uuid,
    started_at timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: reconciliation_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reconciliation_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reconciliation_batch_id uuid NOT NULL,
    payment_transaction_id uuid,
    external_reference character varying,
    expected_amount bigint NOT NULL,
    actual_amount bigint NOT NULL,
    difference_amount bigint NOT NULL,
    currency character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    resolution_code character varying,
    resolution_notes text,
    resolved_by_user_id uuid,
    resolved_at timestamp with time zone,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: refunds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refunds (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    payment_intent_id uuid NOT NULL,
    requested_by_user_id uuid NOT NULL,
    approved_by_user_id uuid,
    status character varying DEFAULT 'requested'::character varying NOT NULL,
    reason_code character varying NOT NULL,
    reason_notes text,
    amount bigint NOT NULL,
    currency character varying NOT NULL,
    idempotency_key character varying NOT NULL,
    provider_reference character varying,
    requested_at timestamp with time zone NOT NULL,
    approved_at timestamp with time zone,
    completed_at timestamp with time zone,
    failed_at timestamp with time zone,
    failure_code character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT refunds_amount_positive CHECK ((amount > 0))
);


--
-- Name: risk_decisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.risk_decisions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subject_type character varying NOT NULL,
    subject_id uuid NOT NULL,
    order_id uuid,
    decision character varying NOT NULL,
    risk_score numeric(5,2) NOT NULL,
    reasons jsonb DEFAULT '{}'::jsonb NOT NULL,
    rules_version character varying NOT NULL,
    reviewed_by_user_id uuid,
    reviewed_at timestamp with time zone,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: role_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    organization_id uuid,
    branch_id uuid,
    starts_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone,
    assigned_by_user_id uuid NOT NULL,
    revoked_at timestamp with time zone,
    revoked_by_user_id uuid,
    revocation_reason character varying,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    conditions jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) with time zone NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    name character varying NOT NULL,
    code character varying NOT NULL,
    description character varying,
    scope_type character varying NOT NULL,
    system_role boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: service_areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_areas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid,
    city_id uuid NOT NULL,
    name character varying NOT NULL,
    geometry public.geography(MultiPolygon,4326) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    delivery_fee_rule_id uuid,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    device_id uuid NOT NULL,
    refresh_token_digest character varying NOT NULL,
    ip_address inet,
    user_agent character varying,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    rotated_from_session_id uuid,
    last_used_at timestamp with time zone,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: settlements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settlements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    beneficiary_type character varying NOT NULL,
    beneficiary_id uuid NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    currency character varying NOT NULL,
    gross_amount bigint NOT NULL,
    commission_amount bigint DEFAULT 0 NOT NULL,
    adjustment_amount bigint DEFAULT 0 NOT NULL,
    net_amount bigint NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    approved_by_user_id uuid,
    paid_at timestamp with time zone,
    payment_reference_encrypted text,
    idempotency_key character varying NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: special_business_hours; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.special_business_hours (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    date date NOT NULL,
    is_closed boolean DEFAULT false NOT NULL,
    opens_at time without time zone,
    closes_at time without time zone,
    reason character varying,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: support_cases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_cases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    public_number character varying NOT NULL,
    customer_id uuid,
    order_id uuid,
    delivery_id uuid,
    opened_by_user_id uuid NOT NULL,
    assigned_to_user_id uuid,
    category character varying NOT NULL,
    priority character varying DEFAULT 'medium'::character varying NOT NULL,
    status character varying DEFAULT 'open'::character varying NOT NULL,
    subject character varying NOT NULL,
    description text NOT NULL,
    resolution text,
    opened_at timestamp with time zone NOT NULL,
    resolved_at timestamp with time zone,
    closed_at timestamp with time zone,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    scope_type character varying NOT NULL,
    scope_id uuid,
    key character varying NOT NULL,
    value jsonb NOT NULL,
    value_type character varying NOT NULL,
    encrypted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    effective_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone,
    updated_by_user_id uuid NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: tax_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tax_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    name character varying NOT NULL,
    rate_basis_points integer NOT NULL,
    inclusive boolean DEFAULT true NOT NULL,
    active boolean DEFAULT true NOT NULL,
    valid_from date NOT NULL,
    valid_until date,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT tax_rules_rate_basis_points_range CHECK (((rate_basis_points >= 0) AND (rate_basis_points <= 10000)))
);


--
-- Name: user_identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_identities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    provider character varying NOT NULL,
    provider_subject character varying NOT NULL,
    provider_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    verified_at timestamp with time zone,
    last_used_at timestamp with time zone,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    phone_country_code character varying NOT NULL,
    phone_number_encrypted text NOT NULL,
    phone_number_digest character varying NOT NULL,
    email_encrypted text,
    email_digest character varying,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    preferred_language character varying DEFAULT 'es'::character varying NOT NULL,
    timezone character varying DEFAULT 'America/Caracas'::character varying NOT NULL,
    status character varying DEFAULT 'pending_verification'::character varying NOT NULL,
    phone_verified_at timestamp with time zone,
    email_verified_at timestamp with time zone,
    last_login_at timestamp with time zone,
    failed_login_attempts integer DEFAULT 0 NOT NULL,
    locked_at timestamp with time zone,
    disabled_at timestamp with time zone,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    CONSTRAINT users_failed_login_attempts_non_negative CHECK ((failed_login_attempts >= 0))
);


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    courier_id uuid NOT NULL,
    vehicle_type character varying NOT NULL,
    brand character varying,
    model character varying,
    color character varying,
    plate_encrypted text,
    plate_digest character varying,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: webhook_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhook_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider character varying NOT NULL,
    provider_event_id character varying NOT NULL,
    event_type character varying,
    signature_valid boolean NOT NULL,
    payload_encrypted text NOT NULL,
    status character varying DEFAULT 'received'::character varying NOT NULL,
    received_at timestamp with time zone NOT NULL,
    processed_at timestamp with time zone,
    attempt_count integer DEFAULT 0 NOT NULL,
    last_error character varying,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    city_id uuid NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    geometry public.geography(MultiPolygon,4326) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    risk_level character varying DEFAULT 'standard'::character varying NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: audit_events audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);


--
-- Name: branches branches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_pkey PRIMARY KEY (id);


--
-- Name: business_hours business_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_hours
    ADD CONSTRAINT business_hours_pkey PRIMARY KEY (id);


--
-- Name: cart_item_modifiers cart_item_modifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item_modifiers
    ADD CONSTRAINT cart_item_modifiers_pkey PRIMARY KEY (id);


--
-- Name: cart_items cart_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_pkey PRIMARY KEY (id);


--
-- Name: carts carts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carts
    ADD CONSTRAINT carts_pkey PRIMARY KEY (id);


--
-- Name: cash_balances cash_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_balances
    ADD CONSTRAINT cash_balances_pkey PRIMARY KEY (id);


--
-- Name: cash_handovers cash_handovers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_handovers
    ADD CONSTRAINT cash_handovers_pkey PRIMARY KEY (id);


--
-- Name: catalogs catalogs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalogs
    ADD CONSTRAINT catalogs_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: cities cities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cities
    ADD CONSTRAINT cities_pkey PRIMARY KEY (id);


--
-- Name: courier_availabilities courier_availabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courier_availabilities
    ADD CONSTRAINT courier_availabilities_pkey PRIMARY KEY (id);


--
-- Name: courier_branch_assignments courier_branch_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courier_branch_assignments
    ADD CONSTRAINT courier_branch_assignments_pkey PRIMARY KEY (id);


--
-- Name: courier_documents courier_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courier_documents
    ADD CONSTRAINT courier_documents_pkey PRIMARY KEY (id);


--
-- Name: couriers couriers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.couriers
    ADD CONSTRAINT couriers_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: deliveries deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deliveries
    ADD CONSTRAINT deliveries_pkey PRIMARY KEY (id);


--
-- Name: delivery_fee_rules delivery_fee_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_fee_rules
    ADD CONSTRAINT delivery_fee_rules_pkey PRIMARY KEY (id);


--
-- Name: delivery_incidents delivery_incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_incidents
    ADD CONSTRAINT delivery_incidents_pkey PRIMARY KEY (id);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: dispatch_offers dispatch_offers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_offers
    ADD CONSTRAINT dispatch_offers_pkey PRIMARY KEY (id);


--
-- Name: domain_events domain_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domain_events
    ADD CONSTRAINT domain_events_pkey PRIMARY KEY (id);


--
-- Name: exchange_rates exchange_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (id);


--
-- Name: feature_flags feature_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags
    ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (id);


--
-- Name: fraud_signals fraud_signals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fraud_signals
    ADD CONSTRAINT fraud_signals_pkey PRIMARY KEY (id);


--
-- Name: idempotency_records idempotency_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idempotency_records
    ADD CONSTRAINT idempotency_records_pkey PRIMARY KEY (id);


--
-- Name: inventory_items inventory_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- Name: ledger_accounts ledger_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_accounts
    ADD CONSTRAINT ledger_accounts_pkey PRIMARY KEY (id);


--
-- Name: ledger_entries ledger_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT ledger_entries_pkey PRIMARY KEY (id);


--
-- Name: ledger_transactions ledger_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_transactions
    ADD CONSTRAINT ledger_transactions_pkey PRIMARY KEY (id);


--
-- Name: location_pings location_pings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_pings
    ADD CONSTRAINT location_pings_pkey PRIMARY KEY (id);


--
-- Name: merchants merchants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_pkey PRIMARY KEY (id);


--
-- Name: mobile_payment_submissions mobile_payment_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_payment_submissions
    ADD CONSTRAINT mobile_payment_submissions_pkey PRIMARY KEY (id);


--
-- Name: modifier_groups modifier_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_groups
    ADD CONSTRAINT modifier_groups_pkey PRIMARY KEY (id);


--
-- Name: modifiers modifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifiers
    ADD CONSTRAINT modifiers_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: order_item_modifiers order_item_modifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_item_modifiers
    ADD CONSTRAINT order_item_modifiers_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: order_status_histories order_status_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_status_histories
    ADD CONSTRAINT order_status_histories_pkey PRIMARY KEY (id);


--
-- Name: order_transition_requests order_transition_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_transition_requests
    ADD CONSTRAINT order_transition_requests_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: otp_challenges otp_challenges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_challenges
    ADD CONSTRAINT otp_challenges_pkey PRIMARY KEY (id);


--
-- Name: outbox_events outbox_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outbox_events
    ADD CONSTRAINT outbox_events_pkey PRIMARY KEY (id);


--
-- Name: payment_intents payment_intents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT payment_intents_pkey PRIMARY KEY (id);


--
-- Name: payment_transactions payment_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: pos_payment_records pos_payment_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_payment_records
    ADD CONSTRAINT pos_payment_records_pkey PRIMARY KEY (id);


--
-- Name: product_variants product_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_variants
    ADD CONSTRAINT product_variants_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: quotes quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_pkey PRIMARY KEY (id);


--
-- Name: reconciliation_batches reconciliation_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_batches
    ADD CONSTRAINT reconciliation_batches_pkey PRIMARY KEY (id);


--
-- Name: reconciliation_items reconciliation_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_items
    ADD CONSTRAINT reconciliation_items_pkey PRIMARY KEY (id);


--
-- Name: refunds refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_pkey PRIMARY KEY (id);


--
-- Name: risk_decisions risk_decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_decisions
    ADD CONSTRAINT risk_decisions_pkey PRIMARY KEY (id);


--
-- Name: role_assignments role_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_assignments
    ADD CONSTRAINT role_assignments_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: service_areas service_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_areas
    ADD CONSTRAINT service_areas_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: settlements settlements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_pkey PRIMARY KEY (id);


--
-- Name: special_business_hours special_business_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.special_business_hours
    ADD CONSTRAINT special_business_hours_pkey PRIMARY KEY (id);


--
-- Name: support_cases support_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_cases
    ADD CONSTRAINT support_cases_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- Name: tax_rules tax_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_rules
    ADD CONSTRAINT tax_rules_pkey PRIMARY KEY (id);


--
-- Name: user_identities user_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_identities
    ADD CONSTRAINT user_identities_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: webhook_events webhook_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_events
    ADD CONSTRAINT webhook_events_pkey PRIMARY KEY (id);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: idx_on_order_id_idempotency_key_d8d7489422; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_order_id_idempotency_key_d8d7489422 ON public.order_transition_requests USING btree (order_id, idempotency_key);


--
-- Name: idx_on_payment_intent_id_idempotency_key_675383ac2e; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_payment_intent_id_idempotency_key_675383ac2e ON public.payment_transactions USING btree (payment_intent_id, idempotency_key);


--
-- Name: idx_on_phone_digest_purpose_created_at_11442c137d; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_phone_digest_purpose_created_at_11442c137d ON public.otp_challenges USING btree (phone_digest, purpose, created_at);


--
-- Name: idx_on_terminal_owner_type_terminal_owner_id_62ec5701bd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_terminal_owner_type_terminal_owner_id_62ec5701bd ON public.pos_payment_records USING btree (terminal_owner_type, terminal_owner_id);


--
-- Name: idx_on_user_id_notification_type_2ab4363e9b; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_user_id_notification_type_2ab4363e9b ON public.notification_preferences USING btree (user_id, notification_type);


--
-- Name: index_addresses_on_city_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_city_id ON public.addresses USING btree (city_id);


--
-- Name: index_addresses_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_customer_id ON public.addresses USING btree (customer_id);


--
-- Name: index_addresses_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_location ON public.addresses USING gist (location);


--
-- Name: index_addresses_one_default_per_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_addresses_one_default_per_customer ON public.addresses USING btree (customer_id) WHERE is_default;


--
-- Name: index_audit_events_on_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_action ON public.audit_events USING btree (action);


--
-- Name: index_audit_events_on_actor_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_actor_user_id ON public.audit_events USING btree (actor_user_id);


--
-- Name: index_audit_events_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_branch_id ON public.audit_events USING btree (branch_id);


--
-- Name: index_audit_events_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_organization_id ON public.audit_events USING btree (organization_id);


--
-- Name: index_audit_events_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_resource_type_and_resource_id ON public.audit_events USING btree (resource_type, resource_id);


--
-- Name: index_branches_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_branches_on_location ON public.branches USING gist (location);


--
-- Name: index_branches_on_merchant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_branches_on_merchant_id ON public.branches USING btree (merchant_id);


--
-- Name: index_branches_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_branches_on_organization_id ON public.branches USING btree (organization_id);


--
-- Name: index_branches_on_organization_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_branches_on_organization_id_and_slug ON public.branches USING btree (organization_id, slug);


--
-- Name: index_branches_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_branches_on_status ON public.branches USING btree (status);


--
-- Name: index_business_hours_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_business_hours_on_branch_id ON public.business_hours USING btree (branch_id);


--
-- Name: index_business_hours_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_business_hours_uniqueness ON public.business_hours USING btree (branch_id, day_of_week, opens_at);


--
-- Name: index_cart_item_modifiers_on_cart_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cart_item_modifiers_on_cart_item_id ON public.cart_item_modifiers USING btree (cart_item_id);


--
-- Name: index_cart_item_modifiers_on_modifier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cart_item_modifiers_on_modifier_id ON public.cart_item_modifiers USING btree (modifier_id);


--
-- Name: index_cart_items_on_cart_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cart_items_on_cart_id ON public.cart_items USING btree (cart_id);


--
-- Name: index_cart_items_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cart_items_on_product_id ON public.cart_items USING btree (product_id);


--
-- Name: index_cart_items_on_product_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cart_items_on_product_variant_id ON public.cart_items USING btree (product_variant_id);


--
-- Name: index_carts_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_carts_on_branch_id ON public.carts USING btree (branch_id);


--
-- Name: index_carts_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_carts_on_customer_id ON public.carts USING btree (customer_id);


--
-- Name: index_carts_one_active_per_customer_and_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_carts_one_active_per_customer_and_branch ON public.carts USING btree (customer_id, branch_id) WHERE ((status)::text = 'active'::text);


--
-- Name: index_cash_balances_on_courier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_balances_on_courier_id ON public.cash_balances USING btree (courier_id);


--
-- Name: index_cash_balances_on_courier_id_and_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cash_balances_on_courier_id_and_currency ON public.cash_balances USING btree (courier_id, currency);


--
-- Name: index_cash_handovers_on_courier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_handovers_on_courier_id ON public.cash_handovers USING btree (courier_id);


--
-- Name: index_cash_handovers_on_courier_id_and_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cash_handovers_on_courier_id_and_idempotency_key ON public.cash_handovers USING btree (courier_id, idempotency_key);


--
-- Name: index_cash_handovers_on_received_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_handovers_on_received_by_user_id ON public.cash_handovers USING btree (received_by_user_id);


--
-- Name: index_cash_handovers_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_handovers_on_status ON public.cash_handovers USING btree (status);


--
-- Name: index_catalogs_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalogs_on_branch_id ON public.catalogs USING btree (branch_id);


--
-- Name: index_categories_on_catalog_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_catalog_id ON public.categories USING btree (catalog_id);


--
-- Name: index_categories_on_parent_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_parent_category_id ON public.categories USING btree (parent_category_id);


--
-- Name: index_cities_on_name_and_state_name_and_country_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cities_on_name_and_state_name_and_country_code ON public.cities USING btree (name, state_name, country_code);


--
-- Name: index_courier_availabilities_on_courier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courier_availabilities_on_courier_id ON public.courier_availabilities USING btree (courier_id);


--
-- Name: index_courier_availabilities_on_open_window; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_courier_availabilities_on_open_window ON public.courier_availabilities USING btree (courier_id) WHERE (ended_at IS NULL);


--
-- Name: index_courier_availabilities_on_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courier_availabilities_on_zone_id ON public.courier_availabilities USING btree (zone_id);


--
-- Name: index_courier_branch_assignments_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courier_branch_assignments_on_branch_id ON public.courier_branch_assignments USING btree (branch_id);


--
-- Name: index_courier_branch_assignments_on_courier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courier_branch_assignments_on_courier_id ON public.courier_branch_assignments USING btree (courier_id);


--
-- Name: index_courier_branch_assignments_on_courier_id_and_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courier_branch_assignments_on_courier_id_and_branch_id ON public.courier_branch_assignments USING btree (courier_id, branch_id);


--
-- Name: index_courier_documents_on_courier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courier_documents_on_courier_id ON public.courier_documents USING btree (courier_id);


--
-- Name: index_courier_documents_on_document_number_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courier_documents_on_document_number_digest ON public.courier_documents USING btree (document_number_digest);


--
-- Name: index_courier_documents_on_reviewed_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courier_documents_on_reviewed_by_user_id ON public.courier_documents USING btree (reviewed_by_user_id);


--
-- Name: index_courier_documents_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courier_documents_on_status ON public.courier_documents USING btree (status);


--
-- Name: index_couriers_on_approval_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_couriers_on_approval_status ON public.couriers USING btree (approval_status);


--
-- Name: index_couriers_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_couriers_on_organization_id ON public.couriers USING btree (organization_id);


--
-- Name: index_couriers_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_couriers_on_status ON public.couriers USING btree (status);


--
-- Name: index_couriers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_couriers_on_user_id ON public.couriers USING btree (user_id);


--
-- Name: index_customers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_customers_on_user_id ON public.customers USING btree (user_id);


--
-- Name: index_deliveries_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_branch_id ON public.deliveries USING btree (branch_id);


--
-- Name: index_deliveries_on_courier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_courier_id ON public.deliveries USING btree (courier_id);


--
-- Name: index_deliveries_on_dropoff_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_dropoff_location ON public.deliveries USING gist (dropoff_location);


--
-- Name: index_deliveries_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_deliveries_on_order_id ON public.deliveries USING btree (order_id);


--
-- Name: index_deliveries_on_pickup_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_pickup_location ON public.deliveries USING gist (pickup_location);


--
-- Name: index_deliveries_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_status ON public.deliveries USING btree (status);


--
-- Name: index_delivery_fee_rules_on_city_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_fee_rules_on_city_id ON public.delivery_fee_rules USING btree (city_id);


--
-- Name: index_delivery_fee_rules_on_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_fee_rules_on_zone_id ON public.delivery_fee_rules USING btree (zone_id);


--
-- Name: index_delivery_incidents_on_delivery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_incidents_on_delivery_id ON public.delivery_incidents USING btree (delivery_id);


--
-- Name: index_delivery_incidents_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_incidents_on_order_id ON public.delivery_incidents USING btree (order_id);


--
-- Name: index_delivery_incidents_on_reported_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_incidents_on_reported_by_user_id ON public.delivery_incidents USING btree (reported_by_user_id);


--
-- Name: index_delivery_incidents_on_resolved_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_incidents_on_resolved_by_user_id ON public.delivery_incidents USING btree (resolved_by_user_id);


--
-- Name: index_delivery_incidents_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_incidents_on_status ON public.delivery_incidents USING btree (status);


--
-- Name: index_devices_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_devices_on_user_id ON public.devices USING btree (user_id);


--
-- Name: index_devices_on_user_id_and_installation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_devices_on_user_id_and_installation_id ON public.devices USING btree (user_id, installation_id);


--
-- Name: index_dispatch_offers_on_accepted_delivery; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_dispatch_offers_on_accepted_delivery ON public.dispatch_offers USING btree (delivery_id) WHERE ((status)::text = 'accepted'::text);


--
-- Name: index_dispatch_offers_on_courier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dispatch_offers_on_courier_id ON public.dispatch_offers USING btree (courier_id);


--
-- Name: index_dispatch_offers_on_delivery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dispatch_offers_on_delivery_id ON public.dispatch_offers USING btree (delivery_id);


--
-- Name: index_dispatch_offers_on_delivery_id_and_courier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dispatch_offers_on_delivery_id_and_courier_id ON public.dispatch_offers USING btree (delivery_id, courier_id);


--
-- Name: index_dispatch_offers_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dispatch_offers_on_status ON public.dispatch_offers USING btree (status);


--
-- Name: index_domain_events_on_aggregate_type_and_aggregate_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_domain_events_on_aggregate_type_and_aggregate_id ON public.domain_events USING btree (aggregate_type, aggregate_id);


--
-- Name: index_domain_events_on_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_domain_events_on_correlation_id ON public.domain_events USING btree (correlation_id);


--
-- Name: index_domain_events_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_domain_events_on_event_type ON public.domain_events USING btree (event_type);


--
-- Name: index_exchange_rates_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchange_rates_on_created_by_user_id ON public.exchange_rates USING btree (created_by_user_id);


--
-- Name: index_exchange_rates_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_exchange_rates_uniqueness ON public.exchange_rates USING btree (base_currency, quote_currency, effective_at, rate_type);


--
-- Name: index_feature_flags_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feature_flags_on_created_by_user_id ON public.feature_flags USING btree (created_by_user_id);


--
-- Name: index_feature_flags_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_feature_flags_on_key ON public.feature_flags USING btree (key);


--
-- Name: index_feature_flags_on_updated_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feature_flags_on_updated_by_user_id ON public.feature_flags USING btree (updated_by_user_id);


--
-- Name: index_fraud_signals_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fraud_signals_on_order_id ON public.fraud_signals USING btree (order_id);


--
-- Name: index_fraud_signals_on_payment_intent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fraud_signals_on_payment_intent_id ON public.fraud_signals USING btree (payment_intent_id);


--
-- Name: index_fraud_signals_on_signal_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fraud_signals_on_signal_type ON public.fraud_signals USING btree (signal_type);


--
-- Name: index_fraud_signals_on_subject_type_and_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fraud_signals_on_subject_type_and_subject_id ON public.fraud_signals USING btree (subject_type, subject_id);


--
-- Name: index_idempotency_records_on_actor_and_operation_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_idempotency_records_on_actor_and_operation_and_key ON public.idempotency_records USING btree (actor_type, actor_id, operation, key);


--
-- Name: index_inventory_items_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_branch_id ON public.inventory_items USING btree (branch_id);


--
-- Name: index_inventory_items_on_branch_id_and_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_inventory_items_on_branch_id_and_product_id ON public.inventory_items USING btree (branch_id, product_id) WHERE (product_id IS NOT NULL);


--
-- Name: index_inventory_items_on_branch_id_and_product_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_inventory_items_on_branch_id_and_product_variant_id ON public.inventory_items USING btree (branch_id, product_variant_id) WHERE (product_variant_id IS NOT NULL);


--
-- Name: index_inventory_items_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_product_id ON public.inventory_items USING btree (product_id);


--
-- Name: index_inventory_items_on_product_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_product_variant_id ON public.inventory_items USING btree (product_variant_id);


--
-- Name: index_inventory_items_on_updated_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_updated_by_user_id ON public.inventory_items USING btree (updated_by_user_id);


--
-- Name: index_ledger_accounts_on_account_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ledger_accounts_on_account_code ON public.ledger_accounts USING btree (account_code);


--
-- Name: index_ledger_accounts_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_accounts_on_organization_id ON public.ledger_accounts USING btree (organization_id);


--
-- Name: index_ledger_accounts_on_owner_type_and_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_accounts_on_owner_type_and_owner_id ON public.ledger_accounts USING btree (owner_type, owner_id);


--
-- Name: index_ledger_entries_on_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_entries_on_direction ON public.ledger_entries USING btree (direction);


--
-- Name: index_ledger_entries_on_ledger_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_entries_on_ledger_account_id ON public.ledger_entries USING btree (ledger_account_id);


--
-- Name: index_ledger_entries_on_ledger_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_entries_on_ledger_transaction_id ON public.ledger_entries USING btree (ledger_transaction_id);


--
-- Name: index_ledger_transactions_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_transactions_on_created_by_user_id ON public.ledger_transactions USING btree (created_by_user_id);


--
-- Name: index_ledger_transactions_on_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ledger_transactions_on_idempotency_key ON public.ledger_transactions USING btree (idempotency_key);


--
-- Name: index_ledger_transactions_on_reference_type_and_reference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_transactions_on_reference_type_and_reference_id ON public.ledger_transactions USING btree (reference_type, reference_id);


--
-- Name: index_ledger_transactions_on_reversal_of_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ledger_transactions_on_reversal_of_transaction_id ON public.ledger_transactions USING btree (reversal_of_transaction_id);


--
-- Name: index_location_pings_on_courier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_pings_on_courier_id ON public.location_pings USING btree (courier_id);


--
-- Name: index_location_pings_on_courier_id_and_server_received_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_pings_on_courier_id_and_server_received_at ON public.location_pings USING btree (courier_id, server_received_at);


--
-- Name: index_location_pings_on_delivery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_pings_on_delivery_id ON public.location_pings USING btree (delivery_id);


--
-- Name: index_location_pings_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_location_pings_on_location ON public.location_pings USING gist (location);


--
-- Name: index_merchants_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merchants_on_organization_id ON public.merchants USING btree (organization_id);


--
-- Name: index_merchants_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_merchants_on_slug ON public.merchants USING btree (slug);


--
-- Name: index_merchants_on_vertical; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merchants_on_vertical ON public.merchants USING btree (vertical);


--
-- Name: index_mobile_payment_submissions_on_duplicate_of_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mobile_payment_submissions_on_duplicate_of_submission_id ON public.mobile_payment_submissions USING btree (duplicate_of_submission_id);


--
-- Name: index_mobile_payment_submissions_on_payment_intent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mobile_payment_submissions_on_payment_intent_id ON public.mobile_payment_submissions USING btree (payment_intent_id);


--
-- Name: index_mobile_payment_submissions_on_reference_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mobile_payment_submissions_on_reference_digest ON public.mobile_payment_submissions USING btree (reference_digest);


--
-- Name: index_mobile_payment_submissions_on_review_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mobile_payment_submissions_on_review_status ON public.mobile_payment_submissions USING btree (review_status);


--
-- Name: index_mobile_payment_submissions_on_reviewed_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mobile_payment_submissions_on_reviewed_by_user_id ON public.mobile_payment_submissions USING btree (reviewed_by_user_id);


--
-- Name: index_modifier_groups_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_modifier_groups_on_product_id ON public.modifier_groups USING btree (product_id);


--
-- Name: index_modifiers_on_modifier_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_modifiers_on_modifier_group_id ON public.modifiers USING btree (modifier_group_id);


--
-- Name: index_notification_preferences_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_preferences_on_user_id ON public.notification_preferences USING btree (user_id);


--
-- Name: index_notifications_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_order_id ON public.notifications USING btree (order_id);


--
-- Name: index_notifications_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_status ON public.notifications USING btree (status);


--
-- Name: index_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_user_id ON public.notifications USING btree (user_id);


--
-- Name: index_notifications_on_user_id_and_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notifications_on_user_id_and_idempotency_key ON public.notifications USING btree (user_id, idempotency_key);


--
-- Name: index_order_item_modifiers_on_order_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_item_modifiers_on_order_item_id ON public.order_item_modifiers USING btree (order_item_id);


--
-- Name: index_order_item_modifiers_on_source_modifier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_item_modifiers_on_source_modifier_id ON public.order_item_modifiers USING btree (source_modifier_id);


--
-- Name: index_order_items_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_items_on_order_id ON public.order_items USING btree (order_id);


--
-- Name: index_order_items_on_source_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_items_on_source_product_id ON public.order_items USING btree (source_product_id);


--
-- Name: index_order_items_on_source_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_items_on_source_variant_id ON public.order_items USING btree (source_variant_id);


--
-- Name: index_order_status_histories_on_actor_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_status_histories_on_actor_user_id ON public.order_status_histories USING btree (actor_user_id);


--
-- Name: index_order_status_histories_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_status_histories_on_order_id ON public.order_status_histories USING btree (order_id);


--
-- Name: index_order_status_histories_on_order_id_and_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_status_histories_on_order_id_and_occurred_at ON public.order_status_histories USING btree (order_id, occurred_at);


--
-- Name: index_order_transition_requests_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_transition_requests_on_order_id ON public.order_transition_requests USING btree (order_id);


--
-- Name: index_order_transition_requests_on_requested_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_transition_requests_on_requested_by_user_id ON public.order_transition_requests USING btree (requested_by_user_id);


--
-- Name: index_orders_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_address_id ON public.orders USING btree (address_id);


--
-- Name: index_orders_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_branch_id ON public.orders USING btree (branch_id);


--
-- Name: index_orders_on_current_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_current_status ON public.orders USING btree (current_status);


--
-- Name: index_orders_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_customer_id ON public.orders USING btree (customer_id);


--
-- Name: index_orders_on_customer_id_and_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orders_on_customer_id_and_idempotency_key ON public.orders USING btree (customer_id, idempotency_key);


--
-- Name: index_orders_on_delivery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orders_on_delivery_id ON public.orders USING btree (delivery_id) WHERE (delivery_id IS NOT NULL);


--
-- Name: index_orders_on_exchange_rate_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_exchange_rate_id ON public.orders USING btree (exchange_rate_id);


--
-- Name: index_orders_on_merchant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_merchant_id ON public.orders USING btree (merchant_id);


--
-- Name: index_orders_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_organization_id ON public.orders USING btree (organization_id);


--
-- Name: index_orders_on_public_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orders_on_public_number ON public.orders USING btree (public_number);


--
-- Name: index_orders_on_quote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_quote_id ON public.orders USING btree (quote_id);


--
-- Name: index_organizations_on_organization_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organizations_on_organization_type ON public.organizations USING btree (organization_type);


--
-- Name: index_organizations_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organizations_on_status ON public.organizations USING btree (status);


--
-- Name: index_organizations_on_tax_identifier_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on_tax_identifier_digest ON public.organizations USING btree (tax_identifier_digest) WHERE (tax_identifier_digest IS NOT NULL);


--
-- Name: index_outbox_events_on_status_and_available_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outbox_events_on_status_and_available_at ON public.outbox_events USING btree (status, available_at);


--
-- Name: index_payment_intents_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_intents_on_customer_id ON public.payment_intents USING btree (customer_id);


--
-- Name: index_payment_intents_on_customer_id_and_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payment_intents_on_customer_id_and_idempotency_key ON public.payment_intents USING btree (customer_id, idempotency_key);


--
-- Name: index_payment_intents_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payment_intents_on_order_id ON public.payment_intents USING btree (order_id);


--
-- Name: index_payment_intents_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_intents_on_status ON public.payment_intents USING btree (status);


--
-- Name: index_payment_transactions_on_payment_intent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_transactions_on_payment_intent_id ON public.payment_transactions USING btree (payment_intent_id);


--
-- Name: index_payment_transactions_on_provider_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payment_transactions_on_provider_transaction_id ON public.payment_transactions USING btree (provider_transaction_id) WHERE (provider_transaction_id IS NOT NULL);


--
-- Name: index_permissions_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_permissions_on_code ON public.permissions USING btree (code);


--
-- Name: index_permissions_on_resource_and_action; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_permissions_on_resource_and_action ON public.permissions USING btree (resource, action);


--
-- Name: index_pos_payment_records_on_confirmed_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pos_payment_records_on_confirmed_by_user_id ON public.pos_payment_records USING btree (confirmed_by_user_id);


--
-- Name: index_pos_payment_records_on_payment_intent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pos_payment_records_on_payment_intent_id ON public.pos_payment_records USING btree (payment_intent_id);


--
-- Name: index_product_variants_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_variants_on_product_id ON public.product_variants USING btree (product_id);


--
-- Name: index_product_variants_on_product_id_and_sku; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_variants_on_product_id_and_sku ON public.product_variants USING btree (product_id, sku);


--
-- Name: index_products_on_catalog_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_catalog_id ON public.products USING btree (catalog_id);


--
-- Name: index_products_on_catalog_id_and_sku; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_products_on_catalog_id_and_sku ON public.products USING btree (catalog_id, sku);


--
-- Name: index_products_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_category_id ON public.products USING btree (category_id);


--
-- Name: index_products_on_tax_rule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_tax_rule_id ON public.products USING btree (tax_rule_id);


--
-- Name: index_quotes_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quotes_on_address_id ON public.quotes USING btree (address_id);


--
-- Name: index_quotes_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quotes_on_branch_id ON public.quotes USING btree (branch_id);


--
-- Name: index_quotes_on_cart_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quotes_on_cart_id ON public.quotes USING btree (cart_id);


--
-- Name: index_quotes_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quotes_on_customer_id ON public.quotes USING btree (customer_id);


--
-- Name: index_quotes_on_customer_id_and_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_quotes_on_customer_id_and_idempotency_key ON public.quotes USING btree (customer_id, idempotency_key);


--
-- Name: index_quotes_on_exchange_rate_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quotes_on_exchange_rate_id ON public.quotes USING btree (exchange_rate_id);


--
-- Name: index_reconciliation_batches_on_completed_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reconciliation_batches_on_completed_by_user_id ON public.reconciliation_batches USING btree (completed_by_user_id);


--
-- Name: index_reconciliation_batches_on_started_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reconciliation_batches_on_started_by_user_id ON public.reconciliation_batches USING btree (started_by_user_id);


--
-- Name: index_reconciliation_batches_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reconciliation_batches_on_status ON public.reconciliation_batches USING btree (status);


--
-- Name: index_reconciliation_items_on_payment_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reconciliation_items_on_payment_transaction_id ON public.reconciliation_items USING btree (payment_transaction_id);


--
-- Name: index_reconciliation_items_on_reconciliation_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reconciliation_items_on_reconciliation_batch_id ON public.reconciliation_items USING btree (reconciliation_batch_id);


--
-- Name: index_reconciliation_items_on_resolved_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reconciliation_items_on_resolved_by_user_id ON public.reconciliation_items USING btree (resolved_by_user_id);


--
-- Name: index_reconciliation_items_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reconciliation_items_on_status ON public.reconciliation_items USING btree (status);


--
-- Name: index_refunds_on_approved_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refunds_on_approved_by_user_id ON public.refunds USING btree (approved_by_user_id);


--
-- Name: index_refunds_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refunds_on_order_id ON public.refunds USING btree (order_id);


--
-- Name: index_refunds_on_order_id_and_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_refunds_on_order_id_and_idempotency_key ON public.refunds USING btree (order_id, idempotency_key);


--
-- Name: index_refunds_on_payment_intent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refunds_on_payment_intent_id ON public.refunds USING btree (payment_intent_id);


--
-- Name: index_refunds_on_requested_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refunds_on_requested_by_user_id ON public.refunds USING btree (requested_by_user_id);


--
-- Name: index_refunds_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refunds_on_status ON public.refunds USING btree (status);


--
-- Name: index_risk_decisions_on_decision; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_risk_decisions_on_decision ON public.risk_decisions USING btree (decision);


--
-- Name: index_risk_decisions_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_risk_decisions_on_order_id ON public.risk_decisions USING btree (order_id);


--
-- Name: index_risk_decisions_on_reviewed_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_risk_decisions_on_reviewed_by_user_id ON public.risk_decisions USING btree (reviewed_by_user_id);


--
-- Name: index_risk_decisions_on_subject_type_and_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_risk_decisions_on_subject_type_and_subject_id ON public.risk_decisions USING btree (subject_type, subject_id);


--
-- Name: index_role_assignments_on_active_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_role_assignments_on_active_scope ON public.role_assignments USING btree (user_id, role_id, organization_id, branch_id) WHERE (revoked_at IS NULL);


--
-- Name: index_role_assignments_on_assigned_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_assignments_on_assigned_by_user_id ON public.role_assignments USING btree (assigned_by_user_id);


--
-- Name: index_role_assignments_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_assignments_on_branch_id ON public.role_assignments USING btree (branch_id);


--
-- Name: index_role_assignments_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_assignments_on_organization_id ON public.role_assignments USING btree (organization_id);


--
-- Name: index_role_assignments_on_revoked_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_assignments_on_revoked_by_user_id ON public.role_assignments USING btree (revoked_by_user_id);


--
-- Name: index_role_assignments_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_assignments_on_role_id ON public.role_assignments USING btree (role_id);


--
-- Name: index_role_assignments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_assignments_on_user_id ON public.role_assignments USING btree (user_id);


--
-- Name: index_role_permissions_on_permission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_permissions_on_permission_id ON public.role_permissions USING btree (permission_id);


--
-- Name: index_role_permissions_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_permissions_on_role_id ON public.role_permissions USING btree (role_id);


--
-- Name: index_role_permissions_on_role_id_and_permission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_role_permissions_on_role_id_and_permission_id ON public.role_permissions USING btree (role_id, permission_id);


--
-- Name: index_roles_on_code_when_global; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_roles_on_code_when_global ON public.roles USING btree (code) WHERE (organization_id IS NULL);


--
-- Name: index_roles_on_organization_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_roles_on_organization_id_and_code ON public.roles USING btree (organization_id, code) WHERE (organization_id IS NOT NULL);


--
-- Name: index_service_areas_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_areas_on_branch_id ON public.service_areas USING btree (branch_id);


--
-- Name: index_service_areas_on_city_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_areas_on_city_id ON public.service_areas USING btree (city_id);


--
-- Name: index_service_areas_on_geometry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_areas_on_geometry ON public.service_areas USING gist (geometry);


--
-- Name: index_sessions_on_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_device_id ON public.sessions USING btree (device_id);


--
-- Name: index_sessions_on_refresh_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_refresh_token_digest ON public.sessions USING btree (refresh_token_digest);


--
-- Name: index_sessions_on_rotated_from_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_rotated_from_session_id ON public.sessions USING btree (rotated_from_session_id);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_settlements_on_approved_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_settlements_on_approved_by_user_id ON public.settlements USING btree (approved_by_user_id);


--
-- Name: index_settlements_on_beneficiary_type_and_beneficiary_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_settlements_on_beneficiary_type_and_beneficiary_id ON public.settlements USING btree (beneficiary_type, beneficiary_id);


--
-- Name: index_settlements_on_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settlements_on_idempotency_key ON public.settlements USING btree (idempotency_key);


--
-- Name: index_settlements_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_settlements_on_status ON public.settlements USING btree (status);


--
-- Name: index_special_business_hours_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_special_business_hours_on_branch_id ON public.special_business_hours USING btree (branch_id);


--
-- Name: index_special_business_hours_on_branch_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_special_business_hours_on_branch_id_and_date ON public.special_business_hours USING btree (branch_id, date);


--
-- Name: index_support_cases_on_assigned_to_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_support_cases_on_assigned_to_user_id ON public.support_cases USING btree (assigned_to_user_id);


--
-- Name: index_support_cases_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_support_cases_on_customer_id ON public.support_cases USING btree (customer_id);


--
-- Name: index_support_cases_on_delivery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_support_cases_on_delivery_id ON public.support_cases USING btree (delivery_id);


--
-- Name: index_support_cases_on_opened_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_support_cases_on_opened_by_user_id ON public.support_cases USING btree (opened_by_user_id);


--
-- Name: index_support_cases_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_support_cases_on_order_id ON public.support_cases USING btree (order_id);


--
-- Name: index_support_cases_on_public_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_support_cases_on_public_number ON public.support_cases USING btree (public_number);


--
-- Name: index_support_cases_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_support_cases_on_status ON public.support_cases USING btree (status);


--
-- Name: index_system_settings_on_scope_and_key_and_version; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_system_settings_on_scope_and_key_and_version ON public.system_settings USING btree (scope_type, scope_id, key, version);


--
-- Name: index_system_settings_on_updated_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_system_settings_on_updated_by_user_id ON public.system_settings USING btree (updated_by_user_id);


--
-- Name: index_tax_rules_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_rules_on_organization_id ON public.tax_rules USING btree (organization_id);


--
-- Name: index_user_identities_on_provider_and_provider_subject; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_identities_on_provider_and_provider_subject ON public.user_identities USING btree (provider, provider_subject);


--
-- Name: index_user_identities_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_identities_on_user_id ON public.user_identities USING btree (user_id);


--
-- Name: index_users_on_email_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_digest ON public.users USING btree (email_digest) WHERE (email_digest IS NOT NULL);


--
-- Name: index_users_on_phone_number_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_phone_number_digest ON public.users USING btree (phone_number_digest);


--
-- Name: index_users_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_status ON public.users USING btree (status);


--
-- Name: index_vehicles_on_courier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicles_on_courier_id ON public.vehicles USING btree (courier_id);


--
-- Name: index_vehicles_on_plate_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vehicles_on_plate_digest ON public.vehicles USING btree (plate_digest);


--
-- Name: index_webhook_events_on_provider_and_provider_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_webhook_events_on_provider_and_provider_event_id ON public.webhook_events USING btree (provider, provider_event_id);


--
-- Name: index_webhook_events_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhook_events_on_status ON public.webhook_events USING btree (status);


--
-- Name: index_zones_on_city_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zones_on_city_id ON public.zones USING btree (city_id);


--
-- Name: index_zones_on_city_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_zones_on_city_id_and_code ON public.zones USING btree (city_id, code);


--
-- Name: index_zones_on_geometry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zones_on_geometry ON public.zones USING gist (geometry);


--
-- Name: role_assignments fk_rails_0058c8fdb3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_assignments
    ADD CONSTRAINT fk_rails_0058c8fdb3 FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT;


--
-- Name: ledger_accounts fk_rails_022c225858; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_accounts
    ADD CONSTRAINT fk_rails_022c225858 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: audit_events fk_rails_0242d0f1e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT fk_rails_0242d0f1e0 FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: location_pings fk_rails_04930166aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_pings
    ADD CONSTRAINT fk_rails_04930166aa FOREIGN KEY (courier_id) REFERENCES public.couriers(id);


--
-- Name: deliveries fk_rails_0557fe5297; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deliveries
    ADD CONSTRAINT fk_rails_0557fe5297 FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: refunds fk_rails_0585533fe2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT fk_rails_0585533fe2 FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: role_assignments fk_rails_07a886715c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_assignments
    ADD CONSTRAINT fk_rails_07a886715c FOREIGN KEY (revoked_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: courier_branch_assignments fk_rails_07d5f97fc3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courier_branch_assignments
    ADD CONSTRAINT fk_rails_07d5f97fc3 FOREIGN KEY (courier_id) REFERENCES public.couriers(id);


--
-- Name: refunds fk_rails_087b6e5c8b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT fk_rails_087b6e5c8b FOREIGN KEY (payment_intent_id) REFERENCES public.payment_intents(id);


--
-- Name: order_transition_requests fk_rails_09f3923684; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_transition_requests
    ADD CONSTRAINT fk_rails_09f3923684 FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE RESTRICT;


--
-- Name: inventory_items fk_rails_0c6f012f57; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT fk_rails_0c6f012f57 FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: settlements fk_rails_0d1f255be8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT fk_rails_0d1f255be8 FOREIGN KEY (approved_by_user_id) REFERENCES public.users(id);


--
-- Name: orders fk_rails_1172a46d74; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_1172a46d74 FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT;


--
-- Name: modifier_groups fk_rails_15bde0f080; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_groups
    ADD CONSTRAINT fk_rails_15bde0f080 FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: quotes fk_rails_16d0e8335d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT fk_rails_16d0e8335d FOREIGN KEY (exchange_rate_id) REFERENCES public.exchange_rates(id);


--
-- Name: delivery_fee_rules fk_rails_20a5c6ac89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_fee_rules
    ADD CONSTRAINT fk_rails_20a5c6ac89 FOREIGN KEY (city_id) REFERENCES public.cities(id);


--
-- Name: delivery_incidents fk_rails_21283e0247; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_incidents
    ADD CONSTRAINT fk_rails_21283e0247 FOREIGN KEY (reported_by_user_id) REFERENCES public.users(id);


--
-- Name: mobile_payment_submissions fk_rails_21abc6fd89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_payment_submissions
    ADD CONSTRAINT fk_rails_21abc6fd89 FOREIGN KEY (reviewed_by_user_id) REFERENCES public.users(id);


--
-- Name: fraud_signals fk_rails_21fc49b1b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fraud_signals
    ADD CONSTRAINT fk_rails_21fc49b1b9 FOREIGN KEY (payment_intent_id) REFERENCES public.payment_intents(id);


--
-- Name: catalogs fk_rails_2236035560; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalogs
    ADD CONSTRAINT fk_rails_2236035560 FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: mobile_payment_submissions fk_rails_2693a882cc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_payment_submissions
    ADD CONSTRAINT fk_rails_2693a882cc FOREIGN KEY (payment_intent_id) REFERENCES public.payment_intents(id);


--
-- Name: couriers fk_rails_26c7728c04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.couriers
    ADD CONSTRAINT fk_rails_26c7728c04 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: orders fk_rails_27f9662e04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_27f9662e04 FOREIGN KEY (quote_id) REFERENCES public.quotes(id) ON DELETE RESTRICT;


--
-- Name: order_items fk_rails_2a487acc86; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fk_rails_2a487acc86 FOREIGN KEY (source_product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: order_status_histories fk_rails_2b161b5f6d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_status_histories
    ADD CONSTRAINT fk_rails_2b161b5f6d FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE RESTRICT;


--
-- Name: audit_events fk_rails_2e3720791c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT fk_rails_2e3720791c FOREIGN KEY (actor_user_id) REFERENCES public.users(id);


--
-- Name: roles fk_rails_2f99738edd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT fk_rails_2f99738edd FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE RESTRICT;


--
-- Name: special_business_hours fk_rails_300fdd3560; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.special_business_hours
    ADD CONSTRAINT fk_rails_300fdd3560 FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: order_status_histories fk_rails_33cd1beb67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_status_histories
    ADD CONSTRAINT fk_rails_33cd1beb67 FOREIGN KEY (actor_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: courier_availabilities fk_rails_36d8038da9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courier_availabilities
    ADD CONSTRAINT fk_rails_36d8038da9 FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: role_assignments fk_rails_373c2f5151; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_assignments
    ADD CONSTRAINT fk_rails_373c2f5151 FOREIGN KEY (assigned_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: cash_handovers fk_rails_38230da54f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_handovers
    ADD CONSTRAINT fk_rails_38230da54f FOREIGN KEY (received_by_user_id) REFERENCES public.users(id);


--
-- Name: business_hours fk_rails_3ae99539d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_hours
    ADD CONSTRAINT fk_rails_3ae99539d3 FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: system_settings fk_rails_3d4f8959e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT fk_rails_3d4f8959e7 FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id);


--
-- Name: cart_item_modifiers fk_rails_3daba72fa7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item_modifiers
    ADD CONSTRAINT fk_rails_3daba72fa7 FOREIGN KEY (modifier_id) REFERENCES public.modifiers(id);


--
-- Name: orders fk_rails_3dad120da9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_3dad120da9 FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE RESTRICT;


--
-- Name: deliveries fk_rails_3eba625948; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deliveries
    ADD CONSTRAINT fk_rails_3eba625948 FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: risk_decisions fk_rails_40e4f43cbe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_decisions
    ADD CONSTRAINT fk_rails_40e4f43cbe FOREIGN KEY (reviewed_by_user_id) REFERENCES public.users(id);


--
-- Name: devices fk_rails_410b63ef65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT fk_rails_410b63ef65 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: orders fk_rails_412cc65b8b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_412cc65b8b FOREIGN KEY (merchant_id) REFERENCES public.merchants(id) ON DELETE RESTRICT;


--
-- Name: dispatch_offers fk_rails_41f38f6d1a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_offers
    ADD CONSTRAINT fk_rails_41f38f6d1a FOREIGN KEY (delivery_id) REFERENCES public.deliveries(id);


--
-- Name: feature_flags fk_rails_42c3909528; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags
    ADD CONSTRAINT fk_rails_42c3909528 FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id);


--
-- Name: role_permissions fk_rails_439e640a3f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT fk_rails_439e640a3f FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: reconciliation_items fk_rails_458941eb10; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_items
    ADD CONSTRAINT fk_rails_458941eb10 FOREIGN KEY (payment_transaction_id) REFERENCES public.payment_transactions(id);


--
-- Name: inventory_items fk_rails_48ddeb658c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT fk_rails_48ddeb658c FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: pos_payment_records fk_rails_491d151c8d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_payment_records
    ADD CONSTRAINT fk_rails_491d151c8d FOREIGN KEY (payment_intent_id) REFERENCES public.payment_intents(id);


--
-- Name: courier_documents fk_rails_4a7131aafb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courier_documents
    ADD CONSTRAINT fk_rails_4a7131aafb FOREIGN KEY (reviewed_by_user_id) REFERENCES public.users(id);


--
-- Name: cash_balances fk_rails_4b52916f22; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_balances
    ADD CONSTRAINT fk_rails_4b52916f22 FOREIGN KEY (courier_id) REFERENCES public.couriers(id);


--
-- Name: carts fk_rails_4b74985b3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carts
    ADD CONSTRAINT fk_rails_4b74985b3d FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: products fk_rails_4b89e3ebbb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_rails_4b89e3ebbb FOREIGN KEY (catalog_id) REFERENCES public.catalogs(id);


--
-- Name: support_cases fk_rails_4cb1a4451b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_cases
    ADD CONSTRAINT fk_rails_4cb1a4451b FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: ledger_transactions fk_rails_4d3874d077; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_transactions
    ADD CONSTRAINT fk_rails_4d3874d077 FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: vehicles fk_rails_4e457adf26; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT fk_rails_4e457adf26 FOREIGN KEY (courier_id) REFERENCES public.couriers(id);


--
-- Name: delivery_incidents fk_rails_4f2b6e6274; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_incidents
    ADD CONSTRAINT fk_rails_4f2b6e6274 FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: cart_item_modifiers fk_rails_506772ae83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item_modifiers
    ADD CONSTRAINT fk_rails_506772ae83 FOREIGN KEY (cart_item_id) REFERENCES public.cart_items(id) ON DELETE CASCADE;


--
-- Name: fraud_signals fk_rails_5235cc345a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fraud_signals
    ADD CONSTRAINT fk_rails_5235cc345a FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: deliveries fk_rails_548a575cd2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deliveries
    ADD CONSTRAINT fk_rails_548a575cd2 FOREIGN KEY (courier_id) REFERENCES public.couriers(id);


--
-- Name: quotes fk_rails_5e1368862f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT fk_rails_5e1368862f FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: payment_transactions fk_rails_5e2a55fe92; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT fk_rails_5e2a55fe92 FOREIGN KEY (payment_intent_id) REFERENCES public.payment_intents(id);


--
-- Name: service_areas fk_rails_5f5ebfa3b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_areas
    ADD CONSTRAINT fk_rails_5f5ebfa3b0 FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: role_permissions fk_rails_60126080bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT fk_rails_60126080bd FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: inventory_items fk_rails_62d92932b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT fk_rails_62d92932b7 FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: products fk_rails_632a051bad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_rails_632a051bad FOREIGN KEY (tax_rule_id) REFERENCES public.tax_rules(id);


--
-- Name: cart_items fk_rails_681a180e84; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT fk_rails_681a180e84 FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: user_identities fk_rails_684b0e1ce0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_identities
    ADD CONSTRAINT fk_rails_684b0e1ce0 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reconciliation_items fk_rails_6b062f7ff5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_items
    ADD CONSTRAINT fk_rails_6b062f7ff5 FOREIGN KEY (resolved_by_user_id) REFERENCES public.users(id);


--
-- Name: orders fk_rails_6b4dec1eb6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_6b4dec1eb6 FOREIGN KEY (exchange_rate_id) REFERENCES public.exchange_rates(id);


--
-- Name: cart_items fk_rails_6cdb1f0139; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT fk_rails_6cdb1f0139 FOREIGN KEY (cart_id) REFERENCES public.carts(id) ON DELETE CASCADE;


--
-- Name: delivery_incidents fk_rails_7484e77e54; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_incidents
    ADD CONSTRAINT fk_rails_7484e77e54 FOREIGN KEY (delivery_id) REFERENCES public.deliveries(id);


--
-- Name: sessions fk_rails_758836b4f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: modifiers fk_rails_769dcf7ebb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifiers
    ADD CONSTRAINT fk_rails_769dcf7ebb FOREIGN KEY (modifier_group_id) REFERENCES public.modifier_groups(id);


--
-- Name: orders fk_rails_774ef80392; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_774ef80392 FOREIGN KEY (address_id) REFERENCES public.addresses(id) ON DELETE RESTRICT;


--
-- Name: order_item_modifiers fk_rails_7e18c89050; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_item_modifiers
    ADD CONSTRAINT fk_rails_7e18c89050 FOREIGN KEY (source_modifier_id) REFERENCES public.modifiers(id) ON DELETE SET NULL;


--
-- Name: feature_flags fk_rails_84522ac1a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags
    ADD CONSTRAINT fk_rails_84522ac1a2 FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: customers fk_rails_8b503d0545; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT fk_rails_8b503d0545 FOREIGN KEY (default_address_id) REFERENCES public.addresses(id) ON DELETE SET NULL;


--
-- Name: role_assignments fk_rails_8ddd873ee0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_assignments
    ADD CONSTRAINT fk_rails_8ddd873ee0 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: quotes fk_rails_8ecd5fdf28; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT fk_rails_8ecd5fdf28 FOREIGN KEY (cart_id) REFERENCES public.carts(id) ON DELETE CASCADE;


--
-- Name: support_cases fk_rails_8f2165c87d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_cases
    ADD CONSTRAINT fk_rails_8f2165c87d FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: location_pings fk_rails_8fe7d51b95; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_pings
    ADD CONSTRAINT fk_rails_8fe7d51b95 FOREIGN KEY (delivery_id) REFERENCES public.deliveries(id);


--
-- Name: delivery_incidents fk_rails_9044298270; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_incidents
    ADD CONSTRAINT fk_rails_9044298270 FOREIGN KEY (resolved_by_user_id) REFERENCES public.users(id);


--
-- Name: inventory_items fk_rails_906b79f0d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT fk_rails_906b79f0d3 FOREIGN KEY (product_variant_id) REFERENCES public.product_variants(id);


--
-- Name: quotes fk_rails_908381b3ca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT fk_rails_908381b3ca FOREIGN KEY (address_id) REFERENCES public.addresses(id);


--
-- Name: ledger_entries fk_rails_942ef43aa4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT fk_rails_942ef43aa4 FOREIGN KEY (ledger_account_id) REFERENCES public.ledger_accounts(id);


--
-- Name: reconciliation_batches fk_rails_946dfc13c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_batches
    ADD CONSTRAINT fk_rails_946dfc13c4 FOREIGN KEY (completed_by_user_id) REFERENCES public.users(id);


--
-- Name: notification_preferences fk_rails_9503aade25; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT fk_rails_9503aade25 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: payment_intents fk_rails_98ae66af3b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT fk_rails_98ae66af3b FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: customers fk_rails_9917eeaf5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT fk_rails_9917eeaf5d FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: risk_decisions fk_rails_9d20a1b0d7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_decisions
    ADD CONSTRAINT fk_rails_9d20a1b0d7 FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: quotes fk_rails_a1ab65f1f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT fk_rails_a1ab65f1f7 FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: tax_rules fk_rails_a97c34740b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_rules
    ADD CONSTRAINT fk_rails_a97c34740b FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: reconciliation_batches fk_rails_aa32ac0422; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_batches
    ADD CONSTRAINT fk_rails_aa32ac0422 FOREIGN KEY (started_by_user_id) REFERENCES public.users(id);


--
-- Name: sessions fk_rails_aa96f6a7c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_aa96f6a7c5 FOREIGN KEY (rotated_from_session_id) REFERENCES public.sessions(id) ON DELETE SET NULL;


--
-- Name: addresses fk_rails_ab048f757c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT fk_rails_ab048f757c FOREIGN KEY (city_id) REFERENCES public.cities(id);


--
-- Name: sessions fk_rails_aec6d92ac2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_aec6d92ac2 FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: payment_intents fk_rails_af0a9a0944; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT fk_rails_af0a9a0944 FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: courier_availabilities fk_rails_af90fc3ab2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courier_availabilities
    ADD CONSTRAINT fk_rails_af90fc3ab2 FOREIGN KEY (courier_id) REFERENCES public.couriers(id);


--
-- Name: notifications fk_rails_b080fb4855; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_b080fb4855 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: support_cases fk_rails_b2932e0c43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_cases
    ADD CONSTRAINT fk_rails_b2932e0c43 FOREIGN KEY (assigned_to_user_id) REFERENCES public.users(id);


--
-- Name: service_areas fk_rails_b351f1b628; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_areas
    ADD CONSTRAINT fk_rails_b351f1b628 FOREIGN KEY (delivery_fee_rule_id) REFERENCES public.delivery_fee_rules(id) ON DELETE SET NULL;


--
-- Name: reconciliation_items fk_rails_b5d1a09b1a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_items
    ADD CONSTRAINT fk_rails_b5d1a09b1a FOREIGN KEY (reconciliation_batch_id) REFERENCES public.reconciliation_batches(id);


--
-- Name: categories fk_rails_b7f1bb9825; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_rails_b7f1bb9825 FOREIGN KEY (parent_category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: courier_branch_assignments fk_rails_baccb566a4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courier_branch_assignments
    ADD CONSTRAINT fk_rails_baccb566a4 FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: order_items fk_rails_bc5a3dd2a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fk_rails_bc5a3dd2a0 FOREIGN KEY (source_variant_id) REFERENCES public.product_variants(id) ON DELETE SET NULL;


--
-- Name: refunds fk_rails_bcf31193a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT fk_rails_bcf31193a5 FOREIGN KEY (requested_by_user_id) REFERENCES public.users(id);


--
-- Name: audit_events fk_rails_be0ed9e37f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT fk_rails_be0ed9e37f FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: order_item_modifiers fk_rails_c123920f0e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_item_modifiers
    ADD CONSTRAINT fk_rails_c123920f0e FOREIGN KEY (order_item_id) REFERENCES public.order_items(id) ON DELETE RESTRICT;


--
-- Name: zones fk_rails_c25880e95e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT fk_rails_c25880e95e FOREIGN KEY (city_id) REFERENCES public.cities(id);


--
-- Name: mobile_payment_submissions fk_rails_c3facd7653; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_payment_submissions
    ADD CONSTRAINT fk_rails_c3facd7653 FOREIGN KEY (duplicate_of_submission_id) REFERENCES public.mobile_payment_submissions(id);


--
-- Name: support_cases fk_rails_c8ac92f1e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_cases
    ADD CONSTRAINT fk_rails_c8ac92f1e0 FOREIGN KEY (delivery_id) REFERENCES public.deliveries(id);


--
-- Name: support_cases fk_rails_c9634a828b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_cases
    ADD CONSTRAINT fk_rails_c9634a828b FOREIGN KEY (opened_by_user_id) REFERENCES public.users(id);


--
-- Name: branches fk_rails_c975a54cff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT fk_rails_c975a54cff FOREIGN KEY (merchant_id) REFERENCES public.merchants(id);


--
-- Name: orders fk_rails_caba0da8d5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_caba0da8d5 FOREIGN KEY (delivery_id) REFERENCES public.deliveries(id);


--
-- Name: ledger_entries fk_rails_cb26505157; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT fk_rails_cb26505157 FOREIGN KEY (ledger_transaction_id) REFERENCES public.ledger_transactions(id);


--
-- Name: ledger_transactions fk_rails_cf7e074829; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_transactions
    ADD CONSTRAINT fk_rails_cf7e074829 FOREIGN KEY (reversal_of_transaction_id) REFERENCES public.ledger_transactions(id);


--
-- Name: role_assignments fk_rails_d5d049f535; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_assignments
    ADD CONSTRAINT fk_rails_d5d049f535 FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE RESTRICT;


--
-- Name: addresses fk_rails_d5f9efddd3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT fk_rails_d5f9efddd3 FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: branches fk_rails_d819cb9507; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT fk_rails_d819cb9507 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: order_transition_requests fk_rails_da92ebf28a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_transition_requests
    ADD CONSTRAINT fk_rails_da92ebf28a FOREIGN KEY (requested_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: product_variants fk_rails_dae52f850b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_variants
    ADD CONSTRAINT fk_rails_dae52f850b FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: carts fk_rails_e02ab95379; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carts
    ADD CONSTRAINT fk_rails_e02ab95379 FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: categories fk_rails_e090108a07; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_rails_e090108a07 FOREIGN KEY (catalog_id) REFERENCES public.catalogs(id);


--
-- Name: courier_documents fk_rails_e15cf3b85a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courier_documents
    ADD CONSTRAINT fk_rails_e15cf3b85a FOREIGN KEY (courier_id) REFERENCES public.couriers(id);


--
-- Name: service_areas fk_rails_e21f04d993; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_areas
    ADD CONSTRAINT fk_rails_e21f04d993 FOREIGN KEY (city_id) REFERENCES public.cities(id);


--
-- Name: delivery_fee_rules fk_rails_e35321d094; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_fee_rules
    ADD CONSTRAINT fk_rails_e35321d094 FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: order_items fk_rails_e3cb28f071; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fk_rails_e3cb28f071 FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE RESTRICT;


--
-- Name: role_assignments fk_rails_e4bfc1cd2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_assignments
    ADD CONSTRAINT fk_rails_e4bfc1cd2c FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE RESTRICT;


--
-- Name: dispatch_offers fk_rails_e60c2d14ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_offers
    ADD CONSTRAINT fk_rails_e60c2d14ea FOREIGN KEY (courier_id) REFERENCES public.couriers(id);


--
-- Name: couriers fk_rails_e99d87c839; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.couriers
    ADD CONSTRAINT fk_rails_e99d87c839 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: refunds fk_rails_f2ec94e6da; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT fk_rails_f2ec94e6da FOREIGN KEY (approved_by_user_id) REFERENCES public.users(id);


--
-- Name: exchange_rates fk_rails_f3b7ba7619; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT fk_rails_f3b7ba7619 FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: pos_payment_records fk_rails_f3f352271e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_payment_records
    ADD CONSTRAINT fk_rails_f3f352271e FOREIGN KEY (confirmed_by_user_id) REFERENCES public.users(id);


--
-- Name: merchants fk_rails_f4f5b48ca1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT fk_rails_f4f5b48ca1 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: cash_handovers fk_rails_f8e8e46539; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_handovers
    ADD CONSTRAINT fk_rails_f8e8e46539 FOREIGN KEY (courier_id) REFERENCES public.couriers(id);


--
-- Name: products fk_rails_fb915499a4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_rails_fb915499a4 FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: notifications fk_rails_fd5a31cf2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_fd5a31cf2f FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: orders fk_rails_fe8af6535c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_fe8af6535c FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE RESTRICT;


--
-- Name: cart_items fk_rails_ffa5d55b09; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT fk_rails_ffa5d55b09 FOREIGN KEY (product_variant_id) REFERENCES public.product_variants(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260821013941'),
('20260821013552'),
('20260821013134'),
('20260821013133'),
('20260821013132'),
('20260821012642'),
('20260821012641'),
('20260821012357'),
('20260821011856'),
('20260821011855'),
('20260820131336'),
('20260820131335'),
('20260820131334'),
('20260820131039'),
('20260820131037'),
('20260820130505'),
('20260820130503'),
('20260820130501'),
('20260820124644'),
('20260820124641'),
('20260820124639'),
('20260820124637'),
('20260820124635'),
('20260820124634'),
('20260820012557'),
('20260820005826'),
('20260820005824'),
('20260820005822'),
('20260820005820'),
('20260820005818'),
('20260820005524'),
('20260820005522'),
('20260820005520'),
('20260820005519'),
('20260820005517'),
('20260819234846'),
('20260819234845'),
('20260819234843'),
('20260819234842'),
('20260819234840'),
('20260819234801'),
('20260819234759'),
('20260819232136'),
('20260819232135'),
('20260819232133'),
('20260819232132'),
('20260819232047'),
('20260819232045'),
('20260819232044'),
('20260819231942'),
('20260819231915'),
('20260819231913'),
('20260819025002'),
('20260819024858'),
('20260819024857'),
('20260819024856'),
('20260819024855'),
('20260819024853'),
('20260819024852'),
('20260819024851'),
('20260819024815'),
('20260819024730'),
('20260819024729'),
('20260819024728'),
('20260819024639'),
('20260819024638'),
('20260819024637'),
('20260819024432'),
('20260819024430'),
('20260819012938'),
('20260819012937'),
('20260819012935'),
('20260819012933'),
('20260819012932'),
('20260819012931'),
('20260819012929'),
('20260819012928'),
('20260819012920'),
('20260819005751');


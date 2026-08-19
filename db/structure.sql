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
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: delivery_fee_rules delivery_fee_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_fee_rules
    ADD CONSTRAINT delivery_fee_rules_pkey PRIMARY KEY (id);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: exchange_rates exchange_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (id);


--
-- Name: inventory_items inventory_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- Name: merchants merchants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_pkey PRIMARY KEY (id);


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
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


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
-- Name: special_business_hours special_business_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.special_business_hours
    ADD CONSTRAINT special_business_hours_pkey PRIMARY KEY (id);


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
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: idx_on_phone_digest_purpose_created_at_11442c137d; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_phone_digest_purpose_created_at_11442c137d ON public.otp_challenges USING btree (phone_digest, purpose, created_at);


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
-- Name: index_customers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_customers_on_user_id ON public.customers USING btree (user_id);


--
-- Name: index_delivery_fee_rules_on_city_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_fee_rules_on_city_id ON public.delivery_fee_rules USING btree (city_id);


--
-- Name: index_delivery_fee_rules_on_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_fee_rules_on_zone_id ON public.delivery_fee_rules USING btree (zone_id);


--
-- Name: index_devices_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_devices_on_user_id ON public.devices USING btree (user_id);


--
-- Name: index_devices_on_user_id_and_installation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_devices_on_user_id_and_installation_id ON public.devices USING btree (user_id, installation_id);


--
-- Name: index_exchange_rates_on_created_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchange_rates_on_created_by_user_id ON public.exchange_rates USING btree (created_by_user_id);


--
-- Name: index_exchange_rates_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_exchange_rates_uniqueness ON public.exchange_rates USING btree (base_currency, quote_currency, effective_at, rate_type);


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
-- Name: index_modifier_groups_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_modifier_groups_on_product_id ON public.modifier_groups USING btree (product_id);


--
-- Name: index_modifiers_on_modifier_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_modifiers_on_modifier_group_id ON public.modifiers USING btree (modifier_group_id);


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
-- Name: index_permissions_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_permissions_on_code ON public.permissions USING btree (code);


--
-- Name: index_permissions_on_resource_and_action; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_permissions_on_resource_and_action ON public.permissions USING btree (resource, action);


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
-- Name: index_special_business_hours_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_special_business_hours_on_branch_id ON public.special_business_hours USING btree (branch_id);


--
-- Name: index_special_business_hours_on_branch_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_special_business_hours_on_branch_id_and_date ON public.special_business_hours USING btree (branch_id, date);


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
-- Name: role_assignments fk_rails_07a886715c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_assignments
    ADD CONSTRAINT fk_rails_07a886715c FOREIGN KEY (revoked_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: inventory_items fk_rails_0c6f012f57; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT fk_rails_0c6f012f57 FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


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
-- Name: catalogs fk_rails_2236035560; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalogs
    ADD CONSTRAINT fk_rails_2236035560 FOREIGN KEY (branch_id) REFERENCES public.branches(id);


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
-- Name: role_assignments fk_rails_373c2f5151; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_assignments
    ADD CONSTRAINT fk_rails_373c2f5151 FOREIGN KEY (assigned_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: business_hours fk_rails_3ae99539d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_hours
    ADD CONSTRAINT fk_rails_3ae99539d3 FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: cart_item_modifiers fk_rails_3daba72fa7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item_modifiers
    ADD CONSTRAINT fk_rails_3daba72fa7 FOREIGN KEY (modifier_id) REFERENCES public.modifiers(id);


--
-- Name: devices fk_rails_410b63ef65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT fk_rails_410b63ef65 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: role_permissions fk_rails_439e640a3f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT fk_rails_439e640a3f FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: inventory_items fk_rails_48ddeb658c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT fk_rails_48ddeb658c FOREIGN KEY (branch_id) REFERENCES public.branches(id);


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
-- Name: cart_item_modifiers fk_rails_506772ae83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item_modifiers
    ADD CONSTRAINT fk_rails_506772ae83 FOREIGN KEY (cart_item_id) REFERENCES public.cart_items(id) ON DELETE CASCADE;


--
-- Name: quotes fk_rails_5e1368862f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT fk_rails_5e1368862f FOREIGN KEY (branch_id) REFERENCES public.branches(id);


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
-- Name: cart_items fk_rails_6cdb1f0139; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT fk_rails_6cdb1f0139 FOREIGN KEY (cart_id) REFERENCES public.carts(id) ON DELETE CASCADE;


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
-- Name: customers fk_rails_9917eeaf5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT fk_rails_9917eeaf5d FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


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
-- Name: service_areas fk_rails_b351f1b628; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_areas
    ADD CONSTRAINT fk_rails_b351f1b628 FOREIGN KEY (delivery_fee_rule_id) REFERENCES public.delivery_fee_rules(id) ON DELETE SET NULL;


--
-- Name: categories fk_rails_b7f1bb9825; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_rails_b7f1bb9825 FOREIGN KEY (parent_category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: zones fk_rails_c25880e95e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT fk_rails_c25880e95e FOREIGN KEY (city_id) REFERENCES public.cities(id);


--
-- Name: branches fk_rails_c975a54cff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT fk_rails_c975a54cff FOREIGN KEY (merchant_id) REFERENCES public.merchants(id);


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
-- Name: role_assignments fk_rails_e4bfc1cd2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_assignments
    ADD CONSTRAINT fk_rails_e4bfc1cd2c FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE RESTRICT;


--
-- Name: exchange_rates fk_rails_f3b7ba7619; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT fk_rails_f3b7ba7619 FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: merchants fk_rails_f4f5b48ca1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT fk_rails_f4f5b48ca1 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: products fk_rails_fb915499a4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_rails_fb915499a4 FOREIGN KEY (category_id) REFERENCES public.categories(id);


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


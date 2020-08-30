\c synapse
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;
SET default_tablespace = '';
SET default_table_access_method = heap;
CREATE TABLE public.access_tokens (
    id bigint NOT NULL,
    user_id text NOT NULL,
    device_id text,
    token text NOT NULL,
    last_used bigint,
    valid_until_ms bigint
);
ALTER TABLE public.access_tokens OWNER TO synapse;
CREATE TABLE public.account_data (
    user_id text NOT NULL,
    account_data_type text NOT NULL,
    stream_id bigint NOT NULL,
    content text NOT NULL
);
ALTER TABLE public.account_data OWNER TO synapse;
CREATE TABLE public.account_data_max_stream_id (
    lock character(1) DEFAULT 'X'::bpchar NOT NULL,
    stream_id bigint NOT NULL,
    CONSTRAINT private_user_data_max_stream_id_lock_check CHECK ((lock = 'X'::bpchar))
);
ALTER TABLE public.account_data_max_stream_id OWNER TO synapse;
CREATE TABLE public.account_validity (
    user_id text NOT NULL,
    expiration_ts_ms bigint NOT NULL,
    email_sent boolean NOT NULL,
    renewal_token text
);
ALTER TABLE public.account_validity OWNER TO synapse;
CREATE TABLE public.application_services_state (
    as_id text NOT NULL,
    state character varying(5),
    last_txn integer
);
ALTER TABLE public.application_services_state OWNER TO synapse;
CREATE TABLE public.application_services_txns (
    as_id text NOT NULL,
    txn_id integer NOT NULL,
    event_ids text NOT NULL
);
ALTER TABLE public.application_services_txns OWNER TO synapse;
CREATE TABLE public.applied_module_schemas (
    module_name text NOT NULL,
    file text NOT NULL
);
ALTER TABLE public.applied_module_schemas OWNER TO synapse;
CREATE TABLE public.applied_schema_deltas (
    version integer NOT NULL,
    file text NOT NULL
);
ALTER TABLE public.applied_schema_deltas OWNER TO synapse;
CREATE TABLE public.appservice_room_list (
    appservice_id text NOT NULL,
    network_id text NOT NULL,
    room_id text NOT NULL
);
ALTER TABLE public.appservice_room_list OWNER TO synapse;
CREATE TABLE public.appservice_stream_position (
    lock character(1) DEFAULT 'X'::bpchar NOT NULL,
    stream_ordering bigint,
    CONSTRAINT appservice_stream_position_lock_check CHECK ((lock = 'X'::bpchar))
);
ALTER TABLE public.appservice_stream_position OWNER TO synapse;
CREATE TABLE public.background_updates (
    update_name text NOT NULL,
    progress_json text NOT NULL,
    depends_on text,
    ordering integer DEFAULT 0 NOT NULL
);
ALTER TABLE public.background_updates OWNER TO synapse;
CREATE TABLE public.blocked_rooms (
    room_id text NOT NULL,
    user_id text NOT NULL
);
ALTER TABLE public.blocked_rooms OWNER TO synapse;
CREATE TABLE public.cache_invalidation_stream (
    stream_id bigint,
    cache_func text,
    keys text[],
    invalidation_ts bigint
);
ALTER TABLE public.cache_invalidation_stream OWNER TO synapse;
CREATE TABLE public.cache_invalidation_stream_by_instance (
    stream_id bigint NOT NULL,
    instance_name text NOT NULL,
    cache_func text NOT NULL,
    keys text[],
    invalidation_ts bigint
);
ALTER TABLE public.cache_invalidation_stream_by_instance OWNER TO synapse;
CREATE SEQUENCE public.cache_invalidation_stream_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE public.cache_invalidation_stream_seq OWNER TO synapse;
CREATE TABLE public.current_state_delta_stream (
    stream_id bigint NOT NULL,
    room_id text NOT NULL,
    type text NOT NULL,
    state_key text NOT NULL,
    event_id text,
    prev_event_id text
);
ALTER TABLE public.current_state_delta_stream OWNER TO synapse;
CREATE TABLE public.current_state_events (
    event_id text NOT NULL,
    room_id text NOT NULL,
    type text NOT NULL,
    state_key text NOT NULL,
    membership text
);
ALTER TABLE public.current_state_events OWNER TO synapse;
CREATE TABLE public.deleted_pushers (
    stream_id bigint NOT NULL,
    app_id text NOT NULL,
    pushkey text NOT NULL,
    user_id text NOT NULL
);
ALTER TABLE public.deleted_pushers OWNER TO synapse;
CREATE TABLE public.destinations (
    destination text NOT NULL,
    retry_last_ts bigint,
    retry_interval bigint,
    failure_ts bigint
);
ALTER TABLE public.destinations OWNER TO synapse;
CREATE TABLE public.device_federation_inbox (
    origin text NOT NULL,
    message_id text NOT NULL,
    received_ts bigint NOT NULL
);
ALTER TABLE public.device_federation_inbox OWNER TO synapse;
CREATE TABLE public.device_federation_outbox (
    destination text NOT NULL,
    stream_id bigint NOT NULL,
    queued_ts bigint NOT NULL,
    messages_json text NOT NULL
);
ALTER TABLE public.device_federation_outbox OWNER TO synapse;
CREATE TABLE public.device_inbox (
    user_id text NOT NULL,
    device_id text NOT NULL,
    stream_id bigint NOT NULL,
    message_json text NOT NULL
);
ALTER TABLE public.device_inbox OWNER TO synapse;
CREATE TABLE public.device_lists_outbound_last_success (
    destination text NOT NULL,
    user_id text NOT NULL,
    stream_id bigint NOT NULL
);
ALTER TABLE public.device_lists_outbound_last_success OWNER TO synapse;
CREATE TABLE public.device_lists_outbound_pokes (
    destination text NOT NULL,
    stream_id bigint NOT NULL,
    user_id text NOT NULL,
    device_id text NOT NULL,
    sent boolean NOT NULL,
    ts bigint NOT NULL,
    opentracing_context text
);
ALTER TABLE public.device_lists_outbound_pokes OWNER TO synapse;
CREATE TABLE public.device_lists_remote_cache (
    user_id text NOT NULL,
    device_id text NOT NULL,
    content text NOT NULL
);
ALTER TABLE public.device_lists_remote_cache OWNER TO synapse;
CREATE TABLE public.device_lists_remote_extremeties (
    user_id text NOT NULL,
    stream_id text NOT NULL
);
ALTER TABLE public.device_lists_remote_extremeties OWNER TO synapse;
CREATE TABLE public.device_lists_remote_resync (
    user_id text NOT NULL,
    added_ts bigint NOT NULL
);
ALTER TABLE public.device_lists_remote_resync OWNER TO synapse;
CREATE TABLE public.device_lists_stream (
    stream_id bigint NOT NULL,
    user_id text NOT NULL,
    device_id text NOT NULL
);
ALTER TABLE public.device_lists_stream OWNER TO synapse;
CREATE TABLE public.device_max_stream_id (
    stream_id bigint NOT NULL
);
ALTER TABLE public.device_max_stream_id OWNER TO synapse;
CREATE TABLE public.devices (
    user_id text NOT NULL,
    device_id text NOT NULL,
    display_name text,
    last_seen bigint,
    ip text,
    user_agent text,
    hidden boolean DEFAULT false
);
ALTER TABLE public.devices OWNER TO synapse;
CREATE TABLE public.e2e_cross_signing_keys (
    user_id text NOT NULL,
    keytype text NOT NULL,
    keydata text NOT NULL,
    stream_id bigint NOT NULL
);
ALTER TABLE public.e2e_cross_signing_keys OWNER TO synapse;
CREATE TABLE public.e2e_cross_signing_signatures (
    user_id text NOT NULL,
    key_id text NOT NULL,
    target_user_id text NOT NULL,
    target_device_id text NOT NULL,
    signature text NOT NULL
);
ALTER TABLE public.e2e_cross_signing_signatures OWNER TO synapse;
CREATE TABLE public.e2e_device_keys_json (
    user_id text NOT NULL,
    device_id text NOT NULL,
    ts_added_ms bigint NOT NULL,
    key_json text NOT NULL
);
ALTER TABLE public.e2e_device_keys_json OWNER TO synapse;
CREATE TABLE public.e2e_one_time_keys_json (
    user_id text NOT NULL,
    device_id text NOT NULL,
    algorithm text NOT NULL,
    key_id text NOT NULL,
    ts_added_ms bigint NOT NULL,
    key_json text NOT NULL
);
ALTER TABLE public.e2e_one_time_keys_json OWNER TO synapse;
CREATE TABLE public.e2e_room_keys (
    user_id text NOT NULL,
    room_id text NOT NULL,
    session_id text NOT NULL,
    version bigint NOT NULL,
    first_message_index integer,
    forwarded_count integer,
    is_verified boolean,
    session_data text NOT NULL
);
ALTER TABLE public.e2e_room_keys OWNER TO synapse;
CREATE TABLE public.e2e_room_keys_versions (
    user_id text NOT NULL,
    version bigint NOT NULL,
    algorithm text NOT NULL,
    auth_data text NOT NULL,
    deleted smallint DEFAULT 0 NOT NULL,
    etag bigint
);
ALTER TABLE public.e2e_room_keys_versions OWNER TO synapse;
CREATE TABLE public.erased_users (
    user_id text NOT NULL
);
ALTER TABLE public.erased_users OWNER TO synapse;
CREATE TABLE public.event_auth (
    event_id text NOT NULL,
    auth_id text NOT NULL,
    room_id text NOT NULL
);
ALTER TABLE public.event_auth OWNER TO synapse;
CREATE TABLE public.event_backward_extremities (
    event_id text NOT NULL,
    room_id text NOT NULL
);
ALTER TABLE public.event_backward_extremities OWNER TO synapse;
CREATE TABLE public.event_edges (
    event_id text NOT NULL,
    prev_event_id text NOT NULL,
    room_id text NOT NULL,
    is_state boolean NOT NULL
);
ALTER TABLE public.event_edges OWNER TO synapse;
CREATE TABLE public.event_expiry (
    event_id text NOT NULL,
    expiry_ts bigint NOT NULL
);
ALTER TABLE public.event_expiry OWNER TO synapse;
CREATE TABLE public.event_forward_extremities (
    event_id text NOT NULL,
    room_id text NOT NULL
);
ALTER TABLE public.event_forward_extremities OWNER TO synapse;
CREATE TABLE public.event_json (
    event_id text NOT NULL,
    room_id text NOT NULL,
    internal_metadata text NOT NULL,
    json text NOT NULL,
    format_version integer
);
ALTER TABLE public.event_json OWNER TO synapse;
CREATE TABLE public.event_labels (
    event_id text NOT NULL,
    label text NOT NULL,
    room_id text NOT NULL,
    topological_ordering bigint NOT NULL
);
ALTER TABLE public.event_labels OWNER TO synapse;
CREATE TABLE public.event_push_actions (
    room_id text NOT NULL,
    event_id text NOT NULL,
    user_id text NOT NULL,
    profile_tag character varying(32),
    actions text NOT NULL,
    topological_ordering bigint,
    stream_ordering bigint,
    notif smallint,
    highlight smallint
);
ALTER TABLE public.event_push_actions OWNER TO synapse;
CREATE TABLE public.event_push_actions_staging (
    event_id text NOT NULL,
    user_id text NOT NULL,
    actions text NOT NULL,
    notif smallint NOT NULL,
    highlight smallint NOT NULL
);
ALTER TABLE public.event_push_actions_staging OWNER TO synapse;
CREATE TABLE public.event_push_summary (
    user_id text NOT NULL,
    room_id text NOT NULL,
    notif_count bigint NOT NULL,
    stream_ordering bigint NOT NULL
);
ALTER TABLE public.event_push_summary OWNER TO synapse;
CREATE TABLE public.event_push_summary_stream_ordering (
    lock character(1) DEFAULT 'X'::bpchar NOT NULL,
    stream_ordering bigint NOT NULL,
    CONSTRAINT event_push_summary_stream_ordering_lock_check CHECK ((lock = 'X'::bpchar))
);
ALTER TABLE public.event_push_summary_stream_ordering OWNER TO synapse;
CREATE TABLE public.event_reference_hashes (
    event_id text,
    algorithm text,
    hash bytea
);
ALTER TABLE public.event_reference_hashes OWNER TO synapse;
CREATE TABLE public.event_relations (
    event_id text NOT NULL,
    relates_to_id text NOT NULL,
    relation_type text NOT NULL,
    aggregation_key text
);
ALTER TABLE public.event_relations OWNER TO synapse;
CREATE TABLE public.event_reports (
    id bigint NOT NULL,
    received_ts bigint NOT NULL,
    room_id text NOT NULL,
    event_id text NOT NULL,
    user_id text NOT NULL,
    reason text,
    content text
);
ALTER TABLE public.event_reports OWNER TO synapse;
CREATE TABLE public.event_search (
    event_id text,
    room_id text,
    sender text,
    key text,
    vector tsvector,
    origin_server_ts bigint,
    stream_ordering bigint
);
ALTER TABLE public.event_search OWNER TO synapse;
CREATE TABLE public.event_to_state_groups (
    event_id text NOT NULL,
    state_group bigint NOT NULL
);
ALTER TABLE public.event_to_state_groups OWNER TO synapse;
CREATE TABLE public.events (
    stream_ordering integer NOT NULL,
    topological_ordering bigint NOT NULL,
    event_id text NOT NULL,
    type text NOT NULL,
    room_id text NOT NULL,
    content text,
    unrecognized_keys text,
    processed boolean NOT NULL,
    outlier boolean NOT NULL,
    depth bigint DEFAULT 0 NOT NULL,
    origin_server_ts bigint,
    received_ts bigint,
    sender text,
    contains_url boolean
);
ALTER TABLE public.events OWNER TO synapse;
CREATE TABLE public.ex_outlier_stream (
    event_stream_ordering bigint NOT NULL,
    event_id text NOT NULL,
    state_group bigint NOT NULL
);
ALTER TABLE public.ex_outlier_stream OWNER TO synapse;
CREATE TABLE public.federation_stream_position (
    type text NOT NULL,
    stream_id integer NOT NULL
);
ALTER TABLE public.federation_stream_position OWNER TO synapse;
CREATE TABLE public.group_attestations_remote (
    group_id text NOT NULL,
    user_id text NOT NULL,
    valid_until_ms bigint NOT NULL,
    attestation_json text NOT NULL
);
ALTER TABLE public.group_attestations_remote OWNER TO synapse;
CREATE TABLE public.group_attestations_renewals (
    group_id text NOT NULL,
    user_id text NOT NULL,
    valid_until_ms bigint NOT NULL
);
ALTER TABLE public.group_attestations_renewals OWNER TO synapse;
CREATE TABLE public.group_invites (
    group_id text NOT NULL,
    user_id text NOT NULL
);
ALTER TABLE public.group_invites OWNER TO synapse;
CREATE TABLE public.group_roles (
    group_id text NOT NULL,
    role_id text NOT NULL,
    profile text NOT NULL,
    is_public boolean NOT NULL
);
ALTER TABLE public.group_roles OWNER TO synapse;
CREATE TABLE public.group_room_categories (
    group_id text NOT NULL,
    category_id text NOT NULL,
    profile text NOT NULL,
    is_public boolean NOT NULL
);
ALTER TABLE public.group_room_categories OWNER TO synapse;
CREATE TABLE public.group_rooms (
    group_id text NOT NULL,
    room_id text NOT NULL,
    is_public boolean NOT NULL
);
ALTER TABLE public.group_rooms OWNER TO synapse;
CREATE TABLE public.group_summary_roles (
    group_id text NOT NULL,
    role_id text NOT NULL,
    role_order bigint NOT NULL,
    CONSTRAINT group_summary_roles_role_order_check CHECK ((role_order > 0))
);
ALTER TABLE public.group_summary_roles OWNER TO synapse;
CREATE TABLE public.group_summary_room_categories (
    group_id text NOT NULL,
    category_id text NOT NULL,
    cat_order bigint NOT NULL,
    CONSTRAINT group_summary_room_categories_cat_order_check CHECK ((cat_order > 0))
);
ALTER TABLE public.group_summary_room_categories OWNER TO synapse;
CREATE TABLE public.group_summary_rooms (
    group_id text NOT NULL,
    room_id text NOT NULL,
    category_id text NOT NULL,
    room_order bigint NOT NULL,
    is_public boolean NOT NULL,
    CONSTRAINT group_summary_rooms_room_order_check CHECK ((room_order > 0))
);
ALTER TABLE public.group_summary_rooms OWNER TO synapse;
CREATE TABLE public.group_summary_users (
    group_id text NOT NULL,
    user_id text NOT NULL,
    role_id text NOT NULL,
    user_order bigint NOT NULL,
    is_public boolean NOT NULL
);
ALTER TABLE public.group_summary_users OWNER TO synapse;
CREATE TABLE public.group_users (
    group_id text NOT NULL,
    user_id text NOT NULL,
    is_admin boolean NOT NULL,
    is_public boolean NOT NULL
);
ALTER TABLE public.group_users OWNER TO synapse;
CREATE TABLE public.groups (
    group_id text NOT NULL,
    name text,
    avatar_url text,
    short_description text,
    long_description text,
    is_public boolean NOT NULL,
    join_policy text DEFAULT 'invite'::text NOT NULL
);
ALTER TABLE public.groups OWNER TO synapse;
CREATE TABLE public.local_current_membership (
    room_id text NOT NULL,
    user_id text NOT NULL,
    event_id text NOT NULL,
    membership text NOT NULL
);
ALTER TABLE public.local_current_membership OWNER TO synapse;
CREATE TABLE public.local_group_membership (
    group_id text NOT NULL,
    user_id text NOT NULL,
    is_admin boolean NOT NULL,
    membership text NOT NULL,
    is_publicised boolean NOT NULL,
    content text NOT NULL
);
ALTER TABLE public.local_group_membership OWNER TO synapse;
CREATE TABLE public.local_group_updates (
    stream_id bigint NOT NULL,
    group_id text NOT NULL,
    user_id text NOT NULL,
    type text NOT NULL,
    content text NOT NULL
);
ALTER TABLE public.local_group_updates OWNER TO synapse;
CREATE TABLE public.local_invites (
    stream_id bigint NOT NULL,
    inviter text NOT NULL,
    invitee text NOT NULL,
    event_id text NOT NULL,
    room_id text NOT NULL,
    locally_rejected text,
    replaced_by text
);
ALTER TABLE public.local_invites OWNER TO synapse;
CREATE TABLE public.local_media_repository (
    media_id text,
    media_type text,
    media_length integer,
    created_ts bigint,
    upload_name text,
    user_id text,
    quarantined_by text,
    url_cache text,
    last_access_ts bigint
);
ALTER TABLE public.local_media_repository OWNER TO synapse;
CREATE TABLE public.local_media_repository_thumbnails (
    media_id text,
    thumbnail_width integer,
    thumbnail_height integer,
    thumbnail_type text,
    thumbnail_method text,
    thumbnail_length integer
);
ALTER TABLE public.local_media_repository_thumbnails OWNER TO synapse;
CREATE TABLE public.local_media_repository_url_cache (
    url text,
    response_code integer,
    etag text,
    expires_ts bigint,
    og text,
    media_id text,
    download_ts bigint
);
ALTER TABLE public.local_media_repository_url_cache OWNER TO synapse;
CREATE TABLE public.monthly_active_users (
    user_id text NOT NULL,
    "timestamp" bigint NOT NULL
);
ALTER TABLE public.monthly_active_users OWNER TO synapse;
CREATE TABLE public.open_id_tokens (
    token text NOT NULL,
    ts_valid_until_ms bigint NOT NULL,
    user_id text NOT NULL
);
ALTER TABLE public.open_id_tokens OWNER TO synapse;
CREATE TABLE public.presence (
    user_id text NOT NULL,
    state character varying(20),
    status_msg text,
    mtime bigint
);
ALTER TABLE public.presence OWNER TO synapse;
CREATE TABLE public.presence_allow_inbound (
    observed_user_id text NOT NULL,
    observer_user_id text NOT NULL
);
ALTER TABLE public.presence_allow_inbound OWNER TO synapse;
CREATE TABLE public.presence_stream (
    stream_id bigint,
    user_id text,
    state text,
    last_active_ts bigint,
    last_federation_update_ts bigint,
    last_user_sync_ts bigint,
    status_msg text,
    currently_active boolean
);
ALTER TABLE public.presence_stream OWNER TO synapse;
CREATE TABLE public.profiles (
    user_id text NOT NULL,
    displayname text,
    avatar_url text
);
ALTER TABLE public.profiles OWNER TO synapse;
CREATE TABLE public.public_room_list_stream (
    stream_id bigint NOT NULL,
    room_id text NOT NULL,
    visibility boolean NOT NULL,
    appservice_id text,
    network_id text
);
ALTER TABLE public.public_room_list_stream OWNER TO synapse;
CREATE TABLE public.push_rules (
    id bigint NOT NULL,
    user_name text NOT NULL,
    rule_id text NOT NULL,
    priority_class smallint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    conditions text NOT NULL,
    actions text NOT NULL
);
ALTER TABLE public.push_rules OWNER TO synapse;
CREATE TABLE public.push_rules_enable (
    id bigint NOT NULL,
    user_name text NOT NULL,
    rule_id text NOT NULL,
    enabled smallint
);
ALTER TABLE public.push_rules_enable OWNER TO synapse;
CREATE TABLE public.push_rules_stream (
    stream_id bigint NOT NULL,
    event_stream_ordering bigint NOT NULL,
    user_id text NOT NULL,
    rule_id text NOT NULL,
    op text NOT NULL,
    priority_class smallint,
    priority integer,
    conditions text,
    actions text
);
ALTER TABLE public.push_rules_stream OWNER TO synapse;
CREATE TABLE public.pusher_throttle (
    pusher bigint NOT NULL,
    room_id text NOT NULL,
    last_sent_ts bigint,
    throttle_ms bigint
);
ALTER TABLE public.pusher_throttle OWNER TO synapse;
CREATE TABLE public.pushers (
    id bigint NOT NULL,
    user_name text NOT NULL,
    access_token bigint,
    profile_tag text NOT NULL,
    kind text NOT NULL,
    app_id text NOT NULL,
    app_display_name text NOT NULL,
    device_display_name text NOT NULL,
    pushkey text NOT NULL,
    ts bigint NOT NULL,
    lang text,
    data text,
    last_stream_ordering integer,
    last_success bigint,
    failing_since bigint
);
ALTER TABLE public.pushers OWNER TO synapse;
CREATE TABLE public.ratelimit_override (
    user_id text NOT NULL,
    messages_per_second bigint,
    burst_count bigint
);
ALTER TABLE public.ratelimit_override OWNER TO synapse;
CREATE TABLE public.receipts_graph (
    room_id text NOT NULL,
    receipt_type text NOT NULL,
    user_id text NOT NULL,
    event_ids text NOT NULL,
    data text NOT NULL
);
ALTER TABLE public.receipts_graph OWNER TO synapse;
CREATE TABLE public.receipts_linearized (
    stream_id bigint NOT NULL,
    room_id text NOT NULL,
    receipt_type text NOT NULL,
    user_id text NOT NULL,
    event_id text NOT NULL,
    data text NOT NULL
);
ALTER TABLE public.receipts_linearized OWNER TO synapse;
CREATE TABLE public.received_transactions (
    transaction_id text,
    origin text,
    ts bigint,
    response_code integer,
    response_json bytea,
    has_been_referenced smallint DEFAULT 0
);
ALTER TABLE public.received_transactions OWNER TO synapse;
CREATE TABLE public.redactions (
    event_id text NOT NULL,
    redacts text NOT NULL,
    have_censored boolean DEFAULT false NOT NULL,
    received_ts bigint
);
ALTER TABLE public.redactions OWNER TO synapse;
CREATE TABLE public.rejections (
    event_id text NOT NULL,
    reason text NOT NULL,
    last_check text NOT NULL
);
ALTER TABLE public.rejections OWNER TO synapse;
CREATE TABLE public.remote_media_cache (
    media_origin text,
    media_id text,
    media_type text,
    created_ts bigint,
    upload_name text,
    media_length integer,
    filesystem_id text,
    last_access_ts bigint,
    quarantined_by text
);
ALTER TABLE public.remote_media_cache OWNER TO synapse;
CREATE TABLE public.remote_media_cache_thumbnails (
    media_origin text,
    media_id text,
    thumbnail_width integer,
    thumbnail_height integer,
    thumbnail_method text,
    thumbnail_type text,
    thumbnail_length integer,
    filesystem_id text
);
ALTER TABLE public.remote_media_cache_thumbnails OWNER TO synapse;
CREATE TABLE public.remote_profile_cache (
    user_id text NOT NULL,
    displayname text,
    avatar_url text,
    last_check bigint NOT NULL
);
ALTER TABLE public.remote_profile_cache OWNER TO synapse;
CREATE TABLE public.room_account_data (
    user_id text NOT NULL,
    room_id text NOT NULL,
    account_data_type text NOT NULL,
    stream_id bigint NOT NULL,
    content text NOT NULL
);
ALTER TABLE public.room_account_data OWNER TO synapse;
CREATE TABLE public.room_alias_servers (
    room_alias text NOT NULL,
    server text NOT NULL
);
ALTER TABLE public.room_alias_servers OWNER TO synapse;
CREATE TABLE public.room_aliases (
    room_alias text NOT NULL,
    room_id text NOT NULL,
    creator text
);
ALTER TABLE public.room_aliases OWNER TO synapse;
CREATE TABLE public.room_depth (
    room_id text NOT NULL,
    min_depth integer NOT NULL
);
ALTER TABLE public.room_depth OWNER TO synapse;
CREATE TABLE public.room_memberships (
    event_id text NOT NULL,
    user_id text NOT NULL,
    sender text NOT NULL,
    room_id text NOT NULL,
    membership text NOT NULL,
    forgotten integer DEFAULT 0,
    display_name text,
    avatar_url text
);
ALTER TABLE public.room_memberships OWNER TO synapse;
CREATE TABLE public.room_retention (
    room_id text NOT NULL,
    event_id text NOT NULL,
    min_lifetime bigint,
    max_lifetime bigint
);
ALTER TABLE public.room_retention OWNER TO synapse;
CREATE TABLE public.room_stats_current (
    room_id text NOT NULL,
    current_state_events integer NOT NULL,
    joined_members integer NOT NULL,
    invited_members integer NOT NULL,
    left_members integer NOT NULL,
    banned_members integer NOT NULL,
    local_users_in_room integer NOT NULL,
    completed_delta_stream_id bigint NOT NULL
);
ALTER TABLE public.room_stats_current OWNER TO synapse;
CREATE TABLE public.room_stats_earliest_token (
    room_id text NOT NULL,
    token bigint NOT NULL
);
ALTER TABLE public.room_stats_earliest_token OWNER TO synapse;
CREATE TABLE public.room_stats_historical (
    room_id text NOT NULL,
    end_ts bigint NOT NULL,
    bucket_size bigint NOT NULL,
    current_state_events bigint NOT NULL,
    joined_members bigint NOT NULL,
    invited_members bigint NOT NULL,
    left_members bigint NOT NULL,
    banned_members bigint NOT NULL,
    local_users_in_room bigint NOT NULL,
    total_events bigint NOT NULL,
    total_event_bytes bigint NOT NULL
);
ALTER TABLE public.room_stats_historical OWNER TO synapse;
CREATE TABLE public.room_stats_state (
    room_id text NOT NULL,
    name text,
    canonical_alias text,
    join_rules text,
    history_visibility text,
    encryption text,
    avatar text,
    guest_access text,
    is_federatable boolean,
    topic text
);
ALTER TABLE public.room_stats_state OWNER TO synapse;
CREATE TABLE public.room_tags (
    user_id text NOT NULL,
    room_id text NOT NULL,
    tag text NOT NULL,
    content text NOT NULL
);
ALTER TABLE public.room_tags OWNER TO synapse;
CREATE TABLE public.room_tags_revisions (
    user_id text NOT NULL,
    room_id text NOT NULL,
    stream_id bigint NOT NULL
);
ALTER TABLE public.room_tags_revisions OWNER TO synapse;
CREATE TABLE public.rooms (
    room_id text NOT NULL,
    is_public boolean,
    creator text,
    room_version text
);
ALTER TABLE public.rooms OWNER TO synapse;
CREATE TABLE public.schema_version (
    lock character(1) DEFAULT 'X'::bpchar NOT NULL,
    version integer NOT NULL,
    upgraded boolean NOT NULL,
    CONSTRAINT schema_version_lock_check CHECK ((lock = 'X'::bpchar))
);
ALTER TABLE public.schema_version OWNER TO synapse;
CREATE TABLE public.server_keys_json (
    server_name text NOT NULL,
    key_id text NOT NULL,
    from_server text NOT NULL,
    ts_added_ms bigint NOT NULL,
    ts_valid_until_ms bigint NOT NULL,
    key_json bytea NOT NULL
);
ALTER TABLE public.server_keys_json OWNER TO synapse;
CREATE TABLE public.server_signature_keys (
    server_name text,
    key_id text,
    from_server text,
    ts_added_ms bigint,
    verify_key bytea,
    ts_valid_until_ms bigint
);
ALTER TABLE public.server_signature_keys OWNER TO synapse;
CREATE TABLE public.state_events (
    event_id text NOT NULL,
    room_id text NOT NULL,
    type text NOT NULL,
    state_key text NOT NULL,
    prev_state text
);
ALTER TABLE public.state_events OWNER TO synapse;
CREATE TABLE public.state_group_edges (
    state_group bigint NOT NULL,
    prev_state_group bigint NOT NULL
);
ALTER TABLE public.state_group_edges OWNER TO synapse;
CREATE SEQUENCE public.state_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE public.state_group_id_seq OWNER TO synapse;
CREATE TABLE public.state_groups (
    id bigint NOT NULL,
    room_id text NOT NULL,
    event_id text NOT NULL
);
ALTER TABLE public.state_groups OWNER TO synapse;
CREATE TABLE public.state_groups_state (
    state_group bigint NOT NULL,
    room_id text NOT NULL,
    type text NOT NULL,
    state_key text NOT NULL,
    event_id text NOT NULL
);
ALTER TABLE public.state_groups_state OWNER TO synapse;
CREATE TABLE public.stats_incremental_position (
    lock character(1) DEFAULT 'X'::bpchar NOT NULL,
    stream_id bigint NOT NULL,
    CONSTRAINT stats_incremental_position_lock_check CHECK ((lock = 'X'::bpchar))
);
ALTER TABLE public.stats_incremental_position OWNER TO synapse;
CREATE TABLE public.stream_ordering_to_exterm (
    stream_ordering bigint NOT NULL,
    room_id text NOT NULL,
    event_id text NOT NULL
);
ALTER TABLE public.stream_ordering_to_exterm OWNER TO synapse;
CREATE TABLE public.threepid_guest_access_tokens (
    medium text,
    address text,
    guest_access_token text,
    first_inviter text
);
ALTER TABLE public.threepid_guest_access_tokens OWNER TO synapse;
CREATE TABLE public.threepid_validation_session (
    session_id text NOT NULL,
    medium text NOT NULL,
    address text NOT NULL,
    client_secret text NOT NULL,
    last_send_attempt bigint NOT NULL,
    validated_at bigint
);
ALTER TABLE public.threepid_validation_session OWNER TO synapse;
CREATE TABLE public.threepid_validation_token (
    token text NOT NULL,
    session_id text NOT NULL,
    next_link text,
    expires bigint NOT NULL
);
ALTER TABLE public.threepid_validation_token OWNER TO synapse;
CREATE TABLE public.ui_auth_sessions (
    session_id text NOT NULL,
    creation_time bigint NOT NULL,
    serverdict text NOT NULL,
    clientdict text NOT NULL,
    uri text NOT NULL,
    method text NOT NULL,
    description text NOT NULL
);
ALTER TABLE public.ui_auth_sessions OWNER TO synapse;
CREATE TABLE public.ui_auth_sessions_credentials (
    session_id text NOT NULL,
    stage_type text NOT NULL,
    result text NOT NULL
);
ALTER TABLE public.ui_auth_sessions_credentials OWNER TO synapse;
CREATE TABLE public.user_daily_visits (
    user_id text NOT NULL,
    device_id text,
    "timestamp" bigint NOT NULL
);
ALTER TABLE public.user_daily_visits OWNER TO synapse;
CREATE TABLE public.user_directory (
    user_id text NOT NULL,
    room_id text,
    display_name text,
    avatar_url text
);
ALTER TABLE public.user_directory OWNER TO synapse;
CREATE TABLE public.user_directory_search (
    user_id text NOT NULL,
    vector tsvector
);
ALTER TABLE public.user_directory_search OWNER TO synapse;
CREATE TABLE public.user_directory_stream_pos (
    lock character(1) DEFAULT 'X'::bpchar NOT NULL,
    stream_id bigint,
    CONSTRAINT user_directory_stream_pos_lock_check CHECK ((lock = 'X'::bpchar))
);
ALTER TABLE public.user_directory_stream_pos OWNER TO synapse;
CREATE TABLE public.user_external_ids (
    auth_provider text NOT NULL,
    external_id text NOT NULL,
    user_id text NOT NULL
);
ALTER TABLE public.user_external_ids OWNER TO synapse;
CREATE TABLE public.user_filters (
    user_id text NOT NULL,
    filter_id bigint NOT NULL,
    filter_json bytea NOT NULL
);
ALTER TABLE public.user_filters OWNER TO synapse;
CREATE TABLE public.user_ips (
    user_id text NOT NULL,
    access_token text NOT NULL,
    device_id text,
    ip text NOT NULL,
    user_agent text NOT NULL,
    last_seen bigint NOT NULL
);
ALTER TABLE public.user_ips OWNER TO synapse;
CREATE TABLE public.user_signature_stream (
    stream_id bigint NOT NULL,
    from_user_id text NOT NULL,
    user_ids text NOT NULL
);
ALTER TABLE public.user_signature_stream OWNER TO synapse;
CREATE TABLE public.user_stats_current (
    user_id text NOT NULL,
    joined_rooms bigint NOT NULL,
    completed_delta_stream_id bigint NOT NULL
);
ALTER TABLE public.user_stats_current OWNER TO synapse;
CREATE TABLE public.user_stats_historical (
    user_id text NOT NULL,
    end_ts bigint NOT NULL,
    bucket_size bigint NOT NULL,
    joined_rooms bigint NOT NULL,
    invites_sent bigint NOT NULL,
    rooms_created bigint NOT NULL,
    total_events bigint NOT NULL,
    total_event_bytes bigint NOT NULL
);
ALTER TABLE public.user_stats_historical OWNER TO synapse;
CREATE TABLE public.user_threepid_id_server (
    user_id text NOT NULL,
    medium text NOT NULL,
    address text NOT NULL,
    id_server text NOT NULL
);
ALTER TABLE public.user_threepid_id_server OWNER TO synapse;
CREATE TABLE public.user_threepids (
    user_id text NOT NULL,
    medium text NOT NULL,
    address text NOT NULL,
    validated_at bigint NOT NULL,
    added_at bigint NOT NULL
);
ALTER TABLE public.user_threepids OWNER TO synapse;
CREATE TABLE public.users (
    name text,
    password_hash text,
    creation_ts bigint,
    admin smallint DEFAULT 0 NOT NULL,
    upgrade_ts bigint,
    is_guest smallint DEFAULT 0 NOT NULL,
    appservice_id text,
    consent_version text,
    consent_server_notice_sent text,
    user_type text,
    deactivated smallint DEFAULT 0 NOT NULL
);
ALTER TABLE public.users OWNER TO synapse;
CREATE TABLE public.users_in_public_rooms (
    user_id text NOT NULL,
    room_id text NOT NULL
);
ALTER TABLE public.users_in_public_rooms OWNER TO synapse;
CREATE TABLE public.users_pending_deactivation (
    user_id text NOT NULL
);
ALTER TABLE public.users_pending_deactivation OWNER TO synapse;
CREATE TABLE public.users_who_share_private_rooms (
    user_id text NOT NULL,
    other_user_id text NOT NULL,
    room_id text NOT NULL
);
ALTER TABLE public.users_who_share_private_rooms OWNER TO synapse;
COPY public.access_tokens (id, user_id, device_id, token, last_used, valid_until_ms) FROM stdin;
2	@admin:localhost	WCSUBIGVWG	MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjNjaWQgdXNlcl9pZCA9IEBhZG1pbjpsb2NhbGhvc3QKMDAxNmNpZCB0eXBlID0gYWNjZXNzCjAwMjFjaWQgbm9uY2UgPSBXVU9yUTVRMFRnUkNjME1ACjAwMmZzaWduYXR1cmUgdYKA-yuTQ5JV5O0HWRak-48xavOYgA1MMc6A1V_Uw5kK	\N	\N
3	@matrix_a:localhost	TKAVEOGKHH	MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjZjaWQgdXNlcl9pZCA9IEBtYXRyaXhfYTpsb2NhbGhvc3QKMDAxNmNpZCB0eXBlID0gYWNjZXNzCjAwMjFjaWQgbm9uY2UgPSAwb3Y6eTZVdHojUk4jbFprCjAwMmZzaWduYXR1cmUgNNZKnOVRzj5svh9pEM0UUEqtXYnHjnj9XyNLJ1_uKoAK	\N	\N
4	@matrix_b:localhost	DJFHSWMXLW	MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjZjaWQgdXNlcl9pZCA9IEBtYXRyaXhfYjpsb2NhbGhvc3QKMDAxNmNpZCB0eXBlID0gYWNjZXNzCjAwMjFjaWQgbm9uY2UgPSBBYl9hbWthI0daSzgtfjdICjAwMmZzaWduYXR1cmUgOReBLkPURCMNtzORS9fpogQqVa3IWN9ZEu5gXW91QTMK	\N	\N
5	@ignored_user:localhost	IYEBBQEXHS	MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMmFjaWQgdXNlcl9pZCA9IEBpZ25vcmVkX3VzZXI6bG9jYWxob3N0CjAwMTZjaWQgdHlwZSA9IGFjY2VzcwowMDIxY2lkIG5vbmNlID0gZU5ta1BBMj1FNnVPRGtwdgowMDJmc2lnbmF0dXJlIHSt8jrFU836Ne3it2HY88EhPD1Aoustsm211bbFjcLcCg	\N	\N
\.
COPY public.account_data (user_id, account_data_type, stream_id, content) FROM stdin;
\.
COPY public.account_data_max_stream_id (lock, stream_id) FROM stdin;
\.
COPY public.account_validity (user_id, expiration_ts_ms, email_sent, renewal_token) FROM stdin;
\.
COPY public.application_services_state (as_id, state, last_txn) FROM stdin;
\.
COPY public.application_services_txns (as_id, txn_id, event_ids) FROM stdin;
\.
COPY public.applied_module_schemas (module_name, file) FROM stdin;
\.
COPY public.applied_schema_deltas (version, file) FROM stdin;
55	55/access_token_expiry.sql
55	55/track_threepid_validations.sql
55	55/users_alter_deactivated.sql
56	56/add_spans_to_device_lists.sql
56	56/current_state_events_membership.sql
56	56/current_state_events_membership_mk2.sql
56	56/delete_keys_from_deleted_backups.sql
56	56/destinations_failure_ts.sql
56	56/destinations_retry_interval_type.sql.postgres
56	56/device_stream_id_insert.sql
56	56/devices_last_seen.sql
56	56/drop_unused_event_tables.sql
56	56/event_expiry.sql
56	56/event_labels.sql
56	56/event_labels_background_update.sql
56	56/fix_room_keys_index.sql
56	56/hidden_devices.sql
56	56/nuke_empty_communities_from_db.sql
56	56/public_room_list_idx.sql
56	56/redaction_censor.sql
56	56/redaction_censor2.sql
56	56/redaction_censor3_fix_update.sql.postgres
56	56/redaction_censor4.sql
56	56/remove_tombstoned_rooms_from_directory.sql
56	56/room_key_etag.sql
56	56/room_membership_idx.sql
56	56/room_retention.sql
56	56/signing_keys.sql
56	56/signing_keys_nonunique_signatures.sql
56	56/state_group_room_idx.sql
56	56/stats_separated.sql
56	56/unique_user_filter_index.py
56	56/user_external_ids.sql
56	56/users_in_public_rooms_idx.sql
57	57/delete_old_current_state_events.sql
57	57/device_list_remote_cache_stale.sql
57	57/local_current_membership.py
57	57/remove_sent_outbound_pokes.sql
57	57/rooms_version_column.sql
57	57/rooms_version_column_2.sql.postgres
57	57/rooms_version_column_3.sql.postgres
58	58/00background_update_ordering.sql
58	58/02remove_dup_outbound_pokes.sql
58	58/03persist_ui_auth.sql
58	58/05cache_instance.sql.postgres
58	58/06dlols_unique_idx.py
\.
COPY public.appservice_room_list (appservice_id, network_id, room_id) FROM stdin;
\.
COPY public.appservice_stream_position (lock, stream_ordering) FROM stdin;
X	19
\.
COPY public.background_updates (update_name, progress_json, depends_on, ordering) FROM stdin;
\.
COPY public.blocked_rooms (room_id, user_id) FROM stdin;
\.
COPY public.cache_invalidation_stream (stream_id, cache_func, keys, invalidation_ts) FROM stdin;
\.
COPY public.cache_invalidation_stream_by_instance (stream_id, instance_name, cache_func, keys, invalidation_ts) FROM stdin;
1	master	user_last_seen_monthly_active	\N	1598686299114
2	master	get_monthly_active_count	{}	1598686299118
3	master	get_user_by_id	{@admin:localhost}	1598686326905
4	master	get_user_by_id	{@matrix_a:localhost}	1598686327226
5	master	get_user_by_id	{@matrix_b:localhost}	1598686327473
6	master	get_user_by_id	{@ignored_user:localhost}	1598686327717
7	master	get_aliases_for_room	{!kmbTYjjsDRDHGgVqUP:localhost}	1598686327750
8	master	cs_cache_fake	{!kmbTYjjsDRDHGgVqUP:localhost}	1598686327775
9	master	cs_cache_fake	{!kmbTYjjsDRDHGgVqUP:localhost,@admin:localhost}	1598686327828
10	master	cs_cache_fake	{!kmbTYjjsDRDHGgVqUP:localhost}	1598686327865
11	master	cs_cache_fake	{!kmbTYjjsDRDHGgVqUP:localhost}	1598686328014
12	master	cs_cache_fake	{!kmbTYjjsDRDHGgVqUP:localhost}	1598686328094
13	master	cs_cache_fake	{!kmbTYjjsDRDHGgVqUP:localhost}	1598686328165
14	master	get_aliases_for_room	{!dKcbdDATuwwphjRPQP:localhost}	1598686328206
15	master	cs_cache_fake	{!dKcbdDATuwwphjRPQP:localhost}	1598686328225
16	master	cs_cache_fake	{!dKcbdDATuwwphjRPQP:localhost,@admin:localhost}	1598686328264
17	master	cs_cache_fake	{!dKcbdDATuwwphjRPQP:localhost}	1598686328293
18	master	cs_cache_fake	{!dKcbdDATuwwphjRPQP:localhost}	1598686328324
19	master	cs_cache_fake	{!dKcbdDATuwwphjRPQP:localhost}	1598686328352
20	master	cs_cache_fake	{!dKcbdDATuwwphjRPQP:localhost}	1598686328382
21	master	cs_cache_fake	{!kmbTYjjsDRDHGgVqUP:localhost,@matrix_a:localhost}	1598686328424
22	master	cs_cache_fake	{!dKcbdDATuwwphjRPQP:localhost,@matrix_a:localhost}	1598686328465
23	master	cs_cache_fake	{!kmbTYjjsDRDHGgVqUP:localhost,@matrix_b:localhost}	1598686328510
24	master	cs_cache_fake	{!dKcbdDATuwwphjRPQP:localhost,@matrix_b:localhost}	1598686328549
25	master	cs_cache_fake	{!kmbTYjjsDRDHGgVqUP:localhost,@ignored_user:localhost}	1598686328591
26	master	cs_cache_fake	{!dKcbdDATuwwphjRPQP:localhost,@ignored_user:localhost}	1598686328631
\.
COPY public.current_state_delta_stream (stream_id, room_id, type, state_key, event_id, prev_event_id) FROM stdin;
2	!kmbTYjjsDRDHGgVqUP:localhost	m.room.create		$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	\N
3	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@admin:localhost	$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	\N
4	!kmbTYjjsDRDHGgVqUP:localhost	m.room.power_levels		$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	\N
5	!kmbTYjjsDRDHGgVqUP:localhost	m.room.canonical_alias		$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	\N
6	!kmbTYjjsDRDHGgVqUP:localhost	m.room.join_rules		$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	\N
7	!kmbTYjjsDRDHGgVqUP:localhost	m.room.history_visibility		$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	\N
8	!dKcbdDATuwwphjRPQP:localhost	m.room.create		$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	\N
9	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@admin:localhost	$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	\N
10	!dKcbdDATuwwphjRPQP:localhost	m.room.power_levels		$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	\N
11	!dKcbdDATuwwphjRPQP:localhost	m.room.canonical_alias		$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	\N
12	!dKcbdDATuwwphjRPQP:localhost	m.room.join_rules		$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	\N
13	!dKcbdDATuwwphjRPQP:localhost	m.room.history_visibility		$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	\N
14	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@matrix_a:localhost	$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	\N
15	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@matrix_a:localhost	$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	\N
16	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@matrix_b:localhost	$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	\N
17	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@matrix_b:localhost	$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	\N
18	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@ignored_user:localhost	$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	\N
19	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@ignored_user:localhost	$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	\N
\.
COPY public.current_state_events (event_id, room_id, type, state_key, membership) FROM stdin;
$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost	m.room.create		\N
$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@admin:localhost	join
$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	!kmbTYjjsDRDHGgVqUP:localhost	m.room.power_levels		\N
$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	!kmbTYjjsDRDHGgVqUP:localhost	m.room.canonical_alias		\N
$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	!kmbTYjjsDRDHGgVqUP:localhost	m.room.join_rules		\N
$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	!kmbTYjjsDRDHGgVqUP:localhost	m.room.history_visibility		\N
$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost	m.room.create		\N
$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@admin:localhost	join
$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	!dKcbdDATuwwphjRPQP:localhost	m.room.power_levels		\N
$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	!dKcbdDATuwwphjRPQP:localhost	m.room.canonical_alias		\N
$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	!dKcbdDATuwwphjRPQP:localhost	m.room.join_rules		\N
$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	!dKcbdDATuwwphjRPQP:localhost	m.room.history_visibility		\N
$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@matrix_a:localhost	join
$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@matrix_a:localhost	join
$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@matrix_b:localhost	join
$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@matrix_b:localhost	join
$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@ignored_user:localhost	join
$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@ignored_user:localhost	join
\.
COPY public.deleted_pushers (stream_id, app_id, pushkey, user_id) FROM stdin;
\.
COPY public.destinations (destination, retry_last_ts, retry_interval, failure_ts) FROM stdin;
\.
COPY public.device_federation_inbox (origin, message_id, received_ts) FROM stdin;
\.
COPY public.device_federation_outbox (destination, stream_id, queued_ts, messages_json) FROM stdin;
\.
COPY public.device_inbox (user_id, device_id, stream_id, message_json) FROM stdin;
\.
COPY public.device_lists_outbound_last_success (destination, user_id, stream_id) FROM stdin;
\.
COPY public.device_lists_outbound_pokes (destination, stream_id, user_id, device_id, sent, ts, opentracing_context) FROM stdin;
\.
COPY public.device_lists_remote_cache (user_id, device_id, content) FROM stdin;
\.
COPY public.device_lists_remote_extremeties (user_id, stream_id) FROM stdin;
\.
COPY public.device_lists_remote_resync (user_id, added_ts) FROM stdin;
\.
COPY public.device_lists_stream (stream_id, user_id, device_id) FROM stdin;
2	@admin:localhost	WCSUBIGVWG
3	@matrix_a:localhost	TKAVEOGKHH
4	@matrix_b:localhost	DJFHSWMXLW
5	@ignored_user:localhost	IYEBBQEXHS
\.
COPY public.device_max_stream_id (stream_id) FROM stdin;
0
\.
COPY public.devices (user_id, device_id, display_name, last_seen, ip, user_agent, hidden) FROM stdin;
@admin:localhost	WCSUBIGVWG	\N	1598686327741	172.21.0.1	curl/7.72.0	f
@matrix_a:localhost	TKAVEOGKHH	\N	1598686328398	172.21.0.1	curl/7.72.0	f
@matrix_b:localhost	DJFHSWMXLW	\N	1598686328482	172.21.0.1	curl/7.72.0	f
@ignored_user:localhost	IYEBBQEXHS	\N	1598686328565	172.21.0.1	curl/7.72.0	f
\.
COPY public.e2e_cross_signing_keys (user_id, keytype, keydata, stream_id) FROM stdin;
\.
COPY public.e2e_cross_signing_signatures (user_id, key_id, target_user_id, target_device_id, signature) FROM stdin;
\.
COPY public.e2e_device_keys_json (user_id, device_id, ts_added_ms, key_json) FROM stdin;
\.
COPY public.e2e_one_time_keys_json (user_id, device_id, algorithm, key_id, ts_added_ms, key_json) FROM stdin;
\.
COPY public.e2e_room_keys (user_id, room_id, session_id, version, first_message_index, forwarded_count, is_verified, session_data) FROM stdin;
\.
COPY public.e2e_room_keys_versions (user_id, version, algorithm, auth_data, deleted, etag) FROM stdin;
\.
COPY public.erased_users (user_id) FROM stdin;
\.
COPY public.event_auth (event_id, auth_id, room_id) FROM stdin;
$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost
$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost
$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	!kmbTYjjsDRDHGgVqUP:localhost
$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	!kmbTYjjsDRDHGgVqUP:localhost
$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost
$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	!kmbTYjjsDRDHGgVqUP:localhost
$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	!kmbTYjjsDRDHGgVqUP:localhost
$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost
$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	!kmbTYjjsDRDHGgVqUP:localhost
$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	!kmbTYjjsDRDHGgVqUP:localhost
$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost
$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	!kmbTYjjsDRDHGgVqUP:localhost
$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost
$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost
$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	!dKcbdDATuwwphjRPQP:localhost
$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	!dKcbdDATuwwphjRPQP:localhost
$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost
$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	!dKcbdDATuwwphjRPQP:localhost
$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	!dKcbdDATuwwphjRPQP:localhost
$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost
$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	!dKcbdDATuwwphjRPQP:localhost
$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	!dKcbdDATuwwphjRPQP:localhost
$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost
$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	!dKcbdDATuwwphjRPQP:localhost
$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	!kmbTYjjsDRDHGgVqUP:localhost
$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost
$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	!kmbTYjjsDRDHGgVqUP:localhost
$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	!dKcbdDATuwwphjRPQP:localhost
$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost
$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	!dKcbdDATuwwphjRPQP:localhost
$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	!kmbTYjjsDRDHGgVqUP:localhost
$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost
$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	!kmbTYjjsDRDHGgVqUP:localhost
$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	!dKcbdDATuwwphjRPQP:localhost
$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost
$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	!dKcbdDATuwwphjRPQP:localhost
$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	!kmbTYjjsDRDHGgVqUP:localhost
$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	!kmbTYjjsDRDHGgVqUP:localhost
$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost
$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	!dKcbdDATuwwphjRPQP:localhost
$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	!dKcbdDATuwwphjRPQP:localhost
$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost
\.
COPY public.event_backward_extremities (event_id, room_id) FROM stdin;
\.
COPY public.event_edges (event_id, prev_event_id, room_id, is_state) FROM stdin;
$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost	f
$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	!kmbTYjjsDRDHGgVqUP:localhost	f
$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	!kmbTYjjsDRDHGgVqUP:localhost	f
$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	!kmbTYjjsDRDHGgVqUP:localhost	f
$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	!kmbTYjjsDRDHGgVqUP:localhost	f
$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost	f
$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	!dKcbdDATuwwphjRPQP:localhost	f
$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	!dKcbdDATuwwphjRPQP:localhost	f
$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	!dKcbdDATuwwphjRPQP:localhost	f
$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	!dKcbdDATuwwphjRPQP:localhost	f
$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	!kmbTYjjsDRDHGgVqUP:localhost	f
$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	!dKcbdDATuwwphjRPQP:localhost	f
$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	!kmbTYjjsDRDHGgVqUP:localhost	f
$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	!dKcbdDATuwwphjRPQP:localhost	f
$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	!kmbTYjjsDRDHGgVqUP:localhost	f
$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	!dKcbdDATuwwphjRPQP:localhost	f
\.
COPY public.event_expiry (event_id, expiry_ts) FROM stdin;
\.
COPY public.event_forward_extremities (event_id, room_id) FROM stdin;
$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	!kmbTYjjsDRDHGgVqUP:localhost
$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	!dKcbdDATuwwphjRPQP:localhost
\.
COPY public.event_json (event_id, room_id, internal_metadata, json, format_version) FROM stdin;
$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost	{"token_id": 2, "stream_ordering": 2}	{"auth_events": [], "prev_events": [], "type": "m.room.create", "room_id": "!kmbTYjjsDRDHGgVqUP:localhost", "sender": "@admin:localhost", "content": {"room_version": "5", "creator": "@admin:localhost"}, "depth": 1, "prev_state": [], "state_key": "", "origin": "localhost", "origin_server_ts": 1598686327756, "hashes": {"sha256": "EYS5stv7QephkSDEw4lMn8/fCE1EfcXS2SKhS9x689c"}, "signatures": {"localhost": {"ed25519:a_snHR": "47z+ybf1v6crQ75SkpwjCPDQ561xdI6SuXgpQHOugqlu7Qkvp1y2U97Z35JRCNa7R0sQvM4rVijYk+YgtbckDw"}}, "unsigned": {"age_ts": 1598686327756}}	3
$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	!kmbTYjjsDRDHGgVqUP:localhost	{"token_id": 2, "stream_ordering": 3}	{"auth_events": ["$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU"], "prev_events": ["$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU"], "type": "m.room.member", "room_id": "!kmbTYjjsDRDHGgVqUP:localhost", "sender": "@admin:localhost", "content": {"membership": "join", "displayname": "admin"}, "depth": 2, "prev_state": [], "state_key": "@admin:localhost", "origin": "localhost", "origin_server_ts": 1598686327803, "hashes": {"sha256": "bFr14ZS6aZalThpjLQ5BkY11tTZqSnnNO5FjkIpsH+0"}, "signatures": {"localhost": {"ed25519:a_snHR": "pvC4gEUv8FV2lKeI3sP1lfY7/eRbZBfNpbWT8v4a8Y9pq+oWw1xozvImaXKjgKgnLKkfEL8U2SKf5Wzchv2iCg"}}, "unsigned": {"age_ts": 1598686327803}}	3
$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	!kmbTYjjsDRDHGgVqUP:localhost	{"token_id": 2, "stream_ordering": 4}	{"auth_events": ["$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU", "$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw"], "prev_events": ["$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw"], "type": "m.room.power_levels", "room_id": "!kmbTYjjsDRDHGgVqUP:localhost", "sender": "@admin:localhost", "content": {"users": {"@admin:localhost": 100}, "users_default": 50, "events": {"m.room.name": 50, "m.room.power_levels": 100, "m.room.history_visibility": 100, "m.room.canonical_alias": 50, "m.room.avatar": 50, "m.room.tombstone": 100, "m.room.server_acl": 100, "m.room.encryption": 100}, "events_default": 0, "state_default": 50, "ban": 50, "kick": 50, "redact": 50, "invite": 50}, "depth": 3, "prev_state": [], "state_key": "", "origin": "localhost", "origin_server_ts": 1598686327849, "hashes": {"sha256": "XRXI1VrMo2lX8l4Xw+9l9POam98NXILANHKa0cTiec8"}, "signatures": {"localhost": {"ed25519:a_snHR": "BpCH59dvjhLkXrhrLvAvctHHpDo5xjfKyPKNPURSOjO9a6M+bBF8BYorYCZ82nY6VuxkpcBEXfqoq0sTZtd3Bw"}}, "unsigned": {"age_ts": 1598686327849}}	3
$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	!kmbTYjjsDRDHGgVqUP:localhost	{"token_id": 2, "stream_ordering": 5}	{"auth_events": ["$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w", "$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU", "$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw"], "prev_events": ["$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w"], "type": "m.room.canonical_alias", "room_id": "!kmbTYjjsDRDHGgVqUP:localhost", "sender": "@admin:localhost", "content": {"alias": "#town-square:localhost"}, "depth": 4, "prev_state": [], "state_key": "", "origin": "localhost", "origin_server_ts": 1598686327933, "hashes": {"sha256": "JFEosUjTDFb17hL0ogqGvy8PsyFS5AfoImme80JxoBs"}, "signatures": {"localhost": {"ed25519:a_snHR": "fIKrBbyf1iHHSpgs1le6Qt6UIhEqGv37ptN9EYF20qOo80r2hFizzL4QUea1iU4Y2eXLXeSbgMyRIBTgNMqCCA"}}, "unsigned": {"age_ts": 1598686327933}}	3
$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	!kmbTYjjsDRDHGgVqUP:localhost	{"token_id": 2, "stream_ordering": 6}	{"auth_events": ["$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w", "$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU", "$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw"], "prev_events": ["$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg"], "type": "m.room.join_rules", "room_id": "!kmbTYjjsDRDHGgVqUP:localhost", "sender": "@admin:localhost", "content": {"join_rule": "public"}, "depth": 5, "prev_state": [], "state_key": "", "origin": "localhost", "origin_server_ts": 1598686328055, "hashes": {"sha256": "jp1fVxbt3dpJlxSWBs8TDJPKkwiNi8RubTXSwOu2cDE"}, "signatures": {"localhost": {"ed25519:a_snHR": "O1DxN7P7TkUmUp2mTvmbynx8sE967SMMDNvWWukJhW/k0Eycxe1aORQInqOx03jBFS91blUjSiame9d4SsflDQ"}}, "unsigned": {"age_ts": 1598686328055}}	3
$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	!kmbTYjjsDRDHGgVqUP:localhost	{"token_id": 2, "stream_ordering": 7}	{"auth_events": ["$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w", "$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU", "$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw"], "prev_events": ["$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o"], "type": "m.room.history_visibility", "room_id": "!kmbTYjjsDRDHGgVqUP:localhost", "sender": "@admin:localhost", "content": {"history_visibility": "shared"}, "depth": 6, "prev_state": [], "state_key": "", "origin": "localhost", "origin_server_ts": 1598686328127, "hashes": {"sha256": "O2HALjh6GpvXYKFGkSI+lQPuJUFwuC032xlArlAC5cU"}, "signatures": {"localhost": {"ed25519:a_snHR": "q2f7/7Q5deI4D976foS2hEJ2u5V5P+rShlUHGLrZ4F1H2xTj+UYejDJbqzhmp6fHwz/tlXtcij6B/PahZDlFCw"}}, "unsigned": {"age_ts": 1598686328127}}	3
$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost	{"token_id": 2, "stream_ordering": 8}	{"auth_events": [], "prev_events": [], "type": "m.room.create", "room_id": "!dKcbdDATuwwphjRPQP:localhost", "sender": "@admin:localhost", "content": {"room_version": "5", "creator": "@admin:localhost"}, "depth": 1, "prev_state": [], "state_key": "", "origin": "localhost", "origin_server_ts": 1598686328210, "hashes": {"sha256": "T2bzVfgzt2griHNrK55gMsLkl82Nz9F/wK3x7lQm0zA"}, "signatures": {"localhost": {"ed25519:a_snHR": "o9ngIVjMu0CXzzIzhHQj+YOJPsXjIAmlQdW+9L6ERQBo8fIQYDUESAAqjGJVhToPS1mFueV7SU7hGRWpd7JSCQ"}}, "unsigned": {"age_ts": 1598686328210}}	3
$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	!dKcbdDATuwwphjRPQP:localhost	{"token_id": 2, "stream_ordering": 9}	{"auth_events": ["$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88"], "prev_events": ["$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88"], "type": "m.room.member", "room_id": "!dKcbdDATuwwphjRPQP:localhost", "sender": "@admin:localhost", "content": {"membership": "join", "displayname": "admin"}, "depth": 2, "prev_state": [], "state_key": "@admin:localhost", "origin": "localhost", "origin_server_ts": 1598686328245, "hashes": {"sha256": "U+/LJW/8SXvlDad8ry9B6gtyrwdAQgQrnsYdoLjFX4c"}, "signatures": {"localhost": {"ed25519:a_snHR": "UFL/8lWTieRcORLzp9XHt+jQ+3dtgGCMRtkmtgbJK1wtJsKvM0Vj+Se/PYxp9D9owNYTYvenbn+Ape9jAWmQDA"}}, "unsigned": {"age_ts": 1598686328245}}	3
$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	!dKcbdDATuwwphjRPQP:localhost	{"token_id": 2, "stream_ordering": 10}	{"auth_events": ["$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88", "$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA"], "prev_events": ["$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA"], "type": "m.room.power_levels", "room_id": "!dKcbdDATuwwphjRPQP:localhost", "sender": "@admin:localhost", "content": {"users": {"@admin:localhost": 100}, "users_default": 50, "events": {"m.room.name": 50, "m.room.power_levels": 100, "m.room.history_visibility": 100, "m.room.canonical_alias": 50, "m.room.avatar": 50, "m.room.tombstone": 100, "m.room.server_acl": 100, "m.room.encryption": 100}, "events_default": 0, "state_default": 50, "ban": 50, "kick": 50, "redact": 50, "invite": 50}, "depth": 3, "prev_state": [], "state_key": "", "origin": "localhost", "origin_server_ts": 1598686328280, "hashes": {"sha256": "uhHLqmMxCXLN+w/WytCiGDedq/bLxHrToWTEkOKf9ew"}, "signatures": {"localhost": {"ed25519:a_snHR": "MlX+Q/aDPzkzLhX5vXzxUqlIh1xTg7shPZ6xg5FfsX7xzRzjEyI/zEdQBts8ZNaN0S/rf9Nj43Bde2xRz1xICA"}}, "unsigned": {"age_ts": 1598686328280}}	3
$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	!dKcbdDATuwwphjRPQP:localhost	{"token_id": 2, "stream_ordering": 11}	{"auth_events": ["$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII", "$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88", "$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA"], "prev_events": ["$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII"], "type": "m.room.canonical_alias", "room_id": "!dKcbdDATuwwphjRPQP:localhost", "sender": "@admin:localhost", "content": {"alias": "#off-topic:localhost"}, "depth": 4, "prev_state": [], "state_key": "", "origin": "localhost", "origin_server_ts": 1598686328305, "hashes": {"sha256": "+JxLKTsEQryx+GEAalUCnv6Rke8EWjX/fPemyJsDHYc"}, "signatures": {"localhost": {"ed25519:a_snHR": "Cjxg3dN0RmH45DnHWi6hpxa+uebFjCgGQV7rVZrz07nq0D2m/m6xetGsZChX81YA7bTlSaZYZbguZo25iAhsBA"}}, "unsigned": {"age_ts": 1598686328305}}	3
$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	!dKcbdDATuwwphjRPQP:localhost	{"token_id": 2, "stream_ordering": 12}	{"auth_events": ["$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII", "$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88", "$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA"], "prev_events": ["$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw"], "type": "m.room.join_rules", "room_id": "!dKcbdDATuwwphjRPQP:localhost", "sender": "@admin:localhost", "content": {"join_rule": "public"}, "depth": 5, "prev_state": [], "state_key": "", "origin": "localhost", "origin_server_ts": 1598686328338, "hashes": {"sha256": "dxq9CFlffHYBvZuBxLJd5stg6IQ3QXbXZ+NE6ebxX70"}, "signatures": {"localhost": {"ed25519:a_snHR": "Uxvxrm+8J8TXY4TQmd21VQ8FquEl8i2G+J4Key2ULCdTPPuLYVzHptZ2XsY+qVkQQ/j7O8GzZor91QnuTO6OAQ"}}, "unsigned": {"age_ts": 1598686328338}}	3
$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	!dKcbdDATuwwphjRPQP:localhost	{"token_id": 2, "stream_ordering": 13}	{"auth_events": ["$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII", "$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88", "$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA"], "prev_events": ["$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs"], "type": "m.room.history_visibility", "room_id": "!dKcbdDATuwwphjRPQP:localhost", "sender": "@admin:localhost", "content": {"history_visibility": "shared"}, "depth": 6, "prev_state": [], "state_key": "", "origin": "localhost", "origin_server_ts": 1598686328366, "hashes": {"sha256": "SfV6Kek5Dwi5pw8ipLU5QhGIZ2QJnoj9F6CDcc5IxB4"}, "signatures": {"localhost": {"ed25519:a_snHR": "5ykJ0Blf6mxyCyowVrPMqCBd1CoGzhyHcTYeI54eSztGls6SbF9v0VY23IxdEiYh6Sbb4p/YqhWE5BK0bC99Dg"}}, "unsigned": {"age_ts": 1598686328366}}	3
$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	!kmbTYjjsDRDHGgVqUP:localhost	{"token_id": 3, "stream_ordering": 14}	{"auth_events": ["$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w", "$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU", "$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o"], "prev_events": ["$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0"], "type": "m.room.member", "room_id": "!kmbTYjjsDRDHGgVqUP:localhost", "sender": "@matrix_a:localhost", "content": {"membership": "join", "displayname": "matrix_a"}, "depth": 7, "prev_state": [], "state_key": "@matrix_a:localhost", "origin": "localhost", "origin_server_ts": 1598686328406, "hashes": {"sha256": "qLMDs9emxYRXqTqqxoKZcDmjV5VXvdIs3XRGMxFZnbk"}, "signatures": {"localhost": {"ed25519:a_snHR": "xsf3Ds6FQ7mG4614Oiydc3TFdQak3qCYQ/OTfnE+Yd8GclvIc/cMtCrz5VTAjRLIHwoctkLkHraQcxnHkFzwCw"}}, "unsigned": {"age_ts": 1598686328406}}	3
$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	!dKcbdDATuwwphjRPQP:localhost	{"token_id": 3, "stream_ordering": 15}	{"auth_events": ["$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII", "$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88", "$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs"], "prev_events": ["$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ"], "type": "m.room.member", "room_id": "!dKcbdDATuwwphjRPQP:localhost", "sender": "@matrix_a:localhost", "content": {"membership": "join", "displayname": "matrix_a"}, "depth": 7, "prev_state": [], "state_key": "@matrix_a:localhost", "origin": "localhost", "origin_server_ts": 1598686328450, "hashes": {"sha256": "Bf7Ixij40HV9U18YkDyyR2LTpCTLLhlY3GoSLyLra6c"}, "signatures": {"localhost": {"ed25519:a_snHR": "qsG72VTiWey+fdCVuq4zZWl8IPFwfI1GBpO4iL+axu/ctL5BEo/YYJmWmTJMOz3z4ZyLj8NN/QpwX+p2A8BRDA"}}, "unsigned": {"age_ts": 1598686328450}}	3
$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	!dKcbdDATuwwphjRPQP:localhost	{"token_id": 4, "stream_ordering": 17}	{"auth_events": ["$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII", "$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88", "$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs"], "prev_events": ["$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0"], "type": "m.room.member", "room_id": "!dKcbdDATuwwphjRPQP:localhost", "sender": "@matrix_b:localhost", "content": {"membership": "join", "displayname": "matrix_b"}, "depth": 8, "prev_state": [], "state_key": "@matrix_b:localhost", "origin": "localhost", "origin_server_ts": 1598686328533, "hashes": {"sha256": "uTzAP3DsMrG8vtss7fDEFt+NvMlkJcrp1JpDI+zCYJw"}, "signatures": {"localhost": {"ed25519:a_snHR": "KebfBSToXNEpvTIjoOVA/dUohbdbS6NpSahz9yHvU1HfdpsPGqxwxrwMNuhXaRHzRO6hV0VNgIKyN09GaKNZCg"}}, "unsigned": {"age_ts": 1598686328533}}	3
$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	!dKcbdDATuwwphjRPQP:localhost	{"token_id": 5, "stream_ordering": 19}	{"auth_events": ["$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII", "$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs", "$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88"], "prev_events": ["$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0"], "type": "m.room.member", "room_id": "!dKcbdDATuwwphjRPQP:localhost", "sender": "@ignored_user:localhost", "content": {"membership": "join", "displayname": "ignored_user"}, "depth": 9, "prev_state": [], "state_key": "@ignored_user:localhost", "origin": "localhost", "origin_server_ts": 1598686328616, "hashes": {"sha256": "jMkusmfkT7UyF+M8kX/BlBE9cfKlzHtTJumYpcHpBus"}, "signatures": {"localhost": {"ed25519:a_snHR": "OqjM8HC+e4wgWSg64xtgWjy8XhQfXWRLcTO8eDmzywvsGEetzg2MbNi+8UeaO+k0HgySjOQdD+uU794G1VQcBA"}}, "unsigned": {"age_ts": 1598686328616}}	3
$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	!kmbTYjjsDRDHGgVqUP:localhost	{"token_id": 4, "stream_ordering": 16}	{"auth_events": ["$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w", "$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU", "$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o"], "prev_events": ["$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8"], "type": "m.room.member", "room_id": "!kmbTYjjsDRDHGgVqUP:localhost", "sender": "@matrix_b:localhost", "content": {"membership": "join", "displayname": "matrix_b"}, "depth": 8, "prev_state": [], "state_key": "@matrix_b:localhost", "origin": "localhost", "origin_server_ts": 1598686328493, "hashes": {"sha256": "cH8tXUk5lxa0k+40sn0aVCgn+JhxncHg3R/oYnHUDlU"}, "signatures": {"localhost": {"ed25519:a_snHR": "C43sosgS9LF5roZP7JiJGmrZR2O9nHvC+mPvYZ0+qDm58WLnmpjC0B8Y8Txye0OoW8HsBqxhJQf10txK8vI6CQ"}}, "unsigned": {"age_ts": 1598686328493}}	3
$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	!kmbTYjjsDRDHGgVqUP:localhost	{"token_id": 5, "stream_ordering": 18}	{"auth_events": ["$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w", "$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o", "$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU"], "prev_events": ["$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk"], "type": "m.room.member", "room_id": "!kmbTYjjsDRDHGgVqUP:localhost", "sender": "@ignored_user:localhost", "content": {"membership": "join", "displayname": "ignored_user"}, "depth": 9, "prev_state": [], "state_key": "@ignored_user:localhost", "origin": "localhost", "origin_server_ts": 1598686328575, "hashes": {"sha256": "D/rwxkYqWZ03Kws7Xsq84khdp4oGHRGnOy4+XwM8dLA"}, "signatures": {"localhost": {"ed25519:a_snHR": "kXK8xKjLjJ97KcFQivelEBI1TR/au+bgtD6i2VPDp9LjRi1bVH/zb6YqHZetT0JYaGt3NY4iFeN0Qh0mD4zyAg"}}, "unsigned": {"age_ts": 1598686328575}}	3
\.
COPY public.event_labels (event_id, label, room_id, topological_ordering) FROM stdin;
\.
COPY public.event_push_actions (room_id, event_id, user_id, profile_tag, actions, topological_ordering, stream_ordering, notif, highlight) FROM stdin;
\.
COPY public.event_push_actions_staging (event_id, user_id, actions, notif, highlight) FROM stdin;
\.
COPY public.event_push_summary (user_id, room_id, notif_count, stream_ordering) FROM stdin;
\.
COPY public.event_push_summary_stream_ordering (lock, stream_ordering) FROM stdin;
X	0
\.
COPY public.event_reference_hashes (event_id, algorithm, hash) FROM stdin;
$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	sha256	\\x981991cb2bcffc973e2c38bbfe18860fd413bb95c6557a8d33164ce320cc40f5
$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	sha256	\\xfe829a68e7cbeeb16d3ec02cc43987ac263db00cc58ec951c2427f407c470d3c
$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	sha256	\\x058c9508fc8987d3d5241b310f09bd35a906635f43942249d46942718a53bfcc
$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	sha256	\\x5fcb5da04b17020042ea0a1b09ea409f7af03bc089a1053a8bd34df51ce1ba48
$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	sha256	\\x1bf9b9f408c7d98d455f80f5d490ec9841137c71805a89274c876ffbf5d85b6a
$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	sha256	\\x3b988ee04208db68a0903ab970c287141f92188603d0aa89417668852d83cdcd
$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	sha256	\\x45cce7e46789d5a60c054fe85d2205f29a5593c584aee698201037144ed8abcf
$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	sha256	\\x3de009e81ca95e325e8078948dc61ef88e827f836e08f2028bfc946fe7f26ae0
$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	sha256	\\x3fdf2fa6d23f8eb35828a9d34c3628b93860a21807a89903e51723d200e0c482
$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	sha256	\\x6fffdaeeb5f72f96295fb9c066d7bbdc301b8ed5d92b8f091fc54a4a718e28ac
$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	sha256	\\x844b65b74354d7a8748b1f71057d0c0c9474839e004c46784bdeae758cd806ab
$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	sha256	\\x4d59efbf49c66cbc9d081b4c9934f3fa1b4cb28238866c42af7b3d007c851874
$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	sha256	\\x377dc6c8e369b926b7cd13499350ad2d8761a896e15c1c12a40954526fb3981f
$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	sha256	\\xc1dfb306c395f4affc1db84f01167dd647f971f6702ca462ef204118635401bd
$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	sha256	\\x9650ad37eb1f542d4839d0d05e0b24831e2397dee14077ca9c41fe20ffa5caf9
$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	sha256	\\xe192dffb725124c2cb0036f3a267b69ffe6b64d11e1c4148a37c35c4de0a2aed
$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	sha256	\\x843d99f811e44ac70e4e27ed7097b59fea5e388b228509506edca34762244e60
$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	sha256	\\x4af7fdd6dc86c94bb37a5607f1b6f333a417b88f5771a6fe5cc5e30ab2203390
\.
COPY public.event_relations (event_id, relates_to_id, relation_type, aggregation_key) FROM stdin;
\.
COPY public.event_reports (id, received_ts, room_id, event_id, user_id, reason, content) FROM stdin;
\.
COPY public.event_search (event_id, room_id, sender, key, vector, origin_server_ts, stream_ordering) FROM stdin;
\.
COPY public.event_to_state_groups (event_id, state_group) FROM stdin;
$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	2
$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	3
$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	4
$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	5
$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	6
$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	7
$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	9
$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	10
$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	11
$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	12
$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	13
$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	14
$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	15
$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	16
$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	17
$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	18
$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	19
$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	20
\.
COPY public.events (stream_ordering, topological_ordering, event_id, type, room_id, content, unrecognized_keys, processed, outlier, depth, origin_server_ts, received_ts, sender, contains_url) FROM stdin;
2	1	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	m.room.create	!kmbTYjjsDRDHGgVqUP:localhost	\N	\N	t	f	1	1598686327756	1598686327770	@admin:localhost	f
3	2	$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	m.room.member	!kmbTYjjsDRDHGgVqUP:localhost	\N	\N	t	f	2	1598686327803	1598686327820	@admin:localhost	f
4	3	$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	m.room.power_levels	!kmbTYjjsDRDHGgVqUP:localhost	\N	\N	t	f	3	1598686327849	1598686327860	@admin:localhost	f
5	4	$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	m.room.canonical_alias	!kmbTYjjsDRDHGgVqUP:localhost	\N	\N	t	f	4	1598686327933	1598686327989	@admin:localhost	f
6	5	$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	m.room.join_rules	!kmbTYjjsDRDHGgVqUP:localhost	\N	\N	t	f	5	1598686328055	1598686328083	@admin:localhost	f
7	6	$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	m.room.history_visibility	!kmbTYjjsDRDHGgVqUP:localhost	\N	\N	t	f	6	1598686328127	1598686328156	@admin:localhost	f
8	1	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	m.room.create	!dKcbdDATuwwphjRPQP:localhost	\N	\N	t	f	1	1598686328210	1598686328221	@admin:localhost	f
9	2	$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	m.room.member	!dKcbdDATuwwphjRPQP:localhost	\N	\N	t	f	2	1598686328245	1598686328258	@admin:localhost	f
10	3	$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	m.room.power_levels	!dKcbdDATuwwphjRPQP:localhost	\N	\N	t	f	3	1598686328280	1598686328291	@admin:localhost	f
11	4	$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	m.room.canonical_alias	!dKcbdDATuwwphjRPQP:localhost	\N	\N	t	f	4	1598686328305	1598686328319	@admin:localhost	f
12	5	$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	m.room.join_rules	!dKcbdDATuwwphjRPQP:localhost	\N	\N	t	f	5	1598686328338	1598686328349	@admin:localhost	f
13	6	$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	m.room.history_visibility	!dKcbdDATuwwphjRPQP:localhost	\N	\N	t	f	6	1598686328366	1598686328379	@admin:localhost	f
14	7	$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	m.room.member	!kmbTYjjsDRDHGgVqUP:localhost	\N	\N	t	f	7	1598686328406	1598686328420	@matrix_a:localhost	f
15	7	$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	m.room.member	!dKcbdDATuwwphjRPQP:localhost	\N	\N	t	f	7	1598686328450	1598686328461	@matrix_a:localhost	f
16	8	$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	m.room.member	!kmbTYjjsDRDHGgVqUP:localhost	\N	\N	t	f	8	1598686328493	1598686328506	@matrix_b:localhost	f
17	8	$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	m.room.member	!dKcbdDATuwwphjRPQP:localhost	\N	\N	t	f	8	1598686328533	1598686328544	@matrix_b:localhost	f
18	9	$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	m.room.member	!kmbTYjjsDRDHGgVqUP:localhost	\N	\N	t	f	9	1598686328575	1598686328587	@ignored_user:localhost	f
19	9	$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	m.room.member	!dKcbdDATuwwphjRPQP:localhost	\N	\N	t	f	9	1598686328616	1598686328628	@ignored_user:localhost	f
\.
COPY public.ex_outlier_stream (event_stream_ordering, event_id, state_group) FROM stdin;
\.
COPY public.federation_stream_position (type, stream_id) FROM stdin;
federation	-1
events	19
\.
COPY public.group_attestations_remote (group_id, user_id, valid_until_ms, attestation_json) FROM stdin;
\.
COPY public.group_attestations_renewals (group_id, user_id, valid_until_ms) FROM stdin;
\.
COPY public.group_invites (group_id, user_id) FROM stdin;
\.
COPY public.group_roles (group_id, role_id, profile, is_public) FROM stdin;
\.
COPY public.group_room_categories (group_id, category_id, profile, is_public) FROM stdin;
\.
COPY public.group_rooms (group_id, room_id, is_public) FROM stdin;
\.
COPY public.group_summary_roles (group_id, role_id, role_order) FROM stdin;
\.
COPY public.group_summary_room_categories (group_id, category_id, cat_order) FROM stdin;
\.
COPY public.group_summary_rooms (group_id, room_id, category_id, room_order, is_public) FROM stdin;
\.
COPY public.group_summary_users (group_id, user_id, role_id, user_order, is_public) FROM stdin;
\.
COPY public.group_users (group_id, user_id, is_admin, is_public) FROM stdin;
\.
COPY public.groups (group_id, name, avatar_url, short_description, long_description, is_public, join_policy) FROM stdin;
\.
COPY public.local_current_membership (room_id, user_id, event_id, membership) FROM stdin;
!kmbTYjjsDRDHGgVqUP:localhost	@admin:localhost	$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	join
!dKcbdDATuwwphjRPQP:localhost	@admin:localhost	$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	join
!kmbTYjjsDRDHGgVqUP:localhost	@matrix_a:localhost	$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	join
!dKcbdDATuwwphjRPQP:localhost	@matrix_a:localhost	$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	join
!kmbTYjjsDRDHGgVqUP:localhost	@matrix_b:localhost	$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	join
!dKcbdDATuwwphjRPQP:localhost	@matrix_b:localhost	$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	join
!kmbTYjjsDRDHGgVqUP:localhost	@ignored_user:localhost	$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	join
!dKcbdDATuwwphjRPQP:localhost	@ignored_user:localhost	$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	join
\.
COPY public.local_group_membership (group_id, user_id, is_admin, membership, is_publicised, content) FROM stdin;
\.
COPY public.local_group_updates (stream_id, group_id, user_id, type, content) FROM stdin;
\.
COPY public.local_invites (stream_id, inviter, invitee, event_id, room_id, locally_rejected, replaced_by) FROM stdin;
\.
COPY public.local_media_repository (media_id, media_type, media_length, created_ts, upload_name, user_id, quarantined_by, url_cache, last_access_ts) FROM stdin;
\.
COPY public.local_media_repository_thumbnails (media_id, thumbnail_width, thumbnail_height, thumbnail_type, thumbnail_method, thumbnail_length) FROM stdin;
\.
COPY public.local_media_repository_url_cache (url, response_code, etag, expires_ts, og, media_id, download_ts) FROM stdin;
\.
COPY public.monthly_active_users (user_id, "timestamp") FROM stdin;
\.
COPY public.open_id_tokens (token, ts_valid_until_ms, user_id) FROM stdin;
\.
COPY public.presence (user_id, state, status_msg, mtime) FROM stdin;
\.
COPY public.presence_allow_inbound (observed_user_id, observer_user_id) FROM stdin;
\.
COPY public.presence_stream (stream_id, user_id, state, last_active_ts, last_federation_update_ts, last_user_sync_ts, status_msg, currently_active) FROM stdin;
\.
COPY public.profiles (user_id, displayname, avatar_url) FROM stdin;
admin	Admin User	\N
matrix_a	Matrix UserA	\N
matrix_b	matrix_b	\N
ignored_user	ignored_user	\N
\.
COPY public.public_room_list_stream (stream_id, room_id, visibility, appservice_id, network_id) FROM stdin;
\.
COPY public.push_rules (id, user_name, rule_id, priority_class, priority, conditions, actions) FROM stdin;
\.
COPY public.push_rules_enable (id, user_name, rule_id, enabled) FROM stdin;
\.
COPY public.push_rules_stream (stream_id, event_stream_ordering, user_id, rule_id, op, priority_class, priority, conditions, actions) FROM stdin;
\.
COPY public.pusher_throttle (pusher, room_id, last_sent_ts, throttle_ms) FROM stdin;
\.
COPY public.pushers (id, user_name, access_token, profile_tag, kind, app_id, app_display_name, device_display_name, pushkey, ts, lang, data, last_stream_ordering, last_success, failing_since) FROM stdin;
\.
COPY public.ratelimit_override (user_id, messages_per_second, burst_count) FROM stdin;
\.
COPY public.receipts_graph (room_id, receipt_type, user_id, event_ids, data) FROM stdin;
\.
COPY public.receipts_linearized (stream_id, room_id, receipt_type, user_id, event_id, data) FROM stdin;
\.
COPY public.received_transactions (transaction_id, origin, ts, response_code, response_json, has_been_referenced) FROM stdin;
\.
COPY public.redactions (event_id, redacts, have_censored, received_ts) FROM stdin;
\.
COPY public.rejections (event_id, reason, last_check) FROM stdin;
\.
COPY public.remote_media_cache (media_origin, media_id, media_type, created_ts, upload_name, media_length, filesystem_id, last_access_ts, quarantined_by) FROM stdin;
\.
COPY public.remote_media_cache_thumbnails (media_origin, media_id, thumbnail_width, thumbnail_height, thumbnail_method, thumbnail_type, thumbnail_length, filesystem_id) FROM stdin;
\.
COPY public.remote_profile_cache (user_id, displayname, avatar_url, last_check) FROM stdin;
\.
COPY public.room_account_data (user_id, room_id, account_data_type, stream_id, content) FROM stdin;
\.
COPY public.room_alias_servers (room_alias, server) FROM stdin;
#town-square:localhost	localhost
#off-topic:localhost	localhost
\.
COPY public.room_aliases (room_alias, room_id, creator) FROM stdin;
#town-square:localhost	!kmbTYjjsDRDHGgVqUP:localhost	@admin:localhost
#off-topic:localhost	!dKcbdDATuwwphjRPQP:localhost	@admin:localhost
\.
COPY public.room_depth (room_id, min_depth) FROM stdin;
!kmbTYjjsDRDHGgVqUP:localhost	1
!dKcbdDATuwwphjRPQP:localhost	1
\.
COPY public.room_memberships (event_id, user_id, sender, room_id, membership, forgotten, display_name, avatar_url) FROM stdin;
$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	@admin:localhost	@admin:localhost	!kmbTYjjsDRDHGgVqUP:localhost	join	0	admin	\N
$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	@admin:localhost	@admin:localhost	!dKcbdDATuwwphjRPQP:localhost	join	0	admin	\N
$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	@matrix_a:localhost	@matrix_a:localhost	!kmbTYjjsDRDHGgVqUP:localhost	join	0	matrix_a	\N
$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	@matrix_a:localhost	@matrix_a:localhost	!dKcbdDATuwwphjRPQP:localhost	join	0	matrix_a	\N
$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	@matrix_b:localhost	@matrix_b:localhost	!kmbTYjjsDRDHGgVqUP:localhost	join	0	matrix_b	\N
$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	@matrix_b:localhost	@matrix_b:localhost	!dKcbdDATuwwphjRPQP:localhost	join	0	matrix_b	\N
$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	@ignored_user:localhost	@ignored_user:localhost	!kmbTYjjsDRDHGgVqUP:localhost	join	0	ignored_user	\N
$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	@ignored_user:localhost	@ignored_user:localhost	!dKcbdDATuwwphjRPQP:localhost	join	0	ignored_user	\N
\.
COPY public.room_retention (room_id, event_id, min_lifetime, max_lifetime) FROM stdin;
\.
COPY public.room_stats_current (room_id, current_state_events, joined_members, invited_members, left_members, banned_members, local_users_in_room, completed_delta_stream_id) FROM stdin;
!kmbTYjjsDRDHGgVqUP:localhost	9	4	0	0	0	4	18
!dKcbdDATuwwphjRPQP:localhost	9	4	0	0	0	4	19
\.
COPY public.room_stats_earliest_token (room_id, token) FROM stdin;
\.
COPY public.room_stats_historical (room_id, end_ts, bucket_size, current_state_events, joined_members, invited_members, left_members, banned_members, local_users_in_room, total_events, total_event_bytes) FROM stdin;
!kmbTYjjsDRDHGgVqUP:localhost	1598745600000	86400000	9	4	0	0	0	4	9	6709
!dKcbdDATuwwphjRPQP:localhost	1598745600000	86400000	9	4	0	0	0	4	9	6707
\.
COPY public.room_stats_state (room_id, name, canonical_alias, join_rules, history_visibility, encryption, avatar, guest_access, is_federatable, topic) FROM stdin;
!kmbTYjjsDRDHGgVqUP:localhost	\N	#town-square:localhost	public	shared	\N	\N	\N	t	\N
!dKcbdDATuwwphjRPQP:localhost	\N	#off-topic:localhost	public	shared	\N	\N	\N	t	\N
\.
COPY public.room_tags (user_id, room_id, tag, content) FROM stdin;
\.
COPY public.room_tags_revisions (user_id, room_id, stream_id) FROM stdin;
\.
COPY public.rooms (room_id, is_public, creator, room_version) FROM stdin;
!kmbTYjjsDRDHGgVqUP:localhost	f	@admin:localhost	5
!dKcbdDATuwwphjRPQP:localhost	f	@admin:localhost	5
\.
COPY public.schema_version (lock, version, upgraded) FROM stdin;
X	58	t
\.
COPY public.server_keys_json (server_name, key_id, from_server, ts_added_ms, ts_valid_until_ms, key_json) FROM stdin;
\.
COPY public.server_signature_keys (server_name, key_id, from_server, ts_added_ms, verify_key, ts_valid_until_ms) FROM stdin;
\.
COPY public.state_events (event_id, room_id, type, state_key, prev_state) FROM stdin;
$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU	!kmbTYjjsDRDHGgVqUP:localhost	m.room.create		\N
$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@admin:localhost	\N
$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w	!kmbTYjjsDRDHGgVqUP:localhost	m.room.power_levels		\N
$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg	!kmbTYjjsDRDHGgVqUP:localhost	m.room.canonical_alias		\N
$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o	!kmbTYjjsDRDHGgVqUP:localhost	m.room.join_rules		\N
$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0	!kmbTYjjsDRDHGgVqUP:localhost	m.room.history_visibility		\N
$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88	!dKcbdDATuwwphjRPQP:localhost	m.room.create		\N
$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@admin:localhost	\N
$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII	!dKcbdDATuwwphjRPQP:localhost	m.room.power_levels		\N
$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw	!dKcbdDATuwwphjRPQP:localhost	m.room.canonical_alias		\N
$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs	!dKcbdDATuwwphjRPQP:localhost	m.room.join_rules		\N
$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ	!dKcbdDATuwwphjRPQP:localhost	m.room.history_visibility		\N
$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@matrix_a:localhost	\N
$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@matrix_a:localhost	\N
$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@matrix_b:localhost	\N
$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@matrix_b:localhost	\N
$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@ignored_user:localhost	\N
$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@ignored_user:localhost	\N
\.
COPY public.state_group_edges (state_group, prev_state_group) FROM stdin;
2	1
3	2
4	3
5	4
6	5
7	6
9	8
10	9
11	10
12	11
13	12
14	13
15	7
16	14
17	15
18	16
19	17
20	18
\.
COPY public.state_groups (id, room_id, event_id) FROM stdin;
1	!kmbTYjjsDRDHGgVqUP:localhost	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU
2	!kmbTYjjsDRDHGgVqUP:localhost	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU
3	!kmbTYjjsDRDHGgVqUP:localhost	$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw
4	!kmbTYjjsDRDHGgVqUP:localhost	$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w
5	!kmbTYjjsDRDHGgVqUP:localhost	$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg
6	!kmbTYjjsDRDHGgVqUP:localhost	$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o
7	!kmbTYjjsDRDHGgVqUP:localhost	$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0
8	!dKcbdDATuwwphjRPQP:localhost	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88
9	!dKcbdDATuwwphjRPQP:localhost	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88
10	!dKcbdDATuwwphjRPQP:localhost	$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA
11	!dKcbdDATuwwphjRPQP:localhost	$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII
12	!dKcbdDATuwwphjRPQP:localhost	$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw
13	!dKcbdDATuwwphjRPQP:localhost	$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs
14	!dKcbdDATuwwphjRPQP:localhost	$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ
15	!kmbTYjjsDRDHGgVqUP:localhost	$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8
16	!dKcbdDATuwwphjRPQP:localhost	$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0
17	!kmbTYjjsDRDHGgVqUP:localhost	$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk
18	!dKcbdDATuwwphjRPQP:localhost	$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0
19	!kmbTYjjsDRDHGgVqUP:localhost	$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA
20	!dKcbdDATuwwphjRPQP:localhost	$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A
\.
COPY public.state_groups_state (state_group, room_id, type, state_key, event_id) FROM stdin;
2	!kmbTYjjsDRDHGgVqUP:localhost	m.room.create		$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU
3	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@admin:localhost	$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw
4	!kmbTYjjsDRDHGgVqUP:localhost	m.room.power_levels		$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w
5	!kmbTYjjsDRDHGgVqUP:localhost	m.room.canonical_alias		$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg
6	!kmbTYjjsDRDHGgVqUP:localhost	m.room.join_rules		$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o
7	!kmbTYjjsDRDHGgVqUP:localhost	m.room.history_visibility		$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0
9	!dKcbdDATuwwphjRPQP:localhost	m.room.create		$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88
10	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@admin:localhost	$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA
11	!dKcbdDATuwwphjRPQP:localhost	m.room.power_levels		$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII
12	!dKcbdDATuwwphjRPQP:localhost	m.room.canonical_alias		$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw
13	!dKcbdDATuwwphjRPQP:localhost	m.room.join_rules		$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs
14	!dKcbdDATuwwphjRPQP:localhost	m.room.history_visibility		$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ
15	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@matrix_a:localhost	$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8
16	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@matrix_a:localhost	$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0
17	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@matrix_b:localhost	$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk
18	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@matrix_b:localhost	$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0
19	!kmbTYjjsDRDHGgVqUP:localhost	m.room.member	@ignored_user:localhost	$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA
20	!dKcbdDATuwwphjRPQP:localhost	m.room.member	@ignored_user:localhost	$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A
\.
COPY public.stats_incremental_position (lock, stream_id) FROM stdin;
X	19
\.
COPY public.stream_ordering_to_exterm (stream_ordering, room_id, event_id) FROM stdin;
2	!kmbTYjjsDRDHGgVqUP:localhost	$mBmRyyvP_Jc-LDi7_hiGD9QTu5XGVXqNMxZM4yDMQPU
3	!kmbTYjjsDRDHGgVqUP:localhost	$_oKaaOfL7rFtPsAsxDmHrCY9sAzFjslRwkJ_QHxHDTw
4	!kmbTYjjsDRDHGgVqUP:localhost	$BYyVCPyJh9PVJBsxDwm9NakGY19DlCJJ1GlCcYpTv8w
5	!kmbTYjjsDRDHGgVqUP:localhost	$X8tdoEsXAgBC6gobCepAn3rwO8CJoQU6i9NN9Rzhukg
6	!kmbTYjjsDRDHGgVqUP:localhost	$G_m59AjH2Y1FX4D11JDsmEETfHGAWoknTIdv-_XYW2o
7	!kmbTYjjsDRDHGgVqUP:localhost	$O5iO4EII22igkDq5cMKHFB-SGIYD0KqJQXZohS2Dzc0
8	!dKcbdDATuwwphjRPQP:localhost	$Rczn5GeJ1aYMBU_oXSIF8ppVk8WEruaYIBA3FE7Yq88
9	!dKcbdDATuwwphjRPQP:localhost	$PeAJ6BypXjJegHiUjcYe-I6Cf4NuCPICi_yUb-fyauA
10	!dKcbdDATuwwphjRPQP:localhost	$P98vptI_jrNYKKnTTDYouThgohgHqJkD5Rcj0gDgxII
11	!dKcbdDATuwwphjRPQP:localhost	$b__a7rX3L5YpX7nAZte73DAbjtXZK48JH8VKSnGOKKw
12	!dKcbdDATuwwphjRPQP:localhost	$hEtlt0NU16h0ix9xBX0MDJR0g54ATEZ4S96udYzYBqs
13	!dKcbdDATuwwphjRPQP:localhost	$TVnvv0nGbLydCBtMmTTz-htMsoI4hmxCr3s9AHyFGHQ
14	!kmbTYjjsDRDHGgVqUP:localhost	$N33GyONpuSa3zRNJk1CtLYdhqJbhXBwSpAlUUm-zmB8
15	!dKcbdDATuwwphjRPQP:localhost	$wd-zBsOV9K_8HbhPARZ91kf5cfZwLKRi7yBBGGNUAb0
16	!kmbTYjjsDRDHGgVqUP:localhost	$llCtN-sfVC1IOdDQXgskgx4jl97hQHfKnEH-IP-lyvk
17	!dKcbdDATuwwphjRPQP:localhost	$4ZLf-3JRJMLLADbzome2n_5rZNEeHEFIo3w1xN4KKu0
18	!kmbTYjjsDRDHGgVqUP:localhost	$hD2Z-BHkSscOTiftcJe1n-peOIsihQlQbtyjR2IkTmA
19	!dKcbdDATuwwphjRPQP:localhost	$Svf91tyGyUuzelYH8bbzM6QXuI9Xcab-XMXjCrIgM5A
\.
COPY public.threepid_guest_access_tokens (medium, address, guest_access_token, first_inviter) FROM stdin;
\.
COPY public.threepid_validation_session (session_id, medium, address, client_secret, last_send_attempt, validated_at) FROM stdin;
\.
COPY public.threepid_validation_token (token, session_id, next_link, expires) FROM stdin;
\.
COPY public.ui_auth_sessions (session_id, creation_time, serverdict, clientdict, uri, method, description) FROM stdin;
xeJRRYeggRZPDjZRxsYsQwor	1598686326894	{"registered_user_id": "@admin:localhost"}	{"username": "admin", "password_hash": "$2b$12$y3lT6nJGWMTXBWF2kFRaRuUqALWaFe.dhbEEBKROoFnkoKBuDnLhK"}	/_matrix/client/r0/register	/_matrix/client/r0/register	register a new account
pljISqDsSRaWKiCZKERPVqQR	1598686327218	{"registered_user_id": "@matrix_a:localhost"}	{"username": "matrix_a", "password_hash": "$2b$12$V8cOJ670WikSre/C66CGI.a1ANkbEvkgYEUW.M23dlUnekRcPr08O"}	/_matrix/client/r0/register	/_matrix/client/r0/register	register a new account
SMvQriZwHcUMqIIOdUeQtXzc	1598686327463	{"registered_user_id": "@matrix_b:localhost"}	{"username": "matrix_b", "password_hash": "$2b$12$gnHJ1cdN/bfA2A2V61rPauepmeV2dLXr/pC70rCZy9qZoM9u2GKaq"}	/_matrix/client/r0/register	/_matrix/client/r0/register	register a new account
EGVIALjvHFLqBpLFKyGCObFZ	1598686327708	{"registered_user_id": "@ignored_user:localhost"}	{"username": "ignored_user", "password_hash": "$2b$12$cDOaADzxfGcFFspSrfJNcueOwevhD2Ex0hu6oAJcpz3S/owrOeSsW"}	/_matrix/client/r0/register	/_matrix/client/r0/register	register a new account
\.
COPY public.ui_auth_sessions_credentials (session_id, stage_type, result) FROM stdin;
xeJRRYeggRZPDjZRxsYsQwor	m.login.dummy	true
pljISqDsSRaWKiCZKERPVqQR	m.login.dummy	true
SMvQriZwHcUMqIIOdUeQtXzc	m.login.dummy	true
EGVIALjvHFLqBpLFKyGCObFZ	m.login.dummy	true
\.
COPY public.user_daily_visits (user_id, device_id, "timestamp") FROM stdin;
\.
COPY public.user_directory (user_id, room_id, display_name, avatar_url) FROM stdin;
@admin:localhost	\N	admin	\N
@matrix_a:localhost	\N	matrix_a	\N
@matrix_b:localhost	\N	matrix_b	\N
@ignored_user:localhost	\N	ignored_user	\N
\.
COPY public.user_directory_search (user_id, vector) FROM stdin;
@admin:localhost	'admin':1A,3B 'localhost':2
@matrix_a:localhost	'localhost':2 'matrix':1A,3B
@matrix_b:localhost	'b':2A,5B 'localhost':3 'matrix':1A,4B
@ignored_user:localhost	'ignor':1A,4B 'localhost':3 'user':2A,5B
\.
COPY public.user_directory_stream_pos (lock, stream_id) FROM stdin;
X	19
\.
COPY public.user_external_ids (auth_provider, external_id, user_id) FROM stdin;
\.
COPY public.user_filters (user_id, filter_id, filter_json) FROM stdin;
\.
COPY public.user_ips (user_id, access_token, device_id, ip, user_agent, last_seen) FROM stdin;
@admin:localhost	MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjNjaWQgdXNlcl9pZCA9IEBhZG1pbjpsb2NhbGhvc3QKMDAxNmNpZCB0eXBlID0gYWNjZXNzCjAwMjFjaWQgbm9uY2UgPSBXVU9yUTVRMFRnUkNjME1ACjAwMmZzaWduYXR1cmUgdYKA-yuTQ5JV5O0HWRak-48xavOYgA1MMc6A1V_Uw5kK	WCSUBIGVWG	172.21.0.1	curl/7.72.0	1598686327741
@matrix_a:localhost	MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjZjaWQgdXNlcl9pZCA9IEBtYXRyaXhfYTpsb2NhbGhvc3QKMDAxNmNpZCB0eXBlID0gYWNjZXNzCjAwMjFjaWQgbm9uY2UgPSAwb3Y6eTZVdHojUk4jbFprCjAwMmZzaWduYXR1cmUgNNZKnOVRzj5svh9pEM0UUEqtXYnHjnj9XyNLJ1_uKoAK	TKAVEOGKHH	172.21.0.1	curl/7.72.0	1598686328398
@matrix_b:localhost	MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjZjaWQgdXNlcl9pZCA9IEBtYXRyaXhfYjpsb2NhbGhvc3QKMDAxNmNpZCB0eXBlID0gYWNjZXNzCjAwMjFjaWQgbm9uY2UgPSBBYl9hbWthI0daSzgtfjdICjAwMmZzaWduYXR1cmUgOReBLkPURCMNtzORS9fpogQqVa3IWN9ZEu5gXW91QTMK	DJFHSWMXLW	172.21.0.1	curl/7.72.0	1598686328482
@ignored_user:localhost	MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMmFjaWQgdXNlcl9pZCA9IEBpZ25vcmVkX3VzZXI6bG9jYWxob3N0CjAwMTZjaWQgdHlwZSA9IGFjY2VzcwowMDIxY2lkIG5vbmNlID0gZU5ta1BBMj1FNnVPRGtwdgowMDJmc2lnbmF0dXJlIHSt8jrFU836Ne3it2HY88EhPD1Aoustsm211bbFjcLcCg	IYEBBQEXHS	172.21.0.1	curl/7.72.0	1598686328565
\.
COPY public.user_signature_stream (stream_id, from_user_id, user_ids) FROM stdin;
\.
COPY public.user_stats_current (user_id, joined_rooms, completed_delta_stream_id) FROM stdin;
@admin:localhost	2	13
@matrix_a:localhost	2	15
@matrix_b:localhost	2	17
@ignored_user:localhost	2	19
\.
COPY public.user_stats_historical (user_id, end_ts, bucket_size, joined_rooms, invites_sent, rooms_created, total_events, total_event_bytes) FROM stdin;
@admin:localhost	1641600000	86400000	0	0	0	0	0
@matrix_a:localhost	1641600000	86400000	0	0	0	0	0
@matrix_b:localhost	1641600000	86400000	0	0	0	0	0
@ignored_user:localhost	1641600000	86400000	0	0	0	0	0
@admin:localhost	1598745600000	86400000	2	0	2	12	8826
@matrix_a:localhost	1598745600000	86400000	2	0	0	2	1522
@matrix_b:localhost	1598745600000	86400000	2	0	0	2	1522
@ignored_user:localhost	1598745600000	86400000	2	0	0	2	1546
\.
COPY public.user_threepid_id_server (user_id, medium, address, id_server) FROM stdin;
\.
COPY public.user_threepids (user_id, medium, address, validated_at, added_at) FROM stdin;
\.
COPY public.users (name, password_hash, creation_ts, admin, upgrade_ts, is_guest, appservice_id, consent_version, consent_server_notice_sent, user_type, deactivated) FROM stdin;
@admin:localhost	$2b$12$y3lT6nJGWMTXBWF2kFRaRuUqALWaFe.dhbEEBKROoFnkoKBuDnLhK	1598686326	0	\N	0	\N	\N	\N	\N	0
@matrix_a:localhost	$2b$12$V8cOJ670WikSre/C66CGI.a1ANkbEvkgYEUW.M23dlUnekRcPr08O	1598686327	0	\N	0	\N	\N	\N	\N	0
@matrix_b:localhost	$2b$12$gnHJ1cdN/bfA2A2V61rPauepmeV2dLXr/pC70rCZy9qZoM9u2GKaq	1598686327	0	\N	0	\N	\N	\N	\N	0
@ignored_user:localhost	$2b$12$cDOaADzxfGcFFspSrfJNcueOwevhD2Ex0hu6oAJcpz3S/owrOeSsW	1598686327	0	\N	0	\N	\N	\N	\N	0
\.
COPY public.users_in_public_rooms (user_id, room_id) FROM stdin;
@admin:localhost	!kmbTYjjsDRDHGgVqUP:localhost
@admin:localhost	!dKcbdDATuwwphjRPQP:localhost
@matrix_a:localhost	!kmbTYjjsDRDHGgVqUP:localhost
@matrix_a:localhost	!dKcbdDATuwwphjRPQP:localhost
@matrix_b:localhost	!kmbTYjjsDRDHGgVqUP:localhost
@matrix_b:localhost	!dKcbdDATuwwphjRPQP:localhost
@ignored_user:localhost	!kmbTYjjsDRDHGgVqUP:localhost
@ignored_user:localhost	!dKcbdDATuwwphjRPQP:localhost
\.
COPY public.users_pending_deactivation (user_id) FROM stdin;
\.
COPY public.users_who_share_private_rooms (user_id, other_user_id, room_id) FROM stdin;
\.
SELECT pg_catalog.setval('public.cache_invalidation_stream_seq', 26, true);
SELECT pg_catalog.setval('public.state_group_id_seq', 20, true);
ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT access_tokens_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT access_tokens_token_key UNIQUE (token);
ALTER TABLE ONLY public.account_data
    ADD CONSTRAINT account_data_uniqueness UNIQUE (user_id, account_data_type);
ALTER TABLE ONLY public.account_validity
    ADD CONSTRAINT account_validity_pkey PRIMARY KEY (user_id);
ALTER TABLE ONLY public.application_services_state
    ADD CONSTRAINT application_services_state_pkey PRIMARY KEY (as_id);
ALTER TABLE ONLY public.application_services_txns
    ADD CONSTRAINT application_services_txns_as_id_txn_id_key UNIQUE (as_id, txn_id);
ALTER TABLE ONLY public.applied_module_schemas
    ADD CONSTRAINT applied_module_schemas_module_name_file_key UNIQUE (module_name, file);
ALTER TABLE ONLY public.applied_schema_deltas
    ADD CONSTRAINT applied_schema_deltas_version_file_key UNIQUE (version, file);
ALTER TABLE ONLY public.appservice_stream_position
    ADD CONSTRAINT appservice_stream_position_lock_key UNIQUE (lock);
ALTER TABLE ONLY public.background_updates
    ADD CONSTRAINT background_updates_uniqueness UNIQUE (update_name);
ALTER TABLE ONLY public.current_state_events
    ADD CONSTRAINT current_state_events_event_id_key UNIQUE (event_id);
ALTER TABLE ONLY public.current_state_events
    ADD CONSTRAINT current_state_events_room_id_type_state_key_key UNIQUE (room_id, type, state_key);
ALTER TABLE ONLY public.destinations
    ADD CONSTRAINT destinations_pkey PRIMARY KEY (destination);
ALTER TABLE ONLY public.devices
    ADD CONSTRAINT device_uniqueness UNIQUE (user_id, device_id);
ALTER TABLE ONLY public.e2e_device_keys_json
    ADD CONSTRAINT e2e_device_keys_json_uniqueness UNIQUE (user_id, device_id);
ALTER TABLE ONLY public.e2e_one_time_keys_json
    ADD CONSTRAINT e2e_one_time_keys_json_uniqueness UNIQUE (user_id, device_id, algorithm, key_id);
ALTER TABLE ONLY public.event_backward_extremities
    ADD CONSTRAINT event_backward_extremities_event_id_room_id_key UNIQUE (event_id, room_id);
ALTER TABLE ONLY public.event_edges
    ADD CONSTRAINT event_edges_event_id_prev_event_id_room_id_is_state_key UNIQUE (event_id, prev_event_id, room_id, is_state);
ALTER TABLE ONLY public.event_expiry
    ADD CONSTRAINT event_expiry_pkey PRIMARY KEY (event_id);
ALTER TABLE ONLY public.event_forward_extremities
    ADD CONSTRAINT event_forward_extremities_event_id_room_id_key UNIQUE (event_id, room_id);
ALTER TABLE ONLY public.event_push_actions
    ADD CONSTRAINT event_id_user_id_profile_tag_uniqueness UNIQUE (room_id, event_id, user_id, profile_tag);
ALTER TABLE ONLY public.event_json
    ADD CONSTRAINT event_json_event_id_key UNIQUE (event_id);
ALTER TABLE ONLY public.event_labels
    ADD CONSTRAINT event_labels_pkey PRIMARY KEY (event_id, label);
ALTER TABLE ONLY public.event_push_summary_stream_ordering
    ADD CONSTRAINT event_push_summary_stream_ordering_lock_key UNIQUE (lock);
ALTER TABLE ONLY public.event_reference_hashes
    ADD CONSTRAINT event_reference_hashes_event_id_algorithm_key UNIQUE (event_id, algorithm);
ALTER TABLE ONLY public.event_reports
    ADD CONSTRAINT event_reports_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.event_to_state_groups
    ADD CONSTRAINT event_to_state_groups_event_id_key UNIQUE (event_id);
ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_event_id_key UNIQUE (event_id);
ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (stream_ordering);
ALTER TABLE ONLY public.ex_outlier_stream
    ADD CONSTRAINT ex_outlier_stream_pkey PRIMARY KEY (event_stream_ordering);
ALTER TABLE ONLY public.group_roles
    ADD CONSTRAINT group_roles_group_id_role_id_key UNIQUE (group_id, role_id);
ALTER TABLE ONLY public.group_room_categories
    ADD CONSTRAINT group_room_categories_group_id_category_id_key UNIQUE (group_id, category_id);
ALTER TABLE ONLY public.group_summary_roles
    ADD CONSTRAINT group_summary_roles_group_id_role_id_role_order_key UNIQUE (group_id, role_id, role_order);
ALTER TABLE ONLY public.group_summary_room_categories
    ADD CONSTRAINT group_summary_room_categories_group_id_category_id_cat_orde_key UNIQUE (group_id, category_id, cat_order);
ALTER TABLE ONLY public.group_summary_rooms
    ADD CONSTRAINT group_summary_rooms_group_id_category_id_room_id_room_order_key UNIQUE (group_id, category_id, room_id, room_order);
ALTER TABLE ONLY public.local_media_repository
    ADD CONSTRAINT local_media_repository_media_id_key UNIQUE (media_id);
ALTER TABLE ONLY public.local_media_repository_thumbnails
    ADD CONSTRAINT local_media_repository_thumbn_media_id_thumbnail_width_thum_key UNIQUE (media_id, thumbnail_width, thumbnail_height, thumbnail_type);
ALTER TABLE ONLY public.user_threepids
    ADD CONSTRAINT medium_address UNIQUE (medium, address);
ALTER TABLE ONLY public.open_id_tokens
    ADD CONSTRAINT open_id_tokens_pkey PRIMARY KEY (token);
ALTER TABLE ONLY public.presence_allow_inbound
    ADD CONSTRAINT presence_allow_inbound_observed_user_id_observer_user_id_key UNIQUE (observed_user_id, observer_user_id);
ALTER TABLE ONLY public.presence
    ADD CONSTRAINT presence_user_id_key UNIQUE (user_id);
ALTER TABLE ONLY public.account_data_max_stream_id
    ADD CONSTRAINT private_user_data_max_stream_id_lock_key UNIQUE (lock);
ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_user_id_key UNIQUE (user_id);
ALTER TABLE ONLY public.push_rules_enable
    ADD CONSTRAINT push_rules_enable_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.push_rules_enable
    ADD CONSTRAINT push_rules_enable_user_name_rule_id_key UNIQUE (user_name, rule_id);
ALTER TABLE ONLY public.push_rules
    ADD CONSTRAINT push_rules_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.push_rules
    ADD CONSTRAINT push_rules_user_name_rule_id_key UNIQUE (user_name, rule_id);
ALTER TABLE ONLY public.pusher_throttle
    ADD CONSTRAINT pusher_throttle_pkey PRIMARY KEY (pusher, room_id);
ALTER TABLE ONLY public.pushers
    ADD CONSTRAINT pushers2_app_id_pushkey_user_name_key UNIQUE (app_id, pushkey, user_name);
ALTER TABLE ONLY public.pushers
    ADD CONSTRAINT pushers2_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.receipts_graph
    ADD CONSTRAINT receipts_graph_uniqueness UNIQUE (room_id, receipt_type, user_id);
ALTER TABLE ONLY public.receipts_linearized
    ADD CONSTRAINT receipts_linearized_uniqueness UNIQUE (room_id, receipt_type, user_id);
ALTER TABLE ONLY public.received_transactions
    ADD CONSTRAINT received_transactions_transaction_id_origin_key UNIQUE (transaction_id, origin);
ALTER TABLE ONLY public.redactions
    ADD CONSTRAINT redactions_event_id_key UNIQUE (event_id);
ALTER TABLE ONLY public.rejections
    ADD CONSTRAINT rejections_event_id_key UNIQUE (event_id);
ALTER TABLE ONLY public.remote_media_cache
    ADD CONSTRAINT remote_media_cache_media_origin_media_id_key UNIQUE (media_origin, media_id);
ALTER TABLE ONLY public.remote_media_cache_thumbnails
    ADD CONSTRAINT remote_media_cache_thumbnails_media_origin_media_id_thumbna_key UNIQUE (media_origin, media_id, thumbnail_width, thumbnail_height, thumbnail_type);
ALTER TABLE ONLY public.room_account_data
    ADD CONSTRAINT room_account_data_uniqueness UNIQUE (user_id, room_id, account_data_type);
ALTER TABLE ONLY public.room_aliases
    ADD CONSTRAINT room_aliases_room_alias_key UNIQUE (room_alias);
ALTER TABLE ONLY public.room_depth
    ADD CONSTRAINT room_depth_room_id_key UNIQUE (room_id);
ALTER TABLE ONLY public.room_memberships
    ADD CONSTRAINT room_memberships_event_id_key UNIQUE (event_id);
ALTER TABLE ONLY public.room_retention
    ADD CONSTRAINT room_retention_pkey PRIMARY KEY (room_id, event_id);
ALTER TABLE ONLY public.room_stats_current
    ADD CONSTRAINT room_stats_current_pkey PRIMARY KEY (room_id);
ALTER TABLE ONLY public.room_stats_historical
    ADD CONSTRAINT room_stats_historical_pkey PRIMARY KEY (room_id, end_ts);
ALTER TABLE ONLY public.room_tags_revisions
    ADD CONSTRAINT room_tag_revisions_uniqueness UNIQUE (user_id, room_id);
ALTER TABLE ONLY public.room_tags
    ADD CONSTRAINT room_tag_uniqueness UNIQUE (user_id, room_id, tag);
ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (room_id);
ALTER TABLE ONLY public.schema_version
    ADD CONSTRAINT schema_version_lock_key UNIQUE (lock);
ALTER TABLE ONLY public.server_keys_json
    ADD CONSTRAINT server_keys_json_uniqueness UNIQUE (server_name, key_id, from_server);
ALTER TABLE ONLY public.server_signature_keys
    ADD CONSTRAINT server_signature_keys_server_name_key_id_key UNIQUE (server_name, key_id);
ALTER TABLE ONLY public.state_events
    ADD CONSTRAINT state_events_event_id_key UNIQUE (event_id);
ALTER TABLE ONLY public.state_groups
    ADD CONSTRAINT state_groups_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.stats_incremental_position
    ADD CONSTRAINT stats_incremental_position_lock_key UNIQUE (lock);
ALTER TABLE ONLY public.threepid_validation_session
    ADD CONSTRAINT threepid_validation_session_pkey PRIMARY KEY (session_id);
ALTER TABLE ONLY public.threepid_validation_token
    ADD CONSTRAINT threepid_validation_token_pkey PRIMARY KEY (token);
ALTER TABLE ONLY public.ui_auth_sessions_credentials
    ADD CONSTRAINT ui_auth_sessions_credentials_session_id_stage_type_key UNIQUE (session_id, stage_type);
ALTER TABLE ONLY public.ui_auth_sessions
    ADD CONSTRAINT ui_auth_sessions_session_id_key UNIQUE (session_id);
ALTER TABLE ONLY public.user_directory_stream_pos
    ADD CONSTRAINT user_directory_stream_pos_lock_key UNIQUE (lock);
ALTER TABLE ONLY public.user_external_ids
    ADD CONSTRAINT user_external_ids_auth_provider_external_id_key UNIQUE (auth_provider, external_id);
ALTER TABLE ONLY public.user_stats_current
    ADD CONSTRAINT user_stats_current_pkey PRIMARY KEY (user_id);
ALTER TABLE ONLY public.user_stats_historical
    ADD CONSTRAINT user_stats_historical_pkey PRIMARY KEY (user_id, end_ts);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_name_key UNIQUE (name);
CREATE INDEX access_tokens_device_id ON public.access_tokens USING btree (user_id, device_id);
CREATE INDEX account_data_stream_id ON public.account_data USING btree (user_id, stream_id);
CREATE INDEX application_services_txns_id ON public.application_services_txns USING btree (as_id);
CREATE UNIQUE INDEX appservice_room_list_idx ON public.appservice_room_list USING btree (appservice_id, network_id, room_id);
CREATE UNIQUE INDEX blocked_rooms_idx ON public.blocked_rooms USING btree (room_id);
CREATE UNIQUE INDEX cache_invalidation_stream_by_instance_id ON public.cache_invalidation_stream_by_instance USING btree (stream_id);
CREATE INDEX cache_invalidation_stream_id ON public.cache_invalidation_stream USING btree (stream_id);
CREATE INDEX current_state_delta_stream_idx ON public.current_state_delta_stream USING btree (stream_id);
CREATE INDEX current_state_events_member_index ON public.current_state_events USING btree (state_key) WHERE (type = 'm.room.member'::text);
CREATE INDEX deleted_pushers_stream_id ON public.deleted_pushers USING btree (stream_id);
CREATE INDEX device_federation_inbox_sender_id ON public.device_federation_inbox USING btree (origin, message_id);
CREATE INDEX device_federation_outbox_destination_id ON public.device_federation_outbox USING btree (destination, stream_id);
CREATE INDEX device_federation_outbox_id ON public.device_federation_outbox USING btree (stream_id);
CREATE INDEX device_inbox_stream_id_user_id ON public.device_inbox USING btree (stream_id, user_id);
CREATE INDEX device_inbox_user_stream_id ON public.device_inbox USING btree (user_id, device_id, stream_id);
CREATE UNIQUE INDEX device_lists_outbound_last_success_unique_idx ON public.device_lists_outbound_last_success USING btree (destination, user_id);
CREATE INDEX device_lists_outbound_pokes_id ON public.device_lists_outbound_pokes USING btree (destination, stream_id);
CREATE INDEX device_lists_outbound_pokes_stream ON public.device_lists_outbound_pokes USING btree (stream_id);
CREATE INDEX device_lists_outbound_pokes_user ON public.device_lists_outbound_pokes USING btree (destination, user_id);
CREATE UNIQUE INDEX device_lists_remote_cache_unique_id ON public.device_lists_remote_cache USING btree (user_id, device_id);
CREATE UNIQUE INDEX device_lists_remote_extremeties_unique_idx ON public.device_lists_remote_extremeties USING btree (user_id);
CREATE UNIQUE INDEX device_lists_remote_resync_idx ON public.device_lists_remote_resync USING btree (user_id);
CREATE INDEX device_lists_remote_resync_ts_idx ON public.device_lists_remote_resync USING btree (added_ts);
CREATE INDEX device_lists_stream_id ON public.device_lists_stream USING btree (stream_id, user_id);
CREATE INDEX device_lists_stream_user_id ON public.device_lists_stream USING btree (user_id, device_id);
CREATE UNIQUE INDEX e2e_cross_signing_keys_idx ON public.e2e_cross_signing_keys USING btree (user_id, keytype, stream_id);
CREATE INDEX e2e_cross_signing_signatures2_idx ON public.e2e_cross_signing_signatures USING btree (user_id, target_user_id, target_device_id);
CREATE UNIQUE INDEX e2e_room_keys_versions_idx ON public.e2e_room_keys_versions USING btree (user_id, version);
CREATE UNIQUE INDEX e2e_room_keys_with_version_idx ON public.e2e_room_keys USING btree (user_id, version, room_id, session_id);
CREATE UNIQUE INDEX erased_users_user ON public.erased_users USING btree (user_id);
CREATE INDEX ev_b_extrem_id ON public.event_backward_extremities USING btree (event_id);
CREATE INDEX ev_b_extrem_room ON public.event_backward_extremities USING btree (room_id);
CREATE INDEX ev_edges_id ON public.event_edges USING btree (event_id);
CREATE INDEX ev_edges_prev_id ON public.event_edges USING btree (prev_event_id);
CREATE INDEX ev_extrem_id ON public.event_forward_extremities USING btree (event_id);
CREATE INDEX ev_extrem_room ON public.event_forward_extremities USING btree (room_id);
CREATE INDEX evauth_edges_id ON public.event_auth USING btree (event_id);
CREATE INDEX event_contains_url_index ON public.events USING btree (room_id, topological_ordering, stream_ordering) WHERE ((contains_url = true) AND (outlier = false));
CREATE INDEX event_expiry_expiry_ts_idx ON public.event_expiry USING btree (expiry_ts);
CREATE INDEX event_json_room_id ON public.event_json USING btree (room_id);
CREATE INDEX event_labels_room_id_label_idx ON public.event_labels USING btree (room_id, label, topological_ordering);
CREATE INDEX event_push_actions_highlights_index ON public.event_push_actions USING btree (user_id, room_id, topological_ordering, stream_ordering) WHERE (highlight = 1);
CREATE INDEX event_push_actions_rm_tokens ON public.event_push_actions USING btree (user_id, room_id, topological_ordering, stream_ordering);
CREATE INDEX event_push_actions_room_id_user_id ON public.event_push_actions USING btree (room_id, user_id);
CREATE INDEX event_push_actions_staging_id ON public.event_push_actions_staging USING btree (event_id);
CREATE INDEX event_push_actions_stream_ordering ON public.event_push_actions USING btree (stream_ordering, user_id);
CREATE INDEX event_push_actions_u_highlight ON public.event_push_actions USING btree (user_id, stream_ordering);
CREATE INDEX event_push_summary_user_rm ON public.event_push_summary USING btree (user_id, room_id);
CREATE INDEX event_reference_hashes_id ON public.event_reference_hashes USING btree (event_id);
CREATE UNIQUE INDEX event_relations_id ON public.event_relations USING btree (event_id);
CREATE INDEX event_relations_relates ON public.event_relations USING btree (relates_to_id, relation_type, aggregation_key);
CREATE INDEX event_search_ev_ridx ON public.event_search USING btree (room_id);
CREATE UNIQUE INDEX event_search_event_id_idx ON public.event_search USING btree (event_id);
CREATE INDEX event_search_fts_idx ON public.event_search USING gin (vector);
CREATE INDEX event_to_state_groups_sg_index ON public.event_to_state_groups USING btree (state_group);
CREATE INDEX events_order_room ON public.events USING btree (room_id, topological_ordering, stream_ordering);
CREATE INDEX events_room_stream ON public.events USING btree (room_id, stream_ordering);
CREATE INDEX events_ts ON public.events USING btree (origin_server_ts, stream_ordering);
CREATE INDEX group_attestations_remote_g_idx ON public.group_attestations_remote USING btree (group_id, user_id);
CREATE INDEX group_attestations_remote_u_idx ON public.group_attestations_remote USING btree (user_id);
CREATE INDEX group_attestations_remote_v_idx ON public.group_attestations_remote USING btree (valid_until_ms);
CREATE INDEX group_attestations_renewals_g_idx ON public.group_attestations_renewals USING btree (group_id, user_id);
CREATE INDEX group_attestations_renewals_u_idx ON public.group_attestations_renewals USING btree (user_id);
CREATE INDEX group_attestations_renewals_v_idx ON public.group_attestations_renewals USING btree (valid_until_ms);
CREATE UNIQUE INDEX group_invites_g_idx ON public.group_invites USING btree (group_id, user_id);
CREATE INDEX group_invites_u_idx ON public.group_invites USING btree (user_id);
CREATE UNIQUE INDEX group_rooms_g_idx ON public.group_rooms USING btree (group_id, room_id);
CREATE INDEX group_rooms_r_idx ON public.group_rooms USING btree (room_id);
CREATE UNIQUE INDEX group_summary_rooms_g_idx ON public.group_summary_rooms USING btree (group_id, room_id, category_id);
CREATE INDEX group_summary_users_g_idx ON public.group_summary_users USING btree (group_id);
CREATE UNIQUE INDEX group_users_g_idx ON public.group_users USING btree (group_id, user_id);
CREATE INDEX group_users_u_idx ON public.group_users USING btree (user_id);
CREATE UNIQUE INDEX groups_idx ON public.groups USING btree (group_id);
CREATE UNIQUE INDEX local_current_membership_idx ON public.local_current_membership USING btree (user_id, room_id);
CREATE INDEX local_current_membership_room_idx ON public.local_current_membership USING btree (room_id);
CREATE INDEX local_group_membership_g_idx ON public.local_group_membership USING btree (group_id);
CREATE INDEX local_group_membership_u_idx ON public.local_group_membership USING btree (user_id, group_id);
CREATE INDEX local_invites_for_user_idx ON public.local_invites USING btree (invitee, locally_rejected, replaced_by, room_id);
CREATE INDEX local_invites_id ON public.local_invites USING btree (stream_id);
CREATE INDEX local_media_repository_thumbnails_media_id ON public.local_media_repository_thumbnails USING btree (media_id);
CREATE INDEX local_media_repository_url_cache_by_url_download_ts ON public.local_media_repository_url_cache USING btree (url, download_ts);
CREATE INDEX local_media_repository_url_cache_expires_idx ON public.local_media_repository_url_cache USING btree (expires_ts);
CREATE INDEX local_media_repository_url_cache_media_idx ON public.local_media_repository_url_cache USING btree (media_id);
CREATE INDEX local_media_repository_url_idx ON public.local_media_repository USING btree (created_ts) WHERE (url_cache IS NOT NULL);
CREATE INDEX monthly_active_users_time_stamp ON public.monthly_active_users USING btree ("timestamp");
CREATE UNIQUE INDEX monthly_active_users_users ON public.monthly_active_users USING btree (user_id);
CREATE INDEX open_id_tokens_ts_valid_until_ms ON public.open_id_tokens USING btree (ts_valid_until_ms);
CREATE INDEX presence_stream_id ON public.presence_stream USING btree (stream_id, user_id);
CREATE INDEX presence_stream_user_id ON public.presence_stream USING btree (user_id);
CREATE INDEX public_room_index ON public.rooms USING btree (is_public);
CREATE INDEX public_room_list_stream_idx ON public.public_room_list_stream USING btree (stream_id);
CREATE INDEX public_room_list_stream_network ON public.public_room_list_stream USING btree (appservice_id, network_id, room_id);
CREATE INDEX public_room_list_stream_rm_idx ON public.public_room_list_stream USING btree (room_id, stream_id);
CREATE INDEX push_rules_enable_user_name ON public.push_rules_enable USING btree (user_name);
CREATE INDEX push_rules_stream_id ON public.push_rules_stream USING btree (stream_id);
CREATE INDEX push_rules_stream_user_stream_id ON public.push_rules_stream USING btree (user_id, stream_id);
CREATE INDEX push_rules_user_name ON public.push_rules USING btree (user_name);
CREATE UNIQUE INDEX ratelimit_override_idx ON public.ratelimit_override USING btree (user_id);
CREATE INDEX receipts_linearized_id ON public.receipts_linearized USING btree (stream_id);
CREATE INDEX receipts_linearized_room_stream ON public.receipts_linearized USING btree (room_id, stream_id);
CREATE INDEX receipts_linearized_user ON public.receipts_linearized USING btree (user_id);
CREATE INDEX received_transactions_ts ON public.received_transactions USING btree (ts);
CREATE INDEX redactions_have_censored_ts ON public.redactions USING btree (received_ts) WHERE (NOT have_censored);
CREATE INDEX redactions_redacts ON public.redactions USING btree (redacts);
CREATE INDEX remote_profile_cache_time ON public.remote_profile_cache USING btree (last_check);
CREATE UNIQUE INDEX remote_profile_cache_user_id ON public.remote_profile_cache USING btree (user_id);
CREATE INDEX room_account_data_stream_id ON public.room_account_data USING btree (user_id, stream_id);
CREATE INDEX room_alias_servers_alias ON public.room_alias_servers USING btree (room_alias);
CREATE INDEX room_aliases_id ON public.room_aliases USING btree (room_id);
CREATE INDEX room_depth_room ON public.room_depth USING btree (room_id);
CREATE INDEX room_memberships_room_id ON public.room_memberships USING btree (room_id);
CREATE INDEX room_memberships_user_id ON public.room_memberships USING btree (user_id);
CREATE INDEX room_memberships_user_room_forgotten ON public.room_memberships USING btree (user_id, room_id) WHERE (forgotten = 1);
CREATE INDEX room_retention_max_lifetime_idx ON public.room_retention USING btree (max_lifetime);
CREATE UNIQUE INDEX room_stats_earliest_token_idx ON public.room_stats_earliest_token USING btree (room_id);
CREATE INDEX room_stats_historical_end_ts ON public.room_stats_historical USING btree (end_ts);
CREATE UNIQUE INDEX room_stats_state_room ON public.room_stats_state USING btree (room_id);
CREATE INDEX state_group_edges_idx ON public.state_group_edges USING btree (state_group);
CREATE INDEX state_group_edges_prev_idx ON public.state_group_edges USING btree (prev_state_group);
CREATE INDEX state_groups_room_id_idx ON public.state_groups USING btree (room_id);
CREATE INDEX state_groups_state_type_idx ON public.state_groups_state USING btree (state_group, type, state_key);
CREATE INDEX stream_ordering_to_exterm_idx ON public.stream_ordering_to_exterm USING btree (stream_ordering);
CREATE INDEX stream_ordering_to_exterm_rm_idx ON public.stream_ordering_to_exterm USING btree (room_id, stream_ordering);
CREATE UNIQUE INDEX threepid_guest_access_tokens_index ON public.threepid_guest_access_tokens USING btree (medium, address);
CREATE INDEX threepid_validation_token_session_id ON public.threepid_validation_token USING btree (session_id);
CREATE INDEX user_daily_visits_ts_idx ON public.user_daily_visits USING btree ("timestamp");
CREATE INDEX user_daily_visits_uts_idx ON public.user_daily_visits USING btree (user_id, "timestamp");
CREATE INDEX user_directory_room_idx ON public.user_directory USING btree (room_id);
CREATE INDEX user_directory_search_fts_idx ON public.user_directory_search USING gin (vector);
CREATE UNIQUE INDEX user_directory_search_user_idx ON public.user_directory_search USING btree (user_id);
CREATE UNIQUE INDEX user_directory_user_idx ON public.user_directory USING btree (user_id);
CREATE UNIQUE INDEX user_filters_unique ON public.user_filters USING btree (user_id, filter_id);
CREATE INDEX user_ips_device_id ON public.user_ips USING btree (user_id, device_id, last_seen);
CREATE INDEX user_ips_last_seen ON public.user_ips USING btree (user_id, last_seen);
CREATE INDEX user_ips_last_seen_only ON public.user_ips USING btree (last_seen);
CREATE UNIQUE INDEX user_ips_user_token_ip_unique_index ON public.user_ips USING btree (user_id, access_token, ip);
CREATE UNIQUE INDEX user_signature_stream_idx ON public.user_signature_stream USING btree (stream_id);
CREATE INDEX user_stats_historical_end_ts ON public.user_stats_historical USING btree (end_ts);
CREATE UNIQUE INDEX user_threepid_id_server_idx ON public.user_threepid_id_server USING btree (user_id, medium, address, id_server);
CREATE INDEX user_threepids_medium_address ON public.user_threepids USING btree (medium, address);
CREATE INDEX user_threepids_user_id ON public.user_threepids USING btree (user_id);
CREATE INDEX users_creation_ts ON public.users USING btree (creation_ts);
CREATE INDEX users_in_public_rooms_r_idx ON public.users_in_public_rooms USING btree (room_id);
CREATE UNIQUE INDEX users_in_public_rooms_u_idx ON public.users_in_public_rooms USING btree (user_id, room_id);
CREATE INDEX users_who_share_private_rooms_o_idx ON public.users_who_share_private_rooms USING btree (other_user_id);
CREATE INDEX users_who_share_private_rooms_r_idx ON public.users_who_share_private_rooms USING btree (room_id);
CREATE UNIQUE INDEX users_who_share_private_rooms_u_idx ON public.users_who_share_private_rooms USING btree (user_id, other_user_id, room_id);
ALTER TABLE ONLY public.ui_auth_sessions_credentials
    ADD CONSTRAINT ui_auth_sessions_credentials_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.ui_auth_sessions(session_id);

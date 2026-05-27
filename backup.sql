--
-- PostgreSQL database dump
--

\restrict 8pvh0SYJBkTn8x8beovzgDmRxMmJDGCyVQVujrHNvq4qJYkLwoa95eqhNHLY8JC

-- Dumped from database version 15.17
-- Dumped by pg_dump version 18.4

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
-- Name: approval_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.approval_status AS ENUM (
    'pending',
    'approved',
    'rejected'
);


--
-- Name: batch_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.batch_status AS ENUM (
    'pending',
    'ready',
    'sent'
);


--
-- Name: beta_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.beta_status AS ENUM (
    'draft',
    'recruiting',
    'outreach_sent',
    'full',
    'in_progress',
    'closing',
    'closed'
);


--
-- Name: close_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.close_reason AS ENUM (
    'completed',
    'cancelled',
    'merged',
    'paused'
);


--
-- Name: health_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.health_status AS ENUM (
    'green',
    'yellow',
    'red'
);


--
-- Name: segment; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.segment AS ENUM (
    'Strategic',
    'Enterprise',
    'Commercial',
    'Professional',
    'Channel'
);


--
-- Name: sentiment; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.sentiment AS ENUM (
    'positive',
    'neutral',
    'negative'
);


--
-- Name: tester_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tester_status AS ENUM (
    'nominated',
    'csm_pending',
    'csm_approved',
    'outreach_sent',
    'confirmed',
    'active',
    'completed',
    'dropped',
    'cancelled'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'pm',
    'pmm',
    'csm',
    'admin',
    'ae'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id text NOT NULL,
    entity_type text NOT NULL,
    entity_id text NOT NULL,
    action text NOT NULL,
    changed_by text NOT NULL,
    prior_state json,
    next_state json,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: beta_enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beta_enrollments (
    id text NOT NULL,
    client_id text NOT NULL,
    feature_id text NOT NULL,
    assigned_by text NOT NULL,
    is_overflow boolean DEFAULT false NOT NULL,
    csm_approval_status public.approval_status DEFAULT 'pending'::public.approval_status NOT NULL,
    csm_approved_by text,
    csm_approved_at timestamp without time zone,
    csm_rejection_reason text,
    tester_status public.tester_status DEFAULT 'nominated'::public.tester_status NOT NULL,
    outreach_sent_at timestamp without time zone,
    confirmed_at timestamp without time zone,
    completed_at timestamp without time zone,
    dropped_at timestamp without time zone,
    drop_reason text,
    feedback_submitted boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: beta_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beta_features (
    id text NOT NULL,
    name text NOT NULL,
    owner_pm text NOT NULL,
    owner_pmm text NOT NULL,
    target_tester_count integer DEFAULT 15 NOT NULL,
    status public.beta_status DEFAULT 'draft'::public.beta_status NOT NULL,
    start_date date NOT NULL,
    closed_at timestamp without time zone,
    close_reason public.close_reason,
    close_notes text,
    ideal_client_criteria text,
    outreach_deadline date NOT NULL,
    cloned_from text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    jira_epic_link text DEFAULT ''::text NOT NULL,
    slug text,
    previous_slug text
);


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id text NOT NULL,
    name text NOT NULL,
    csm_owner text NOT NULL,
    tier integer,
    account_health public.health_status DEFAULT 'green'::public.health_status NOT NULL,
    outreach_lock boolean DEFAULT false NOT NULL,
    last_outreach_date date,
    notes text,
    crm_id text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    segment public.segment,
    primary_contact_name text,
    primary_contact_email text,
    vertical text,
    contract_renewal_date date,
    product_subscriptions text
);


--
-- Name: feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback (
    id text NOT NULL,
    client_id text NOT NULL,
    feature_id text NOT NULL,
    sentiment public.sentiment NOT NULL,
    notes text,
    logged_by text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: outreach_batch_enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outreach_batch_enrollments (
    batch_id text NOT NULL,
    enrollment_id text NOT NULL
);


--
-- Name: outreach_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outreach_batches (
    id text NOT NULL,
    client_id text NOT NULL,
    batch_status public.batch_status DEFAULT 'pending'::public.batch_status NOT NULL,
    sent_at timestamp without time zone,
    sent_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id text NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    role public.user_role NOT NULL,
    email_verified timestamp without time zone,
    image text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (id, entity_type, entity_id, action, changed_by, prior_state, next_state, created_at) FROM stdin;
75646732-62d4-4f97-857f-692d8692ad6e	BetaEnrollment	42e80b83-47fa-40f2-a992-dc228a614187	nominated	004df477-84b3-4aba-b191-1bde5deb1606	\N	{"id":"42e80b83-47fa-40f2-a992-dc228a614187","clientId":"0442dc39-1a7a-4430-bd50-972236198b8f","featureId":"d9175740-c9e7-4245-aee5-b21e6bcc6edb","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-17T19:58:53.393Z","updatedAt":"2026-05-17T19:58:53.393Z"}	2026-05-17 19:58:53.477669
1a94b53a-d92f-421c-ae17-ed65f67c3b53	BetaEnrollment	77625255-d2a1-40ea-b200-6677558f0256	nominated	004df477-84b3-4aba-b191-1bde5deb1606	\N	{"id":"77625255-d2a1-40ea-b200-6677558f0256","clientId":"704f3226-4c5d-4269-a746-d5a648fb037a","featureId":"a9da113e-8d77-4c2e-8aff-a4b1d14b2f42","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-18T23:08:21.025Z","updatedAt":"2026-05-18T23:08:21.025Z"}	2026-05-18 23:08:21.061345
8c771ab6-514c-4561-a433-a29ab9c026ed	BetaEnrollment	84fab1c7-e39e-4947-b3a1-625a1f0a7b22	nominated	004df477-84b3-4aba-b191-1bde5deb1606	\N	{"id":"84fab1c7-e39e-4947-b3a1-625a1f0a7b22","clientId":"37aa9a9a-5d84-4cf6-88e3-3f61938f6246","featureId":"d9175740-c9e7-4245-aee5-b21e6bcc6edb","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-19T13:52:49.615Z","updatedAt":"2026-05-19T13:52:49.615Z"}	2026-05-19 13:52:49.654035
d8069a3b-0fc5-49c7-a0d8-91d03df0fcbb	BetaEnrollment	77625255-d2a1-40ea-b200-6677558f0256	csm_approved	004df477-84b3-4aba-b191-1bde5deb1606	{"id":"77625255-d2a1-40ea-b200-6677558f0256","clientId":"704f3226-4c5d-4269-a746-d5a648fb037a","featureId":"a9da113e-8d77-4c2e-8aff-a4b1d14b2f42","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-18T23:08:21.025Z","updatedAt":"2026-05-18T23:08:21.025Z"}	{"id":"77625255-d2a1-40ea-b200-6677558f0256","clientId":"704f3226-4c5d-4269-a746-d5a648fb037a","featureId":"a9da113e-8d77-4c2e-8aff-a4b1d14b2f42","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"approved","csmApprovedById":"004df477-84b3-4aba-b191-1bde5deb1606","csmApprovedAt":"2026-05-23T18:21:13.629Z","csmRejectionReason":null,"testerStatus":"csm_approved","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-18T23:08:21.025Z","updatedAt":"2026-05-23T18:21:13.629Z"}	2026-05-23 18:21:13.64395
981104e5-4cb8-4f55-a3bb-735840abc1a5	BetaEnrollment	84fab1c7-e39e-4947-b3a1-625a1f0a7b22	csm_approved	004df477-84b3-4aba-b191-1bde5deb1606	{"id":"84fab1c7-e39e-4947-b3a1-625a1f0a7b22","clientId":"37aa9a9a-5d84-4cf6-88e3-3f61938f6246","featureId":"d9175740-c9e7-4245-aee5-b21e6bcc6edb","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-19T13:52:49.615Z","updatedAt":"2026-05-19T13:52:49.615Z"}	{"id":"84fab1c7-e39e-4947-b3a1-625a1f0a7b22","clientId":"37aa9a9a-5d84-4cf6-88e3-3f61938f6246","featureId":"d9175740-c9e7-4245-aee5-b21e6bcc6edb","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"approved","csmApprovedById":"004df477-84b3-4aba-b191-1bde5deb1606","csmApprovedAt":"2026-05-24T16:58:58.367Z","csmRejectionReason":null,"testerStatus":"csm_approved","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-19T13:52:49.615Z","updatedAt":"2026-05-24T16:58:58.367Z"}	2026-05-24 16:58:58.37732
612218c7-eca9-4eb5-9a69-b34d4ec00ee3	BetaEnrollment	5b4308a3-587a-41c9-9b39-e265a5699c91	nominated	004df477-84b3-4aba-b191-1bde5deb1606	\N	{"id":"5b4308a3-587a-41c9-9b39-e265a5699c91","clientId":"ec222637-64f4-4b27-8ac2-dd0f2a553c75","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:28.724Z","updatedAt":"2026-05-26T18:06:28.724Z"}	2026-05-26 18:06:28.731936
78ed57d6-fe3a-4575-bac5-558e5c2c36ef	BetaEnrollment	ff513f77-9e36-4561-9e6c-5b68f85b73d4	nominated	004df477-84b3-4aba-b191-1bde5deb1606	\N	{"id":"ff513f77-9e36-4561-9e6c-5b68f85b73d4","clientId":"471f1f31-7938-4078-b5d5-cf1e5a9526ec","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:31.264Z","updatedAt":"2026-05-26T18:06:31.264Z"}	2026-05-26 18:06:31.269669
c016cef6-e174-454c-b5f5-ced07fa73645	BetaEnrollment	1f927882-a5a1-471d-a00a-e21b8bab0a20	nominated	004df477-84b3-4aba-b191-1bde5deb1606	\N	{"id":"1f927882-a5a1-471d-a00a-e21b8bab0a20","clientId":"37aa9a9a-5d84-4cf6-88e3-3f61938f6246","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:35.859Z","updatedAt":"2026-05-26T18:06:35.859Z"}	2026-05-26 18:06:35.863737
b4d21e97-ddce-4743-b77c-f7bab9cb80e7	BetaEnrollment	fc873689-e3ed-4794-a2bc-4ee196b7492e	nominated	004df477-84b3-4aba-b191-1bde5deb1606	\N	{"id":"fc873689-e3ed-4794-a2bc-4ee196b7492e","clientId":"e47eeb20-d797-4389-b892-42b8929c9260","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:37.105Z","updatedAt":"2026-05-26T18:06:37.105Z"}	2026-05-26 18:06:37.108949
46c1b703-b6a9-40ea-b8e1-f66b471c9950	BetaEnrollment	7a5e6045-eb55-45a3-8aaa-fd36af87bbb7	nominated	004df477-84b3-4aba-b191-1bde5deb1606	\N	{"id":"7a5e6045-eb55-45a3-8aaa-fd36af87bbb7","clientId":"1c3dd9b2-b399-40fa-b215-d6e8908b3588","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:40.923Z","updatedAt":"2026-05-26T18:06:40.923Z"}	2026-05-26 18:06:40.928309
b44736ac-64d3-46e3-9b7a-4657c541420d	BetaEnrollment	c7b8baa9-181a-4d5e-91a7-dd91b12a5482	nominated	004df477-84b3-4aba-b191-1bde5deb1606	\N	{"id":"c7b8baa9-181a-4d5e-91a7-dd91b12a5482","clientId":"99fc72b8-3f7e-484a-916f-27968259ec30","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:43.518Z","updatedAt":"2026-05-26T18:06:43.518Z"}	2026-05-26 18:06:43.52299
4c68c27e-76e7-4769-b292-04614f7e463b	BetaEnrollment	c7b8baa9-181a-4d5e-91a7-dd91b12a5482	csm_approved	004df477-84b3-4aba-b191-1bde5deb1606	{"id":"c7b8baa9-181a-4d5e-91a7-dd91b12a5482","clientId":"99fc72b8-3f7e-484a-916f-27968259ec30","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:43.518Z","updatedAt":"2026-05-26T18:06:43.518Z"}	{"id":"c7b8baa9-181a-4d5e-91a7-dd91b12a5482","clientId":"99fc72b8-3f7e-484a-916f-27968259ec30","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"approved","csmApprovedById":"004df477-84b3-4aba-b191-1bde5deb1606","csmApprovedAt":"2026-05-26T18:06:49.933Z","csmRejectionReason":null,"testerStatus":"csm_approved","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:43.518Z","updatedAt":"2026-05-26T18:06:49.933Z"}	2026-05-26 18:06:49.938102
0e683f96-b778-4372-bfdf-93cc30105d17	BetaEnrollment	fc873689-e3ed-4794-a2bc-4ee196b7492e	csm_approved	004df477-84b3-4aba-b191-1bde5deb1606	{"id":"fc873689-e3ed-4794-a2bc-4ee196b7492e","clientId":"e47eeb20-d797-4389-b892-42b8929c9260","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:37.105Z","updatedAt":"2026-05-26T18:06:37.105Z"}	{"id":"fc873689-e3ed-4794-a2bc-4ee196b7492e","clientId":"e47eeb20-d797-4389-b892-42b8929c9260","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"approved","csmApprovedById":"004df477-84b3-4aba-b191-1bde5deb1606","csmApprovedAt":"2026-05-26T18:06:51.299Z","csmRejectionReason":null,"testerStatus":"csm_approved","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:37.105Z","updatedAt":"2026-05-26T18:06:51.299Z"}	2026-05-26 18:06:51.304338
250c427e-c4b0-427f-be0c-cc280d40b2bd	BetaEnrollment	ff513f77-9e36-4561-9e6c-5b68f85b73d4	csm_approved	004df477-84b3-4aba-b191-1bde5deb1606	{"id":"ff513f77-9e36-4561-9e6c-5b68f85b73d4","clientId":"471f1f31-7938-4078-b5d5-cf1e5a9526ec","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:31.264Z","updatedAt":"2026-05-26T18:06:31.264Z"}	{"id":"ff513f77-9e36-4561-9e6c-5b68f85b73d4","clientId":"471f1f31-7938-4078-b5d5-cf1e5a9526ec","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"approved","csmApprovedById":"004df477-84b3-4aba-b191-1bde5deb1606","csmApprovedAt":"2026-05-26T18:06:52.254Z","csmRejectionReason":null,"testerStatus":"csm_approved","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:31.264Z","updatedAt":"2026-05-26T18:06:52.254Z"}	2026-05-26 18:06:52.259176
6641360e-b21e-4f2a-bf50-74876138cd7f	BetaEnrollment	7a5e6045-eb55-45a3-8aaa-fd36af87bbb7	csm_approved	004df477-84b3-4aba-b191-1bde5deb1606	{"id":"7a5e6045-eb55-45a3-8aaa-fd36af87bbb7","clientId":"1c3dd9b2-b399-40fa-b215-d6e8908b3588","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:40.923Z","updatedAt":"2026-05-26T18:06:40.923Z"}	{"id":"7a5e6045-eb55-45a3-8aaa-fd36af87bbb7","clientId":"1c3dd9b2-b399-40fa-b215-d6e8908b3588","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"approved","csmApprovedById":"004df477-84b3-4aba-b191-1bde5deb1606","csmApprovedAt":"2026-05-26T18:06:52.826Z","csmRejectionReason":null,"testerStatus":"csm_approved","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:40.923Z","updatedAt":"2026-05-26T18:06:52.826Z"}	2026-05-26 18:06:52.83119
c3892da2-1f0c-4c5c-99fe-f1ce8b7009ff	BetaEnrollment	5b4308a3-587a-41c9-9b39-e265a5699c91	csm_approved	004df477-84b3-4aba-b191-1bde5deb1606	{"id":"5b4308a3-587a-41c9-9b39-e265a5699c91","clientId":"ec222637-64f4-4b27-8ac2-dd0f2a553c75","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"pending","csmApprovedById":null,"csmApprovedAt":null,"csmRejectionReason":null,"testerStatus":"nominated","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:28.724Z","updatedAt":"2026-05-26T18:06:28.724Z"}	{"id":"5b4308a3-587a-41c9-9b39-e265a5699c91","clientId":"ec222637-64f4-4b27-8ac2-dd0f2a553c75","featureId":"11001aa3-bdd4-4f13-95e7-c7d02fc20bba","assignedById":"004df477-84b3-4aba-b191-1bde5deb1606","isOverflow":false,"csmApprovalStatus":"approved","csmApprovedById":"004df477-84b3-4aba-b191-1bde5deb1606","csmApprovedAt":"2026-05-26T18:06:53.905Z","csmRejectionReason":null,"testerStatus":"csm_approved","outreachSentAt":null,"confirmedAt":null,"completedAt":null,"droppedAt":null,"dropReason":null,"feedbackSubmitted":false,"createdAt":"2026-05-26T18:06:28.724Z","updatedAt":"2026-05-26T18:06:53.905Z"}	2026-05-26 18:06:53.909829
\.


--
-- Data for Name: beta_enrollments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.beta_enrollments (id, client_id, feature_id, assigned_by, is_overflow, csm_approval_status, csm_approved_by, csm_approved_at, csm_rejection_reason, tester_status, outreach_sent_at, confirmed_at, completed_at, dropped_at, drop_reason, feedback_submitted, created_at, updated_at) FROM stdin;
42e80b83-47fa-40f2-a992-dc228a614187	0442dc39-1a7a-4430-bd50-972236198b8f	d9175740-c9e7-4245-aee5-b21e6bcc6edb	004df477-84b3-4aba-b191-1bde5deb1606	f	pending	\N	\N	\N	nominated	\N	\N	\N	\N	\N	f	2026-05-17 19:58:53.393576	2026-05-17 19:58:53.393576
77625255-d2a1-40ea-b200-6677558f0256	704f3226-4c5d-4269-a746-d5a648fb037a	a9da113e-8d77-4c2e-8aff-a4b1d14b2f42	004df477-84b3-4aba-b191-1bde5deb1606	f	approved	004df477-84b3-4aba-b191-1bde5deb1606	2026-05-23 18:21:13.629	\N	csm_approved	\N	\N	\N	\N	\N	f	2026-05-18 23:08:21.025665	2026-05-23 18:21:13.629
84fab1c7-e39e-4947-b3a1-625a1f0a7b22	37aa9a9a-5d84-4cf6-88e3-3f61938f6246	d9175740-c9e7-4245-aee5-b21e6bcc6edb	004df477-84b3-4aba-b191-1bde5deb1606	f	approved	004df477-84b3-4aba-b191-1bde5deb1606	2026-05-24 16:58:58.367	\N	csm_approved	\N	\N	\N	\N	\N	f	2026-05-19 13:52:49.615077	2026-05-24 16:58:58.367
1f927882-a5a1-471d-a00a-e21b8bab0a20	37aa9a9a-5d84-4cf6-88e3-3f61938f6246	11001aa3-bdd4-4f13-95e7-c7d02fc20bba	004df477-84b3-4aba-b191-1bde5deb1606	f	pending	\N	\N	\N	nominated	\N	\N	\N	\N	\N	f	2026-05-26 18:06:35.859477	2026-05-26 18:06:35.859477
c7b8baa9-181a-4d5e-91a7-dd91b12a5482	99fc72b8-3f7e-484a-916f-27968259ec30	11001aa3-bdd4-4f13-95e7-c7d02fc20bba	004df477-84b3-4aba-b191-1bde5deb1606	f	approved	004df477-84b3-4aba-b191-1bde5deb1606	2026-05-26 18:06:49.933	\N	csm_approved	\N	\N	\N	\N	\N	f	2026-05-26 18:06:43.518967	2026-05-26 18:06:49.933
fc873689-e3ed-4794-a2bc-4ee196b7492e	e47eeb20-d797-4389-b892-42b8929c9260	11001aa3-bdd4-4f13-95e7-c7d02fc20bba	004df477-84b3-4aba-b191-1bde5deb1606	f	approved	004df477-84b3-4aba-b191-1bde5deb1606	2026-05-26 18:06:51.299	\N	csm_approved	\N	\N	\N	\N	\N	f	2026-05-26 18:06:37.105029	2026-05-26 18:06:51.299
ff513f77-9e36-4561-9e6c-5b68f85b73d4	471f1f31-7938-4078-b5d5-cf1e5a9526ec	11001aa3-bdd4-4f13-95e7-c7d02fc20bba	004df477-84b3-4aba-b191-1bde5deb1606	f	approved	004df477-84b3-4aba-b191-1bde5deb1606	2026-05-26 18:06:52.254	\N	csm_approved	\N	\N	\N	\N	\N	f	2026-05-26 18:06:31.264312	2026-05-26 18:06:52.254
7a5e6045-eb55-45a3-8aaa-fd36af87bbb7	1c3dd9b2-b399-40fa-b215-d6e8908b3588	11001aa3-bdd4-4f13-95e7-c7d02fc20bba	004df477-84b3-4aba-b191-1bde5deb1606	f	approved	004df477-84b3-4aba-b191-1bde5deb1606	2026-05-26 18:06:52.826	\N	csm_approved	\N	\N	\N	\N	\N	f	2026-05-26 18:06:40.923917	2026-05-26 18:06:52.826
5b4308a3-587a-41c9-9b39-e265a5699c91	ec222637-64f4-4b27-8ac2-dd0f2a553c75	11001aa3-bdd4-4f13-95e7-c7d02fc20bba	004df477-84b3-4aba-b191-1bde5deb1606	f	approved	004df477-84b3-4aba-b191-1bde5deb1606	2026-05-26 18:06:53.905	\N	csm_approved	\N	\N	\N	\N	\N	f	2026-05-26 18:06:28.724665	2026-05-26 18:06:53.905
\.


--
-- Data for Name: beta_features; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.beta_features (id, name, owner_pm, owner_pmm, target_tester_count, status, start_date, closed_at, close_reason, close_notes, ideal_client_criteria, outreach_deadline, cloned_from, created_at, updated_at, jira_epic_link, slug, previous_slug) FROM stdin;
ac983730-3889-4c1e-89ab-5d66c66ed80c	Myna Agents	aa578ef5-541c-4de1-a69a-827c1ee520f4	98e67dd8-1469-4717-8ebe-c0774f47e58f	15	draft	2026-06-02	\N	\N	\N		2026-06-02	\N	2026-05-18 23:07:15.039533	2026-05-18 23:07:15.039533	https://feature-roadmap.replit.app/?issue=BIRD-182123	myna-agents	\N
a9da113e-8d77-4c2e-8aff-a4b1d14b2f42	Search AI Optimization Agent	b498d3a5-0936-46f2-bdc9-441abeae9aa4	4dd0edc1-54e0-4928-ab9e-658d088f2623	15	recruiting	2026-06-02	\N	\N	\N		2026-06-02	\N	2026-05-18 23:02:53.196089	2026-05-24 16:56:07.878	https://feature-roadmap.replit.app/?issue=BIRD-193248	search-ai-optimization-agent	\N
d9175740-c9e7-4245-aee5-b21e6bcc6edb	Listings Optimization Agent	ed13f6be-692d-4f89-a77d-57d070bdb774	4dd0edc1-54e0-4928-ab9e-658d088f2623	15	draft	2026-06-02	\N	\N	\N	Enterprise listings client	2026-06-02	\N	2026-05-17 19:24:57.971937	2026-05-24 17:38:15.841	https://feature-roadmap.replit.app/?issue=BIRD-200688	listings-optimization-agent	\N
11001aa3-bdd4-4f13-95e7-c7d02fc20bba	Social Publishing Agent Test	a9e29554-510e-4b3b-b1be-1210b24102b8	f7db9b43-5165-44d0-931c-eebbdf8fb2f4	15	in_progress	2026-06-02	\N	\N	\N	Active customers with a relevant use case, green or yellow account health, and willingness to provide structured feedback within the beta period.	2026-06-02	\N	2026-05-26 18:05:51.873421	2026-05-26 18:05:58.782	https://feature-roadmap.replit.app/?issue=BIRD-182581	social-publishing-agent-test	\N
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.clients (id, name, csm_owner, tier, account_health, outreach_lock, last_outreach_date, notes, crm_id, created_at, updated_at, segment, primary_contact_name, primary_contact_email, vertical, contract_renewal_date, product_subscriptions) FROM stdin;
0442dc39-1a7a-4430-bd50-972236198b8f	Aspen Dental	02a5f706-3275-4670-bc93-1d0f670799ba	\N	green	f	\N	\N	840135232	2026-05-17 19:54:07.258972	2026-05-17 19:54:07.258972	Enterprise	Rachel Bentley	rachel.bentley@teamtag.com	Healthcare	\N	\N
37aa9a9a-5d84-4cf6-88e3-3f61938f6246	Wyndham Hotels & Resorts	ffa96572-267d-44fa-82e1-7518094c77b9	\N	green	f	\N	\N	174474980470341	2026-05-18 22:57:30.037142	2026-05-18 23:00:39.523	Strategic	Michael Mahar	michael.mahar@wyndham.com	Hospitality	\N	\N
704f3226-4c5d-4269-a746-d5a648fb037a	Sutter Health	02a5f706-3275-4670-bc93-1d0f670799ba	\N	green	f	\N	\N	174188733881209	2026-05-18 23:01:14.567053	2026-05-18 23:01:45.533	Strategic	Nolan Perry	nolan.perry@sutterhealth.org	Healthcare	\N	\N
e7aaa8f6-d390-4a2b-b914-3041dfba68f2	HANSONS	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	153841656055628	2026-05-23 00:38:43.174696	2026-05-23 00:38:43.174696	Commercial	\N	\N	Home Services	2026-10-18	\N
9a8dcdad-ea24-4535-9a99-dacacd08b3b9	Poolwerx USA	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	red	f	\N	\N	167387857109221	2026-05-23 00:38:43.185102	2026-05-23 00:38:43.185102	Commercial	\N	\N	Other	2026-02-28	\N
5a73e1a0-0944-4c91-b5bf-a36e32de9227	Morningstar Properties, LLC	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	150835066887293	2026-05-23 00:38:43.192189	2026-05-23 00:38:43.192189	Commercial	\N	\N	Consumer Services	2027-01-27	\N
6f6017f8-76cf-4633-8f5c-e80f70437e0b	Green Courte Partners (Windward Communities)	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	red	f	\N	\N	167906152353776	2026-05-23 00:38:43.197101	2026-05-23 00:38:43.197101	Commercial	\N	\N	Other	2026-10-01	\N
c8d0f958-bb0f-40f0-9ac9-738f9d3b102c	Regency Furniture	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	161919918578860	2026-05-23 00:38:43.202378	2026-05-23 00:38:43.202378	Commercial	\N	\N	Retail	2027-08-11	\N
262952db-cc0b-4ab3-b790-42850c4baf46	State Employees Credit Union of Maryland	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	171379114306389	2026-05-23 00:38:43.209051	2026-05-23 00:38:43.209051	Commercial	\N	\N	Finance	2026-06-28	\N
9eedefb1-b240-413b-bd71-45b9881114b0	CareWell Urgent Care	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	159172263338897	2026-05-23 00:38:43.214375	2026-05-23 00:38:43.214375	Commercial	\N	\N	Healthcare	2026-10-02	\N
58d1c4d8-2ce3-4cab-8245-84cc78267cae	Evergreen Healthcare Group	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	170483402233230	2026-05-23 00:38:43.219141	2026-05-23 00:38:43.219141	Commercial	\N	\N	Healthcare	2026-08-29	\N
24013e7e-fee5-40e5-b9cb-5e5dd62f7954	Resort Lifestyle Communities	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	156893198874414	2026-05-23 00:38:43.22602	2026-05-23 00:38:43.22602	Commercial	\N	\N	Wellness	2028-03-01	\N
5f8da6f4-6e26-48d0-8b29-35cff0f7c278	Fairway Corp	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	173998827635771	2026-05-23 00:38:43.231553	2026-05-23 00:38:43.231553	Commercial	\N	\N	Home Services	2028-03-18	\N
78195579-fb8f-48fb-93bb-c0d2a9e07bf1	VIVE Collision	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	171051957637392	2026-05-23 00:38:43.236174	2026-05-23 00:38:43.236174	Commercial	\N	\N	Automotive	2027-01-15	\N
08343517-d2cf-49d8-8979-4aa539c8683a	Transitions Care	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	red	f	\N	\N	166180139464631	2026-05-23 00:38:43.240292	2026-05-23 00:38:43.240292	Commercial	\N	\N	Wellness	2026-05-31	\N
8b4f8fba-dfe9-418e-93a3-49ec15f7123c	United Urology Group	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	red	f	\N	\N	170440179371909	2026-05-23 00:38:43.244757	2026-05-23 00:38:43.244757	Commercial	\N	\N	Healthcare	2027-05-30	\N
03cdb5eb-d1d5-4251-9936-c0ece84e387a	Advance Financial	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	171501895190872	2026-05-23 00:38:43.249279	2026-05-23 00:38:43.249279	Commercial	\N	\N	Finance	2027-12-30	\N
28e28a84-a3f8-4f71-baa6-9c47289832d3	Veterinary Innovative Partners	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	157909869076747	2026-05-23 00:38:43.253427	2026-05-23 00:38:43.253427	Commercial	\N	\N	Healthcare	2027-08-28	\N
b2f85a97-c400-4436-ad57-dface9a77ec1	Oxford Physical Therapy Centers	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	157056269831620	2026-05-23 00:38:43.257957	2026-05-23 00:38:43.257957	Commercial	\N	\N	Wellness	2026-12-15	\N
655f2e59-7874-488d-810a-a841601b32fc	Perspire Sauna Studio	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	162115236444641	2026-05-23 00:38:43.262392	2026-05-23 00:38:43.262392	Commercial	\N	\N	Wellness	2027-05-24	\N
ab65f4d8-ed78-49fb-b9b2-1a54539321ae	Guardian Storage	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	175467400366578	2026-05-23 00:38:43.267024	2026-05-23 00:38:43.267024	Commercial	\N	\N	Consumer Services	2026-08-31	\N
85932ebd-df0b-4e74-bb2c-68283e3421f6	Chartway Federal Credit Union	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	157592981737020	2026-05-23 00:38:43.272036	2026-05-23 00:38:43.272036	Commercial	\N	\N	Finance	2027-09-29	\N
50e8a287-fd5e-456e-a070-0c3fa3a68489	Easy Mile Fitness (easymilefitness.com)	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	174862300287095	2026-05-23 00:38:43.276762	2026-05-23 00:38:43.276762	Commercial	\N	\N	Wellness	2027-08-30	\N
fc3aaeae-b49b-450d-9393-8c04a3f167df	Crowne Health Care	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	169904259568679	2026-05-23 00:38:43.282191	2026-05-23 00:38:43.282191	Commercial	\N	\N	Healthcare	2029-02-26	\N
de99f2c9-d226-4670-b6bd-2a36f7cd0392	Diversicare Healthcare Services Inc	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	170049595424556	2026-05-23 00:38:43.288087	2026-05-23 00:38:43.288087	Commercial	\N	\N	Healthcare	2026-12-21	\N
1f7b86b0-7447-46cc-bfc0-2923f2973dd2	Kremer Eye Center - King of Prussia	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	171330331466581	2026-05-23 00:38:43.292905	2026-05-23 00:38:43.292905	Commercial	\N	\N	Healthcare	2027-02-09	\N
deafa825-1680-4cda-a314-a24ee33f5db6	Oilstop, Inc.	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	170216649622897	2026-05-23 00:38:43.297349	2026-05-23 00:38:43.297349	Commercial	\N	\N	Automotive	2026-12-21	\N
1d3a3dc3-6714-40cc-b5a1-1e61d365981b	Nothing bundt cakes	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	171720247358942	2026-05-23 00:38:43.302024	2026-05-23 00:38:43.302024	Commercial	\N	\N	Restaurants	2026-07-27	\N
7f52295b-72b9-4124-841d-5a1c50bd7135	Aquarius Home Services	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	172626380346897	2026-05-23 00:38:43.307233	2026-05-23 00:38:43.307233	Commercial	\N	\N	Contractors	2026-08-24	\N
8f81fb23-dcd2-4842-b5a6-a1b7e3dc74f8	Heart + Paw	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	170483351055816	2026-05-23 00:38:43.312264	2026-05-23 00:38:43.312264	Commercial	\N	\N	Healthcare	2027-03-13	\N
c0137246-59e0-4407-b82e-46bfd683fff3	Anne Arundel Dermatology	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	172238100342434	2026-05-23 00:38:43.317639	2026-05-23 00:38:43.317639	Commercial	\N	\N	Healthcare	2026-09-17	\N
b2d562d5-b37f-466e-b950-3a277ceda9e5	Financial Partners Credit Union	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	red	f	\N	\N	166363217321117	2026-05-23 00:38:43.322298	2026-05-23 00:38:43.322298	Commercial	\N	\N	Finance	2026-11-13	\N
69584e9d-903a-4540-a348-fa762deb1947	ABHM	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	red	f	\N	\N	161661587812459	2026-05-23 00:38:43.326682	2026-05-23 00:38:43.326682	Commercial	\N	\N	Wellness	2027-03-30	\N
afcb2c94-2b9e-46a5-af6c-5ef6d84c6d01	Emagine Entertainment	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	155354121282268	2026-05-23 00:38:43.332227	2026-05-23 00:38:43.332227	Commercial	\N	\N	Arts & Entertainment	2027-05-17	\N
0fe0f223-b870-4750-958c-81b2c822643c	Tree Care Partners	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	154445583533314	2026-05-23 00:38:43.336264	2026-05-23 00:38:43.336264	Commercial	\N	\N	Home Services	2027-03-24	\N
4415a3d4-4c9e-47c1-bf42-54edc5c0aaa4	Affinity Hospice	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	168018740951137	2026-05-23 00:38:43.340199	2026-05-23 00:38:43.340199	Commercial	\N	\N	Healthcare	2027-05-31	\N
9d611b74-f155-48f1-9c1e-98fcba8e9a0b	Synovation Medical Group	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	170483384512118	2026-05-23 00:38:43.344631	2026-05-23 00:38:43.344631	Commercial	\N	\N	Healthcare	2026-07-29	\N
91e27c9d-e7d7-4eb1-aebc-28b0299fad61	Seven Feathers Casino Resort	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	155553058892478	2026-05-23 00:38:43.348699	2026-05-23 00:38:43.348699	Commercial	\N	\N	Hospitality	2026-10-31	\N
6b18c587-f4ae-4ba5-9fa7-da90b4651e06	Cadia Healthcare	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	156028013107324	2026-05-23 00:38:43.352647	2026-05-23 00:38:43.352647	Commercial	\N	\N	Wellness	2026-07-20	\N
b771bd38-843d-42ac-a4c4-7b8a6e4743cb	Skin Solutions Dermatology	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	161117854265953	2026-05-23 00:38:43.356719	2026-05-23 00:38:43.356719	Commercial	\N	\N	Healthcare	2026-12-31	\N
a560f20e-2572-40e8-8aa6-b3f2c4f55e13	Mancave For Men	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	159563215114821	2026-05-23 00:38:43.360538	2026-05-23 00:38:43.360538	Commercial	\N	\N	Beauty	2026-09-19	\N
c9f2bac4-79bd-4693-962b-613a392c7ed4	Landmark Credit Union	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	168755422764991	2026-05-23 00:38:43.366163	2026-05-23 00:38:43.366163	Commercial	\N	\N	Finance	2026-06-26	\N
9144cc67-aa42-4451-8e29-379b3bf6a314	Affordable Storage & A-Plus Super Storage	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	yellow	f	\N	\N	158377186410537	2026-05-23 00:38:43.369941	2026-05-23 00:38:43.369941	Commercial	\N	\N	Consumer Services	2026-09-09	\N
65414395-5d9c-42ee-965c-c6f8fd62bfea	W Management Services LLC	367d1e32-6cf1-42ae-8d37-bb29d5a727e4	\N	red	f	\N	\N	175588006010767	2026-05-23 00:38:43.374586	2026-05-23 00:38:43.374586	Commercial	\N	\N	Wellness	2026-09-22	\N
129570a3-8f90-4401-81b9-c7a557a04d78	Greentec Auto	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	162193860496518	2026-05-23 00:38:43.379321	2026-05-23 00:38:43.379321	Commercial	\N	\N	Automotive	2027-06-27	\N
08e8ae18-a0f7-423f-95f8-231f58de3e0d	Abra Health Group	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	174017028163476	2026-05-23 00:38:43.383954	2026-05-23 00:38:43.383954	Commercial	\N	\N	Dental	2026-05-30	\N
912bf811-0e2c-4494-b513-be5bfaa80637	Jenkins Companies	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	173636818194803	2026-05-23 00:38:43.388028	2026-05-23 00:38:43.388028	Commercial	\N	\N	Real Estate	2027-01-21	\N
8ed7f2f8-8803-4dc0-9889-51091b413394	American Portfolio Mortgage / Town Square Mortgage	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	173869454927555	2026-05-23 00:38:43.392218	2026-05-23 00:38:43.392218	Commercial	\N	\N	Finance	2027-04-27	\N
f679c292-1556-47b6-8e1b-ba4f7fe746e5	A-Key Car Wash	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	164580917494754	2026-05-23 00:38:43.396369	2026-05-23 00:38:43.396369	Commercial	\N	\N	Automotive	2026-11-19	\N
d33830ce-159a-4e79-be60-be9e82088a09	Pain Care Florida	e0433321-a79d-4393-9bff-0c6700a16aa5	\N	yellow	f	\N	\N	175743708985369	2026-05-23 00:38:43.400665	2026-05-23 00:38:43.400665	Commercial	\N	\N	Healthcare	2028-10-17	\N
c2563c51-b1c6-4f36-8618-b119397b62a6	The Arbor Company Senior Living	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	156863887006094	2026-05-23 00:38:43.407159	2026-05-23 00:38:43.407159	Commercial	\N	\N	Wellness	2026-06-29	\N
2ac52ac7-a15e-4ad7-9dc8-604f69cfa720	Mariner Finance, LLC	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	160150657532943	2026-05-23 00:38:43.411934	2026-05-23 00:38:43.411934	Commercial	\N	\N	Finance	2027-10-30	\N
3d81a7d3-111d-4e9f-bcb5-a857916a9fa0	Maid Brigade	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	166600620753167	2026-05-23 00:38:43.416226	2026-05-23 00:38:43.416226	Commercial	\N	\N	Home Services	2027-01-15	\N
1d1ce2bd-4b8f-4bbd-a419-67251d8c0ebb	Morguard	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	166794734341230	2026-05-23 00:38:43.420185	2026-05-23 00:38:43.420185	Commercial	\N	\N	Real Estate	2027-04-01	\N
89caf86a-41ef-43c3-ac2e-0caeac499de0	Waste Pro USA	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	171693075723848	2026-05-23 00:38:43.423908	2026-05-23 00:38:43.423908	Commercial	\N	\N	Consumer Services	2026-05-31	\N
b0e59598-797e-455e-aa05-7c185b0090fd	Dun & Bradstreet Corporation	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	green	f	\N	\N	175432835214180	2026-05-23 00:38:43.428113	2026-05-23 00:38:43.428113	Commercial	\N	\N	Technology	2027-04-14	\N
77c77e1e-0472-44a0-8e49-51aec8d694e4	BankSouth Mortgage Company, LLC	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	167768781547741	2026-05-23 00:38:43.432074	2026-05-23 00:38:43.432074	Commercial	\N	\N	Finance	2026-06-30	\N
58fe74ed-774f-4492-a2fa-9d83bbd09175	Rio Body Wax - Georgia	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	166673782703845	2026-05-23 00:38:43.436064	2026-05-23 00:38:43.436064	Commercial	\N	\N	Beauty	2028-03-31	\N
88f4a72a-cace-4b72-8b1c-7ba5143ad26d	Radiant Credit Union	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	161883739682286	2026-05-23 00:38:43.439959	2026-05-23 00:38:43.439959	Commercial	\N	\N	Finance	2026-09-30	\N
6c1419ce-d522-49a5-9aaf-b10cc25e5596	Benevis LLC	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	green	f	\N	\N	166318131322210	2026-05-23 00:38:43.443811	2026-05-23 00:38:43.443811	Commercial	\N	\N	Dental	2029-03-22	\N
4e6b4761-9a5a-4985-938c-1459427937e7	Apollo Veterinary Animal Hospitals	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	165048475949236	2026-05-23 00:38:43.448575	2026-05-23 00:38:43.448575	Commercial	\N	\N	Healthcare	2027-04-25	\N
bac1610a-c9f5-46ac-9877-bbcf124def55	Fortegra	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	166396606702583	2026-05-23 00:38:43.452774	2026-05-23 00:38:43.452774	Commercial	\N	\N	Insurance	2026-11-23	\N
995e8872-5d65-4535-bc61-146d065809bc	Optim Health System	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	170483370799046	2026-05-23 00:38:43.45733	2026-05-23 00:38:43.45733	Commercial	\N	\N	Healthcare	2027-03-06	\N
86103608-b3e2-4a24-b275-b5a69d540a37	Team Pest USA	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	red	f	\N	\N	167890690902671	2026-05-23 00:38:43.462575	2026-05-23 00:38:43.462575	Commercial	\N	\N	Home Services	2027-03-26	\N
041f87a7-fbff-4e44-9b35-db0105ca4d73	Gwinnett Clinic Inc	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	161856108447053	2026-05-23 00:38:43.467064	2026-05-23 00:38:43.467064	Commercial	\N	\N	Healthcare	2029-01-24	\N
32867929-6d82-4240-9d8b-d1facb117c2f	Providence Med Spa	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	166992745911725	2026-05-23 00:38:43.471216	2026-05-23 00:38:43.471216	Commercial	\N	\N	Beauty	2027-04-09	\N
3326200f-453e-4a36-a296-aa0b746597d8	Sign-A-Rama	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	173202946533014	2026-05-23 00:38:43.475504	2026-05-23 00:38:43.475504	Commercial	\N	\N	Retail	2026-11-29	\N
bb887829-5e4e-48c6-be29-7aa4094a3502	Ortho Sport & Spine Physicians	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	red	f	\N	\N	149857766893566	2026-05-23 00:38:43.479792	2026-05-23 00:38:43.479792	Commercial	\N	\N	Healthcare	2028-06-30	\N
f35430d7-4acf-457e-b749-45b58ecba47e	Bridgeview Eye Partners	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	yellow	f	\N	\N	176157825498513	2026-05-23 00:38:43.484101	2026-05-23 00:38:43.484101	Commercial	\N	\N	Healthcare	2026-12-11	\N
4bbaedce-f07e-4612-bdd3-4cd53e63bc27	Sterling Karamar Property Management	1a1f01ea-fb1d-4347-9ee6-667921cd1855	\N	red	f	\N	\N	167596175184076	2026-05-23 00:38:43.488374	2026-05-23 00:38:43.488374	Commercial	\N	\N	Real Estate	2026-06-30	\N
c6e83cd0-6e88-4a77-bc83-9c971dc25cc4	James Hardie Industries	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	171155071117389	2026-05-23 00:38:43.49256	2026-05-23 00:38:43.49256	Commercial	\N	\N	Home Services	2027-04-30	\N
2d198d74-5d2e-4b3a-9b16-2512e03227cf	Jax Kar Wash	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	161981424398263	2026-05-23 00:38:43.497365	2026-05-23 00:38:43.497365	Commercial	\N	\N	Automotive	2027-05-21	\N
430194a6-3c20-422e-954d-dfbe15924480	DxTx Pain & Spine	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	165643173224776	2026-05-23 00:38:43.501198	2026-05-23 00:38:43.501198	Commercial	\N	\N	Healthcare	2026-10-11	\N
c1794b2c-2429-4884-bf2a-be38098b975e	Diamond Residential Mortgage Corporation	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	162024894413581	2026-05-23 00:38:43.505106	2026-05-23 00:38:43.505106	Commercial	\N	\N	Finance	2026-12-21	\N
699887d9-4b21-4462-b63d-3a470121df26	Axiom Properties, Inc	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	172729981271972	2026-05-23 00:38:43.508917	2026-05-23 00:38:43.508917	Commercial	\N	\N	Real Estate	2027-06-01	\N
fb1ae9ed-468b-45a9-b473-6361d76e9d2c	Charter Senior Living	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	167839012662636	2026-05-23 00:38:43.513067	2026-05-23 00:38:43.513067	Commercial	\N	\N	Healthcare	2027-08-29	\N
79685f90-ecd0-42c7-a93f-8c19c03068fa	Winterwood	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	red	f	\N	\N	167952093316074	2026-05-23 00:38:43.517353	2026-05-23 00:38:43.517353	Commercial	\N	\N	Real Estate	2026-09-29	\N
a147fca3-5bbb-4306-87fc-b65ef0f43f53	Elite Casino Resorts	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	red	f	\N	\N	167241674314872	2026-05-23 00:38:43.521387	2026-05-23 00:38:43.521387	Commercial	\N	\N	Hospitality	2029-07-24	\N
2cfff33f-2e05-4f78-8256-5ba25bab5b4a	Veterinarian Partners	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	173686570508661	2026-05-23 00:38:43.525549	2026-05-23 00:38:43.525549	Commercial	\N	\N	Healthcare	2027-03-05	\N
144f455c-42d2-4518-a488-69cbe294125f	Sunrun Inc.	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	171216525922055	2026-05-23 00:38:43.530176	2026-05-23 00:38:43.530176	Commercial	\N	\N	Home Services	2027-02-08	\N
a4e9d8a3-b6c5-4ec5-bb56-22a6e23e357b	LightRx	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	147259959283396	2026-05-23 00:38:43.53426	2026-05-23 00:38:43.53426	Commercial	\N	\N	Wellness	2027-01-20	\N
765d0a98-81d7-48f7-b535-2e79592fe1b0	LynCo, Inc.	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	red	f	\N	\N	172736965454919	2026-05-23 00:38:43.538514	2026-05-23 00:38:43.538514	Commercial	\N	\N	Real Estate	2026-06-01	\N
adb6facf-3fb3-463e-b723-b26bf48707b4	Dentologie	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	166377007753222	2026-05-23 00:38:43.54397	2026-05-23 00:38:43.54397	Commercial	\N	\N	Dental	2026-09-28	\N
aef55a08-2d88-4d60-8fb5-47998884dda5	Bridges Health	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	169141929838208	2026-05-23 00:38:43.548359	2026-05-23 00:38:43.548359	Commercial	\N	\N	Healthcare	2027-02-20	\N
68354375-ebd2-455f-be54-fb6f7502729c	McCormack Baron Management	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	167518525516073	2026-05-23 00:38:43.552197	2026-05-23 00:38:43.552197	Commercial	\N	\N	Real Estate	2027-01-22	\N
04bda506-65ab-4bb0-834f-72134a4abd77	Next Day Access	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	156926105473084	2026-05-23 00:38:43.55649	2026-05-23 00:38:43.55649	Commercial	\N	\N	Home Services	2027-03-27	\N
ceac5859-134a-4029-9286-05de2af5b2de	54th Street Grill & Bar	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	150635082131960	2026-05-23 00:38:43.560748	2026-05-23 00:38:43.560748	Commercial	\N	\N	Restaurants	2027-01-28	\N
e51b1c53-e39b-4401-94b5-b64a11759dd1	DCC Propane	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	173091357539787	2026-05-23 00:38:43.564946	2026-05-23 00:38:43.564946	Commercial	\N	\N	Home Services	2027-03-30	\N
42162029-f96e-4065-8e99-2cc6a0478198	HumanGood	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	173393412290061	2026-05-23 00:38:43.569278	2026-05-23 00:38:43.569278	Commercial	\N	\N	Wellness	2026-10-30	\N
803f2a2f-9d0f-4f6b-831a-efa5bc0a0f16	BEST WASH LAUNDROMATS	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	172487701873033	2026-05-23 00:38:43.573308	2026-05-23 00:38:43.573308	Commercial	\N	\N	Consumer Services	2026-08-29	\N
e5574159-f5b0-4f69-9d19-864656527470	LRS	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	170560869470315	2026-05-23 00:38:43.577042	2026-05-23 00:38:43.577042	Commercial	\N	\N	Consumer Services	2027-02-20	\N
50574d17-181d-41ae-a2d9-0714435ef50b	Lionheart Children's Academy	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	red	f	\N	\N	168367157852481	2026-05-23 00:38:43.581259	2026-05-23 00:38:43.581259	Commercial	\N	\N	Other	2028-06-23	\N
82b393d5-57bb-40af-ae13-52ae07435cb0	Feeders Supply	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	172919219699040	2026-05-23 00:38:43.585317	2026-05-23 00:38:43.585317	Commercial	\N	\N	Retail	2027-12-30	\N
bd116d08-63ec-4adf-922e-618efc25f7be	WesleyLife	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	163943580209347	2026-05-23 00:38:43.589296	2026-05-23 00:38:43.589296	Commercial	\N	\N	Wellness	2027-01-19	\N
396ce381-0569-4ebe-98f0-c978b9667716	Reliant Specialty Infusion	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	171390124547289	2026-05-23 00:38:43.593439	2026-05-23 00:38:43.593439	Commercial	\N	\N	Healthcare	2026-06-03	\N
352d5737-0896-45bf-9615-615263db2c7e	HCW	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	171865248355818	2026-05-23 00:38:43.597951	2026-05-23 00:38:43.597951	Commercial	\N	\N	Contractors	2027-07-31	\N
95abd551-784b-46b4-8821-a15f6d5ebc6c	Western States Lodging	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	170319448161884	2026-05-23 00:38:43.601973	2026-05-23 00:38:43.601973	Commercial	\N	\N	Consumer Services	2027-03-16	\N
bcbcd027-b411-4465-8848-9f2c12434236	RENOSY by Renters Warehouse	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	red	f	\N	\N	149074211910568	2026-05-23 00:38:43.60632	2026-05-23 00:38:43.60632	Commercial	\N	\N	Real Estate	2027-04-25	\N
5ac643ef-8a0b-4c70-a635-086b32ae467f	Banner Property Management	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	red	f	\N	\N	166127587775325	2026-05-23 00:38:43.610236	2026-05-23 00:38:43.610236	Commercial	\N	\N	Real Estate	2027-01-01	\N
a67d3367-7c0e-4fd1-a88a-96cedc22d84a	21st Mortgage Corporation	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	157229406815254	2026-05-23 00:38:43.614223	2026-05-23 00:38:43.614223	Commercial	\N	\N	Finance	2026-12-31	\N
ab3b0082-285b-4e05-a251-361a4f89c3eb	Granite Student Living	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	168191604229118	2026-05-23 00:38:43.618272	2026-05-23 00:38:43.618272	Commercial	\N	\N	Real Estate	2027-04-26	\N
580b0f67-7c49-4827-b5b6-44a315753f14	Del Norte Credit Union	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	166492057294075	2026-05-23 00:38:43.622988	2026-05-23 00:38:43.622988	Commercial	\N	\N	Finance	2026-11-30	\N
3c2aed5e-ea0f-4569-9a8e-8a484951b81b	The Advocates	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	169325924980082	2026-05-23 00:38:43.627188	2026-05-23 00:38:43.627188	Commercial	\N	\N	Legal	2026-11-30	\N
ba01bcf5-c40a-409e-8426-587fe62b5f21	First Central Credit Union	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	green	f	\N	\N	159837819726175	2026-05-23 00:38:43.630743	2026-05-23 00:38:43.630743	Commercial	\N	\N	Finance	2027-01-30	\N
042f5e3a-b9ac-4b62-9a68-fbbcd4f35d9b	Preferred Management Services Inc	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	166568006775782	2026-05-23 00:38:43.634426	2026-05-23 00:38:43.634426	Commercial	\N	\N	Real Estate	2026-07-28	\N
f8981b5d-6e41-4d5c-83ac-48bec4f52f05	Warren & Griffin P.C.	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	158212406021287	2026-05-23 00:38:43.638305	2026-05-23 00:38:43.638305	Commercial	\N	\N	Legal	2029-02-18	\N
1a451896-0fd6-4373-a9ff-195dcb470010	Choice Wireless	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	red	f	\N	\N	157141066399282	2026-05-23 00:38:43.642307	2026-05-23 00:38:43.642307	Commercial	\N	\N	Technology	2027-01-14	\N
41fed0d6-5d02-4299-8f2b-dd38a0ba0135	DDS Partners	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	yellow	f	\N	\N	169178529329167	2026-05-23 00:38:43.647247	2026-05-23 00:38:43.647247	Commercial	\N	\N	Dental	2027-08-19	\N
08d1fccb-f4d8-40cf-ba71-dc29ea9b1b74	American Pain Consortium	a31b3aa4-8170-469b-97a7-28850de6cdc2	\N	red	f	\N	\N	165453907832734	2026-05-23 00:38:43.65125	2026-05-23 00:38:43.65125	Commercial	\N	\N	Healthcare	2028-10-28	\N
a7b91d47-64b2-489c-ba00-0cbe3f7bdfb2	Southeast Medical Group P.C.	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	167787109288480	2026-05-23 00:38:43.655259	2026-05-23 00:38:43.655259	Commercial	\N	\N	Healthcare	2026-05-30	\N
6c1826aa-8e8f-4ac7-9da4-cee74f476e73	Behavioral Innovations Inc	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	red	f	\N	\N	166983620049116	2026-05-23 00:38:43.660055	2026-05-23 00:38:43.660055	Commercial	\N	\N	Healthcare	2027-03-31	\N
02f880ec-ba18-40ac-9fa6-1943eb7bb1c0	Blackmon Mooring & BMS CAT	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	164364668217571	2026-05-23 00:38:43.664136	2026-05-23 00:38:43.664136	Commercial	\N	\N	Home Services	2028-04-10	\N
3a3845b1-6402-4fc6-9f38-af37f46378e1	LCB Senior Living	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	red	f	\N	\N	156639718746024	2026-05-23 00:38:43.669091	2026-05-23 00:38:43.669091	Commercial	\N	\N	Wellness	2027-03-11	\N
22254278-b1fb-4d5e-a304-13002e438f5c	National Property Inspections	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	156055491235258	2026-05-23 00:38:43.674061	2026-05-23 00:38:43.674061	Commercial	\N	\N	Home Services	2026-06-28	\N
7cf69a5b-4300-4fbd-8cc4-11d7fdfcfea2	CareOne	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	164624881078069	2026-05-23 00:38:43.678454	2026-05-23 00:38:43.678454	Commercial	\N	\N	Wellness	2026-12-19	\N
1145a7f4-ed74-413c-9166-5bcc1a51683c	The RealReal	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	164703796822555	2026-05-23 00:38:43.682498	2026-05-23 00:38:43.682498	Commercial	\N	\N	Retail	2026-10-30	\N
6b26f333-ab74-4569-9240-4797806773e4	Farah & Farah	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	157020020130726	2026-05-23 00:38:43.686569	2026-05-23 00:38:43.686569	Commercial	\N	\N	Legal	2026-09-25	\N
e7457197-c0f2-43d8-a66a-3b9a0c8c062c	Kids Empire	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	171693232950359	2026-05-23 00:38:43.690985	2026-05-23 00:38:43.690985	Commercial	\N	\N	Recreation	2027-06-21	\N
066fd199-5d57-46e1-bb04-28002f70f2e5	EmergeOrtho-Triangle Region	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	167587450096839	2026-05-23 00:38:43.695063	2026-05-23 00:38:43.695063	Commercial	\N	\N	Healthcare	2027-06-21	\N
7f5cf773-8133-41c6-a4a2-aa6e9869e4c7	Walters Wedding Estates	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	172919541113348	2026-05-23 00:38:43.699999	2026-05-23 00:38:43.699999	Commercial	\N	\N	Consumer Services	2026-11-20	\N
c5b11ae6-0251-4135-8904-5a978c2d13bf	Bail Hotline	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	162630751308873	2026-05-23 00:38:43.704255	2026-05-23 00:38:43.704255	Commercial	\N	\N	Consumer Services	2026-07-22	\N
367f3d5d-d352-4bc0-914c-d507bb5dd3cc	Agemark Corporation	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	161132609865939	2026-05-23 00:38:43.708404	2026-05-23 00:38:43.708404	Commercial	\N	\N	Healthcare	2026-08-06	\N
c12511a3-9fa6-46e3-8819-f19f96338682	Tradehome Shoes Home Office and Distribution Center	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	167726086489430	2026-05-23 00:38:43.712269	2026-05-23 00:38:43.712269	Commercial	\N	\N	Retail	2028-05-07	\N
c2ab4391-69c6-4c51-856b-0ba2a1b068a6	Southern Careers Institute	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	red	f	\N	\N	153736466715746	2026-05-23 00:38:43.716305	2026-05-23 00:38:43.716305	Commercial	\N	\N	Education	2026-05-24	\N
fbd9d2ff-772f-4e23-a4ad-29fcc51c4b71	Yess Home Center	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	164704011285132	2026-05-23 00:38:43.71984	2026-05-23 00:38:43.71984	Commercial	\N	\N	Finance	2026-06-17	\N
74752f6e-6bab-4ac9-85af-29ee80693227	Key-Whitman Eye Center	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	155501380785626	2026-05-23 00:38:43.723791	2026-05-23 00:38:43.723791	Commercial	\N	\N	Healthcare	2027-09-25	\N
5f57d651-7069-4d0d-936b-846a0cb9d8dd	First National Bank and Trust	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	160711287041155	2026-05-23 00:38:43.727718	2026-05-23 00:38:43.727718	Commercial	\N	\N	Finance	2027-02-23	\N
10acd8ef-bc82-4069-a5f1-bee8f61cc3ff	Complete Care	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	144200997364872	2026-05-23 00:38:43.731389	2026-05-23 00:38:43.731389	Commercial	\N	\N	Healthcare	2027-04-20	\N
07723c04-60b5-4a1f-b03c-79bc9b1b4066	Worldwide Express	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	red	f	\N	\N	165220778339259	2026-05-23 00:38:43.735266	2026-05-23 00:38:43.735266	Commercial	\N	\N	Transportation Services	2026-08-11	\N
a897e6b6-0f42-4f3d-87f1-0a3be2a8f840	BlueSprig Pediatrics	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	169350687609016	2026-05-23 00:38:43.739271	2026-05-23 00:38:43.739271	Commercial	\N	\N	Healthcare	2027-03-20	\N
caf0ce32-f02b-4bb6-96c3-b3e7997c0023	American Fence Company	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	red	f	\N	\N	166492099884180	2026-05-23 00:38:43.742911	2026-05-23 00:38:43.742911	Commercial	\N	\N	Construction	2026-10-16	\N
3f4e5f97-177d-40f7-9b5b-9792947efed6	First American Bank	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	161668997543073	2026-05-23 00:38:43.746572	2026-05-23 00:38:43.746572	Commercial	\N	\N	Finance	2027-08-01	\N
1ed9d333-fb4d-4ce4-90f5-c60a92ddd918	Grand Fitness Partners	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	red	f	\N	\N	157549658535715	2026-05-23 00:38:43.75021	2026-05-23 00:38:43.75021	Commercial	\N	\N	Wellness	2026-11-16	\N
f7a244cf-b94b-466b-a6b9-b8e66569591f	Restaurant Technologies	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	red	f	\N	\N	168073105505190	2026-05-23 00:38:43.75427	2026-05-23 00:38:43.75427	Commercial	\N	\N	Retail	2027-05-21	\N
2ecd5e01-3599-4ef9-ba72-db4598a12b25	yorCMO	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	167337414320349	2026-05-23 00:38:43.758748	2026-05-23 00:38:43.758748	Commercial	\N	\N	Business Services	2028-02-24	\N
9aa77734-8483-4a4f-96d6-9f472e853169	American Sale	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	149332895614867	2026-05-23 00:38:43.763904	2026-05-23 00:38:43.763904	Commercial	\N	\N	Consumer Services	2027-08-14	\N
b9b90ea9-5314-4391-9039-05e70f08f865	Your Boat Club	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	172850421901680	2026-05-23 00:38:43.7677	2026-05-23 00:38:43.7677	Commercial	\N	\N	Automotive	2028-08-25	\N
53a749ae-44d7-4bf8-a43a-2c2e46308b54	Safe Harbor Behavioral Care	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	162742032333693	2026-05-23 00:38:43.771966	2026-05-23 00:38:43.771966	Commercial	\N	\N	Healthcare	2026-10-31	\N
0f464ae7-c292-4a3e-ab06-02d17534db30	USA Mortgage	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	174250171781253	2026-05-23 00:38:43.775903	2026-05-23 00:38:43.775903	Commercial	\N	\N	Finance	2026-09-29	\N
31d731dc-8495-4d16-9dfa-a690592584c2	Ignite Credit Union	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	red	f	\N	\N	170956445170763	2026-05-23 00:38:43.780959	2026-05-23 00:38:43.780959	Commercial	\N	\N	Finance	2027-02-11	\N
f0e1a156-e860-41b3-932b-7e83c344c2c3	Arthritis Knee Pain Centers	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	153729464045582	2026-05-23 00:38:43.784913	2026-05-23 00:38:43.784913	Commercial	\N	\N	Healthcare	2026-10-30	\N
4f6c4365-348c-4d9e-8d20-59374b8a542b	Dr. G's Urgent Care Delray Beach, FL	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	160331600826053	2026-05-23 00:38:43.789025	2026-05-23 00:38:43.789025	Commercial	\N	\N	Healthcare	2026-06-25	\N
cece46b5-0a91-4381-8177-71c0331fb525	Boys Town National Research Hospital	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	159664223833197	2026-05-23 00:38:43.792797	2026-05-23 00:38:43.792797	Commercial	\N	\N	Healthcare	2027-01-27	\N
0846f15d-96d3-4b9a-8d84-7e633c8a569a	Gershman Mortgage	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	155602333202378	2026-05-23 00:38:43.796728	2026-05-23 00:38:43.796728	Commercial	\N	\N	Finance	2026-12-19	\N
5c8ad08d-3e39-4c8d-b845-d5e8bb333180	South Jersey Radiology	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	red	f	\N	\N	155958970300357	2026-05-23 00:38:43.800446	2026-05-23 00:38:43.800446	Commercial	\N	\N	Healthcare	2026-07-19	\N
91566d4b-5a38-4563-9948-8003b838c7dc	Center for Vein Restoration	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	170483174823717	2026-05-23 00:38:43.804313	2026-05-23 00:38:43.804313	Commercial	\N	\N	Healthcare	2028-12-29	\N
d9c6fbed-b0f5-44fc-a445-726454406d0e	Lamps Plus	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	147449196205685	2026-05-23 00:38:43.808053	2026-05-23 00:38:43.808053	Commercial	\N	\N	Home Services	2026-07-23	\N
20435d21-a56a-4f2c-a781-3fb42c0c3d95	Majestic Care	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	162033840709843	2026-05-23 00:38:43.811992	2026-05-23 00:38:43.811992	Commercial	\N	\N	Healthcare	2027-01-26	\N
c679ab4d-3ae1-4e18-b466-1ed82ed54410	Metropolitan Associates	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	red	f	\N	\N	172980224862378	2026-05-23 00:38:43.815541	2026-05-23 00:38:43.815541	Commercial	\N	\N	Real Estate	2027-01-25	\N
2bbca024-6e33-4573-9ba9-2861381b4f52	Wallick Communities	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	green	f	\N	\N	155863542383662	2026-05-23 00:38:43.819935	2026-05-23 00:38:43.819935	Commercial	\N	\N	Real Estate	2026-12-25	\N
490e15c5-bb5e-4c06-88eb-86a71a0eed66	YMCA of Greater Oklahoma City	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	168450623827648	2026-05-23 00:38:43.824346	2026-05-23 00:38:43.824346	Commercial	\N	\N	Wellness	2027-04-14	\N
392e34b3-f496-4793-9ff1-0b167df505a1	Wrench	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	red	f	\N	\N	169965608717626	2026-05-23 00:38:43.828671	2026-05-23 00:38:43.828671	Commercial	\N	\N	Automotive	2026-09-27	\N
65f97d68-5279-4702-a715-4a89c6ca8450	River Pools And Spas	d0f3d476-5058-45ea-8f4d-fa0a9ebd8697	\N	yellow	f	\N	\N	162396152824351	2026-05-23 00:38:43.833169	2026-05-23 00:38:43.833169	Commercial	\N	\N	Contractors	2026-08-30	\N
d6d7a8bb-a895-49d1-98d9-020486040902	Amazing Home Care	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	169142625836468	2026-05-23 00:38:43.837667	2026-05-23 00:38:43.837667	Commercial	\N	\N	Healthcare	2026-08-29	\N
dd61854f-fdd4-43f7-b6a8-45d3fefae69a	US Fertility	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	165785098613767	2026-05-23 00:38:43.842154	2026-05-23 00:38:43.842154	Commercial	\N	\N	Healthcare	2026-12-20	\N
d8832df4-0b06-4b24-b00a-3d9d93dd0f4a	Rogers Enterprises, Inc.	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	162463682355003	2026-05-23 00:38:43.845924	2026-05-23 00:38:43.845924	Commercial	\N	\N	Business Services	2026-07-30	\N
1bdd8ccf-ead4-4e4d-a1f2-c2161fa6477c	Autumn Lake Healthcare	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	170197529224927	2026-05-23 00:38:43.849981	2026-05-23 00:38:43.849981	Commercial	\N	\N	Healthcare	2027-01-31	\N
efda7044-a308-4249-8d07-ea85efa9ee03	Hendersen-Webb, Inc.	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	160340436353518	2026-05-23 00:38:43.854612	2026-05-23 00:38:43.854612	Commercial	\N	\N	Real Estate	2027-03-14	\N
41f8687f-b4c2-4eee-a49a-0761d714fd74	Hill Valley Healthcare	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	168659617912436	2026-05-23 00:38:43.859253	2026-05-23 00:38:43.859253	Commercial	\N	\N	Finance	2026-06-27	\N
0a213c07-c654-427c-9683-305e7c345809	Proud Moments ABA	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	red	f	\N	\N	165333424654814	2026-05-23 00:38:43.863083	2026-05-23 00:38:43.863083	Commercial	\N	\N	Healthcare	2026-06-30	\N
244a1166-5963-4911-8211-92603f8e592b	First Fertility	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	168419159788930	2026-05-23 00:38:43.867161	2026-05-23 00:38:43.867161	Commercial	\N	\N	Healthcare	2027-03-25	\N
8ee958d5-25b6-41db-90b4-4e6ad5300853	Cove Property Management	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	156337167878072	2026-05-23 00:38:43.870899	2026-05-23 00:38:43.870899	Commercial	\N	\N	Real Estate	2026-06-21	\N
21be2953-0f01-451a-b6e9-c297ddd9d053	Guidance Residential	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	159413094020836	2026-05-23 00:38:43.874608	2026-05-23 00:38:43.874608	Commercial	\N	\N	Real Estate	2026-07-26	\N
66bfbfe0-209a-48f8-93f3-ff44b5ddb75a	Southern Trust Mortgage LLC	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	170569106996636	2026-05-23 00:38:43.878452	2026-05-23 00:38:43.878452	Commercial	\N	\N	Finance	2026-07-24	\N
4371773c-a838-40a5-92c5-a77d9e9f5c47	Elevate Living	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	red	f	\N	\N	153929052595767	2026-05-23 00:38:43.883048	2026-05-23 00:38:43.883048	Commercial	\N	\N	Real Estate	2026-10-24	\N
74276adf-9472-407c-b9c7-d944071bee4c	Two Men and a Truck - Charlotte	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	red	f	\N	\N	170811041864395	2026-05-23 00:38:43.88699	2026-05-23 00:38:43.88699	Commercial	\N	\N	Transportation Services	2027-04-29	\N
46a36787-22cb-4aad-a260-7eabda33ba50	Bethpage Federal Credit Union	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	165763766835978	2026-05-23 00:38:43.890728	2026-05-23 00:38:43.890728	Commercial	\N	\N	Finance	2026-08-31	\N
734896d8-b5e7-4476-b673-e31223b819dd	The Apartment Gallery	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	red	f	\N	\N	156760106440362	2026-05-23 00:38:43.894352	2026-05-23 00:38:43.894352	Commercial	\N	\N	Real Estate	2026-10-30	\N
1d38ee88-e3ec-489c-a436-3aee3ebb6972	Montway LLC	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	148357050542971	2026-05-23 00:38:43.89784	2026-05-23 00:38:43.89784	Commercial	\N	\N	Transportation Services	2026-11-30	\N
498cf95c-c85b-4723-b5a0-b93959209d72	Castle Park Investments	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	red	f	\N	\N	169887052545833	2026-05-23 00:38:43.901387	2026-05-23 00:38:43.901387	Commercial	\N	\N	Hospitality	2026-12-30	\N
b748cfaf-fe97-4dfb-81b5-802add692a9d	Mark Medical Care	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	166066827210865	2026-05-23 00:38:43.905095	2026-05-23 00:38:43.905095	Commercial	\N	\N	Healthcare	2026-06-28	\N
99fc72b8-3f7e-484a-916f-27968259ec30	C.S. Wo	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	149875658358699	2026-05-23 00:38:43.908753	2026-05-23 00:38:43.908753	Commercial	\N	\N	Home Services	2026-06-29	\N
e2901698-05f2-4808-9b0f-9ec960c50781	V Care OB/GYN	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	165782096968718	2026-05-23 00:38:43.912533	2026-05-23 00:38:43.912533	Commercial	\N	\N	Healthcare	2026-07-15	\N
5f61cafb-4773-4a40-8092-508a9f749b8b	Wilder Balter Partners Inc.	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	red	f	\N	\N	158108587780496	2026-05-23 00:38:43.916303	2026-05-23 00:38:43.916303	Commercial	\N	\N	Real Estate	2026-09-29	\N
bdc0e123-f9ed-4944-a31e-db06139fb137	Champion Homes	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	red	f	\N	\N	170631033033451	2026-05-23 00:38:43.920062	2026-05-23 00:38:43.920062	Commercial	\N	\N	Construction	2027-02-28	\N
fca9f622-5560-4a53-a586-06ccc8397290	Outreach	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	red	f	\N	\N	170483108682312	2026-05-23 00:38:43.925063	2026-05-23 00:38:43.925063	Commercial	\N	\N	Healthcare	2027-01-29	\N
70b0f6e7-be4c-4e02-87e5-0bad793d9673	Quick Care Med	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	156920039636093	2026-05-23 00:38:43.929206	2026-05-23 00:38:43.929206	Commercial	\N	\N	Healthcare	2026-10-26	\N
e1979d69-12d4-427a-af9a-83faa894bb5b	California Patio	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	163467342678691	2026-05-23 00:38:43.933135	2026-05-23 00:38:43.933135	Commercial	\N	\N	Retail	2026-12-11	\N
6279fb66-4522-405d-ad85-d119f8da1826	Ettinger Law Firm	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	155663435251360	2026-05-23 00:38:43.937074	2026-05-23 00:38:43.937074	Commercial	\N	\N	Legal	2027-05-13	\N
205dfd2d-f6db-4dfc-aade-75d24ba018ef	Great Lakes Bay Health Centers	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	161854129854459	2026-05-23 00:38:43.943166	2026-05-23 00:38:43.943166	Commercial	\N	\N	Healthcare	2026-09-29	\N
304757ec-fddb-448b-a816-da22b74503f3	Dynamic Companies	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	159888841810728	2026-05-23 00:38:43.947334	2026-05-23 00:38:43.947334	Commercial	\N	\N	Other	2027-01-28	\N
fecc541e-87ed-4a06-b8e8-53f51c7198d9	Heartland Company	77458093-f257-44d0-bef6-a22768b5402b	\N	red	f	\N	\N	163290120178104	2026-05-23 00:38:43.950952	2026-05-23 00:38:43.950952	Commercial	\N	\N	Construction	2027-12-17	\N
bdd85d3e-e693-495c-88f5-c4e3082fe309	Cordell & Cordell P.C	77458093-f257-44d0-bef6-a22768b5402b	\N	red	f	\N	\N	161852598452570	2026-05-23 00:38:43.954856	2026-05-23 00:38:43.954856	Commercial	\N	\N	Legal	2026-06-29	\N
44e021b7-8ff1-44be-9dbf-b0890afc52a3	Meridia Living	77458093-f257-44d0-bef6-a22768b5402b	\N	yellow	f	\N	\N	151182646359821	2026-05-23 00:38:43.958924	2026-05-23 00:38:43.958924	Commercial	\N	\N	Real Estate	2028-01-08	\N
83192223-3c47-4003-98e9-e717940618a9	Pure Healthcare	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	167459840362065	2026-05-23 00:38:43.963439	2026-05-23 00:38:43.963439	Commercial	\N	\N	Healthcare	2028-03-12	\N
35b3fe3b-1c5b-49c8-9e10-662e4d2e0ded	Repipe Specialists	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	167483770354494	2026-05-23 00:38:43.967424	2026-05-23 00:38:43.967424	Commercial	\N	\N	Construction	2026-08-31	\N
b1deece3-e0bb-4e38-8f48-51a24ff9f7b7	Vision Innovation Partners	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	170483423273844	2026-05-23 00:38:43.971173	2026-05-23 00:38:43.971173	Commercial	\N	\N	Healthcare	2026-07-29	\N
58bbc901-4340-400c-8589-567537dd0ace	Dreyfuss LLC	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	172730188679391	2026-05-23 00:38:43.975101	2026-05-23 00:38:43.975101	Commercial	\N	\N	Real Estate	2027-06-01	\N
65a5730c-a8bb-4956-b3f8-94e1d4a410d2	OGD Overhead Garage Door	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	169514868545348	2026-05-23 00:38:43.978975	2026-05-23 00:38:43.978975	Commercial	\N	\N	Home Services	2026-11-30	\N
5da9cef1-44e2-4cd1-85ff-97bef626b9c1	Rumpke	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	162065294758638	2026-05-23 00:38:43.982926	2026-05-23 00:38:43.982926	Commercial	\N	\N	Government	2027-01-01	\N
b3e2ec97-152e-4c14-b5c9-8e097877756f	Tower Loan	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	175250302853395	2026-05-23 00:38:43.987835	2026-05-23 00:38:43.987835	Commercial	\N	\N	Finance	2028-08-06	\N
3433c8d7-ce06-41ae-a749-9c3cbb6747dd	Anytime Storage	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	174645948417509	2026-05-23 00:38:43.992046	2026-05-23 00:38:43.992046	Commercial	\N	\N	Business Services	2027-05-25	\N
2b9d4a65-ade3-4139-8e8b-dffa638153f5	Garage Experts International	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	165548174949949	2026-05-23 00:38:43.995964	2026-05-23 00:38:43.995964	Commercial	\N	\N	Home Services	2027-12-29	\N
7e9eb0a1-9311-4c33-a32d-a9ea98db581e	Endeavor Schools	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	red	f	\N	\N	173170553042632	2026-05-23 00:38:44.000049	2026-05-23 00:38:44.000049	Commercial	\N	\N	Education	2026-05-30	\N
e47eeb20-d797-4389-b892-42b8929c9260	Blue Cardinal Home Services Group	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	169960117976138	2026-05-23 00:38:44.004353	2026-05-23 00:38:44.004353	Commercial	\N	\N	Contractors	2026-09-01	\N
e18dca9a-a7a9-447f-b852-3f05ca0d1542	Empower Behavioral Health	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	170483341164610	2026-05-23 00:38:44.008175	2026-05-23 00:38:44.008175	Commercial	\N	\N	Healthcare	2027-01-31	\N
aa2acc87-f4e0-4713-8653-1b2d46be2b29	Storal	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	1759310334092353	2026-05-23 00:38:44.011956	2026-05-23 00:38:44.011956	Commercial	\N	\N	Education	2027-09-26	\N
3fd0d0e3-e834-43b3-9f0a-2e53df06ee0d	Allied Universal	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	161812309029172	2026-05-23 00:38:44.015975	2026-05-23 00:38:44.015975	Commercial	\N	\N	Business Services	2027-07-01	\N
d1d860f9-0970-4744-94f6-429909330c7d	Guardian Fleet Services	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	164208891946270	2026-05-23 00:38:44.019979	2026-05-23 00:38:44.019979	Commercial	\N	\N	Transportation Services	2027-01-31	\N
8e1ba8a1-beb3-4ba2-a984-62a4b0a6bbcb	Stonegate Senior Living	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	154939658362629	2026-05-23 00:38:44.023647	2026-05-23 00:38:44.023647	Commercial	\N	\N	Wellness	2026-10-19	\N
46e89a70-6eca-4ce4-8075-f8dfb744f848	1-800-PLUMBER +AIR	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	167702133227024	2026-05-23 00:38:44.027947	2026-05-23 00:38:44.027947	Commercial	\N	\N	Other	2026-05-31	\N
5d63ee32-505d-4758-b8b6-7dd833a9117d	Sunburst Shutters & Window Fashions	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	156035530971880	2026-05-23 00:38:44.031871	2026-05-23 00:38:44.031871	Commercial	\N	\N	Home Services	2026-11-01	\N
c1fdfcc8-1b27-4719-8e45-cca6bbb09b32	Fath Properties	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	160461024040053	2026-05-23 00:38:44.035839	2026-05-23 00:38:44.035839	Commercial	\N	\N	Real Estate	2026-11-24	\N
d0134473-f342-4026-b472-d3eb4735b6f9	Union Real Estate	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	172739250987258	2026-05-23 00:38:44.040103	2026-05-23 00:38:44.040103	Commercial	\N	\N	Real Estate	2028-05-26	\N
4735bef7-c2e1-4197-9552-54ceb5fc7c2a	Space Shop Self Storage	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	168557479671795	2026-05-23 00:38:44.044133	2026-05-23 00:38:44.044133	Commercial	\N	\N	Contractors	2027-06-30	\N
c150da90-44ce-4dff-a876-d4c446787e82	Cavenders	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	174491239919455	2026-05-23 00:38:44.049083	2026-05-23 00:38:44.049083	Commercial	\N	\N	Retail	2026-06-13	\N
25c91f26-914e-4fec-9e77-b0fcdb2e82aa	Bonmente | Psychiatrist Long Beach, Psychiatrist Los Angeles	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	169603369850315	2026-05-23 00:38:44.052905	2026-05-23 00:38:44.052905	Commercial	\N	\N	Healthcare	2026-08-06	\N
00f7a62e-681b-4c3f-9bbb-a515de841e23	Glo Tanning Salon	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	174742874445848	2026-05-23 00:38:44.057401	2026-05-23 00:38:44.057401	Commercial	\N	\N	Wellness	2027-05-20	\N
242227e3-b3e5-4241-89d8-983e0cb3ef69	YMCA Central Florida	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	169937173396124	2026-05-23 00:38:44.062081	2026-05-23 00:38:44.062081	Commercial	\N	\N	Arts & Entertainment	2026-12-30	\N
1f6f065b-4b54-4057-8087-f16986795db5	Pinnacle Propane, LLC	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	166333966296955	2026-05-23 00:38:44.066639	2026-05-23 00:38:44.066639	Commercial	\N	\N	Consumer Goods	2026-11-13	\N
7a0a1537-6ff8-4ade-9f49-d97f8e44c7f6	MORTGAGE INVESTORS GROUP	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	162331651918629	2026-05-23 00:38:44.071269	2026-05-23 00:38:44.071269	Commercial	\N	\N	Insurance	2027-01-16	\N
a23bd816-d640-4b22-94db-026050559e40	Me-n-Ed's Pizzeria	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	165515781473757	2026-05-23 00:38:44.075758	2026-05-23 00:38:44.075758	Commercial	\N	\N	Business Services	2026-09-30	\N
719e15c6-7823-4209-9451-9b6b074052ab	PAssioun Enterprises	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	159586436839621	2026-05-23 00:38:44.079538	2026-05-23 00:38:44.079538	Commercial	\N	\N	Dental	2026-10-06	\N
f2a5230a-5ca6-4cdc-bc1a-e2f2fa6812e0	Kane's Furniture	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	175569724457419	2026-05-23 00:38:44.083628	2026-05-23 00:38:44.083628	Commercial	\N	\N	Retail	2027-09-29	\N
95cc41e4-83bc-44a1-8b7e-1bdece9eff01	Specialdocs Consultants, LLC.	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	148167150260372	2026-05-23 00:38:44.087528	2026-05-23 00:38:44.087528	Commercial	\N	\N	Business Services	2026-07-31	\N
047c6779-2200-4442-b897-4622d255e5d0	Avrek Law	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	156872904493844	2026-05-23 00:38:44.092458	2026-05-23 00:38:44.092458	Commercial	\N	\N	Legal	2026-08-28	\N
7713565e-275b-4cd4-b883-56384d5b2971	Benedictine Health System	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	169029725877389	2026-05-23 00:38:44.096639	2026-05-23 00:38:44.096639	Commercial	\N	\N	Healthcare	2026-06-30	\N
23d46828-31cd-4a82-ac5b-4ae3621809c4	Evolve Health	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	173921604234771	2026-05-23 00:38:44.100258	2026-05-23 00:38:44.100258	Commercial	\N	\N	Healthcare	2028-02-19	\N
09a455a4-a18d-4c4d-b36d-b623619a0229	LPI Inc.	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	171866888962354	2026-05-23 00:38:44.104126	2026-05-23 00:38:44.104126	Commercial	\N	\N	Automotive	2027-10-22	\N
c98533b1-f141-43b7-af4e-e6582425f20f	Bel Furniture - Clute	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	165600568647706	2026-05-23 00:38:44.107897	2026-05-23 00:38:44.107897	Commercial	\N	\N	Retail	2026-12-14	\N
5a9e2a97-7345-4401-8bb5-ed75d4b58afe	North	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	red	f	\N	\N	171821604065911	2026-05-23 00:38:44.111628	2026-05-23 00:38:44.111628	Commercial	\N	\N	Finance	2026-06-28	\N
8c4bea2e-e97b-4435-9b3f-4cd2f9b05d1a	Ultracuts	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	169159654100272	2026-05-23 00:38:44.115915	2026-05-23 00:38:44.115915	Commercial	\N	\N	Beauty	2026-09-26	\N
4d6eff50-0111-4934-987b-d8485c720c10	Fat Boyz Barbecue Restaurant	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	171960921411290	2026-05-23 00:38:44.119665	2026-05-23 00:38:44.119665	Commercial	\N	\N	Restaurants	2026-06-30	\N
f046ee46-9f7d-4395-af23-b744ef823ea9	Gamble Home	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	167285566603352	2026-05-23 00:38:44.124184	2026-05-23 00:38:44.124184	Commercial	\N	\N	Retail	2027-01-18	\N
3b67ac1f-2f1e-42c9-bb06-4cad85124ace	StorageMax	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	175692530023761	2026-05-23 00:38:44.128207	2026-05-23 00:38:44.128207	Commercial	\N	\N	Consumer Services	2027-09-15	\N
885b98e3-678d-48a5-9120-d8980817211d	Range	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	165533122788317	2026-05-23 00:38:44.132556	2026-05-23 00:38:44.132556	Commercial	\N	\N	Business Services	2026-08-01	\N
2c3babb3-b2fe-4649-91fe-906e54d2e724	Security Public Storage	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	155231192826342	2026-05-23 00:38:44.140044	2026-05-23 00:38:44.140044	Commercial	\N	\N	Consumer Services	2027-05-01	\N
e1d8f3c3-fe30-4cf0-b68d-56828b466154	Empire Truck Sales LLC	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	174252030974312	2026-05-23 00:38:44.144347	2026-05-23 00:38:44.144347	Commercial	\N	\N	Automotive	2029-02-20	\N
e07886d4-e161-4f8c-99f4-c3f906028f7b	Country Court Care	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	172970140679965	2026-05-23 00:38:44.148019	2026-05-23 00:38:44.148019	Commercial	\N	\N	Healthcare	2028-03-18	\N
45e6cffe-5382-45ee-ab17-26650a6b234f	Homeland	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	170673809253596	2026-05-23 00:38:44.151989	2026-05-23 00:38:44.151989	Commercial	\N	\N	Retail	2028-02-09	\N
1c3dd9b2-b399-40fa-b215-d6e8908b3588	Sun City Garage Doors	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	169273425809169	2026-05-23 00:38:44.155903	2026-05-23 00:38:44.155903	Commercial	\N	\N	Home Services	2026-11-14	\N
faf54bcf-f4ff-4acd-b1ea-574b26104748	Make Space Inc.	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	166906127524536	2026-05-23 00:38:44.15966	2026-05-23 00:38:44.15966	Commercial	\N	\N	Consumer Services	2026-06-14	\N
357e1185-3078-456e-adaf-d326c19107d1	Capstone Multi-Family Group LLC	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	165532528869244	2026-05-23 00:38:44.163852	2026-05-23 00:38:44.163852	Commercial	\N	\N	Real Estate	2026-12-30	\N
c44db1be-0ed2-47c5-b81b-ee700915cd5b	Perry Homes	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	157842600230692	2026-05-23 00:38:44.167759	2026-05-23 00:38:44.167759	Commercial	\N	\N	Construction	2026-12-29	\N
767052b7-f4bf-4885-a897-33b1b7d89a3a	StorSafe Self Storage	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	170127624269615	2026-05-23 00:38:44.172707	2026-05-23 00:38:44.172707	Commercial	\N	\N	Consumer Services	2026-12-08	\N
332b77c4-d84c-4ba9-813e-3112c552915c	Borland-Groover Clinic, P.A.	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	170483171477287	2026-05-23 00:38:44.176339	2026-05-23 00:38:44.176339	Commercial	\N	\N	Healthcare	2027-02-20	\N
bf933999-9beb-4c33-a0ae-7fd451d0edfe	StayAPT Suites Headquarters	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	167950847871772	2026-05-23 00:38:44.179967	2026-05-23 00:38:44.179967	Commercial	\N	\N	Hospitality	2026-06-05	\N
b0853d12-fd5d-4b58-aba6-776c7bbcd232	MC Fence And Deck	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	164752997053258	2026-05-23 00:38:44.183719	2026-05-23 00:38:44.183719	Commercial	\N	\N	Contractors	2027-03-17	\N
6d9c614e-d8b4-4061-83a5-7cce90cefd6b	LeaderOne Financial	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	red	f	\N	\N	156815025795851	2026-05-23 00:38:44.187401	2026-05-23 00:38:44.187401	Commercial	\N	\N	Finance	2027-02-28	\N
f11b567d-9bd3-4319-b409-b9a6f67d93f2	Agape Care Group	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	170483398752331	2026-05-23 00:38:44.19142	2026-05-23 00:38:44.19142	Commercial	\N	\N	Healthcare	2027-02-13	\N
25830389-ae99-4ed4-90a1-2d5d909a48e8	The Breeden Company	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	170732252784146	2026-05-23 00:38:44.195071	2026-05-23 00:38:44.195071	Commercial	\N	\N	Contractors	2027-12-05	\N
dab86e01-78bd-4f2d-a61a-88e31428b821	Family Flowers	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	169219847411383	2026-05-23 00:38:44.198916	2026-05-23 00:38:44.198916	Commercial	\N	\N	Retail	2028-05-21	\N
d292bf11-574a-4c41-be35-138c064f74a0	Mattress By Appointment LLC	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	172893791069602	2026-05-23 00:38:44.203354	2026-05-23 00:38:44.203354	Commercial	\N	\N	Retail	2027-10-30	\N
5a8b225a-5572-4b26-8c0c-5354cee480eb	United Vein and Vascular Centers	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	168789568495015	2026-05-23 00:38:44.20712	2026-05-23 00:38:44.20712	Commercial	\N	\N	Healthcare	2026-07-31	\N
a225a458-7ad2-4e9b-9ee4-aed440a3cdc3	DeCoach Rehabilitation Centre	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	165729347192049	2026-05-23 00:38:44.211138	2026-05-23 00:38:44.211138	Commercial	\N	\N	Wellness	2026-11-17	\N
3e3dc7ff-a4c9-4d52-9399-2e998cc70c46	Southern Surgical Arts	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	166767858970704	2026-05-23 00:38:44.214587	2026-05-23 00:38:44.214587	Commercial	\N	\N	Healthcare	2026-10-09	\N
42199b83-3beb-47ea-aea9-3b0638960168	Relax The Back	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	170491752167993	2026-05-23 00:38:44.218844	2026-05-23 00:38:44.218844	Commercial	\N	\N	Retail	2027-02-24	\N
ecb6a186-4796-4b6c-a722-f66461d158e7	Keith Zars Pools	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	red	f	\N	\N	169895702614586	2026-05-23 00:38:44.222715	2026-05-23 00:38:44.222715	Commercial	\N	\N	Contractors	2026-10-18	\N
6ac5f411-2a5e-4df5-8d70-d0fad101c6ea	Centria Healthcare	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	150669803025371	2026-05-23 00:38:44.226366	2026-05-23 00:38:44.226366	Commercial	\N	\N	Healthcare	2027-12-14	\N
165b881f-6547-48fe-aec8-b1d37b0d006a	Holt Homes	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	167744439226841	2026-05-23 00:38:44.22984	2026-05-23 00:38:44.22984	Commercial	\N	\N	Contractors	2028-05-22	\N
0558f5ba-2866-44ba-a405-882b3996d3d0	Pinnacle Storage	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	169765024975281	2026-05-23 00:38:44.233583	2026-05-23 00:38:44.233583	Commercial	\N	\N	Consumer Services	2027-01-01	\N
75416456-b97e-4211-805d-2f89d8232f1a	Planned Property Management Inc	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	red	f	\N	\N	159533799270004	2026-05-23 00:38:44.237453	2026-05-23 00:38:44.237453	Commercial	\N	\N	Real Estate	2027-02-28	\N
77421b3c-1cbf-4386-8b51-3d6a4b46ff69	Insperity	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	red	f	\N	\N	167605998677369	2026-05-23 00:38:44.241032	2026-05-23 00:38:44.241032	Commercial	\N	\N	Technology	2029-05-02	\N
acc500a2-3a12-4a9f-9bc3-994e34bcfa18	Model Group	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	166602182165664	2026-05-23 00:38:44.245246	2026-05-23 00:38:44.245246	Commercial	\N	\N	Contractors	2026-10-31	\N
785278ab-e764-4472-baaa-5031f0e0c562	Good Greek Moving & Storage	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	170794598772875	2026-05-23 00:38:44.248854	2026-05-23 00:38:44.248854	Commercial	\N	\N	Consumer Services	2028-02-26	\N
6f5ab9d1-ac72-48af-80a8-ee6ed8e18fc4	Chair King: BackYard Store	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	153816530164637	2026-05-23 00:38:44.252785	2026-05-23 00:38:44.252785	Commercial	\N	\N	Retail	2026-12-30	\N
41951153-4b79-457c-b34d-c40dcd4e6964	First Storage	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	172773121812735	2026-05-23 00:38:44.256737	2026-05-23 00:38:44.256737	Commercial	\N	\N	Home Services	2026-10-02	\N
9feacddc-fe03-4530-9562-971240f1f7c5	South Carolina Federal Credit Union	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	174777637552646	2026-05-23 00:38:44.260569	2026-05-23 00:38:44.260569	Commercial	\N	\N	Finance	2027-09-25	\N
6a06225a-a356-4bea-a895-77c3154799f3	BesaMe Wellness Dispensary - Kansas City	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	164150272603648	2026-05-23 00:38:44.264404	2026-05-23 00:38:44.264404	Commercial	\N	\N	Recreation	2027-03-26	\N
a1158d23-11f3-4840-984d-f9cbfbdf9ef5	RiteRug Flooring	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	150842488881106	2026-05-23 00:38:44.269225	2026-05-23 00:38:44.269225	Commercial	\N	\N	Consumer Goods	2026-10-21	\N
48f43d03-99ab-45f5-9a6f-afa708fc207f	Cambridge Management Services, Inc.	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	166146394614733	2026-05-23 00:38:44.27368	2026-05-23 00:38:44.27368	Commercial	\N	\N	Real Estate	2028-01-01	\N
a91db9de-5c27-4206-81ab-08299ee732c7	Copper Storage Management	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	168868258345353	2026-05-23 00:38:44.277633	2026-05-23 00:38:44.277633	Commercial	\N	\N	Consumer Services	2027-05-21	\N
ad840b7b-96ae-4dd0-bdf2-7e4da1b90544	Senior Resource Group	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	167968261798721	2026-05-23 00:38:44.282031	2026-05-23 00:38:44.282031	Commercial	\N	\N	Healthcare	2028-02-29	\N
f1bf519b-d90c-43a7-a0ac-5e21565ba431	Chuze Fitness	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	169824932412194	2026-05-23 00:38:44.285679	2026-05-23 00:38:44.285679	Commercial	\N	\N	Recreation	2027-04-30	\N
71eb424b-8960-4c8e-a71e-a9c8da8e4b2a	Melone Hatley, P.C. Divorce Law Office	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	167165488867987	2026-05-23 00:38:44.289608	2026-05-23 00:38:44.289608	Commercial	\N	\N	Legal	2026-12-29	\N
21811a3e-5b98-472e-b47d-88382e74c15a	Queen City Homestore	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	162237675486307	2026-05-23 00:38:44.29328	2026-05-23 00:38:44.29328	Commercial	\N	\N	Retail	2026-12-31	\N
39a18561-0411-4c03-9683-eae80c70b20d	Givens Communities	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	165229258907497	2026-05-23 00:38:44.296936	2026-05-23 00:38:44.296936	Commercial	\N	\N	Wellness	2026-05-23	\N
b6b28c88-1078-4ba3-8d1b-1b78491a6ec4	EMG Management	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	159888859258242	2026-05-23 00:38:44.30084	2026-05-23 00:38:44.30084	Commercial	\N	\N	Real Estate	2026-12-14	\N
197e2a1a-ddc5-4ee9-bf18-449baaff5df9	Shurgard Self Storage	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	yellow	f	\N	\N	173675736334356	2026-05-23 00:38:44.304566	2026-05-23 00:38:44.304566	Commercial	\N	\N	Consumer Services	2028-02-26	\N
7b2c4b10-cacd-4412-ae18-29b333179669	Cheyenne Regional Medical Center - West Campus	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	yellow	f	\N	\N	170440426330875	2026-05-23 00:38:44.308065	2026-05-23 00:38:44.308065	Commercial	\N	\N	Healthcare	2029-07-01	\N
20009b11-0056-4a47-987e-d7f204ca6b4d	Desert Radiology	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	158222436688123	2026-05-23 00:38:44.311902	2026-05-23 00:38:44.311902	Commercial	\N	\N	Healthcare	2028-03-30	\N
3642be34-6be7-4404-9d59-db121215cb7c	Pico Propane and Fuels	54ab8b97-6679-4284-ba1b-850ea562722a	\N	red	f	\N	\N	166760541899045	2026-05-23 00:38:44.315425	2026-05-23 00:38:44.315425	Commercial	\N	\N	Other	2028-04-14	\N
e27a0a99-c7f2-4f84-9117-7c4b2ba1c1c8	Minnesota Women's Care	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	164450755760594	2026-05-23 00:38:44.319398	2026-05-23 00:38:44.319398	Commercial	\N	\N	Healthcare	2026-09-09	\N
321ba967-5f72-4b34-98a2-c858df2d5391	ExperiGreen Lawn Care	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	174948245482667	2026-05-23 00:38:44.32329	2026-05-23 00:38:44.32329	Commercial	\N	\N	Home Services	2027-03-02	\N
eae07698-73f2-421f-a7a7-2355d4a1d378	Club Car Wash	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	green	f	\N	\N	172468985801928	2026-05-23 00:38:44.327301	2026-05-23 00:38:44.327301	Commercial	\N	\N	Automotive	2027-01-11	\N
41df5b8c-4805-40fe-9a3b-ee626f2bb12f	Earls Kitchen + Bar	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	175190444427072	2026-05-23 00:38:44.331036	2026-05-23 00:38:44.331036	Commercial	\N	\N	Restaurants	2027-02-27	\N
4ee95f4d-5938-446e-9d88-db5b39bdb0b7	The SEES Group	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	175502208917709	2026-05-23 00:38:44.335653	2026-05-23 00:38:44.335653	Commercial	\N	\N	Healthcare	2027-10-21	\N
8c375864-3914-4907-b6c8-c9cd57f2e55e	Public Storage Canada	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	168366089519887	2026-05-23 00:38:44.339854	2026-05-23 00:38:44.339854	Commercial	\N	\N	Consumer Services	2027-03-05	\N
ad75abf3-3c59-4560-ba2d-a999515b3928	INDOCHINO	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	160859301604289	2026-05-23 00:38:44.343682	2026-05-23 00:38:44.343682	Commercial	\N	\N	Retail	2026-12-14	\N
fc7d21b8-ed4a-4b40-87a6-3a44595fda96	Solis Mammography	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	green	f	\N	\N	161849484346451	2026-05-23 00:38:44.347744	2026-05-23 00:38:44.347744	Commercial	\N	\N	Healthcare	2027-01-22	\N
78e623b6-10d9-4e51-b841-81f15ee37dd8	Aspen Skilled Healthcare	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	155801620933563	2026-05-23 00:38:44.351518	2026-05-23 00:38:44.351518	Commercial	\N	\N	Wellness	2026-11-06	\N
0a2989cf-73f9-4d83-80ec-755a0f17a81f	Johnson Fitness & Wellness	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	165288602788863	2026-05-23 00:38:44.355496	2026-05-23 00:38:44.355496	Commercial	\N	\N	Consumer Goods	2027-01-26	\N
64400def-4350-4ea3-b92f-ae7c77015ae1	Anthony's Restaurants	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	165090595375319	2026-05-23 00:38:44.359601	2026-05-23 00:38:44.359601	Commercial	\N	\N	Restaurants	2026-12-28	\N
a8933ecf-3031-4379-bb82-a7a1e0a27015	SmartStop Self Storage	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	165835087930998	2026-05-23 00:38:44.363577	2026-05-23 00:38:44.363577	Commercial	\N	\N	Consumer Services	2027-01-31	\N
07750a5d-6b14-4530-b29e-618ad4bd24d5	Dick Hannah Dealerships	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	green	f	\N	\N	176497193477862	2026-05-23 00:38:44.367309	2026-05-23 00:38:44.367309	Commercial	\N	\N	Automotive	2028-04-12	\N
049dd276-c34e-4833-a15e-27b55ff618b0	The Flower Bucket	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	167330404161581	2026-05-23 00:38:44.371654	2026-05-23 00:38:44.371654	Commercial	\N	\N	Consumer Services	2026-07-31	\N
245b008a-3eca-4a00-8e2a-d3fb5edf6af8	SKS Management	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	red	f	\N	\N	170585759448117	2026-05-23 00:38:44.375546	2026-05-23 00:38:44.375546	Commercial	\N	\N	Real Estate	2028-04-24	\N
28fc803c-dd0a-49ce-97ae-33fad4ba30e3	Next Health	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	166790963100976	2026-05-23 00:38:44.379754	2026-05-23 00:38:44.379754	Commercial	\N	\N	Wellness	2027-01-05	\N
c7327b55-383e-4c1a-8431-4476bd347ee2	1st Lake Properties	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	147250419626131	2026-05-23 00:38:44.383591	2026-05-23 00:38:44.383591	Commercial	\N	\N	Real Estate	2026-09-20	\N
9ae1d283-7485-4b5e-bbbb-cdbc3cd6128f	Davlyn Investments	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	154724066435964	2026-05-23 00:38:44.387242	2026-05-23 00:38:44.387242	Commercial	\N	\N	Real Estate	2026-06-14	\N
1cfa8044-cfa1-4d82-a187-2c960c4afa2e	Austin Health Partners	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	150289559105554	2026-05-23 00:38:44.390967	2026-05-23 00:38:44.390967	Commercial	\N	\N	Healthcare	2026-09-29	\N
e0859c63-cc3c-4a11-953a-fb500fddb720	Wolfe Eye Clinic	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	152779012609747	2026-05-23 00:38:44.394694	2026-05-23 00:38:44.394694	Commercial	\N	\N	Wellness	2026-10-26	\N
bcb10937-8cb9-4cf0-b26e-2e67ce9cceac	Collision Pros	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	green	f	\N	\N	166812168428246	2026-05-23 00:38:44.398407	2026-05-23 00:38:44.398407	Commercial	\N	\N	Automotive	2026-11-14	\N
07ac9483-826e-42f7-bc08-7248a4027454	Beacon Behavioral Health Partners	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	175148214899501	2026-05-23 00:38:44.402832	2026-05-23 00:38:44.402832	Commercial	\N	\N	Healthcare	2027-07-31	\N
211d8ea4-2e5e-4625-8ee4-4a9bf2e4524a	Waco Family Medicine	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	175580292281712	2026-05-23 00:38:44.40637	2026-05-23 00:38:44.40637	Commercial	\N	\N	Healthcare	2026-10-24	\N
66b35bf6-b2d7-471a-8684-3fc3b5b378e9	Front Porch Communities & Services	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	red	f	\N	\N	170984287487327	2026-05-23 00:38:44.409922	2026-05-23 00:38:44.409922	Commercial	\N	\N	Healthcare	2028-01-09	\N
5dfdb4f9-c2fb-4d22-a30d-70f7c11eae99	Bethesda Senior	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	161096934969269	2026-05-23 00:38:44.413711	2026-05-23 00:38:44.413711	Commercial	\N	\N	Wellness	2026-10-13	\N
e15c87a3-7972-4dae-a787-2e81d9886d04	Attic Storage	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	green	f	\N	\N	176785405123475	2026-05-23 00:38:44.41717	2026-05-23 00:38:44.41717	Commercial	\N	\N	Consumer Services	2027-02-27	\N
b5614f0a-dbf6-46e7-8e9a-72f2520ca4b2	Inglewood Park Cemetery	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	yellow	f	\N	\N	170491632288823	2026-05-23 00:38:44.420517	2026-05-23 00:38:44.420517	Commercial	\N	\N	Consumer Services	2027-01-29	\N
0f44d633-add4-4fd6-870c-894ecf167e41	Sharpline Communities	0ebe8813-36fc-4628-b799-1a98e73daa82	\N	red	f	\N	\N	172607987323084	2026-05-23 00:38:44.424021	2026-05-23 00:38:44.424021	Commercial	\N	\N	Real Estate	2026-09-25	\N
6323343d-0f28-422b-9727-c1d978f50311	Hudson's Furniture + Mattress	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	167241855659787	2026-05-23 00:38:44.427761	2026-05-23 00:38:44.427761	Commercial	\N	\N	Retail	2026-07-01	\N
2a6020d3-8368-42bb-bdc3-69c6747ea79e	Florida Eye Specialists	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	166621249471585	2026-05-23 00:38:44.431773	2026-05-23 00:38:44.431773	Commercial	\N	\N	Healthcare	2026-12-27	\N
38c4afc7-a5be-431a-bf62-a186f2c7bf22	Froedtert Kenosha Hospital	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	165652162625140	2026-05-23 00:38:44.436333	2026-05-23 00:38:44.436333	Commercial	\N	\N	Healthcare	2029-04-27	\N
40971e4a-fbc2-45af-8e0b-aa943cac7103	KIDZ Medical Services	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	155199667142797	2026-05-23 00:38:44.440138	2026-05-23 00:38:44.440138	Commercial	\N	\N	Healthcare	2027-08-30	\N
f7ca76e3-4ea4-42de-a1e3-f8b8c9ce52b3	Centers Health Care	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	168055219563437	2026-05-23 00:38:44.443783	2026-05-23 00:38:44.443783	Commercial	\N	\N	Healthcare	2026-09-10	\N
3eb86393-2a35-449d-9caf-204006466828	The Hamilton Company	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	157593681656128	2026-05-23 00:38:44.448262	2026-05-23 00:38:44.448262	Commercial	\N	\N	Real Estate	2026-07-29	\N
b158fbd7-2245-48e8-a3a5-f31bdfe6f884	Seacoast Bank	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	169108658179338	2026-05-23 00:38:44.453462	2026-05-23 00:38:44.453462	Commercial	\N	\N	Finance	2028-12-30	\N
dfb94b01-af77-4006-8fb9-e5a67ab6f574	Unlimited Service Group	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	168426309454283	2026-05-23 00:38:44.45785	2026-05-23 00:38:44.45785	Commercial	\N	\N	Business Services	2026-07-18	\N
50c2fa77-ce4f-4876-bad7-fe0e4a777d4f	Flex	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	169152435605348	2026-05-23 00:38:44.462468	2026-05-23 00:38:44.462468	Commercial	\N	\N	Consumer Services	2026-06-16	\N
b1acd3f7-86f4-4fa5-a9fc-1f0f6d9df5c0	RadiFi Credit Union	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	163008114768095	2026-05-23 00:38:44.466323	2026-05-23 00:38:44.466323	Commercial	\N	\N	Finance	2026-12-09	\N
32c8865f-6abb-4343-bab4-f8de87afd007	Our Best Life-Whitelabel	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	166309120802715	2026-05-23 00:38:44.470058	2026-05-23 00:38:44.470058	Commercial	\N	\N	Other	2026-08-31	\N
ca635e80-8e21-47b2-9b36-d4458457e0d0	JRK Property Holdings	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	149132411068129	2026-05-23 00:38:44.473643	2026-05-23 00:38:44.473643	Commercial	\N	\N	Finance	2027-06-03	\N
9582b990-2b41-482f-92bd-4d990ba1a78b	Medieval Times Dinner & Tournament	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	144347224184650	2026-05-23 00:38:44.477511	2026-05-23 00:38:44.477511	Commercial	\N	\N	Restaurants	2026-05-30	\N
94230f5c-2cbc-4b9b-955f-18ccea989918	Senior Services of America	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	160761578882360	2026-05-23 00:38:44.481205	2026-05-23 00:38:44.481205	Commercial	\N	\N	Wellness	2038-03-14	\N
f29608ca-f13c-46ad-9c16-4c239942c785	Skyline Living	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	163415188174567	2026-05-23 00:38:44.485608	2026-05-23 00:38:44.485608	Commercial	\N	\N	Real Estate	2026-06-27	\N
ec4cfbe9-a0f5-4c52-a402-123cf7981f03	TOCA Football	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	166333510861116	2026-05-23 00:38:44.489421	2026-05-23 00:38:44.489421	Commercial	\N	\N	Recreation	2026-10-30	\N
b28e7450-39c3-4b33-8fdb-0d0a14e4afbf	Best Mattress	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	154100518861066	2026-05-23 00:38:44.493321	2026-05-23 00:38:44.493321	Commercial	\N	\N	Consumer Goods	2027-04-30	\N
915181e0-48e5-4ec4-bbcd-82dfa877fc9c	Eagle Rock Management	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	161978921783111	2026-05-23 00:38:44.497195	2026-05-23 00:38:44.497195	Commercial	\N	\N	Real Estate	2026-11-18	\N
35dc5698-47d6-4502-a32d-aa67642a042e	Integrated Oncology Network	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	166904366653176	2026-05-23 00:38:44.501067	2026-05-23 00:38:44.501067	Commercial	\N	\N	Healthcare	2027-03-15	\N
c51cc8e2-3e43-4fa8-a93c-6a479f24ee05	First Choice Neurology	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	161989021080217	2026-05-23 00:38:44.504896	2026-05-23 00:38:44.504896	Commercial	\N	\N	Healthcare	2026-06-29	\N
672df841-96a9-46e5-9da4-270959e8a98d	Medi-Weightloss Corporate Office	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	169176714784436	2026-05-23 00:38:44.50838	2026-05-23 00:38:44.50838	Commercial	\N	\N	Healthcare	2026-08-28	\N
10df94b3-d537-4c10-8054-72b6bd3bb720	The Paley Orthopedic & Spine Institute	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	158998903177148	2026-05-23 00:38:44.512032	2026-05-23 00:38:44.512032	Commercial	\N	\N	Healthcare	2026-06-18	\N
b692d961-711e-44df-a477-c1386022abd3	Joey Restaurants	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	156596456369435	2026-05-23 00:38:44.515434	2026-05-23 00:38:44.515434	Commercial	\N	\N	Restaurants	2027-02-28	\N
f578f649-adff-46bf-89b7-b0dc4c8825cb	Smart Pool Services Ltd	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	166301433765446	2026-05-23 00:38:44.519068	2026-05-23 00:38:44.519068	Commercial	\N	\N	Home Services	2027-12-30	\N
21c66f2a-824f-4f6c-8118-f4e470279d33	The Mortgage Firm, Inc.	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	175950204201051	2026-05-23 00:38:44.524152	2026-05-23 00:38:44.524152	Commercial	\N	\N	Finance	2028-01-30	\N
9134c920-e202-4df3-bc98-d33600020739	Texas Wood Supply	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	163191194296641	2026-05-23 00:38:44.529583	2026-05-23 00:38:44.529583	Commercial	\N	\N	Retail	2026-10-14	\N
7e48ad32-0c3a-437e-b787-582790fe9b1c	Lume Cannabis Co.	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	167087381623392	2026-05-23 00:38:44.533228	2026-05-23 00:38:44.533228	Commercial	\N	\N	Wellness	2027-12-30	\N
a724fea9-e0a0-4af2-b270-021d7e5b2a8e	Three Oaks Hospice, Inc.	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	160035645683703	2026-05-23 00:38:44.537775	2026-05-23 00:38:44.537775	Commercial	\N	\N	Healthcare	2027-11-22	\N
a495f657-e4ec-49f4-96b5-4c6d87246bf2	O'Connor & Associates	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	163415506434342	2026-05-23 00:38:44.541297	2026-05-23 00:38:44.541297	Commercial	\N	\N	Finance	2026-10-28	\N
018aee61-70dc-4af6-97f3-db8f08396e0e	Al Angelo Company	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	172729924026712	2026-05-23 00:38:44.5451	2026-05-23 00:38:44.5451	Commercial	\N	\N	Real Estate	2026-06-01	\N
682d4157-d718-446e-82e7-8ea3517908be	Cascade Rental Management Co	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	161462609497775	2026-05-23 00:38:44.549086	2026-05-23 00:38:44.549086	Commercial	\N	\N	Real Estate	2026-09-23	\N
8af6015f-d5f2-475e-aaf9-83d862501eeb	Holcim UK	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	1758175892615953	2026-05-23 00:38:44.55348	2026-05-23 00:38:44.55348	Commercial	\N	\N	Home Services	2027-11-04	\N
ba76bdee-8468-4557-896d-b2758780ebe8	Jiffy Lube	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	167329179980695	2026-05-23 00:38:44.558317	2026-05-23 00:38:44.558317	Commercial	\N	\N	Automotive	2028-05-02	\N
264e1e3d-696a-4234-9809-e5ba35907ad6	CADY	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	159172158282692	2026-05-23 00:38:44.562376	2026-05-23 00:38:44.562376	Commercial	\N	\N	Arts & Entertainment	2027-06-28	\N
b8a0119b-7ecd-4ed6-b40e-9e164135e9ac	Tru Fit Athletic Clubs	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	158283878199097	2026-05-23 00:38:44.566495	2026-05-23 00:38:44.566495	Commercial	\N	\N	Wellness	2027-02-27	\N
e96ae55b-a7ab-4190-93cd-c4a28019a079	South Bay Med Spa	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	159242273020885	2026-05-23 00:38:44.570008	2026-05-23 00:38:44.570008	Commercial	\N	\N	Other	2027-05-19	\N
897d5149-0530-426e-8605-58fe8782888a	End Of The Roll Flooring Centres	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	168745530844060	2026-05-23 00:38:44.573791	2026-05-23 00:38:44.573791	Commercial	\N	\N	Home Services	2026-06-29	\N
97f93f1d-5707-488e-85fc-e10931f47f5a	Kustom Disaster Restoration	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	165462492272571	2026-05-23 00:38:44.577868	2026-05-23 00:38:44.577868	Commercial	\N	\N	Contractors	2026-06-28	\N
3cbbe2fe-50f3-44cf-99fa-84ec808d5ec0	The Shortis Group	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	175501632003011	2026-05-23 00:38:44.581477	2026-05-23 00:38:44.581477	Commercial	\N	\N	Automotive	2027-10-29	\N
60bd2b51-d5c8-474e-8eaf-4cd7c7709c8e	Levco Management	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	164130599799645	2026-05-23 00:38:44.585314	2026-05-23 00:38:44.585314	Commercial	\N	\N	Real Estate	2027-01-25	\N
58a325a3-2ffa-4dd6-8557-3dfcd68f21ad	FirstKey Homes	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	151622651538133	2026-05-23 00:38:44.589205	2026-05-23 00:38:44.589205	Commercial	\N	\N	Real Estate	2026-07-06	\N
fab4ff76-91b4-406e-bcf0-d0d6972d27aa	Empower Aesthetics	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	170300063072012	2026-05-23 00:38:44.593472	2026-05-23 00:38:44.593472	Commercial	\N	\N	Wellness	2026-12-21	\N
625f0678-3697-4522-a064-bb2775a453e1	Edfed - The Educational Federal Credit Union	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	166785050846779	2026-05-23 00:38:44.597823	2026-05-23 00:38:44.597823	Commercial	\N	\N	Finance	2028-12-30	\N
876717c7-4dce-4984-b706-40809158dd32	Best-One Of Indy	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	162609931857747	2026-05-23 00:38:44.601795	2026-05-23 00:38:44.601795	Commercial	\N	\N	Automotive	2027-05-01	\N
de99e780-c248-42b8-82e6-161c9a8562b9	V.I.P. Mortgage, Inc.	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	169713655779994	2026-05-23 00:38:44.605423	2026-05-23 00:38:44.605423	Commercial	\N	\N	Finance	2027-01-31	\N
570dc4fd-5225-4574-b1e7-e9bd93e18df5	Smarter Home AI	3ed58702-5fcb-4742-a9f2-842a09991732	\N	green	f	\N	\N	175986391702504	2026-05-23 00:38:44.608809	2026-05-23 00:38:44.608809	Commercial	\N	\N	Home Services	2026-11-27	\N
7816b4b4-3a3f-4f6c-8d99-f7e9dcfa9b04	Pet Paradise	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	165418309797166	2026-05-23 00:38:44.612391	2026-05-23 00:38:44.612391	Commercial	\N	\N	Healthcare	2027-04-29	\N
6f8efd5a-5be7-4c12-9d6b-9f1ceefaa50f	K1 Speed, Inc.	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	161902840699780	2026-05-23 00:38:44.615932	2026-05-23 00:38:44.615932	Commercial	\N	\N	Arts & Entertainment	2027-12-30	\N
9aa7c09d-a741-4f83-b1fe-c6b020de1883	Afton Properties	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	171106257789659	2026-05-23 00:38:44.619963	2026-05-23 00:38:44.619963	Commercial	\N	\N	Real Estate	2027-02-19	\N
4f012fbe-f29b-4bc3-970d-7ffcac056e12	The Hydration Room	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	161885800961529	2026-05-23 00:38:44.624361	2026-05-23 00:38:44.624361	Commercial	\N	\N	Consumer Services	2026-09-15	\N
cf53d6e2-6b41-4bfe-b0b3-97aa1c4ca7d6	Mendocino Farms	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	166793596755349	2026-05-23 00:38:44.62807	2026-05-23 00:38:44.62807	Commercial	\N	\N	Restaurants	2026-12-30	\N
383cb7c4-3cb4-4133-a299-2b15f8ad7602	CFSC	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	169904267246831	2026-05-23 00:38:44.632436	2026-05-23 00:38:44.632436	Commercial	\N	\N	Finance	2026-08-22	\N
732a0e01-27fc-4e61-94e5-12e3d5b2ec1d	Right Now Heating, Air Conditioning & Plumbing	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	170327103509327	2026-05-23 00:38:44.6362	2026-05-23 00:38:44.6362	Commercial	\N	\N	Contractors	2027-01-22	\N
91d2db85-f02c-4060-9122-1f543d6ad420	US Storage Centers	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	165064612273103	2026-05-23 00:38:44.63979	2026-05-23 00:38:44.63979	Commercial	\N	\N	Consumer Services	2026-12-01	\N
7ac72d80-5eda-43c1-b55b-dd1bb6bbb8f3	Leonard LLC	3ed58702-5fcb-4742-a9f2-842a09991732	\N	red	f	\N	\N	168373438957512	2026-05-23 00:38:44.643402	2026-05-23 00:38:44.643402	Commercial	\N	\N	Automotive	2026-08-30	\N
c2d191e1-2bce-4e56-8519-09d7fe0a0cd6	O'Brien Auto Group	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	147687255887163	2026-05-23 00:38:44.646956	2026-05-23 00:38:44.646956	Commercial	\N	\N	Automotive	2026-11-04	\N
b60757b9-216a-43d4-805d-a51e53cb1337	Schumacher Automotive	3ed58702-5fcb-4742-a9f2-842a09991732	\N	red	f	\N	\N	160131437681651	2026-05-23 00:38:44.651292	2026-05-23 00:38:44.651292	Commercial	\N	\N	Automotive	2026-10-15	\N
885d2c5d-5577-4744-8595-03bae5711ce5	Endeavour Automotive Limited	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	172925843633878	2026-05-23 00:38:44.655331	2026-05-23 00:38:44.655331	Commercial	\N	\N	Automotive	2027-12-05	\N
975af035-ddfd-4c70-a229-948df5a435bd	Simplicity Car Care	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	171460078616145	2026-05-23 00:38:44.659285	2026-05-23 00:38:44.659285	Commercial	\N	\N	Automotive	2027-04-02	\N
2b0a2def-3caa-40c0-bea5-66aa69037a52	Hero Practice Services	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	155863405360881	2026-05-23 00:38:44.663057	2026-05-23 00:38:44.663057	Commercial	\N	\N	Dental	2026-06-26	\N
e993b4bc-8bac-4017-b9d5-1c1e9a059cfc	Davis Development	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	174239592243494	2026-05-23 00:38:44.66666	2026-05-23 00:38:44.66666	Commercial	\N	\N	Real Estate	2027-04-29	\N
c368fb0f-eebc-46d3-ab79-0cd85037c229	Shoe Sensation	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	174907065944561	2026-05-23 00:38:44.670928	2026-05-23 00:38:44.670928	Commercial	\N	\N	Retail	2026-09-01	\N
713f0dd3-35d9-4336-9e29-1482d09b545b	JumpstartMD	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	159476737495202	2026-05-23 00:38:44.675205	2026-05-23 00:38:44.675205	Commercial	\N	\N	Healthcare	2026-11-26	\N
9c859df5-a77e-4071-a0c9-e1a9d6a84899	Energy Distribution Partners	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	168383611379282	2026-05-23 00:38:44.679651	2026-05-23 00:38:44.679651	Commercial	\N	\N	Home Services	2026-06-30	\N
6986a399-8be1-4722-af9e-3a7098874e0d	Spooner Physical Therapy	3ed58702-5fcb-4742-a9f2-842a09991732	\N	red	f	\N	\N	167172322647536	2026-05-23 00:38:44.684078	2026-05-23 00:38:44.684078	Commercial	\N	\N	Other	2026-11-27	\N
debeee52-4d54-48c3-be21-5ec853cc4af3	OVME	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	163887940216582	2026-05-23 00:38:44.687858	2026-05-23 00:38:44.687858	Commercial	\N	\N	Wellness	2026-08-13	\N
1c641c61-4526-494a-9479-9f5b45e4368d	Clancy's Inc.	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	159975051829045	2026-05-23 00:38:44.691962	2026-05-23 00:38:44.691962	Commercial	\N	\N	Business Services	2027-12-30	\N
373c32a2-daaa-41a6-b43b-055897fee096	Group Five Management Company	3ed58702-5fcb-4742-a9f2-842a09991732	\N	red	f	\N	\N	172904751753366	2026-05-23 00:38:44.696103	2026-05-23 00:38:44.696103	Commercial	\N	\N	Real Estate	2026-06-01	\N
f7731c43-1819-4e45-b5b4-223ae479aa1b	Johnson RV	3ed58702-5fcb-4742-a9f2-842a09991732	\N	red	f	\N	\N	164020107201278	2026-05-23 00:38:44.699951	2026-05-23 00:38:44.699951	Commercial	\N	\N	Automotive	2028-01-28	\N
809d6dd6-27f5-4e54-818e-ad6530c7a2d3	Legacy Communities	3ed58702-5fcb-4742-a9f2-842a09991732	\N	red	f	\N	\N	173765789947419	2026-05-23 00:38:44.703948	2026-05-23 00:38:44.703948	Commercial	\N	\N	Real Estate	2027-02-18	\N
cab61f4c-3927-490a-813d-06513cfa30fa	Oral Surgery Partners	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	172909402088919	2026-05-23 00:38:44.707748	2026-05-23 00:38:44.707748	Commercial	\N	\N	Healthcare	2026-06-12	\N
6ea0f516-f953-4125-b28a-7d53e66e7548	SMIL Southwest Medical Imaging	3ed58702-5fcb-4742-a9f2-842a09991732	\N	red	f	\N	\N	156277315272476	2026-05-23 00:38:44.71133	2026-05-23 00:38:44.71133	Commercial	\N	\N	Healthcare	2026-12-18	\N
5abd10c6-640a-4b68-aad9-cd69fbc545dc	Illinois Retina Associates, S.C.	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	151614462001130	2026-05-23 00:38:44.714672	2026-05-23 00:38:44.714672	Commercial	\N	\N	Healthcare	2027-05-31	\N
9e7e791f-44f3-4b6d-b2e1-b72d6fda249d	1 Stop Motor Vehicle Services	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	168555943360689	2026-05-23 00:38:44.718509	2026-05-23 00:38:44.718509	Commercial	\N	\N	Government	2026-07-29	\N
f8338355-0939-4dcf-b29a-494333a38e74	Avis Car Sales	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	173747238759150	2026-05-23 00:38:44.722307	2026-05-23 00:38:44.722307	Commercial	\N	\N	Automotive	2027-03-31	\N
93731ecd-676b-4e3c-9fcb-d200ed102385	AleraCare Intermediate, LLC	3ed58702-5fcb-4742-a9f2-842a09991732	\N	red	f	\N	\N	171165319631881	2026-05-23 00:38:44.725871	2026-05-23 00:38:44.725871	Commercial	\N	\N	Healthcare	2027-03-24	\N
f92ed14d-3830-4e0a-9077-70d07c0c4efe	G & C Auto Body	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	155017658837971	2026-05-23 00:38:44.729408	2026-05-23 00:38:44.729408	Commercial	\N	\N	Automotive	2027-06-23	\N
647d4667-5a9f-4bfd-91a5-bfc17444c844	Cubix Storage	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	171933108364070	2026-05-23 00:38:44.732849	2026-05-23 00:38:44.732849	Commercial	\N	\N	Consumer Services	2026-09-26	\N
6353608d-4493-4e2b-a00e-9e02c6f9573f	Retina Group Of Florida	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	161862337084235	2026-05-23 00:38:44.736291	2026-05-23 00:38:44.736291	Commercial	\N	\N	Healthcare	2026-08-31	\N
ff17e3b2-d3e3-451b-baa8-b5cd05225b46	3Rivers Federal Credit Union	3ed58702-5fcb-4742-a9f2-842a09991732	\N	red	f	\N	\N	169904268072666	2026-05-23 00:38:44.740041	2026-05-23 00:38:44.740041	Commercial	\N	\N	Finance	2028-04-29	\N
d1449806-6194-430e-bf87-a753a0175f94	SWAT Environmental	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	171743696844377	2026-05-23 00:38:44.743897	2026-05-23 00:38:44.743897	Commercial	\N	\N	Contractors	2026-10-02	\N
3fed19d9-60bb-4a8d-80a2-a9e4c66af10a	LifeLong Medical Care	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	170673777474889	2026-05-23 00:38:44.747621	2026-05-23 00:38:44.747621	Commercial	\N	\N	Healthcare	2026-06-30	\N
3a788fc5-371e-45ee-b4e3-10f4225c7247	Pave America	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	171389936857629	2026-05-23 00:38:44.751677	2026-05-23 00:38:44.751677	Commercial	\N	\N	Contractors	2027-06-29	\N
5ec69931-452f-4f6c-94e9-8a26cae838e4	Dark Horse CPAs	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	169349976799351	2026-05-23 00:38:44.755909	2026-05-23 00:38:44.755909	Commercial	\N	\N	Finance	2027-09-29	\N
e48bd89b-5124-410d-b562-755aea2985ce	Vivant Behavioral Healthcare	3ed58702-5fcb-4742-a9f2-842a09991732	\N	red	f	\N	\N	171321178325918	2026-05-23 00:38:44.760644	2026-05-23 00:38:44.760644	Commercial	\N	\N	Healthcare	2027-04-29	\N
e7d94755-3198-485a-a459-d9c8fdf5e39a	WAG Hotels	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	149183745205520	2026-05-23 00:38:44.764663	2026-05-23 00:38:44.764663	Commercial	\N	\N	Consumer Services	2026-10-21	\N
9b76c22d-8f93-42a0-a800-823b9e878029	Eustis Mortgage	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	173342871109634	2026-05-23 00:38:44.768392	2026-05-23 00:38:44.768392	Commercial	\N	\N	Finance	2026-12-30	\N
c80cd4ea-f7c6-404c-899f-63753baf4f56	The Village Health Clubs & Spas	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	161456747808080	2026-05-23 00:38:44.771981	2026-05-23 00:38:44.771981	Commercial	\N	\N	Wellness	2026-08-17	\N
742fe9f8-c3b1-4462-9440-ca5957aa350e	Milestone Education	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	172245324685714	2026-05-23 00:38:44.775656	2026-05-23 00:38:44.775656	Commercial	\N	\N	Education	2026-08-27	\N
1a3d3fa4-3181-4adb-bdef-8c8b56adb75d	Sierra Health Care, Inc.	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	166032569405747	2026-05-23 00:38:44.779643	2026-05-23 00:38:44.779643	Commercial	\N	\N	Healthcare	2026-11-01	\N
2ac296ad-8b8a-4aaf-9e06-fa081b87e122	Cairn Communities	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	174672716337724	2026-05-23 00:38:44.783543	2026-05-23 00:38:44.783543	Commercial	\N	\N	Real Estate	2026-09-08	\N
36d4a6d6-fe8a-43ad-80e9-e284b9727b1c	Family Care Center	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	151129616632128	2026-05-23 00:38:44.787542	2026-05-23 00:38:44.787542	Commercial	\N	\N	Healthcare	2027-04-30	\N
c129190c-f77b-41a1-9ef1-28d25ffca11e	DaBella	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	170299998055889	2026-05-23 00:38:44.792064	2026-05-23 00:38:44.792064	Commercial	\N	\N	Contractors	2027-03-30	\N
467de87b-1bb8-42fb-b991-d423b3f42910	West Coast Self-Storage	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	168020033646255	2026-05-23 00:38:44.795867	2026-05-23 00:38:44.795867	Commercial	\N	\N	Transportation Services	2027-05-31	\N
24e73106-303e-44d3-b61d-3962432b239b	Fischer Homes	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	170317308906703	2026-05-23 00:38:44.799646	2026-05-23 00:38:44.799646	Commercial	\N	\N	Real Estate	2028-02-29	\N
a54d832c-e2ea-4c71-9bd0-d2a503f609b3	KO Storage Headquarters	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	157609420002316	2026-05-23 00:38:44.803248	2026-05-23 00:38:44.803248	Commercial	\N	\N	Real Estate	2026-07-31	\N
fbea96da-a534-4688-a68e-1922e61ecc88	PCRK Group	13c3af04-c401-4c4b-b371-12cb014178e1	\N	green	f	\N	\N	168556976506014	2026-05-23 00:38:44.807317	2026-05-23 00:38:44.807317	Commercial	\N	\N	Wellness	2027-09-18	\N
4349a5ac-cf46-4dcd-8848-46c46260b4ed	Jones Lang Lasalle Incorporated	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	169281678661579	2026-05-23 00:38:44.811127	2026-05-23 00:38:44.811127	Commercial	\N	\N	Real Estate	2026-10-31	\N
db32014c-0daf-4a08-bd86-00a370a5d92b	TEKsystems Corporate	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	170622561162378	2026-05-23 00:38:44.815007	2026-05-23 00:38:44.815007	Commercial	\N	\N	Technology	2028-03-15	\N
10193732-f69b-4e38-82d0-e8a0f612bb16	Churchill Downs Inc	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	166992806809415	2026-05-23 00:38:44.819146	2026-05-23 00:38:44.819146	Commercial	\N	\N	Recreation	2026-07-23	\N
4494a852-015d-4429-ae8e-a231f4486527	Good Shepherd Rehabilitation	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	154877424109448	2026-05-23 00:38:44.823067	2026-05-23 00:38:44.823067	Commercial	\N	\N	Healthcare	2026-08-25	\N
dafd18e0-65f7-477c-8f6a-976c3bfecddc	Madison Reed Inc	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	169904041990957	2026-05-23 00:38:44.827004	2026-05-23 00:38:44.827004	Commercial	\N	\N	Other	2027-05-01	\N
d71d3c1e-0e24-4309-a8f7-ff9e45bfc333	Endodontic Practice Partners	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	165582616151295	2026-05-23 00:38:44.831156	2026-05-23 00:38:44.831156	Commercial	\N	\N	Dental	2026-11-30	\N
68c3e0e4-e304-4177-8afe-3169f28dca3e	Colorado Center for Reproductive Medicine	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	170483174470379	2026-05-23 00:38:44.83818	2026-05-23 00:38:44.83818	Commercial	\N	\N	Healthcare	2027-06-13	\N
9808c1b7-6c8a-4d40-b005-acc62097dfeb	InnovAge Headquarters	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	167450473332050	2026-05-23 00:38:44.841895	2026-05-23 00:38:44.841895	Commercial	\N	\N	Healthcare	2026-04-02	\N
c185aa87-1c55-4917-ace7-45393ef9d7af	Investment Property Group (IPG)	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	158463839315919	2026-05-23 00:38:44.845485	2026-05-23 00:38:44.845485	Commercial	\N	\N	Real Estate	2026-12-09	\N
c2e20a06-ed73-4eb4-b7e7-7355ade03504	Alliance Orthopedics	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	169885474671300	2026-05-23 00:38:44.849067	2026-05-23 00:38:44.849067	Commercial	\N	\N	Healthcare	2026-12-13	\N
3683bf5b-6a76-42ad-9368-ef2f487c4fb0	Softroc	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	176245428442605	2026-05-23 00:38:45.010615	2026-05-23 00:38:45.010615	Commercial	\N	\N	Home Services	2028-01-19	\N
25916958-2898-4e30-bf1b-820fee94be6f	Clinicas del Camino Real, Inc.	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	163848369058148	2026-05-23 00:38:44.852353	2026-05-23 00:38:44.852353	Commercial	\N	\N	Healthcare	2026-06-03	\N
98e7387d-04a3-4e94-aea3-3734777dc89a	RED RHINO, The Pool Leak Experts	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	155361851105718	2026-05-23 00:38:44.855724	2026-05-23 00:38:44.855724	Commercial	\N	\N	Home Services	2027-03-29	\N
31502344-9c56-4718-beba-432ae63fb0a8	The SEER Group	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	169902271714931	2026-05-23 00:38:44.859131	2026-05-23 00:38:44.859131	Commercial	\N	\N	Home Services	2027-08-29	\N
6f132bbc-d88a-497c-80d6-5a5761c8a2ec	United Water Restoration Group	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	165817060410677	2026-05-23 00:38:44.863405	2026-05-23 00:38:44.863405	Commercial	\N	\N	Home Services	2027-12-27	\N
4defc0f3-3422-46bc-bb0c-714349bf5ce8	Woodward Properties	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	167389176227209	2026-05-23 00:38:44.867049	2026-05-23 00:38:44.867049	Commercial	\N	\N	Real Estate	2027-01-31	\N
7c271a15-c9cf-48d1-b326-a3d3ee29b2fc	A First Name Basis	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	166421157755430	2026-05-23 00:38:44.870944	2026-05-23 00:38:44.870944	Commercial	\N	\N	Home Services	2026-11-10	\N
8fb93e4b-d354-441b-bdab-d9d48032be97	Spitz Restaurants	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	175370795126696	2026-05-23 00:38:44.874722	2026-05-23 00:38:44.874722	Commercial	\N	\N	Restaurants	2027-08-18	\N
8f455129-72a5-495e-95c7-ad40e4ac85b9	Partners In Building Lp	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	170371264715357	2026-05-23 00:38:44.879397	2026-05-23 00:38:44.879397	Commercial	\N	\N	Contractors	2026-12-29	\N
d05e64fb-4723-4d8e-934d-4b590b07eba5	EnergyAid, Inc.	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	166846289597446	2026-05-23 00:38:44.882871	2026-05-23 00:38:44.882871	Commercial	\N	\N	Home Services	2026-11-30	\N
4f10824f-cbd7-48c3-95d8-913cb7be337b	Fluid-Aire Dynamics Inc	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	162447005839739	2026-05-23 00:38:44.886679	2026-05-23 00:38:44.886679	Commercial	\N	\N	Home Services	2028-01-26	\N
4b430a17-cdda-403f-8ac1-79a183c994aa	Viking Capital, Inc	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	169627903111696	2026-05-23 00:38:44.89034	2026-05-23 00:38:44.89034	Commercial	\N	\N	Finance	2026-10-13	\N
70ce29f1-fd2f-467e-a563-a4aabb60fe36	Mike's Carwash	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	173759338842753	2026-05-23 00:38:44.894168	2026-05-23 00:38:44.894168	Commercial	\N	\N	Automotive	2027-02-21	\N
34910871-be0b-4eba-af18-347083227620	VP Supply Corp	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	167457650763559	2026-05-23 00:38:44.898293	2026-05-23 00:38:44.898293	Commercial	\N	\N	Retail	2027-03-31	\N
f9ba588a-4fdf-4697-a6f7-c6a54594c379	GO Mortgage	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	163422625421749	2026-05-23 00:38:44.901933	2026-05-23 00:38:44.901933	Commercial	\N	\N	Finance	2026-12-28	\N
9bf03120-27f6-4dec-a3ba-23b5bb6727bd	All Copy Products	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	157771959211606	2026-05-23 00:38:44.905721	2026-05-23 00:38:44.905721	Commercial	\N	\N	Consumer Services	2026-12-28	\N
ce254004-ffa9-446a-a8e9-7014c53f81f0	BaseCamp Franchising	13c3af04-c401-4c4b-b371-12cb014178e1	\N	yellow	f	\N	\N	164925675126131	2026-05-23 00:38:44.909515	2026-05-23 00:38:44.909515	Commercial	\N	\N	Retail	2028-04-12	\N
2db61834-5df2-4217-84ee-7d842a08f3a8	Nicolet Law Office, S.C.	13c3af04-c401-4c4b-b371-12cb014178e1	\N	red	f	\N	\N	151136227324265	2026-05-23 00:38:44.913713	2026-05-23 00:38:44.913713	Commercial	\N	\N	Legal	2026-12-15	\N
6671837e-34b4-43c4-ac44-e57e74b0cb37	DFCU Financial	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	153685011810290	2026-05-23 00:38:44.917214	2026-05-23 00:38:44.917214	Commercial	\N	\N	Finance	2027-01-21	\N
40bc3fed-271b-4ce7-bd88-0079b000bade	AIY Properties	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	red	f	\N	\N	159672807384670	2026-05-23 00:38:44.921334	2026-05-23 00:38:44.921334	Commercial	\N	\N	Real Estate	2026-10-23	\N
db76f80a-4a7d-4a25-a480-62a30703d28d	All In Credit Union	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	167226186380048	2026-05-23 00:38:44.925556	2026-05-23 00:38:44.925556	Commercial	\N	\N	Finance	2028-02-28	\N
66874ba1-3cb0-49d8-b598-9c65ccbc4e69	Fairlawn Real Estate	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	162318408394825	2026-05-23 00:38:44.929474	2026-05-23 00:38:44.929474	Commercial	\N	\N	Real Estate	2026-07-16	\N
1a695c6c-bece-4055-8f15-2b35f9fa8d73	Dewey Pest Control	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	161248109026019	2026-05-23 00:38:44.933675	2026-05-23 00:38:44.933675	Commercial	\N	\N	Home Services	2027-10-30	\N
0e87c961-031c-4177-bc49-2f1de3e54f09	50 Floor	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	162075051723883	2026-05-23 00:38:44.937676	2026-05-23 00:38:44.937676	Commercial	\N	\N	Retail	2027-04-14	\N
8e43ca0a-88b2-4071-9f32-34409d48e7b1	U.S. Lawns	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	red	f	\N	\N	174985331273623	2026-05-23 00:38:44.941631	2026-05-23 00:38:44.941631	Commercial	\N	\N	Home Services	2026-07-01	\N
526580bc-89ae-4aee-9aa0-8936c54beff5	Cahaba Medical Care	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	154022652765434	2026-05-23 00:38:44.94541	2026-05-23 00:38:44.94541	Commercial	\N	\N	Healthcare	2026-12-13	\N
b7d0123f-5ac3-4e2c-919b-fe0a0283a4a4	Baton Rouge Clinic	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	162144686503260	2026-05-23 00:38:44.948896	2026-05-23 00:38:44.948896	Commercial	\N	\N	Healthcare	2026-07-19	\N
29871d0b-c819-413f-8f71-b4ab5ab26439	Avid Storage	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	168962744521079	2026-05-23 00:38:44.952668	2026-05-23 00:38:44.952668	Commercial	\N	\N	Real Estate	2026-07-28	\N
c056d857-5f44-460e-8230-a05a5c923952	K&D Management LLC	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	172730437626384	2026-05-23 00:38:44.956376	2026-05-23 00:38:44.956376	Commercial	\N	\N	Real Estate	2027-06-01	\N
542c3300-77df-4065-8730-403bb0d21a02	IN'n'OUT Autocentres	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	174973928064937	2026-05-23 00:38:44.960224	2026-05-23 00:38:44.960224	Commercial	\N	\N	Automotive	2026-07-31	\N
0d21bd08-9b25-4da4-9921-154e193fd46c	Greenbrier Senior Living	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	166725678814765	2026-05-23 00:38:44.96462	2026-05-23 00:38:44.96462	Commercial	\N	\N	Real Estate	2027-02-27	\N
d719c829-dfed-4ead-95d8-501c8468df79	Escapology	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	171035485307491	2026-05-23 00:38:44.96852	2026-05-23 00:38:44.96852	Commercial	\N	\N	Arts & Entertainment	2027-12-27	\N
944e3a26-14ba-4c94-b137-15bef0b9ffeb	Alexander Shunnarah Injury Attorneys P.C	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	173559983630732	2026-05-23 00:38:44.972945	2026-05-23 00:38:44.972945	Commercial	\N	\N	Legal	2026-12-31	\N
1e31510b-b23e-48ee-a83c-7d4885db64f9	Simpson Housing	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	148112781717402	2026-05-23 00:38:44.976924	2026-05-23 00:38:44.976924	Commercial	\N	\N	Real Estate	2026-04-23	\N
9533f745-e5c1-4e7f-8ed2-5365379ec175	StoragePro, Inc.	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	155811441722374	2026-05-23 00:38:44.980425	2026-05-23 00:38:44.980425	Commercial	\N	\N	Consumer Services	2027-03-11	\N
e7caf761-8434-432d-854e-64c08d82be6e	Foot Solutions	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	156959471536910	2026-05-23 00:38:44.983786	2026-05-23 00:38:44.983786	Commercial	\N	\N	Healthcare	2027-02-24	\N
603273e0-5f30-4c10-928c-67dd3f8d80fa	Pond Lehocky Giordano LLP	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	173698372999966	2026-05-23 00:38:44.987659	2026-05-23 00:38:44.987659	Commercial	\N	\N	Legal	2029-01-13	\N
bce7f943-a249-491b-aeb9-439d694a9a70	Acorn Health, Inc	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	168055227335975	2026-05-23 00:38:44.99174	2026-05-23 00:38:44.99174	Commercial	\N	\N	Healthcare	2026-09-29	\N
3a980111-d91a-43c0-b444-1742706e5983	New Jersey Spine and Orthopedic	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	red	f	\N	\N	160694420230250	2026-05-23 00:38:44.995657	2026-05-23 00:38:44.995657	Commercial	\N	\N	Healthcare	2026-12-21	\N
585b2ebc-9da6-43e7-89b9-2c5a585095f7	American Heritage Credit Union	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	166515530705482	2026-05-23 00:38:44.99963	2026-05-23 00:38:44.99963	Commercial	\N	\N	Finance	2028-11-07	\N
46220b17-2cb2-4b54-9b30-a5c7235b274a	Rehab Medical & Cork Medical	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	155604378954541	2026-05-23 00:38:45.003259	2026-05-23 00:38:45.003259	Commercial	\N	\N	Consumer Goods	2026-12-09	\N
f27691d9-672b-40d9-8eae-c459012ae559	Resolve Pain Solutions	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	170630350253339	2026-05-23 00:38:45.007129	2026-05-23 00:38:45.007129	Commercial	\N	\N	Healthcare	2026-09-11	\N
09207ff7-1c9e-4d14-886c-c652a7ec5724	Consolidated Communications	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	red	f	\N	\N	167890568410420	2026-05-23 00:38:45.014758	2026-05-23 00:38:45.014758	Commercial	\N	\N	Technology	2026-12-31	\N
a3e91664-cc66-41b7-9d7c-70eef9e2f4e9	Paradigm Oral Surgery	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	red	f	\N	\N	163829947969744	2026-05-23 00:38:45.018671	2026-05-23 00:38:45.018671	Commercial	\N	\N	Dental	2027-03-12	\N
cfe88f71-69ac-4633-92be-20c5d065e457	TRA Medical Imaging	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	yellow	f	\N	\N	153807137213693	2026-05-23 00:38:45.022612	2026-05-23 00:38:45.022612	Commercial	\N	\N	Healthcare	2027-11-15	\N
d0b1d8ab-32a5-491b-b0ce-bf3bef2487ec	Kromer Investments Inc	173b2a24-d088-4ea7-af81-4c82c0c50639	\N	red	f	\N	\N	155715815784851	2026-05-23 00:38:45.026125	2026-05-23 00:38:45.026125	Commercial	\N	\N	Real Estate	2026-07-30	\N
71ccc0a8-1295-40c5-a629-0e4be70213cf	Emler Swim School	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	155205673455451	2026-05-23 00:38:45.029666	2026-05-23 00:38:45.029666	Commercial	\N	\N	Education	2026-07-30	\N
1b4a4fa0-cd74-48fb-bfe5-0da00ea14911	Evergreen Prosthetics And Orthotics	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	170483342344831	2026-05-23 00:38:45.033416	2026-05-23 00:38:45.033416	Commercial	\N	\N	Healthcare	2028-03-13	\N
471f1f31-7938-4078-b5d5-cf1e5a9526ec	Andersens Flooring	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	175090317016316	2026-05-23 00:38:45.037184	2026-05-23 00:38:45.037184	Commercial	\N	\N	Home Services	2026-06-29	\N
b72cb88f-0d5a-4c9b-95d7-8a8bd73f5efa	MosaicMedical	46c035c6-6314-45a0-ab81-f7792559300d	\N	red	f	\N	\N	166612345395080	2026-05-23 00:38:45.041932	2026-05-23 00:38:45.041932	Commercial	\N	\N	Healthcare	2027-04-30	\N
986e6f30-a198-439b-a011-31bcfc55f2b1	PM Pediatric Care	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	170006665335166	2026-05-23 00:38:45.045847	2026-05-23 00:38:45.045847	Commercial	\N	\N	Healthcare	2027-12-10	\N
b690d562-d51d-4837-8eff-7ffa99668e33	Wonder	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	176191908804982	2026-05-23 00:38:45.049398	2026-05-23 00:38:45.049398	Commercial	\N	\N	Restaurants	2026-12-08	\N
b32b88ab-f848-490d-b6da-c0b4d0e39e49	VanDyk Mortgage Corporation	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	157421164328020	2026-05-23 00:38:45.053164	2026-05-23 00:38:45.053164	Commercial	\N	\N	Finance	2027-12-30	\N
b40efc73-d81c-47ca-84ff-dcfd3d17ec17	XPO	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	green	f	\N	\N	155060482166977	2026-05-23 00:38:45.057289	2026-05-23 00:38:45.057289	Commercial	\N	\N	Transportation Services	2027-01-29	\N
c0d20c05-d9b1-4919-956f-3e8311b58715	Levin Furniture & Mattress	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	159984327832719	2026-05-23 00:38:45.06165	2026-05-23 00:38:45.06165	Commercial	\N	\N	Retail	2027-03-30	\N
e3827328-81c9-41b5-831d-13311f03e2c3	Tend	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	red	f	\N	\N	163768382203233	2026-05-23 00:38:45.065639	2026-05-23 00:38:45.065639	Commercial	\N	\N	Dental	2027-01-22	\N
f9e0258a-af5d-4940-ae7d-9e7091daac95	SavATree	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	169210751699450	2026-05-23 00:38:45.070245	2026-05-23 00:38:45.070245	Commercial	\N	\N	Contractors	2027-04-07	\N
2e7a0093-fa59-4185-9791-38538dfc1efd	St. Joseph's Candler	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	161986249959780	2026-05-23 00:38:45.074495	2026-05-23 00:38:45.074495	Commercial	\N	\N	Healthcare	2027-10-31	\N
b417d937-9677-4388-a3a8-64a3521e8a29	Horizon Services	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	161869122606173	2026-05-23 00:38:45.079029	2026-05-23 00:38:45.079029	Commercial	\N	\N	Contractors	2026-07-21	\N
e6543af3-513c-4c0e-ae6b-7fe100659036	Asden Management LLC	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	172729967881102	2026-05-23 00:38:45.084644	2026-05-23 00:38:45.084644	Commercial	\N	\N	Real Estate	2028-06-24	\N
f6947406-3c0c-46bd-993f-aeb32f7547bd	Brookfield Properties	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	169937069686263	2026-05-23 00:38:45.08863	2026-05-23 00:38:45.08863	Commercial	\N	\N	Real Estate	2026-11-26	\N
9f998255-ceb4-42e0-9a45-6f8a9e286298	Gardant Management Solutions	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	176341370728880	2026-05-23 00:38:45.092674	2026-05-23 00:38:45.092674	Commercial	\N	\N	Healthcare	2029-02-28	\N
2c4f38ab-6cf0-4bbd-b62f-96742e81c09c	Milhaus Management, LLC	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	157444855671485	2026-05-23 00:38:45.096614	2026-05-23 00:38:45.096614	Commercial	\N	\N	Real Estate	2027-03-17	\N
79453a1b-f9ba-4dd2-8e5e-f354cff8daee	Mckinley	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	166785675954404	2026-05-23 00:38:45.100291	2026-05-23 00:38:45.100291	Commercial	\N	\N	Real Estate	2028-01-22	\N
e0b62524-d9f7-404f-9294-22b5c41a8c5f	Fireman Hospitality Group	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	167570732593086	2026-05-23 00:38:45.104091	2026-05-23 00:38:45.104091	Commercial	\N	\N	Hospitality	2027-02-21	\N
5e801eb2-e21a-484c-99d7-ccecc9f68b46	Kotarides Companies	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	156262153388108	2026-05-23 00:38:45.108129	2026-05-23 00:38:45.108129	Commercial	\N	\N	Real Estate	2027-05-10	\N
58956eb5-fe7e-47d0-8ed6-8f24e57294dd	Natures Grace & Wellness	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	red	f	\N	\N	167580555561525	2026-05-23 00:38:45.112267	2026-05-23 00:38:45.112267	Commercial	\N	\N	Retail	2027-03-01	\N
8e4369f4-81c4-40eb-995d-69821f7991b4	Honest Abe Roofing Inc	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	157011138986992	2026-05-23 00:38:45.116212	2026-05-23 00:38:45.116212	Commercial	\N	\N	Home Services	2026-12-05	\N
c5192d31-6897-452f-99a3-5a8cd7c4be26	Lost Treasure Golf	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	green	f	\N	\N	175770633156627	2026-05-23 00:38:45.119808	2026-05-23 00:38:45.119808	Commercial	\N	\N	Hospitality	2027-12-28	\N
09e69aac-d031-47e3-b83c-96d5564969ed	Griswold	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	red	f	\N	\N	167824345181931	2026-05-23 00:38:45.123797	2026-05-23 00:38:45.123797	Commercial	\N	\N	Healthcare	2027-08-18	\N
89a2ba1e-1915-49e1-9564-05ad358f720f	AV Properties	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	red	f	\N	\N	157598836406047	2026-05-23 00:38:45.127385	2026-05-23 00:38:45.127385	Commercial	\N	\N	Real Estate	2026-07-23	\N
8c358fe8-8b84-422a-89ac-b8d4d9ef60ca	Aion Management LLC	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	163295102032657	2026-05-23 00:38:45.131583	2026-05-23 00:38:45.131583	Commercial	\N	\N	Real Estate	2027-07-30	\N
dffd3c2a-aa79-4140-8d6a-109ce8fe4d70	Top Flite Financial, Inc.	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	red	f	\N	\N	161170486685981	2026-05-23 00:38:45.135963	2026-05-23 00:38:45.135963	Commercial	\N	\N	Finance	2026-09-29	\N
413c4172-5f54-4296-a410-9c4388371312	Lessing's Hospitality Group	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	151560312747820	2026-05-23 00:38:45.140169	2026-05-23 00:38:45.140169	Commercial	\N	\N	Restaurants	2028-01-12	\N
92b78a18-eb7c-418b-bc58-98dfb254b9be	Reside Living LLC	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	159429935361960	2026-05-23 00:38:45.144799	2026-05-23 00:38:45.144799	Commercial	\N	\N	Real Estate	2028-12-31	\N
fc9d99b8-f862-4a0b-8834-fa5184ac7451	Tom Wood Powersports	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	160037781044596	2026-05-23 00:38:45.149014	2026-05-23 00:38:45.149014	Commercial	\N	\N	Automotive	2026-09-29	\N
f983d66e-1edf-477d-832c-b7f43da709df	World Acceptance Corporation	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	175951640766138	2026-05-23 00:38:45.153332	2026-05-23 00:38:45.153332	Commercial	\N	\N	Finance	2026-12-31	\N
91fe5091-ac44-44f0-b665-6ff6fb13ef08	ABC Bail Bonds	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	red	f	\N	\N	162144457706889	2026-05-23 00:38:45.157325	2026-05-23 00:38:45.157325	Commercial	\N	\N	Community & Social Services	2027-05-21	\N
30b3535d-8f0e-4ca1-a842-650c7bf172be	PFCU	bcc998fa-c19a-4ab1-b59d-263e7e121d7e	\N	yellow	f	\N	\N	155380245436343	2026-05-23 00:38:45.161764	2026-05-23 00:38:45.161764	Commercial	\N	\N	Finance	2027-05-26	\N
7a246100-3536-4725-bda0-82a559682eae	COIT Cleaning and Restoration	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	160797827320130	2026-05-23 00:38:45.165671	2026-05-23 00:38:45.165671	Commercial	\N	\N	Home Services	2027-05-01	\N
ca4be136-f25e-4d88-b108-46944f6cadd3	C&N Construction, Inc	acd1c2fa-6a07-4f5c-aca9-a0c666b69940	\N	red	f	\N	\N	162232092448211	2026-05-23 00:38:45.169542	2026-05-23 00:38:45.169542	Commercial	\N	\N	Contractors	2027-03-26	\N
e87b1d94-869f-42cd-9858-b6a2bea7e6e6	AMA Collision	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	169946908786991	2026-05-23 00:38:45.173534	2026-05-23 00:38:45.173534	Commercial	\N	\N	Automotive	2027-04-23	\N
48052503-191f-4066-821c-2cde538348a8	Tourism Holdings Limited	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	164728881482261	2026-05-23 00:38:45.177374	2026-05-23 00:38:45.177374	Commercial	\N	\N	Hospitality	2027-02-26	\N
65273c93-a4eb-43c9-8d84-82c497155e1d	Raine & Horne Victoria	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	171410574481586	2026-05-23 00:38:45.181831	2026-05-23 00:38:45.181831	Commercial	\N	\N	Real Estate	2026-07-07	\N
0bce6f00-7e6c-4ba9-a869-5092e749b27e	First Aid Pro	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	173406606468904	2026-05-23 00:38:45.186001	2026-05-23 00:38:45.186001	Commercial	\N	\N	Education	2027-03-24	\N
cd1d42c1-95d2-4fdb-9cf8-435d4006d936	Looksmart Alterations Head Office	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	169754687050744	2026-05-23 00:38:45.190226	2026-05-23 00:38:45.190226	Commercial	\N	\N	Consumer Services	2027-02-16	\N
ecac524d-741d-4a94-9554-f3b02bf17031	Roll'd	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	174123903569623	2026-05-23 00:38:45.194204	2026-05-23 00:38:45.194204	Commercial	\N	\N	Restaurants	2027-07-21	\N
cf5410b9-6a54-40ce-8335-f8e2ea8a5f0b	Advertising Development Services Pty Ltd	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	171935815691196	2026-05-23 00:38:45.19809	2026-05-23 00:38:45.19809	Commercial	\N	\N	Retail	2026-11-30	\N
6f5e2678-5aa2-49c2-bdbe-17f5b2e41754	Capital S.M.A.R.T. Repairs	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	170830146819681	2026-05-23 00:38:45.202173	2026-05-23 00:38:45.202173	Commercial	\N	\N	Automotive	2027-04-23	\N
535e4e7d-f367-454e-a7d4-4ae42fd3acf4	East Coast Car Rentals	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	174601821008691	2026-05-23 00:38:45.205785	2026-05-23 00:38:45.205785	Commercial	\N	\N	Transportation Services	2026-06-02	\N
f018614a-86e7-43ae-8e26-6c447305c10f	National Dental Care	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	174668538992663	2026-05-23 00:38:45.209605	2026-05-23 00:38:45.209605	Commercial	\N	\N	Dental	2027-06-09	\N
f57a667e-725f-453d-b2b7-37a20fa03904	Bakers Delight	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	174251608670150	2026-05-23 00:38:45.214198	2026-05-23 00:38:45.214198	Commercial	\N	\N	Restaurants	2026-06-09	\N
15d3b5ac-682b-4eb9-84c9-85c52c3dabf0	Sushi Sushi	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	173889868441412	2026-05-23 00:38:45.218085	2026-05-23 00:38:45.218085	Commercial	\N	\N	Restaurants	2027-03-01	\N
7b1162fd-e120-47e7-bb3b-c35ca0854d91	Travel Money Group	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	172371767105319	2026-05-23 00:38:45.221827	2026-05-23 00:38:45.221827	Commercial	\N	\N	Finance	2026-09-24	\N
567a5e74-53b2-4ec8-b118-4e197622c98d	Hearing Australia	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	green	f	\N	\N	170561577328668	2026-05-23 00:38:45.225897	2026-05-23 00:38:45.225897	Commercial	\N	\N	Healthcare	2031-01-12	\N
3f027030-a7f3-426b-8e14-d318ecbcafaa	Vivo Hair Salon	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	green	f	\N	\N	176784935782310	2026-05-23 00:38:45.229783	2026-05-23 00:38:45.229783	Commercial	\N	\N	Beauty	2027-01-30	\N
ec52d26e-ae70-40d2-b9af-17ce02586ff3	Bellway Homes	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	red	f	\N	\N	1756984341636523	2026-05-23 00:38:45.23449	2026-05-23 00:38:45.23449	Commercial	\N	\N	Construction	2026-10-15	\N
30d6b0d2-db36-4fa3-af19-35fceeb73c2c	Snows	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	red	f	\N	\N	1750843630835903	2026-05-23 00:38:45.238782	2026-05-23 00:38:45.238782	Commercial	\N	\N	Automotive	2026-07-07	\N
bdfe29b5-65df-49c1-a964-9e820bf745aa	Ivolve Group	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	yellow	f	\N	\N	1759818486739553	2026-05-23 00:38:45.242939	2026-05-23 00:38:45.242939	Commercial	\N	\N	Healthcare	2029-01-29	\N
33b793be-4f22-483f-ac88-ec87978bfdb9	DNA Vetcare Ltd	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	yellow	f	\N	\N	171110883656973	2026-05-23 00:38:45.24709	2026-05-23 00:38:45.24709	Commercial	\N	\N	Healthcare	2026-10-22	\N
0a4d5286-67e6-47e5-8f61-3ca1b0400268	Priory	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	yellow	f	\N	\N	1764775343902953	2026-05-23 00:38:45.251129	2026-05-23 00:38:45.251129	Commercial	\N	\N	Wellness	2028-05-31	\N
2365a4f7-6dac-4853-933a-eb5e44b684fe	Nolte Kitchens UK Limited	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	red	f	\N	\N	173393054068654	2026-05-23 00:38:45.254705	2026-05-23 00:38:45.254705	Commercial	\N	\N	Home Services	2026-12-19	\N
8c1ce8ca-d145-4293-b87b-1c594bcda8e2	Signature Pub Group	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	yellow	f	\N	\N	173635059576148	2026-05-23 00:38:45.25835	2026-05-23 00:38:45.25835	Commercial	\N	\N	Restaurants	2026-06-01	\N
f1e45639-7b95-4e17-b3aa-50c7cd2bb6f8	Goals	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	173736508337982	2026-05-23 00:38:45.26216	2026-05-23 00:38:45.26216	Commercial	\N	\N	Recreation	2028-08-23	\N
5d2f203d-2fe8-4b2c-aec8-35c1615cbbf8	Stringam Law	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	169896739755445	2026-05-23 00:38:45.268299	2026-05-23 00:38:45.268299	Commercial	\N	\N	Legal	2028-12-03	\N
6d04f803-f789-4057-81f9-b0298bd9be65	Blue Star Investments	566d6af5-e82f-4360-b4a2-76d0b916195c	\N	red	f	\N	\N	173628066566731	2026-05-23 00:38:45.273175	2026-05-23 00:38:45.273175	Commercial	\N	\N	Retail	2027-02-26	\N
2968b326-b1e3-404d-8956-82bc574208ed	Ciot	566d6af5-e82f-4360-b4a2-76d0b916195c	\N	red	f	\N	\N	161479512354390	2026-05-23 00:38:45.277409	2026-05-23 00:38:45.277409	Commercial	\N	\N	Consumer Services	2026-08-02	\N
ba6aea1f-f5e7-4e9b-a021-765665ee7c12	The Edge Fitness Clubs	566d6af5-e82f-4360-b4a2-76d0b916195c	\N	yellow	f	\N	\N	174490405015795	2026-05-23 00:38:45.28115	2026-05-23 00:38:45.28115	Commercial	\N	\N	Recreation	2026-04-28	\N
c9cc3f11-4e8e-45bc-a6d2-98e385d66a70	Artisan Management Group	566d6af5-e82f-4360-b4a2-76d0b916195c	\N	red	f	\N	\N	170585757438728	2026-05-23 00:38:45.284916	2026-05-23 00:38:45.284916	Commercial	\N	\N	Real Estate	2027-03-04	\N
746c1919-7ea9-4812-bc78-abe5e0d543cd	Archer's Bikes Mesa	566d6af5-e82f-4360-b4a2-76d0b916195c	\N	yellow	f	\N	\N	169764164524788	2026-05-23 00:38:45.288452	2026-05-23 00:38:45.288452	Commercial	\N	\N	Other	2026-10-19	\N
8d482ed7-b5e4-4412-822b-004108f01f7e	Align Communities	566d6af5-e82f-4360-b4a2-76d0b916195c	\N	red	f	\N	\N	169472048548598	2026-05-23 00:38:45.292356	2026-05-23 00:38:45.292356	Commercial	\N	\N	Real Estate	2026-10-31	\N
cd966e1f-5f7b-46b7-b3ea-e10afb8b5cb3	Box Self Storage - Metairie	566d6af5-e82f-4360-b4a2-76d0b916195c	\N	yellow	f	\N	\N	168113284084382	2026-05-23 00:38:45.296149	2026-05-23 00:38:45.296149	Commercial	\N	\N	Transportation Services	2027-01-29	\N
6e4297ab-99db-426a-8246-1948952c7329	Raine & Horne Corporate	eb4c741c-1303-44f8-a9f1-7cbea02ab44e	\N	yellow	f	\N	\N	175443777744679	2026-05-23 00:38:45.300371	2026-05-23 00:38:45.300371	Enterprise	\N	\N	Real Estate	2028-01-11	\N
9797e7ce-f9c4-42e2-a8b9-71c45fb54f8d	Acton | Belle Property | Hockingstuart	eb4c741c-1303-44f8-a9f1-7cbea02ab44e	\N	red	f	\N	\N	172946408955442	2026-05-23 00:38:45.304601	2026-05-23 00:38:45.304601	Enterprise	\N	\N	Real Estate	2026-12-16	\N
77f6df66-833e-4334-ae94-331ce14bc362	Roots Management, LLC	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	161826694273638	2026-05-23 00:38:45.312565	2026-05-23 00:38:45.312565	Enterprise	\N	\N	Real Estate	2026-12-27	\N
d0fe9152-e0bf-421a-9c9a-b0751b4e6e23	Varsity Healthcare Partners	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	172488153067760	2026-05-23 00:38:45.316275	2026-05-23 00:38:45.316275	Enterprise	\N	\N	Healthcare	2027-12-31	\N
0414fb08-cf67-4b44-9348-d382b20b2f3e	Investment Concepts, Inc.	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	172730398510047	2026-05-23 00:38:45.319922	2026-05-23 00:38:45.319922	Enterprise	\N	\N	Real Estate	2026-06-01	\N
0a20df6e-5f14-4de6-ad79-3e1c9a6eeb83	Cortland	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	169699783343081	2026-05-23 00:38:45.323464	2026-05-23 00:38:45.323464	Enterprise	\N	\N	Real Estate	2027-02-28	\N
fbf03d00-c5d4-45cb-94f8-6d0099485a09	My Garage Self Storage	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	168356302240296	2026-05-23 00:38:45.327293	2026-05-23 00:38:45.327293	Enterprise	\N	\N	Consumer Services	2027-03-25	\N
f3cdb8b4-d8f9-406a-a8e7-18374f321699	Tidal Wave Auto Spa	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	170871901578853	2026-05-23 00:38:45.331219	2026-05-23 00:38:45.331219	Enterprise	\N	\N	Automotive	2026-12-30	\N
61437d4c-73cc-4c86-96ec-ddb67908d964	Sono Bello	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	154351870738564	2026-05-23 00:38:45.33531	2026-05-23 00:38:45.33531	Enterprise	\N	\N	Beauty	2027-11-22	\N
dc3b64d0-d61d-4dfe-96c2-1b4a026334eb	The Glass Guru Enterprises, Inc.	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	159968684338598	2026-05-23 00:38:45.339226	2026-05-23 00:38:45.339226	Enterprise	\N	\N	Home Services	2028-02-29	\N
3c105ac6-94bd-4125-a04c-2059df8a71ce	Road Runner Sports	ffa96572-267d-44fa-82e1-7518094c77b9	\N	yellow	f	\N	\N	158041303669458	2026-05-23 00:38:45.342931	2026-05-23 00:38:45.342931	Enterprise	\N	\N	Retail	2026-12-30	\N
31c8bebe-6631-4b58-aee9-695f5015797c	Argus Professional Storage Management	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	170130183357927	2026-05-23 00:38:45.346803	2026-05-23 00:38:45.346803	Enterprise	\N	\N	Consumer Services	2028-01-21	\N
3c7e18dd-5369-4ac0-a605-d79223574264	Grace Management, Inc.	ffa96572-267d-44fa-82e1-7518094c77b9	\N	yellow	f	\N	\N	150550049324262	2026-05-23 00:38:45.350483	2026-05-23 00:38:45.350483	Enterprise	\N	\N	Wellness	2026-12-19	\N
d1bd9287-4b4e-411d-9e7c-f616dfd024d4	SRI Management	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	162818096614407	2026-05-23 00:38:45.354484	2026-05-23 00:38:45.354484	Enterprise	\N	\N	Real Estate	2026-10-29	\N
a70fffa3-bc34-4370-a836-144ce5affc8f	Numotion	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	161918874478641	2026-05-23 00:38:45.358159	2026-05-23 00:38:45.358159	Enterprise	\N	\N	Other	2027-12-01	\N
2c9e1461-0123-43db-974f-2d1e3297b401	Stockton Mortgage | Corporate | Frankfort, KY | NMLS# 8259	ffa96572-267d-44fa-82e1-7518094c77b9	\N	yellow	f	\N	\N	164389934807088	2026-05-23 00:38:45.361561	2026-05-23 00:38:45.361561	Enterprise	\N	\N	Real Estate	2027-02-17	\N
c1082064-6f26-49f0-8510-ee80e231d789	GreenEarth Marketing	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	172003272651476	2026-05-23 00:38:45.365312	2026-05-23 00:38:45.365312	Enterprise	\N	\N	Consumer Services	2026-07-31	\N
25329361-ac50-4496-9366-7fe21fb370a1	Pennant	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	169653235619102	2026-05-23 00:38:45.369071	2026-05-23 00:38:45.369071	Enterprise	\N	\N	Healthcare	2027-11-19	\N
797aea6a-e2a6-4cb2-9620-0e0da3d1d872	Fidelity Bank	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	170561253308630	2026-05-23 00:38:45.372596	2026-05-23 00:38:45.372596	Enterprise	\N	\N	Finance	2026-07-21	\N
8b9eb6ac-81e2-4563-a6f2-d27568217222	Removery Tattoo Removal & Fading	ffa96572-267d-44fa-82e1-7518094c77b9	\N	yellow	f	\N	\N	174292252535739	2026-05-23 00:38:45.376169	2026-05-23 00:38:45.376169	Enterprise	\N	\N	Wellness	2028-04-14	\N
2adb98aa-a339-4fcd-99f0-8a2ee06fe1c2	Heritage Family	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	173464014783568	2026-05-23 00:38:45.381817	2026-05-23 00:38:45.381817	Enterprise	\N	\N	Consumer Services	2027-12-25	\N
14a1e9f9-de6d-4a3e-aedb-0b440a40aad5	True Spec Golf	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	155302208003040	2026-05-23 00:38:45.385962	2026-05-23 00:38:45.385962	Enterprise	\N	\N	Retail	2028-04-03	\N
2ccfcd83-e493-4789-b5b1-31ccf68b50c4	Paramount Residential Mortgage Group	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	157410699141441	2026-05-23 00:38:45.390008	2026-05-23 00:38:45.390008	Enterprise	\N	\N	Finance	2026-12-11	\N
4eb43788-b65d-4c26-b85a-61fd5fef1891	WhiteWater Express Car Wash	ffa96572-267d-44fa-82e1-7518094c77b9	\N	red	f	\N	\N	163008177916685	2026-05-23 00:38:45.394311	2026-05-23 00:38:45.394311	Enterprise	\N	\N	Automotive	2027-01-28	\N
bca990dc-d8d0-444d-84c8-96a49cd6ee0d	Heritage Senior Communities	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	165462090646966	2026-05-23 00:38:45.398325	2026-05-23 00:38:45.398325	Enterprise	\N	\N	Healthcare	2026-06-21	\N
9b4c2d26-fb54-4e28-aedc-9946f862a370	The Community Builders	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	red	f	\N	\N	167700715583239	2026-05-23 00:38:45.402399	2026-05-23 00:38:45.402399	Enterprise	\N	\N	Real Estate	2026-06-30	\N
fd99dc90-cc86-4333-ae11-df1ada48f329	Extra Space Storage Inc	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	154224558480194	2026-05-23 00:38:45.406747	2026-05-23 00:38:45.406747	Enterprise	\N	\N	Consumer Services	2026-12-26	\N
80b79762-48c2-4459-8d00-78df151290d6	Drucker and Falk, LLC	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	172730191209389	2026-05-23 00:38:45.410645	2026-05-23 00:38:45.410645	Enterprise	\N	\N	Real Estate	2026-06-01	\N
ce177d84-e5eb-49e5-bd7b-f31a835c1b60	Mohawk Industries	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	153850361873276	2026-05-23 00:38:45.414225	2026-05-23 00:38:45.414225	Enterprise	\N	\N	Home Services	2026-11-17	\N
a4fa3981-31b4-4e49-b2c2-a86940182ce9	Floor and Decor	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	155846300171434	2026-05-23 00:38:45.417737	2026-05-23 00:38:45.417737	Enterprise	\N	\N	Home Services	2027-02-19	\N
deb045f3-3cf9-46d9-ae38-86b07129f060	Audiology Distribution, LLC	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	172889377879822	2026-05-23 00:38:45.421912	2026-05-23 00:38:45.421912	Enterprise	\N	\N	Other	2026-10-01	\N
69624d07-b231-4234-a871-18e229a44c53	Superior Fence & Rail Franchising, LLC	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	yellow	f	\N	\N	152044990070323	2026-05-23 00:38:45.425587	2026-05-23 00:38:45.425587	Enterprise	\N	\N	Contractors	2026-11-14	\N
39ca73e0-0714-4f33-8db8-8510228ca459	GFL Environmental Inc	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	168623947407486	2026-05-23 00:38:45.429383	2026-05-23 00:38:45.429383	Enterprise	\N	\N	Consumer Services	2026-07-31	\N
b1722e49-47d3-4ba4-ac87-ecf408dd5451	Foundation Partners Group	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	165910341250161	2026-05-23 00:38:45.433172	2026-05-23 00:38:45.433172	Enterprise	\N	\N	Community & Social Services	2029-03-18	\N
54cc5722-5c95-4e86-bf2f-1d0be07cdaba	Timpson Ltd	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	173444284809207	2026-05-23 00:38:45.437147	2026-05-23 00:38:45.437147	Enterprise	\N	\N	Retail	2028-09-29	\N
62dfa801-70ed-4898-b641-2d2f6dbb8ceb	Elevate ENT Partners	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	yellow	f	\N	\N	169056117953285	2026-05-23 00:38:45.440673	2026-05-23 00:38:45.440673	Enterprise	\N	\N	Healthcare	2026-12-28	\N
f8393b64-6549-4c8a-b7c5-478c4e55c67e	Big Yellow Group PLC	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	172442439140224	2026-05-23 00:38:45.444623	2026-05-23 00:38:45.444623	Enterprise	\N	\N	Consumer Services	2028-03-31	\N
d1aedf00-53ba-434d-be5d-af70254f6e3a	Massey Services	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	157970891274810	2026-05-23 00:38:45.448416	2026-05-23 00:38:45.448416	Enterprise	\N	\N	Home Services	2027-02-04	\N
1835e2b2-19ac-445c-b788-677925b33850	Community Loans of America	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	169150087128198	2026-05-23 00:38:45.452236	2026-05-23 00:38:45.452236	Enterprise	\N	\N	Finance	2026-05-28	\N
ead89e69-f8cb-4dd2-8752-0ad33d55dc54	Vestis	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	164192902536219	2026-05-23 00:38:45.455938	2026-05-23 00:38:45.455938	Enterprise	\N	\N	Hospitality	2026-05-23	\N
1b106877-82dc-4170-950b-0ede7679f883	Hollywood Feed	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	166855466645785	2026-05-23 00:38:45.459818	2026-05-23 00:38:45.459818	Enterprise	\N	\N	Retail	2027-03-28	\N
50719ae9-1699-4b9e-b1ce-2d7e1010d74c	Quipt Home Medical	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	yellow	f	\N	\N	169117560706257	2026-05-23 00:38:45.463605	2026-05-23 00:38:45.463605	Enterprise	\N	\N	Healthcare	2027-09-30	\N
910cfdef-60ea-46cd-92c3-fdbebd353fb3	Vast Coworking Group	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	162523796234568	2026-05-23 00:38:45.467284	2026-05-23 00:38:45.467284	Enterprise	\N	\N	Hospitality	2027-11-29	\N
3451db56-750b-4c88-9e84-c0f70822f06e	Right at School	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	174317595101965	2026-05-23 00:38:45.470819	2026-05-23 00:38:45.470819	Enterprise	\N	\N	Education	2027-05-30	\N
91fdab97-6a39-4ff0-9ea5-6e9bbab2dcc5	Budget Storage and Lock	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	166430378439386	2026-05-23 00:38:45.474312	2026-05-23 00:38:45.474312	Enterprise	\N	\N	Consumer Services	2028-04-30	\N
85c0859a-714e-4d7f-b826-463b27f74d0e	Alexander Forrest	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	151794601233127	2026-05-23 00:38:45.477887	2026-05-23 00:38:45.477887	Enterprise	\N	\N	Real Estate	2027-04-12	\N
3f059355-24c2-442a-b0df-d794f9bfe065	Pinnacle/ Rollings	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	174724313598501	2026-05-23 00:38:45.481283	2026-05-23 00:38:45.481283	Enterprise	\N	\N	Consumer Services	2027-06-20	\N
04dbf8dd-1d28-4312-914a-ec60be72dbf4	Indiana Members Credit Union	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	167474773726700	2026-05-23 00:38:45.484697	2026-05-23 00:38:45.484697	Enterprise	\N	\N	Finance	2027-03-27	\N
62771a5c-2a66-4292-99f2-407baa06e8f3	Homes for Students	490b2e13-e9b3-4eb3-ba8e-5d98279a787b	\N	red	f	\N	\N	1755595771441063	2026-05-23 00:38:45.488284	2026-05-23 00:38:45.488284	Enterprise	\N	\N	Real Estate	2027-11-13	\N
8c8722b4-31ee-4d20-8f66-730632da85ac	Trinity Health	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	yellow	f	\N	\N	174645873035992	2026-05-23 00:38:45.492009	2026-05-23 00:38:45.492009	Enterprise	\N	\N	Healthcare	2027-07-01	\N
b42b06bb-d9b7-4b8d-81ac-f7ff99365ce2	PACS	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	yellow	f	\N	\N	176133289494409	2026-05-23 00:38:45.495991	2026-05-23 00:38:45.495991	Enterprise	\N	\N	Wellness	2027-11-17	\N
73452d11-c8dc-482e-9e47-9ae2d937e275	Choice Healthcare Services	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	yellow	f	\N	\N	156805401018563	2026-05-23 00:38:45.500038	2026-05-23 00:38:45.500038	Enterprise	\N	\N	Healthcare	2026-11-16	\N
0f3d9940-b220-469c-a2f1-288c30192580	SYNERGY HomeCare	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	155240502463691	2026-05-23 00:38:45.504428	2026-05-23 00:38:45.504428	Enterprise	\N	\N	Healthcare	2026-08-29	\N
e00f9bfd-7a38-49d9-8175-456a75d2ff01	Imagen Dental Partners	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	yellow	f	\N	\N	166879057915183	2026-05-23 00:38:45.508286	2026-05-23 00:38:45.508286	Enterprise	\N	\N	Dental	2026-12-30	\N
17662c5d-6617-4d85-b7bb-7857e4c1750a	Simonmed Imaging	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	166388373796731	2026-05-23 00:38:45.512095	2026-05-23 00:38:45.512095	Enterprise	\N	\N	Healthcare	2028-03-17	\N
63c88de3-791a-4d1b-81f6-b6fe26ae873a	NVISION Eye Centers	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	148761947719095	2026-05-23 00:38:45.515732	2026-05-23 00:38:45.515732	Enterprise	\N	\N	Healthcare	2027-02-24	\N
6cd7230e-b483-4fa5-ae5f-43df11ba88b2	Ogden Clinic | Business Office	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	165662458257311	2026-05-23 00:38:45.51942	2026-05-23 00:38:45.51942	Enterprise	\N	\N	Other	2027-11-11	\N
fc596d41-0158-42db-98b8-7a589da47a85	Western Veterinary Partners	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	yellow	f	\N	\N	168797753388224	2026-05-23 00:38:45.522948	2026-05-23 00:38:45.522948	Enterprise	\N	\N	Healthcare	2026-06-27	\N
4c9fd330-5ff1-4d36-ab88-13f51583c8c9	Espire Dental	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	161651479754963	2026-05-23 00:38:45.526779	2026-05-23 00:38:45.526779	Enterprise	\N	\N	Dental	2027-04-30	\N
e1ca9523-40f4-4df1-a844-7e01dc12f8ca	Schweiger Dermatology Group	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	170483380096645	2026-05-23 00:38:45.530402	2026-05-23 00:38:45.530402	Enterprise	\N	\N	Healthcare	2026-05-24	\N
b683819d-a733-4981-abdd-cfe405dcdaff	Discovery Behavioral Health	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	166863029349503	2026-05-23 00:38:45.533927	2026-05-23 00:38:45.533927	Enterprise	\N	\N	Healthcare	2026-06-27	\N
ada2fbaa-b6b4-4b21-99ff-da9c9e1653e0	InterDent	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	yellow	f	\N	\N	169964609052215	2026-05-23 00:38:45.537845	2026-05-23 00:38:45.537845	Enterprise	\N	\N	Dental	2026-06-18	\N
3825514e-3693-4bb9-bcf0-8612b464a977	Salt Dental	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	172866527572631	2026-05-23 00:38:45.542012	2026-05-23 00:38:45.542012	Enterprise	\N	\N	Dental	2027-07-31	\N
e6fea5be-ce1a-4d39-9130-9718944b28c7	VIVO Infusion	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	173401898710776	2026-05-23 00:38:45.545625	2026-05-23 00:38:45.545625	Enterprise	\N	\N	Healthcare	2026-06-09	\N
69968fda-c368-454c-a65a-8b64c5de6e7c	ABS Kids ABA Therapy Center	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	165513833236193	2026-05-23 00:38:45.54914	2026-05-23 00:38:45.54914	Enterprise	\N	\N	Healthcare	2026-06-29	\N
34c7f22e-4866-45a2-93e7-84f1129d3828	Radiology Partners	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	red	f	\N	\N	163718345948442	2026-05-23 00:38:45.55294	2026-05-23 00:38:45.55294	Enterprise	\N	\N	Healthcare	2026-06-30	\N
ad869f1d-4197-4eec-8096-12c58e373434	LifeStance Health Inc	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	yellow	f	\N	\N	165064943678183	2026-05-23 00:38:45.557065	2026-05-23 00:38:45.557065	Enterprise	\N	\N	Healthcare	2026-11-30	\N
a7081b9e-e464-4999-a59d-3efcb80db973	Rollins, Inc.	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	170253196506212	2026-05-23 00:38:45.560965	2026-05-23 00:38:45.560965	Enterprise	\N	\N	Home Services	2027-01-31	\N
84bdc7dc-7776-43de-820f-1a90b3d3fc1a	National Veterinary Associates, Inc.	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	yellow	f	\N	\N	150515828177007	2026-05-23 00:38:45.564945	2026-05-23 00:38:45.564945	Enterprise	\N	\N	Healthcare	2029-04-03	\N
b4bba017-4ad8-4135-9eea-31005daff1f0	National Storage Affiliates Trust	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	green	f	\N	\N	153816464014690	2026-05-23 00:38:45.568845	2026-05-23 00:38:45.568845	Enterprise	\N	\N	Consumer Services	2027-03-31	\N
0b696ba9-df20-47d8-a01a-21d72647a9ea	Kairoi Residential	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	yellow	f	\N	\N	150837789850462	2026-05-23 00:38:45.572694	2026-05-23 00:38:45.572694	Enterprise	\N	\N	Real Estate	2027-01-30	\N
76517250-2c03-43e2-87ff-c5b3d1c14b4f	American Pacific Mortgage	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	145875423866494	2026-05-23 00:38:45.576668	2026-05-23 00:38:45.576668	Enterprise	\N	\N	Finance	2027-02-01	\N
81bfd655-5869-47f7-8ab7-bc8e3b4eee1b	Equity LifeStyle Properties	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	yellow	f	\N	\N	174440484720974	2026-05-23 00:38:45.580458	2026-05-23 00:38:45.580458	Enterprise	\N	\N	Real Estate	2029-01-13	\N
22ca4c29-780b-489a-ba3c-0205fa2dc3fe	Rent-A-Center	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	167786581529965	2026-05-23 00:38:45.584611	2026-05-23 00:38:45.584611	Enterprise	\N	\N	Retail	2028-03-31	\N
db1b6768-a1a0-4dfb-8b8a-5a36282ee750	RingCentral Inc.	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	292151792	2026-05-23 00:38:45.58865	2026-05-23 00:38:45.58865	Enterprise	\N	\N	Technology	2027-05-20	\N
c425c131-858e-47de-821b-7487c05ba455	Fluidra North America	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	702740224	2026-05-23 00:38:45.593006	2026-05-23 00:38:45.593006	Enterprise	\N	\N	Home Services	2027-09-19	\N
d9200ec9-b2d5-446b-8c54-487b62a1aa35	Globe Life Inc.	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	149791251297789	2026-05-23 00:38:45.597475	2026-05-23 00:38:45.597475	Enterprise	\N	\N	Insurance	2028-03-29	\N
177cc096-7333-4167-8917-c345473902c1	US Dermatology Partners	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	yellow	f	\N	\N	149278516802012	2026-05-23 00:38:45.601943	2026-05-23 00:38:45.601943	Enterprise	\N	\N	Other	2027-01-13	\N
1070afd1-1d1d-41cb-bd67-f0d8771b64e7	Crossroads Treatment Centers	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	yellow	f	\N	\N	157627694635518	2026-05-23 00:38:45.606102	2026-05-23 00:38:45.606102	Enterprise	\N	\N	Healthcare	2027-04-30	\N
ff8ff68c-56fa-419a-83ab-837406953890	All My Sons Moving	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	159329522274581	2026-05-23 00:38:45.610133	2026-05-23 00:38:45.610133	Enterprise	\N	\N	Transportation Services	2026-11-29	\N
fad0f1d5-ac90-4c0f-8274-9bc7d4476571	The Michaels Organization	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	162947467023095	2026-05-23 00:38:45.614173	2026-05-23 00:38:45.614173	Enterprise	\N	\N	Real Estate	2027-10-05	\N
6e6ed583-61f7-4a0c-9e7a-575d4d49b2b9	Six Flags, LLC.	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	161550297006271	2026-05-23 00:38:45.618134	2026-05-23 00:38:45.618134	Enterprise	\N	\N	Recreation	2027-04-30	\N
f8309751-a120-4992-91f5-31419dab980b	Absolute Storage Management	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	yellow	f	\N	\N	166671172750117	2026-05-23 00:38:45.621845	2026-05-23 00:38:45.621845	Enterprise	\N	\N	Consumer Services	2029-03-31	\N
d99cc5dd-801d-44ef-929c-376a11d21d34	Zollege	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	171580754913664	2026-05-23 00:38:45.625769	2026-05-23 00:38:45.625769	Enterprise	\N	\N	Education	2027-12-20	\N
597caf1a-fcd1-4b08-a612-02103d6cb4c2	StoneCreek Communities	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	159850352576694	2026-05-23 00:38:45.629585	2026-05-23 00:38:45.629585	Enterprise	\N	\N	Real Estate	2026-11-08	\N
627d5f13-5dae-42d0-acc2-e0b4c6b24c52	Syufy Enterprises	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	172444785602448	2026-05-23 00:38:45.633066	2026-05-23 00:38:45.633066	Enterprise	\N	\N	Finance	2026-12-30	\N
058e50f0-0ecc-4d67-a694-6b4cfc66fd83	Stellar Service Brands	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	yellow	f	\N	\N	167762828479411	2026-05-23 00:38:45.6368	2026-05-23 00:38:45.6368	Enterprise	\N	\N	Contractors	2027-05-31	\N
fb6b9dff-438e-4487-83b6-ca12a2a7f4be	Berkshire Hathaway Automotive	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	173887616750943	2026-05-23 00:38:45.640831	2026-05-23 00:38:45.640831	Enterprise	\N	\N	Automotive	2027-08-30	\N
cf0aa062-8296-45cd-bea8-53b2ec9161a3	CWS Apartment Homes	123fd323-e46d-41aa-bf09-fc56e932efc2	\N	red	f	\N	\N	166542793666545	2026-05-23 00:38:45.644744	2026-05-23 00:38:45.644744	Enterprise	\N	\N	Real Estate	2026-12-15	\N
1d15f73b-e238-49d8-a1c7-65b34587af70	David's Bridal	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	red	f	\N	\N	147156432530912	2026-05-23 00:38:45.649352	2026-05-23 00:38:45.649352	Enterprise	\N	\N	Consumer Goods	2027-12-09	\N
e0a6b712-a57c-4d1d-9de6-a617d02c15c5	Erie Construction	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	red	f	\N	\N	158102510647273	2026-05-23 00:38:45.65346	2026-05-23 00:38:45.65346	Enterprise	\N	\N	Construction	2026-12-24	\N
8f998873-162d-44ee-944f-4142d6ad1745	Storage Asset Management	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	yellow	f	\N	\N	174171655395306	2026-05-23 00:38:45.656949	2026-05-23 00:38:45.656949	Enterprise	\N	\N	Real Estate	2026-12-29	\N
23d67881-522d-46df-ace2-d944597f6a2d	TruGreen Lawn Care	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	yellow	f	\N	\N	166455702916346	2026-05-23 00:38:45.660855	2026-05-23 00:38:45.660855	Enterprise	\N	\N	Home Services	2027-11-13	\N
ec222637-64f4-4b27-8ac2-dd0f2a553c75	AmeriGas	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	green	f	\N	\N	172600506420729	2026-05-23 00:38:45.665229	2026-05-23 00:38:45.665229	Enterprise	\N	\N	Home Services	2027-04-09	\N
4a992837-0445-4d20-9e01-8a28be3ff82d	Ned Stevens Gutter Cleaning	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	red	f	\N	\N	161098071311587	2026-05-23 00:38:45.669377	2026-05-23 00:38:45.669377	Enterprise	\N	\N	Contractors	2027-03-05	\N
c805d114-8b04-4901-b177-72f45bb6ba67	Star Group	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	red	f	\N	\N	152027060829502	2026-05-23 00:38:45.673076	2026-05-23 00:38:45.673076	Enterprise	\N	\N	Contractors	2026-12-18	\N
9b173405-da0c-4402-ab2f-56964f825a0f	Window Nation	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	yellow	f	\N	\N	163295411066298	2026-05-23 00:38:45.676714	2026-05-23 00:38:45.676714	Enterprise	\N	\N	Home Services	2028-03-30	\N
18cb25a4-e990-43f5-b6be-488089be33f5	Hudson Automotive Group	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	red	f	\N	\N	155631110066362	2026-05-23 00:38:45.680684	2026-05-23 00:38:45.680684	Enterprise	\N	\N	Automotive	2026-11-30	\N
651a58a5-92a7-490c-b76c-ff8bfaa805ef	Andover Properties LLC	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	red	f	\N	\N	168737941738721	2026-05-23 00:38:45.685227	2026-05-23 00:38:45.685227	Enterprise	\N	\N	Real Estate	2027-01-07	\N
325d97c3-4910-417f-bbcc-e58c4d4c0c9d	Flynn's Tire	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	yellow	f	\N	\N	167771454618602	2026-05-23 00:38:45.689136	2026-05-23 00:38:45.689136	Enterprise	\N	\N	Automotive	2027-03-23	\N
467ebd73-9ee8-4ecd-a803-8db0cb58fe4b	Lark Hotels	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	yellow	f	\N	\N	168996577847144	2026-05-23 00:38:45.693051	2026-05-23 00:38:45.693051	Enterprise	\N	\N	Hospitality	2026-06-30	\N
4600e81c-3529-4183-908a-081cbc40a8d3	Royal Farms	d016e3fd-343c-45ca-85f0-6b4d8e0935cb	\N	red	f	\N	\N	175132079741026	2026-05-23 00:38:45.696816	2026-05-23 00:38:45.696816	Enterprise	\N	\N	Retail	2026-11-14	\N
af6413c5-f4b8-46c4-a970-c511650937ff	Budget Brakes	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	169170529271289	2026-05-23 00:38:45.700896	2026-05-23 00:38:45.700896	Enterprise	\N	\N	Automotive	2027-08-31	\N
40d8d411-2f39-4710-b164-aeefdd7df8c7	Guardian Dentistry	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	157737092268571	2026-05-23 00:38:45.70461	2026-05-23 00:38:45.70461	Enterprise	\N	\N	Healthcare	2026-12-30	\N
d433dfce-0944-49f3-acd8-322a48fdbc2d	Hawthorn Senior Living	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	red	f	\N	\N	156138937337092	2026-05-23 00:38:45.708527	2026-05-23 00:38:45.708527	Enterprise	\N	\N	Real Estate	2027-01-30	\N
57fb63f3-ee84-4ae4-9c94-5386e37e6e60	Specialized Dental Partners	10c8305a-03b6-4447-9d00-5b37c7106240	\N	yellow	f	\N	\N	159794669480634	2026-05-23 00:38:45.712592	2026-05-23 00:38:45.712592	Enterprise	\N	\N	Healthcare	2026-09-27	\N
e3136e13-40b6-4427-abcf-65f7b58565c9	Forefront Dermatology	10c8305a-03b6-4447-9d00-5b37c7106240	\N	yellow	f	\N	\N	175762545522517	2026-05-23 00:38:45.716147	2026-05-23 00:38:45.716147	Enterprise	\N	\N	Healthcare	2027-10-31	\N
e106feb3-3ce1-431c-9e96-8d47b9b8668a	Osf Healthcare System	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	173757966029429	2026-05-23 00:38:45.719645	2026-05-23 00:38:45.719645	Enterprise	\N	\N	Healthcare	2029-09-30	\N
e1d73ec7-6f4a-416f-9291-aa18d74da460	D4C Dental Brands	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	150903535811972	2026-05-23 00:38:45.723362	2026-05-23 00:38:45.723362	Enterprise	\N	\N	Other	2027-02-03	\N
9762b1e7-9c8f-4a18-b2ae-7d01a6ebbf4c	DermCare Management	10c8305a-03b6-4447-9d00-5b37c7106240	\N	yellow	f	\N	\N	157479047240455	2026-05-23 00:38:45.727085	2026-05-23 00:38:45.727085	Enterprise	\N	\N	Healthcare	2026-12-26	\N
2455fbac-99e7-4222-88f5-0329055c6e0b	ATI Physical Therapy	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	172122936041317	2026-05-23 00:38:45.731051	2026-05-23 00:38:45.731051	Enterprise	\N	\N	Wellness	2028-01-30	\N
72766887-ef36-44b2-a9eb-5a6059cc52be	Pinnacle Dermatology	10c8305a-03b6-4447-9d00-5b37c7106240	\N	yellow	f	\N	\N	151784870532334	2026-05-23 00:38:45.73535	2026-05-23 00:38:45.73535	Enterprise	\N	\N	Healthcare	2027-02-23	\N
d477591b-970c-48b5-87f8-fbaf32b4c6e2	Smile Partners USA	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	156561271065049	2026-05-23 00:38:45.739215	2026-05-23 00:38:45.739215	Enterprise	\N	\N	Dental	2026-05-23	\N
3cd75db2-1800-4ab3-bb39-9739f532ccbf	Xpress Wellness Urgent Care	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	167406094540435	2026-05-23 00:38:45.742963	2026-05-23 00:38:45.742963	Enterprise	\N	\N	Healthcare	2027-02-27	\N
6efdbd8c-b0d2-4818-b81e-fc055078ae58	Gentiva	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	169522723044470	2026-05-23 00:38:45.746715	2026-05-23 00:38:45.746715	Enterprise	\N	\N	Healthcare	2027-06-30	\N
29a8b73f-fcbb-47a8-aa18-1f6dceaafa5a	AmeriVet Veterinary Partners	10c8305a-03b6-4447-9d00-5b37c7106240	\N	yellow	f	\N	\N	165229363692308	2026-05-23 00:38:45.750491	2026-05-23 00:38:45.750491	Enterprise	\N	\N	Healthcare	2026-07-18	\N
d3450b9d-dd1e-4458-a4f1-48c6ccaf0a72	Balance Health	10c8305a-03b6-4447-9d00-5b37c7106240	\N	yellow	f	\N	\N	171657906779828	2026-05-23 00:38:45.754317	2026-05-23 00:38:45.754317	Enterprise	\N	\N	Healthcare	2028-03-31	\N
f061ba2a-67d8-4dcf-9e32-5da8355f5033	Aqua Dermatology	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	156146852812443	2026-05-23 00:38:45.758372	2026-05-23 00:38:45.758372	Enterprise	\N	\N	Healthcare	2026-06-18	\N
74c6bfcb-b3f3-45d0-bc24-c4054932f491	Urban Self Storage	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	158327492553450	2026-05-23 00:38:45.762229	2026-05-23 00:38:45.762229	Enterprise	\N	\N	Consumer Services	2028-05-28	\N
18d06e88-d6bf-4a44-b14a-7867730299f3	Geode Health	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	164555197257490	2026-05-23 00:38:45.766603	2026-05-23 00:38:45.766603	Enterprise	\N	\N	Healthcare	2026-07-31	\N
4661d28c-511a-4438-927f-a247adbf73bd	123Dentist	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	169844524872130	2026-05-23 00:38:45.771219	2026-05-23 00:38:45.771219	Enterprise	\N	\N	Dental	2026-09-30	\N
4c71cacd-fd55-4a30-bfdb-8d0aab1d18a8	Heartland Veterinary Partners	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	155977000829267	2026-05-23 00:38:45.775557	2026-05-23 00:38:45.775557	Enterprise	\N	\N	Healthcare	2027-02-28	\N
772c9f8c-9690-4596-b9be-bf0084e7b862	Arrow Senior Living	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	172746803226934	2026-05-23 00:38:45.779168	2026-05-23 00:38:45.779168	Enterprise	\N	\N	Wellness	2026-10-31	\N
4b001c0d-f010-4998-bae3-836f05d8c634	Georgia Urology	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	170258340411550	2026-05-23 00:38:45.783031	2026-05-23 00:38:45.783031	Enterprise	\N	\N	Healthcare	2027-05-05	\N
16aa2494-b78d-4ec1-8d20-877edb1465e6	Mindpath Health	10c8305a-03b6-4447-9d00-5b37c7106240	\N	red	f	\N	\N	160683787034392	2026-05-23 00:38:45.787212	2026-05-23 00:38:45.787212	Enterprise	\N	\N	Healthcare	2026-06-30	\N
fab338b4-d094-45da-9822-4e7085f71ebd	PREG Management, LLC	bbff08b2-dd93-4559-b5b8-4ac3855b6b56	\N	yellow	f	\N	\N	172736633019507	2026-05-23 00:38:45.791295	2026-05-23 00:38:45.791295	Enterprise	\N	\N	Real Estate	2026-10-30	\N
80e945f7-871c-40c7-b262-a04ea330ce24	The William Warren Group (StorQuest)	bbff08b2-dd93-4559-b5b8-4ac3855b6b56	\N	yellow	f	\N	\N	175139823628028	2026-05-23 00:38:45.795215	2026-05-23 00:38:45.795215	Enterprise	\N	\N	Real Estate	2027-12-28	\N
492f2338-977f-4c8d-9244-1e3714643ce3	Devon Self Storage Holdings, LLC	bbff08b2-dd93-4559-b5b8-4ac3855b6b56	\N	red	f	\N	\N	153062862219350	2026-05-23 00:38:45.79913	2026-05-23 00:38:45.79913	Enterprise	\N	\N	Consumer Services	2026-12-13	\N
642b9281-02f4-4895-9f02-64ff7179ed8d	Essex	bbff08b2-dd93-4559-b5b8-4ac3855b6b56	\N	red	f	\N	\N	155750897907327	2026-05-23 00:38:45.803285	2026-05-23 00:38:45.803285	Enterprise	\N	\N	Real Estate	2029-01-30	\N
37ad854e-71d1-4802-822a-243a03af9dff	Idaho Central Credit Union	bbff08b2-dd93-4559-b5b8-4ac3855b6b56	\N	red	f	\N	\N	156683109799763	2026-05-23 00:38:45.807011	2026-05-23 00:38:45.807011	Enterprise	\N	\N	Other	2027-10-31	\N
8f74a7d3-9b0d-4413-8113-f8e571ae6f81	Sun Auto Tire & Service, Inc.	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	168858610231682	2026-05-23 00:38:45.811136	2026-05-23 00:38:45.811136	Enterprise	\N	\N	Automotive	2027-11-26	\N
f9580e64-daf0-4126-8746-ee8a7757b6eb	H&R Block	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	yellow	f	\N	\N	174119138493502	2026-05-23 00:38:45.815155	2026-05-23 00:38:45.815155	Enterprise	\N	\N	Finance	2026-07-01	\N
f12d2e8e-f59b-4eeb-ad0b-3b6366873ffe	Dave's Hot Chicken	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	159726269368132	2026-05-23 00:38:45.818763	2026-05-23 00:38:45.818763	Enterprise	\N	\N	Restaurants	2026-08-22	\N
4fe422a9-ac1e-4cfb-8f12-78299aee377b	Prime Storage	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	161523890160899	2026-05-23 00:38:45.823011	2026-05-23 00:38:45.823011	Enterprise	\N	\N	Consumer Services	2026-05-24	\N
2a24e196-fc55-4d5f-91ba-13598a55fcd6	Guaranteed Rate , Inc.	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	157416811183557	2026-05-23 00:38:45.827754	2026-05-23 00:38:45.827754	Enterprise	\N	\N	Finance	2026-07-31	\N
47d9c135-8c5d-4db7-822b-de34ff70b9a7	Great Day Improvements	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	160397593471085	2026-05-23 00:38:45.831633	2026-05-23 00:38:45.831633	Enterprise	\N	\N	Contractors	2026-12-27	\N
384de25c-d57c-49ef-a32d-6e8889d1650a	PENNYMAC	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	164969017231473	2026-05-23 00:38:45.836075	2026-05-23 00:38:45.836075	Enterprise	\N	\N	Finance	2026-08-29	\N
4520708b-9ef9-40d6-959f-79ad48089889	Cornerstone Home Lending, Inc.	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	147155093441427	2026-05-23 00:38:45.840057	2026-05-23 00:38:45.840057	Enterprise	\N	\N	Finance	2029-01-16	\N
8a6249a6-02b7-416e-be18-ebac3cd68bd7	Arhaus LLC	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	yellow	f	\N	\N	156277691932713	2026-05-23 00:38:45.843986	2026-05-23 00:38:45.843986	Enterprise	\N	\N	Retail	2027-01-07	\N
5503db73-05e9-4767-9a32-d9336ccd6541	BH Management Services	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	yellow	f	\N	\N	171139464642150	2026-05-23 00:38:45.848046	2026-05-23 00:38:45.848046	Enterprise	\N	\N	Real Estate	2026-10-15	\N
465d3165-ee6e-4c29-9b28-76d995099c05	Stewart Title	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	163716804227374	2026-05-23 00:38:45.852401	2026-05-23 00:38:45.852401	Enterprise	\N	\N	Finance	2029-03-15	\N
fe331f29-e01e-44fa-afef-b3a4aa3d11fd	Waste Management National Services, Inc.	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	168658681020733	2026-05-23 00:38:45.856848	2026-05-23 00:38:45.856848	Enterprise	\N	\N	Home Services	2028-01-01	\N
26ac3512-b5ef-401b-b2ca-f2cdd0efc546	The Woda Cooper Companies	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	152466635184856	2026-05-23 00:38:45.861107	2026-05-23 00:38:45.861107	Enterprise	\N	\N	Real Estate	2027-06-30	\N
6aca1400-d16e-422e-9e0e-a77a9ecf8da7	Independence Realty Trust, Inc.	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	yellow	f	\N	\N	171933250083831	2026-05-23 00:38:45.865526	2026-05-23 00:38:45.865526	Enterprise	\N	\N	Real Estate	2026-12-30	\N
7b93fee8-c72d-4d39-bd63-f071e173289d	Elmington Property Management	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	171278257576996	2026-05-23 00:38:45.870389	2026-05-23 00:38:45.870389	Enterprise	\N	\N	Real Estate	2026-11-30	\N
2e08e907-23e9-48ef-8362-dac8e2fea443	Compass Self Storage	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	162327708617444	2026-05-23 00:38:45.87427	2026-05-23 00:38:45.87427	Enterprise	\N	\N	Other	2027-12-30	\N
14cba174-37ff-4959-ba08-f84c276bb36c	Club4 Fitness	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	171397319810665	2026-05-23 00:38:45.878544	2026-05-23 00:38:45.878544	Enterprise	\N	\N	Recreation	2026-08-31	\N
4bcb65b6-849f-462d-9ccb-817e47ecc9a9	Magnolia Capital	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	159544892155371	2026-05-23 00:38:45.882841	2026-05-23 00:38:45.882841	Enterprise	\N	\N	Real Estate	2026-08-13	\N
d721f60f-80fd-4fd4-890a-557c4d7b365e	Sterling Group	2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	\N	red	f	\N	\N	157073336799859	2026-05-23 00:38:45.887451	2026-05-23 00:38:45.887451	Enterprise	\N	\N	Contractors	2027-06-23	\N
cb462ff0-ce6f-4b50-a953-7208c1c1d2b8	BluePearl	d3fd524d-5854-47ff-aaac-ed9b3066b2b4	\N	yellow	f	\N	\N	161884854350873	2026-05-23 00:38:45.892056	2026-05-23 00:38:45.892056	Enterprise	\N	\N	Healthcare	2028-02-15	\N
473cb5c1-d1e1-46d9-bc11-3ba4420fd9aa	Sarasota Memorial Health Care System	d3fd524d-5854-47ff-aaac-ed9b3066b2b4	\N	green	f	\N	\N	174595538829142	2026-05-23 00:38:45.895864	2026-05-23 00:38:45.895864	Enterprise	\N	\N	Healthcare	2030-01-30	\N
62b1e732-47ff-43bc-82bc-9e678a222074	Dentalcorp	d3fd524d-5854-47ff-aaac-ed9b3066b2b4	\N	yellow	f	\N	\N	170058655709872	2026-05-23 00:38:45.89952	2026-05-23 00:38:45.89952	Enterprise	\N	\N	Healthcare	2027-12-01	\N
b124e507-b3f7-49a3-86bd-4809db6841e4	42 North Dental	d3fd524d-5854-47ff-aaac-ed9b3066b2b4	\N	red	f	\N	\N	164444207123201	2026-05-23 00:38:45.903855	2026-05-23 00:38:45.903855	Enterprise	\N	\N	Dental	2026-12-28	\N
f404c9d4-8bd2-467e-90f0-f18ca1f306e9	The Dermatology Specialists	d3fd524d-5854-47ff-aaac-ed9b3066b2b4	\N	yellow	f	\N	\N	151207373518104	2026-05-23 00:38:45.908197	2026-05-23 00:38:45.908197	Enterprise	\N	\N	Healthcare	2026-11-30	\N
7b3e7e47-e976-4709-b165-97d50bc34b82	Capital Digestive Care	d3fd524d-5854-47ff-aaac-ed9b3066b2b4	\N	red	f	\N	\N	168754018268503	2026-05-23 00:38:45.912248	2026-05-23 00:38:45.912248	Enterprise	\N	\N	Healthcare	2027-11-01	\N
543c0866-37f2-4e3a-b995-ce65c5b74b9d	Bayada Home Health Care, Inc.	d3fd524d-5854-47ff-aaac-ed9b3066b2b4	\N	red	f	\N	\N	153438874208219	2026-05-23 00:38:45.915838	2026-05-23 00:38:45.915838	Enterprise	\N	\N	Healthcare	2029-01-01	\N
3a971b4a-79af-41c9-a186-ea29a10de75b	Axia Women's Health	d3fd524d-5854-47ff-aaac-ed9b3066b2b4	\N	yellow	f	\N	\N	157963708248888	2026-05-23 00:38:45.919631	2026-05-23 00:38:45.919631	Enterprise	\N	\N	Healthcare	2027-01-31	\N
c9cfaebb-48e7-4720-ad4e-6de428e9ec74	Transformations Care Network	d3fd524d-5854-47ff-aaac-ed9b3066b2b4	\N	red	f	\N	\N	166880822713586	2026-05-23 00:38:45.924609	2026-05-23 00:38:45.924609	Enterprise	\N	\N	Healthcare	2026-06-26	\N
88ec3b10-75c9-4b88-9e4d-fdbc4c934f60	Clearway Pain Solutions	d3fd524d-5854-47ff-aaac-ed9b3066b2b4	\N	red	f	\N	\N	155257395650239	2026-05-23 00:38:45.92847	2026-05-23 00:38:45.92847	Enterprise	\N	\N	Healthcare	2027-02-28	\N
6c6b5055-3ed3-4cb0-a38a-746e0b2b4b6b	Motto Mortgage	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	red	f	\N	\N	161055950321175	2026-05-23 00:38:45.932611	2026-05-23 00:38:45.932611	Enterprise	\N	\N	Finance	2028-03-31	\N
ff5ad0b7-f678-4310-9b70-c2bb67231d7e	Greenix Pest Control	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	yellow	f	\N	\N	161840754354372	2026-05-23 00:38:45.936598	2026-05-23 00:38:45.936598	Enterprise	\N	\N	Home Services	2028-04-30	\N
7168d01f-c59b-4ed3-bd9b-abe91547dd17	Ferrellgas	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	yellow	f	\N	\N	174914656344530	2026-05-23 00:38:45.940589	2026-05-23 00:38:45.940589	Enterprise	\N	\N	Home Services	2026-07-01	\N
7a362d9d-375d-45d1-9eb5-d370339b8f20	Wild Bill's Tobacco	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	yellow	f	\N	\N	166697857311871	2026-05-23 00:38:45.944204	2026-05-23 00:38:45.944204	Enterprise	\N	\N	Retail	2027-10-04	\N
e8d35d05-2dc0-4dd8-8a5e-c5a0b54d8315	Mutual of Omaha Mortgage	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	yellow	f	\N	\N	173324101206246	2026-05-23 00:38:45.94847	2026-05-23 00:38:45.94847	Enterprise	\N	\N	Finance	2028-08-30	\N
a624519c-e62c-419f-ac32-ce31635394d8	PRMI	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	yellow	f	\N	\N	159984204853485	2026-05-23 00:38:45.952324	2026-05-23 00:38:45.952324	Enterprise	\N	\N	Finance	2028-06-20	\N
a010052f-75ed-41ca-a96a-cd33fe0ed21f	Goldenwest Credit Union	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	yellow	f	\N	\N	165064914073131	2026-05-23 00:38:45.956235	2026-05-23 00:38:45.956235	Enterprise	\N	\N	Finance	2026-08-06	\N
3c473112-601d-4969-8e49-8a36de2af27e	Stellar Senior Living	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	yellow	f	\N	\N	173332588620406	2026-05-23 00:38:45.960074	2026-05-23 00:38:45.960074	Enterprise	\N	\N	Wellness	2027-01-27	\N
3750ab4d-857d-420d-a80e-6045148c6d91	Americare Senior Living	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	yellow	f	\N	\N	161965369891041	2026-05-23 00:38:45.963692	2026-05-23 00:38:45.963692	Enterprise	\N	\N	Wellness	2027-09-13	\N
ef779ebf-f354-483c-a878-e7692ec70138	America First	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	yellow	f	\N	\N	172963404325685	2026-05-23 00:38:45.967475	2026-05-23 00:38:45.967475	Enterprise	\N	\N	Finance	2026-12-31	\N
a85c30ff-458a-42bb-9cd0-5e1096c6b72c	Radiance Holdings	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	red	f	\N	\N	165881038244984	2026-05-23 00:38:45.971509	2026-05-23 00:38:45.971509	Enterprise	\N	\N	Beauty	2026-07-31	\N
1bc14c2c-d0b7-4fee-b566-1406ef816abb	Black Bear Diner	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	yellow	f	\N	\N	146680023962849	2026-05-23 00:38:45.975427	2026-05-23 00:38:45.975427	Enterprise	\N	\N	Restaurants	2026-12-30	\N
ef2cde30-83d4-4e80-97f7-45f1722e9728	Rosati's Chicago Pizza	e4dca8e2-d48c-4e6b-9728-39345143876c	\N	yellow	f	\N	\N	155423153020941	2026-05-23 00:38:45.979282	2026-05-23 00:38:45.979282	Enterprise	\N	\N	Restaurants	2027-09-29	\N
55e0a685-1ac1-471a-b03b-27beaf716861	Bluebird Care	1c36db24-ef04-4f47-a214-2a2b7c7f930d	\N	red	f	\N	\N	175024020098640	2026-05-23 00:38:45.983014	2026-05-23 00:38:45.983014	Enterprise	\N	\N	Healthcare	2028-12-12	\N
43c99d67-aa63-4be7-8172-5beccc427430	Weill Cornell Medicine	02a5f706-3275-4670-bc93-1d0f670799ba	\N	yellow	f	\N	\N	146724531835545	2026-05-23 00:38:45.995437	2026-05-23 00:38:45.995437	Enterprise	\N	\N	Healthcare	2026-08-07	\N
d43d26bf-45c7-4c96-8b8b-7755b8a606c6	Thrive Pet Healthcare	02a5f706-3275-4670-bc93-1d0f670799ba	\N	yellow	f	\N	\N	157920766989525	2026-05-23 00:38:45.999674	2026-05-23 00:38:45.999674	Enterprise	\N	\N	Healthcare	2027-12-29	\N
4589c39f-85c1-4529-8d85-2985bfe7a54f	American Home Shield	02a5f706-3275-4670-bc93-1d0f670799ba	\N	red	f	\N	\N	144589382164705	2026-05-23 00:38:46.004455	2026-05-23 00:38:46.004455	Enterprise	\N	\N	Insurance	2026-12-31	\N
a944bd42-9ce3-420e-a0c8-72d783227f8f	Cracker Barrel	02a5f706-3275-4670-bc93-1d0f670799ba	\N	yellow	f	\N	\N	168994713468800	2026-05-23 00:38:46.008465	2026-05-23 00:38:46.008465	Enterprise	\N	\N	Restaurants	2026-06-27	\N
4bc238d2-9658-4af6-953e-3c53d515f059	Smile Brands	02a5f706-3275-4670-bc93-1d0f670799ba	\N	red	f	\N	\N	157125653333153	2026-05-23 00:38:46.012662	2026-05-23 00:38:46.012662	Enterprise	\N	\N	Dental	2026-06-28	\N
e70b68b7-1ec6-4f6a-8d5f-233bc8f56f04	Great Expressions Dental Centers	02a5f706-3275-4670-bc93-1d0f670799ba	\N	red	f	\N	\N	164210923178141	2026-05-23 00:38:46.016738	2026-05-23 00:38:46.016738	Enterprise	\N	\N	Dental	2027-10-30	\N
8e9b7896-d035-4414-ac83-eb7b630a5e09	Caesars Entertainment	02a5f706-3275-4670-bc93-1d0f670799ba	\N	red	f	\N	\N	149936873412006	2026-05-23 00:38:46.020277	2026-05-23 00:38:46.020277	Enterprise	\N	\N	Hospitality	2027-09-30	\N
1db9ec11-ce31-4a59-90ab-3b69483752ff	TotalCare Emergency Room	02a5f706-3275-4670-bc93-1d0f670799ba	\N	red	f	\N	\N	160528244249981	2026-05-23 00:38:46.024295	2026-05-23 00:38:46.024295	Enterprise	\N	\N	Healthcare	2028-01-14	\N
1cfbf645-2675-4677-a513-757fc9542ce8	Altus Community Healthcare	02a5f706-3275-4670-bc93-1d0f670799ba	\N	red	f	\N	\N	156658923047905	2026-05-23 00:38:46.02804	2026-05-23 00:38:46.02804	Enterprise	\N	\N	Healthcare	2026-06-14	\N
6c52550c-9794-4071-bcf8-aea9a170627d	AllerVie Health	02a5f706-3275-4670-bc93-1d0f670799ba	\N	red	f	\N	\N	163293149676967	2026-05-23 00:38:46.032209	2026-05-23 00:38:46.032209	Enterprise	\N	\N	Healthcare	2027-12-30	\N
7301e257-1f20-495d-a4f3-f16e58dce7dc	Veterinary Practice Partners	02a5f706-3275-4670-bc93-1d0f670799ba	\N	red	f	\N	\N	165999001525943	2026-05-23 00:38:46.035742	2026-05-23 00:38:46.035742	Enterprise	\N	\N	Healthcare	2027-07-30	\N
699aaed7-0f7c-4359-8a8a-705932e9f5b1	Epiphany Dermatology	02a5f706-3275-4670-bc93-1d0f670799ba	\N	red	f	\N	\N	162002430771083	2026-05-23 00:38:46.039222	2026-05-23 00:38:46.039222	Enterprise	\N	\N	Healthcare	2028-09-30	\N
f0777ff5-6830-4fa1-9c22-97f1ac51069a	Mortgage Choice	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	red	f	\N	\N	149210048607227	2026-05-23 00:38:46.043201	2026-05-23 00:38:46.043201	Enterprise	\N	\N	Finance	2027-05-30	\N
82736750-e7aa-4a74-83da-3d97d74b180f	VetPartners AU	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	red	f	\N	\N	156901591761483	2026-05-23 00:38:46.047043	2026-05-23 00:38:46.047043	Enterprise	\N	\N	Healthcare	2026-09-07	\N
0f8e64ec-39bc-4b49-9c13-29532e7bef23	Poolwerx Corporation AUNZ	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	red	f	\N	\N	168694430709641	2026-05-23 00:38:46.050906	2026-05-23 00:38:46.050906	Enterprise	\N	\N	Home Services	2026-03-31	\N
4dd1372b-e08c-4400-a327-a47183216939	Wesfarmers Health Division	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	174953884882915	2026-05-23 00:38:46.05476	2026-05-23 00:38:46.05476	Enterprise	\N	\N	Wellness	2029-01-11	\N
ff35f1c7-5380-44f4-b343-89167c3236dc	Ekera Dental	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	173706187169934	2026-05-23 00:38:46.058573	2026-05-23 00:38:46.058573	Enterprise	\N	\N	Dental	2026-09-01	\N
5f933266-b288-4c89-bdb5-4bfab0d7ac16	Property Franchise Group	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	red	f	\N	\N	1759818471043003	2026-05-23 00:38:46.062558	2026-05-23 00:38:46.062558	Enterprise	\N	\N	Real Estate	2026-12-28	\N
7b7a7eca-c2a4-48a3-9d1f-0ef1dfa5849a	Sushi Daily	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	red	f	\N	\N	1758730197812223	2026-05-23 00:38:46.066769	2026-05-23 00:38:46.066769	Enterprise	\N	\N	Restaurants	2026-12-19	\N
a5bd0afa-e370-45d7-8b04-31fd97acbe5e	Mister Minit Europe	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	green	f	\N	\N	177264218444429	2026-05-23 00:38:46.070945	2026-05-23 00:38:46.070945	Enterprise	\N	\N	Consumer Services	2029-04-30	\N
bde01813-fc8b-44f6-a8bf-6427baf4e680	Emeria UK	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	yellow	f	\N	\N	1767619318181153	2026-05-23 00:38:46.075053	2026-05-23 00:38:46.075053	Enterprise	\N	\N	Real Estate	2028-01-29	\N
c4c679c3-f389-4e23-aa8d-6f01690c292d	The Westover Companies	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	green	f	\N	\N	165850355651259	2026-05-23 00:38:46.079027	2026-05-23 00:38:46.079027	Enterprise	\N	\N	Real Estate	2026-06-01	\N
ff67c963-9422-4df7-9764-a8714b9227a1	Fast Pace Urgent Care	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	161883507546224	2026-05-23 00:38:46.083363	2026-05-23 00:38:46.083363	Enterprise	\N	\N	Healthcare	2027-04-01	\N
e3a50492-3c6a-4d89-84ac-2b6da2c084a1	Acadia Healthcare	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	156216610479400	2026-05-23 00:38:46.087632	2026-05-23 00:38:46.087632	Enterprise	\N	\N	Healthcare	2026-12-06	\N
b7b2aedd-4947-4fbc-b5e6-4da67f89c91c	Mydentist	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	170499033908552	2026-05-23 00:38:46.092234	2026-05-23 00:38:46.092234	Enterprise	\N	\N	Dental	2029-05-12	\N
29f90d7f-2b02-4ed9-92f0-c26c3ca93d28	WellStreet	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	160148749223742	2026-05-23 00:38:46.096175	2026-05-23 00:38:46.096175	Enterprise	\N	\N	Healthcare	2026-09-30	\N
786aa3fb-5243-4c13-9052-c8f6b0538aa6	Encompass Health Corporation	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	green	f	\N	\N	175510421326756	2026-05-23 00:38:46.099736	2026-05-23 00:38:46.099736	Enterprise	\N	\N	Healthcare	2029-05-15	\N
b0487a92-7bc4-454e-98f8-f8d63a40f40c	Rock Dental Brands	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	167716743666663	2026-05-23 00:38:46.103414	2026-05-23 00:38:46.103414	Enterprise	\N	\N	Dental	2027-03-30	\N
090fe0a2-9c73-4936-829b-5728407a5711	Innovative Renal Care	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	170483355074478	2026-05-23 00:38:46.107196	2026-05-23 00:38:46.107196	Enterprise	\N	\N	Healthcare	2026-06-29	\N
78024857-0666-4400-9cb6-3141b1226def	Atria Management Company LLC	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	174052234430123	2026-05-23 00:38:46.11075	2026-05-23 00:38:46.11075	Enterprise	\N	\N	Wellness	2028-05-31	\N
b86708e4-b942-4ae4-9bd7-1bccf8e5c0bd	Lumexa Imaging	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	yellow	f	\N	\N	157081547792501	2026-05-23 00:38:46.114547	2026-05-23 00:38:46.114547	Enterprise	\N	\N	Healthcare	2026-06-06	\N
9dc6ed27-5d39-46cb-b5f5-341357ca9544	Village Pet Care	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	169030216166956	2026-05-23 00:38:46.118398	2026-05-23 00:38:46.118398	Enterprise	\N	\N	Healthcare	2026-10-16	\N
b442fd09-80c5-4170-a8f7-1620f13a88ad	Daymark Recovery Services, Inc	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	168487391209026	2026-05-23 00:38:46.122261	2026-05-23 00:38:46.122261	Enterprise	\N	\N	Healthcare	2026-10-18	\N
9baba783-a385-4e83-bb4d-b64d48f6d99a	Advantia Health	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	159836925884329	2026-05-23 00:38:46.12574	2026-05-23 00:38:46.12574	Enterprise	\N	\N	Healthcare	2027-03-06	\N
50847cb3-44d7-4a31-a2c2-2c40475739ac	Greenbrook TMS	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	156881555433788	2026-05-23 00:38:46.129606	2026-05-23 00:38:46.129606	Enterprise	\N	\N	Healthcare	2027-07-01	\N
d4a7fb9e-503f-4a73-99a1-a312d21925dc	Advantage Dental+	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	168735581539581	2026-05-23 00:38:46.133618	2026-05-23 00:38:46.133618	Enterprise	\N	\N	Dental	2026-10-30	\N
900e3460-5994-4da7-b1d0-938c248b5774	FastMed	03794424-77ef-42aa-b8fb-2d1f6cb17114	\N	red	f	\N	\N	152780528097862	2026-05-23 00:38:46.137334	2026-05-23 00:38:46.137334	Enterprise	\N	\N	Healthcare	2027-12-05	\N
83492b1d-7505-422c-a676-0f0b196d9431	Retina Consultants San Diego	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	green	f	\N	\N	164995787907313	2026-05-23 00:55:23.473538	2026-05-23 00:55:23.473538	Professional	\N	\N	Healthcare	2027-04-28	\N
933e5065-8bd8-42d9-a4e3-09439b607ca3	The Management Group LLC	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	green	f	\N	\N	172736622963127	2026-05-23 00:55:23.481087	2026-05-23 00:55:23.481087	Professional	\N	\N	Real Estate	2026-10-15	\N
0b813e82-73d6-4e1c-8ebd-3389b36bd338	Baldino's Lock & Key	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	162093978453089	2026-05-23 00:55:23.485326	2026-05-23 00:55:23.485326	Professional	\N	\N	Home Services	2026-08-16	\N
f7395e83-8559-452c-9d51-62dedaff7894	Ward Tirecraft	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	166092173754002	2026-05-23 00:55:23.489673	2026-05-23 00:55:23.489673	Professional	\N	\N	Automotive	2028-11-17	\N
62871cfe-9a8f-4dff-b04d-4021b50d9edc	Edward Beiner	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	red	f	\N	\N	174544898262558	2026-05-23 00:55:23.493867	2026-05-23 00:55:23.493867	Professional	\N	\N	Healthcare	2026-05-23	\N
7a72d83f-1c45-41fd-a072-b5209f1fde31	ServiceTitan	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	167707687372792	2026-05-23 00:55:23.498233	2026-05-23 00:55:23.498233	Professional	\N	\N	Business Services	2027-05-08	\N
7d4d7a46-be30-45af-94d6-f66c79b11e53	Allworth Financial	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	175803127980899	2026-05-23 00:55:23.502571	2026-05-23 00:55:23.502571	Professional	\N	\N	Finance	2026-09-30	\N
5c49dc18-55c1-45eb-bbd4-a8cfa3e29c5a	Vanderbilt Mortgage and Finance Inc	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	158099993867462	2026-05-23 00:55:23.506224	2026-05-23 00:55:23.506224	Professional	\N	\N	Finance	2026-07-16	\N
183a00a4-c739-48ac-84e1-287e392b92e7	Inspire Veterinary Partners	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	173887718278948	2026-05-23 00:55:23.510998	2026-05-23 00:55:23.510998	Professional	\N	\N	Healthcare	2027-02-19	\N
629f1614-c87b-4fd8-804d-35f75fdf038f	American Addiction Centers Inc	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	156088384784267	2026-05-23 00:55:23.515004	2026-05-23 00:55:23.515004	Professional	\N	\N	Healthcare	2026-08-29	\N
8c843037-9245-4878-966e-50de59eed768	Integrity Realty Group	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	green	f	\N	\N	168303484714400	2026-05-23 00:55:23.519192	2026-05-23 00:55:23.519192	Professional	\N	\N	Real Estate	2026-07-31	\N
de3e9a6a-a8d1-4a83-92f9-9484e3a8a1e5	Wolfe Automotive	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	164987900596133	2026-05-23 00:55:23.523676	2026-05-23 00:55:23.523676	Professional	\N	\N	Automotive	2026-06-06	\N
57ba141e-076f-4994-b8b0-45992e819519	Cormorant Company, Inc.	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	172730129555866	2026-05-23 00:55:23.527769	2026-05-23 00:55:23.527769	Professional	\N	\N	Real Estate	2026-07-28	\N
dcd062dc-7709-4e38-951b-d10ecab7bc93	Connections Wellness Group	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	167120458482269	2026-05-23 00:55:23.531743	2026-05-23 00:55:23.531743	Professional	\N	\N	Healthcare	2026-12-27	\N
18441d0e-ba27-4292-aa3b-fedca7300a52	Civitas Senior Living	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	green	f	\N	\N	153485913301746	2026-05-23 00:55:23.535847	2026-05-23 00:55:23.535847	Professional	\N	\N	Wellness	2026-10-05	\N
7628d5f7-93ec-47d4-9240-22702c80eedd	Gulf Coast Bank	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	green	f	\N	\N	175451141274116	2026-05-23 00:55:23.539775	2026-05-23 00:55:23.539775	Professional	\N	\N	Finance	2028-11-28	\N
db14d47d-ddf0-4968-9c10-8973fe2f4181	Law Offices of Charles R Frazier	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	150843556860273	2026-05-23 00:55:23.543635	2026-05-23 00:55:23.543635	Professional	\N	\N	Legal	2026-10-25	\N
2037f62d-d618-4dac-b54c-b781c41453be	Sharp Management	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	170585759396566	2026-05-23 00:55:23.548744	2026-05-23 00:55:23.548744	Professional	\N	\N	Real Estate	2027-03-21	\N
b6c9ee28-af87-4df7-96ea-93ef6119b95c	Nurse Next Door	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	170483369246903	2026-05-23 00:55:23.552532	2026-05-23 00:55:23.552532	Professional	\N	\N	Healthcare	2026-09-07	\N
3bf0c3ec-6d44-4a61-a6e9-473e1302a665	Lee Company	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	154421243798102	2026-05-23 00:55:23.55609	2026-05-23 00:55:23.55609	Professional	\N	\N	Contractors	2027-09-30	\N
58504d93-1342-41ad-a41b-148e57f864c5	Revel Communities	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	green	f	\N	\N	169403731597024	2026-05-23 00:55:23.559717	2026-05-23 00:55:23.559717	Professional	\N	\N	Real Estate	2026-07-29	\N
5ab6c81c-2d14-4a65-810b-5da5a80384c0	J.K. Residential Services, Inc.	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	173748543666463	2026-05-23 00:55:23.563646	2026-05-23 00:55:23.563646	Professional	\N	\N	Real Estate	2027-02-27	\N
2a96976e-0a23-42fa-aa34-90a8f14f5a29	Comcap Management	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	157064931084387	2026-05-23 00:55:23.568563	2026-05-23 00:55:23.568563	Professional	\N	\N	Real Estate	2027-01-26	\N
5926a1de-ce3c-4e6b-8225-9962e09add96	FOUND Study Management, LLC	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	175578523457300	2026-05-23 00:55:23.572385	2026-05-23 00:55:23.572385	Professional	\N	\N	Real Estate	2026-10-28	\N
15311008-8c6d-4e56-9a7a-a37a37231520	RW Supply + Design	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	green	f	\N	\N	175214844633286	2026-05-23 00:55:23.576472	2026-05-23 00:55:23.576472	Professional	\N	\N	Home Services	2027-07-30	\N
56b87c4d-950e-4f14-93ac-f6169d8d8210	Amazing Care Home Health Services LLC	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	169902613942155	2026-05-23 00:55:23.580999	2026-05-23 00:55:23.580999	Professional	\N	\N	Healthcare	2027-12-30	\N
01f1a850-ae58-4fe6-a6a6-63f130cf3214	T.R. Mckenzie Apartments	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	176176562005095	2026-05-23 00:55:23.584965	2026-05-23 00:55:23.584965	Professional	\N	\N	Real Estate	2026-10-31	\N
8262b524-670e-4f30-933d-91365c404835	Monarch	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	167958946876206	2026-05-23 00:55:23.58894	2026-05-23 00:55:23.58894	Professional	\N	\N	Healthcare	2026-06-26	\N
c5ff8059-3252-40d1-85b1-450a5c9ec615	Firstmark Credit Union	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	156026694947621	2026-05-23 00:55:23.59311	2026-05-23 00:55:23.59311	Professional	\N	\N	Finance	2026-09-29	\N
e4bb0341-ffa4-4c8d-b9a3-5a93e41b34c7	Urgent Team	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	green	f	\N	\N	163650011134757	2026-05-23 00:55:23.597039	2026-05-23 00:55:23.597039	Professional	\N	\N	Healthcare	2027-12-23	\N
62f2b8ad-b828-4873-8f9f-c3f6f03b72aa	Union Square Hospitality Group	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	175934816702039	2026-05-23 00:55:23.600997	2026-05-23 00:55:23.600997	Professional	\N	\N	Hospitality	2026-11-25	\N
9d4f2003-9f37-4f86-928f-3b39097f1216	Bailey & Wood Financial Group	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	175218174024169	2026-05-23 00:55:23.604832	2026-05-23 00:55:23.604832	Professional	\N	\N	Finance	2026-08-29	\N
3993312d-b999-4a3c-bdee-9eddb3089707	Charter Homes & Neighborhoods	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	175141852026228	2026-05-23 00:55:23.608804	2026-05-23 00:55:23.608804	Professional	\N	\N	Construction	2026-08-24	\N
18211d50-b7be-4333-bc15-0eade388843e	Manhattan Oral Facial Surgery LLC	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	green	f	\N	\N	175942030182167	2026-05-23 00:55:23.612999	2026-05-23 00:55:23.612999	Professional	\N	\N	Healthcare	2026-10-20	\N
f65b47c2-a976-48e7-92b6-1054511bf05e	Cavalier Senior Living	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	175520427257827	2026-05-23 00:55:23.616814	2026-05-23 00:55:23.616814	Professional	\N	\N	Wellness	2027-09-30	\N
dad2f72b-156a-4623-91e4-55de1c7c145f	Club Tattoo	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	green	f	\N	\N	170008772717174	2026-05-23 00:55:23.620899	2026-05-23 00:55:23.620899	Professional	\N	\N	Beauty	2026-11-27	\N
6cc645c0-8d32-4df6-baed-c494df926c9b	Aegis Medical Group	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	162198325085760	2026-05-23 00:55:23.624997	2026-05-23 00:55:23.624997	Professional	\N	\N	Healthcare	2026-09-14	\N
30c6cc66-4e46-4dcb-9bf0-1c1da1c84d75	Penhall Company	aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	\N	yellow	f	\N	\N	171076676766565	2026-05-23 00:55:23.629108	2026-05-23 00:55:23.629108	Professional	\N	\N	Construction	2027-08-22	\N
737b3260-ac9a-4863-9242-32aaae35cb54	Graber Custom Structures	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	173378121751953	2026-05-23 00:55:23.633794	2026-05-23 00:55:23.633794	Professional	\N	\N	Contractors	2028-04-20	\N
b730c568-2d84-4e98-90b8-bb023a41bcbf	Austin Telco Federal Credit Union	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	175345441638452	2026-05-23 00:55:23.638223	2026-05-23 00:55:23.638223	Professional	\N	\N	Finance	2026-11-23	\N
0b0a6740-f367-4b50-9aa1-b1ec80bc2546	WELL Health Clinics	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	169662976001526	2026-05-23 00:55:23.647769	2026-05-23 00:55:23.647769	Professional	\N	\N	Healthcare	2027-01-31	\N
f15511d0-6552-4d9c-b121-9a8724a87643	Heritage Resource Group	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	167997474376100	2026-05-23 00:55:23.651703	2026-05-23 00:55:23.651703	Professional	\N	\N	Wellness	2026-09-30	\N
a0b8834f-27b6-4d85-bfe8-65cb3b0d0d23	Pacific Living Centers, Inc.	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	170977466005846	2026-05-23 00:55:23.655719	2026-05-23 00:55:23.655719	Professional	\N	\N	Wellness	2026-12-30	\N
b637646f-23e5-4a17-a689-b5423a284e5c	Genisys Credit Union	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	156338642040896	2026-05-23 00:55:23.659837	2026-05-23 00:55:23.659837	Professional	\N	\N	Finance	2026-08-30	\N
ba9c2736-dea7-4160-a552-96fe0221faea	A+ Federal Credit Union	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	156354470580473	2026-05-23 00:55:23.666694	2026-05-23 00:55:23.666694	Professional	\N	\N	Finance	2026-08-28	\N
147aea9c-c088-4c9f-a068-82da0dbad937	The Aspenwood Company	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	171829713358143	2026-05-23 00:55:23.670854	2026-05-23 00:55:23.670854	Professional	\N	\N	Wellness	2026-12-31	\N
b6f0639b-4224-42cf-83d3-be2690b7db04	Grand Appliance And TV	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	161308761772257	2026-05-23 00:55:23.677148	2026-05-23 00:55:23.677148	Professional	\N	\N	Consumer Goods	2026-06-29	\N
4c51a900-680b-4084-abc3-dba488508c79	Aqua Quip	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	149073874713756	2026-05-23 00:55:23.681289	2026-05-23 00:55:23.681289	Professional	\N	\N	Home Services	2029-03-30	\N
f0ab8de6-184c-4f4b-a0dc-8a434172835c	Opulence of Southern Pines, LLC	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	169818441806836	2026-05-23 00:55:23.685122	2026-05-23 00:55:23.685122	Professional	\N	\N	Consumer Goods	2026-10-28	\N
73fdb864-4217-4eda-8379-9abe60656d51	Spectrum Properties LTD	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	169842597741244	2026-05-23 00:55:23.689152	2026-05-23 00:55:23.689152	Professional	\N	\N	Real Estate	2026-11-06	\N
32e2417a-c468-4bb0-b050-f04fec25570e	Urban Flats	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	170594708902366	2026-05-23 00:55:23.693098	2026-05-23 00:55:23.693098	Professional	\N	\N	Education	2027-01-25	\N
60ee46d2-3b49-4afe-a3ee-0ede699c9eaa	Directions Credit Union	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	174664417569145	2026-05-23 00:55:23.697166	2026-05-23 00:55:23.697166	Professional	\N	\N	Finance	2028-07-15	\N
3d493ea3-9974-48ec-bafa-86caf2ae6494	Well by Messer	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	169176104173428	2026-05-23 00:55:23.701017	2026-05-23 00:55:23.701017	Professional	\N	\N	Healthcare	2027-06-16	\N
f7be9a24-654f-4e7e-bbd0-99eb8d64fba4	Ottawa Derm Centre	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	163294883044245	2026-05-23 00:55:23.70489	2026-05-23 00:55:23.70489	Professional	\N	\N	Healthcare	2026-09-30	\N
bb30e8bc-9173-4a46-974a-aca9abb88b57	Eastern Shore Heating & Air Conditioning, Inc.	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	167578694150885	2026-05-23 00:55:23.708643	2026-05-23 00:55:23.708643	Professional	\N	\N	Contractors	2027-02-07	\N
0b8a4246-c543-47cb-a47a-af26bee84065	Stark & Stark P.C	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	152634656947041	2026-05-23 00:55:23.713056	2026-05-23 00:55:23.713056	Professional	\N	\N	Legal	2026-12-31	\N
36830476-f2ff-42ab-9df5-e8be248b3c21	APEX Spine and Neurosurgery	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	167061940366131	2026-05-23 00:55:23.716864	2026-05-23 00:55:23.716864	Professional	\N	\N	Healthcare	2027-01-16	\N
e481b489-88c8-48e7-b2b8-a7f9f26f76f3	Light On Anxiety	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	163121853444247	2026-05-23 00:55:23.720828	2026-05-23 00:55:23.720828	Professional	\N	\N	Healthcare	2026-10-30	\N
a064e2c7-6da3-4ee2-af2f-c6f35048dcd9	Central Park Management	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	168210565400853	2026-05-23 00:55:23.724703	2026-05-23 00:55:23.724703	Professional	\N	\N	Real Estate	2026-08-18	\N
d3a92981-7976-40ee-920d-e9de011f5912	Ennoble Care	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	red	f	\N	\N	165911979753821	2026-05-23 00:55:23.728365	2026-05-23 00:55:23.728365	Professional	\N	\N	Healthcare	2027-05-21	\N
ad45d8d6-1031-4876-9ee3-29f744d61168	Witherite Law Group	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	1438181711728	2026-05-23 00:55:23.737823	2026-05-23 00:55:23.737823	Professional	\N	\N	Legal	2026-09-28	\N
d36a07f9-cce6-4e2e-ba39-7d6147decfb4	LAWBOSS - Uvalle Law Firm, PLLC	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	157894720050777	2026-05-23 00:55:23.74204	2026-05-23 00:55:23.74204	Professional	\N	\N	Legal	2027-01-13	\N
fd422301-649d-4949-a4bc-1b947512fcfe	The Cromeens Law Firm, PLLC	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	165272810818158	2026-05-23 00:55:23.745958	2026-05-23 00:55:23.745958	Professional	\N	\N	Legal	2026-05-31	\N
d7e77272-7411-4212-85ec-7abc5188ed39	Cahaba Dermatology Skin Health Center, LLC	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	145683987735810	2026-05-23 00:55:23.749444	2026-05-23 00:55:23.749444	Professional	\N	\N	Healthcare	2026-07-21	\N
b618395c-7af7-4097-8275-ea938e3054d3	Winter's Mini Storage	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	162252127050342	2026-05-23 00:55:23.752964	2026-05-23 00:55:23.752964	Professional	\N	\N	Consumer Services	2027-01-28	\N
8d27a20b-c2d9-40a9-a133-a62d32a27daf	Rich Management LLC	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	172736740559570	2026-05-23 00:55:23.756786	2026-05-23 00:55:23.756786	Professional	\N	\N	Real Estate	2026-06-01	\N
82cec659-aed4-40e7-b49e-223f55ecdc56	Cardel Homes	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	171898109781042	2026-05-23 00:55:23.76038	2026-05-23 00:55:23.76038	Professional	\N	\N	Construction	2026-12-31	\N
96d26810-9b54-463f-b957-6790867653bc	DK Law - Injury, Accident, and More	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	176600843739709	2026-05-23 00:55:23.770078	2026-05-23 00:55:23.770078	Professional	\N	\N	Legal	2027-01-13	\N
41fa3a58-60b8-40f8-b644-a576494743f6	JC Endodontics	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	167880371766675	2026-05-23 00:55:23.774617	2026-05-23 00:55:23.774617	Professional	\N	\N	Dental	2026-06-17	\N
8494860b-74bc-41ec-acef-209417ed76b4	Texas Security Bank	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	172660304144146	2026-05-23 00:55:23.779003	2026-05-23 00:55:23.779003	Professional	\N	\N	Finance	2026-10-29	\N
37d1055f-f7f2-4287-b2ba-eecfd54033bb	Affordable Radon Services	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	162196293502970	2026-05-23 00:55:23.783305	2026-05-23 00:55:23.783305	Professional	\N	\N	Real Estate	2026-11-26	\N
ac3ca3e6-59a6-4d8a-8fe1-9af1eccadbb0	Prosthodontics & Implant Therapy (Drs. Iranmanesh, Esfahanian & Mashkouri)	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	149617579173150	2026-05-23 00:55:23.787187	2026-05-23 00:55:23.787187	Professional	\N	\N	Dental	2026-05-30	\N
45a6853e-14d1-4f01-88e6-0e42255cbf27	Avayda Pest Control	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	165947018827239	2026-05-23 00:55:23.792014	2026-05-23 00:55:23.792014	Professional	\N	\N	Home Services	2027-01-18	\N
4449c83f-e11b-4c39-a7dd-3ecae468b0f0	Candy Cars	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	173351538265449	2026-05-23 00:55:23.795864	2026-05-23 00:55:23.795864	Professional	\N	\N	Automotive	2026-12-09	\N
8d6dd9bd-d420-46ee-b625-b1870d243a2a	Lewis Investments	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	173205486742062	2026-05-23 00:55:23.799928	2026-05-23 00:55:23.799928	Professional	\N	\N	Contractors	2026-11-19	\N
a2401251-4582-4a7c-9317-6648ce4e909c	Arizona Advanced Imaging	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	173265353860231	2026-05-23 00:55:23.804509	2026-05-23 00:55:23.804509	Professional	\N	\N	Healthcare	2026-11-15	\N
18a1ffe5-7555-4d38-ac61-c19c433a88d8	Ervil Dental	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	172381797357843	2026-05-23 00:55:23.808208	2026-05-23 00:55:23.808208	Professional	\N	\N	Dental	2026-08-30	\N
83c02b9f-99d9-479c-98b5-c6038ac24bcd	Abilene Total Wellness Medical Spa	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	163736540168261	2026-05-23 00:55:23.811558	2026-05-23 00:55:23.811558	Professional	\N	\N	Wellness	2026-12-03	\N
0ea1ac0a-55f3-4494-b0c8-7e5759371655	Lane oral surgery	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	156172925802403	2026-05-23 00:55:23.815024	2026-05-23 00:55:23.815024	Professional	\N	\N	Dental	2026-09-18	\N
545bbfcb-b338-4806-ad3f-25fbd9c6f515	Scrofano Law PC	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	173871229225312	2026-05-23 00:55:23.818492	2026-05-23 00:55:23.818492	Professional	\N	\N	Legal	2027-02-05	\N
0d8ac75a-4f8f-4e9e-abb5-6b6a15686b7c	Torhoerman Law	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	174613052403809	2026-05-23 00:55:23.822633	2026-05-23 00:55:23.822633	Professional	\N	\N	Legal	2027-05-15	\N
dee8e35f-0dc9-451a-8958-b5b1e49ec853	Webster Dental Care	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	red	f	\N	\N	165377037299907	2026-05-23 00:55:23.82756	2026-05-23 00:55:23.82756	Professional	\N	\N	Dental	2026-05-28	\N
0a9ab6d9-8209-41f4-8566-cd1af2fa79b3	San Francisco Toyota	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	172788823179252	2026-05-23 00:55:23.831479	2026-05-23 00:55:23.831479	Professional	\N	\N	Automotive	2026-10-23	\N
909f5a0e-2094-437a-8be5-db76eb487fc2	Living Care Lifestyles	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	171347407862314	2026-05-23 00:55:23.837928	2026-05-23 00:55:23.837928	Professional	\N	\N	Healthcare	2027-04-19	\N
07e07703-ca84-4dc9-9e30-195f45d37d89	Dallas Ear Institute	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	164331425310067	2026-05-23 00:55:23.842225	2026-05-23 00:55:23.842225	Professional	\N	\N	Healthcare	2027-01-31	\N
663b6a1a-2f38-4e79-baed-5958ea6fbc83	Green Ridge Solar	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	169289792928147	2026-05-23 00:55:23.845605	2026-05-23 00:55:23.845605	Professional	\N	\N	Home Services	2026-12-04	\N
b8657a23-7437-4eaf-a891-d72944c2508e	MedEast Post-Op & Surgical, Inc	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	yellow	f	\N	\N	173022351675046	2026-05-23 00:55:23.848997	2026-05-23 00:55:23.848997	Professional	\N	\N	Healthcare	2026-10-29	\N
da59f357-e8fe-44cb-b1a7-e62d0794b6b0	Hotshots Sports Bar & Grill	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	147465482535759	2026-05-23 00:55:23.852541	2026-05-23 00:55:23.852541	Professional	\N	\N	Restaurants	2026-08-30	\N
08dc1323-0c8b-4232-bbb1-6bb0d7ecf9d0	Conference Technologies	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	red	f	\N	\N	164823979557455	2026-05-23 00:55:23.855844	2026-05-23 00:55:23.855844	Professional	\N	\N	Technology	2028-03-31	\N
f818ca2e-9b6f-438a-b1f4-542597d7add5	INOVA Federal	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	166007311910966	2026-05-23 00:55:23.859237	2026-05-23 00:55:23.859237	Professional	\N	\N	Finance	2026-08-31	\N
f4269093-0443-4918-ad60-abf5a055c841	eyeTrust.ca Corporation	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	152132407428046	2026-05-23 00:55:23.862902	2026-05-23 00:55:23.862902	Professional	\N	\N	Healthcare	2029-03-18	\N
f04ffd6f-cb7a-46d5-aa8b-145e609efc2d	Fort Hays Tech Northwest	c162aac7-5f74-418b-bdd6-048e21c1c4ff	\N	green	f	\N	\N	161048296652890	2026-05-23 00:55:23.867063	2026-05-23 00:55:23.867063	Professional	\N	\N	Education	2027-09-20	\N
4455d335-2361-4c96-8888-a9e53c54d5db	Modern Heart & Vascular	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	172127690301091	2026-05-23 00:55:23.870735	2026-05-23 00:55:23.870735	Professional	\N	\N	Healthcare	2028-03-02	\N
7f5aa678-ad6b-46f0-ac77-871e4c59578b	Thoroughbred Express Auto Wash	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	173706120060741	2026-05-23 00:55:23.87435	2026-05-23 00:55:23.87435	Professional	\N	\N	Automotive	2027-02-04	\N
bd375c94-7220-4e18-acdc-802749355584	Outcome Healthcare	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	173402812920303	2026-05-23 00:55:23.877801	2026-05-23 00:55:23.877801	Professional	\N	\N	Healthcare	2026-12-31	\N
692112ae-9653-4f8a-bab1-382670544559	el dorado mexican restaurant	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	red	f	\N	\N	172115901279438	2026-05-23 00:55:23.881781	2026-05-23 00:55:23.881781	Professional	\N	\N	Restaurants	2027-05-19	\N
8d80aa71-2098-49a8-8a04-ab9ecfb3761a	We Care Senior Care Dba Home Instead	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	162292052735262	2026-05-23 00:55:23.885339	2026-05-23 00:55:23.885339	Professional	\N	\N	Other	2026-09-22	\N
70332afa-0499-456f-ac7e-3fe2fea5f934	Kings Roofing NWFL, LLC	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	172667723571893	2026-05-23 00:55:23.888757	2026-05-23 00:55:23.888757	Professional	\N	\N	Contractors	2026-10-10	\N
297b50ae-3eba-44fc-94e4-e215696a82eb	DJE Holdings, LLC dba The Place for Children with Autism	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	175398110542323	2026-05-23 00:55:23.892824	2026-05-23 00:55:23.892824	Professional	\N	\N	Healthcare	2026-11-30	\N
5b00ea41-f2b4-4334-96d5-bba1bb53aed1	Everest Exteriors	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	170991833465343	2026-05-23 00:55:23.896435	2026-05-23 00:55:23.896435	Professional	\N	\N	Contractors	2026-09-26	\N
a60459f2-cab2-4526-9046-b92a0351a8e1	InfoWest	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	167631718134798	2026-05-23 00:55:23.900704	2026-05-23 00:55:23.900704	Professional	\N	\N	Technology	2028-02-17	\N
fd7a23be-cc28-4722-89ac-bb4bb5ec5b9f	American Debt Relief	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	165720803363964	2026-05-23 00:55:23.90441	2026-05-23 00:55:23.90441	Professional	\N	\N	Finance	2027-01-21	\N
0f0ea1ca-7634-4eba-ab4a-cbc67709e507	Arizona Iron Patio Furniture	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	166266941874261	2026-05-23 00:55:23.907851	2026-05-23 00:55:23.907851	Professional	\N	\N	Retail	2026-09-30	\N
179400f4-c0f2-4b6a-9f74-5fd19319a869	Sleep City	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	167880602091318	2026-05-23 00:55:23.911218	2026-05-23 00:55:23.911218	Professional	\N	\N	Consumer Goods	2027-05-06	\N
1825c2cd-e2eb-4267-8e16-1d0e61997731	University Tire And Auto Center	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	174664246778390	2026-05-23 00:55:23.914925	2026-05-23 00:55:23.914925	Professional	\N	\N	Automotive	2026-06-04	\N
3bb1a0e8-ae46-4315-9262-0e9b130ff627	DayMet Credit Union	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	161591674159419	2026-05-23 00:55:23.918381	2026-05-23 00:55:23.918381	Professional	\N	\N	Finance	2026-09-30	\N
2eab94d4-4241-46aa-b3ae-95239ac974f3	EHS Housing	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	175278626010630	2026-05-23 00:55:23.922009	2026-05-23 00:55:23.922009	Professional	\N	\N	Real Estate	2026-09-15	\N
939e5b40-2f52-4c6f-bd70-13bd2781e5df	Ascentra Credit Union	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	156449689698356	2026-05-23 00:55:23.925725	2026-05-23 00:55:23.925725	Professional	\N	\N	Finance	2026-07-27	\N
f4fe6256-d849-4de7-98b0-9ac880403587	Above & Beyond	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	175071682219069	2026-05-23 00:55:23.92943	2026-05-23 00:55:23.92943	Professional	\N	\N	Healthcare	2026-11-07	\N
21b11c4c-2cf7-418a-8d2b-0276bbdf7c6f	FG Brands	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	175252702718667	2026-05-23 00:55:23.935685	2026-05-23 00:55:23.935685	Professional	\N	\N	Beauty	2026-09-26	\N
26ae30eb-3e9f-434f-972d-7bf010ce3de7	Renewal by Andersen	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	169774587672688	2026-05-23 00:55:23.939961	2026-05-23 00:55:23.939961	Professional	\N	\N	Contractors	2026-11-03	\N
8f35692c-833f-4472-b75a-d489d83326b0	Georgia Floors Direct	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	160622916298509	2026-05-23 00:55:23.943778	2026-05-23 00:55:23.943778	Professional	\N	\N	Home Services	2027-12-31	\N
9a7c1808-4d71-45e1-aaba-07ff4f4437b9	Wesley Apartment Homes	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	154834105206581	2026-05-23 00:55:23.947547	2026-05-23 00:55:23.947547	Professional	\N	\N	Real Estate	2028-10-29	\N
45a56a91-dbb1-4107-bdfc-89057728bc5a	Prism Specialties	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	174009046400711	2026-05-23 00:55:23.951467	2026-05-23 00:55:23.951467	Professional	\N	\N	Home Services	2026-10-01	\N
dbc9900e-b2e1-449d-b129-d5a31554ea96	Alan's Roofing Inc	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	169817450179172	2026-05-23 00:55:23.955369	2026-05-23 00:55:23.955369	Professional	\N	\N	Contractors	2026-11-15	\N
b1722528-917f-4b25-9c60-891926a5b169	Hoffman Cooling & Heating	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	169271851685323	2026-05-23 00:55:23.959091	2026-05-23 00:55:23.959091	Professional	\N	\N	Contractors	2026-08-22	\N
dc16522f-4c41-4630-a71e-866d19a5b0ba	Comprehensive Pain Care of South Florida	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	159907586771773	2026-05-23 00:55:23.962609	2026-05-23 00:55:23.962609	Professional	\N	\N	Healthcare	2026-09-18	\N
2190c5c6-2437-461f-a8bf-a95d793fad95	Disparti Law Group, P.A.	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	165755356050062	2026-05-23 00:55:23.966774	2026-05-23 00:55:23.966774	Professional	\N	\N	Legal	2026-09-12	\N
a498c8a7-7ded-40f6-8591-b65140f5d3cc	PetPartners Pet Insurance	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	157062967178671	2026-05-23 00:55:23.971511	2026-05-23 00:55:23.971511	Professional	\N	\N	Insurance	2026-10-14	\N
f225e32b-dae7-4487-93c2-89627be48856	Manor Communities	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	157427700811964	2026-05-23 00:55:23.975542	2026-05-23 00:55:23.975542	Professional	\N	\N	Real Estate	2028-11-27	\N
72f3b3dc-255d-42a9-a0ad-a18dcc14e437	New York Laser Vision	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	172243576437596	2026-05-23 00:55:23.979268	2026-05-23 00:55:23.979268	Professional	\N	\N	Wellness	2026-10-28	\N
5f0d7583-ca71-4292-b634-c55174e863e7	Richard Schwartz & Associates PA	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	165547579080605	2026-05-23 00:55:23.983407	2026-05-23 00:55:23.983407	Professional	\N	\N	Legal	2026-07-22	\N
fa5b7b14-17eb-4950-b97c-aa3c0ad1dfcc	Lake Washington Windows and Doors	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	149702801672629	2026-05-23 00:55:23.987311	2026-05-23 00:55:23.987311	Professional	\N	\N	Contractors	2026-06-20	\N
b6cc64e1-3d63-4525-aea0-b8d26798f1f0	Hempy Water - Dublin	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	169505070895024	2026-05-23 00:55:23.991007	2026-05-23 00:55:23.991007	Professional	\N	\N	Retail	2026-09-27	\N
400211cd-6f5a-401f-a235-50ae7a1f876f	Boyd Law	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	169636579846706	2026-05-23 00:55:23.994383	2026-05-23 00:55:23.994383	Professional	\N	\N	Legal	2026-10-09	\N
e488fbb9-6a5c-40dd-8e82-baf2d45d14c7	Shaheen, Ruth, Martin & Fonville Real Estate	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	176598678952567	2026-05-23 00:55:23.998005	2026-05-23 00:55:23.998005	Professional	\N	\N	Real Estate	2026-12-18	\N
8e1a9a69-a755-477c-947c-e5c3763ec738	Salsa Con Fuego	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	163300924921175	2026-05-23 00:55:24.001763	2026-05-23 00:55:24.001763	Professional	\N	\N	Restaurants	2026-09-30	\N
d2ba0243-94a3-47d7-943c-a5c176c3c147	Tebo Dental	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	150733096561834	2026-05-23 00:55:24.005699	2026-05-23 00:55:24.005699	Professional	\N	\N	Dental	2026-10-17	\N
ea839116-907c-455a-9f6b-8e42a35bfffe	DuraShield Roofing & Contracting	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	172729014216503	2026-05-23 00:55:24.009039	2026-05-23 00:55:24.009039	Professional	\N	\N	Contractors	2026-09-29	\N
1ee6e23e-9c1e-4e13-bcb1-8c62c8dfeeaf	FL-Air Heating & Cooling	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	red	f	\N	\N	170380568378586	2026-05-23 00:55:24.012919	2026-05-23 00:55:24.012919	Professional	\N	\N	Contractors	2026-12-28	\N
c62ff20b-3d03-4668-b75a-bdaf33ce1d5f	Bulwark Exterminating	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	174354130176494	2026-05-23 00:55:24.016458	2026-05-23 00:55:24.016458	Professional	\N	\N	Home Services	2026-06-20	\N
06819a18-eb0b-4b81-91d9-4514f7e937d8	CR Legal Team	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	154878677060404	2026-05-23 00:55:24.019836	2026-05-23 00:55:24.019836	Professional	\N	\N	Legal	2026-12-08	\N
c409c7ae-a9f4-4018-8252-61806d0fd797	Kids R Kids	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	166855590779360	2026-05-23 00:55:24.023189	2026-05-23 00:55:24.023189	Professional	\N	\N	Education	2026-09-30	\N
1f936067-79f2-4e98-93af-241c9b683022	Eagle Auto Glass	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	162248940740447	2026-05-23 00:55:24.027284	2026-05-23 00:55:24.027284	Professional	\N	\N	Automotive	2027-04-03	\N
38b37a32-32e1-49a7-bf82-6596725499b1	Moon Lash in Brea	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	green	f	\N	\N	174122361546039	2026-05-23 00:55:24.032129	2026-05-23 00:55:24.032129	Professional	\N	\N	Beauty	2027-03-06	\N
63cd9cee-b100-4796-968a-832d5a4dd355	Ozarks Elder Law	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	175381962923339	2026-05-23 00:55:24.035521	2026-05-23 00:55:24.035521	Professional	\N	\N	Legal	2026-10-07	\N
5c24cde6-86f4-4141-9b53-11e92e9ff218	Pediatric Dentistry of Shreveport	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	149583177465241	2026-05-23 00:55:24.039	2026-05-23 00:55:24.039	Professional	\N	\N	Dental	2026-05-26	\N
6288832c-e9ae-4a84-b6d0-f95df226eff0	Advanced Oral Surgery of Tampa	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	152969429228029	2026-05-23 00:55:24.043223	2026-05-23 00:55:24.043223	Professional	\N	\N	Dental	2028-06-28	\N
54ce2c75-c8cf-41eb-b972-ff128ef14efb	Unlock Technologies, Inc.	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	173040543445134	2026-05-23 00:55:24.046762	2026-05-23 00:55:24.046762	Professional	\N	\N	Finance	2026-11-06	\N
3427cd02-2e32-454f-91da-fefb84e43811	Royal Medical Center	ba12dc3b-4ae7-4d67-b508-435c13e53c90	\N	yellow	f	\N	\N	168374907423248	2026-05-23 00:55:24.050803	2026-05-23 00:55:24.050803	Professional	\N	\N	Healthcare	2027-05-11	\N
330ecb88-67bf-46e6-8643-041b5f3354ff	Valley Eye Associates	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	170507181146356	2026-05-23 00:55:24.054237	2026-05-23 00:55:24.054237	Professional	\N	\N	Healthcare	2027-01-31	\N
95327b9a-f7f6-401d-a664-c0ba74b22456	Ted's Cafe Escondido	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	164210319512008	2026-05-23 00:55:24.058057	2026-05-23 00:55:24.058057	Professional	\N	\N	Restaurants	2027-04-01	\N
22fad671-6557-4bf6-aab0-eee20c6fb677	Ancestry	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	red	f	\N	\N	169168071198380	2026-05-23 00:55:24.062462	2026-05-23 00:55:24.062462	Professional	\N	\N	Healthcare	2026-11-30	\N
c76312a5-76e5-4218-9541-b32aef348162	Greater Philadelphia YMCA - Association Office	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	169333021459921	2026-05-23 00:55:24.066313	2026-05-23 00:55:24.066313	Professional	\N	\N	Wellness	2028-03-30	\N
191d8126-ee79-4fc3-b24d-ddaf5782b94a	Love That Door, LLC	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	166425954209279	2026-05-23 00:55:24.070178	2026-05-23 00:55:24.070178	Professional	\N	\N	Home Services	2027-03-30	\N
6278dda1-49b8-41a9-bb99-ce358c836809	Culture Care Senior Living	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	170932985372658	2026-05-23 00:55:24.074558	2026-05-23 00:55:24.074558	Professional	\N	\N	Healthcare	2027-03-29	\N
1e2c787c-3624-4467-9b17-e8929b54cd41	New York Sports Clubs	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	173351425772375	2026-05-23 00:55:24.078213	2026-05-23 00:55:24.078213	Professional	\N	\N	Recreation	2027-03-18	\N
df3d4d08-f976-4afd-ad60-dc96e9106554	LifeWorx Home Care	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	red	f	\N	\N	170915262747049	2026-05-23 00:55:24.082293	2026-05-23 00:55:24.082293	Professional	\N	\N	Healthcare	2028-04-17	\N
a70a9366-eeb8-48f3-9717-4ed46ae35fbb	Senior Management Advisors	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	170688543402253	2026-05-23 00:55:24.08591	2026-05-23 00:55:24.08591	Professional	\N	\N	Finance	2027-03-21	\N
304a0188-00ca-436c-8244-fbc32d7f0d48	Mindcolor Autism - ABA Therapy	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	red	f	\N	\N	170483364114655	2026-05-23 00:55:24.089194	2026-05-23 00:55:24.089194	Professional	\N	\N	Healthcare	2027-02-21	\N
a2ccb11c-74d5-4226-a814-b4c12849d299	Crisp Imaging	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	red	f	\N	\N	171960187742243	2026-05-23 00:55:24.092946	2026-05-23 00:55:24.092946	Professional	\N	\N	Business Services	2026-12-31	\N
1857e8ec-461b-4c1e-9316-8fceacd7b47d	Avondale Toyota	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	165772815705400	2026-05-23 00:55:24.096539	2026-05-23 00:55:24.096539	Professional	\N	\N	Automotive	2026-07-15	\N
61fc9c44-362e-40d5-8691-212ac2c816f2	Cabanas Law Firm	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	168503052283595	2026-05-23 00:55:24.100277	2026-05-23 00:55:24.100277	Professional	\N	\N	Legal	2026-12-12	\N
d8fc2b24-912e-49b1-a41e-92096e02f990	Hupy and Abraham	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	157238121406321	2026-05-23 00:55:24.104488	2026-05-23 00:55:24.104488	Professional	\N	\N	Legal	2026-11-14	\N
971f74d9-d99f-496b-a906-44ecb3a7901a	Advancial Federal Credit Union	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	166509061663756	2026-05-23 00:55:24.10798	2026-05-23 00:55:24.10798	Professional	\N	\N	Finance	2026-12-20	\N
900c4c0a-a4d8-4583-8523-72a7c7054aff	Fairfax EggBank Inc	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	173877697478209	2026-05-23 00:55:24.112116	2026-05-23 00:55:24.112116	Professional	\N	\N	Healthcare	2027-02-16	\N
1cc14142-4e8f-4dd6-b698-e9e7bedc7343	Legacy Hospice	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	170483358636616	2026-05-23 00:55:24.115575	2026-05-23 00:55:24.115575	Professional	\N	\N	Healthcare	2026-05-30	\N
9c3ab2d6-7604-4c9e-a24b-2bb762414b3c	RainSoft A & B Marketing	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	168987093533950	2026-05-23 00:55:24.119006	2026-05-23 00:55:24.119006	Professional	\N	\N	Home Services	2026-07-31	\N
1b842553-e651-4c4f-80ec-f7e46863804c	Ivy Kids	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	164512295070040	2026-05-23 00:55:24.123011	2026-05-23 00:55:24.123011	Professional	\N	\N	Education	2027-02-24	\N
697df20e-beb9-4480-bf41-07f59cf11371	Supplement King	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	174725760179359	2026-05-23 00:55:24.126603	2026-05-23 00:55:24.126603	Professional	\N	\N	Consumer Goods	2028-05-26	\N
574b3e9a-35aa-4f61-b055-a82ddf3a665d	Ace's Garage Door Repair & Installation	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	148518648643186	2026-05-23 00:55:24.130085	2026-05-23 00:55:24.130085	Professional	\N	\N	Home Services	2027-01-23	\N
6dbb7df8-a981-40cd-8e8e-1d9b82bda5bd	7 17 Credit Union	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	157132684998137	2026-05-23 00:55:24.133831	2026-05-23 00:55:24.133831	Professional	\N	\N	Finance	2026-10-30	\N
64929041-5a94-448f-a350-60ec2af7d785	Stack & Store Self Storage	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	162122022720456	2026-05-23 00:55:24.13744	2026-05-23 00:55:24.13744	Professional	\N	\N	Consumer Services	2027-05-18	\N
3c6044c1-f69b-4591-acd6-321ca4b8fa5f	The Apartment Company	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	172736625913698	2026-05-23 00:55:24.141333	2026-05-23 00:55:24.141333	Professional	\N	\N	Real Estate	2026-06-01	\N
0cac91ca-d720-4bb6-947a-7a1444012d06	Premier Roofing Company	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	172107177950990	2026-05-23 00:55:24.145025	2026-05-23 00:55:24.145025	Professional	\N	\N	Contractors	2027-03-27	\N
9f3f1ced-50d6-4320-84d7-a09b6076ad52	Northwest Oral & Maxillofacial Surgery Associates, Pc.	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	171146530855088	2026-05-23 00:55:24.148588	2026-05-23 00:55:24.148588	Professional	\N	\N	Dental	2027-04-30	\N
576a8367-7e36-4017-92b3-d4fb947fa0c8	Quality Labor Management LLC, Corporate Office	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	170258535309082	2026-05-23 00:55:24.152389	2026-05-23 00:55:24.152389	Professional	\N	\N	Business Services	2026-12-29	\N
09960801-f8bc-4180-9d3f-705c7635f1af	Barrington Residential	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	168815012599490	2026-05-23 00:55:24.155914	2026-05-23 00:55:24.155914	Professional	\N	\N	Hospitality	2027-07-23	\N
630efa25-b11d-43af-bca5-acfd27e47d93	Group Fox Inc.	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	170585753257365	2026-05-23 00:55:24.159126	2026-05-23 00:55:24.159126	Professional	\N	\N	Real Estate	2027-04-15	\N
28f2f0bc-53d6-468f-a747-ec404153231e	Throw Me A Bone	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	163907184459300	2026-05-23 00:55:24.162644	2026-05-23 00:55:24.162644	Professional	\N	\N	Consumer Services	2026-06-30	\N
98400695-ca82-4485-9e62-e908cd94e133	A  Financial Services	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	157296432938842	2026-05-23 00:55:24.166246	2026-05-23 00:55:24.166246	Professional	\N	\N	Finance	2026-06-30	\N
0bd4ef0d-b852-474e-ac04-94a0dac3f8af	Mountain West Motor	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	173643271269641	2026-05-23 00:55:24.17024	2026-05-23 00:55:24.17024	Professional	\N	\N	Automotive	2027-01-20	\N
d6b6b640-d61c-49f2-9f4d-22feea4e056c	Montilla Plastic Surgery	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	154153424451377	2026-05-23 00:55:24.177136	2026-05-23 00:55:24.177136	Professional	\N	\N	Healthcare	2026-11-06	\N
6da9ddae-a8cf-4cdc-8ccb-027b56e15d5a	RollShield LLC	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	164643119933877	2026-05-23 00:55:24.181024	2026-05-23 00:55:24.181024	Professional	\N	\N	Contractors	2027-03-14	\N
46929854-d14a-4978-a79d-93a0c267d0d4	Washburn-Mcreavy	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	155620204038472	2026-05-23 00:55:24.184858	2026-05-23 00:55:24.184858	Professional	\N	\N	Consumer Services	2027-03-28	\N
ba70f89e-ecf7-47d3-92a4-cdb515974a78	ProCare Health	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	174171512451501	2026-05-23 00:55:24.188503	2026-05-23 00:55:24.188503	Professional	\N	\N	Healthcare	2028-05-14	\N
bf02e275-a011-4292-877b-14473581ae88	EMCI Wireless	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	175328752566337	2026-05-23 00:55:24.192468	2026-05-23 00:55:24.192468	Professional	\N	\N	Retail	2026-07-31	\N
3e185465-eb71-4215-b3fb-b44d1af9ab3a	WellQuest	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	173127232900365	2026-05-23 00:55:24.196118	2026-05-23 00:55:24.196118	Professional	\N	\N	Wellness	2026-07-14	\N
b37be9d0-b829-4ce9-ab02-68d68581dcc5	Conservation Construction of Texas	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	159232419799111	2026-05-23 00:55:24.199998	2026-05-23 00:55:24.199998	Professional	\N	\N	Home Services	2027-04-27	\N
3a0fb035-18c7-436f-a8c3-23029c340978	Walsh Periodontics	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	157903665695092	2026-05-23 00:55:24.203595	2026-05-23 00:55:24.203595	Professional	\N	\N	Dental	2027-01-14	\N
3762bfa9-c949-48bd-9c27-9ad952889377	Johnson Roofing Solutions	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	165360136525124	2026-05-23 00:55:24.206926	2026-05-23 00:55:24.206926	Professional	\N	\N	Contractors	2027-05-31	\N
a77fa07f-a897-4862-8da3-95c2f94c0d87	Akeso Oral Surgery Group	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	171769938759698	2026-05-23 00:55:24.210799	2026-05-23 00:55:24.210799	Professional	\N	\N	Healthcare	2027-06-17	\N
1cdfc35f-c5d5-4f9f-8004-4c986318b3fc	Horsley Construction Group Inc.	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	173635123165561	2026-05-23 00:55:24.214147	2026-05-23 00:55:24.214147	Professional	\N	\N	Contractors	2027-01-07	\N
78bfedaa-7dff-46c0-ba5b-ef9a8a2007f0	Slyman Bros Appliances	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	red	f	\N	\N	170785670501600	2026-05-23 00:55:24.221703	2026-05-23 00:55:24.221703	Professional	\N	\N	Retail	2027-02-27	\N
97b3c135-cf96-45e8-8ff9-6cbcdcefee95	Alliance Funding Group	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	171035809511772	2026-05-23 00:55:24.226566	2026-05-23 00:55:24.226566	Professional	\N	\N	Finance	2026-07-02	\N
bdba18ab-263c-45d6-9ef7-c884e0fce838	Family Dental Offices	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	161497911299807	2026-05-23 00:55:24.23086	2026-05-23 00:55:24.23086	Professional	\N	\N	Dental	2027-03-17	\N
10589bbe-4510-4de5-bb3e-927aab8bf402	Sherwood Buick GMC	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	166258736090068	2026-05-23 00:55:24.234936	2026-05-23 00:55:24.234936	Professional	\N	\N	Automotive	2026-09-21	\N
a580e78f-79b7-43bd-94b0-2e7e4a426efc	Dental Options	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	156175589083304	2026-05-23 00:55:24.238613	2026-05-23 00:55:24.238613	Professional	\N	\N	Dental	2026-10-29	\N
b6ce3834-78e5-4262-951f-1695f9f27ddc	Perrie & Associates LLC	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	174545012148313	2026-05-23 00:55:24.242247	2026-05-23 00:55:24.242247	Professional	\N	\N	Legal	2026-05-28	\N
dd0b36ac-9425-4e82-b249-4c54eed74b17	Peak Builders & Roofers of San Diego	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	172686528232954	2026-05-23 00:55:24.24606	2026-05-23 00:55:24.24606	Professional	\N	\N	Contractors	2026-09-24	\N
141a6358-daec-4d71-a6ee-2780d370ebe9	AutoMax Preowned Marlboro Service	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	169263195219898	2026-05-23 00:55:24.249649	2026-05-23 00:55:24.249649	Professional	\N	\N	Automotive	2026-08-21	\N
c2412d50-1093-4547-8cf0-1398d74a52a5	BODi Louisville (formerly BodyRX Louisville)	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	green	f	\N	\N	170671904254763	2026-05-23 00:55:24.25333	2026-05-23 00:55:24.25333	Professional	\N	\N	Wellness	2027-02-05	\N
a428cc71-a56a-4d07-ba52-a7c956a02bbc	Rojeh Melikian, MD - Spine Surgeon	99cbad47-c52b-4539-b4fa-dbec732e7cc5	\N	yellow	f	\N	\N	168027862399779	2026-05-23 00:55:24.25811	2026-05-23 00:55:24.25811	Professional	\N	\N	Healthcare	2026-06-30	\N
89902c61-5993-4490-8312-4b6dd12c7368	NQAS	eb4c741c-1303-44f8-a9f1-7cbea02ab44e	\N	green	f	\N	\N	175730075836477	2026-05-23 00:55:24.262046	2026-05-23 00:55:24.262046	Professional	\N	\N	Construction	2027-01-08	\N
e5f75d33-ab4d-4945-b112-31009226319b	Mums2Mums Home Services	eb4c741c-1303-44f8-a9f1-7cbea02ab44e	\N	green	f	\N	\N	177249001186619	2026-05-23 00:55:24.266421	2026-05-23 00:55:24.266421	Professional	\N	\N	Home Services	2027-04-13	\N
162a9e7a-2904-4ec6-bb6e-bb94c2948034	Lumia Care Pty Ltd	eb4c741c-1303-44f8-a9f1-7cbea02ab44e	\N	green	f	\N	\N	173804107841661	2026-05-23 00:55:24.270399	2026-05-23 00:55:24.270399	Professional	\N	\N	Healthcare	2027-04-30	\N
8da2bba7-7c0f-46b8-8a0f-cecfe24d4431	Streamside Parks	0c27716b-b6f9-4286-a5ce-34e335c06d64	\N	green	f	\N	\N	175880973143592	2026-05-23 00:55:24.274072	2026-05-23 00:55:24.274072	Professional	\N	\N	Recreation	2027-02-26	\N
fda495e1-e247-451c-bc62-cc57481b9467	Fall River Public Schools	0c27716b-b6f9-4286-a5ce-34e335c06d64	\N	yellow	f	\N	\N	175985664596814	2026-05-23 00:55:24.277998	2026-05-23 00:55:24.277998	Professional	\N	\N	Education	2028-11-25	\N
d75cacbf-676d-428b-adf4-5d911444a5ea	The Dominguez Firm	0c27716b-b6f9-4286-a5ce-34e335c06d64	\N	yellow	f	\N	\N	170292214994067	2026-05-23 00:55:24.283374	2026-05-23 00:55:24.283374	Professional	\N	\N	Legal	2027-12-29	\N
96cec41a-ca8b-437e-8777-a09c740fa57a	Riddle & Riddle Injury Lawyers	0c27716b-b6f9-4286-a5ce-34e335c06d64	\N	yellow	f	\N	\N	173870400883546	2026-05-23 00:55:24.2874	2026-05-23 00:55:24.2874	Professional	\N	\N	Legal	2027-01-14	\N
c6ba5360-edbb-443a-a854-058ec04718a9	The Sage HeadSpa	0c27716b-b6f9-4286-a5ce-34e335c06d64	\N	green	f	\N	\N	177461977570557	2026-05-23 00:55:24.291141	2026-05-23 00:55:24.291141	Professional	\N	\N	Wellness	2027-03-30	\N
0d81c028-1432-4d13-be17-c2c9ce1671c9	Wave Dental Professionals	0c27716b-b6f9-4286-a5ce-34e335c06d64	\N	yellow	f	\N	\N	177505098577694	2026-05-23 00:55:24.294938	2026-05-23 00:55:24.294938	Professional	\N	\N	Dental	2027-04-29	\N
59af9756-89c2-4116-87ca-0a6a4bc94df8	Burton Pools & Spas	0c27716b-b6f9-4286-a5ce-34e335c06d64	\N	yellow	f	\N	\N	176971079060923	2026-05-23 00:55:24.29868	2026-05-23 00:55:24.29868	Professional	\N	\N	Other	2027-02-02	\N
2fb5a61e-aa14-4aac-88b3-f302363f0c1b	MAX Surgical Specialty Management	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	171338595540451	2026-05-23 00:55:24.302781	2026-05-23 00:55:24.302781	Professional	\N	\N	Healthcare	2026-11-17	\N
66355d92-1f67-40e6-a53e-43ae9de8d6f4	Laurus College	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	171346689239703	2026-05-23 00:55:24.3073	2026-05-23 00:55:24.3073	Professional	\N	\N	Education	2028-05-01	\N
e9cd4e6a-f29c-4716-a8b3-e07e52a6d440	Zoro	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	172116229729741	2026-05-23 00:55:24.31116	2026-05-23 00:55:24.31116	Professional	\N	\N	E-commerce	2027-05-13	\N
4bcfdd05-2d73-4f19-9b56-b6ca14bb31ed	Sam Leman Auto Group	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	165756448283645	2026-05-23 00:55:24.315339	2026-05-23 00:55:24.315339	Professional	\N	\N	Automotive	2026-08-26	\N
cb3fc38a-1bec-48dd-8121-ca9d522184ba	The Bailey Company	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	163727215456614	2026-05-23 00:55:24.319188	2026-05-23 00:55:24.319188	Professional	\N	\N	Home Services	2027-05-09	\N
2c60abbe-ca50-4c09-b7ba-0cd44b010987	RHF	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	168262377513782	2026-05-23 00:55:24.32373	2026-05-23 00:55:24.32373	Professional	\N	\N	Wellness	2029-03-20	\N
ccf2a00b-7b09-442c-bbc5-f409b4dd68c0	Code Red Roofers, Inc	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	164028705919968	2026-05-23 00:55:24.327771	2026-05-23 00:55:24.327771	Professional	\N	\N	Contractors	2028-03-24	\N
8444f568-f1d8-403f-866b-4913e46427fd	Walter Clark Legal Group	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	170663704557701	2026-05-23 00:55:24.33192	2026-05-23 00:55:24.33192	Professional	\N	\N	Legal	2027-02-23	\N
8314d969-082e-43cd-85ba-5f269b363e59	Industrial Credit Union	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	171934245387157	2026-05-23 00:55:24.335834	2026-05-23 00:55:24.335834	Professional	\N	\N	Finance	2026-07-15	\N
192cb550-b5f7-41a2-8e9d-134ca30ca4bd	Same Day Windshield	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	156865256738557	2026-05-23 00:55:24.33935	2026-05-23 00:55:24.33935	Professional	\N	\N	Automotive	2029-02-17	\N
fca5e3af-94e0-4c9b-a223-cd6ffa40c0f2	Senor Check Cashing	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	168452533024364	2026-05-23 00:55:24.343043	2026-05-23 00:55:24.343043	Professional	\N	\N	Automotive	2026-05-31	\N
2dd1a251-18ac-4bc1-8f3d-393b9d20db32	Heartland Payment Systems , Inc.	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	169151188388369	2026-05-23 00:55:24.347465	2026-05-23 00:55:24.347465	Professional	\N	\N	Technology	2026-08-30	\N
4c248f4b-05d4-43eb-9348-e56bf044b9cb	McDonald Insurance Group of Colorado	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	163242806867606	2026-05-23 00:55:24.352952	2026-05-23 00:55:24.352952	Professional	\N	\N	Insurance	2026-09-23	\N
f7b494b5-36bc-474e-be52-4aac8c638fb8	Cobb Nephrology Hypertension Associates	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	160943116385001	2026-05-23 00:55:24.356771	2026-05-23 00:55:24.356771	Professional	\N	\N	Healthcare	2026-12-31	\N
2d88260e-556b-4c64-9986-bd62d10f2d87	Healthcare Express	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	161097035441557	2026-05-23 00:55:24.360953	2026-05-23 00:55:24.360953	Professional	\N	\N	Healthcare	2026-10-16	\N
117cd6ab-f047-4b94-95f4-bf489422f2e6	Foothill Cardiology Medical Group Inc	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	red	f	\N	\N	167511978315474	2026-05-23 00:55:24.364508	2026-05-23 00:55:24.364508	Professional	\N	\N	Healthcare	2027-03-28	\N
2b079715-8b17-4776-bee8-82cf51a6694f	Inspired Education LLC (Happy Days Preschool)	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	172355295765859	2026-05-23 00:55:24.368948	2026-05-23 00:55:24.368948	Professional	\N	\N	Education	2026-08-23	\N
57db381c-2ee7-4446-9fb1-293eeafac44b	The Saxton Group	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	152691489181737	2026-05-23 00:55:24.373571	2026-05-23 00:55:24.373571	Professional	\N	\N	Restaurants	2026-12-28	\N
a44aeb5d-4fd0-448a-b5b7-699425491076	Kingswood Academy Greenacres Daycare & Preschool	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	166033861411494	2026-05-23 00:55:24.377676	2026-05-23 00:55:24.377676	Professional	\N	\N	Education	2027-12-11	\N
6e513265-27aa-4aa7-b6c8-2c967609f1ab	Nick's Menswear	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	169161456200890	2026-05-23 00:55:24.385869	2026-05-23 00:55:24.385869	Professional	\N	\N	Retail	2026-08-30	\N
6685c0c2-339e-4935-ad22-d3d522693d0e	Runza National	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	169928277342896	2026-05-23 00:55:24.390065	2026-05-23 00:55:24.390065	Professional	\N	\N	Business Services	2026-12-14	\N
19dade47-bca9-440c-923a-1d14737f92ae	Comprehensive Orthopaedics, S.C	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	151732539024627	2026-05-23 00:55:24.394	2026-05-23 00:55:24.394	Professional	\N	\N	Healthcare	2030-02-01	\N
6b3ea988-a54b-432d-aac2-17d067ced281	Chelsea Fertility NYC	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	165946702992749	2026-05-23 00:55:24.397471	2026-05-23 00:55:24.397471	Professional	\N	\N	Healthcare	2026-08-03	\N
17dc8beb-4e56-4f84-8a60-13f3609fc4af	Motor City Pawn Brokers	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	170422016532243	2026-05-23 00:55:24.4007	2026-05-23 00:55:24.4007	Professional	\N	\N	Consumer Goods	2028-03-17	\N
55933377-dee8-45a4-97f9-8786121d54f1	Select Dental Management	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	169651644625355	2026-05-23 00:55:24.404098	2026-05-23 00:55:24.404098	Professional	\N	\N	Healthcare	2026-11-26	\N
b1237deb-8a6f-468d-891e-c50c0352956f	Lee Dental Care	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	154334154749567	2026-05-23 00:55:24.40756	2026-05-23 00:55:24.40756	Professional	\N	\N	Dental	2027-07-25	\N
ed6caafb-1370-434e-a873-7eac01c50746	Ohio State Waterproofing / Everdry	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	160529239674278	2026-05-23 00:55:24.410765	2026-05-23 00:55:24.410765	Professional	\N	\N	Home Services	2026-12-22	\N
93175421-68ee-4d19-8d81-7a488e190dae	HAPO Community Credit Union	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	165833755745234	2026-05-23 00:55:24.414284	2026-05-23 00:55:24.414284	Professional	\N	\N	Finance	2026-12-30	\N
194b65d3-6560-4091-b9f5-9b2b0445abf4	Sutherland Global Services	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	164882091326073	2026-05-23 00:55:24.417699	2026-05-23 00:55:24.417699	Professional	\N	\N	Business Services	2026-04-29	\N
7122ebad-ee0e-4e51-b2be-a2feda398790	First Credit Union	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	155121438194841	2026-05-23 00:55:24.421244	2026-05-23 00:55:24.421244	Professional	\N	\N	Contractors	2028-03-29	\N
488d4cf2-3d7f-40f0-bff2-4fab9a75ceb4	Canna Doctors of America	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	159493027378982	2026-05-23 00:55:24.424954	2026-05-23 00:55:24.424954	Professional	\N	\N	Healthcare	2027-11-13	\N
80164bcf-9f9e-4dad-b472-7341799bea92	Law Offices Of Richard C. Mcconathy	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	162132876667509	2026-05-23 00:55:24.428814	2026-05-23 00:55:24.428814	Professional	\N	\N	Legal	2026-08-30	\N
9303a7ae-e5f9-4523-8d7c-ae4d5919596a	The Law Offices of Thomas Maronick Jr LLC	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	156906413503162	2026-05-23 00:55:24.4328	2026-05-23 00:55:24.4328	Professional	\N	\N	Legal	2029-03-11	\N
cef050e9-f6cb-4b44-a9f4-328f46a40490	Exer Urgent Care	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	168373840134389	2026-05-23 00:55:24.436717	2026-05-23 00:55:24.436717	Professional	\N	\N	Healthcare	2026-10-31	\N
36d2efa2-7e59-4e01-837f-495ad3d7e458	Pella Windows & Doors	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	red	f	\N	\N	151093076930661	2026-05-23 00:55:24.440381	2026-05-23 00:55:24.440381	Professional	\N	\N	Contractors	2026-12-28	\N
f5232b0f-a438-46c4-a687-6e6f55272caa	CODAC Inc	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	168487074045737	2026-05-23 00:55:24.44377	2026-05-23 00:55:24.44377	Professional	\N	\N	Healthcare	2027-11-01	\N
f4348945-0b79-46f8-8628-a3c1ae832b6c	Siranli Implants & Facial Aesthetics & Prosthodontics	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	168868834986165	2026-05-23 00:55:24.447967	2026-05-23 00:55:24.447967	Professional	\N	\N	Dental	2026-07-07	\N
43defec9-5e1d-446a-b4ec-360931eff392	Deli Italiano Great Falls	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	168236815251847	2026-05-23 00:55:24.45201	2026-05-23 00:55:24.45201	Professional	\N	\N	Business Services	2027-12-03	\N
11dc9af8-60d1-4f1b-a760-5172d857c831	WellWay	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	170110416530236	2026-05-23 00:55:24.455717	2026-05-23 00:55:24.455717	Professional	\N	\N	Wellness	2026-12-18	\N
14007044-461b-4c92-957e-b06f937de3da	Lightfully Behavioral Health	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	173764497824695	2026-05-23 00:55:24.459233	2026-05-23 00:55:24.459233	Professional	\N	\N	Healthcare	2027-03-28	\N
0e084acf-5b64-4f06-ad42-e78ccc6c0098	Compassionate Care Consultants	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	155681954241820	2026-05-23 00:55:24.462667	2026-05-23 00:55:24.462667	Professional	\N	\N	Healthcare	2026-06-26	\N
b22ed9a6-2776-4d30-b08a-314055e38c78	North Texas Allergy and Asthma Associates	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	167217962359300	2026-05-23 00:55:24.466548	2026-05-23 00:55:24.466548	Professional	\N	\N	Healthcare	2026-12-29	\N
d2db88f3-7e91-4cee-901b-116253d6607d	Texas Pain and Spine Physicians: M. Ali Khan, MD	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	174708613947262	2026-05-23 00:55:24.470924	2026-05-23 00:55:24.470924	Professional	\N	\N	Healthcare	2026-09-30	\N
f04abbd9-2574-4842-8c32-725ee4cd0bfd	Sunstate Companies	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	171822805062239	2026-05-23 00:55:24.474911	2026-05-23 00:55:24.474911	Professional	\N	\N	Contractors	2026-06-13	\N
f7b0ad74-fca2-4de5-b1b1-edd318988a06	The Smith	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	168391305637836	2026-05-23 00:55:24.478409	2026-05-23 00:55:24.478409	Professional	\N	\N	Restaurants	2026-12-29	\N
8b12b05f-bdf5-4ab8-9258-599ef33bbd89	Copenbarger & Copenbarger LLP	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	148528065021869	2026-05-23 00:55:24.4833	2026-05-23 00:55:24.4833	Professional	\N	\N	Legal	2028-07-06	\N
5ace3a93-ea3d-4220-8be0-d6520361c613	Holden Roofing	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	153659682845388	2026-05-23 00:55:24.817635	2026-05-23 00:55:24.817635	Professional	\N	\N	Contractors	2026-09-05	\N
75dc3340-f3dc-41f8-ab07-b78b0e3d8dd2	Crossland's A&A Rent-All & Sales Co.	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	155121780477664	2026-05-23 00:55:24.487094	2026-05-23 00:55:24.487094	Professional	\N	\N	Consumer Services	2026-09-19	\N
b972046f-371f-4163-b9eb-2513910811f5	Vascular Centers of America	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	166129598603731	2026-05-23 00:55:24.490722	2026-05-23 00:55:24.490722	Professional	\N	\N	Healthcare	2026-10-04	\N
be680c21-6083-4b9c-b35c-8e195148ded0	Triad Financial Services	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	yellow	f	\N	\N	167880849275481	2026-05-23 00:55:24.494163	2026-05-23 00:55:24.494163	Professional	\N	\N	Finance	2026-07-14	\N
bd70e640-5d80-4d03-9e38-6dac07272285	Longevity Medical Clinic	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	red	f	\N	\N	163900363579772	2026-05-23 00:55:24.497555	2026-05-23 00:55:24.497555	Professional	\N	\N	Healthcare	2026-12-14	\N
afdf9306-caa2-4b9d-8976-a4cb3aef79e4	Box City LLC	8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	\N	green	f	\N	\N	174136991910943	2026-05-23 00:55:24.501038	2026-05-23 00:55:24.501038	Professional	\N	\N	Consumer Goods	2028-03-17	\N
8e5918f0-309f-4e21-9a5f-324eb0f77ae1	Lexington Partners, LLC	0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	\N	yellow	f	\N	\N	172537554195133	2026-05-23 00:55:24.505011	2026-05-23 00:55:24.505011	Professional	\N	\N	Contractors	2026-09-16	\N
8e5c08c0-7fbb-49cc-9c30-155c2d53caa5	Van Leeuwen Ice Cream	b33d6a81-3d2c-401a-9aee-23d82fed6969	\N	yellow	f	\N	\N	172123206846625	2026-05-23 00:55:24.50838	2026-05-23 00:55:24.50838	Professional	\N	\N	Restaurants	2026-07-31	\N
7e96a3c4-4036-4ce1-b3a8-8b9b3c52b3fa	Ignite Funding	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	168262710609295	2026-05-23 00:55:24.512349	2026-05-23 00:55:24.512349	Professional	\N	\N	Finance	2027-04-27	\N
d8aae3f6-39a7-4024-9c00-34fbf85dba1c	Commonwealth Care of Roanoke	3520009d-e788-4bea-8d6a-245711cbfe42	\N	green	f	\N	\N	176374963588232	2026-05-23 00:55:24.516177	2026-05-23 00:55:24.516177	Professional	\N	\N	Wellness	2026-12-10	\N
e830e7fb-92f9-4d94-9313-f0efe2d08f93	Churchill Forge Properties	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	172730080965364	2026-05-23 00:55:24.519981	2026-05-23 00:55:24.519981	Professional	\N	\N	Real Estate	2026-06-01	\N
faa8015f-0377-49b4-8451-44bf8b988848	Athena Care Nashville	3520009d-e788-4bea-8d6a-245711cbfe42	\N	green	f	\N	\N	170318960381378	2026-05-23 00:55:24.524573	2026-05-23 00:55:24.524573	Professional	\N	\N	Healthcare	2027-01-30	\N
b4a9f5c5-4e1d-43cc-b09a-891c963329dd	GO ORTHODONTICS	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	162339066407746	2026-05-23 00:55:24.52884	2026-05-23 00:55:24.52884	Professional	\N	\N	Dental	2026-06-29	\N
d87e5b02-0d74-42ea-8121-df11c59a5b42	Stag Shop - Adult Sex Store	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	158023912654013	2026-05-23 00:55:24.533095	2026-05-23 00:55:24.533095	Professional	\N	\N	Retail	2027-01-28	\N
30af50a8-5b7a-4c65-b3cb-d26e022fa222	MISTR	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	169335416401398	2026-05-23 00:55:24.537145	2026-05-23 00:55:24.537145	Professional	\N	\N	Healthcare	2026-08-01	\N
1f4d8632-b2ca-4db2-87dc-2fc7b7ad234a	Hawaii Life Real Estate Brokers	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	148847979189944	2026-05-23 00:55:24.540779	2026-05-23 00:55:24.540779	Professional	\N	\N	Real Estate	2027-03-31	\N
0b4b4e34-75a5-4621-a499-87b20a6f24f4	Marque Urgent Care	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	173757263448560	2026-05-23 00:55:24.544581	2026-05-23 00:55:24.544581	Professional	\N	\N	Healthcare	2027-03-09	\N
8c19f92f-0776-44f3-8066-8db3509f6f82	O'Reilly Hospitality Management LLC	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	170060081266707	2026-05-23 00:55:24.548174	2026-05-23 00:55:24.548174	Professional	\N	\N	Hospitality	2026-01-31	\N
6c1d49ea-1d93-47c6-8d1f-765bd06b989d	iCode	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	169410718886310	2026-05-23 00:55:24.551645	2026-05-23 00:55:24.551645	Professional	\N	\N	Other	2027-01-09	\N
fddc981e-3c11-4c71-aac7-84256278e932	Pattillo, Brown & Hill, LLP	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	168918032518119	2026-05-23 00:55:24.55568	2026-05-23 00:55:24.55568	Professional	\N	\N	Finance	2026-07-27	\N
ce6ec982-c4e4-4801-87a7-2b25b88dc275	Informed Mortgage	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	169583695197959	2026-05-23 00:55:24.559646	2026-05-23 00:55:24.559646	Professional	\N	\N	Finance	2026-12-20	\N
d7420c43-b5a5-466e-a843-196a21bd882a	Penkert Properties, Ltd.	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	168971278047992	2026-05-23 00:55:24.563177	2026-05-23 00:55:24.563177	Professional	\N	\N	Real Estate	2026-10-07	\N
1bcfffcc-18ac-4796-bd7f-16d39dca0953	Custom Exteriors	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	159768963991915	2026-05-23 00:55:24.568075	2026-05-23 00:55:24.568075	Professional	\N	\N	Home Services	2026-08-25	\N
491398de-21db-475a-9ac5-21100c3be47d	Be Well Primary Care	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	175442873643791	2026-05-23 00:55:24.572187	2026-05-23 00:55:24.572187	Professional	\N	\N	Healthcare	2026-09-16	\N
1dc42e96-80b9-47c2-bb99-c050963474e9	Langley Health Services	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	169159393426745	2026-05-23 00:55:24.577913	2026-05-23 00:55:24.577913	Professional	\N	\N	Healthcare	2026-06-02	\N
e79302c9-0f22-4196-8059-a739a8254eef	Appletree Day Care, Inc.	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	172618287764010	2026-05-23 00:55:24.583519	2026-05-23 00:55:24.583519	Professional	\N	\N	Education	2026-10-09	\N
8817ae3c-685f-4696-9590-f7fa33191bf0	+MEDRITE Urgent Care	3520009d-e788-4bea-8d6a-245711cbfe42	\N	green	f	\N	\N	162247393064861	2026-05-23 00:55:24.58763	2026-05-23 00:55:24.58763	Professional	\N	\N	Healthcare	2026-11-25	\N
54e88da5-1e96-44eb-bc3b-0dbd3e034c74	Price Self Storage	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	161993053903651	2026-05-23 00:55:24.596546	2026-05-23 00:55:24.596546	Professional	\N	\N	Consumer Services	2026-09-16	\N
51a5d31d-0ab9-4395-9100-fe22bf901da2	DermDox Dermatology	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	171347234642797	2026-05-23 00:55:24.600228	2026-05-23 00:55:24.600228	Professional	\N	\N	Healthcare	2026-08-29	\N
a9353bbd-891a-4df6-999a-afe56f5d2fd2	Burnside Dental	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	170836269201300	2026-05-23 00:55:24.603739	2026-05-23 00:55:24.603739	Professional	\N	\N	Dental	2027-02-28	\N
08297471-443d-4e42-a7d7-5f96e5e7f8b1	Bernie & Phyl's Furniture	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	158100950567358	2026-05-23 00:55:24.607118	2026-05-23 00:55:24.607118	Professional	\N	\N	Retail	2027-03-31	\N
c229a06e-77b8-4ed9-99e8-054d905cac79	Cardiovascular Clinic of North Georgia	3520009d-e788-4bea-8d6a-245711cbfe42	\N	red	f	\N	\N	170621005776257	2026-05-23 00:55:24.61055	2026-05-23 00:55:24.61055	Professional	\N	\N	Healthcare	2027-03-29	\N
0660e3fa-0b40-4c25-8529-c3c13f5f8761	U-Stor-It Self Storage	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	169533137069555	2026-05-23 00:55:24.613911	2026-05-23 00:55:24.613911	Professional	\N	\N	Consumer Services	2026-11-29	\N
7d0167a2-3c2d-4744-a8d5-57356a106561	Foot and Ankle Specialists of Southeast Michigan	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	166509012844801	2026-05-23 00:55:24.618215	2026-05-23 00:55:24.618215	Professional	\N	\N	Healthcare	2026-10-26	\N
3b20d161-15cd-406a-9503-560014110e68	Fastwyre Broadband	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	173348915813274	2026-05-23 00:55:24.621854	2026-05-23 00:55:24.621854	Professional	\N	\N	Technology	2026-06-12	\N
83ae983d-9803-42fc-a6d6-d8cf80b3bb0a	Johnny Morris' Wonders of Wildlife National Museum and Aquarium	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	155267080420190	2026-05-23 00:55:24.625485	2026-05-23 00:55:24.625485	Professional	\N	\N	Arts & Entertainment	2027-03-26	\N
7bcc4740-b217-4ca6-9ece-103401a012b0	Rainier Properties	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	164762416220840	2026-05-23 00:55:24.6292	2026-05-23 00:55:24.6292	Professional	\N	\N	Real Estate	2027-03-31	\N
5949160d-996c-4a02-b994-dfc88aaf9b12	Therapy Brands	3520009d-e788-4bea-8d6a-245711cbfe42	\N	red	f	\N	\N	170663991983709	2026-05-23 00:55:24.63286	2026-05-23 00:55:24.63286	Professional	\N	\N	Healthcare	2027-02-17	\N
da3e987e-9a24-4e5c-a090-e031d64ddb1d	John Owens Services, Inc.	3520009d-e788-4bea-8d6a-245711cbfe42	\N	red	f	\N	\N	161317716031996	2026-05-23 00:55:24.636839	2026-05-23 00:55:24.636839	Professional	\N	\N	Contractors	2027-02-07	\N
9e5653b1-9203-40be-8cae-307ec977553a	University of Kentucky Federal Credit Union	3520009d-e788-4bea-8d6a-245711cbfe42	\N	red	f	\N	\N	162465012522385	2026-05-23 00:55:24.640366	2026-05-23 00:55:24.640366	Professional	\N	\N	Finance	2028-12-04	\N
10b037d7-7b6e-458a-974b-4c6981ed6dbf	1-800-JUNKPRO	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	172081176101075	2026-05-23 00:55:24.646308	2026-05-23 00:55:24.646308	Professional	\N	\N	Home Services	2026-07-31	\N
0fe95bce-8627-4532-b8e1-735a2a080ea4	Broadway Real Estate Services	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	171944041876935	2026-05-23 00:55:24.650745	2026-05-23 00:55:24.650745	Professional	\N	\N	Real Estate	2026-07-01	\N
f6b621de-c699-4ed7-a13a-8941c72f3b7f	The Treetop ABA	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	176522071842442	2026-05-23 00:55:24.654758	2026-05-23 00:55:24.654758	Professional	\N	\N	Healthcare	2026-12-18	\N
32a3080c-883c-4698-b365-97c3101e363e	Bemiss Dental Care	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	169265596443225	2026-05-23 00:55:24.659289	2026-05-23 00:55:24.659289	Professional	\N	\N	Dental	2026-08-25	\N
81ba3625-a4e4-4c4b-a52f-d9e29b0e5c95	Eye Specialists of Indiana	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	172712826878783	2026-05-23 00:55:24.662924	2026-05-23 00:55:24.662924	Professional	\N	\N	Healthcare	2026-10-10	\N
f55057c0-fd79-4ce8-bd4f-75849ba45a1a	McGuire Group	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	146654155638376	2026-05-23 00:55:24.66696	2026-05-23 00:55:24.66696	Professional	\N	\N	Wellness	2027-05-22	\N
9b3755b6-5deb-4e06-8685-08b4acf68976	Home Organizers, Inc.	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	169031060720588	2026-05-23 00:55:24.671392	2026-05-23 00:55:24.671392	Professional	\N	\N	Business Services	2026-09-01	\N
42620a6c-f0e0-4a02-8843-9680e0d83c95	J.J. Ratigan Brewing Company	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	168598787779777	2026-05-23 00:55:24.6754	2026-05-23 00:55:24.6754	Professional	\N	\N	Restaurants	2027-12-12	\N
c9229161-1c07-4467-8fb3-4fb106576ce7	Sky Properties	3520009d-e788-4bea-8d6a-245711cbfe42	\N	yellow	f	\N	\N	160738142777621	2026-05-23 00:55:24.679833	2026-05-23 00:55:24.679833	Professional	\N	\N	Real Estate	2026-06-23	\N
9c592b68-322e-43bf-a28a-e6c370d66b3d	Weathervane Seafood Restaurant	3520009d-e788-4bea-8d6a-245711cbfe42	\N	green	f	\N	\N	169818256168273	2026-05-23 00:55:24.685202	2026-05-23 00:55:24.685202	Professional	\N	\N	Other	2026-11-30	\N
60ba8248-fda1-461b-b9c5-61efca77b437	Wake Radiology	d0b866f0-a6d0-4944-a1d6-3e8e8ce80962	\N	green	f	\N	\N	162066457916250	2026-05-23 00:55:24.689348	2026-05-23 00:55:24.689348	Professional	\N	\N	Healthcare	2027-03-31	\N
34ee608f-e88b-4c0d-8e41-820e75367f27	Pressed Cafe	d0b866f0-a6d0-4944-a1d6-3e8e8ce80962	\N	green	f	\N	\N	176053728270501	2026-05-23 00:55:24.693153	2026-05-23 00:55:24.693153	Professional	\N	\N	Restaurants	2027-03-31	\N
2a2ce83e-40c0-47d8-a1e0-e6aacd08035d	Courtesy Driving School	d0b866f0-a6d0-4944-a1d6-3e8e8ce80962	\N	green	f	\N	\N	176901808464410	2026-05-23 00:55:24.696983	2026-05-23 00:55:24.696983	Professional	\N	\N	Education	2027-03-18	\N
5ddcb010-e58c-48b2-a13b-d66e2d1bcdf8	Lakeside Companies	d0b866f0-a6d0-4944-a1d6-3e8e8ce80962	\N	green	f	\N	\N	177273346296152	2026-05-23 00:55:24.70104	2026-05-23 00:55:24.70104	Professional	\N	\N	Finance	2027-03-12	\N
f030b252-b076-44c6-9b38-8d3b04956aa7	Today's Dental Network	a3ee215f-24e2-49fb-877b-86f3a4e8442f	\N	yellow	f	\N	\N	165247829651179	2026-05-23 00:55:24.704603	2026-05-23 00:55:24.704603	Professional	\N	\N	Dental	2027-03-31	\N
e02e7b2d-95ce-4910-8cea-4597574df9bf	Hay Creek Hotels	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	green	f	\N	\N	165107210345834	2026-05-23 00:55:24.70812	2026-05-23 00:55:24.70812	Professional	\N	\N	Hospitality	2026-09-30	\N
ecdea9b6-4d1c-4e73-b02a-993208fe86a6	The Springs Living	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	170561450413785	2026-05-23 00:55:24.711605	2026-05-23 00:55:24.711605	Professional	\N	\N	Wellness	2028-02-28	\N
e7d68d2e-5f57-45f2-868b-d7feee52ebbe	AcutePet Urgent Care	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	green	f	\N	\N	172539096904040	2026-05-23 00:55:24.715127	2026-05-23 00:55:24.715127	Professional	\N	\N	Healthcare	2028-02-18	\N
ba6dbe2f-0278-424c-a57c-ae502792cb48	Twin Liquors	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	172237035073968	2026-05-23 00:55:24.71876	2026-05-23 00:55:24.71876	Professional	\N	\N	Retail	2026-08-16	\N
b12e7257-af1b-4db8-ad6b-174034f232e1	Primary Care Center	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	164883451198296	2026-05-23 00:55:24.723041	2026-05-23 00:55:24.723041	Professional	\N	\N	Healthcare	2027-06-20	\N
5b701308-b50f-45a9-89c5-cf5c400bf342	Coastline Academy	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	green	f	\N	\N	175797083532472	2026-05-23 00:55:24.727034	2026-05-23 00:55:24.727034	Professional	\N	\N	Education	2027-11-14	\N
405e037e-568c-4e0d-a989-3bb1b8350780	Blue Stream Fiber	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	169152066661551	2026-05-23 00:55:24.731045	2026-05-23 00:55:24.731045	Professional	\N	\N	Consumer Services	2027-03-25	\N
e8a09182-19b7-4a4d-b758-94b18b01df96	Graff: Foot, Ankle & Wound Care	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	green	f	\N	\N	167278139027362	2026-05-23 00:55:24.734664	2026-05-23 00:55:24.734664	Professional	\N	\N	Healthcare	2027-08-28	\N
212be251-fbb4-4eca-ac3f-8195a0b2931c	Harms Auto Group	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	151144985182921	2026-05-23 00:55:24.739567	2026-05-23 00:55:24.739567	Professional	\N	\N	Automotive	2027-01-15	\N
8dea5d0a-d82e-4f95-8813-c877fe1e9716	950 Management, LLC	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	170723554778408	2026-05-23 00:55:24.743609	2026-05-23 00:55:24.743609	Professional	\N	\N	Real Estate	2027-07-14	\N
7382c875-d503-409c-b434-487338edf266	Citizens Community Federal National Association	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	169482536828160	2026-05-23 00:55:24.749445	2026-05-23 00:55:24.749445	Professional	\N	\N	Education	2028-08-04	\N
784de368-2b1e-40be-8a0b-1617edba17d3	UNCO	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	168659292594436	2026-05-23 00:55:24.753472	2026-05-23 00:55:24.753472	Professional	\N	\N	Restaurants	2026-06-01	\N
ba50f56d-22c6-43ca-8794-bbff4903c054	HealthTexas	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	161532676166826	2026-05-23 00:55:24.758079	2026-05-23 00:55:24.758079	Professional	\N	\N	Healthcare	2027-07-31	\N
55abafc2-5fd2-4083-a9cf-2aeed332ce3d	General Electric Credit Union	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	156087819289601	2026-05-23 00:55:24.762379	2026-05-23 00:55:24.762379	Professional	\N	\N	Finance	2026-08-29	\N
f97858a9-d4ff-4e2b-b2ab-ca152fa9c8c7	Cupbop	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	171710733835390	2026-05-23 00:55:24.766824	2026-05-23 00:55:24.766824	Professional	\N	\N	Hospitality	2027-06-26	\N
ef037f58-bfdc-4944-9a8a-1e4171f86b4c	Enthusiast Enterprises Inc.	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	green	f	\N	\N	167112289377511	2026-05-23 00:55:24.770735	2026-05-23 00:55:24.770735	Professional	\N	\N	Automotive	2026-09-30	\N
14590958-fafc-49b9-ba04-a197505bd1af	Gulf Coast Plastic Surgery	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	148104379589626	2026-05-23 00:55:24.775475	2026-05-23 00:55:24.775475	Professional	\N	\N	Healthcare	2026-05-29	\N
417a94a9-bfa2-4dc2-b53b-0e166ba94755	Pulte Financial Services	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	green	f	\N	\N	170440484314696	2026-05-23 00:55:24.779895	2026-05-23 00:55:24.779895	Professional	\N	\N	Insurance	2029-02-09	\N
0afca2bf-f82e-42fc-9e33-24cf01c5da65	MFA Medical Group	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	170681918693788	2026-05-23 00:55:24.784521	2026-05-23 00:55:24.784521	Professional	\N	\N	Healthcare	2027-02-28	\N
22c89e33-d2b7-4213-9286-b16bdf358336	BGSF	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	171631760766696	2026-05-23 00:55:24.788703	2026-05-23 00:55:24.788703	Professional	\N	\N	Business Services	2026-05-31	\N
588a3eae-e8db-4515-ba09-858e7c3ae6fc	Donaldson & Weston Personal Injury, Car Accident & Workers Comp Attorneys	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	170257141046288	2026-05-23 00:55:24.793461	2026-05-23 00:55:24.793461	Professional	\N	\N	Legal	2027-01-12	\N
e0f7224e-aa66-4f6b-a650-aefa1402af60	The Champion Companies	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	green	f	\N	\N	172730076961094	2026-05-23 00:55:24.797282	2026-05-23 00:55:24.797282	Professional	\N	\N	Real Estate	2027-06-01	\N
59db7670-276b-40ac-91da-314ffadfab04	American Bath and Shower	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	red	f	\N	\N	172182784416302	2026-05-23 00:55:24.801187	2026-05-23 00:55:24.801187	Professional	\N	\N	Contractors	2026-07-24	\N
ebd4c6f2-09fc-4a3e-9593-b2df6e179af8	Sonoran Vein and Endovascular LLC	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	168779977463475	2026-05-23 00:55:24.805704	2026-05-23 00:55:24.805704	Professional	\N	\N	Healthcare	2026-06-30	\N
b1f8596f-2d05-4472-8458-5ec756a69456	Charles E. Smith Life Communities	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	170853876881626	2026-05-23 00:55:24.810016	2026-05-23 00:55:24.810016	Professional	\N	\N	Healthcare	2027-05-21	\N
97c2cd93-6ec0-434e-9bd1-df58d79f6a2b	Kay Four Properties	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	170111154974569	2026-05-23 00:55:24.81367	2026-05-23 00:55:24.81367	Professional	\N	\N	Real Estate	2026-09-30	\N
75951e78-4919-4769-a31f-d136b499d01d	Lasik of Nevada	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	148942195225203	2026-05-23 00:55:24.822327	2026-05-23 00:55:24.822327	Professional	\N	\N	Healthcare	2026-06-13	\N
6cb11b36-9821-4498-94bb-0854b28828d5	T3 Services group	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	green	f	\N	\N	174671777595569	2026-05-23 00:55:24.826679	2026-05-23 00:55:24.826679	Professional	\N	\N	Home Services	2026-06-30	\N
94b65fa7-93ed-477b-83d8-d22ed995cef9	Dewey's Pizza	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	green	f	\N	\N	175831769674964	2026-05-23 00:55:24.831016	2026-05-23 00:55:24.831016	Professional	\N	\N	Restaurants	2026-12-30	\N
a748a4ad-6385-422f-9f33-e7bee48a8d68	Blue Magma Residential	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	green	f	\N	\N	164183713308018	2026-05-23 00:55:24.835453	2026-05-23 00:55:24.835453	Professional	\N	\N	Real Estate	2028-04-18	\N
771684a4-be0f-4002-ab71-ce3addeff9c2	Spacious Skies Campgrounds	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	172427472445474	2026-05-23 00:55:24.839442	2026-05-23 00:55:24.839442	Professional	\N	\N	Recreation	2026-08-30	\N
546a2782-ae2b-49f5-8389-c14051fe507e	Aqua-Flo Supply	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	171388630187962	2026-05-23 00:55:24.84307	2026-05-23 00:55:24.84307	Professional	\N	\N	Contractors	2026-05-30	\N
1770a623-3423-4a2b-98f2-291ce678c3c2	Municipal Credit Union	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	168788263652650	2026-05-23 00:55:24.847017	2026-05-23 00:55:24.847017	Professional	\N	\N	Finance	2027-04-02	\N
f897279e-5414-456c-a54c-a8000b9810bc	Robbins Estate Law ( earlier: The law offices of Kyle Robbins)	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	red	f	\N	\N	166913739878618	2026-05-23 00:55:24.851049	2026-05-23 00:55:24.851049	Professional	\N	\N	Legal	2026-11-22	\N
84b1e464-c99b-4ad2-be4b-c6974c07540d	FAROS PROPERTIES	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	166117448820327	2026-05-23 00:55:24.855017	2026-05-23 00:55:24.855017	Professional	\N	\N	Real Estate	2028-03-20	\N
3a4566b4-ace4-404c-bcd7-222f69c6cbc6	MacGillis Law group	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	175769065993981	2026-05-23 00:55:24.860652	2026-05-23 00:55:24.860652	Professional	\N	\N	Professional Services	2026-11-29	\N
209dc1d2-d5fc-4cea-8e8b-41867abb55c4	EI US, LLC d/b/a LearnWell	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	162203560585197	2026-05-23 00:55:24.864584	2026-05-23 00:55:24.864584	Professional	\N	\N	Healthcare	2026-09-05	\N
a835cfe1-dccf-4e8e-9055-f1f5648cabfc	MCCA -	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	red	f	\N	\N	171520174820536	2026-05-23 00:55:24.868305	2026-05-23 00:55:24.868305	Professional	\N	\N	Healthcare	2028-05-13	\N
84dca819-fd05-4813-bb53-600a04d3bbf4	Carlsbad Management Group, LLC	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	172730062649436	2026-05-23 00:55:24.873539	2026-05-23 00:55:24.873539	Professional	\N	\N	Real Estate	2026-06-01	\N
22c57e7d-b9b0-4b86-9757-f2e10d9a8b1a	Bravo Pizza Ny	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	171821475067297	2026-05-23 00:55:24.877698	2026-05-23 00:55:24.877698	Professional	\N	\N	Restaurants	2026-06-20	\N
69658616-98fe-4951-b881-48e7ef79ae13	EZ Storage	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	148303888833376	2026-05-23 00:55:24.881702	2026-05-23 00:55:24.881702	Professional	\N	\N	Consumer Services	2026-02-07	\N
1d35f80b-0df4-4fa6-abb5-95149d7fa9fa	Meyer, Inc.	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	red	f	\N	\N	171113906175457	2026-05-23 00:55:24.88543	2026-05-23 00:55:24.88543	Professional	\N	\N	Transportation Services	2027-04-12	\N
438f5c45-3d93-40c1-9bc6-e57058f06ced	Michigan Educational Credit Union	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	green	f	\N	\N	162217011497245	2026-05-23 00:55:24.889301	2026-05-23 00:55:24.889301	Professional	\N	\N	Finance	2026-12-15	\N
33bb5560-7257-40f8-8489-f77a57bb80a6	Dental Wellness Centers	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	169237516578564	2026-05-23 00:55:24.892893	2026-05-23 00:55:24.892893	Professional	\N	\N	Dental	2026-09-29	\N
db3d2346-3173-4295-9ffb-61164825642f	Dr. Jason Clapp	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	157186005786818	2026-05-23 00:55:24.896766	2026-05-23 00:55:24.896766	Professional	\N	\N	Dental	2026-10-23	\N
8d15200f-f8d2-4074-b933-bad66c0cb736	Kaplan Companies	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	166871394719903	2026-05-23 00:55:24.900613	2026-05-23 00:55:24.900613	Professional	\N	\N	Real Estate	2028-03-12	\N
4fbe88cc-953d-4d32-9481-2067f2f0bd50	Clarity Debt Resolution Inc.	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	red	f	\N	\N	168914041059578	2026-05-23 00:55:24.904689	2026-05-23 00:55:24.904689	Professional	\N	\N	Finance	2026-09-03	\N
1f566198-cda5-4bb7-bc7d-c9f2227bf1c9	Georgia World Congress Center	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	149946159153889	2026-05-23 00:55:24.908785	2026-05-23 00:55:24.908785	Professional	\N	\N	Arts & Entertainment	2026-07-31	\N
d05eb71b-d1ab-4ead-b417-bb373b44e8f1	Navia Benefit Solutions	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	red	f	\N	\N	169774980806439	2026-05-23 00:55:24.912948	2026-05-23 00:55:24.912948	Professional	\N	\N	Insurance	2026-11-21	\N
d253bc83-1ba3-4eca-b379-94f66fafa81c	Dugas Dental	876973fb-f662-4aca-adc5-c2e8a73af6fc	\N	yellow	f	\N	\N	173966167575418	2026-05-23 00:55:24.91669	2026-05-23 00:55:24.91669	Professional	\N	\N	Dental	2027-03-09	\N
225e47c5-fd97-4afa-a9f9-33858a49ee87	Blue Sky MD	080fe6ed-33cc-4a27-b352-0835b6747dfb	\N	yellow	f	\N	\N	148829660074646	2026-05-23 00:55:24.922976	2026-05-23 00:55:24.922976	Professional	\N	\N	Wellness	2027-03-01	\N
db909237-53ec-4a00-ab95-5e71286dc852	Kindred Homes	11ddb44f-8c90-4b88-89a3-ccad4c1693d7	\N	green	f	\N	\N	176763306857946	2026-05-23 00:55:24.927219	2026-05-23 00:55:24.927219	Professional	\N	\N	Construction	2027-02-24	\N
28c9cec1-66f9-4606-8725-a13586f4a00c	Integrated Real Estate Group	11ddb44f-8c90-4b88-89a3-ccad4c1693d7	\N	green	f	\N	\N	176954605304716	2026-05-23 00:55:24.93139	2026-05-23 00:55:24.93139	Professional	\N	\N	Real Estate	2027-03-20	\N
88387e86-7412-4716-843d-ddf64afda6e3	The 401 Group of Companies	11ddb44f-8c90-4b88-89a3-ccad4c1693d7	\N	red	f	\N	\N	177576771102246	2026-05-23 00:55:24.935141	2026-05-23 00:55:24.935141	Professional	\N	\N	Other	2027-04-29	\N
15765317-4852-4dbb-9e29-e99ef489e286	Craig Kelley and Faultless LLC	11ddb44f-8c90-4b88-89a3-ccad4c1693d7	\N	yellow	f	\N	\N	176712906884739	2026-05-23 00:55:24.938517	2026-05-23 00:55:24.938517	Professional	\N	\N	Legal	2026-12-31	\N
94359f34-3e8b-4049-94c2-e982e82b27fb	Landmark Event Co.	11ddb44f-8c90-4b88-89a3-ccad4c1693d7	\N	yellow	f	\N	\N	176300656740079	2026-05-23 00:55:24.941775	2026-05-23 00:55:24.941775	Professional	\N	\N	Hospitality	2026-12-28	\N
1b30e1ab-313e-423c-9c0b-15570654c919	SonderMind	1bb5bb0b-c655-478b-9f7b-dd692dcb181a	\N	yellow	f	\N	\N	173818288504976	2026-05-23 00:55:24.945719	2026-05-23 00:55:24.945719	Professional	\N	\N	Healthcare	2027-03-30	\N
3dc27df3-48cf-427d-8d31-aeaac8b5efb5	Trilogy Services AC	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	165169745468983	2026-05-23 00:55:24.949405	2026-05-23 00:55:24.949405	Professional	\N	\N	Contractors	2027-05-29	\N
ba80aca6-c9eb-4154-9875-449b8c51784f	Alco Management	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	170188889088414	2026-05-23 00:55:24.954114	2026-05-23 00:55:24.954114	Professional	\N	\N	Real Estate	2027-02-28	\N
5bc983ea-915e-4973-9e81-fceeb860530f	Steinhafels	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	161902627042953	2026-05-23 00:55:24.96272	2026-05-23 00:55:24.96272	Professional	\N	\N	Retail	2026-11-29	\N
9c2b69a3-3464-4a12-b467-e55297cd62a2	LAFCU	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	168478288271016	2026-05-23 00:55:24.967271	2026-05-23 00:55:24.967271	Professional	\N	\N	Finance	2026-03-31	\N
86aa694c-bfae-4769-827e-25d5ee71de47	Coastal1 Credit Union	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	171596122722264	2026-05-23 00:55:24.971187	2026-05-23 00:55:24.971187	Professional	\N	\N	Finance	2026-12-02	\N
fa31171d-9f95-401d-8c4a-e5599368d579	Mama Justice - MW Law Firm	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	166792582362707	2026-05-23 00:55:24.975479	2026-05-23 00:55:24.975479	Professional	\N	\N	Legal	2026-11-10	\N
703f7194-5f89-4811-b9e0-0a0018ab31b9	Gardner Mill Company	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	167417198192146	2026-05-23 00:55:24.979125	2026-05-23 00:55:24.979125	Professional	\N	\N	Retail	2028-01-30	\N
56672d4c-b228-4d8f-8b3a-df9fcae31831	ALIYA Healthcare	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	174292154022068	2026-05-23 00:55:24.982679	2026-05-23 00:55:24.982679	Professional	\N	\N	Healthcare	2027-03-27	\N
df5769a6-5d5a-4c14-b3be-669cb0768462	Ozarks Medical Center	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	163915404730925	2026-05-23 00:55:24.986183	2026-05-23 00:55:24.986183	Professional	\N	\N	Healthcare	2026-10-01	\N
d45df934-c25d-4a9f-a6aa-1c7c1bf9f493	Alert 360 Home Security	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	152279603126556	2026-05-23 00:55:24.989798	2026-05-23 00:55:24.989798	Professional	\N	\N	Home Services	2026-06-30	\N
e7e93f57-7095-4900-8d9d-f26b59ca1664	Wash Hounds Express Car Wash & Oil Change	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	167356639361666	2026-05-23 00:55:24.99336	2026-05-23 00:55:24.99336	Professional	\N	\N	Automotive	2027-02-16	\N
6bc3b231-97f4-427b-928d-00429b3c60db	Sharky's Woodfired Mexican Grill	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	174342718792494	2026-05-23 00:55:24.996793	2026-05-23 00:55:24.996793	Professional	\N	\N	Restaurants	2028-04-27	\N
2b646e98-9210-4f2d-912c-e8b4b854c442	Americor	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	154205045457076	2026-05-23 00:55:25.000348	2026-05-23 00:55:25.000348	Professional	\N	\N	Finance	2026-10-20	\N
52bddb19-6bc7-4339-b5e1-41e3e5ea078f	Medical Marijuana Treatment Clinics of Florida	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	152062794858021	2026-05-23 00:55:25.003972	2026-05-23 00:55:25.003972	Professional	\N	\N	Wellness	2027-03-28	\N
d1bb7fbc-7fee-4a73-bf05-88f5897213c9	Fitzrovia Property Management	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	160754898647966	2026-05-23 00:55:25.007855	2026-05-23 00:55:25.007855	Professional	\N	\N	Real Estate	2028-04-08	\N
674d1f0b-8766-45fa-97b1-4a9ed63ddb5a	Progressive Spine & Orthopaedics	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	175761468308363	2026-05-23 00:55:25.012191	2026-05-23 00:55:25.012191	Professional	\N	\N	Healthcare	2026-09-15	\N
840796c8-3fff-45fb-b67a-a034355badf0	Elite Tree Service AZ	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	159130508928133	2026-05-23 00:55:25.015943	2026-05-23 00:55:25.015943	Professional	\N	\N	Home Services	2026-06-12	\N
9713ec94-5a1a-411f-a7ba-327ad476794a	AZ Club Prep	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	175346918941967	2026-05-23 00:55:25.022731	2026-05-23 00:55:25.022731	Professional	\N	\N	Recreation	2026-07-31	\N
75e88b1b-75c0-46b6-a1a9-3ceb19a4b445	Smiles Family Dental	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	165973374111478	2026-05-23 00:55:25.029763	2026-05-23 00:55:25.029763	Professional	\N	\N	Dental	2026-08-05	\N
eb91734b-690d-4423-86a3-424e6a591088	Mid-Florida Prosthetics and Orthotics	c9d3c854-c559-4822-8013-1b42b3618e47	\N	red	f	\N	\N	174292363762251	2026-05-23 00:55:25.033592	2026-05-23 00:55:25.033592	Professional	\N	\N	Healthcare	2027-03-30	\N
a9c10452-514f-4252-afac-677461dcd246	Digestive Associates	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	161697523355904	2026-05-23 00:55:25.042684	2026-05-23 00:55:25.042684	Professional	\N	\N	Healthcare	2027-03-30	\N
80a9ad8f-69c5-4b18-bd91-97ddd9f0bbbe	EJ's Auto World	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	169997784939843	2026-05-23 00:55:25.046955	2026-05-23 00:55:25.046955	Professional	\N	\N	Automotive	2026-11-14	\N
f667c928-bc9e-44a8-b8cb-4e9294cb084f	Honolulu Plastic Surgery LLC	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	172919588524625	2026-05-23 00:55:25.051309	2026-05-23 00:55:25.051309	Professional	\N	\N	Healthcare	2026-10-21	\N
4672d03b-f403-448e-a794-d620f307bf92	26 Medical LLC	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	175432725396872	2026-05-23 00:55:25.0551	2026-05-23 00:55:25.0551	Professional	\N	\N	Healthcare	2027-09-02	\N
78e4738e-ce1a-4401-98ba-88c0ec25d0c5	Shouse Law Group	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	144121714747743	2026-05-23 00:55:25.058935	2026-05-23 00:55:25.058935	Professional	\N	\N	Legal	2027-02-15	\N
f11bbd7e-1dd8-4cc2-97c7-296d1edbe168	Minuteman Press of Myrtle Beach	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	167821819283434	2026-05-23 00:55:25.062926	2026-05-23 00:55:25.062926	Professional	\N	\N	Consumer Services	2027-04-06	\N
76764ec8-fd95-4707-941a-ef89359f98e2	OC VeinCare	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	158283741421032	2026-05-23 00:55:25.066342	2026-05-23 00:55:25.066342	Professional	\N	\N	Healthcare	2026-05-31	\N
aae84961-9a7a-4a0c-a878-3e68a7375f0e	Car Pool LLC	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	167458120768075	2026-05-23 00:55:25.069937	2026-05-23 00:55:25.069937	Professional	\N	\N	Automotive	2027-01-31	\N
81373ff4-3e17-4ba0-829f-1ea25a120087	Dr. Kelly's Surgical Unit	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	156927612707316	2026-05-23 00:55:25.073642	2026-05-23 00:55:25.073642	Professional	\N	\N	Healthcare	2027-02-16	\N
db3ec8cc-9285-434f-9f12-89db8c6308e7	Sheppard Auto Group	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	173706894069504	2026-05-23 00:55:25.078113	2026-05-23 00:55:25.078113	Professional	\N	\N	Automotive	2027-01-29	\N
53e6932e-129b-4ab1-9ce6-1fae9ce4bb1f	Tonis Garage Doors	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	164149520212429	2026-05-23 00:55:25.083333	2026-05-23 00:55:25.083333	Professional	\N	\N	Home Services	2027-01-05	\N
a079a42a-aa16-406c-8cf5-618c2f474ce6	Martin's Caterers	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	170569070269947	2026-05-23 00:55:25.087392	2026-05-23 00:55:25.087392	Professional	\N	\N	Hospitality	2027-02-20	\N
71f27222-d554-43ea-a71f-6d001a416424	Zion Utah Jellystone Park	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	172064137958166	2026-05-23 00:55:25.091784	2026-05-23 00:55:25.091784	Professional	\N	\N	Arts & Entertainment	2026-07-10	\N
170be214-cd92-4575-b5e1-c4227adc542b	Geoff McDonald & Associates	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	149978322052382	2026-05-23 00:55:25.095794	2026-05-23 00:55:25.095794	Professional	\N	\N	Legal	2026-10-25	\N
2520e25f-a9fd-44cc-91f7-ae8167063766	McArthur Law Firm	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	167829337094491	2026-05-23 00:55:25.099526	2026-05-23 00:55:25.099526	Professional	\N	\N	Legal	2027-03-20	\N
35bb8bc0-40e0-46de-b73c-54ef0cb79fb1	Spirit of Santa Fe	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	174199245559184	2026-05-23 00:55:25.104256	2026-05-23 00:55:25.104256	Professional	\N	\N	Consumer Goods	2027-03-14	\N
91a68d7e-9136-4353-9518-8b934671f04d	Autos By Nelson	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	168684268948614	2026-05-23 00:55:25.108546	2026-05-23 00:55:25.108546	Professional	\N	\N	Automotive	2026-07-27	\N
55408b67-3a48-4a16-a53d-1d0c6220d540	All Valley Home Health Care & Nursing	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	166016103269944	2026-05-23 00:55:25.112761	2026-05-23 00:55:25.112761	Professional	\N	\N	Healthcare	2027-09-29	\N
058e7484-1656-491b-880b-642e038f4a22	Bloom Dental - Downtown	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	173548349110851	2026-05-23 00:55:25.116407	2026-05-23 00:55:25.116407	Professional	\N	\N	Dental	2027-01-13	\N
b17f472a-7fda-43e1-af8d-51da8d281c29	Wonder Years Psychiatric Services	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	172243675217241	2026-05-23 00:55:25.122453	2026-05-23 00:55:25.122453	Professional	\N	\N	Healthcare	2027-03-20	\N
7d1fb285-395a-47ea-91d6-2c545d0d87ea	Fairchild Tropical Botanic Garden	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	174732071898339	2026-05-23 00:55:25.126028	2026-05-23 00:55:25.126028	Professional	\N	\N	Arts & Entertainment	2026-06-06	\N
0e30e883-3f66-458a-bb48-86ae7b615cfb	Nation's Pure Water Systems	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	152209783627031	2026-05-23 00:55:25.130432	2026-05-23 00:55:25.130432	Professional	\N	\N	Home Services	2027-04-10	\N
e76e3f46-0f07-4979-bae3-745dcc35ec96	The Rose Clinic	c9d3c854-c559-4822-8013-1b42b3618e47	\N	green	f	\N	\N	155070522751329	2026-05-23 00:55:25.134412	2026-05-23 00:55:25.134412	Professional	\N	\N	Healthcare	2027-02-20	\N
b54bc99f-5fda-492e-a294-f8527a49ed80	Clinton Wilkins Mortgage Team	c9d3c854-c559-4822-8013-1b42b3618e47	\N	yellow	f	\N	\N	156390166067678	2026-05-23 00:55:25.140489	2026-05-23 00:55:25.140489	Professional	\N	\N	Finance	2026-08-28	\N
d450bd9e-88d7-4414-9b79-6aa8767c17d4	Marquis Companies	54ab8b97-6679-4284-ba1b-850ea562722a	\N	red	f	\N	\N	162067069038892	2026-05-23 00:55:25.144386	2026-05-23 00:55:25.144386	Professional	\N	\N	Wellness	2027-05-20	\N
f0f4fecb-ae5f-4fa5-89e6-77c9c5264c3e	Wellhaven	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	169791063653458	2026-05-23 00:55:25.148801	2026-05-23 00:55:25.148801	Professional	\N	\N	Healthcare	2027-12-31	\N
bcde9248-270d-48d2-9ba7-d04e2998c69c	Pure Psychiatry of Michigan	54ab8b97-6679-4284-ba1b-850ea562722a	\N	green	f	\N	\N	169541080274586	2026-05-23 00:55:25.153098	2026-05-23 00:55:25.153098	Professional	\N	\N	Healthcare	2027-08-29	\N
45127996-ea52-4675-8f8a-9b068a10878b	Galen Medical Group	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	175583190104260	2026-05-23 00:55:25.156732	2026-05-23 00:55:25.156732	Professional	\N	\N	Healthcare	2026-12-31	\N
10475156-3d5e-4365-b22b-5b71adaacb15	Strive Compounding Pharmacy	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	170241167990827	2026-05-23 00:55:25.16091	2026-05-23 00:55:25.16091	Professional	\N	\N	Healthcare	2027-01-30	\N
114a0acc-d263-42f8-85de-659c3f20adb8	NSPC Brain & Spine Surgery	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	155007691738564	2026-05-23 00:55:25.164754	2026-05-23 00:55:25.164754	Professional	\N	\N	Healthcare	2026-05-22	\N
536f3bc0-fecd-4036-8296-58774f85aaf8	Eagle Carports, Inc. (Corporate Office)	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	173341738344951	2026-05-23 00:55:25.168457	2026-05-23 00:55:25.168457	Professional	\N	\N	Contractors	2026-12-18	\N
ba10aaba-4c0e-4681-ba14-873f1d8a99cc	Victory Medical	54ab8b97-6679-4284-ba1b-850ea562722a	\N	green	f	\N	\N	170265302838162	2026-05-23 00:55:25.173141	2026-05-23 00:55:25.173141	Professional	\N	\N	Wellness	2027-02-21	\N
8c1841ec-a8eb-48c7-bb74-dc662629af09	Boardwalk Storage - Killian's	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	162320113003450	2026-05-23 00:55:25.177063	2026-05-23 00:55:25.177063	Professional	\N	\N	Contractors	2027-03-02	\N
f770cbad-110f-4151-9fc5-65370a4057b8	Scotto Properties	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	172123094530667	2026-05-23 00:55:25.180691	2026-05-23 00:55:25.180691	Professional	\N	\N	Real Estate	2026-08-13	\N
c642b7ef-864b-406c-86ec-9b1db1385a12	Legacy Residential	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	174172128804031	2026-05-23 00:55:25.184322	2026-05-23 00:55:25.184322	Professional	\N	\N	Real Estate	2027-03-25	\N
cc998a0e-622b-4741-8d04-897f7f8d8cde	Luxe Laundries	54ab8b97-6679-4284-ba1b-850ea562722a	\N	green	f	\N	\N	172444525443538	2026-05-23 00:55:25.187957	2026-05-23 00:55:25.187957	Professional	\N	\N	Consumer Services	2026-06-02	\N
f645e607-61c6-480b-957a-e1da43447101	DBS Residential Solutions	54ab8b97-6679-4284-ba1b-850ea562722a	\N	green	f	\N	\N	173894158318944	2026-05-23 00:55:25.191895	2026-05-23 00:55:25.191895	Professional	\N	\N	Contractors	2028-02-26	\N
6fea3be9-168e-44f5-b7a1-8856ac038d98	Avalon Health Care	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	152782566119604	2026-05-23 00:55:25.195563	2026-05-23 00:55:25.195563	Professional	\N	\N	Healthcare	2026-05-31	\N
7dbea991-4ac9-4e36-8007-7c77c4ff97e2	Citadel Roofing & Solar	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	155984840880546	2026-05-23 00:55:25.199446	2026-05-23 00:55:25.199446	Professional	\N	\N	Contractors	2026-06-21	\N
f20888e7-dded-48fc-9a48-1032114460bc	Exclusive Furniture	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	161170415251610	2026-05-23 00:55:25.203979	2026-05-23 00:55:25.203979	Professional	\N	\N	Retail	2026-10-07	\N
c956f981-bb70-4600-af76-10dbfb9f4106	NP Dodge	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	172739236974413	2026-05-23 00:55:25.207799	2026-05-23 00:55:25.207799	Professional	\N	\N	Real Estate	2026-05-31	\N
633dd2c1-f1e1-4d4f-8764-8f646d2a9311	Gene Juarez Salon & Spa	54ab8b97-6679-4284-ba1b-850ea562722a	\N	green	f	\N	\N	167346965934855	2026-05-23 00:55:25.21182	2026-05-23 00:55:25.21182	Professional	\N	\N	Beauty	2027-02-06	\N
70c2f33c-3067-4850-b030-e49f77c0d4e9	Ebenezer	54ab8b97-6679-4284-ba1b-850ea562722a	\N	red	f	\N	\N	174795369450639	2026-05-23 00:55:25.215927	2026-05-23 00:55:25.215927	Professional	\N	\N	Healthcare	2026-05-29	\N
d44a9525-8af8-4fb8-850f-c7d4cc384861	Safavieh Home Furnishings	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	156209598606152	2026-05-23 00:55:25.220034	2026-05-23 00:55:25.220034	Professional	\N	\N	Retail	2026-07-09	\N
c46b698f-0d4b-40c1-89ee-b6529aff3f59	Cinergy Entertainment Group	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	173401773312173	2026-05-23 00:55:25.226109	2026-05-23 00:55:25.226109	Professional	\N	\N	Arts & Entertainment	2026-12-31	\N
0f8abe48-e6ad-489e-932d-366c03c07472	Second Specs	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	175189341222521	2026-05-23 00:55:25.230394	2026-05-23 00:55:25.230394	Professional	\N	\N	Healthcare	2026-09-25	\N
54acae1b-e312-4503-8996-52c2406c18f7	Ethos Hospitality Group	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	175881985531074	2026-05-23 00:55:25.234613	2026-05-23 00:55:25.234613	Professional	\N	\N	Restaurants	2026-09-26	\N
abf862b1-b145-4a0f-b742-4cfd7ca0577a	Brandywine Homes USA Atlanta	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	168011564999694	2026-05-23 00:55:25.238356	2026-05-23 00:55:25.238356	Professional	\N	\N	Home Services	2027-04-20	\N
955abb85-bf24-4606-9826-b665f5209888	Purchase Park 2 Fly	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	174498890222942	2026-05-23 00:55:25.242379	2026-05-23 00:55:25.242379	Professional	\N	\N	Automotive	2027-04-18	\N
03982fea-14b3-4a7d-875c-cead3a7bd499	Jackson Health System	54ab8b97-6679-4284-ba1b-850ea562722a	\N	green	f	\N	\N	173877800526571	2026-05-23 00:55:25.246137	2026-05-23 00:55:25.246137	Professional	\N	\N	Healthcare	2026-07-10	\N
768e9773-f8fe-4ebe-b24d-4086210a0d7d	GatorGuard Concrete Coatings	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	155354447715266	2026-05-23 00:55:25.250177	2026-05-23 00:55:25.250177	Professional	\N	\N	Contractors	2027-07-01	\N
c7cf349e-92d4-496f-abab-cdf00ff321a8	Lutheran Life Villages	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	162214578862504	2026-05-23 00:55:25.254444	2026-05-23 00:55:25.254444	Professional	\N	\N	Wellness	2026-05-23	\N
3567117e-80b2-439c-b317-de7814d64f86	Power Finance Texas	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	156761037155604	2026-05-23 00:55:25.258847	2026-05-23 00:55:25.258847	Professional	\N	\N	Finance	2026-11-30	\N
ae627e94-3d32-4fe3-95d0-e0eb819bddf1	Arroyo Vista Family Health Foundation	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	170500790459288	2026-05-23 00:55:25.266167	2026-05-23 00:55:25.266167	Professional	\N	\N	Healthcare	2027-03-06	\N
f2bd2fa6-cf7e-490f-8f48-e56f4d2b4f2e	Attic Selfstor LLC	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	171586600761166	2026-05-23 00:55:25.272317	2026-05-23 00:55:25.272317	Professional	\N	\N	Consumer Services	2026-09-27	\N
b68b307e-b8da-40c9-b1a2-5a657b7715fa	The Mold Pros of Florida	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	174075619032407	2026-05-23 00:55:25.27657	2026-05-23 00:55:25.27657	Professional	\N	\N	Contractors	2027-03-25	\N
a6f122a5-2691-4c94-beb9-f1d63c827122	TruForce Pest Control	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	163173822628705	2026-05-23 00:55:25.2806	2026-05-23 00:55:25.2806	Professional	\N	\N	Home Services	2026-09-15	\N
7a020692-accd-4706-aacd-78e8afd68673	All One Storage LLC	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	162732925079596	2026-05-23 00:55:25.284393	2026-05-23 00:55:25.284393	Professional	\N	\N	Consumer Services	2026-05-31	\N
2fec911c-29e0-46de-92fd-67c002a13b7d	Prime Pediatric Dental Group	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	171536270794183	2026-05-23 00:55:25.287756	2026-05-23 00:55:25.287756	Professional	\N	\N	Dental	2027-03-03	\N
5659cdc6-44f3-4e1e-addb-a98797530095	Evergreene Management	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	172730227645373	2026-05-23 00:55:25.291484	2026-05-23 00:55:25.291484	Professional	\N	\N	Real Estate	2027-04-22	\N
fdea2ea4-e0b4-4710-9317-a31c0f7d0457	Ulrich Lifestyle Structures	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	172364382877207	2026-05-23 00:55:25.295248	2026-05-23 00:55:25.295248	Professional	\N	\N	Construction	2028-06-30	\N
c5ab63f6-3c98-4e71-b274-c4bbecb74bbc	MJHS Health System	54ab8b97-6679-4284-ba1b-850ea562722a	\N	red	f	\N	\N	172105546580608	2026-05-23 00:55:25.305855	2026-05-23 00:55:25.305855	Professional	\N	\N	Healthcare	2027-02-24	\N
d4a60daf-25d8-4390-9d92-afec65161bde	Zane Grey RV Village	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	174042314603560	2026-05-23 00:55:25.309674	2026-05-23 00:55:25.309674	Professional	\N	\N	Hospitality	2027-03-27	\N
94258bf9-10ca-44f3-845d-0ed8be409ca9	Tri City National Bank	54ab8b97-6679-4284-ba1b-850ea562722a	\N	green	f	\N	\N	175077725320819	2026-05-23 00:55:25.313155	2026-05-23 00:55:25.313155	Professional	\N	\N	Finance	2027-07-25	\N
084f4f5a-aa6e-4494-b4b6-f34ee7ec70d6	R&G Brenner	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	165850344643137	2026-05-23 00:55:25.316981	2026-05-23 00:55:25.316981	Professional	\N	\N	Finance	2026-12-29	\N
af918409-c2a5-4ea9-b8b7-6ecb8f447443	The Kidney Experts	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	169904779263184	2026-05-23 00:55:25.323266	2026-05-23 00:55:25.323266	Professional	\N	\N	Healthcare	2026-12-29	\N
042c3f0e-bf52-4adc-b2ee-26f0f60bb96d	Turner Medical Arts	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	161247150690886	2026-05-23 00:55:25.330343	2026-05-23 00:55:25.330343	Professional	\N	\N	Healthcare	2026-12-01	\N
f770a49f-20e7-40a1-8652-a5eb7a1e5a24	Shorehaven Behavioral Health, Inc	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	174222508618560	2026-05-23 00:55:25.335668	2026-05-23 00:55:25.335668	Professional	\N	\N	Healthcare	2027-03-18	\N
bfbdc488-1cd3-4f28-a07b-016e00c136fb	The Tree Place	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	165671159722380	2026-05-23 00:55:25.343753	2026-05-23 00:55:25.343753	Professional	\N	\N	Home Services	2026-07-27	\N
5b655785-2072-43e2-a844-ba87ddc44e96	Sun Country Marine Group (SCMG)	54ab8b97-6679-4284-ba1b-850ea562722a	\N	red	f	\N	\N	151880204210921	2026-05-23 00:55:25.351734	2026-05-23 00:55:25.351734	Professional	\N	\N	Automotive	2027-02-16	\N
17884995-537b-41eb-99aa-6fa3ad39396c	Wake Forest Endodontics	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	156874154854498	2026-05-23 00:55:25.359993	2026-05-23 00:55:25.359993	Professional	\N	\N	Dental	2027-05-17	\N
44eeb67a-6ba6-4383-b089-e674f698f7a7	Pacific Hair Loss Solutions	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	153970983975959	2026-05-23 00:55:25.363968	2026-05-23 00:55:25.363968	Professional	\N	\N	Beauty	2026-10-16	\N
e632adcf-c83e-47de-b7ee-14c81f6e6684	Street Legal Golf Cart Rentals, Sales & Service - Miramar Beach/Destin	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	171173014300638	2026-05-23 00:55:25.376355	2026-05-23 00:55:25.376355	Professional	\N	\N	Transportation Services	2026-05-29	\N
a715d28a-dbdc-4308-96d1-e70430d78312	Nothing Bundt Cakes - OK	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	174526764291331	2026-05-23 00:55:25.380122	2026-05-23 00:55:25.380122	Professional	\N	\N	Restaurants	2027-04-30	\N
d732bb8c-c563-4c58-949a-900e54ac1bfd	Impriano Roofing	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	165239569066624	2026-05-23 00:55:25.383824	2026-05-23 00:55:25.383824	Professional	\N	\N	Construction	2026-06-22	\N
45dde748-08f8-46f7-88d8-ad0e01680562	Cosmetic Dermatology Center	54ab8b97-6679-4284-ba1b-850ea562722a	\N	green	f	\N	\N	173946866963710	2026-05-23 00:55:25.387483	2026-05-23 00:55:25.387483	Professional	\N	\N	Healthcare	2027-02-13	\N
7e4c639d-b7c2-45c0-8ec5-a52328e84623	Boutique Apartments	54ab8b97-6679-4284-ba1b-850ea562722a	\N	red	f	\N	\N	149581663020602	2026-05-23 00:55:25.391294	2026-05-23 00:55:25.391294	Professional	\N	\N	Real Estate	2026-05-27	\N
7af56e45-df95-4214-8bc4-041de2a45143	Burton Urgent Care	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	173697952254778	2026-05-23 00:55:25.396659	2026-05-23 00:55:25.396659	Professional	\N	\N	Healthcare	2027-01-17	\N
04dc41e3-07c7-4d6f-a0e5-27b9e21de5c7	KEEP.Rentals Self Storage	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	173403773494017	2026-05-23 00:55:25.40339	2026-05-23 00:55:25.40339	Professional	\N	\N	Transportation Services	2026-12-13	\N
d823caa7-0872-428d-b3f9-34e8449ff1a3	The Eastwood Company	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	165221588702998	2026-05-23 00:55:25.411444	2026-05-23 00:55:25.411444	Professional	\N	\N	Automotive	2026-05-23	\N
a519a954-c94b-47d3-8913-648f8a14e73e	University Pain Centers	54ab8b97-6679-4284-ba1b-850ea562722a	\N	yellow	f	\N	\N	174345126891608	2026-05-23 00:55:25.415382	2026-05-23 00:55:25.415382	Professional	\N	\N	Healthcare	2027-05-19	\N
8d7b3271-d9c3-4f63-b0f7-64105b70166e	Ring's End	4d90d894-3886-44fc-8cb5-66b5fadeff4b	\N	green	f	\N	\N	177084467386941	2026-05-23 00:55:25.418716	2026-05-23 00:55:25.418716	Professional	\N	\N	Home Services	2027-02-26	\N
f47479be-9623-479c-8a07-62e7699fdbc2	DuGood Federal Credit Union	4d90d894-3886-44fc-8cb5-66b5fadeff4b	\N	green	f	\N	\N	176461125297878	2026-05-23 00:55:25.422563	2026-05-23 00:55:25.422563	Professional	\N	\N	Finance	2027-03-26	\N
b2bf275b-4bd7-4a5b-a66e-f4d1e7ebbdfa	Radiant Complexions Dermatology Clinics	018ffd1e-b602-4cb9-911f-210585f78a29	\N	green	f	\N	\N	162127350530657	2026-05-23 00:55:25.426245	2026-05-23 00:55:25.426245	Professional	\N	\N	Healthcare	2027-03-18	\N
43b5eb26-a7ac-4be4-8db6-bcc99bc5cd9f	GoodVets	018ffd1e-b602-4cb9-911f-210585f78a29	\N	green	f	\N	\N	170483347202679	2026-05-23 00:55:25.430061	2026-05-23 00:55:25.430061	Professional	\N	\N	Healthcare	2027-04-10	\N
e3555451-dfee-4227-8b62-a8e3cc2f30f6	Red Oak Apartment Homes	018ffd1e-b602-4cb9-911f-210585f78a29	\N	green	f	\N	\N	167457668984487	2026-05-23 00:55:25.44232	2026-05-23 00:55:25.44232	Professional	\N	\N	Real Estate	2027-03-29	\N
1e916de8-3ec0-4e14-8ab3-1d2d7429d7df	Atwoods	018ffd1e-b602-4cb9-911f-210585f78a29	\N	green	f	\N	\N	176781997001956	2026-05-23 00:55:25.446984	2026-05-23 00:55:25.446984	Professional	\N	\N	Retail	2028-03-12	\N
680aba27-0f40-4b26-b501-91ea89b10632	Tap Room	018ffd1e-b602-4cb9-911f-210585f78a29	\N	green	f	\N	\N	165230315969500	2026-05-23 00:55:25.45113	2026-05-23 00:55:25.45113	Professional	\N	\N	Restaurants	2027-07-15	\N
185987c8-c261-4cfa-95eb-7e2f3c6dc03b	Stress-Free Auto Care	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	171208679219084	2026-05-23 00:55:25.454941	2026-05-23 00:55:25.454941	Professional	\N	\N	Automotive	2027-05-14	\N
d0c39f73-3ab7-4514-b7b8-0e7de2c1edc0	Ginkgo Residential LLC	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	170024517533632	2026-05-23 00:55:25.458509	2026-05-23 00:55:25.458509	Professional	\N	\N	Real Estate	2027-01-14	\N
821cb857-6e0d-4a4c-99f5-09754eabc570	Montreal Mini-Storage	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	172727358695166	2026-05-23 00:55:25.463234	2026-05-23 00:55:25.463234	Professional	\N	\N	Consumer Services	2027-10-29	\N
f5e1c20f-0340-4009-9567-029262f06f4f	Wyndhurst Medical Aesthetics	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	161108102916054	2026-05-23 00:55:25.467122	2026-05-23 00:55:25.467122	Professional	\N	\N	Wellness	2027-02-21	\N
7a70b802-00ea-44d5-b836-57935bb0262d	HMY Yachts Sales, Inc.	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	red	f	\N	\N	169989054126366	2026-05-23 00:55:25.471741	2026-05-23 00:55:25.471741	Professional	\N	\N	Automotive	2027-01-12	\N
439a9e8f-63ba-46dd-b808-7e0006f1a9c3	SERVPRO Extreme Team Miller	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	169203847942572	2026-05-23 00:55:25.47693	2026-05-23 00:55:25.47693	Professional	\N	\N	Contractors	2026-10-23	\N
7d2f6dda-3b28-478a-a0dd-ec08ae9c26ff	Infinity Dental Partners	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	173721845262490	2026-05-23 00:55:25.481915	2026-05-23 00:55:25.481915	Professional	\N	\N	Dental	2027-01-30	\N
5d1149fa-9b27-4d0a-9ea1-2dd18132d565	The Bartolotta Restaurants	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	green	f	\N	\N	165117406664473	2026-05-23 00:55:25.485583	2026-05-23 00:55:25.485583	Professional	\N	\N	Hospitality	2027-01-27	\N
f29d03f0-5d43-44f0-bec9-895fdbedfbb4	The Gilmore Collection	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	166431343615740	2026-05-23 00:55:25.489905	2026-05-23 00:55:25.489905	Professional	\N	\N	Home Services	2026-10-31	\N
581f91a4-550f-498f-856d-27bad98c6897	Mid-Florida Endodontics	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	red	f	\N	\N	151932934617892	2026-05-23 00:55:25.494093	2026-05-23 00:55:25.494093	Professional	\N	\N	Dental	2027-02-26	\N
31908582-12f2-4d42-b32f-c2f2bedf3ac9	Minute Suites	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	green	f	\N	\N	156580109626133	2026-05-23 00:55:25.497421	2026-05-23 00:55:25.497421	Professional	\N	\N	Hospitality	2028-10-19	\N
1b4591e1-f203-4a2c-94c2-fa4c80d379d0	Law Office of Domingo Garcia	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	170621978066102	2026-05-23 00:55:25.500921	2026-05-23 00:55:25.500921	Professional	\N	\N	Legal	2027-05-06	\N
b605e7d4-3659-4aa5-8ead-ae0678d43a58	Sunrise Treatment Center	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	green	f	\N	\N	166688105917571	2026-05-23 00:55:25.505777	2026-05-23 00:55:25.505777	Professional	\N	\N	Healthcare	2026-08-14	\N
f125787a-a0f5-4d9c-aa89-cc9b6bbb698e	Burrow Welchel & Culp Orthodontics	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	green	f	\N	\N	175381884711308	2026-05-23 00:55:25.510309	2026-05-23 00:55:25.510309	Professional	\N	\N	Dental	2027-08-25	\N
3e08219d-30d7-410e-b102-4ee5874d963f	Chelsea Senior Living	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	170052953871181	2026-05-23 00:55:25.513609	2026-05-23 00:55:25.513609	Professional	\N	\N	Healthcare	2027-12-26	\N
0acfac26-ccc1-491d-877b-9b75d3681192	Ghuman Dental Corp	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	169750160178176	2026-05-23 00:55:25.517609	2026-05-23 00:55:25.517609	Professional	\N	\N	Dental	2026-11-01	\N
9c5fd49d-5653-47e6-891c-046701796961	Brightstar Credit Union	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	153574176892745	2026-05-23 00:55:25.521475	2026-05-23 00:55:25.521475	Professional	\N	\N	Finance	2026-08-31	\N
fd784679-494d-4629-9c07-e31adee6a8c4	Coleman Taylor Transmissions	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	159586585866506	2026-05-23 00:55:25.527619	2026-05-23 00:55:25.527619	Professional	\N	\N	Automotive	2026-06-29	\N
e400b860-f92e-4041-a319-ae1e0ed53898	Northwest Federal Credit Union	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	166360629911852	2026-05-23 00:55:25.531993	2026-05-23 00:55:25.531993	Professional	\N	\N	Finance	2026-11-08	\N
72782b3d-ae7c-4df5-a3c3-9202c0a46209	Fairwinds Credit Union	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	161962038368242	2026-05-23 00:55:25.535987	2026-05-23 00:55:25.535987	Professional	\N	\N	Finance	2027-02-19	\N
5ec1d22e-4355-475a-9e09-c8e5981bea33	Cooper Multifamily Services LLC	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	red	f	\N	\N	167588828021779	2026-05-23 00:55:25.540932	2026-05-23 00:55:25.540932	Professional	\N	\N	Real Estate	2027-02-23	\N
b2d0d4cb-e104-4602-818d-c74ca7715551	WV Eye Consultants	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	green	f	\N	\N	171718313670397	2026-05-23 00:55:25.544681	2026-05-23 00:55:25.544681	Professional	\N	\N	Healthcare	2026-07-12	\N
bda21fc0-169f-41df-bf31-bbb65e3b97ef	Advanced Vision Care	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	168608811030037	2026-05-23 00:55:25.548137	2026-05-23 00:55:25.548137	Professional	\N	\N	Healthcare	2026-06-27	\N
394ecdf1-3405-4f58-9186-4c8a843aefc1	Texas Tiny Teeth	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	175623413280329	2026-05-23 00:55:25.551815	2026-05-23 00:55:25.551815	Professional	\N	\N	Dental	2026-12-07	\N
2b5e23c4-ac2a-4415-b1ea-d0f64b8fe0b9	Interactive College Of Technology	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	160836039527944	2026-05-23 00:55:25.555674	2026-05-23 00:55:25.555674	Professional	\N	\N	Education	2026-10-01	\N
7428d629-0584-4023-ac91-a618e5b4f8af	Kleinman Realty Company	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	172739205954421	2026-05-23 00:55:25.559088	2026-05-23 00:55:25.559088	Professional	\N	\N	Real Estate	2026-06-01	\N
b8f6f666-9e8b-4e62-9a30-4cc95911878f	Monticciolo Family & Sedation Dentistry	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	red	f	\N	\N	163717525693776	2026-05-23 00:55:25.569662	2026-05-23 00:55:25.569662	Professional	\N	\N	Dental	2026-12-10	\N
daf6c9f8-ea26-42ba-9eb7-c41507ef7213	Kingline Equipment	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	green	f	\N	\N	174102445207964	2026-05-23 00:55:25.573666	2026-05-23 00:55:25.573666	Professional	\N	\N	Automotive	2027-03-13	\N
9246f87e-645f-4819-8192-d436f8a9cf2e	Tampa Bay Area Counseling DBA TBAC Group	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	174282996375464	2026-05-23 00:55:25.578528	2026-05-23 00:55:25.578528	Professional	\N	\N	Healthcare	2026-10-15	\N
76cfa43a-894a-4469-992a-5d02ee36834b	Princeton Brain, Spine and Sports Medicine	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	157867415127560	2026-05-23 00:55:25.58224	2026-05-23 00:55:25.58224	Professional	\N	\N	Healthcare	2026-11-30	\N
60670317-24f7-4d5d-a160-e052ae5dcb06	American Steel Carports, Inc.	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	green	f	\N	\N	167458702913941	2026-05-23 00:55:25.585741	2026-05-23 00:55:25.585741	Professional	\N	\N	Contractors	2027-01-27	\N
9018c162-5465-473e-b122-761b3a26cf50	Meltzer & Bell, P.A.	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	158136843770744	2026-05-23 00:55:25.589655	2026-05-23 00:55:25.589655	Professional	\N	\N	Legal	2027-02-19	\N
fb4a6549-ae67-43a7-9e4a-d1a5e2b835e9	Rios Golden Cut	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	172184584392769	2026-05-23 00:55:25.593351	2026-05-23 00:55:25.593351	Professional	\N	\N	Beauty	2026-08-13	\N
1f267131-8d1c-40ed-8e8b-8ab7a5d099c7	Kenmore Development	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	157168092622357	2026-05-23 00:55:25.596594	2026-05-23 00:55:25.596594	Professional	\N	\N	Real Estate	2027-10-28	\N
281f71b7-69b5-4a2c-b7c1-7b8fd537c099	Behavior Frontiers	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	red	f	\N	\N	162066727930043	2026-05-23 00:55:25.599664	2026-05-23 00:55:25.599664	Professional	\N	\N	Education	2027-01-30	\N
761a9792-42e8-45fb-880a-46925e9826ff	People First Urgent & Primary Care	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	159318576925691	2026-05-23 00:55:25.603409	2026-05-23 00:55:25.603409	Professional	\N	\N	Healthcare	2027-06-18	\N
3040b656-b711-4cc7-ad34-4708fde3d1cb	Cedar Point Health	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	166266997568324	2026-05-23 00:55:25.607035	2026-05-23 00:55:25.607035	Professional	\N	\N	Healthcare	2026-08-03	\N
22613d54-96de-4aa5-a96e-4533ea715f5f	Joint Relief Institute	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	green	f	\N	\N	172772932593244	2026-05-23 00:55:25.610995	2026-05-23 00:55:25.610995	Professional	\N	\N	Healthcare	2026-10-16	\N
5837c7d6-e442-4163-84ad-088b8948c9ba	Musicworks Canada	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	170559587784642	2026-05-23 00:55:25.614189	2026-05-23 00:55:25.614189	Professional	\N	\N	Education	2027-05-09	\N
9bfd89e8-61bf-46e2-9664-7203c1b73168	Methodist Retirement Communities	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	158092819371038	2026-05-23 00:55:25.617543	2026-05-23 00:55:25.617543	Professional	\N	\N	Wellness	2028-02-18	\N
5bb5d9a5-b5b0-4927-9d86-fa20052b6c77	Vital Imaging Center- Miami Center	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	172071146054814	2026-05-23 00:55:25.621342	2026-05-23 00:55:25.621342	Professional	\N	\N	Healthcare	2026-07-26	\N
3184e78a-58f4-4246-886b-a6102fd9cd4b	MEI, INC/AUTOMAX	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	156684792565767	2026-05-23 00:55:25.626336	2026-05-23 00:55:25.626336	Professional	\N	\N	Automotive	2026-07-28	\N
0e135d81-5384-410f-a21a-143bf7d6aa3f	Tahini Authentic Middle Eastern Street Food	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	175622730679719	2026-05-23 00:55:25.629944	2026-05-23 00:55:25.629944	Professional	\N	\N	Restaurants	2026-09-05	\N
8a7672f8-651b-4f71-bcc3-f25d46efaf2d	Aoa Property Management of Southern California	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	166033753672045	2026-05-23 00:55:25.634121	2026-05-23 00:55:25.634121	Professional	\N	\N	Real Estate	2027-03-10	\N
a5503f6f-c249-4423-a68a-ddeba6cdd824	The May Firm	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	red	f	\N	\N	150481412667479	2026-05-23 00:55:25.637552	2026-05-23 00:55:25.637552	Professional	\N	\N	Legal	2026-09-07	\N
180b2350-6a08-4643-a870-115a4c1f6d67	SAFE Federal Credit Union	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	green	f	\N	\N	173046478076206	2026-05-23 00:55:25.640771	2026-05-23 00:55:25.640771	Professional	\N	\N	Finance	2027-12-31	\N
b24409bd-c1a5-4e27-8ade-d1883fc1911b	Empire Management, Inc.	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	166214365506711	2026-05-23 00:55:25.64408	2026-05-23 00:55:25.64408	Professional	\N	\N	Real Estate	2027-02-12	\N
a437c3ed-6849-44ae-abe4-9f251346122f	Recker and Boerger	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	168444385787499	2026-05-23 00:55:25.647326	2026-05-23 00:55:25.647326	Professional	\N	\N	Contractors	2026-05-30	\N
d688cd50-7659-441e-895b-06fe52eb1eb0	Trillium Clinic	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	green	f	\N	\N	169599656745962	2026-05-23 00:55:25.650952	2026-05-23 00:55:25.650952	Professional	\N	\N	Healthcare	2026-12-01	\N
bc44c834-1c62-49fa-822c-547fbfea8b2a	Driftwood Hospitality Management	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	166973733804355	2026-05-23 00:55:25.654595	2026-05-23 00:55:25.654595	Professional	\N	\N	Hospitality	2026-07-26	\N
68b625f0-9b6d-4da5-9d83-2355962b2d5e	MRI Centers of Texas	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	162191233899676	2026-05-23 00:55:25.6584	2026-05-23 00:55:25.6584	Professional	\N	\N	Healthcare	2027-01-07	\N
5dba1f90-9f4e-4644-82fb-59157ebd0713	H2 Dermatology	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	171172299969453	2026-05-23 00:55:25.662765	2026-05-23 00:55:25.662765	Professional	\N	\N	Healthcare	2027-04-16	\N
02ec884a-d7c1-4d96-affb-e39bf8a489e6	White Aluminum & Windows	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	169643675249046	2026-05-23 00:55:25.666612	2026-05-23 00:55:25.666612	Professional	\N	\N	Contractors	2027-02-14	\N
46630e80-c926-4729-be4f-293d9911eb67	Ali Beauty Supply	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	green	f	\N	\N	173151493914584	2026-05-23 00:55:25.670481	2026-05-23 00:55:25.670481	Professional	\N	\N	Beauty	2026-11-21	\N
e7ab688f-74c3-4389-beda-2de8a19bbc8e	Vision Dental	40dba9be-69cc-4ec1-9c8e-1c2433d520c1	\N	yellow	f	\N	\N	170991785722605	2026-05-23 00:55:25.673996	2026-05-23 00:55:25.673996	Professional	\N	\N	Dental	2027-03-08	\N
43d0ed21-28e2-4ada-a15e-5f2a214e2b1f	Taymil Partners	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	166749782588102	2026-05-23 00:55:25.67782	2026-05-23 00:55:25.67782	Professional	\N	\N	Real Estate	2028-02-27	\N
788e4277-3324-4ffd-ab76-f439b863579a	SUMMIT Medical Partners	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	166560674843717	2026-05-23 00:55:25.681611	2026-05-23 00:55:25.681611	Professional	\N	\N	Healthcare	2028-10-13	\N
6e817e29-4046-4c02-9975-adfd634aca74	Blue Sky RV Living	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	166275408432807	2026-05-23 00:55:25.687622	2026-05-23 00:55:25.687622	Professional	\N	\N	Recreation	2026-09-26	\N
0d31d955-72e7-40c2-bf29-5488d70bb3c3	Maryland Speedy Tag & Title	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	164934534306436	2026-05-23 00:55:25.691292	2026-05-23 00:55:25.691292	Professional	\N	\N	Finance	2029-03-29	\N
e08b3754-566f-40e3-9881-0f308c11eb45	Vondran Legal - Copyright Law Firm	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	166793324675006	2026-05-23 00:55:25.694547	2026-05-23 00:55:25.694547	Professional	\N	\N	Legal	2027-01-30	\N
6e653ee9-84d2-4963-ad25-bb1e60bd8484	Arbraska	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	167354727692961	2026-05-23 00:55:25.699053	2026-05-23 00:55:25.699053	Professional	\N	\N	Recreation	2026-10-23	\N
0978dc24-b4a6-4c84-b2be-bf54f0355b4b	PT Link Physical Therapy	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	162342397098623	2026-05-23 00:55:25.70286	2026-05-23 00:55:25.70286	Professional	\N	\N	Healthcare	2026-05-30	\N
a5307466-2447-4111-b0d8-7b2da6c9c5be	Listerhill Credit Union	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	169930631122189	2026-05-23 00:55:25.706286	2026-05-23 00:55:25.706286	Professional	\N	\N	Finance	2029-01-29	\N
77353dd7-2ebb-4ecf-bc59-b2cfb91f9516	Curis Functional Health	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	170483346260662	2026-05-23 00:55:25.709911	2026-05-23 00:55:25.709911	Professional	\N	\N	Healthcare	2026-11-29	\N
df4873d0-6e1b-4d2e-83bf-48e5fe0ad90a	Revelation Pharma	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	169141933704958	2026-05-23 00:55:25.713446	2026-05-23 00:55:25.713446	Professional	\N	\N	Healthcare	2026-12-28	\N
a40d61eb-ac04-4771-bf05-561fffe858ea	MDI Management PO	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	175155411287911	2026-05-23 00:55:25.717317	2026-05-23 00:55:25.717317	Professional	\N	\N	Real Estate	2027-08-10	\N
c4bd28f1-f08d-46e6-b4a9-08b889808a10	The College of Health Care Professions	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	149814509009402	2026-05-23 00:55:25.721581	2026-05-23 00:55:25.721581	Professional	\N	\N	Education	2026-06-29	\N
951b6123-f7cc-403f-b415-2d1fa8aa12ea	Saatva Mattress	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	171581040610413	2026-05-23 00:55:25.727777	2026-05-23 00:55:25.727777	Professional	\N	\N	Consumer Goods	2028-04-23	\N
b130d230-9995-4018-8301-0de43540d909	Vrdolyak Law	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	161659949228887	2026-05-23 00:55:25.735032	2026-05-23 00:55:25.735032	Professional	\N	\N	Legal	2028-03-26	\N
6d73ec4e-f0e9-4bc2-9c78-768e0ad706ca	Big Boy	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	174293486290149	2026-05-23 00:55:25.738986	2026-05-23 00:55:25.738986	Professional	\N	\N	Restaurants	2026-05-29	\N
c3ddb7bd-fad7-4b86-a196-94ee3db64403	Global Self Storage	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	169885297690458	2026-05-23 00:55:25.742671	2026-05-23 00:55:25.742671	Professional	\N	\N	Consumer Services	2026-12-18	\N
f4e768cc-f5a2-4111-9dc2-231a2c705b37	TRI-SUPPLY	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	151940603689088	2026-05-23 00:55:25.74633	2026-05-23 00:55:25.74633	Professional	\N	\N	Retail	2029-04-27	\N
aabc55ba-b2c3-4425-8a64-d741d6471584	Pure Skin MedSpa of Trumbull	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	165332994063974	2026-05-23 00:55:25.752962	2026-05-23 00:55:25.752962	Professional	\N	\N	Wellness	2026-05-26	\N
f30b0755-3b3b-4ff5-920b-4655298ca05a	Kind Health Group	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	165160128825542	2026-05-23 00:55:25.757235	2026-05-23 00:55:25.757235	Professional	\N	\N	Healthcare	2028-05-04	\N
2ab9c2b8-1ecf-4632-bb37-f1a046957115	Iowa Oral & Maxillofacial Surgeons, P.C.	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	165454985195471	2026-05-23 00:55:25.760925	2026-05-23 00:55:25.760925	Professional	\N	\N	Dental	2026-06-17	\N
2f9f8790-d579-436e-873c-4154886d822e	Cynergy Property Management, LLC	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	172600611686043	2026-05-23 00:55:25.764691	2026-05-23 00:55:25.764691	Professional	\N	\N	Real Estate	2027-10-11	\N
b6d52f01-7613-4a91-872f-e4701cb09ad0	Bowser Automotive	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	172545195779840	2026-05-23 00:55:25.768633	2026-05-23 00:55:25.768633	Professional	\N	\N	Automotive	2026-10-31	\N
7d21bf41-e40e-44e5-8b1a-ba2ab113333c	Ohio Foot & Ankle Specialists	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	162947587181428	2026-05-23 00:55:25.772463	2026-05-23 00:55:25.772463	Professional	\N	\N	Healthcare	2026-06-02	\N
244c0ba2-2dbe-4935-9a42-2fe4461aa195	First Capital REIT	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	172365013546292	2026-05-23 00:55:25.776199	2026-05-23 00:55:25.776199	Professional	\N	\N	Contractors	2027-10-24	\N
b77710c8-08c4-4e74-88ea-88b7963eb761	Buildingstars Operations, Inc	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	175709948487746	2026-05-23 00:55:25.780193	2026-05-23 00:55:25.780193	Professional	\N	\N	Business Services	2026-10-31	\N
74f1dea0-396f-4088-bf29-9915d81008b0	Catalogue	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	171350008664005	2026-05-23 00:55:25.783847	2026-05-23 00:55:25.783847	Professional	\N	\N	Hospitality	2026-06-29	\N
21ba865c-512e-45a0-81d9-8a61ec3b7806	The Hill Medical Corporation	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	165669250435496	2026-05-23 00:55:25.787233	2026-05-23 00:55:25.787233	Professional	\N	\N	Healthcare	2027-10-01	\N
ba79fde3-9786-4b29-8f1f-0d3c2d2b2ffb	Senior TLC	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	170541920733652	2026-05-23 00:55:25.790468	2026-05-23 00:55:25.790468	Professional	\N	\N	Healthcare	2026-10-23	\N
4db1cbcf-7699-486f-9bbe-76396c21908e	Manhattan Specialty Care	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	red	f	\N	\N	152114755315227	2026-05-23 00:55:25.793839	2026-05-23 00:55:25.793839	Professional	\N	\N	Healthcare	2026-07-24	\N
e0a8d641-d663-4f0c-bba1-9efe6be95d01	Somerpointe Resorts	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	166318895233180	2026-05-23 00:55:25.796959	2026-05-23 00:55:25.796959	Professional	\N	\N	Hospitality	2027-01-02	\N
021812a4-b241-42c9-af6e-241d043a1097	Astra Vein Treatment Center	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	175700582274152	2026-05-23 00:55:25.800263	2026-05-23 00:55:25.800263	Professional	\N	\N	Healthcare	2026-09-09	\N
86f99902-e712-46bd-bf19-c547a9d3f559	LoanCare, LLC	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	157194580172420	2026-05-23 00:55:25.803408	2026-05-23 00:55:25.803408	Professional	\N	\N	Finance	2026-12-31	\N
ad025d4c-2945-4edf-8066-35fb379376bd	Lilly Pullitzer	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	158325749394272	2026-05-23 00:55:25.806969	2026-05-23 00:55:25.806969	Professional	\N	\N	Retail	2026-12-30	\N
af535696-f903-435a-956f-7a9a997498d1	Center For Sight	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	162826987818485	2026-05-23 00:55:25.810436	2026-05-23 00:55:25.810436	Professional	\N	\N	Healthcare	2026-08-31	\N
6853a5c9-99c9-4024-9056-8317777abd6e	NOVA Perio Specialists-Periodontics and Dental Imp	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	147370735949390	2026-05-23 00:55:25.814202	2026-05-23 00:55:25.814202	Professional	\N	\N	Dental	2026-09-12	\N
390f0d6d-e65f-45a0-be0b-10a612cbc6e5	Weinberger Divorce & Family Law Group	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	152397404461184	2026-05-23 00:55:25.818213	2026-05-23 00:55:25.818213	Professional	\N	\N	Legal	2028-06-09	\N
6049ec99-8d44-4d01-8285-9fdf269af424	Anthony & Sylvan Pools	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	red	f	\N	\N	149339703919981	2026-05-23 00:55:25.823111	2026-05-23 00:55:25.823111	Professional	\N	\N	Home Services	2027-04-28	\N
5b842a0f-d52e-46e7-a080-9941c61e5185	Resolute Dental Partners & Shoreline Periodontics	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	149556935318006	2026-05-23 00:55:25.826815	2026-05-23 00:55:25.826815	Professional	\N	\N	Dental	2027-03-08	\N
a5b59fe8-b8f6-43f8-ade3-4b4381681cb4	Renovo Endodontic Studio	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	167243616009766	2026-05-23 00:55:25.830578	2026-05-23 00:55:25.830578	Professional	\N	\N	Dental	2026-05-31	\N
c9ac45b0-0227-4d96-a5f2-942f5b9cf6df	Pacific Cataract and Laser Institute	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	170483373065871	2026-05-23 00:55:25.834843	2026-05-23 00:55:25.834843	Professional	\N	\N	Healthcare	2027-02-18	\N
c6e5f5e1-6fea-4e13-81f8-a649333ea601	People's Trust Insurance	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	149497056017918	2026-05-23 00:55:25.838488	2026-05-23 00:55:25.838488	Professional	\N	\N	Insurance	2027-05-19	\N
584032dd-9814-4398-8547-8de1b044c436	Countryside Property Management	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	167511942204409	2026-05-23 00:55:25.842118	2026-05-23 00:55:25.842118	Professional	\N	\N	Real Estate	2028-03-01	\N
dbf8f102-989b-437c-a83d-b111b9faa83a	AMJ	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	166871539908566	2026-05-23 00:55:25.845603	2026-05-23 00:55:25.845603	Professional	\N	\N	Transportation Services	2029-03-30	\N
5a336487-1cf6-4acd-a9a8-0f201886aaed	Stratus	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	157192453917802	2026-05-23 00:55:25.85108	2026-05-23 00:55:25.85108	Professional	\N	\N	Healthcare	2026-12-23	\N
4c6166e0-ac78-4466-bcd4-aea11171bf11	Long Lake Insurance	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	175554751623577	2026-05-23 00:55:25.854967	2026-05-23 00:55:25.854967	Professional	\N	\N	Insurance	2026-11-27	\N
628ec1f0-3ec9-446d-a12f-e4fc6dd51452	Sun State International Trucks, LLC	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	164737081246127	2026-05-23 00:55:25.859132	2026-05-23 00:55:25.859132	Professional	\N	\N	Automotive	2027-03-16	\N
9400af93-e51b-446e-808d-56664c17951e	Utility Trailer Sales Southeast Texas, Inc	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	157055392801989	2026-05-23 00:55:25.863778	2026-05-23 00:55:25.863778	Professional	\N	\N	Automotive	2027-02-04	\N
9b838832-fac2-4623-bebd-64391bd7907c	Texas Truckworks	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	171526868978417	2026-05-23 00:55:25.867653	2026-05-23 00:55:25.867653	Professional	\N	\N	Automotive	2027-05-09	\N
a8c1eb4b-bf5b-4202-b250-cc2bd624d0e6	ABC Humane Wildlife Control and Prevention Inc.	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	169229867572977	2026-05-23 00:55:25.871508	2026-05-23 00:55:25.871508	Professional	\N	\N	Wellness	2026-08-29	\N
8902c526-991a-4b70-a89f-5a17e29ecf14	Innovative Implant and Oral Surgery	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	157530863641329	2026-05-23 00:55:25.875287	2026-05-23 00:55:25.875287	Professional	\N	\N	Dental	2026-08-10	\N
d4ec765a-795b-4c63-ad07-251ccd44e932	Tax Workout Group	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	171052108648385	2026-05-23 00:55:25.879074	2026-05-23 00:55:25.879074	Professional	\N	\N	Finance	2027-04-30	\N
6c6ebb7e-8ba3-48b2-8b15-de1e2a1278c7	Mom's Meals	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	158436495512666	2026-05-23 00:55:25.882689	2026-05-23 00:55:25.882689	Professional	\N	\N	Restaurants	2026-10-30	\N
a280da02-32ce-4c41-b5c5-744ac68b81a1	A-1 Appliance	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	green	f	\N	\N	171587626171739	2026-05-23 00:55:25.88631	2026-05-23 00:55:25.88631	Professional	\N	\N	Retail	2027-05-19	\N
c5b40617-4e52-4970-9187-af12374155b2	Wauwatosa Dental Arts	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	165072396561901	2026-05-23 00:55:25.889679	2026-05-23 00:55:25.889679	Professional	\N	\N	Dental	2026-08-11	\N
83602f10-022e-4924-83e8-5291b57e7a23	Shine Bright Cleaning Services	d8a702e3-ce10-4e4e-8c5b-52611e941c21	\N	yellow	f	\N	\N	155326705984844	2026-05-23 00:55:25.893439	2026-05-23 00:55:25.893439	Professional	\N	\N	Home Services	2027-01-21	\N
2b0abba8-bd03-47c1-aacc-00633042df59	Cunningham Restaurant Group	0e846a2d-095d-45ca-a7a1-e0c21edc78e1	\N	yellow	f	\N	\N	155447271972137	2026-05-23 00:55:25.896819	2026-05-23 00:55:25.896819	Professional	\N	\N	Restaurants	2026-07-01	\N
54ae6aa5-c64b-48d2-84f3-b7d1eee1204a	Oxford Auto Insurance	3ed58702-5fcb-4742-a9f2-842a09991732	\N	green	f	\N	\N	174282553009248	2026-05-23 00:55:25.900161	2026-05-23 00:55:25.900161	Professional	\N	\N	Insurance	2027-04-14	\N
a5977772-f107-4fb3-a3b7-ed2ee69210fc	Paychex	3ed58702-5fcb-4742-a9f2-842a09991732	\N	yellow	f	\N	\N	169299212470640	2026-05-23 00:55:25.904042	2026-05-23 00:55:25.904042	Professional	\N	\N	Insurance	2026-05-28	\N
3a0b6dd6-d63d-44f2-b375-45434ac17a38	Mister Car Wash	bbff08b2-dd93-4559-b5b8-4ac3855b6b56	\N	yellow	f	\N	\N	174120284101550	2026-05-23 00:55:25.907727	2026-05-23 00:55:25.907727	Professional	\N	\N	Automotive	2027-04-28	\N
ace74a49-baec-405b-a395-142fdd2c64ec	Notre Dame Federal Credit Union	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	172424927136353	2026-05-23 00:55:25.911265	2026-05-23 00:55:25.911265	Professional	\N	\N	Finance	2026-12-15	\N
c825e2b7-d6bd-4730-856c-3c24b570c6a1	Meadows Behavioral Healthcare	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	171149295283267	2026-05-23 00:55:25.914763	2026-05-23 00:55:25.914763	Professional	\N	\N	Healthcare	2026-06-30	\N
e8c83e0c-e739-4eda-8883-06e9534c8c76	Bogin, Munns & Munns, P.A.	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	162106255104346	2026-05-23 00:55:25.918392	2026-05-23 00:55:25.918392	Professional	\N	\N	Legal	2027-04-10	\N
b647a9df-0f93-4d08-bbb2-025602cfd0aa	Battery Source	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	161996814352092	2026-05-23 00:55:25.921796	2026-05-23 00:55:25.921796	Professional	\N	\N	Consumer Services	2027-09-20	\N
9daebaea-bc8f-4f34-b017-26aae85d2724	Timber Dental	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	152641045324676	2026-05-23 00:55:25.925187	2026-05-23 00:55:25.925187	Professional	\N	\N	Dental	2026-10-03	\N
6108b754-0a43-41d0-9acb-1ad3184f5675	E Mortgage Capital	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	red	f	\N	\N	158801434723778	2026-05-23 00:55:25.928457	2026-05-23 00:55:25.928457	Professional	\N	\N	Finance	2026-10-11	\N
bba107cc-c787-4e98-ad98-6aab760e5008	Läderach	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	174612632546871	2026-05-23 00:55:25.932548	2026-05-23 00:55:25.932548	Professional	\N	\N	Restaurants	2026-09-30	\N
12d67cd7-30bf-4575-92d9-d71994f14be3	Walker Zanger	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	162680563021796	2026-05-23 00:55:25.936161	2026-05-23 00:55:25.936161	Professional	\N	\N	Construction	2026-05-31	\N
abd1226a-362b-41d5-84c4-9baf87a382e3	Bella Bridesmaids	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	172444881629296	2026-05-23 00:55:25.940096	2026-05-23 00:55:25.940096	Professional	\N	\N	Retail	2026-10-22	\N
ced7b219-0ea0-4fe9-b67f-91688cdd2b01	Value Store It Self Storage	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	167813857237456	2026-05-23 00:55:25.943612	2026-05-23 00:55:25.943612	Professional	\N	\N	Consumer Services	2026-11-21	\N
4bd469bb-9a60-4a25-807a-7b08181504a5	Family Foot and Ankle Associates of Maryland	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	164928740502314	2026-05-23 00:55:25.948055	2026-05-23 00:55:25.948055	Professional	\N	\N	Healthcare	2027-04-30	\N
9a5e68e7-f7a7-457c-8b2a-05bb27d3e37c	Encompass Medical Group, P.A.	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	162196473535235	2026-05-23 00:55:25.951819	2026-05-23 00:55:25.951819	Professional	\N	\N	Healthcare	2026-06-06	\N
6bd91ab6-4f1f-4e45-a17e-e6438661e073	VNA Health Care	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	171745454777648	2026-05-23 00:55:25.955248	2026-05-23 00:55:25.955248	Professional	\N	\N	Healthcare	2026-06-28	\N
06aafd0d-4fe0-496b-9d99-ea6ba44ddc26	Porch Light Health	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	170483344355032	2026-05-23 00:55:25.959059	2026-05-23 00:55:25.959059	Professional	\N	\N	Healthcare	2028-05-13	\N
2d0314aa-877f-4ac0-a01a-b14143504e20	Omni Family of Services	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	162066006482316	2026-05-23 00:55:25.962849	2026-05-23 00:55:25.962849	Professional	\N	\N	Healthcare	2026-08-28	\N
3a4ddf1d-fc16-477b-86da-5d049afb9390	Clegg's Termite & Pest Control LLC	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	171658379051688	2026-05-23 00:55:25.966436	2026-05-23 00:55:25.966436	Professional	\N	\N	Home Services	2028-11-28	\N
6e63d3fb-c804-4b30-adfd-1e38dd943303	Pain Specialists of America	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	165826058581040	2026-05-23 00:55:25.970189	2026-05-23 00:55:25.970189	Professional	\N	\N	Healthcare	2026-08-30	\N
d44bc6be-12fa-4669-9685-4e254d8cf50b	Van Metre Companies, Inc.	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	170585759848602	2026-05-23 00:55:25.973947	2026-05-23 00:55:25.973947	Professional	\N	\N	Real Estate	2026-09-30	\N
097039bf-a8d8-49f9-abcc-8ee0483d0d76	Tree Pros, LLC	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	158638180852303	2026-05-23 00:55:25.977682	2026-05-23 00:55:25.977682	Professional	\N	\N	Home Services	2026-06-09	\N
f46fbfd9-c4af-4356-a118-103f039fe378	SquareTrade	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	149333369625525	2026-05-23 00:55:25.981498	2026-05-23 00:55:25.981498	Professional	\N	\N	Insurance	2026-11-24	\N
ecaa17c5-2f51-47ef-9bd4-c48387ccf8e8	Apricot Lane Boutique	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	168727721879130	2026-05-23 00:55:25.985509	2026-05-23 00:55:25.985509	Professional	\N	\N	Retail	2026-08-01	\N
6dae9a9c-40de-49ef-aa19-85bed60136cd	Royal Prestige	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	166853903640391	2026-05-23 00:55:25.98942	2026-05-23 00:55:25.98942	Professional	\N	\N	Other	2026-06-15	\N
cd7b5be0-667f-44cd-bc87-63b1d65d5b75	SUNation Solar Systems	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	161952683298294	2026-05-23 00:55:25.993178	2026-05-23 00:55:25.993178	Professional	\N	\N	Home Services	2027-01-27	\N
9354cf0c-3d65-4781-a9ae-057108ad5d01	Pony Express Car Wash	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	158880239277352	2026-05-23 00:55:25.99677	2026-05-23 00:55:25.99677	Professional	\N	\N	Automotive	2027-02-27	\N
f4eb67f4-3b40-4421-b987-08ad0ee56e4a	Florida Spine Associates	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	164315140884491	2026-05-23 00:55:26.000217	2026-05-23 00:55:26.000217	Professional	\N	\N	Healthcare	2026-12-17	\N
825f99fb-645a-46f3-a067-134033c302b5	Erik's Bike Shop	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	161124557726372	2026-05-23 00:55:26.003972	2026-05-23 00:55:26.003972	Professional	\N	\N	Retail	2027-01-30	\N
82dca05c-8bdf-44b2-96b5-53132d8f576e	TexasLending.com	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	149969896111739	2026-05-23 00:55:26.007379	2026-05-23 00:55:26.007379	Professional	\N	\N	Finance	2026-07-27	\N
a2e4398b-079e-40c0-b848-04a667272530	Andy Mohr Automotive	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	165177986030088	2026-05-23 00:55:26.010956	2026-05-23 00:55:26.010956	Professional	\N	\N	Automotive	2026-06-30	\N
60b20b3c-0f3d-4a5a-b57b-26b764ea9e5c	Medical Eye Center	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	161843621577286	2026-05-23 00:55:26.014309	2026-05-23 00:55:26.014309	Professional	\N	\N	Healthcare	2027-04-21	\N
8c89b0b2-f6f9-4273-8145-730ea2617003	Abilene Teachers Federal Credit Union	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	160824296036105	2026-05-23 00:55:26.017927	2026-05-23 00:55:26.017927	Professional	\N	\N	Finance	2026-12-30	\N
5cefa626-726d-4a8f-8933-87c857dff738	Gordon McKernan Injury Attorneys	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	151619114593175	2026-05-23 00:55:26.021962	2026-05-23 00:55:26.021962	Professional	\N	\N	Legal	2028-01-30	\N
22301fd0-e7b6-4c84-8c8d-06b0f1e774a9	Maxem Health Urgent Care	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	156036892953953	2026-05-23 00:55:26.025747	2026-05-23 00:55:26.025747	Professional	\N	\N	Healthcare	2027-05-21	\N
838ce2a1-d323-4213-8892-5d9a2a0c95d7	Strategic Management Solutions Apartment Management	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	171761776108672	2026-05-23 00:55:26.029219	2026-05-23 00:55:26.029219	Professional	\N	\N	Real Estate	2027-06-27	\N
25aeb1af-5ae5-46a8-894f-73760517c7ce	Curtis Legal Group	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	162558246696673	2026-05-23 00:55:26.035088	2026-05-23 00:55:26.035088	Professional	\N	\N	Legal	2026-07-26	\N
ad038d81-cab6-4db9-962a-3f0b24300e3c	Pella Windows and Doors- Georgia	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	157419882586003	2026-05-23 00:55:26.039031	2026-05-23 00:55:26.039031	Professional	\N	\N	Home Services	2026-09-07	\N
7a913772-0e61-4c8e-9141-8bdc1c828649	Pavilion Properties	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	171510336022428	2026-05-23 00:55:26.042977	2026-05-23 00:55:26.042977	Professional	\N	\N	Real Estate	2026-08-13	\N
cb26cbe2-3c8e-4b9a-a3e1-066babff6428	Titan Factory Direct	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	147031784306450	2026-05-23 00:55:26.04705	2026-05-23 00:55:26.04705	Professional	\N	\N	Real Estate	2027-02-11	\N
f736004d-df58-4a27-a1e7-9b4e01b7e1ad	Zoom Tan	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	169325214414223	2026-05-23 00:55:26.052445	2026-05-23 00:55:26.052445	Professional	\N	\N	Beauty	2027-02-24	\N
dc8e4c0d-6017-4889-aa09-3b2a6f5c495c	LPI Loans	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	164426914152651	2026-05-23 00:55:26.057643	2026-05-23 00:55:26.057643	Professional	\N	\N	Finance	2029-03-10	\N
33c481bc-79b6-4716-b9ac-8055b6730608	Maggie McFly's	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	174888255049014	2026-05-23 00:55:26.062844	2026-05-23 00:55:26.062844	Professional	\N	\N	Restaurants	2026-06-12	\N
0113c584-d324-4cbf-95bb-f07ec8842062	Protea Real Estate	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	167951893375237	2026-05-23 00:55:26.066584	2026-05-23 00:55:26.066584	Professional	\N	\N	Real Estate	2027-04-30	\N
f91c18f4-95c0-4595-991c-ef2de97d1964	Long Home Products	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	171339025447843	2026-05-23 00:55:26.070441	2026-05-23 00:55:26.070441	Professional	\N	\N	Contractors	2027-03-30	\N
0e597630-86f0-4681-8d9e-7904ee53a59d	Mecca Residential	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	169747794296521	2026-05-23 00:55:26.074308	2026-05-23 00:55:26.074308	Professional	\N	\N	Contractors	2026-10-30	\N
bfd0c43b-376c-417c-bada-1c9b711b6a5f	Senior Nannies Homecare Services	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	174492312665809	2026-05-23 00:55:26.078184	2026-05-23 00:55:26.078184	Professional	\N	\N	Healthcare	2026-06-26	\N
7bcde3e3-4ac6-4508-9fae-2c89a919ac4f	Victory Home Remodeling	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	173826198123385	2026-05-23 00:55:26.082254	2026-05-23 00:55:26.082254	Professional	\N	\N	Contractors	2027-05-01	\N
e5cbbdb5-f75f-4afb-b353-87c6b8820527	FlatRate Moving	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	yellow	f	\N	\N	155191343058077	2026-05-23 00:55:26.085865	2026-05-23 00:55:26.085865	Professional	\N	\N	Consumer Services	2027-03-07	\N
f99b7340-1507-408c-8ccb-6638f17abbf4	Parrish Tire	5bc36182-653f-4252-b939-f24a8b9e50f3	\N	green	f	\N	\N	169038978751032	2026-05-23 00:55:26.089538	2026-05-23 00:55:26.089538	Professional	\N	\N	Consumer Services	2026-08-02	\N
7285474a-0b06-48a7-9e9d-68d66e6a4ffa	Harmony Early Education	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	172741557220740	2026-05-23 00:55:26.093193	2026-05-23 00:55:26.093193	Professional	\N	\N	Education	2026-06-17	\N
db7fcdb7-e7d8-4e70-8883-d89d7cec7f18	Habit Health	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	172955351890911	2026-05-23 00:55:26.096567	2026-05-23 00:55:26.096567	Professional	\N	\N	Wellness	2026-08-07	\N
d4a73829-354f-44ac-bec3-830ba8db9495	Bargain Car Rentals Australia	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	169991954714291	2026-05-23 00:55:26.100504	2026-05-23 00:55:26.100504	Professional	\N	\N	Transportation Services	2027-07-02	\N
c506fc04-f2ac-470a-a871-8be3dc72796d	Action Smart Group	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	172300830078246	2026-05-23 00:55:26.104115	2026-05-23 00:55:26.104115	Professional	\N	\N	Automotive	2026-07-31	\N
4dbfd2d9-0205-496b-a0c5-4e9a7cb9b725	Spa World	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	169337723299005	2026-05-23 00:55:26.107525	2026-05-23 00:55:26.107525	Professional	\N	\N	Retail	2026-09-30	\N
ab31ebb8-d7a2-4c60-a1f0-7824f9a70c3a	Pillow Talk	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	173760112216458	2026-05-23 00:55:26.111745	2026-05-23 00:55:26.111745	Professional	\N	\N	Retail	2027-02-16	\N
75151359-0f87-40d1-b11a-5788a7dffde9	Smile On Clinics	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	173914286968579	2026-05-23 00:55:26.117986	2026-05-23 00:55:26.117986	Professional	\N	\N	Dental	2027-03-26	\N
e3efed62-aa8e-4f94-a1b7-7a6690c360e5	Inspire Allied Health and Education Group	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	169680708150300	2026-05-23 00:55:26.122778	2026-05-23 00:55:26.122778	Professional	\N	\N	Home Services	2026-10-20	\N
015aac64-25bc-4a9d-9dcd-4402bebf8c3c	Aim Dental Group	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	169681477514374	2026-05-23 00:55:26.126559	2026-05-23 00:55:26.126559	Professional	\N	\N	Dental	2026-08-13	\N
171944ad-12e3-4b60-9958-ab6cf1c0916b	Smile Sensations	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	170952691487589	2026-05-23 00:55:26.13009	2026-05-23 00:55:26.13009	Professional	\N	\N	Dental	2027-03-20	\N
87866c2b-b99a-435e-a919-5afe38c1026f	Franck Provost Paris Hair Salons	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	169535916663395	2026-05-23 00:55:26.134019	2026-05-23 00:55:26.134019	Professional	\N	\N	Beauty	2026-09-29	\N
7b8bd9da-5296-4356-a18d-55ea4b27fba5	AVH Vet Corp	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	168738369003864	2026-05-23 00:55:26.137785	2026-05-23 00:55:26.137785	Professional	\N	\N	Other	2026-06-20	\N
3a0aa4db-dba5-4a02-a455-ad360009508d	Eden Academy	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	174467492265705	2026-05-23 00:55:26.142804	2026-05-23 00:55:26.142804	Professional	\N	\N	Education	2026-05-19	\N
dfc97ab7-0871-401a-a92f-d2e19042418b	Aidacare	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	green	f	\N	\N	174485632208470	2026-05-23 00:55:26.146679	2026-05-23 00:55:26.146679	Professional	\N	\N	Healthcare	2027-01-15	\N
4866645a-40e5-4f15-af53-6b027e15924c	Super Easy Storage	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	175332632332861	2026-05-23 00:55:26.150396	2026-05-23 00:55:26.150396	Professional	\N	\N	Consumer Services	2026-11-18	\N
543e2d9a-3afd-4ba3-b7a8-8cc102672b6d	Ozzy Tyres	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	red	f	\N	\N	173949895731120	2026-05-23 00:55:26.153784	2026-05-23 00:55:26.153784	Professional	\N	\N	Automotive	2027-03-19	\N
0f0ee3fa-6b4c-4ff1-9f14-ed0a9bdeebca	O'Hara Group	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	171884999701848	2026-05-23 00:55:26.157189	2026-05-23 00:55:26.157189	Professional	\N	\N	Hospitality	2026-07-29	\N
52990b7d-69ba-41bf-87d3-2362a90fc402	SunDoctors Skin Cancer Clinics	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	173879190711928	2026-05-23 00:55:26.16072	2026-05-23 00:55:26.16072	Professional	\N	\N	Wellness	2026-08-28	\N
becdd5a0-a57b-4ec2-a3e6-4d145a26184e	Doctors&Co Group	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	170493205009818	2026-05-23 00:55:26.164719	2026-05-23 00:55:26.164719	Professional	\N	\N	Healthcare	2028-02-01	\N
f1f29f2c-a76a-4455-baad-885ee28f6552	Dentist for Chickens	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	170668909130090	2026-05-23 00:55:26.168484	2026-05-23 00:55:26.168484	Professional	\N	\N	Other	2027-02-28	\N
4ce07ba0-1af2-4a86-91dd-04306ae2cdd7	The Beauty Base	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	170856197436582	2026-05-23 00:55:26.172755	2026-05-23 00:55:26.172755	Professional	\N	\N	Beauty	2027-04-03	\N
9737881b-69ac-4be4-8657-4013dc5714d7	Travellers Autobarn	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	172282137359076	2026-05-23 00:55:26.177077	2026-05-23 00:55:26.177077	Professional	\N	\N	Transportation Services	2027-04-15	\N
e66610cf-863b-41f1-ae1b-2b0c3ecabdf7	Medindie Dental	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	169700737852729	2026-05-23 00:55:26.181316	2026-05-23 00:55:26.181316	Professional	\N	\N	Dental	2026-10-16	\N
4633f053-bd7f-4be8-9974-e7b29b8ad39e	Gerard Malouf & Partners Lawyers	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	169881392703226	2026-05-23 00:55:26.18532	2026-05-23 00:55:26.18532	Professional	\N	\N	Legal	2026-11-26	\N
a82fdc5f-0ad2-49ec-a0bd-c7010aa94f5d	CityFitness	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	174131781174393	2026-05-23 00:55:26.189384	2026-05-23 00:55:26.189384	Professional	\N	\N	Recreation	2029-05-20	\N
c8421104-194c-4900-94cd-6dde5c654da8	Guild Insurance	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	red	f	\N	\N	175868954337276	2026-05-23 00:55:26.193355	2026-05-23 00:55:26.193355	Professional	\N	\N	Insurance	2026-09-30	\N
e3a9fbaf-b3a4-4db4-81e5-8c4562c486c1	Enviro-PCS	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	168982774667019	2026-05-23 00:55:26.19692	2026-05-23 00:55:26.19692	Professional	\N	\N	Other	2026-10-13	\N
87e2c894-0968-4d5e-9983-579957ea228e	Brisbane Dental	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	green	f	\N	\N	172472595611971	2026-05-23 00:55:26.201094	2026-05-23 00:55:26.201094	Professional	\N	\N	Dental	2026-10-21	\N
798205db-5c30-4706-ab09-88717faf1db9	My Legal Crunch Lawyers | Family Law | Mediation	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	172611627707958	2026-05-23 00:55:26.205225	2026-05-23 00:55:26.205225	Professional	\N	\N	Legal	2027-10-02	\N
c9e3dfdd-3ab4-4e2b-85b5-5d257cfc0857	Blackshaw Real Estate Corporate	b70f282a-e8a5-4842-954e-fcd2eca55251	\N	yellow	f	\N	\N	171098059648018	2026-05-23 00:55:26.208913	2026-05-23 00:55:26.208913	Professional	\N	\N	Real Estate	2026-12-09	\N
cb0412ec-6d9b-4b6b-9db0-d7bf03489331	Amber Tiles	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	175980682810738	2026-05-23 00:55:26.212622	2026-05-23 00:55:26.212622	Professional	\N	\N	Retail	2026-11-28	\N
d3df7dce-0d4b-4ab0-88d4-98a03c7b04a7	Xero Limited	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	green	f	\N	\N	175143201576614	2026-05-23 00:55:26.216004	2026-05-23 00:55:26.216004	Professional	\N	\N	Technology	2026-09-24	\N
48cfc67b-fe5f-442f-a311-e6131f8502d0	Davidson Cameron & Co	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	174848079422207	2026-05-23 00:55:26.219583	2026-05-23 00:55:26.219583	Professional	\N	\N	Real Estate	2026-06-23	\N
014339c2-300b-49b2-b2e5-68c167845ada	Ouwens Casserly Real Estate	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	170605841327511	2026-05-23 00:55:26.223916	2026-05-23 00:55:26.223916	Professional	\N	\N	Real Estate	2027-04-07	\N
b7838bc2-afe6-4570-b54f-b3c62b253d7d	Luv Bridal	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	171894059099111	2026-05-23 00:55:26.227642	2026-05-23 00:55:26.227642	Professional	\N	\N	Consumer Goods	2026-08-06	\N
1cc6bdc4-b576-41da-96d5-188b095ed7fb	Coronis	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	171150880481308	2026-05-23 00:55:26.231717	2026-05-23 00:55:26.231717	Professional	\N	\N	Real Estate	2027-06-30	\N
2fd9845f-0717-4daa-98d2-2c56d35c5785	Wardle Co Real Estate	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	170676283620509	2026-05-23 00:55:26.235661	2026-05-23 00:55:26.235661	Professional	\N	\N	Real Estate	2027-03-26	\N
adc0efa1-a12a-4613-9244-8fbf40def2cc	Chill-Rite Refrigeration and Air Conditioning	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	169594613705789	2026-05-23 00:55:26.239987	2026-05-23 00:55:26.239987	Professional	\N	\N	Contractors	2026-10-03	\N
a3d099fb-8822-41b4-8fb8-5bf405b33497	Ownit	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	green	f	\N	\N	172489973783078	2026-05-23 00:55:26.243886	2026-05-23 00:55:26.243886	Professional	\N	\N	Legal	2026-10-25	\N
5a32d184-3bed-41da-9d60-6240064a1cd3	OTR Wheels Tyres & Axles	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	green	f	\N	\N	172522941962189	2026-05-23 00:55:26.24717	2026-05-23 00:55:26.24717	Professional	\N	\N	Automotive	2027-02-19	\N
d2bb2e6a-9616-4623-825c-5c9f8b2b9bbd	Enterprise Motor Group New Lynn	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	172343750682654	2026-05-23 00:55:26.25066	2026-05-23 00:55:26.25066	Professional	\N	\N	Automotive	2026-09-09	\N
1d411073-18d0-40a3-a49e-08ddebf7435f	Traditional Credit Union	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	172837173759341	2026-05-23 00:55:26.254081	2026-05-23 00:55:26.254081	Professional	\N	\N	Finance	2026-11-02	\N
7ac8d16f-2887-4902-a525-9383d58c31e8	Nespresso	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	green	f	\N	\N	174173110590263	2026-05-23 00:55:26.257684	2026-05-23 00:55:26.257684	Professional	\N	\N	Consumer Goods	2026-11-28	\N
c13a1c50-698b-4936-b30e-dfca2adc423c	Kingsgrove Sports Centre	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	green	f	\N	\N	173275065723025	2026-05-23 00:55:26.263652	2026-05-23 00:55:26.263652	Professional	\N	\N	Retail	2026-12-13	\N
5eaa8166-c01a-4636-b864-1fcd00fb9685	Smartmove	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	176395887353049	2026-05-23 00:55:26.267489	2026-05-23 00:55:26.267489	Professional	\N	\N	Finance	2026-12-18	\N
01a5c93a-615e-4a90-9e84-c6becbbe32b0	RASHAYS Cafe	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	green	f	\N	\N	173572331170431	2026-05-23 00:55:26.272329	2026-05-23 00:55:26.272329	Professional	\N	\N	Restaurants	2026-10-14	\N
09c67581-0aad-45c8-a035-fa212c4e5eae	Fishbowl	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	174054528198737	2026-05-23 00:55:26.275856	2026-05-23 00:55:26.275856	Professional	\N	\N	Restaurants	2026-06-15	\N
dbb17644-6f8b-42e9-a533-13c8c0f4719d	Always There Automotive	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	green	f	\N	\N	169284443618065	2026-05-23 00:55:26.27947	2026-05-23 00:55:26.27947	Professional	\N	\N	Contractors	2026-09-30	\N
047c76f2-c18f-4d08-be47-8dcab1f7b9d5	Walkers Auto Electrics	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	165435561856754	2026-05-23 00:55:26.283661	2026-05-23 00:55:26.283661	Professional	\N	\N	Automotive	2026-10-12	\N
c5a7f708-c432-47d0-882d-c2c2bfb8a838	Bec Dental Group	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	green	f	\N	\N	175212910773128	2026-05-23 00:55:26.28964	2026-05-23 00:55:26.28964	Professional	\N	\N	Dental	2026-07-19	\N
230cc61c-3c8b-4ebc-b31a-9b458f245c4d	Therapy Alliance Group	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	green	f	\N	\N	171937964902542	2026-05-23 00:55:26.293679	2026-05-23 00:55:26.293679	Professional	\N	\N	Wellness	2026-11-25	\N
b976e213-adca-4b15-938b-015f35751ba4	Nightowl Convenience	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	174847265329729	2026-05-23 00:55:26.29728	2026-05-23 00:55:26.29728	Professional	\N	\N	Retail	2026-07-01	\N
5f127989-9527-4bad-9605-f795c51a043b	TCare Dental Centre	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	170493404371911	2026-05-23 00:55:26.301016	2026-05-23 00:55:26.301016	Professional	\N	\N	Dental	2027-01-14	\N
5bb307bc-3ccc-452d-bce8-57873cb2fab5	Beds R Us	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	green	f	\N	\N	175385834255922	2026-05-23 00:55:26.305345	2026-05-23 00:55:26.305345	Professional	\N	\N	Retail	2026-11-28	\N
99e98122-789c-4215-be2d-31d49b66f412	Attwood Marshall Lawyers	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	174367718658882	2026-05-23 00:55:26.309061	2026-05-23 00:55:26.309061	Professional	\N	\N	Legal	2026-07-28	\N
50ef81cd-8468-4b3f-a877-f80d5a09997b	Future Finance Group	f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	\N	yellow	f	\N	\N	170553629565305	2026-05-23 00:55:26.31316	2026-05-23 00:55:26.31316	Professional	\N	\N	Finance	2028-04-21	\N
19983cf8-dbb2-489b-997e-450e84a9c78e	Onvo Travel Plaza - Corporate Office	a6351540-4df1-4717-9266-ef0557a14515	\N	green	f	\N	\N	176496552482312	2026-05-23 00:55:26.316954	2026-05-23 00:55:26.316954	Professional	\N	\N	Restaurants	2027-02-13	\N
6b011b6b-8752-4c30-9059-9cf551494f97	Dolphin Hotel Management	a6351540-4df1-4717-9266-ef0557a14515	\N	green	f	\N	\N	176970743595755	2026-05-23 00:55:26.321103	2026-05-23 00:55:26.321103	Professional	\N	\N	Hospitality	2027-03-31	\N
be7fb797-d39e-4c64-b3c0-0c37d54ea611	Hutson Inc.	a6351540-4df1-4717-9266-ef0557a14515	\N	green	f	\N	\N	176590110460213	2026-05-23 00:55:26.32518	2026-05-23 00:55:26.32518	Professional	\N	\N	Automotive	2026-12-29	\N
60f3234b-0d70-4867-8cde-1c597cedd4fe	Millicare	a6351540-4df1-4717-9266-ef0557a14515	\N	yellow	f	\N	\N	176834120670021	2026-05-23 00:55:26.329797	2026-05-23 00:55:26.329797	Professional	\N	\N	Business Services	2027-04-29	\N
a0222f31-e0e7-4f81-abdf-aae1ffcd68a1	Ridgeline Roofing & Restoration	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	green	f	\N	\N	176841868123220	2026-05-23 00:55:26.334724	2026-05-23 00:55:26.334724	Professional	\N	\N	Contractors	2027-01-28	\N
ae9255ad-3e67-4846-8433-d3b7cd071f12	OnPoint Medical Group	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	151811039105799	2026-05-23 00:55:26.339325	2026-05-23 00:55:26.339325	Professional	\N	\N	Healthcare	2027-03-21	\N
a1d9cb7f-554a-41f6-b265-72adb473a79f	Stoltz Management	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	169930670673635	2026-05-23 00:55:26.344312	2026-05-23 00:55:26.344312	Professional	\N	\N	Real Estate	2028-03-10	\N
1b195596-80bc-4c6e-a7b9-dc56af4d4062	Rob Levine Law	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	150394583784750	2026-05-23 00:55:26.348831	2026-05-23 00:55:26.348831	Professional	\N	\N	Legal	2027-02-04	\N
a8d89e22-1017-4fca-8439-7c261bbdb7bd	FreedomCare	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	151915014091144	2026-05-23 00:55:26.354235	2026-05-23 00:55:26.354235	Professional	\N	\N	Healthcare	2027-02-27	\N
e9c6d5ac-ab41-4e52-a49a-649c49d24a1f	Exit Factor	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	173860531495932	2026-05-23 00:55:26.358695	2026-05-23 00:55:26.358695	Professional	\N	\N	Business Services	2026-08-15	\N
b9410a18-a6c5-445a-a381-575d6bf12c14	Health West	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	green	f	\N	\N	177162588319639	2026-05-23 00:55:26.362771	2026-05-23 00:55:26.362771	Professional	\N	\N	Healthcare	2027-03-15	\N
4e008dff-ed77-478c-80e9-6a3cb9966763	Campus Life & Style	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	164633489918924	2026-05-23 00:55:26.366943	2026-05-23 00:55:26.366943	Professional	\N	\N	Real Estate	2027-03-31	\N
db0dd825-998f-48eb-bba5-a18d48369c76	Transworld Business Advisors	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	173203174421009	2026-05-23 00:55:26.370414	2026-05-23 00:55:26.370414	Professional	\N	\N	Business Services	2026-11-30	\N
026784ea-9324-4b8a-94b7-843decdbde66	Pardy & Rodriguez, P.A.	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	151914052361446	2026-05-23 00:55:26.374415	2026-05-23 00:55:26.374415	Professional	\N	\N	Legal	2027-02-19	\N
ffa7d8fe-359a-4772-a24b-2dcff552c6c2	First Commonwealth Federal Credit Union	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	green	f	\N	\N	176537841778935	2026-05-23 00:55:26.378569	2026-05-23 00:55:26.378569	Professional	\N	\N	Finance	2027-01-29	\N
e5c0472c-2d47-4bd1-9fbf-b745249b9955	Fully Promoted	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	173203081685292	2026-05-23 00:55:26.382161	2026-05-23 00:55:26.382161	Professional	\N	\N	Consumer Goods	2026-11-29	\N
bbd31954-c995-4c9e-8ada-264baaf79968	AgeWell Senior Living	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	green	f	\N	\N	175339080615279	2026-05-23 00:55:26.385816	2026-05-23 00:55:26.385816	Professional	\N	\N	Wellness	2027-03-12	\N
d2b70d7b-339f-44a1-8af2-0c8318161802	Self Storage Services Inc	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	green	f	\N	\N	169625542393970	2026-05-23 00:55:26.389787	2026-05-23 00:55:26.389787	Professional	\N	\N	Consumer Services	2028-02-18	\N
04930c93-b53d-47e8-91a8-c204b9f0ea17	Southern Nevada Surgery Specialists	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	174664261625659	2026-05-23 00:55:26.393787	2026-05-23 00:55:26.393787	Professional	\N	\N	Healthcare	2027-05-07	\N
275932ae-3dd2-4f3b-8ad9-3d80ddec5d30	MyStorage	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	173410799038991	2026-05-23 00:55:26.397481	2026-05-23 00:55:26.397481	Professional	\N	\N	Consumer Services	2027-02-24	\N
1d194173-ae9e-4fb0-abad-1eecf76da61a	Johnson & Johnson Law Firm	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	green	f	\N	\N	156597453077254	2026-05-23 00:55:26.40148	2026-05-23 00:55:26.40148	Professional	\N	\N	Legal	2027-01-17	\N
5165d822-21c9-4645-b67f-cead35d455d2	Excel Dental, llc.	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	green	f	\N	\N	153679606702793	2026-05-23 00:55:26.405116	2026-05-23 00:55:26.405116	Professional	\N	\N	Dental	2028-02-19	\N
7da40d48-2b28-4222-80ed-fe13cb53c592	Streetside Classics	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	154964934150281	2026-05-23 00:55:26.408674	2026-05-23 00:55:26.408674	Professional	\N	\N	Automotive	2027-02-08	\N
111702c1-badd-42ee-a16d-5003175fef07	Randolph Center for Oral & Maxillofacial Surgery	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	155034384358473	2026-05-23 00:55:26.41224	2026-05-23 00:55:26.41224	Professional	\N	\N	Dental	2027-02-16	\N
d720a852-7416-47ec-81bc-ce2a0a96ccb1	The Legacy Lawyers, P.C.	ab7bd637-8552-454f-9dde-2313d8f2f432	\N	yellow	f	\N	\N	164583173917195	2026-05-23 00:55:26.415771	2026-05-23 00:55:26.415771	Professional	\N	\N	Legal	2027-02-25	\N
b410764e-4042-438f-a2b5-a3ca49f3283b	Wasabi Co. Ltd	1c36db24-ef04-4f47-a214-2a2b7c7f930d	\N	green	f	\N	\N	1761230658773433	2026-05-23 00:55:26.41927	2026-05-23 00:55:26.41927	Professional	\N	\N	Restaurants	2027-01-29	\N
fa4ff4ee-3f0e-49a1-b718-bee656447012	Angel Of The Winds Casino Resort	46c035c6-6314-45a0-ab81-f7792559300d	\N	red	f	\N	\N	166093869559959	2026-05-23 00:55:26.423149	2026-05-23 00:55:26.423149	Professional	\N	\N	Arts & Entertainment	2028-08-31	\N
7a807f47-b018-4690-b16c-491689dac0a0	Aspen Group HR	02a5f706-3275-4670-bc93-1d0f670799ba	\N	yellow	f	\N	\N	171054120091503	2026-05-23 00:55:26.432174	2026-05-23 00:55:26.432174	Professional	\N	\N	Dental	2027-03-15	\N
df5bc086-33d7-4714-bf95-af8776504121	Lovet Pet Health Care	02a5f706-3275-4670-bc93-1d0f670799ba	\N	yellow	f	\N	\N	162067734396970	2026-05-23 00:55:26.436372	2026-05-23 00:55:26.436372	Professional	\N	\N	Healthcare	2027-03-31	\N
12c9a5f9-91c5-400f-a1af-21dadd83be83	Billingsley Property Services II, Inc.	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	148607704842026	2026-05-23 00:55:26.440502	2026-05-23 00:55:26.440502	Professional	\N	\N	Real Estate	2027-02-07	\N
dfe9f599-886c-4014-9abe-593e2df4e5e0	Westville	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	green	f	\N	\N	173757600097756	2026-05-23 00:55:26.444452	2026-05-23 00:55:26.444452	Professional	\N	\N	Restaurants	2027-02-17	\N
59c42a94-bf0b-4e87-a51c-e269b71fead4	Pathways Healthcare	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	red	f	\N	\N	170249939719326	2026-05-23 00:55:26.448855	2026-05-23 00:55:26.448855	Professional	\N	\N	Healthcare	2027-01-14	\N
77c080cc-9054-49b8-b678-5ae7c67fc054	Grapevine Communications	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	168123794158488	2026-05-23 00:55:26.453103	2026-05-23 00:55:26.453103	Professional	\N	\N	Business Services	2027-04-11	\N
62640b86-85e5-4613-b88a-3923b924daaf	East Carolina Outdoor Products LLC	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	165338748284910	2026-05-23 00:55:26.457279	2026-05-23 00:55:26.457279	Professional	\N	\N	Home Services	2027-03-29	\N
7e7763b8-4761-4608-923f-3e3f0db0cd58	Venture Forthe	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	157106485545150	2026-05-23 00:55:26.460808	2026-05-23 00:55:26.460808	Professional	\N	\N	Healthcare	2027-10-31	\N
ec1b2f69-ee66-405a-9ed5-cf07ad0a3ccb	Paxton Medical Management	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	red	f	\N	\N	174256879599715	2026-05-23 00:55:26.464812	2026-05-23 00:55:26.464812	Professional	\N	\N	Healthcare	2028-04-10	\N
87ded46e-a70d-4458-956f-7edc37136a19	Premier Dental	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	148891510994744	2026-05-23 00:55:26.468708	2026-05-23 00:55:26.468708	Professional	\N	\N	Dental	2027-07-02	\N
bd20e3da-ebe6-4352-9b09-485d2514cd64	TLC Management Co	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	150332556392493	2026-05-23 00:55:26.472542	2026-05-23 00:55:26.472542	Professional	\N	\N	Real Estate	2027-08-30	\N
d4b528cc-de16-4179-b7de-2416ed3a84c0	Carolina Furniture Concepts	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	green	f	\N	\N	153020447313317	2026-05-23 00:55:26.475867	2026-05-23 00:55:26.475867	Professional	\N	\N	Retail	2027-11-29	\N
4fd4f7df-c30c-4717-a1f9-d0138c8070c0	Catalyst Orthodontics	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	170144242706471	2026-05-23 00:55:26.479308	2026-05-23 00:55:26.479308	Professional	\N	\N	Healthcare	2027-12-17	\N
f1f89443-eda2-4860-80d1-ec8e1f49d55d	Concept Property Management	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	668028992	2026-05-23 00:55:26.483386	2026-05-23 00:55:26.483386	Professional	\N	\N	Real Estate	2026-12-13	\N
8b3f53a0-1d71-48a7-8fee-14b2a55fbbc9	Smile Arts of NY	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	149848810915648	2026-05-23 00:55:26.487248	2026-05-23 00:55:26.487248	Professional	\N	\N	Dental	2026-10-26	\N
d6a75deb-b6f5-4889-b891-3073d9b7147a	WallyPark	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	157418171996151	2026-05-23 00:55:26.490786	2026-05-23 00:55:26.490786	Professional	\N	\N	Automotive	2027-10-30	\N
df6d59b2-b25f-4def-8125-717b63fa9b57	Smythe Insolvency Inc.	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	167087671630846	2026-05-23 00:55:26.494238	2026-05-23 00:55:26.494238	Professional	\N	\N	Finance	2026-12-22	\N
ead02867-3038-48a4-a15c-905d602a355d	TintWorks	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	175157898142764	2026-05-23 00:55:26.497323	2026-05-23 00:55:26.497323	Professional	\N	\N	Automotive	2026-07-09	\N
c1c0ec0c-02a4-46ea-baaf-3c1693f3c398	Splintered Forest Tree Services	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	161230433940215	2026-05-23 00:55:26.500723	2026-05-23 00:55:26.500723	Professional	\N	\N	Home Services	2027-02-02	\N
8ae9448f-939c-4ab2-b6cd-6108e9c2b751	Washington Jaw & Facial Surgery	e82a85a3-78cc-4cd5-938d-d7771cbd8246	\N	yellow	f	\N	\N	162276930439176	2026-05-23 00:55:26.504339	2026-05-23 00:55:26.504339	Professional	\N	\N	Dental	2027-04-02	\N
bcbbd0b7-8966-48d1-aead-aa9124cd6f8c	Associates in Medicine & Surgery	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	163491518008556	2026-05-23 00:55:26.50777	2026-05-23 00:55:26.50777	Professional	\N	\N	Healthcare	2027-01-31	\N
23671fde-05ee-4eba-813a-4436e9cea856	Storage Star	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	159077160953413	2026-05-23 00:55:26.511434	2026-05-23 00:55:26.511434	Professional	\N	\N	Consumer Services	2027-11-29	\N
d9fc70e2-bdcb-48cb-ac5d-8205d76efb1f	American United Federal Credit Union	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	155439528684946	2026-05-23 00:55:26.514823	2026-05-23 00:55:26.514823	Professional	\N	\N	Finance	2027-04-12	\N
d210db61-f86b-4f74-9e35-4158b109d89c	Metro Credit Union	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	161956656670332	2026-05-23 00:55:26.518761	2026-05-23 00:55:26.518761	Professional	\N	\N	Finance	2028-01-19	\N
7acd050e-a0ef-4555-b148-84633f41a2a2	Planet 13	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	175683499982859	2026-05-23 00:55:26.529093	2026-05-23 00:55:26.529093	Professional	\N	\N	Retail	2026-10-29	\N
965cb8a5-da4b-4d0a-af9f-a06248eda939	Performance Ortho	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	green	f	\N	\N	169593544108276	2026-05-23 00:55:26.533179	2026-05-23 00:55:26.533179	Professional	\N	\N	Healthcare	2027-01-27	\N
4cbd2064-c2c3-453a-878c-dbbf0d38f99d	Tiffin Indian Cuisine	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	168737263811066	2026-05-23 00:55:26.537484	2026-05-23 00:55:26.537484	Professional	\N	\N	Business Services	2026-12-30	\N
8b94ce78-0880-42b8-8ebf-072fad34cca2	Community Resource Credit Union	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	green	f	\N	\N	169461902948720	2026-05-23 00:55:26.541502	2026-05-23 00:55:26.541502	Professional	\N	\N	Finance	2027-01-25	\N
0783b0fd-9e85-4c9d-8af5-f8b40c11cc3f	Livingston International	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	166419532749342	2026-05-23 00:55:26.546014	2026-05-23 00:55:26.546014	Professional	\N	\N	Real Estate	2027-03-29	\N
2e838eff-ed0e-4a34-9410-33032326835b	Medella Urgent Care	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	green	f	\N	\N	158161581326476	2026-05-23 00:55:26.550269	2026-05-23 00:55:26.550269	Professional	\N	\N	Healthcare	2027-03-04	\N
ea1d9b53-a00c-4537-9003-14e2a84a5038	Elite Jewelers	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	165247000470916	2026-05-23 00:55:26.554118	2026-05-23 00:55:26.554118	Professional	\N	\N	Consumer Goods	2026-05-30	\N
a8f5e7f9-e431-4471-89af-111da7fc36ac	Doppler Veterinary Network	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	175390472864797	2026-05-23 00:55:26.558255	2026-05-23 00:55:26.558255	Professional	\N	\N	Healthcare	2026-09-15	\N
ac5e7081-5634-47be-ae56-8660a895addc	Summit Automotive Partners	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	149996244821459	2026-05-23 00:55:26.562085	2026-05-23 00:55:26.562085	Professional	\N	\N	Automotive	2026-11-01	\N
ef997627-07d8-4e53-9228-5c3a2d43ed00	Stor-It Self Storage LLC	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	162087735482026	2026-05-23 00:55:26.565867	2026-05-23 00:55:26.565867	Professional	\N	\N	Consumer Services	2028-11-25	\N
1ffd94d0-29ce-4871-8006-9baa4601fed8	Gateway Foundation	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	175260930701482	2026-05-23 00:55:26.56964	2026-05-23 00:55:26.56964	Professional	\N	\N	Healthcare	2027-09-26	\N
ad8c8041-f850-4427-9f26-36b89ca699a0	Nebraska Family Dentistry	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	green	f	\N	\N	167228055292522	2026-05-23 00:55:26.573784	2026-05-23 00:55:26.573784	Professional	\N	\N	Dental	2028-02-03	\N
ad4b9e5e-45f9-4950-8d2a-8beaddc4c88e	Fyda, Inc	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	168435738406607	2026-05-23 00:55:26.577458	2026-05-23 00:55:26.577458	Professional	\N	\N	Automotive	2026-06-29	\N
caf9103b-7d72-45f1-a902-6ce09abae815	Natura Pest Control	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	165543104656057	2026-05-23 00:55:26.581163	2026-05-23 00:55:26.581163	Professional	\N	\N	Home Services	2026-06-28	\N
25fc5dba-11eb-4ab4-b553-2ffc0fd9cceb	Bingham Equipment Company	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	155715862329338	2026-05-23 00:55:26.584461	2026-05-23 00:55:26.584461	Professional	\N	\N	Automotive	2026-09-17	\N
90bf13e1-4c2e-45b0-869c-9a85c896eb69	Ontario Diagnostic Centres	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	157669116564544	2026-05-23 00:55:26.588051	2026-05-23 00:55:26.588051	Professional	\N	\N	Healthcare	2026-05-31	\N
b598924a-e5ec-427b-81b2-f9e343ab30c9	Hawaii Health Systems Corporation	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	168634853635432	2026-05-23 00:55:26.59143	2026-05-23 00:55:26.59143	Professional	\N	\N	Healthcare	2026-07-30	\N
945dae0f-b02a-4eb8-aed2-90acd9d47258	Travis Hyde Properties	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	173091357027750	2026-05-23 00:55:26.594673	2026-05-23 00:55:26.594673	Professional	\N	\N	Real Estate	2026-11-29	\N
ac1d1715-bd06-4d38-b208-8b1a1713da6a	Carolina Storage	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	172426163909431	2026-05-23 00:55:26.598259	2026-05-23 00:55:26.598259	Professional	\N	\N	Consumer Services	2026-08-29	\N
6f1d20bf-e1fc-4e04-a021-e74ca6cc5d8a	Real.Travel	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	167042669505673	2026-05-23 00:55:26.601772	2026-05-23 00:55:26.601772	Professional	\N	\N	Hospitality	2027-08-29	\N
76cf7b5d-3e84-432f-a1b4-a1af10368f24	Neighbors Federal Credit Union	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	162188764415964	2026-05-23 00:55:26.605046	2026-05-23 00:55:26.605046	Professional	\N	\N	Finance	2027-03-23	\N
e3fb9d2d-30ce-44f0-9b12-325e966448f8	Credit Union ONE	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	green	f	\N	\N	164735933344081	2026-05-23 00:55:26.608263	2026-05-23 00:55:26.608263	Professional	\N	\N	Finance	2027-08-31	\N
6aa7d368-f8ba-4aef-9608-78767bcd1f17	Lytal, Reiter, Smith, Ivey & Fronrath	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	158457580708449	2026-05-23 00:55:26.611629	2026-05-23 00:55:26.611629	Professional	\N	\N	Legal	2027-03-19	\N
ee9e1bb2-d2f8-4244-a3e1-0f09acb9a9c9	NearU	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	green	f	\N	\N	166177922106652	2026-05-23 00:55:26.61524	2026-05-23 00:55:26.61524	Professional	\N	\N	Contractors	2026-10-18	\N
430f5e20-c1b8-41ac-a1e2-7f68d53d2797	Mazzio's	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	168063755692506	2026-05-23 00:55:26.619152	2026-05-23 00:55:26.619152	Professional	\N	\N	Restaurants	2026-06-30	\N
786ab780-3851-4151-b4b6-b5006c514c36	LBS Financial Credit Union	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	green	f	\N	\N	156986373926858	2026-05-23 00:55:26.623233	2026-05-23 00:55:26.623233	Professional	\N	\N	Finance	2026-10-18	\N
86d6a2fb-08bb-4b4f-abad-540cf96fda35	global smiles dental	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	153271238714460	2026-05-23 00:55:26.62686	2026-05-23 00:55:26.62686	Professional	\N	\N	Dental	2026-07-27	\N
d3c51427-ce42-481f-87d2-b260ca64921a	Primp and Blow	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	green	f	\N	\N	155236183381503	2026-05-23 00:55:26.630959	2026-05-23 00:55:26.630959	Professional	\N	\N	Beauty	2027-06-27	\N
11358ccc-2e5c-4da8-a092-e2a4e43655b2	Metropolitan Bath and Tile	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	green	f	\N	\N	167120591059895	2026-05-23 00:55:26.634838	2026-05-23 00:55:26.634838	Professional	\N	\N	Retail	2029-03-25	\N
e1fa8244-f50c-471a-b25f-44e9cbbee099	Smart Choice Windows and More	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	156685502545071	2026-05-23 00:55:26.639415	2026-05-23 00:55:26.639415	Professional	\N	\N	Home Services	2026-08-26	\N
750c6edd-f8bb-4bce-bc53-6f236b00463b	Frontier Credit Union	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	155620076740687	2026-05-23 00:55:26.643066	2026-05-23 00:55:26.643066	Professional	\N	\N	Finance	2027-04-23	\N
4197f41e-a00e-424e-8e24-5542d7eefc83	Franklin Communities	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	green	f	\N	\N	169660038509082	2026-05-23 00:55:26.646626	2026-05-23 00:55:26.646626	Professional	\N	\N	Real Estate	2028-04-16	\N
40a71b67-4ee7-4bfb-bbc1-c0e7d8d7c879	Oral, Facial & Implant Surgery Salina & Med Spa	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	156908052950579	2026-05-23 00:55:26.650068	2026-05-23 00:55:26.650068	Professional	\N	\N	Dental	2026-09-21	\N
e62735a8-dc0c-41c0-8075-b037f00284b2	Heritage Operations Group	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	171951034054032	2026-05-23 00:55:26.653492	2026-05-23 00:55:26.653492	Professional	\N	\N	Healthcare	2026-07-26	\N
31aef88b-efea-44f1-979d-a95a01777048	Lifestyle Club	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	green	f	\N	\N	155352760747692	2026-05-23 00:55:26.658016	2026-05-23 00:55:26.658016	Professional	\N	\N	Hospitality	2027-05-12	\N
05815b2c-edb9-4709-acb2-d4dc1dde3072	Doran Companies	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	161531368542873	2026-05-23 00:55:26.66145	2026-05-23 00:55:26.66145	Professional	\N	\N	Real Estate	2026-07-29	\N
a0cac69f-fa8f-42ad-b491-aa2de3797cac	Solar Optimum, Inc.	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	167243292413142	2026-05-23 00:55:26.664953	2026-05-23 00:55:26.664953	Professional	\N	\N	Technology	2026-08-26	\N
97ea6498-d919-40e1-8839-a054ca048a74	A.G. Cassar Management L.L.C.	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	172729895022481	2026-05-23 00:55:26.668415	2026-05-23 00:55:26.668415	Professional	\N	\N	Real Estate	2026-06-01	\N
6c85ebe2-ce67-41bf-82ff-760b264e6ce1	Bleuwave	66f072be-a0bf-4328-a45c-1f927fbcfd4e	\N	yellow	f	\N	\N	169869820656145	2026-05-23 00:55:26.672165	2026-05-23 00:55:26.672165	Professional	\N	\N	Contractors	2026-11-14	\N
f7662f91-0019-4abf-8c07-0a0bc6340330	Capital Health Care Network	acd1c2fa-6a07-4f5c-aca9-a0c666b69940	\N	yellow	f	\N	\N	163474448882304	2026-05-23 00:55:26.675668	2026-05-23 00:55:26.675668	Professional	\N	\N	Business Services	2026-11-29	\N
0c79044e-e0fb-4054-b1ea-571e2d86fc72	Orthodontic Associates	acd1c2fa-6a07-4f5c-aca9-a0c666b69940	\N	yellow	f	\N	\N	165048367426619	2026-05-23 00:55:26.679348	2026-05-23 00:55:26.679348	Professional	\N	\N	Dental	2026-05-31	\N
eed03536-d3d8-40a2-82c7-8a66fb050d11	Complete Care Centers	acd1c2fa-6a07-4f5c-aca9-a0c666b69940	\N	yellow	f	\N	\N	170302122552491	2026-05-23 00:55:26.683209	2026-05-23 00:55:26.683209	Professional	\N	\N	Healthcare	2027-02-15	\N
f6ac69b9-8555-40e2-a1aa-6f3baba78019	New Hampshire Oral and Maxillofacial Surgery	acd1c2fa-6a07-4f5c-aca9-a0c666b69940	\N	yellow	f	\N	\N	150793032380565	2026-05-23 00:55:26.687358	2026-05-23 00:55:26.687358	Professional	\N	\N	Dental	2027-11-15	\N
80f68282-321b-4460-b060-a27053c4a42e	Ybarra Franchising Group, LLC	acd1c2fa-6a07-4f5c-aca9-a0c666b69940	\N	yellow	f	\N	\N	155983259743683	2026-05-23 00:55:26.691086	2026-05-23 00:55:26.691086	Professional	\N	\N	Restaurants	2027-05-20	\N
df267fe5-6d25-470d-869a-329005bc6ece	APS	acd1c2fa-6a07-4f5c-aca9-a0c666b69940	\N	green	f	\N	\N	170776928308504	2026-05-23 00:55:26.694462	2026-05-23 00:55:26.694462	Professional	\N	\N	Home Services	2026-11-08	\N
6ad9870c-ee50-4d64-8de6-d860948aea66	Eden Therapy and Massage	acd1c2fa-6a07-4f5c-aca9-a0c666b69940	\N	yellow	f	\N	\N	173696907265877	2026-05-23 00:55:26.698464	2026-05-23 00:55:26.698464	Professional	\N	\N	Wellness	2027-01-21	\N
e40be96b-1de2-445f-9aae-106d20f31d80	Dr. Andrews Plastic Surgery	acd1c2fa-6a07-4f5c-aca9-a0c666b69940	\N	yellow	f	\N	\N	157532113327730	2026-05-23 00:55:26.701898	2026-05-23 00:55:26.701898	Professional	\N	\N	Wellness	2026-12-11	\N
3fcedc5a-17b4-452a-ae58-2fac27e454e5	Dunlop Tyre	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	yellow	f	\N	\N	175184520323382	2026-05-23 00:55:26.70545	2026-05-23 00:55:26.70545	Professional	\N	\N	Automotive	2026-12-06	\N
6e4f3b41-295e-431f-9b90-744bcacb4067	Carpet Call	832299ec-81b4-45da-9c61-ab97c69e8d56	\N	green	f	\N	\N	176456606892291	2026-05-23 00:55:26.708827	2026-05-23 00:55:26.708827	Professional	\N	\N	Consumer Goods	2027-04-29	\N
8786cd44-b5d1-4ca4-8f0b-d28e150a2beb	Priority Ambulance	10ec1e18-cc66-4f4d-bb2c-77ce6d62919e	\N	green	f	\N	\N	176945702777189	2026-05-23 00:55:26.715614	2026-05-23 00:55:26.715614	Professional	\N	\N	Healthcare	2027-03-16	\N
a4adfa54-767e-4d2d-8145-0d9a892b665a	Spring-Green Lawn Care	10ec1e18-cc66-4f4d-bb2c-77ce6d62919e	\N	yellow	f	\N	\N	158109699562144	2026-05-23 00:55:26.719863	2026-05-23 00:55:26.719863	Professional	\N	\N	Home Services	2027-04-14	\N
22339a15-bcce-44b3-bbb4-50ef7fce4bd7	Greater Austin Allergy	10ec1e18-cc66-4f4d-bb2c-77ce6d62919e	\N	green	f	\N	\N	177454722807662	2026-05-23 00:55:26.723984	2026-05-23 00:55:26.723984	Professional	\N	\N	Healthcare	2027-03-31	\N
aa128b38-6e92-4cb4-958c-484bb613a5e1	Flat Iron	5abbea6a-ba11-4cf9-a9f3-5795453dec7b	\N	green	f	\N	\N	1772520120657013	2026-05-23 00:55:26.727733	2026-05-23 00:55:26.727733	Professional	\N	\N	Restaurants	2028-03-30	\N
765fcc57-df50-432a-bddc-40704c7e9154	The Hearing Clinic UK	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	170972380809132	2026-05-23 00:55:26.731507	2026-05-23 00:55:26.731507	Professional	\N	\N	Wellness	2026-07-31	\N
1dde2e7d-850f-46a7-aecc-c82b144251a1	Lyons Bowe Solicitors	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	172647794443342	2026-05-23 00:55:26.735174	2026-05-23 00:55:26.735174	Professional	\N	\N	Legal	2026-09-23	\N
46e3de26-6d24-4613-b7c0-139b0ed05e01	Argyll Townhouse	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	172441985209495	2026-05-23 00:55:26.738729	2026-05-23 00:55:26.738729	Professional	\N	\N	Real Estate	2026-11-18	\N
7f2fa6ba-76ef-4f01-a080-fe8ae1915c52	ILSC, ELS, and Greystone College	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	170137269459619	2026-05-23 00:55:26.742151	2026-05-23 00:55:26.742151	Professional	\N	\N	Education	2027-01-24	\N
3f2924f4-aa8a-4d54-9ced-5589ee857835	CaliDental	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	156701144073704	2026-05-23 00:55:26.747002	2026-05-23 00:55:26.747002	Professional	\N	\N	Dental	2026-06-11	\N
28938324-f6fa-4043-9020-dc460f3392ba	Greensboro Imaging	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	green	f	\N	\N	163543123802025	2026-05-23 00:55:26.750771	2026-05-23 00:55:26.750771	Professional	\N	\N	Healthcare	2028-01-21	\N
cfd13d67-adc5-4486-9510-14bfa0ef15ac	Perfect Brow Bar	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	169469151238715	2026-05-23 00:55:26.760106	2026-05-23 00:55:26.760106	Professional	\N	\N	Beauty	2027-02-16	\N
d48b65f6-7b39-4a88-a9c6-8c8b4309a222	Beacon Credit Union	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	166264829390945	2026-05-23 00:55:26.76404	2026-05-23 00:55:26.76404	Professional	\N	\N	Finance	2027-09-30	\N
e8b35743-58f1-4cc3-92c0-a10480d91a0c	London Doctors Clinic	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	173746998203726	2026-05-23 00:55:26.768195	2026-05-23 00:55:26.768195	Professional	\N	\N	Healthcare	2026-05-31	\N
6516e289-bb2f-4ad0-87ec-7c91b56470fe	Bierman Autism Centers	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	169272873846001	2026-05-23 00:55:26.772034	2026-05-23 00:55:26.772034	Professional	\N	\N	Healthcare	2027-02-12	\N
01a7730f-89a0-4294-968d-aca0b3cc5031	Fox Group (Moving & Storage) Ltd	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	169589959135767	2026-05-23 00:55:26.775943	2026-05-23 00:55:26.775943	Professional	\N	\N	Transportation Services	2026-09-30	\N
ebd4ee84-894d-4860-93bb-2126cf22cb98	Premier Lending, Inc.	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	168433493192373	2026-05-23 00:55:26.779464	2026-05-23 00:55:26.779464	Professional	\N	\N	Finance	2026-11-12	\N
6150ac6e-7874-44c3-90a5-6d1732172985	Palmetto Dunes	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	147804373443233	2026-05-23 00:55:26.783237	2026-05-23 00:55:26.783237	Professional	\N	\N	Real Estate	2027-07-27	\N
4847ca08-21e4-4fd4-9ea3-d0b1be6776e1	BankFiveNine	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	160711272656168	2026-05-23 00:55:26.786811	2026-05-23 00:55:26.786811	Professional	\N	\N	Finance	2026-11-13	\N
e9e612aa-0850-4641-a0fb-f5e0daeb44fc	Arun Estate Agencies Ltd	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	173384992983374	2026-05-23 00:55:26.789969	2026-05-23 00:55:26.789969	Professional	\N	\N	Real Estate	2027-06-30	\N
29123d9a-a401-4812-85b8-79baace71066	Law Office of Bryan Fagan, PLLC	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	149020350076522	2026-05-23 00:55:26.793387	2026-05-23 00:55:26.793387	Professional	\N	\N	Legal	2028-03-29	\N
a9b34e7b-bac4-43a3-acb5-e2c5e9f3508b	Day's Jewelers | Waterville, ME	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	green	f	\N	\N	168502911433196	2026-05-23 00:55:26.796548	2026-05-23 00:55:26.796548	Professional	\N	\N	Consumer Goods	2028-08-08	\N
30a1d7db-f9f1-4e87-9722-8cca6ba8a2fe	Shasta Community Health Center	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	green	f	\N	\N	151207909470563	2026-05-23 00:55:26.800632	2026-05-23 00:55:26.800632	Professional	\N	\N	Healthcare	2028-01-24	\N
6bc61507-6ec3-4fca-b223-6b6cd32c974f	Articularis Healthcare Group	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	green	f	\N	\N	170483403449951	2026-05-23 00:55:26.804384	2026-05-23 00:55:26.804384	Professional	\N	\N	Healthcare	2027-05-20	\N
b547e0be-2995-4ac0-a7a3-acb65b8397b3	E.C. Alderwick & Son Ltd.	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	171863007247208	2026-05-23 00:55:26.807925	2026-05-23 00:55:26.807925	Professional	\N	\N	Consumer Services	2026-06-25	\N
fd3b9f4f-1608-428e-af36-dcc2efdd42f6	Diamond And Diamond Lawyers LLP	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	157972227743603	2026-05-23 00:55:26.811334	2026-05-23 00:55:26.811334	Professional	\N	\N	Legal	2027-04-13	\N
debf14d3-07a6-410c-8870-38c68dbad04a	Turtle Bay	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	174240454690884	2026-05-23 00:55:26.816374	2026-05-23 00:55:26.816374	Professional	\N	\N	Restaurants	2026-06-13	\N
3a9d922e-8c00-47fe-aa5c-9b3310e88c98	Pain Free Dentistry Group	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	green	f	\N	\N	174005984703077	2026-05-23 00:55:26.822533	2026-05-23 00:55:26.822533	Professional	\N	\N	Dental	2027-03-30	\N
8b7252ed-fef1-4fc7-9362-2a08489d249a	Harvest Valley Pest Control	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	168297037369705	2026-05-23 00:55:26.826347	2026-05-23 00:55:26.826347	Professional	\N	\N	Contractors	2027-05-11	\N
9936d7a7-f835-4f15-ad8f-8b232d314500	Ensors Accountants LLP	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	red	f	\N	\N	173140323370955	2026-05-23 00:55:26.829934	2026-05-23 00:55:26.829934	Professional	\N	\N	Finance	2027-01-30	\N
13faabc6-a2de-4b01-8f5b-bd3a2456210f	77 Diamonds	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	171387965917913	2026-05-23 00:55:26.834478	2026-05-23 00:55:26.834478	Professional	\N	\N	Consumer Goods	2026-08-13	\N
78674414-07bf-434a-9340-b23d5ab7604e	Forest Lawn Memorial-Parks & Mortuaries	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	154543977265041	2026-05-23 00:55:26.837848	2026-05-23 00:55:26.837848	Professional	\N	\N	Consumer Services	2028-09-27	\N
b41c9d6b-805d-495e-825f-307ffea251cb	Signs Express	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	173219093964815	2026-05-23 00:55:26.841201	2026-05-23 00:55:26.841201	Professional	\N	\N	Business Services	2027-01-17	\N
6f764fd2-7ac5-4d60-9c3a-f299bae2d87c	Amicus Law (South West) LLP	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	171034247644659	2026-05-23 00:55:26.845565	2026-05-23 00:55:26.845565	Professional	\N	\N	Legal	2028-04-30	\N
20381525-7c70-45e4-8c58-fa11db41bc51	Space Station Self Storage	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	1766047823246063	2026-05-23 00:55:26.849417	2026-05-23 00:55:26.849417	Professional	\N	\N	Consumer Services	2026-12-18	\N
a897695e-0191-4c06-a8f6-f28563bf7c5b	Caffe Concerto	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	green	f	\N	\N	173868221110995	2026-05-23 00:55:26.855335	2026-05-23 00:55:26.855335	Professional	\N	\N	Restaurants	2030-02-13	\N
a2fa3631-633f-49e4-bd0e-da20d5cf9204	H/K/B Cosmetic Surgery	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	157793805963225	2026-05-23 00:55:26.859384	2026-05-23 00:55:26.859384	Professional	\N	\N	Healthcare	2026-07-25	\N
3dda6c46-6b22-4116-8ca3-e0460aacd9f8	Shamrock Property Management LLC	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	172736680325545	2026-05-23 00:55:26.863994	2026-05-23 00:55:26.863994	Professional	\N	\N	Real Estate	2026-06-01	\N
4ba88b2a-91ab-4397-9dd1-5a31592299a3	Verity Healthcare	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	174712685290644	2026-05-23 00:55:26.868098	2026-05-23 00:55:26.868098	Professional	\N	\N	Healthcare	2029-04-30	\N
f254f618-4b7c-4c9d-9f4a-6e336efe102e	CIBTvisas Global Headquarters	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	169282682757958	2026-05-23 00:55:26.872277	2026-05-23 00:55:26.872277	Professional	\N	\N	Business Services	2027-01-01	\N
e8494f8c-f059-4c3c-a11a-05950bfe328d	North State Dental Partners	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	156502503762214	2026-05-23 00:55:26.876151	2026-05-23 00:55:26.876151	Professional	\N	\N	Dental	2026-08-05	\N
14608c15-6ace-49ed-a8fb-933e057325fc	Elizabeth Finn Homes Ltd	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	172363148171922	2026-05-23 00:55:26.87977	2026-05-23 00:55:26.87977	Professional	\N	\N	Healthcare	2026-09-26	\N
ec2d34bc-cb11-4203-84c8-49976ebeb43f	Greenslade Taylor Hunt	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	173028653900266	2026-05-23 00:55:26.883376	2026-05-23 00:55:26.883376	Professional	\N	\N	Real Estate	2027-12-28	\N
47554407-6f6f-4fd0-8563-5d55a6e1f16b	Martyn Gerrard	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	174715160194473	2026-05-23 00:55:26.887274	2026-05-23 00:55:26.887274	Professional	\N	\N	Real Estate	2027-04-22	\N
4f75c7ae-a696-487b-ad8b-d22a260459ef	Kobe Japanese Steakhouse	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	154715901084491	2026-05-23 00:55:26.890869	2026-05-23 00:55:26.890869	Professional	\N	\N	Restaurants	2026-06-30	\N
7b43b486-c374-4cb4-9f59-2dd37717426d	Mainstreet Credit Union	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	160735306442157	2026-05-23 00:55:26.894805	2026-05-23 00:55:26.894805	Professional	\N	\N	Finance	2026-12-31	\N
4b379c06-e07e-42c4-a352-706b91ef1d9e	Vascular Institute of Virginia	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	red	f	\N	\N	154775805853778	2026-05-23 00:55:26.898815	2026-05-23 00:55:26.898815	Professional	\N	\N	Healthcare	2027-01-17	\N
f23b2067-7cb0-4488-81e7-338cce350fba	Smith Douglas Homes	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	148165766132288	2026-05-23 00:55:26.902754	2026-05-23 00:55:26.902754	Professional	\N	\N	Real Estate	2027-03-01	\N
9ce0d2dd-2573-4b87-bede-072b89614989	Aderans Hair Centre	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	green	f	\N	\N	172416203184591	2026-05-23 00:55:26.906335	2026-05-23 00:55:26.906335	Professional	\N	\N	Beauty	2027-02-02	\N
f925b523-b3f0-475d-8ec6-5b7eb399d238	Thomas Auto Group	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	160833749251639	2026-05-23 00:55:26.910205	2026-05-23 00:55:26.910205	Professional	\N	\N	Automotive	2026-12-21	\N
185baea5-c3e6-4a1f-ab4f-3ef230dcdf1a	Healthpointe	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	green	f	\N	\N	820032896	2026-05-23 00:55:26.91377	2026-05-23 00:55:26.91377	Professional	\N	\N	Healthcare	2028-04-12	\N
a51b286d-839b-44dc-9000-4115a3064608	Regain Hearing	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	1761661692218093	2026-05-23 00:55:26.917172	2026-05-23 00:55:26.917172	Professional	\N	\N	Healthcare	2027-11-18	\N
442bba62-2775-494a-b8e8-d6fe5a8b0643	Caron Group	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	1759818491716423	2026-05-23 00:55:26.920772	2026-05-23 00:55:26.920772	Professional	\N	\N	Wellness	2026-11-09	\N
e6d57226-ca71-4783-9041-08f0653c584f	Bourn Hall Fertility Clinic	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	170134830446386	2026-05-23 00:55:26.924456	2026-05-23 00:55:26.924456	Professional	\N	\N	Healthcare	2027-02-28	\N
2163bfb0-2bcb-48cf-919d-120849b74f2f	Grace Medical Aesthetics	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	155181565006604	2026-05-23 00:55:26.928428	2026-05-23 00:55:26.928428	Professional	\N	\N	Wellness	2027-03-05	\N
1159c47f-f136-4b0a-a343-2fceaed9fef4	Falkirk Dental Care	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	green	f	\N	\N	170895445020722	2026-05-23 00:55:26.932807	2026-05-23 00:55:26.932807	Professional	\N	\N	Dental	2026-06-26	\N
79d437c0-44ef-4a7e-a561-6addc6b1fcd3	Dunedin Dental Clinic	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	green	f	\N	\N	172865680352110	2026-05-23 00:55:26.936458	2026-05-23 00:55:26.936458	Professional	\N	\N	Dental	2026-10-28	\N
66cdaa00-b433-44d8-a22b-fd140b2a22d1	Ashberry Healthcare Limited	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	174652285337658	2026-05-23 00:55:26.940459	2026-05-23 00:55:26.940459	Professional	\N	\N	Healthcare	2026-07-22	\N
1ff2d118-1670-4579-904d-6205429b03da	J Coates	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	green	f	\N	\N	175310124453897	2026-05-23 00:55:26.944347	2026-05-23 00:55:26.944347	Professional	\N	\N	Education	2028-08-13	\N
2f1a43e6-80f1-4023-b935-7e0e3734e086	Morgan Fertility and Reproductive Medicine	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	157781108186251	2026-05-23 00:55:26.947839	2026-05-23 00:55:26.947839	Professional	\N	\N	Healthcare	2026-08-03	\N
85386a90-abda-4ae7-8a73-0f89410c71ef	Clece Care Services	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	173695107622160	2026-05-23 00:55:26.960471	2026-05-23 00:55:26.960471	Professional	\N	\N	Healthcare	2026-06-30	\N
136fbf53-872a-4c43-bc24-eb6c15d75182	Southwest Oral Surgical Arts	e68e2148-bff2-4ba0-a8ed-9d843f9786eb	\N	yellow	f	\N	\N	166845613067699	2026-05-23 00:55:26.964585	2026-05-23 00:55:26.964585	Professional	\N	\N	Dental	2026-11-14	\N
028b0ce1-fc6c-4218-8761-93d285a17c32	Fine Airport Parking	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	175442391957980	2026-05-23 00:55:26.968285	2026-05-23 00:55:26.968285	Professional	\N	\N	Automotive	2026-09-30	\N
2693c21f-960c-495d-9bb2-a0e9f7aaf711	Suncoastskin Solutions	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	161832948369587	2026-05-23 00:55:26.971644	2026-05-23 00:55:26.971644	Professional	\N	\N	Healthcare	2027-12-30	\N
3c165837-5796-432f-a4d3-f0193b181f4d	The Friendly Toast	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	175311423047012	2026-05-23 00:55:26.975203	2026-05-23 00:55:26.975203	Professional	\N	\N	Restaurants	2026-08-29	\N
2a6d4a41-8c59-4285-a3de-b91d853164db	Acme Oyster House	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	161895252042253	2026-05-23 00:55:26.979605	2026-05-23 00:55:26.979605	Professional	\N	\N	Restaurants	2026-07-28	\N
f8928165-ba93-4487-a029-640b0a2fb557	Natural Dentures & Implant Center	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	176652992463562	2026-05-23 00:55:26.983537	2026-05-23 00:55:26.983537	Professional	\N	\N	Dental	2026-12-30	\N
2762c6d6-72e0-4555-8909-80a1a194ab43	Neuropsychiatric Hospital of Indianapolis	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	173879463238089	2026-05-23 00:55:26.986962	2026-05-23 00:55:26.986962	Professional	\N	\N	Healthcare	2026-06-30	\N
e6a870e2-c857-4eb3-b687-66b7741de776	Ameritas	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	169532979986698	2026-05-23 00:55:26.990251	2026-05-23 00:55:26.990251	Professional	\N	\N	Finance	2026-11-25	\N
0fd3263c-0f04-491e-ad61-42d163470c65	Resound Networks	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	174983093535137	2026-05-23 00:55:26.993474	2026-05-23 00:55:26.993474	Professional	\N	\N	Technology	2026-11-19	\N
5da717d9-2e9e-4245-a5ed-14b3b84ec307	YMCA of GREATER CHARLOTTE	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	174906177106781	2026-05-23 00:55:26.997008	2026-05-23 00:55:26.997008	Professional	\N	\N	Recreation	2028-07-31	\N
2da713fe-11f2-4149-af09-1e397129b18e	Texas Tech Credit Union	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	162214236414776	2026-05-23 00:55:27.001075	2026-05-23 00:55:27.001075	Professional	\N	\N	Finance	2026-08-31	\N
087f326c-2d54-4188-bb16-05a677209595	Grand Rapids Gm	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	157132287963471	2026-05-23 00:55:27.004952	2026-05-23 00:55:27.004952	Professional	\N	\N	Automotive	2026-11-08	\N
1ba129d8-6e7a-4906-b354-46b0033a6b89	Harding Mazzotti, LLP	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	172443176830800	2026-05-23 00:55:27.008596	2026-05-23 00:55:27.008596	Professional	\N	\N	Legal	2026-09-27	\N
af53926d-27d6-4a68-a052-cd5a9226a906	HME Companies	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	174792642849780	2026-05-23 00:55:27.012609	2026-05-23 00:55:27.012609	Professional	\N	\N	Contractors	2026-12-31	\N
241917bc-7ad7-4567-8be9-c8389d5d546c	Carlton Senior Living	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	169869466859304	2026-05-23 00:55:27.016071	2026-05-23 00:55:27.016071	Professional	\N	\N	Wellness	2026-09-30	\N
4931e0d2-f0b6-40e5-8c5f-4d6c50c07c59	Mustang Creek Estates	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	174766737716553	2026-05-23 00:55:27.019317	2026-05-23 00:55:27.019317	Professional	\N	\N	Wellness	2026-10-14	\N
44450068-105c-49f4-bf46-ebcc9a41b12e	Lazer Adjusters	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	173678855676192	2026-05-23 00:55:27.022767	2026-05-23 00:55:27.022767	Professional	\N	\N	Construction	2027-04-15	\N
a7a776c3-3ed8-4471-813a-8266f8a1238e	Sandstone Care LLC	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	162085159125665	2026-05-23 00:55:27.026286	2026-05-23 00:55:27.026286	Professional	\N	\N	Healthcare	2026-11-21	\N
3a200f15-7947-4f7a-98ba-8ac4bf96e02c	Haven Home Healthcare	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	175743357409925	2026-05-23 00:55:27.029708	2026-05-23 00:55:27.029708	Professional	\N	\N	Healthcare	2026-09-18	\N
d3bae690-6cc1-4fc5-8b74-4b5df7c82f62	Pacific Lawn Sprinklers	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	176340894055643	2026-05-23 00:55:27.033379	2026-05-23 00:55:27.033379	Professional	\N	\N	Home Services	2026-12-11	\N
9ffad372-af23-4292-86cc-90e7c6b1db15	JL Parking LLC	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	176555786190253	2026-05-23 00:55:27.036839	2026-05-23 00:55:27.036839	Professional	\N	\N	Automotive	2026-12-12	\N
42efc1f4-e4c5-4bac-ac36-432ea46ba41f	Storage World	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	164727751255531	2026-05-23 00:55:27.040976	2026-05-23 00:55:27.040976	Professional	\N	\N	Consumer Services	2027-03-29	\N
8e31f9fe-323b-4e72-ad9f-eef40245a198	Hattie B's Hot Chicken	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	165426469513104	2026-05-23 00:55:27.044263	2026-05-23 00:55:27.044263	Professional	\N	\N	Restaurants	2026-06-30	\N
466b5ff0-4697-4cf1-b9b9-cab2cf0bceb6	RAYGUN	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	162196833703710	2026-05-23 00:55:27.047825	2026-05-23 00:55:27.047825	Professional	\N	\N	Retail	2026-12-17	\N
8dec77eb-423d-425c-84e8-ea2b30c3b3df	HFS Federal Credit Union - Keaau	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	red	f	\N	\N	170146355570057	2026-05-23 00:55:27.051634	2026-05-23 00:55:27.051634	Professional	\N	\N	Finance	2026-12-22	\N
fb784586-1f59-48e8-b5ea-24d49f082bc4	CENTURY 21 Judge Fite Company	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	169758187378197	2026-05-23 00:55:27.055204	2026-05-23 00:55:27.055204	Professional	\N	\N	Real Estate	2026-11-14	\N
84f54de5-e045-4cca-a1a0-336760bccee1	Tones Day Spa	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	173274457454079	2026-05-23 00:55:27.058849	2026-05-23 00:55:27.058849	Professional	\N	\N	Wellness	2026-08-24	\N
d368c252-9014-4ebf-9f3d-26105a3014d2	Royal Swimming Pools	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	154991435730793	2026-05-23 00:55:27.062946	2026-05-23 00:55:27.062946	Professional	\N	\N	Home Services	2027-02-11	\N
374b49f8-ce8e-4857-b3a2-b70d57ebe24b	Christian Living Communities	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	174018127179921	2026-05-23 00:55:27.066353	2026-05-23 00:55:27.066353	Professional	\N	\N	Wellness	2027-03-30	\N
fe27213d-b313-4451-8a99-be6d43119943	CommuniCare	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	156143465059732	2026-05-23 00:55:27.070119	2026-05-23 00:55:27.070119	Professional	\N	\N	Healthcare	2026-12-19	\N
322b2a54-905f-4201-881b-41854d73858f	Gladstone Psychiatry and Wellness	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	175207886150546	2026-05-23 00:55:27.074297	2026-05-23 00:55:27.074297	Professional	\N	\N	Healthcare	2026-08-14	\N
228cf468-b8f1-48fe-b695-c6152f2012a7	Cleveland Dental Management	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	176548231191557	2026-05-23 00:55:27.078593	2026-05-23 00:55:27.078593	Professional	\N	\N	Dental	2026-12-21	\N
dd07c167-6720-4527-a2f9-db0e908eaa2f	First Alliance Credit Union	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	163917473785085	2026-05-23 00:55:27.083338	2026-05-23 00:55:27.083338	Professional	\N	\N	Finance	2026-12-14	\N
69e04c37-8012-4f42-a3e2-479e3f79a5bc	Family Dental Care	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	146239546890378	2026-05-23 00:55:27.087167	2026-05-23 00:55:27.087167	Professional	\N	\N	Dental	2029-03-29	\N
11213baf-becb-4911-b9ed-0423caa42909	Lee Auto Malls	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	169895735679291	2026-05-23 00:55:27.091211	2026-05-23 00:55:27.091211	Professional	\N	\N	Automotive	2026-08-30	\N
4b2c8d2b-4739-4359-a4f0-822caae09fed	Modani Furniture	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	150056140529413	2026-05-23 00:55:27.095364	2026-05-23 00:55:27.095364	Professional	\N	\N	Real Estate	2026-08-31	\N
920b548d-5ce4-4a0b-8db4-f64b2bc4515e	Reeve Woods Eye Center	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	164987462068979	2026-05-23 00:55:27.099133	2026-05-23 00:55:27.099133	Professional	\N	\N	Healthcare	2028-04-13	\N
11764703-142f-4fa2-b14b-aa19b8658820	LUMINANCE REGENERATIVE BEAUTY & WELLNESS	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	169265759203600	2026-05-23 00:55:27.103342	2026-05-23 00:55:27.103342	Professional	\N	\N	Wellness	2026-06-30	\N
b36ee279-5141-467f-b4bd-b2e742fe7bae	TWIN CITIES ORAL & MAXILLOFACIAL SURGERY	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	162343567087886	2026-05-23 00:55:27.107047	2026-05-23 00:55:27.107047	Professional	\N	\N	Dental	2026-11-29	\N
8eacd943-93c3-4e85-8a9a-4b9ca4cc43b0	HEW Fitness	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	175381440870104	2026-05-23 00:55:27.110847	2026-05-23 00:55:27.110847	Professional	\N	\N	Recreation	2026-12-29	\N
1f464b33-959b-4a78-9640-7f211071c894	Oxnard Dentistry	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	159163034163379	2026-05-23 00:55:27.114499	2026-05-23 00:55:27.114499	Professional	\N	\N	Dental	2026-06-26	\N
81ad6034-b711-4e27-906d-826ae2735fd5	Kimlin Energy Services	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	157133776388183	2026-05-23 00:55:27.118065	2026-05-23 00:55:27.118065	Professional	\N	\N	Home Services	2026-06-23	\N
ac2e2c4d-05eb-4d83-9137-e6548c86b355	East Coast Sprayers	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	170257765485842	2026-05-23 00:55:27.123121	2026-05-23 00:55:27.123121	Professional	\N	\N	Home Services	2026-12-15	\N
a5ebd585-d892-42cf-a791-940cfbef5140	StoreRight Self Storage	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	165539476570637	2026-05-23 00:55:27.127869	2026-05-23 00:55:27.127869	Professional	\N	\N	Consumer Services	2028-02-27	\N
491f0951-c3dd-4b46-bbea-ceaaf5f378e1	Shift4	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	164131824521217	2026-05-23 00:55:27.135786	2026-05-23 00:55:27.135786	Professional	\N	\N	Technology	2027-02-03	\N
cf6fa538-b0f5-414f-9637-cf62c5b617ad	Economy Fence	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	166905345644345	2026-05-23 00:55:27.140753	2026-05-23 00:55:27.140753	Professional	\N	\N	Construction	2026-11-21	\N
bc8d55e9-7211-4211-9110-7a3f7b60ec3d	Blue Back Dental: West Hartford and Avon	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	145808072243478	2026-05-23 00:55:27.144942	2026-05-23 00:55:27.144942	Professional	\N	\N	Dental	2028-03-15	\N
44626995-bf03-4b9e-afa4-16bea099d8db	Simonian Oriental Rug Cleaners	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	154826616816284	2026-05-23 00:55:27.148908	2026-05-23 00:55:27.148908	Professional	\N	\N	Home Services	2029-03-24	\N
7f7565ea-515f-4fc3-bb13-14141c685654	Bellwether Community Credit Union	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	yellow	f	\N	\N	164995144510296	2026-05-23 00:55:27.152827	2026-05-23 00:55:27.152827	Professional	\N	\N	Finance	2026-10-14	\N
a8c6aad1-eef9-4d2e-bf0c-780ba897a5fe	Park-N-Go Dayton Airport Parking	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	149270244374052	2026-05-23 00:55:27.156372	2026-05-23 00:55:27.156372	Professional	\N	\N	Automotive	2027-04-28	\N
02d816e6-0937-4713-a19f-ce768b08b8dd	Urban Day Spa	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	176236895342004	2026-05-23 00:55:27.16073	2026-05-23 00:55:27.16073	Professional	\N	\N	Beauty	2026-11-05	\N
1317a745-abd0-4172-b791-0d391fbff98c	Redmint	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	164573764403187	2026-05-23 00:55:27.165108	2026-05-23 00:55:27.165108	Professional	\N	\N	Wellness	2026-12-06	\N
490c4acf-1721-4ee1-a264-af3071598373	GOODTIME III	f46a55a3-b5cd-4568-a5b7-d0862d917635	\N	green	f	\N	\N	149269857121015	2026-05-23 00:55:27.168958	2026-05-23 00:55:27.168958	Professional	\N	\N	Recreation	2027-04-23	\N
58276905-e456-4d72-8232-70ff8646940f	Spilman Auto Parts Inc	0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	\N	yellow	f	\N	\N	173696007305150	2026-05-23 00:55:27.173388	2026-05-23 00:55:27.173388	Professional	\N	\N	Automotive	2027-01-15	\N
4014b80a-ed7d-4c8d-bb60-bf00993e5bf0	Armor Fence Co	0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	\N	yellow	f	\N	\N	157480129361750	2026-05-23 00:55:27.177335	2026-05-23 00:55:27.177335	Professional	\N	\N	Contractors	2026-12-10	\N
fd43af4f-51c2-4613-af25-0afa135b047b	Michaelangelo's Sustainable Landscape & Design Group	0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	\N	yellow	f	\N	\N	167519045671014	2026-05-23 00:55:27.181668	2026-05-23 00:55:27.181668	Professional	\N	\N	Contractors	2027-01-19	\N
e67448af-9737-480b-b53c-2eb4ab11f534	Results Laser Clinic	0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	\N	yellow	f	\N	\N	155803338966553	2026-05-23 00:55:27.185411	2026-05-23 00:55:27.185411	Professional	\N	\N	Beauty	2028-05-03	\N
3dfbc257-5bc0-4d03-aa55-99294787521a	Sydney Smile Care - Cabramatta	0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	\N	yellow	f	\N	\N	175801839414650	2026-05-23 00:55:27.188976	2026-05-23 00:55:27.188976	Professional	\N	\N	Dental	2026-09-30	\N
9492cace-2341-4b09-9dab-7185e6624f2e	Lawen Dentistry	0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	\N	yellow	f	\N	\N	164202617478851	2026-05-23 00:55:27.193111	2026-05-23 00:55:27.193111	Professional	\N	\N	Dental	2027-01-12	\N
f1ca3499-28ef-4c25-81ef-9dbd2bb7698b	Fuller's Service Center	0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	\N	yellow	f	\N	\N	172589671791127	2026-05-23 00:55:27.196962	2026-05-23 00:55:27.196962	Professional	\N	\N	Automotive	2027-03-03	\N
578ededa-adda-4b6e-82ad-8127fe7a6f43	Pony Salon	0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	\N	yellow	f	\N	\N	160702986868369	2026-05-23 00:55:27.200867	2026-05-23 00:55:27.200867	Professional	\N	\N	Beauty	2027-03-30	\N
31f0caa4-39d9-47b4-8673-f765128f0aeb	AC Today	0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	\N	yellow	f	\N	\N	167405660901882	2026-05-23 00:55:27.204794	2026-05-23 00:55:27.204794	Professional	\N	\N	Contractors	2027-01-18	\N
477a10bb-8b67-4c5e-9f7a-50e18882e9c6	Southwest Auto Glass	0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	\N	yellow	f	\N	\N	171638553410561	2026-05-23 00:55:27.208359	2026-05-23 00:55:27.208359	Professional	\N	\N	Automotive	2028-02-23	\N
256d5170-3e35-4f29-9c59-ae900361324e	Bay Area Plumbing, Inc.	0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	\N	yellow	f	\N	\N	174863367899445	2026-05-23 00:55:27.212479	2026-05-23 00:55:27.212479	Professional	\N	\N	Contractors	2026-05-30	\N
77372916-f503-4942-b50f-4fad4b145899	Eaze	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	172772996647239	2026-05-23 00:55:27.216002	2026-05-23 00:55:27.216002	Professional	\N	\N	Consumer Services	2026-10-17	\N
ba2a063f-5b8b-4b28-a174-aa4aeb43a4de	Title Guaranty Escrow Services, Inc.	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	168306181693056	2026-05-23 00:55:27.219833	2026-05-23 00:55:27.219833	Professional	\N	\N	Real Estate	2027-08-31	\N
b773d7f2-17b7-4ad6-8177-cf54df7f7bc8	Kniesel's Collision Centers	974ba604-4f28-42ba-b910-bfb553ae6161	\N	green	f	\N	\N	161011881181153	2026-05-23 00:55:27.223688	2026-05-23 00:55:27.223688	Professional	\N	\N	Automotive	2027-08-13	\N
8aaeec48-31d8-4c64-adc8-02be4849e1e5	Georgia Dermatology & Skin Cancer Center	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	170751720591914	2026-05-23 00:55:27.227578	2026-05-23 00:55:27.227578	Professional	\N	\N	Healthcare	2027-03-31	\N
36928197-52b4-480c-8f84-7d3fd955bb6c	Advantage Storage	974ba604-4f28-42ba-b910-bfb553ae6161	\N	green	f	\N	\N	175649511654481	2026-05-23 00:55:27.231739	2026-05-23 00:55:27.231739	Professional	\N	\N	Consumer Services	2026-08-31	\N
54028fd3-c7fe-429b-a7e8-03d7d3f358bf	San Diego Dining Events	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	173472373420116	2026-05-23 00:55:27.235413	2026-05-23 00:55:27.235413	Professional	\N	\N	Restaurants	2027-01-31	\N
3bf0c41a-0425-4b28-8421-3798183a973c	Suds Deluxe Car Wash	974ba604-4f28-42ba-b910-bfb553ae6161	\N	green	f	\N	\N	175442907898983	2026-05-23 00:55:27.238848	2026-05-23 00:55:27.238848	Professional	\N	\N	Automotive	2026-10-27	\N
a9b54bd4-549d-4a08-a25a-8db9718a73b1	Zintex Remodeling Group	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	176375385322036	2026-05-23 00:55:27.242627	2026-05-23 00:55:27.242627	Professional	\N	\N	Home Services	2026-12-09	\N
20291378-e01c-4dff-b158-93ed2f95b4e3	Nebraska Title Company	974ba604-4f28-42ba-b910-bfb553ae6161	\N	red	f	\N	\N	171044940609792	2026-05-23 00:55:27.246041	2026-05-23 00:55:27.246041	Professional	\N	\N	Insurance	2027-05-06	\N
0b1d93c9-72ac-4a1f-b7d2-be25b0c51621	Rocky River Dental Management	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	159433246310687	2026-05-23 00:55:27.249668	2026-05-23 00:55:27.249668	Professional	\N	\N	E-commerce	2027-03-22	\N
f3c98745-afca-42a3-8703-6d9a5d6c0a52	George Sink, P.A. Injury Lawyers	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	170196607848717	2026-05-23 00:55:27.25367	2026-05-23 00:55:27.25367	Professional	\N	\N	Legal	2026-12-21	\N
1725e698-8b74-4145-8217-20aa08e8e2e8	A & M Properties	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	172729881104183	2026-05-23 00:55:27.257651	2026-05-23 00:55:27.257651	Professional	\N	\N	Real Estate	2026-06-01	\N
03a4e03e-f551-4f6f-af7d-5ce3fb21e1c7	Lombardo Homes	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	173219936991032	2026-05-23 00:55:27.261706	2026-05-23 00:55:27.261706	Professional	\N	\N	Construction	2027-01-27	\N
30460555-c886-47d4-96d2-6b6e3a312593	Restoration Management Company	974ba604-4f28-42ba-b910-bfb553ae6161	\N	red	f	\N	\N	170250067960588	2026-05-23 00:55:27.265787	2026-05-23 00:55:27.265787	Professional	\N	\N	Contractors	2026-12-19	\N
5ab3c610-d243-461a-b65c-0a32a0400730	Buzz Custom Fence - Fort Worth	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	171952091679263	2026-05-23 00:55:27.26958	2026-05-23 00:55:27.26958	Professional	\N	\N	Contractors	2026-06-27	\N
2e8751bb-c041-4e5c-a25a-a549cce72c6d	Recharge Clinic	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	170932344625360	2026-05-23 00:55:27.273165	2026-05-23 00:55:27.273165	Professional	\N	\N	Healthcare	2027-05-21	\N
737fc9c9-6fe9-4ad9-8892-1db156cb7bd3	Good Shepherd Hospice	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	161864730415306	2026-05-23 00:55:27.27668	2026-05-23 00:55:27.27668	Professional	\N	\N	Healthcare	2027-06-28	\N
08758c5f-192b-4627-825b-24e039a3dd22	Consumers Credit Union	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	173825771071076	2026-05-23 00:55:27.280688	2026-05-23 00:55:27.280688	Professional	\N	\N	Finance	2028-02-27	\N
a55b4bf8-a0c0-498a-aa19-aca8e86c6bca	Milani MedSpa	974ba604-4f28-42ba-b910-bfb553ae6161	\N	green	f	\N	\N	163978031804178	2026-05-23 00:55:27.28435	2026-05-23 00:55:27.28435	Professional	\N	\N	Wellness	2028-01-05	\N
b87d69f1-90fe-450f-9e94-c4cfdb6cda60	Pearl Pools - Fort Myers	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	156693262051202	2026-05-23 00:55:27.287702	2026-05-23 00:55:27.287702	Professional	\N	\N	Home Services	2027-04-30	\N
a2d2b7d0-2b00-459a-b5ab-4c870d5f1da0	Capital Credit Union	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	169530887044951	2026-05-23 00:55:27.291774	2026-05-23 00:55:27.291774	Professional	\N	\N	Finance	2027-01-07	\N
f58a1dc0-01d9-4fcb-a582-03e14a24e1e5	Adam & Eve - 5 Locations Franchise	974ba604-4f28-42ba-b910-bfb553ae6161	\N	green	f	\N	\N	173776769243184	2026-05-23 00:55:27.295409	2026-05-23 00:55:27.295409	Professional	\N	\N	Retail	2030-01-29	\N
1fed4b51-9c92-45e7-83ba-01a4a7bd2eee	Berrett Pest	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	162209358377369	2026-05-23 00:55:27.299229	2026-05-23 00:55:27.299229	Professional	\N	\N	Home Services	2028-04-30	\N
61d81eed-0252-4f55-ae39-4d9bd5b00350	Maison Law	974ba604-4f28-42ba-b910-bfb553ae6161	\N	red	f	\N	\N	163595948940456	2026-05-23 00:55:27.302727	2026-05-23 00:55:27.302727	Professional	\N	\N	Legal	2027-01-03	\N
130762cc-5ab0-4484-94bd-16de996d0af0	Fort William Henry	974ba604-4f28-42ba-b910-bfb553ae6161	\N	green	f	\N	\N	171216949943004	2026-05-23 00:55:27.306232	2026-05-23 00:55:27.306232	Professional	\N	\N	Hospitality	2028-01-05	\N
25255b05-5d89-4766-ab9c-cb03620196bb	The Vineyards - California Armenian Home	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	167605505857628	2026-05-23 00:55:27.310784	2026-05-23 00:55:27.310784	Professional	\N	\N	Wellness	2027-01-23	\N
6b2827d6-d125-4df8-ba34-75e7c0047253	Dottie's Flowers & Plants	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	169531354765438	2026-05-23 00:55:27.314464	2026-05-23 00:55:27.314464	Professional	\N	\N	Consumer Services	2026-09-21	\N
b28055c4-8805-43bf-97c0-58410e706991	United States Building Supply, Inc.	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	170607755145395	2026-05-23 00:55:27.318488	2026-05-23 00:55:27.318488	Professional	\N	\N	Construction	2028-04-05	\N
cc6059b4-7235-40c0-82a1-18671cc85e9f	Edge Dental Management	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	174533687511255	2026-05-23 00:55:27.32244	2026-05-23 00:55:27.32244	Professional	\N	\N	Dental	2027-05-11	\N
0e03b30e-3422-4dd9-b7b9-0b6bc13bfcfb	Excelsior Communities	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	170181031991008	2026-05-23 00:55:27.326715	2026-05-23 00:55:27.326715	Professional	\N	\N	Real Estate	2027-01-05	\N
1ac0c478-8085-4d85-a19f-995e1e8541c1	Mint Indian Bistro	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	166423141680924	2026-05-23 00:55:27.334439	2026-05-23 00:55:27.334439	Professional	\N	\N	Restaurants	2026-09-30	\N
8d86b62f-a595-48b1-84e9-a5a0f9ba5cbc	Radiant Senior Living	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	169056648503789	2026-05-23 00:55:27.340528	2026-05-23 00:55:27.340528	Professional	\N	\N	Wellness	2027-01-12	\N
a15bd507-88cc-4d87-9426-1ff4075230b6	Manrique Custom Vision Center	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	172238109126992	2026-05-23 00:55:27.344729	2026-05-23 00:55:27.344729	Professional	\N	\N	Healthcare	2026-08-22	\N
25b04042-dff7-4822-a227-b0e1372cc23a	HVAC Comfort	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	169541748078575	2026-05-23 00:55:27.348741	2026-05-23 00:55:27.348741	Professional	\N	\N	Contractors	2026-08-07	\N
3fc1036c-db9d-4802-8db4-8c8e9c43dd5d	Rally Credit Union	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	173688253241889	2026-05-23 00:55:27.355008	2026-05-23 00:55:27.355008	Professional	\N	\N	Finance	2027-02-23	\N
7a96c00a-0fdd-4853-b2d3-f17d5d10c4b0	5812 Investment Group	974ba604-4f28-42ba-b910-bfb553ae6161	\N	green	f	\N	\N	169990833943539	2026-05-23 00:55:27.360795	2026-05-23 00:55:27.360795	Professional	\N	\N	Real Estate	2027-01-16	\N
6e24fc7f-5613-4630-95c5-73cef600c821	Crown Home Care - Brooklyn	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	169290940860764	2026-05-23 00:55:27.36459	2026-05-23 00:55:27.36459	Professional	\N	\N	Healthcare	2026-06-08	\N
67f0d478-fc43-4b06-8a60-91fe5486abe2	GHR Center for Addiction Recovery and Treatment	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	171483523447893	2026-05-23 00:55:27.36823	2026-05-23 00:55:27.36823	Professional	\N	\N	Healthcare	2027-05-10	\N
848c5576-c243-47ea-983f-dd99b3e99919	Davis Window & Door	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	167966868208727	2026-05-23 00:55:27.37186	2026-05-23 00:55:27.37186	Professional	\N	\N	Contractors	2028-03-28	\N
0d393a6a-fcc2-4252-b824-98dfccc8617e	Fox Injury Law	974ba604-4f28-42ba-b910-bfb553ae6161	\N	green	f	\N	\N	168779107213413	2026-05-23 00:55:27.376521	2026-05-23 00:55:27.376521	Professional	\N	\N	Legal	2026-06-27	\N
9b3578d3-14d8-43cc-b382-d4b1945faef5	Atlanta Hearing Associates	974ba604-4f28-42ba-b910-bfb553ae6161	\N	green	f	\N	\N	169454335925150	2026-05-23 00:55:27.380511	2026-05-23 00:55:27.380511	Professional	\N	\N	Retail	2027-09-18	\N
7cc32e85-b33c-45d4-9e2a-f5f28472f717	The Gutter Guys	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	157166990677621	2026-05-23 00:55:27.384709	2026-05-23 00:55:27.384709	Professional	\N	\N	Home Services	2026-10-21	\N
356165be-ac51-4b7e-a841-ca656e4d98dc	Highland Dental	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	169420559209532	2026-05-23 00:55:27.389063	2026-05-23 00:55:27.389063	Professional	\N	\N	Dental	2026-10-16	\N
890e7259-f103-4d86-8cfc-5b7b892a5865	Mountainside Dental	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	169040313654281	2026-05-23 00:55:27.393354	2026-05-23 00:55:27.393354	Professional	\N	\N	Dental	2026-09-11	\N
d3ac8b7a-5c7b-4803-9e13-cf12347ae0a1	The Medical Team	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	170483361509999	2026-05-23 00:55:27.397226	2026-05-23 00:55:27.397226	Professional	\N	\N	Healthcare	2027-05-02	\N
269b5dfb-d3f8-4c36-bee5-94e96cbeac0d	Leggat Auto Group	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	168787721276018	2026-05-23 00:55:27.400951	2026-05-23 00:55:27.400951	Professional	\N	\N	Automotive	2027-03-16	\N
61f60311-5e55-4c43-8850-9ad3addc4d9c	Preferred Trust Company	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	168132680521700	2026-05-23 00:55:27.404304	2026-05-23 00:55:27.404304	Professional	\N	\N	Finance	2027-04-29	\N
f510b4a2-ba47-473a-b378-f0e59fa37e38	FATCO Holdings, LLC	974ba604-4f28-42ba-b910-bfb553ae6161	\N	green	f	\N	\N	167469638704787	2026-05-23 00:55:27.4081	2026-05-23 00:55:27.4081	Professional	\N	\N	Insurance	2027-01-26	\N
a1823191-09d3-4a2b-a8ec-cd5524ca5ecd	Wildfire Credit Union	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	171588949309959	2026-05-23 00:55:27.41173	2026-05-23 00:55:27.41173	Professional	\N	\N	Finance	2026-06-26	\N
96960038-13ce-43ae-999d-f89806e87569	Fusion Property Management	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	165912371322413	2026-05-23 00:55:27.415915	2026-05-23 00:55:27.415915	Professional	\N	\N	Real Estate	2027-02-12	\N
ccf685b3-e35f-4736-9180-5a93df9d2dbd	Berkower Pain & Spine Rehabilitation: David Berkower, DO	974ba604-4f28-42ba-b910-bfb553ae6161	\N	yellow	f	\N	\N	174671158375799	2026-05-23 00:55:27.420012	2026-05-23 00:55:27.420012	Professional	\N	\N	Healthcare	2027-05-08	\N
a4077818-8ffd-4802-8706-fb6a9ee773e3	SP Hospitality Group	015c26cb-d437-4e9f-bbb5-572c02d58736	\N	green	f	\N	\N	177213978402958	2026-05-23 00:55:27.424079	2026-05-23 00:55:27.424079	Professional	\N	\N	Business Services	2027-04-23	\N
21e860d1-0088-45b5-a736-96402225552e	ALLO Fiber	015c26cb-d437-4e9f-bbb5-572c02d58736	\N	green	f	\N	\N	176886116446285	2026-05-23 00:55:27.428083	2026-05-23 00:55:27.428083	Professional	\N	\N	Technology	2028-02-27	\N
e715d184-0fa5-4e7e-989e-806165c80293	United Dental Partners	015c26cb-d437-4e9f-bbb5-572c02d58736	\N	yellow	f	\N	\N	176105496770812	2026-05-23 00:55:27.43336	2026-05-23 00:55:27.43336	Professional	\N	\N	Dental	2028-03-31	\N
38678024-59f1-4bcd-9fde-12fce990f98d	VASA Fitness	015c26cb-d437-4e9f-bbb5-572c02d58736	\N	green	f	\N	\N	176832528954680	2026-05-23 00:55:27.437712	2026-05-23 00:55:27.437712	Professional	\N	\N	Recreation	2028-02-24	\N
e034dcbb-f28f-41ea-a7a7-9348935cdf39	Marathon Mermaid Charters	015c26cb-d437-4e9f-bbb5-572c02d58736	\N	green	f	\N	\N	177669273214834	2026-05-23 00:55:27.442421	2026-05-23 00:55:27.442421	Professional	\N	\N	Hospitality	2027-04-21	\N
b690e9f6-ee38-4b6e-961c-1d02c9ad9ec0	Attorney Brian White	015c26cb-d437-4e9f-bbb5-572c02d58736	\N	green	f	\N	\N	177436713699083	2026-05-23 00:55:27.451284	2026-05-23 00:55:27.451284	Professional	\N	\N	Other	2027-03-30	\N
0f141723-6463-49d7-8449-f3de253e5878	Pratum Companies	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	172288431692972	2026-05-23 00:55:27.462162	2026-05-23 00:55:27.462162	Professional	\N	\N	Real Estate	2026-06-05	\N
29d646a8-eb25-48af-a60f-f50f5fa41481	Carbon Thompson Multifamily Management LLC	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	172730056927416	2026-05-23 00:55:27.466299	2026-05-23 00:55:27.466299	Professional	\N	\N	Real Estate	2026-05-30	\N
9596b6ca-80fc-4e08-ba59-5c0bd827ff88	Atrium	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	175399845773939	2026-05-23 00:55:27.470433	2026-05-23 00:55:27.470433	Professional	\N	\N	Real Estate	2026-09-26	\N
9eee9ab7-2bf7-42d5-9cd6-945936234328	Uncle Giuseppe's Marketplace	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	162072702664731	2026-05-23 00:55:27.474208	2026-05-23 00:55:27.474208	Professional	\N	\N	Restaurants	2027-06-01	\N
c647cc09-cd8f-4475-9d2b-3f19b8dc7bfe	Cooper, Adel, Vu & Associates, LPA	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	157263513589966	2026-05-23 00:55:27.478497	2026-05-23 00:55:27.478497	Professional	\N	\N	Legal	2026-11-01	\N
b62c31b7-dd38-4c83-97cf-a5c458569a40	Master Lawn	0935a1f0-751b-44d7-992d-26a36294542d	\N	red	f	\N	\N	173777503555809	2026-05-23 00:55:27.482148	2026-05-23 00:55:27.482148	Professional	\N	\N	Home Services	2027-02-09	\N
fb94f315-2aff-4462-a6cb-1167b3f9e790	Inframark Community Management	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	170118825362991	2026-05-23 00:55:27.485945	2026-05-23 00:55:27.485945	Professional	\N	\N	Business Services	2027-03-01	\N
01620ddb-164e-4133-895d-eb73032711dd	thl USA	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	161402800584085	2026-05-23 00:55:27.489497	2026-05-23 00:55:27.489497	Professional	\N	\N	Automotive	2026-07-01	\N
5c9eda07-9744-48b5-a352-ae8afd9414eb	Gastro Center of Maryland	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	176243077481652	2026-05-23 00:55:27.492862	2026-05-23 00:55:27.492862	Professional	\N	\N	Healthcare	2026-11-07	\N
0d53788b-5690-4205-a1b3-dd76c4e9828a	Kanoski Bresney	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	156105682890900	2026-05-23 00:55:27.49669	2026-05-23 00:55:27.49669	Professional	\N	\N	Legal	2026-07-09	\N
08700167-06d1-444d-93b5-d62073071c5d	Healthquest Physical Therapy	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	162097776551165	2026-05-23 00:55:27.500608	2026-05-23 00:55:27.500608	Professional	\N	\N	Healthcare	2029-01-30	\N
8d754039-13d4-4c81-9819-4456eef97cdd	Amish Sheds Direct of Ohio	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	166689887546555	2026-05-23 00:55:27.504323	2026-05-23 00:55:27.504323	Professional	\N	\N	Contractors	2026-10-31	\N
aee3f9a1-8355-4cc1-b2f2-5af9a3948a88	Meriwether & Tharp	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	823338944	2026-05-23 00:55:27.508158	2026-05-23 00:55:27.508158	Professional	\N	\N	Legal	2026-07-26	\N
b0382462-6025-44ea-a136-281e36e173f6	Es Vedra Cinemas	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	175157278806546	2026-05-23 00:55:27.51176	2026-05-23 00:55:27.51176	Professional	\N	\N	Hospitality	2026-08-22	\N
b55338d4-ee18-4df8-bb5d-131dd816a452	NovaSpine Pain Institute	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	170665436658231	2026-05-23 00:55:27.515282	2026-05-23 00:55:27.515282	Professional	\N	\N	Healthcare	2026-10-12	\N
d3624435-4e9b-4c02-84a5-57afaa4882e2	ChuckTown Homes	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	173418880292000	2026-05-23 00:55:27.519442	2026-05-23 00:55:27.519442	Professional	\N	\N	Real Estate	2026-12-31	\N
f6e9ec13-bfe4-4d9a-90ee-186a60f78bdf	FLATS LLC	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	159320818447399	2026-05-23 00:55:27.528113	2026-05-23 00:55:27.528113	Professional	\N	\N	Real Estate	2026-06-30	\N
ea997952-e24c-4364-8113-592e495d9a9a	Brush Dental	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	154032103597409	2026-05-23 00:55:27.532576	2026-05-23 00:55:27.532576	Professional	\N	\N	Dental	2026-10-24	\N
67ad1058-5dbb-4aea-b088-b2526c976982	GECU	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	170550473620593	2026-05-23 00:55:27.536664	2026-05-23 00:55:27.536664	Professional	\N	\N	Finance	2026-09-30	\N
dc5b5c7d-e1fb-4078-9d55-cc09759b2bed	Allied Outdoor Solutions	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	165228119700363	2026-05-23 00:55:27.540998	2026-05-23 00:55:27.540998	Professional	\N	\N	Contractors	2027-05-16	\N
391d2e2d-c973-4b90-b3e9-dea38622b38b	Personify Financial	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	151251032034322	2026-05-23 00:55:27.544781	2026-05-23 00:55:27.544781	Professional	\N	\N	Finance	2027-01-22	\N
7a5eab3b-d9b0-40ca-8855-488a3b1a880b	Gordon Management	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	164866065486030	2026-05-23 00:55:27.548796	2026-05-23 00:55:27.548796	Professional	\N	\N	Real Estate	2027-03-30	\N
a91b4ae6-c269-4404-b8f6-72edf2563ed8	Grass Works Lawn Care	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	166913889541638	2026-05-23 00:55:27.552931	2026-05-23 00:55:27.552931	Professional	\N	\N	Home Services	2026-06-12	\N
430d89b1-5220-4c68-896a-7de088e8b135	Reproductive Medicine Institute	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	162200076906150	2026-05-23 00:55:27.557024	2026-05-23 00:55:27.557024	Professional	\N	\N	Healthcare	2027-01-17	\N
ff4957cb-6eb0-44f2-b065-a93a3414fb6c	Skogman Realty Co	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	164262057065261	2026-05-23 00:55:27.561579	2026-05-23 00:55:27.561579	Professional	\N	\N	Real Estate	2027-02-27	\N
a7f1bfa2-416b-4dfd-a145-7bbaef2292e4	McMahon's Best-One	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	172114401912903	2026-05-23 00:55:27.565516	2026-05-23 00:55:27.565516	Professional	\N	\N	Automotive	2027-12-25	\N
9c1580f0-6ff4-4595-bb70-f921e52ba7e3	Preferred Auto Advantage	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	163770206311315	2026-05-23 00:55:27.573042	2026-05-23 00:55:27.573042	Professional	\N	\N	Automotive	2027-02-14	\N
4eced2ad-d0bc-46ed-b240-857eec87fc12	Summerall Law	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	176176631675288	2026-05-23 00:55:27.577435	2026-05-23 00:55:27.577435	Professional	\N	\N	Legal	2026-10-31	\N
2069a805-ded1-450e-9c3c-576d70e29c07	Hannoush Jewelers	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	159622846005293	2026-05-23 00:55:27.581691	2026-05-23 00:55:27.581691	Professional	\N	\N	Consumer Goods	2027-07-31	\N
94c542ab-e91c-4849-9611-cac1e1929a06	South Texas Eye Institute	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	158352826235946	2026-05-23 00:55:27.586287	2026-05-23 00:55:27.586287	Professional	\N	\N	Healthcare	2026-05-22	\N
e2c2fe7f-e042-41cf-843e-627245f9c802	Family Financial Credit Union	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	173254849057024	2026-05-23 00:55:27.590955	2026-05-23 00:55:27.590955	Professional	\N	\N	Finance	2027-01-23	\N
a1702b0d-2831-4d12-b51f-99688ca90100	PAUL PADDA LAW	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	169023160444872	2026-05-23 00:55:27.594776	2026-05-23 00:55:27.594776	Professional	\N	\N	Legal	2026-07-25	\N
ae301532-2e8d-47ba-907b-96bc13f1ea6e	Bargain Storage	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	157134598160817	2026-05-23 00:55:27.598356	2026-05-23 00:55:27.598356	Professional	\N	\N	Consumer Services	2026-11-29	\N
f7f92ea5-e44f-450c-bc15-f40fda50c250	Quarterdeck	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	172286685971185	2026-05-23 00:55:27.602115	2026-05-23 00:55:27.602115	Professional	\N	\N	Restaurants	2026-08-21	\N
b8df7c9e-343e-4ca1-a030-d5bf2a67b3b8	Smiles 4 Kids: Dentistry for Children	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	173938840057399	2026-05-23 00:55:27.605837	2026-05-23 00:55:27.605837	Professional	\N	\N	Dental	2027-02-27	\N
2f21b615-bc06-425d-8436-75f7881128c0	7 Souls Tattoo & Body Piercing	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	157288350855302	2026-05-23 00:55:27.609313	2026-05-23 00:55:27.609313	Professional	\N	\N	Arts & Entertainment	2029-01-03	\N
45390ba9-09ce-4ad5-8592-0df288e738d1	CornerStone Staffing	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	154179924105463	2026-05-23 00:55:27.613179	2026-05-23 00:55:27.613179	Professional	\N	\N	Business Services	2026-12-17	\N
194262bb-0028-43cd-8b8e-137135cd498c	Wassco Llc	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	175372860205919	2026-05-23 00:55:27.616847	2026-05-23 00:55:27.616847	Professional	\N	\N	Real Estate	2027-08-20	\N
8e69abc9-31fb-4c50-b372-d48c8bf92293	Panache Bridals	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	173637904861290	2026-05-23 00:55:27.620789	2026-05-23 00:55:27.620789	Professional	\N	\N	Retail	2027-01-08	\N
b072b879-e37e-463f-ad14-56ad7cdd0ab1	Refricenter International	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	171863895263395	2026-05-23 00:55:27.624783	2026-05-23 00:55:27.624783	Professional	\N	\N	Contractors	2026-07-18	\N
1f4953a3-2d0a-4134-b178-16b9802aac08	Bartlett Roofing	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	173843034601329	2026-05-23 00:55:27.636055	2026-05-23 00:55:27.636055	Professional	\N	\N	Contractors	2027-04-15	\N
3dc8b221-ad59-4f13-8459-f902d36abc66	Hillcrest Animal Hospital	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	156691818431723	2026-05-23 00:55:27.640543	2026-05-23 00:55:27.640543	Professional	\N	\N	Healthcare	2026-08-30	\N
ee27ca2e-7a11-4e5c-a9b3-9d13644e0540	949 Pediatric Dentistry and Orthodontics	0935a1f0-751b-44d7-992d-26a36294542d	\N	yellow	f	\N	\N	172987875902497	2026-05-23 00:55:27.644592	2026-05-23 00:55:27.644592	Professional	\N	\N	Dental	2026-11-07	\N
f3157f6f-2cab-48d8-bf37-85cd80d3660a	AZ MediQuip	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	165999343880173	2026-05-23 00:55:27.648234	2026-05-23 00:55:27.648234	Professional	\N	\N	Healthcare	2027-08-26	\N
a14b4dda-91e2-4b75-b888-e4d8b0344db0	Restorative Dentistry Group	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	175131483820371	2026-05-23 00:55:27.652056	2026-05-23 00:55:27.652056	Professional	\N	\N	Dental	2026-07-14	\N
ef090b77-1960-4741-a203-a4fef675782b	Alssaro Counseling Services	0935a1f0-751b-44d7-992d-26a36294542d	\N	green	f	\N	\N	164148282215200	2026-05-23 00:55:27.656006	2026-05-23 00:55:27.656006	Professional	\N	\N	Other	2027-01-06	\N
03d04dfd-10f2-44ed-a47c-9f8874370f41	Complete Allied Health Care	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	172293521614387	2026-05-23 00:55:27.660326	2026-05-23 00:55:27.660326	Professional	\N	\N	Wellness	2026-10-31	\N
6e832a11-4883-4378-85ba-db7774f7d4cc	Outdoor Elegance	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	172679442267550	2026-05-23 00:55:27.664288	2026-05-23 00:55:27.664288	Professional	\N	\N	Retail	2026-10-30	\N
a5c431e9-de8f-4bfd-8a7a-2523ae7b4edd	MyClinic Group	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	175280602363362	2026-05-23 00:55:27.667966	2026-05-23 00:55:27.667966	Professional	\N	\N	Healthcare	2026-08-19	\N
d10a07c7-9f37-4390-85a3-fca5008148ba	Kinetic Medicine	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	174243176105551	2026-05-23 00:55:27.672247	2026-05-23 00:55:27.672247	Professional	\N	\N	Healthcare	2027-04-01	\N
5a7bc5ed-dd92-4f2a-a9f9-7b58b36070fa	Jg King Homes	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	174400562040871	2026-05-23 00:55:27.675961	2026-05-23 00:55:27.675961	Professional	\N	\N	Construction	2026-06-29	\N
296b39e7-9952-4bf3-bd4b-16b766a65135	ForHealth	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	168920214302391	2026-05-23 00:55:27.679715	2026-05-23 00:55:27.679715	Professional	\N	\N	Healthcare	2026-08-31	\N
daf9880c-6a41-4d39-8db8-41b44fb483e6	Avenue Dental	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	171745720614186	2026-05-23 00:55:27.683426	2026-05-23 00:55:27.683426	Professional	\N	\N	Dental	2026-09-01	\N
7ea36f2c-bc6d-44fe-ab57-3af9748a07c2	I'm In The Right	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	174547528131711	2026-05-23 00:55:27.69064	2026-05-23 00:55:27.69064	Professional	\N	\N	Transportation Services	2026-06-30	\N
cfc62166-aaaa-40ce-b4dd-a6fe211efa1c	Ready Movers	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	171107277357067	2026-05-23 00:55:27.695384	2026-05-23 00:55:27.695384	Professional	\N	\N	Transportation Services	2026-05-31	\N
cd2345ff-c075-4a88-90ca-f8acd3fc4c1a	Ausloans Finance Group	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	169293664862785	2026-05-23 00:55:27.698786	2026-05-23 00:55:27.698786	Professional	\N	\N	Finance	2026-08-29	\N
0fba32e6-3256-434c-b979-5f2317e82189	The Rent Shop	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	174649826260642	2026-05-23 00:55:27.702154	2026-05-23 00:55:27.702154	Professional	\N	\N	Real Estate	2026-06-01	\N
52683ea5-5845-46e4-84a0-7bfcff71833b	Next Gen	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	174778097706724	2026-05-23 00:55:27.705465	2026-05-23 00:55:27.705465	Professional	\N	\N	Recreation	2026-08-14	\N
423c3eb1-2e66-42b7-8a2c-c79cbb2b1817	Hire Rite Temporary Fence	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	174364533290685	2026-05-23 00:55:27.708837	2026-05-23 00:55:27.708837	Professional	\N	\N	Contractors	2027-04-08	\N
7d0a0514-de6a-474d-9215-09497f323667	Qualitas Australia	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	173439714744241	2026-05-23 00:55:27.71249	2026-05-23 00:55:27.71249	Professional	\N	\N	Healthcare	2027-04-30	\N
c95a0c44-939b-4432-9137-505cbbbed78a	Elite Body Contouring Rosebery	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	165109652888128	2026-05-23 00:55:27.716114	2026-05-23 00:55:27.716114	Professional	\N	\N	Wellness	2026-09-24	\N
f4567256-2c14-46c6-a441-129bc1d21b95	Australia Wide First Aid	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	green	f	\N	\N	175133491892052	2026-05-23 00:55:27.719828	2026-05-23 00:55:27.719828	Professional	\N	\N	Education	2026-12-07	\N
7c8f9ff5-486f-47df-b616-ebb699d4ca6a	BurMac Insurance Solutions	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	173326659172225	2026-05-23 00:55:27.72355	2026-05-23 00:55:27.72355	Professional	\N	\N	Insurance	2027-02-17	\N
3a1499fa-b9a5-47c3-b27b-8ce2d90faa04	Peninsula Foot Clinic	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	173138786172674	2026-05-23 00:55:27.727483	2026-05-23 00:55:27.727483	Professional	\N	\N	Healthcare	2026-11-26	\N
e3061408-2ef0-47d0-a548-ea806c045c33	Locksmith DC Lock and Key	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	166537174065772	2026-05-23 00:55:27.731845	2026-05-23 00:55:27.731845	Professional	\N	\N	Other	2026-10-30	\N
ea2ede3f-7059-4c93-a243-a20df19b4ac5	Melbourne Institute of Plastic Surgery	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	170969668616185	2026-05-23 00:55:27.735768	2026-05-23 00:55:27.735768	Professional	\N	\N	Healthcare	2028-05-09	\N
5eb20e54-3daa-4f53-943a-9376c333f5af	John Hughes Group	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	172073719739681	2026-05-23 00:55:27.739694	2026-05-23 00:55:27.739694	Professional	\N	\N	Automotive	2026-07-28	\N
85342b4e-0b12-4ecb-9781-3102edfdc1ca	The Reject Shop	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	green	f	\N	\N	173429936409279	2026-05-23 00:55:27.743634	2026-05-23 00:55:27.743634	Professional	\N	\N	Retail	2026-12-31	\N
304c465e-16d9-4164-8b70-c5a1abf3eb12	Oasis Dental Studio	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	175644496384384	2026-05-23 00:55:27.747811	2026-05-23 00:55:27.747811	Professional	\N	\N	Dental	2026-11-29	\N
de92cbc1-c59f-4e36-bab1-b3dc81524d5a	Queensland Foot Centres	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	172920192973411	2026-05-23 00:55:27.751965	2026-05-23 00:55:27.751965	Professional	\N	\N	Healthcare	2026-11-06	\N
e17938e2-0b8b-44d8-84f6-c2ef1b10e71e	PRD - Penrith	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	173026582908368	2026-05-23 00:55:27.756213	2026-05-23 00:55:27.756213	Professional	\N	\N	Real Estate	2026-10-14	\N
55f68253-0bd8-41dc-a9ba-7f8aa0ef8eca	M Physio Spring Hill - Musculoskeletal Physiotherapy Australia	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	yellow	f	\N	\N	169404985928440	2026-05-23 00:55:27.760132	2026-05-23 00:55:27.760132	Professional	\N	\N	Wellness	2027-04-08	\N
f457ce65-7e68-4ad6-b48a-2bdc770a4c1a	MOG Orthodontics	1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	\N	red	f	\N	\N	171523774563684	2026-05-23 00:55:27.764033	2026-05-23 00:55:27.764033	Professional	\N	\N	Dental	2028-05-05	\N
c1f2617c-932f-4404-accf-d75cfc5fd438	Montessori Academy	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	green	f	\N	\N	176109095225010	2026-05-23 00:55:27.767969	2026-05-23 00:55:27.767969	Professional	\N	\N	Education	2027-03-12	\N
dd633ee4-3a9b-48f5-b4f3-31be15e2f4af	Anglicare	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	green	f	\N	\N	175876543106883	2026-05-23 00:55:27.773031	2026-05-23 00:55:27.773031	Professional	\N	\N	Wellness	2027-02-15	\N
4409c5bd-b5e2-4a69-b5c5-ab21c03ff590	Baby Bunting	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	green	f	\N	\N	174002385094249	2026-05-23 00:55:27.77707	2026-05-23 00:55:27.77707	Professional	\N	\N	Consumer Goods	2027-04-10	\N
c1468974-5e7b-447b-8d8f-55428f959a5b	Howards Storage World	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	yellow	f	\N	\N	177621821964054	2026-05-23 00:55:27.781286	2026-05-23 00:55:27.781286	Professional	\N	\N	Retail	2028-06-13	\N
fc69e01d-9c7b-47b6-a51a-442c5f689ef6	Next Smile Australia	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	yellow	f	\N	\N	174590562451561	2026-05-23 00:55:27.784644	2026-05-23 00:55:27.784644	Professional	\N	\N	Dental	2028-04-29	\N
dd3c87a8-7acc-4a98-8d30-d4ae93cb7112	Veriu Group	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	green	f	\N	\N	176351071431805	2026-05-23 00:55:27.789111	2026-05-23 00:55:27.789111	Professional	\N	\N	Hospitality	2029-04-28	\N
a67e1f87-7cd5-42f9-bb56-a8807ae25dfa	Metlifecare	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	yellow	f	\N	\N	176362237093165	2026-05-23 00:55:27.79313	2026-05-23 00:55:27.79313	Professional	\N	\N	Wellness	2027-01-27	\N
82824411-4262-4be6-ad99-c38e9dc79a95	Localsearch (GTM Team)	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	yellow	f	\N	\N	176904841128683	2026-05-23 00:55:27.79642	2026-05-23 00:55:27.79642	Professional	\N	\N	Technology	2027-02-17	\N
a68771d3-79f9-4245-971b-095bd9f1c26c	Wicked Campers	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	green	f	\N	\N	172499363449603	2026-05-23 00:55:27.799687	2026-05-23 00:55:27.799687	Professional	\N	\N	Transportation Services	2027-04-14	\N
5407d8a9-d531-4aa4-befa-dd31def243ba	Harcourts Property Centre	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	green	f	\N	\N	170969600096546	2026-05-23 00:55:27.80303	2026-05-23 00:55:27.80303	Professional	\N	\N	Real Estate	2027-02-05	\N
4fe73dfb-b813-45ca-82a8-b348b38b024f	Empower Healthcare	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	green	f	\N	\N	177026410147131	2026-05-23 00:55:27.806257	2026-05-23 00:55:27.806257	Professional	\N	\N	Wellness	2027-02-04	\N
d9dbc0f6-143e-4d0f-ba1a-06d7384489a8	Ray White Upper North Shore	90c81f71-88c3-4b8d-9e3c-473864f9c62b	\N	green	f	\N	\N	173829053898845	2026-05-23 00:55:27.809725	2026-05-23 00:55:27.809725	Professional	\N	\N	Real Estate	2027-03-31	\N
7308b81d-cfb5-4006-a2ba-6827df309483	Southeastern Credit Union	200c8b17-2fd7-4935-84d0-58c5507e0b90	\N	yellow	f	\N	\N	166551765485976	2026-05-23 00:55:27.812818	2026-05-23 00:55:27.812818	Professional	\N	\N	Finance	2027-01-19	\N
7667f7d1-113c-4e04-becb-84990b68c532	Panoramic Doors	200c8b17-2fd7-4935-84d0-58c5507e0b90	\N	yellow	f	\N	\N	176487884003704	2026-05-23 00:55:27.816355	2026-05-23 00:55:27.816355	Professional	\N	\N	Home Services	2026-12-29	\N
d8f5ea4c-2e8a-4775-92e9-b8b2cfaaceac	Pogoda Companies	200c8b17-2fd7-4935-84d0-58c5507e0b90	\N	green	f	\N	\N	164426505890257	2026-05-23 00:55:27.821106	2026-05-23 00:55:27.821106	Professional	\N	\N	Real Estate	2029-03-02	\N
f9dba23a-d9fd-422d-8657-b7f9d45906de	Genesis Counseling Center	200c8b17-2fd7-4935-84d0-58c5507e0b90	\N	green	f	\N	\N	162197904211816	2026-05-23 00:55:27.824705	2026-05-23 00:55:27.824705	Professional	\N	\N	Healthcare	2028-05-28	\N
71ae9c1d-c9f9-4301-8379-f1dec75e3cd7	Waverly Health Center	200c8b17-2fd7-4935-84d0-58c5507e0b90	\N	green	f	\N	\N	167995286444525	2026-05-23 00:55:27.831129	2026-05-23 00:55:27.831129	Professional	\N	\N	Healthcare	2027-11-27	\N
20e61282-bb6d-44d0-a0d4-2bfa5e5001ed	Butler Auto Group	200c8b17-2fd7-4935-84d0-58c5507e0b90	\N	yellow	f	\N	\N	173706057372182	2026-05-23 00:55:27.83465	2026-05-23 00:55:27.83465	Professional	\N	\N	Automotive	2026-06-15	\N
910d8d52-0829-4f7e-bc94-e40f2eb8132a	Murgado Automotive Group	200c8b17-2fd7-4935-84d0-58c5507e0b90	\N	yellow	f	\N	\N	172443882451866	2026-05-23 00:55:27.838211	2026-05-23 00:55:27.838211	Professional	\N	\N	Automotive	2026-07-31	\N
09024bce-d82a-40f0-8009-45d50f7643f0	Hekemian & Co. Inc	200c8b17-2fd7-4935-84d0-58c5507e0b90	\N	yellow	f	\N	\N	170291741654556	2026-05-23 00:55:27.846565	2026-05-23 00:55:27.846565	Professional	\N	\N	Real Estate	2026-09-29	\N
5fce35ca-f9bf-473f-8689-25668f18b040	Sagora Senior Living	200c8b17-2fd7-4935-84d0-58c5507e0b90	\N	yellow	f	\N	\N	165668660369904	2026-05-23 00:55:27.850368	2026-05-23 00:55:27.850368	Professional	\N	\N	Wellness	2026-12-29	\N
73664b09-9b72-40a2-804b-b9dedfbfa051	Churchill Mortgage	200c8b17-2fd7-4935-84d0-58c5507e0b90	\N	yellow	f	\N	\N	173957326075023	2026-05-23 00:55:27.853731	2026-05-23 00:55:27.853731	Professional	\N	\N	Finance	2027-04-28	\N
43b3b75e-4069-4140-95a4-5e1ce29c1c1b	Just Right Lawns - Austin	5cf199b1-896f-43d0-9828-19b208191873	\N	green	f	\N	\N	166551396714681	2026-05-23 00:55:27.857584	2026-05-23 00:55:27.857584	Professional	\N	\N	Contractors	2027-04-07	\N
\.


--
-- Data for Name: feedback; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.feedback (id, client_id, feature_id, sentiment, notes, logged_by, created_at) FROM stdin;
\.


--
-- Data for Name: outreach_batch_enrollments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.outreach_batch_enrollments (batch_id, enrollment_id) FROM stdin;
\.


--
-- Data for Name: outreach_batches; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.outreach_batches (id, client_id, batch_status, sent_at, sent_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, name, email, role, email_verified, image, created_at) FROM stdin;
ed13f6be-692d-4f89-a77d-57d070bdb774	Sasidhar Lingaladinne	sasidhar.lingaladinne@birdeye.com	pm	\N	\N	2026-05-17 19:15:14.811809
b498d3a5-0936-46f2-bdc9-441abeae9aa4	Gunjan Pilania	gunjan.pilania@birdeye.com	pm	\N	\N	2026-05-17 19:15:50.799528
4dd0edc1-54e0-4928-ab9e-658d088f2623	Abhishek Iyer	abhishek.iyer@birdeye.com	pmm	\N	\N	2026-05-17 19:16:35.431441
02a5f706-3275-4670-bc93-1d0f670799ba	Rob Nation	rob@birdeye.com	csm	\N	\N	2026-05-17 19:17:09.414226
ffa96572-267d-44fa-82e1-7518094c77b9	Brad Kremer	brad.kremer@birdeye.com	csm	\N	\N	2026-05-18 22:55:23.090793
98e67dd8-1469-4717-8ebe-c0774f47e58f	Vikram Viswanathan	vikram.viswanathan@birdeye.com	pmm	\N	\N	2026-05-18 23:04:16.004904
aa578ef5-541c-4de1-a69a-827c1ee520f4	Naveen Suravarpu	naveen.suravarpu@birdeye.com	pm	\N	\N	2026-05-18 23:03:42.86598
2b82336a-024b-40c8-b5c9-3b8ce0b7a5bd	Madeline Noonan	madeline.noonan@birdeye.com	csm	\N	\N	2026-05-18 23:17:39.3989
004df477-84b3-4aba-b191-1bde5deb1606	Adam Dorfman	adam.dorfman@birdeye.com	admin	\N	\N	2026-05-17 19:14:55.614525
490b2e13-e9b3-4eb3-ba8e-5d98279a787b	Gabrielle Romyn	gabrielle.romyn@birdeye.com	csm	\N	\N	2026-05-22 21:45:40.253065
123fd323-e46d-41aa-bf09-fc56e932efc2	Jay Gleisberg	jay.gleisberg@birdeye.com	csm	\N	\N	2026-05-22 21:46:36.292379
10c8305a-03b6-4447-9d00-5b37c7106240	Lindsey Garcia	lindsey.garcia@birdeye.com	csm	\N	\N	2026-05-22 21:47:01.369014
03794424-77ef-42aa-b8fb-2d1f6cb17114	Will Ehrhorn	will.ehrhorn@birdeye.com	csm	\N	\N	2026-05-22 22:11:05.135623
566d6af5-e82f-4360-b4a2-76d0b916195c	Tony Roy	tony.roy@birdeye.com	csm	\N	\N	2026-05-22 22:11:40.240608
5cf199b1-896f-43d0-9828-19b208191873	Tanmay Mathur	tanmay.mathur@birdeye.com	csm	\N	\N	2026-05-22 22:12:04.645901
200c8b17-2fd7-4935-84d0-58c5507e0b90	Syed Haider	syed.haider@birdeye.com	csm	\N	\N	2026-05-22 22:12:23.402742
90c81f71-88c3-4b8d-9e3c-473864f9c62b	Swati Sachdeva	swati.sachdeva@birdeye.com	csm	\N	\N	2026-05-22 22:12:36.869069
1f11d3fb-ff2d-4d1d-a178-35a98fac40d4	Sunidhi Sharma	sunidhi.sharma@birdeye.com	csm	\N	\N	2026-05-22 22:12:52.826995
0935a1f0-751b-44d7-992d-26a36294542d	Somdatta Ganguly	somdatta.ganguly@birdeye.com	csm	\N	\N	2026-05-22 22:13:07.885346
015c26cb-d437-4e9f-bbb5-572c02d58736	Siddharth Hellan	siddharth.hellan@birdeye.com	csm	\N	\N	2026-05-22 22:13:28.809139
974ba604-4f28-42ba-b910-bfb553ae6161	Shyam Tulsyan	shyam.tulsyan@birdeye.com	csm	\N	\N	2026-05-22 22:13:43.510061
0cc50f9e-1ce3-4ae8-b9be-501cbdebfb8d	Shunail Jiwani	shunail.jiwani@birdeye.com	csm	\N	\N	2026-05-22 22:14:03.133091
f46a55a3-b5cd-4568-a5b7-d0862d917635	Shivam Gupta	shivam.gupta@birdeye.com	csm	\N	\N	2026-05-22 22:14:20.73369
e68e2148-bff2-4ba0-a8ed-9d843f9786eb	Shashi Kujur	shashi.kujur@birdeye.com	csm	\N	\N	2026-05-22 22:14:38.030849
5abbea6a-ba11-4cf9-a9f3-5795453dec7b	Sharim Atilano	sharim.atilano@birdeye.com	csm	\N	\N	2026-05-22 22:14:56.172427
10ec1e18-cc66-4f4d-bb2c-77ce6d62919e	Sanyam Gandhi	sanyam.gandhi@birdeye.com	csm	\N	\N	2026-05-22 22:15:10.650447
832299ec-81b4-45da-9c61-ab97c69e8d56	Sanjwali Madan	sanjwali.madan@birdeye.com	csm	\N	\N	2026-05-22 22:15:25.200639
acd1c2fa-6a07-4f5c-aca9-a0c666b69940	Samar Talwar	samar.talwar@birdeye.com	csm	\N	\N	2026-05-22 22:15:44.950427
66f072be-a0bf-4328-a45c-1f927fbcfd4e	Sahil Johri	sahil.johri@birdeye.com	csm	\N	\N	2026-05-22 22:15:57.501401
e82a85a3-78cc-4cd5-938d-d7771cbd8246	Sahil Bhatia	sahil.bhatia@birdeye.com	pm	\N	\N	2026-05-22 22:16:12.974743
bcc998fa-c19a-4ab1-b59d-263e7e121d7e	Ryan Martin-Yates	ryan.martinyates@birdeye.com	csm	\N	\N	2026-05-22 22:16:35.810162
46c035c6-6314-45a0-ab81-f7792559300d	Riley Sinclair	riley.sinclair@birdeye.com	csm	\N	\N	2026-05-22 22:16:53.543557
1c36db24-ef04-4f47-a214-2a2b7c7f930d	Rachael Krust	rachael.krust@birdeye.com	csm	\N	\N	2026-05-22 22:17:06.127611
ab7bd637-8552-454f-9dde-2313d8f2f432	Pratibha Wadhwani	pratibha.wadhwani@birdeye.com	csm	\N	\N	2026-05-22 22:17:18.973855
e4dca8e2-d48c-4e6b-9728-39345143876c	Peyton Nelson	peyton.nelson@birdeye.com	csm	\N	\N	2026-05-22 22:17:35.52034
d3fd524d-5854-47ff-aaac-ed9b3066b2b4	Peter Kohl	peter.kohl@birdeye.com	csm	\N	\N	2026-05-22 22:17:49.257621
a6351540-4df1-4717-9266-ef0557a14515	Nupurr Arora	nupurr.arora@birdeye.com	csm	\N	\N	2026-05-22 22:18:01.877375
f39d48be-3a4a-4b3f-aedd-ef9b2b1041a1	Nayana Paul	nayana.paul@birdeye.com	csm	\N	\N	2026-05-22 22:18:14.995801
b70f282a-e8a5-4842-954e-fcd2eca55251	Nayamat Sabharwal	nayamat.sabharwal@birdeye.com	csm	\N	\N	2026-05-22 22:18:30.50297
5bc36182-653f-4252-b939-f24a8b9e50f3	Megha Unnikrishnan	megha.unnikrishnan@birdeye.com	csm	\N	\N	2026-05-22 22:18:46.60124
173b2a24-d088-4ea7-af81-4c82c0c50639	Mariana Flores-Estrada	mariana.floresestrada@birdeye.com	csm	\N	\N	2026-05-22 22:19:01.203018
13c3af04-c401-4c4b-b371-12cb014178e1	Loren Kolb	loren.kolb@birdeye.com	csm	\N	\N	2026-05-22 22:19:28.117968
bbff08b2-dd93-4559-b5b8-4ac3855b6b56	Lora Bruton	lora.bruton@birdeye.com	csm	\N	\N	2026-05-22 22:19:42.391258
3ed58702-5fcb-4742-a9f2-842a09991732	Laguna Edwards	laguna.edwards@birdeye.com	csm	\N	\N	2026-05-22 22:20:07.050184
0e846a2d-095d-45ca-a7a1-e0c21edc78e1	Kayla Nemchik	kayla.nemchik@birdeye.com	csm	\N	\N	2026-05-22 22:20:21.219712
d8a702e3-ce10-4e4e-8c5b-52611e941c21	Karan Malhotra	karan.malhotra@birdeye.com	csm	\N	\N	2026-05-22 22:20:36.807048
40dba9be-69cc-4ec1-9c8e-1c2433d520c1	Jubiline Bavan	jubiline.bavan@birdeye.com	csm	\N	\N	2026-05-22 22:21:01.692997
d016e3fd-343c-45ca-85f0-6b4d8e0935cb	Jordan Polkowitz	jordan.polkowitz@birdeye.com	csm	\N	\N	2026-05-22 22:21:14.778352
018ffd1e-b602-4cb9-911f-210585f78a29	Jenenlo Apon	jenenlo.apon@birdeye.com	csm	\N	\N	2026-05-22 22:21:27.984926
4d90d894-3886-44fc-8cb5-66b5fadeff4b	Jaya Kumari	jaya.kumari@birdeye.com	csm	\N	\N	2026-05-22 22:21:42.01756
0ebe8813-36fc-4628-b799-1a98e73daa82	Jasmine Rathod	jasmine.rathod@birdeye.com	csm	\N	\N	2026-05-22 22:21:59.117559
54ab8b97-6679-4284-ba1b-850ea562722a	Himanshu Sharma	himanshu.sharma@birdeye.com	csm	\N	\N	2026-05-22 22:22:22.206585
c9d3c854-c559-4822-8013-1b42b3618e47	Himani Kashyap	himani.kashyap@birdeye.com	csm	\N	\N	2026-05-22 22:22:42.206983
1bb5bb0b-c655-478b-9f7b-dd692dcb181a	Genise Logston	genise.logston@birdeye.com	csm	\N	\N	2026-05-22 22:23:01.277305
11ddb44f-8c90-4b88-89a3-ccad4c1693d7	Gaurav Mudgal	gaurav.mudgal@birdeye.com	csm	\N	\N	2026-05-22 22:23:13.953261
080fe6ed-33cc-4a27-b352-0835b6747dfb	Evelyn Rogers	evelyn.rogers@birdeye.com	csm	\N	\N	2026-05-22 22:23:33.53232
876973fb-f662-4aca-adc5-c2e8a73af6fc	Divya Sharma	divya.sharma@birdeye.com	csm	\N	\N	2026-05-22 22:23:48.628186
a3ee215f-24e2-49fb-877b-86f3a4e8442f	Danny Munoz	danny.munoz@birdeye.com	csm	\N	\N	2026-05-22 22:24:08.194259
d0b866f0-a6d0-4944-a1d6-3e8e8ce80962	Daniyal Usmani	daniyal.usmani@birdeye.com	csm	\N	\N	2026-05-22 22:24:26.44451
3520009d-e788-4bea-8d6a-245711cbfe42	Danish Khan	danish.khan@birdeye.com	csm	\N	\N	2026-05-22 22:24:41.001292
77458093-f257-44d0-bef6-a22768b5402b	Christian Bechard	christian.bechard@birdeye.com	csm	\N	\N	2026-05-22 22:24:59.380816
b33d6a81-3d2c-401a-9aee-23d82fed6969	Carolyn Nguyen	carolyn.nguyen@birdeye.com	csm	\N	\N	2026-05-22 22:25:14.925515
d0f3d476-5058-45ea-8f4d-fa0a9ebd8697	Caroline Featherstone	caroline.featherstone@birdeye.com	csm	\N	\N	2026-05-22 22:25:25.893014
0a021f40-b2a4-46f7-b7af-d4ef60f59cc7	Britt Hogland	britt.hogland@birdeye.com	csm	\N	\N	2026-05-22 22:25:41.746807
a31b3aa4-8170-469b-97a7-28850de6cdc2	Britny Trahant	britny.trahant@birdeye.com	csm	\N	\N	2026-05-22 22:25:53.53932
8f807f1f-ae3d-452c-87b8-c3b83a6a6a8f	Bhanu Tanwar	bhanu.tanwar@birdeye.com	csm	\N	\N	2026-05-22 22:26:10.423571
1a1f01ea-fb1d-4347-9ee6-667921cd1855	Austin Cantrell	austin.candrell@birdeye.com	csm	\N	\N	2026-05-22 22:26:23.201601
0c27716b-b6f9-4286-a5ce-34e335c06d64	Ashish Roul	ashish.roul@birdeye.com	csm	\N	\N	2026-05-22 22:26:36.402952
eb4c741c-1303-44f8-a9f1-7cbea02ab44e	Aoife O'Rourke	aoife.orourke@birdeye.com	csm	\N	\N	2026-05-22 22:26:49.298536
e0433321-a79d-4393-9bff-0c6700a16aa5	Ankona Chatterjee	ankona.chatterjee@birdeye.com	csm	\N	\N	2026-05-22 22:27:02.638208
99cbad47-c52b-4539-b4fa-dbec732e7cc5	Aniket Amolik	aniket.amolik@birdeye.com	csm	\N	\N	2026-05-22 22:27:17.968939
ba12dc3b-4ae7-4d67-b508-435c13e53c90	Anas Khan	anas.khan@birdeye.com	csm	\N	\N	2026-05-22 22:27:32.699693
c162aac7-5f74-418b-bdd6-048e21c1c4ff	Anamita Baruah	anamita.baruah@birdeye.com	csm	\N	\N	2026-05-22 22:27:45.870319
aba8fa22-0c20-4536-8b58-ba3b41eb3b0c	Aditya Narayan	aditya.narayan@birdeye.com	csm	\N	\N	2026-05-22 22:28:14.17234
367d1e32-6cf1-42ae-8d37-bb29d5a727e4	Adam Hughes	adam.hughes@birdeye.com	csm	\N	\N	2026-05-22 22:28:29.685296
7f094b9b-94c1-453a-a3f4-2504b916b346	Anil Panguluri	anil@birdeye.com	admin	\N	\N	2026-05-23 01:00:15.779627
a9e29554-510e-4b3b-b1be-1210b24102b8	Abhijeet Srivastava	abhijeet.srivastava@birdeye.com	pm	\N	\N	2026-05-23 01:00:52.327134
9b09c2d3-74b2-4c0b-b731-0df264a4ee2e	Dhaivat Mehta	dhaivat.mehta@birdeye.com	pm	\N	\N	2026-05-23 01:01:18.178568
b4bf63dd-0c27-4358-b031-765ee6af8724	Paras Garg	paras.garg@birdeye.com	pm	\N	\N	2026-05-23 01:02:01.615933
677277ae-849c-4897-9e4d-0582feb547fd	Sabari Priyadarshini	sabari.priyadarshini@birdeye.com	pm	\N	\N	2026-05-23 01:02:22.490202
5e5ac52c-e52d-47af-8e7e-b7445846c56b	Sathyajith V	sathyajith.v@birdeye.com	pm	\N	\N	2026-05-23 01:02:47.928861
477d6e66-e6d7-481d-9a67-3e8b8926e0e2	Shubham Sachdeva	shubham.sachdeva@birdeye.com	pm	\N	\N	2026-05-23 01:03:07.205946
f4ede5b2-3d93-4a1c-bf09-7df89d923da4	Kartik Chachra	kartik.chachra@birdeye.com	pm	\N	\N	2026-05-23 01:03:46.948113
20cdd327-d53c-49ab-b90b-85a1ef3230f7	Shivani Deo	shivani.deo@birdeye.com	pm	\N	\N	2026-05-23 01:04:03.695949
bcb8ccdf-899a-42c9-8be1-e8ca40f42f0e	Aakanksha Vats	aakanksha.vats@birdeye.com	pm	\N	\N	2026-05-23 01:05:46.945667
70a02fa6-1cc4-4c0e-8e4f-0e1a9d7eeb7a	Lipsa Goel	lipsa.goel@birdeye.com	pm	\N	\N	2026-05-23 01:06:24.960621
8f276277-0044-4eb1-9c04-7bb5fc4d5416	Suraj Saste	suraj.saste@birdeye.com	pm	\N	\N	2026-05-23 01:06:42.399198
26e4dc90-e28f-472c-a1b9-ee2fde1a2502	Abhisek Chakraborty	abhisek.chakraborty1@birdeye.com	pmm	\N	\N	2026-05-23 01:09:05.877287
f7db9b43-5165-44d0-931c-eebbdf8fb2f4	Manila Rauniyar	manila.rauniyar@birdeye.com	pmm	\N	\N	2026-05-23 01:08:41.759072
19c37e4c-7780-434e-9d25-bcd6ee6dca4b	Harith Venkitakrishnan	harith.venkitakrishnan@birdeye.com	pmm	\N	\N	2026-05-23 01:09:46.702026
cc0b74f2-6c7c-41f1-8942-2a3c5e0b9041	Reshma Rayadurgam	reshma.rayadurgam@birdeye.com	pmm	\N	\N	2026-05-23 01:10:13.634171
c43ca194-6ae5-442e-9b5d-d2663991f14d	Robert Black	robert.black@birdeye.com	ae	\N	\N	2026-05-26 17:26:07.792002
aca999b4-82a6-4379-974b-e141d5383349	Aaron Novak	aaron.novak@birdeye.com	ae	\N	\N	2026-05-26 17:27:13.424977
2376ae2d-ca07-46d1-ae69-176ef70e0cfa	Aditya Chauhan	aditya.chauhan@birdeye.com	ae	\N	\N	2026-05-26 17:27:44.79026
60b207c5-da30-47f3-9a17-a89d7df791b2	Aditya Tripathi	aditya.tripathi@birdeye.com	ae	\N	\N	2026-05-26 17:28:07.505324
9b981f3e-a12d-4e15-9755-32f688bac651	Amber Then	amber.then@birdeye.com	ae	\N	\N	2026-05-26 17:28:26.717852
fbc8626e-342b-4607-9eda-221812c0fc19	Ami Espinal	ami.espinal@birdeye.com	ae	\N	\N	2026-05-26 17:28:52.08062
3ace81d9-0261-4e0b-831b-42c52a8ff52e	April Ngo	april.ngo@birdeye.com	ae	\N	\N	2026-05-26 17:29:07.944424
077180cf-167e-48fe-9d2e-45906228cf9a	Atul Pandey	atul.pandey@birdeye.com	ae	\N	\N	2026-05-26 17:29:32.515182
0bd4e319-d555-4c09-9466-9a6229f105b8	Ayush Gairola	ayush.gairola@birdeye.com	ae	\N	\N	2026-05-26 17:29:57.555704
e962e0bb-8b0e-401e-81c3-9ebd0c598a3c	Ben Stidwill	ben.stidwill@birdeye.com	ae	\N	\N	2026-05-26 17:30:24.213977
b6135a63-5402-45b3-9e03-b6005728b361	Brandon Borden	brandon.borden@birdeye.com	ae	\N	\N	2026-05-26 17:30:38.131717
0e6b8f86-aaf2-4770-adce-a95683d0e7b2	Brian Bulkley	brian.bulkley@birdeye.com	ae	\N	\N	2026-05-26 17:31:05.100265
6c856258-d90c-4be6-afe6-8fb8f0a4e70e	Brian Jeffery	brian.jeffery@birdeye.com	ae	\N	\N	2026-05-26 17:31:21.397335
e762b64d-d801-4497-9edc-96843c1eecee	Britany Schachtner	britany.schachtner@birdeye.com	ae	\N	\N	2026-05-26 17:32:57.809566
506a955b-d8e6-46db-a17e-e2706198c90d	Brittany Olson	brittany.olson@birdeye.com	ae	\N	\N	2026-05-26 17:33:41.375294
b30634d9-565f-4af8-bcf2-2e20abf08053	Chaaht Vasisth	chaaht.vasisth@birdeye.com	ae	\N	\N	2026-05-26 17:34:07.963286
7e14f952-2e98-4308-834b-952982b57735	Chelsea Sullivan	chelsea.sullivan@birdeye.com	ae	\N	\N	2026-05-26 17:34:48.14298
bc47814f-8ee6-4797-bfba-99e726cac35d	Chris Grundell	chris.grundell@birdeye.com	ae	\N	\N	2026-05-26 17:35:02.170479
91df5f23-c418-4bf7-847c-c8ca69305f4f	Cole Wilkins	cole.wilkins@birdeye.com	ae	\N	\N	2026-05-26 17:35:20.361391
68f35251-fbdf-4d8b-b526-4c2eb3af71f1	Dan Godfrey	dan.godfrey@birdeye.com	ae	\N	\N	2026-05-26 17:35:33.750736
710f09e9-9043-454c-90d3-06dd1ecf23a4	Emerson Radabaugh	emerson.radabaugh@birdeye.com	ae	\N	\N	2026-05-26 17:38:17.258298
3cd8f2b9-94d9-4d1e-896f-09b9274f1310	Emmanuel Gabler	emmanuel.gabler@birdeye.com	ae	\N	\N	2026-05-26 17:38:54.984619
6c5e5cb7-46bb-42ea-aa42-846795b8762c	Geno Ricci	geno.ricci@birdeye.com	ae	\N	\N	2026-05-26 17:39:23.154229
61a5c233-7da6-480d-835e-eeb7608a282c	Heather Fink	heather.fink@birdeye.com	ae	\N	\N	2026-05-26 17:39:37.387279
381578d3-4780-41d7-b304-9b69965b476f	Hershika Sobti	hershika.sobti@birdeye.com	ae	\N	\N	2026-05-26 17:39:58.203376
6c75b799-e74d-4b7c-9890-e900cb3a8266	Jaclyn Kilburn	jaclyn.kilburn@birdeye.com	ae	\N	\N	2026-05-26 17:40:18.232374
6fa2dc8c-00d7-4e8b-a903-aa260bd969fa	Jacob Hoard	jacob.hoard@birdeye.com	ae	\N	\N	2026-05-26 17:41:01.581563
6b2160d0-fba4-499f-951d-e9a385a60b28	Janine Elliott	janine.elliott@birdeye.com	ae	\N	\N	2026-05-26 17:41:22.814758
47763d92-d646-48e2-a572-644b138eb044	Jeff Novak	jeff.novak@birdeye.com	ae	\N	\N	2026-05-26 17:41:37.101565
183ef182-4f8a-4855-aba9-acbf5a4fce73	Joe Marchese	joe.marchese@birdeye.com	ae	\N	\N	2026-05-26 17:41:51.10658
64c603c4-1f69-45cf-9008-ed490c9d8070	Jordan Keegan	jordan.keegan@birdeye.com	ae	\N	\N	2026-05-26 17:42:05.890411
b8e7d0d5-a198-4598-af8f-71b9b7687746	Jordan Pinzolo	jordan.pinzolo@birdeye.com	ae	\N	\N	2026-05-26 17:42:26.9538
2ee8c92e-99ca-4a7e-8612-3859a9ffb2e8	Julia Porter	julia.porter@birdeye.com	ae	\N	\N	2026-05-26 17:42:40.724177
e4369c65-7c26-4689-8f51-74939bffd9ab	Kameron Hall	kameron.hall@birdeye.com	ae	\N	\N	2026-05-26 17:45:18.856416
2d6a8d72-22da-4d8a-9436-af8bc1080dee	Karan Sabikhi	karan.sabikhi@birdeye.com	ae	\N	\N	2026-05-26 17:45:35.401767
c1b89313-3093-4231-b7ad-0a0e7daa8c24	Korinna Komarova	korinna.komarova@birdeye.com	ae	\N	\N	2026-05-26 17:46:04.226971
68ab07e9-6eb1-4740-936b-cf00684319a9	Kristen Goen	kristen.goen@birdeye.com	ae	\N	\N	2026-05-26 17:46:22.703915
bb56871e-ac79-4f42-b50c-7698b3bbdd06	Kunal Khanna	kunal.khanna@birdeye.com	ae	\N	\N	2026-05-26 17:46:41.332277
34e78c14-ad28-4740-9587-74440caf5b7a	Kyle Bles	kyle.bles@birdeye.com	ae	\N	\N	2026-05-26 17:48:40.936802
ab175a33-1879-4766-be17-ae3237363103	Lee Ziebarth	lee.ziebarth@birdeye.com	ae	\N	\N	2026-05-26 17:48:54.497253
f22450e8-bc51-4eec-a985-fe19a64f5a8d	Leonard Tau	leonard.tau@birdeye.com	ae	\N	\N	2026-05-26 17:49:17.975148
fe25f878-bc68-4eb4-a787-41fc572d6b6e	Lisette Collins	lisette.collins@birdeye.com	ae	\N	\N	2026-05-26 17:49:35.218493
04b3fdc5-c641-4d13-9bf5-bb0583fa57f3	Mark Scannell	mark.scannell@birdeye.com	ae	\N	\N	2026-05-26 17:49:54.95064
4897786b-c120-44c0-a7e5-996fcfc0c6d6	Mason Bullard	mason.bullard@birdeye.com	ae	\N	\N	2026-05-26 17:50:15.058948
c01dea49-e91e-4336-ac3b-b8dd217759f8	Michael Tarter	michael.tarter@birdeye.com	ae	\N	\N	2026-05-26 17:50:31.143933
c1f3bf06-d639-4859-9df4-b119f8d8399a	Mike McHardy	mike.mchardy@birdeye.com	ae	\N	\N	2026-05-26 17:50:46.807235
2ee0ef8a-2eba-44d5-8ac8-cddbb01d1e27	Mohsin Samnani	mohsin.samnani@birdeye.com	ae	\N	\N	2026-05-26 17:51:12.964068
0e2c3546-7025-4d23-8c87-c57453879fc6	Nathan Griffiths	nathan.griffiths@birdeye.com	ae	\N	\N	2026-05-26 17:51:45.859444
94a44f81-61e2-4604-a1cf-07e9fe0346a4	Nikhil Dudi	nikhil.dudi@birdeye.com	ae	\N	\N	2026-05-26 17:52:01.711395
f0fafa9b-9d9e-48ce-b713-18dc006293c6	Pearse Mulvany	pearse.mulvany@birdeye.com	ae	\N	\N	2026-05-26 17:52:21.573905
99e346b9-1881-4809-8ed7-090e65fe329a	Peter Barrie	peter.barrie@birdeye.com	ae	\N	\N	2026-05-26 17:52:33.73595
d22e0aa2-82ee-41b6-96d8-7ee77779cd6e	Prachi Solanki	prachi.solanki@birdeye.com	ae	\N	\N	2026-05-26 17:52:58.839628
05036928-0d2a-4614-bde9-4a255e03500e	Pratyush Rathi	pratyush.rathi@birdeye.com	ae	\N	\N	2026-05-26 17:53:19.313863
1b8fe2fb-7c65-4e13-884d-17fa01ad0e94	Ridhi Mohan	ridhi.mohan@birdeye.com	ae	\N	\N	2026-05-26 17:53:34.84176
79372871-7450-4e9d-a92f-3038cec90309	Robert Castel	robert.castel@birdeye.com	ae	\N	\N	2026-05-26 17:53:53.140825
1df3c652-b983-4015-a1e9-d6c25b155228	Rohit Sharma	rohit.sharma@birdeye.com	ae	\N	\N	2026-05-26 17:54:12.682165
fdc803f7-07d8-420c-83b1-48b4c2db733b	Sam Good	sam.good@birdeye.com	ae	\N	\N	2026-05-26 17:54:26.000128
f2890e57-8975-496a-aed4-3cc07e6e7819	Scott Sebens	scott.sebens@birdeye.com	ae	\N	\N	2026-05-26 17:54:47.556029
77b2fe27-3e57-4a41-95ff-a65866532cbd	Sherry Arora	sherry.arora@birdeye.com	ae	\N	\N	2026-05-26 17:55:03.454128
2acc476a-1dec-48ef-bb75-5c077d1ebebf	Shiva Reddy	shiva.reddy@birdeye.com	ae	\N	\N	2026-05-26 17:55:22.837739
d0f3455b-00a6-4afc-bcdc-d7344c55798e	Stuart Young	stuart.young@birdeye.com	ae	\N	\N	2026-05-26 17:55:46.843903
0e2eb2bd-79e7-4496-9e33-e196859b68e5	Suhail Farook	suhail.farook@birdeye.com	ae	\N	\N	2026-05-26 17:56:03.094796
55bcab37-1a0c-497f-9553-9f3b26b78e21	Tony Van-Eyk	tony.van-eyk@birdeye.com	ae	\N	\N	2026-05-26 17:57:06.702305
a723015c-7234-492b-ae0f-951f982942f8	Trais Foy	trais.foy@birdeye.com	ae	\N	\N	2026-05-26 17:57:27.916436
c5c497ae-d1ca-41a8-bb36-55ec21cfa79a	Vaibhav Uttam	vaibhav.uttam@birdeye.com	ae	\N	\N	2026-05-26 17:57:50.694146
c92f7f2c-3ccf-4401-bbe6-fd8b90d6ddbb	Virender Bhola	virender.bhola@birdeye.com	ae	\N	\N	2026-05-26 17:58:14.031857
669df3cc-a9d8-4d3d-8b0d-31f09a449664	Vishesh Gupta	vishesh.gupta@birdeye.com	ae	\N	\N	2026-05-26 17:58:39.612831
ab4379d0-c727-4bfe-aeed-29deaac8cb2d	Warren Kay	warren.kay@birdeye.com	ae	\N	\N	2026-05-26 17:58:49.832403
6556863e-6356-41ed-8485-eb3e3a45d829	Zach Watson	zach.watson@birdeye.com	ae	\N	\N	2026-05-26 17:59:06.934412
a1764d10-3a4e-468a-8281-5f16a596c50d	Zoie Page	zoie.page@birdeye.com	ae	\N	\N	2026-05-26 17:59:23.918793
\.


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: beta_enrollments beta_enrollments_client_id_feature_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_enrollments
    ADD CONSTRAINT beta_enrollments_client_id_feature_id_unique UNIQUE (client_id, feature_id);


--
-- Name: beta_enrollments beta_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_enrollments
    ADD CONSTRAINT beta_enrollments_pkey PRIMARY KEY (id);


--
-- Name: beta_features beta_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_features
    ADD CONSTRAINT beta_features_pkey PRIMARY KEY (id);


--
-- Name: clients clients_crm_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_crm_id_unique UNIQUE (crm_id);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (id);


--
-- Name: outreach_batch_enrollments outreach_batch_enrollments_batch_id_enrollment_id_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outreach_batch_enrollments
    ADD CONSTRAINT outreach_batch_enrollments_batch_id_enrollment_id_pk PRIMARY KEY (batch_id, enrollment_id);


--
-- Name: outreach_batches outreach_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outreach_batches
    ADD CONSTRAINT outreach_batches_pkey PRIMARY KEY (id);


--
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: beta_features_slug_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX beta_features_slug_unique ON public.beta_features USING btree (slug);


--
-- Name: audit_logs audit_logs_changed_by_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_changed_by_users_id_fk FOREIGN KEY (changed_by) REFERENCES public.users(id);


--
-- Name: beta_enrollments beta_enrollments_assigned_by_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_enrollments
    ADD CONSTRAINT beta_enrollments_assigned_by_users_id_fk FOREIGN KEY (assigned_by) REFERENCES public.users(id);


--
-- Name: beta_enrollments beta_enrollments_client_id_clients_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_enrollments
    ADD CONSTRAINT beta_enrollments_client_id_clients_id_fk FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: beta_enrollments beta_enrollments_csm_approved_by_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_enrollments
    ADD CONSTRAINT beta_enrollments_csm_approved_by_users_id_fk FOREIGN KEY (csm_approved_by) REFERENCES public.users(id);


--
-- Name: beta_enrollments beta_enrollments_feature_id_beta_features_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_enrollments
    ADD CONSTRAINT beta_enrollments_feature_id_beta_features_id_fk FOREIGN KEY (feature_id) REFERENCES public.beta_features(id);


--
-- Name: beta_features beta_features_owner_pm_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_features
    ADD CONSTRAINT beta_features_owner_pm_users_id_fk FOREIGN KEY (owner_pm) REFERENCES public.users(id);


--
-- Name: beta_features beta_features_owner_pmm_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_features
    ADD CONSTRAINT beta_features_owner_pmm_users_id_fk FOREIGN KEY (owner_pmm) REFERENCES public.users(id);


--
-- Name: clients clients_csm_owner_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_csm_owner_users_id_fk FOREIGN KEY (csm_owner) REFERENCES public.users(id);


--
-- Name: feedback feedback_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: feedback feedback_feature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES public.beta_features(id);


--
-- Name: feedback feedback_logged_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_logged_by_fkey FOREIGN KEY (logged_by) REFERENCES public.users(id);


--
-- Name: outreach_batch_enrollments outreach_batch_enrollments_batch_id_outreach_batches_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outreach_batch_enrollments
    ADD CONSTRAINT outreach_batch_enrollments_batch_id_outreach_batches_id_fk FOREIGN KEY (batch_id) REFERENCES public.outreach_batches(id);


--
-- Name: outreach_batch_enrollments outreach_batch_enrollments_enrollment_id_beta_enrollments_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outreach_batch_enrollments
    ADD CONSTRAINT outreach_batch_enrollments_enrollment_id_beta_enrollments_id_fk FOREIGN KEY (enrollment_id) REFERENCES public.beta_enrollments(id);


--
-- Name: outreach_batches outreach_batches_client_id_clients_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outreach_batches
    ADD CONSTRAINT outreach_batches_client_id_clients_id_fk FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: outreach_batches outreach_batches_sent_by_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outreach_batches
    ADD CONSTRAINT outreach_batches_sent_by_users_id_fk FOREIGN KEY (sent_by) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 8pvh0SYJBkTn8x8beovzgDmRxMmJDGCyVQVujrHNvq4qJYkLwoa95eqhNHLY8JC


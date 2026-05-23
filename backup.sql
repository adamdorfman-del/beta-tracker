--
-- PostgreSQL database dump
--

\restrict Fu9FtUryBYq4lGSfIXd0wVf1BvrTi6awpi0R3aeCy9N63agL66qGMppj5VrUXlq

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
    'Midmarket',
    'Channel',
    'SMB'
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
    'coordinator',
    'admin'
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
    status text[] DEFAULT ARRAY['draft'::text] NOT NULL,
    start_date date NOT NULL,
    closed_at timestamp without time zone,
    close_reason public.close_reason,
    close_notes text,
    ideal_client_criteria text,
    outreach_deadline date NOT NULL,
    cloned_from text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    jira_epic_link text DEFAULT ''::text NOT NULL
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
\.


--
-- Data for Name: beta_enrollments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.beta_enrollments (id, client_id, feature_id, assigned_by, is_overflow, csm_approval_status, csm_approved_by, csm_approved_at, csm_rejection_reason, tester_status, outreach_sent_at, confirmed_at, completed_at, dropped_at, drop_reason, feedback_submitted, created_at, updated_at) FROM stdin;
42e80b83-47fa-40f2-a992-dc228a614187	0442dc39-1a7a-4430-bd50-972236198b8f	d9175740-c9e7-4245-aee5-b21e6bcc6edb	004df477-84b3-4aba-b191-1bde5deb1606	f	pending	\N	\N	\N	nominated	\N	\N	\N	\N	\N	f	2026-05-17 19:58:53.393576	2026-05-17 19:58:53.393576
77625255-d2a1-40ea-b200-6677558f0256	704f3226-4c5d-4269-a746-d5a648fb037a	a9da113e-8d77-4c2e-8aff-a4b1d14b2f42	004df477-84b3-4aba-b191-1bde5deb1606	f	pending	\N	\N	\N	nominated	\N	\N	\N	\N	\N	f	2026-05-18 23:08:21.025665	2026-05-18 23:08:21.025665
84fab1c7-e39e-4947-b3a1-625a1f0a7b22	37aa9a9a-5d84-4cf6-88e3-3f61938f6246	d9175740-c9e7-4245-aee5-b21e6bcc6edb	004df477-84b3-4aba-b191-1bde5deb1606	f	pending	\N	\N	\N	nominated	\N	\N	\N	\N	\N	f	2026-05-19 13:52:49.615077	2026-05-19 13:52:49.615077
\.


--
-- Data for Name: beta_features; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.beta_features (id, name, owner_pm, owner_pmm, target_tester_count, status, start_date, closed_at, close_reason, close_notes, ideal_client_criteria, outreach_deadline, cloned_from, created_at, updated_at, jira_epic_link) FROM stdin;
d9175740-c9e7-4245-aee5-b21e6bcc6edb	Listings Optimization Agent	ed13f6be-692d-4f89-a77d-57d070bdb774	4dd0edc1-54e0-4928-ab9e-658d088f2623	15	{draft}	2026-06-02	\N	\N	\N	Enterprise listings client	2026-06-02	\N	2026-05-17 19:24:57.971937	2026-05-17 19:34:37.767	https://feature-roadmap.replit.app/?issue=BIRD-200688
a9da113e-8d77-4c2e-8aff-a4b1d14b2f42	Search AI Optimization Agent	b498d3a5-0936-46f2-bdc9-441abeae9aa4	4dd0edc1-54e0-4928-ab9e-658d088f2623	15	{draft}	2026-06-02	\N	\N	\N		2026-06-02	\N	2026-05-18 23:02:53.196089	2026-05-18 23:02:53.196089	https://feature-roadmap.replit.app/?issue=BIRD-193248
ac983730-3889-4c1e-89ab-5d66c66ed80c	Myna Agents	aa578ef5-541c-4de1-a69a-827c1ee520f4	98e67dd8-1469-4717-8ebe-c0774f47e58f	15	{draft}	2026-06-02	\N	\N	\N		2026-06-02	\N	2026-05-18 23:07:15.039533	2026-05-18 23:07:15.039533	https://feature-roadmap.replit.app/?issue=BIRD-182123
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.clients (id, name, csm_owner, tier, account_health, outreach_lock, last_outreach_date, notes, crm_id, created_at, updated_at, segment, primary_contact_name, primary_contact_email, vertical, contract_renewal_date, product_subscriptions) FROM stdin;
0442dc39-1a7a-4430-bd50-972236198b8f	Aspen Dental	02a5f706-3275-4670-bc93-1d0f670799ba	\N	green	f	\N	\N	840135232	2026-05-17 19:54:07.258972	2026-05-17 19:54:07.258972	Enterprise	Rachel Bentley	rachel.bentley@teamtag.com	Healthcare	\N	\N
37aa9a9a-5d84-4cf6-88e3-3f61938f6246	Wyndham Hotels & Resorts	ffa96572-267d-44fa-82e1-7518094c77b9	\N	green	f	\N	\N	174474980470341	2026-05-18 22:57:30.037142	2026-05-18 23:00:39.523	Strategic	Michael Mahar	michael.mahar@wyndham.com	Hospitality	\N	\N
704f3226-4c5d-4269-a746-d5a648fb037a	Sutter Health	02a5f706-3275-4670-bc93-1d0f670799ba	\N	green	f	\N	\N	174188733881209	2026-05-18 23:01:14.567053	2026-05-18 23:01:45.533	Strategic	Nolan Perry	nolan.perry@sutterhealth.org	Healthcare	\N	\N
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
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


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

\unrestrict Fu9FtUryBYq4lGSfIXd0wVf1BvrTi6awpi0R3aeCy9N63agL66qGMppj5VrUXlq


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
CREATE TABLE public.audits (
    id character varying(26) NOT NULL,
    createat bigint,
    userid character varying(26),
    action character varying(512),
    extrainfo character varying(1024),
    ipaddress character varying(64),
    sessionid character varying(26)
);
ALTER TABLE public.audits OWNER TO mattermost;
CREATE TABLE public.bots (
    userid character varying(26) NOT NULL,
    description character varying(1024),
    ownerid character varying(190),
    lasticonupdate bigint,
    createat bigint,
    updateat bigint,
    deleteat bigint
);
ALTER TABLE public.bots OWNER TO mattermost;
CREATE TABLE public.channelmemberhistory (
    channelid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    jointime bigint NOT NULL,
    leavetime bigint
);
ALTER TABLE public.channelmemberhistory OWNER TO mattermost;
CREATE TABLE public.channelmembers (
    channelid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    roles character varying(64),
    lastviewedat bigint,
    msgcount bigint,
    mentioncount bigint,
    notifyprops character varying(2000),
    lastupdateat bigint,
    schemeuser boolean,
    schemeadmin boolean,
    schemeguest boolean
);
ALTER TABLE public.channelmembers OWNER TO mattermost;
CREATE TABLE public.channels (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    teamid character varying(26),
    type character varying(1),
    displayname character varying(64),
    name character varying(64),
    header character varying(1024),
    purpose character varying(250),
    lastpostat bigint,
    totalmsgcount bigint,
    extraupdateat bigint,
    creatorid character varying(26),
    schemeid character varying(26),
    groupconstrained boolean
);
ALTER TABLE public.channels OWNER TO mattermost;
CREATE TABLE public.clusterdiscovery (
    id character varying(26) NOT NULL,
    type character varying(64),
    clustername character varying(64),
    hostname character varying(512),
    gossipport integer,
    port integer,
    createat bigint,
    lastpingat bigint
);
ALTER TABLE public.clusterdiscovery OWNER TO mattermost;
CREATE TABLE public.commands (
    id character varying(26) NOT NULL,
    token character varying(26),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    creatorid character varying(26),
    teamid character varying(26),
    trigger character varying(128),
    method character varying(1),
    username character varying(64),
    iconurl character varying(1024),
    autocomplete boolean,
    autocompletedesc character varying(1024),
    autocompletehint character varying(1024),
    displayname character varying(64),
    description character varying(128),
    url character varying(1024)
);
ALTER TABLE public.commands OWNER TO mattermost;
CREATE TABLE public.commandwebhooks (
    id character varying(26) NOT NULL,
    createat bigint,
    commandid character varying(26),
    userid character varying(26),
    channelid character varying(26),
    rootid character varying(26),
    parentid character varying(26),
    usecount integer
);
ALTER TABLE public.commandwebhooks OWNER TO mattermost;
CREATE TABLE public.compliances (
    id character varying(26) NOT NULL,
    createat bigint,
    userid character varying(26),
    status character varying(64),
    count integer,
    "desc" character varying(512),
    type character varying(64),
    startat bigint,
    endat bigint,
    keywords character varying(512),
    emails character varying(1024)
);
ALTER TABLE public.compliances OWNER TO mattermost;
CREATE TABLE public.emoji (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    creatorid character varying(26),
    name character varying(64)
);
ALTER TABLE public.emoji OWNER TO mattermost;
CREATE TABLE public.fileinfo (
    id character varying(26) NOT NULL,
    creatorid character varying(26),
    postid character varying(26),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    path character varying(512),
    thumbnailpath character varying(512),
    previewpath character varying(512),
    name character varying(256),
    extension character varying(64),
    size bigint,
    mimetype character varying(256),
    width integer,
    height integer,
    haspreviewimage boolean
);
ALTER TABLE public.fileinfo OWNER TO mattermost;
CREATE TABLE public.groupchannels (
    groupid character varying(26) NOT NULL,
    autoadd boolean,
    schemeadmin boolean,
    createat bigint,
    deleteat bigint,
    updateat bigint,
    channelid character varying(26) NOT NULL
);
ALTER TABLE public.groupchannels OWNER TO mattermost;
CREATE TABLE public.groupmembers (
    groupid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    createat bigint,
    deleteat bigint
);
ALTER TABLE public.groupmembers OWNER TO mattermost;
CREATE TABLE public.groupteams (
    groupid character varying(26) NOT NULL,
    autoadd boolean,
    schemeadmin boolean,
    createat bigint,
    deleteat bigint,
    updateat bigint,
    teamid character varying(26) NOT NULL
);
ALTER TABLE public.groupteams OWNER TO mattermost;
CREATE TABLE public.incomingwebhooks (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    userid character varying(26),
    channelid character varying(26),
    teamid character varying(26),
    displayname character varying(64),
    description character varying(500),
    username text,
    iconurl text,
    channellocked boolean
);
ALTER TABLE public.incomingwebhooks OWNER TO mattermost;
CREATE TABLE public.jobs (
    id character varying(26) NOT NULL,
    type character varying(32),
    priority bigint,
    createat bigint,
    startat bigint,
    lastactivityat bigint,
    status character varying(32),
    progress bigint,
    data character varying(1024)
);
ALTER TABLE public.jobs OWNER TO mattermost;
CREATE TABLE public.licenses (
    id character varying(26) NOT NULL,
    createat bigint,
    bytes character varying(10000)
);
ALTER TABLE public.licenses OWNER TO mattermost;
CREATE TABLE public.linkmetadata (
    hash bigint NOT NULL,
    url character varying(2048),
    "timestamp" bigint,
    type character varying(16),
    data character varying(4096)
);
ALTER TABLE public.linkmetadata OWNER TO mattermost;
CREATE TABLE public.oauthaccessdata (
    clientid character varying(26),
    userid character varying(26),
    token character varying(26) NOT NULL,
    refreshtoken character varying(26),
    redirecturi character varying(256),
    expiresat bigint,
    scope character varying(128)
);
ALTER TABLE public.oauthaccessdata OWNER TO mattermost;
CREATE TABLE public.oauthapps (
    id character varying(26) NOT NULL,
    creatorid character varying(26),
    createat bigint,
    updateat bigint,
    clientsecret character varying(128),
    name character varying(64),
    description character varying(512),
    iconurl character varying(512),
    callbackurls character varying(1024),
    homepage character varying(256),
    istrusted boolean
);
ALTER TABLE public.oauthapps OWNER TO mattermost;
CREATE TABLE public.oauthauthdata (
    clientid character varying(26),
    userid character varying(26),
    code character varying(128) NOT NULL,
    expiresin integer,
    createat bigint,
    redirecturi character varying(256),
    state character varying(1024),
    scope character varying(128)
);
ALTER TABLE public.oauthauthdata OWNER TO mattermost;
CREATE TABLE public.outgoingwebhooks (
    id character varying(26) NOT NULL,
    token character varying(26),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    creatorid character varying(26),
    channelid character varying(26),
    teamid character varying(26),
    triggerwords character varying(1024),
    triggerwhen integer,
    callbackurls character varying(1024),
    displayname character varying(64),
    description character varying(500),
    contenttype character varying(128),
    username character varying(64),
    iconurl character varying(1024)
);
ALTER TABLE public.outgoingwebhooks OWNER TO mattermost;
CREATE TABLE public.pluginkeyvaluestore (
    pluginid character varying(190) NOT NULL,
    pkey character varying(50) NOT NULL,
    pvalue bytea,
    expireat bigint
);
ALTER TABLE public.pluginkeyvaluestore OWNER TO mattermost;
CREATE TABLE public.posts (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    editat bigint,
    deleteat bigint,
    ispinned boolean,
    userid character varying(26),
    channelid character varying(26),
    rootid character varying(26),
    parentid character varying(26),
    originalid character varying(26),
    message character varying(65535),
    type character varying(26),
    props character varying(8000),
    hashtags character varying(1000),
    filenames character varying(4000),
    fileids character varying(150),
    hasreactions boolean
);
ALTER TABLE public.posts OWNER TO mattermost;
CREATE TABLE public.preferences (
    userid character varying(26) NOT NULL,
    category character varying(32) NOT NULL,
    name character varying(32) NOT NULL,
    value character varying(2000)
);
ALTER TABLE public.preferences OWNER TO mattermost;
CREATE TABLE public.publicchannels (
    id character varying(26) NOT NULL,
    deleteat bigint,
    teamid character varying(26),
    displayname character varying(64),
    name character varying(64),
    header character varying(1024),
    purpose character varying(250)
);
ALTER TABLE public.publicchannels OWNER TO mattermost;
CREATE TABLE public.reactions (
    userid character varying(26) NOT NULL,
    postid character varying(26) NOT NULL,
    emojiname character varying(64) NOT NULL,
    createat bigint
);
ALTER TABLE public.reactions OWNER TO mattermost;
CREATE TABLE public.roles (
    id character varying(26) NOT NULL,
    name character varying(64),
    displayname character varying(128),
    description character varying(1024),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    permissions character varying(4096),
    schememanaged boolean,
    builtin boolean
);
ALTER TABLE public.roles OWNER TO mattermost;
CREATE TABLE public.schemes (
    id character varying(26) NOT NULL,
    name character varying(64),
    displayname character varying(128),
    description character varying(1024),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    scope character varying(32),
    defaultteamadminrole character varying(64),
    defaultteamuserrole character varying(64),
    defaultchanneladminrole character varying(64),
    defaultchanneluserrole character varying(64),
    defaultteamguestrole character varying(64),
    defaultchannelguestrole character varying(64)
);
ALTER TABLE public.schemes OWNER TO mattermost;
CREATE TABLE public.sessions (
    id character varying(26) NOT NULL,
    token character varying(26),
    createat bigint,
    expiresat bigint,
    lastactivityat bigint,
    userid character varying(26),
    deviceid character varying(512),
    roles character varying(64),
    isoauth boolean,
    expirednotify boolean,
    props character varying(1000)
);
ALTER TABLE public.sessions OWNER TO mattermost;
CREATE TABLE public.sidebarcategories (
    id character varying(26) NOT NULL,
    userid character varying(26),
    teamid character varying(26),
    sortorder bigint,
    sorting character varying(64),
    type character varying(64),
    displayname character varying(64)
);
ALTER TABLE public.sidebarcategories OWNER TO mattermost;
CREATE TABLE public.sidebarchannels (
    channelid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    categoryid character varying(26) NOT NULL,
    sortorder bigint
);
ALTER TABLE public.sidebarchannels OWNER TO mattermost;
CREATE TABLE public.status (
    userid character varying(26) NOT NULL,
    status character varying(32),
    manual boolean,
    lastactivityat bigint
);
ALTER TABLE public.status OWNER TO mattermost;
CREATE TABLE public.systems (
    name character varying(64) NOT NULL,
    value character varying(1024)
);
ALTER TABLE public.systems OWNER TO mattermost;
CREATE TABLE public.teammembers (
    teamid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    roles character varying(64),
    deleteat bigint,
    schemeuser boolean,
    schemeadmin boolean,
    schemeguest boolean
);
ALTER TABLE public.teammembers OWNER TO mattermost;
CREATE TABLE public.teams (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    displayname character varying(64),
    name character varying(64),
    description character varying(255),
    email character varying(128),
    type text,
    companyname character varying(64),
    alloweddomains character varying(1000),
    inviteid character varying(32),
    allowopeninvite boolean,
    lastteamiconupdate bigint,
    schemeid text,
    groupconstrained boolean
);
ALTER TABLE public.teams OWNER TO mattermost;
CREATE TABLE public.termsofservice (
    id character varying(26) NOT NULL,
    createat bigint,
    userid character varying(26),
    text character varying(65535)
);
ALTER TABLE public.termsofservice OWNER TO mattermost;
CREATE TABLE public.tokens (
    token character varying(64) NOT NULL,
    createat bigint,
    type character varying(64),
    extra character varying(2048)
);
ALTER TABLE public.tokens OWNER TO mattermost;
CREATE TABLE public.useraccesstokens (
    id character varying(26) NOT NULL,
    token character varying(26),
    userid character varying(26),
    description character varying(512),
    isactive boolean
);
ALTER TABLE public.useraccesstokens OWNER TO mattermost;
CREATE TABLE public.usergroups (
    id character varying(26) NOT NULL,
    name character varying(64),
    displayname character varying(128),
    description character varying(1024),
    source character varying(64),
    remoteid character varying(48),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    allowreference boolean
);
ALTER TABLE public.usergroups OWNER TO mattermost;
CREATE TABLE public.users (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    username character varying(64),
    password character varying(128),
    authdata character varying(128),
    authservice character varying(32),
    email character varying(128),
    emailverified boolean,
    nickname character varying(64),
    firstname character varying(64),
    lastname character varying(64),
    "position" character varying(128),
    roles character varying(256),
    allowmarketing boolean,
    props character varying(4000),
    notifyprops character varying(2000),
    lastpasswordupdate bigint,
    lastpictureupdate bigint,
    failedattempts integer,
    locale character varying(5),
    timezone character varying(256),
    mfaactive boolean,
    mfasecret character varying(128)
);
ALTER TABLE public.users OWNER TO mattermost;
CREATE TABLE public.usertermsofservice (
    userid character varying(26) NOT NULL,
    termsofserviceid character varying(26),
    createat bigint
);
ALTER TABLE public.usertermsofservice OWNER TO mattermost;
COPY public.audits (id, createat, userid, action, extrainfo, ipaddress, sessionid) FROM stdin;
\.
COPY public.bots (userid, description, ownerid, lasticonupdate, createat, updateat, deleteat) FROM stdin;
\.
COPY public.channelmemberhistory (channelid, userid, jointime, leavetime) FROM stdin;
cxtmz3ubz3gfigd5m6prendmsw	bmq7jiumpib3xdz3mx5iyo99ro	1598351847734	\N
73uy6kj1jb8wdqrf3ti6zies6r	bmq7jiumpib3xdz3mx5iyo99ro	1598351847751	\N
cxtmz3ubz3gfigd5m6prendmsw	5bw66y36bff3umq1q57mfy4y5c	1598351852028	\N
73uy6kj1jb8wdqrf3ti6zies6r	5bw66y36bff3umq1q57mfy4y5c	1598351852045	\N
cxtmz3ubz3gfigd5m6prendmsw	3zats68fztgu9mgu944a4t35so	1598351852028	\N
73uy6kj1jb8wdqrf3ti6zies6r	3zats68fztgu9mgu944a4t35so	1598351852045	\N
cxtmz3ubz3gfigd5m6prendmsw	0z4okgmv5lfhx3p0tf6pnpk8sk	1598351852028	\N
73uy6kj1jb8wdqrf3ti6zies6r	0z4okgmv5lfhx3p0tf6pnpk8sk	1598351852045	\N
\.
COPY public.channelmembers (channelid, userid, roles, lastviewedat, msgcount, mentioncount, notifyprops, lastupdateat, schemeuser, schemeadmin, schemeguest) FROM stdin;
cxtmz3ubz3gfigd5m6prendmsw	bmq7jiumpib3xdz3mx5iyo99ro		0	0	0	{"desktop":"default","email":"default","ignore_channel_mentions":"default","mark_unread":"all","push":"default"}	1598351847724	t	f	f
73uy6kj1jb8wdqrf3ti6zies6r	bmq7jiumpib3xdz3mx5iyo99ro		0	0	0	{"desktop":"default","email":"default","ignore_channel_mentions":"default","mark_unread":"all","push":"default"}	1598351847747	t	f	f
cxtmz3ubz3gfigd5m6prendmsw	5bw66y36bff3umq1q57mfy4y5c		0	0	0	{"desktop":"default","email":"default","ignore_channel_mentions":"default","mark_unread":"all","push":"default"}	1598351852017	t	f	f
73uy6kj1jb8wdqrf3ti6zies6r	5bw66y36bff3umq1q57mfy4y5c		0	0	0	{"desktop":"default","email":"default","ignore_channel_mentions":"default","mark_unread":"all","push":"default"}	1598351852041	t	f	f
cxtmz3ubz3gfigd5m6prendmsw	0z4okgmv5lfhx3p0tf6pnpk8sk		0	0	0	{"desktop":"default","email":"default","ignore_channel_mentions":"default","mark_unread":"all","push":"default"}	1598351852017	t	f	f
73uy6kj1jb8wdqrf3ti6zies6r	0z4okgmv5lfhx3p0tf6pnpk8sk		0	0	0	{"desktop":"default","email":"default","ignore_channel_mentions":"default","mark_unread":"all","push":"default"}	1598351852041	t	f	f
cxtmz3ubz3gfigd5m6prendmsw	3zats68fztgu9mgu944a4t35so		0	0	0	{"desktop":"default","email":"default","ignore_channel_mentions":"default","mark_unread":"all","push":"default"}	1598351852017	t	f	f
73uy6kj1jb8wdqrf3ti6zies6r	3zats68fztgu9mgu944a4t35so		0	0	0	{"desktop":"default","email":"default","ignore_channel_mentions":"default","mark_unread":"all","push":"default"}	1598351852041	t	f	f
\.
COPY public.channels (id, createat, updateat, deleteat, teamid, type, displayname, name, header, purpose, lastpostat, totalmsgcount, extraupdateat, creatorid, schemeid, groupconstrained) FROM stdin;
cxtmz3ubz3gfigd5m6prendmsw	1598351837713	1598351837713	0	tgrw7sjgbiy1jggs3qg3m6zpee	O	Town Square	town-square			1598351852030	0	0		\N	\N
73uy6kj1jb8wdqrf3ti6zies6r	1598351837717	1598351837717	0	tgrw7sjgbiy1jggs3qg3m6zpee	O	Off-Topic	off-topic			1598351852046	0	0		\N	\N
\.
COPY public.clusterdiscovery (id, type, clustername, hostname, gossipport, port, createat, lastpingat) FROM stdin;
\.
COPY public.commands (id, token, createat, updateat, deleteat, creatorid, teamid, trigger, method, username, iconurl, autocomplete, autocompletedesc, autocompletehint, displayname, description, url) FROM stdin;
\.
COPY public.commandwebhooks (id, createat, commandid, userid, channelid, rootid, parentid, usecount) FROM stdin;
\.
COPY public.compliances (id, createat, userid, status, count, "desc", type, startat, endat, keywords, emails) FROM stdin;
\.
COPY public.emoji (id, createat, updateat, deleteat, creatorid, name) FROM stdin;
\.
COPY public.fileinfo (id, creatorid, postid, createat, updateat, deleteat, path, thumbnailpath, previewpath, name, extension, size, mimetype, width, height, haspreviewimage) FROM stdin;
\.
COPY public.groupchannels (groupid, autoadd, schemeadmin, createat, deleteat, updateat, channelid) FROM stdin;
\.
COPY public.groupmembers (groupid, userid, createat, deleteat) FROM stdin;
\.
COPY public.groupteams (groupid, autoadd, schemeadmin, createat, deleteat, updateat, teamid) FROM stdin;
\.
COPY public.incomingwebhooks (id, createat, updateat, deleteat, userid, channelid, teamid, displayname, description, username, iconurl, channellocked) FROM stdin;
\.
COPY public.jobs (id, type, priority, createat, startat, lastactivityat, status, progress, data) FROM stdin;
fky8msypr7nhbko6jm1fydozow	migrations	0	1598351829123	1598351839894	1598351840103	success	0	{"last_done":"{\\"current_table\\":\\"ChannelMembers\\",\\"last_team_id\\":\\"00000000000000000000000000\\",\\"last_channel_id\\":\\"00000000000000000000000000\\",\\"last_user\\":\\"00000000000000000000000000\\"}","migration_key":"migration_advanced_permissions_phase_2"}
\.
COPY public.licenses (id, createat, bytes) FROM stdin;
\.
COPY public.linkmetadata (hash, url, "timestamp", type, data) FROM stdin;
\.
COPY public.oauthaccessdata (clientid, userid, token, refreshtoken, redirecturi, expiresat, scope) FROM stdin;
\.
COPY public.oauthapps (id, creatorid, createat, updateat, clientsecret, name, description, iconurl, callbackurls, homepage, istrusted) FROM stdin;
\.
COPY public.oauthauthdata (clientid, userid, code, expiresin, createat, redirecturi, state, scope) FROM stdin;
\.
COPY public.outgoingwebhooks (id, token, createat, updateat, deleteat, creatorid, channelid, teamid, triggerwords, triggerwhen, callbackurls, displayname, description, contenttype, username, iconurl) FROM stdin;
\.
COPY public.pluginkeyvaluestore (pluginid, pkey, pvalue, expireat) FROM stdin;
\.
COPY public.posts (id, createat, updateat, editat, deleteat, ispinned, userid, channelid, rootid, parentid, originalid, message, type, props, hashtags, filenames, fileids, hasreactions) FROM stdin;
\.
COPY public.preferences (userid, category, name, value) FROM stdin;
bmq7jiumpib3xdz3mx5iyo99ro	tutorial_step	bmq7jiumpib3xdz3mx5iyo99ro	0
5bw66y36bff3umq1q57mfy4y5c	tutorial_step	5bw66y36bff3umq1q57mfy4y5c	0
0z4okgmv5lfhx3p0tf6pnpk8sk	tutorial_step	0z4okgmv5lfhx3p0tf6pnpk8sk	0
3zats68fztgu9mgu944a4t35so	tutorial_step	3zats68fztgu9mgu944a4t35so	0
\.
COPY public.publicchannels (id, deleteat, teamid, displayname, name, header, purpose) FROM stdin;
cxtmz3ubz3gfigd5m6prendmsw	0	tgrw7sjgbiy1jggs3qg3m6zpee	Town Square	town-square		
73uy6kj1jb8wdqrf3ti6zies6r	0	tgrw7sjgbiy1jggs3qg3m6zpee	Off-Topic	off-topic		
\.
COPY public.reactions (userid, postid, emojiname, createat) FROM stdin;
\.
COPY public.roles (id, name, displayname, description, createat, updateat, deleteat, permissions, schememanaged, builtin) FROM stdin;
cqedmkhfmtfhidp18w8pkogtpa	team_post_all	authentication.roles.team_post_all.name	authentication.roles.team_post_all.description	1598351767777	1598351767984	0	 use_channel_mentions create_post use_group_mentions	f	t
jdfscmmwq7yc9pb3j8egpkrhgo	team_admin	authentication.roles.team_admin.name	authentication.roles.team_admin.description	1598351767783	1598351767985	0	 delete_post manage_private_channel_members create_post manage_channel_roles manage_outgoing_webhooks manage_others_outgoing_webhooks use_channel_mentions manage_team_roles delete_others_posts manage_slash_commands use_group_mentions remove_user_from_team add_reaction manage_others_slash_commands manage_others_incoming_webhooks remove_reaction import_team manage_public_channel_members manage_incoming_webhooks manage_team	t	t
qj5hbu454fn63njq69nni3drxh	system_post_all	authentication.roles.system_post_all.name	authentication.roles.system_post_all.description	1598351767778	1598351767986	0	 create_post use_channel_mentions use_group_mentions	f	t
abmhgi8pa3robkzd7kfzongfmc	system_guest	authentication.roles.global_guest.name	authentication.roles.global_guest.description	1598351767761	1598351767987	0	 create_direct_channel create_group_channel	t	t
3sojxu7t47r95cfjs94yywyd9c	system_post_all_public	authentication.roles.system_post_all_public.name	authentication.roles.system_post_all_public.description	1598351767764	1598351767988	0	 create_post_public use_channel_mentions use_group_mentions	f	t
xqc3eckiafg5i86jthcwbazdpy	team_user	authentication.roles.team_user.name	authentication.roles.team_user.description	1598351767784	1598351767979	0	 create_private_channel invite_user add_user_to_team list_team_channels join_public_channels read_public_channel view_team create_public_channel	t	t
go6yxappktb93quowz9j6mkjra	team_post_all_public	authentication.roles.team_post_all_public.name	authentication.roles.team_post_all_public.description	1598351767786	1598351767981	0	 create_post_public use_group_mentions use_channel_mentions	f	t
getwmro16pd7jrn1oqrkmn1wsw	system_user	authentication.roles.global_user.name	authentication.roles.global_user.description	1598351767781	1598351767981	0	 create_emojis delete_emojis list_public_teams join_public_teams create_direct_channel create_group_channel view_members create_team	t	t
ghsp7z49qbbi5bhuoqaqqs6ake	channel_admin	authentication.roles.channel_admin.name	authentication.roles.channel_admin.description	1598351767766	1598351767982	0	 manage_private_channel_members use_channel_mentions manage_channel_roles use_group_mentions create_post add_reaction remove_reaction manage_public_channel_members	t	t
t6x4ph1uojb398ciuhkgqzexfw	channel_user	authentication.roles.channel_user.name	authentication.roles.channel_user.description	1598351767775	1598351767983	0	 use_channel_mentions add_reaction manage_private_channel_properties manage_private_channel_members manage_public_channel_members manage_public_channel_properties edit_post delete_private_channel use_group_mentions create_post read_channel delete_public_channel remove_reaction upload_file use_slash_commands get_public_link delete_post	t	t
gygr3fd64p8izpynu6uef8jq3r	channel_guest	authentication.roles.channel_guest.name	authentication.roles.channel_guest.description	1598351767780	1598351767988	0	 remove_reaction upload_file edit_post create_post use_channel_mentions use_slash_commands read_channel add_reaction	t	t
jgrdf15eifyu5gsrum87u8ka5y	team_guest	authentication.roles.team_guest.name	authentication.roles.team_guest.description	1598351767768	1598351767989	0	 view_team	t	t
sw8erru9jjyzfegokosh9sb15h	system_user_access_token	authentication.roles.system_user_access_token.name	authentication.roles.system_user_access_token.description	1598351767769	1598351767990	0	 create_user_access_token read_user_access_token revoke_user_access_token	f	t
nypn4aniofbf9eu4efqkb1n56y	system_admin	authentication.roles.global_admin.name	authentication.roles.global_admin.description	1598351767771	1598351767991	0	 manage_channel_roles read_public_channel read_user_access_token invite_guest manage_oauth add_reaction manage_bots manage_slash_commands assign_system_admin_role create_post list_users_without_team list_private_teams invite_user delete_post create_emojis add_user_to_team manage_public_channel_members manage_outgoing_webhooks manage_others_slash_commands list_team_channels remove_reaction delete_public_channel read_channel remove_others_reactions delete_emojis remove_user_from_team create_private_channel manage_others_incoming_webhooks create_team edit_post manage_private_channel_members manage_jobs delete_others_posts manage_team_roles create_bot manage_private_channel_properties read_others_bots manage_system_wide_oauth create_public_channel join_public_channels use_slash_commands view_team join_private_teams edit_others_posts manage_others_bots create_post_public read_bots edit_other_users manage_system delete_others_emojis use_group_mentions create_user_access_token manage_public_channel_properties manage_roles promote_guest use_channel_mentions revoke_user_access_token manage_team manage_others_outgoing_webhooks manage_incoming_webhooks get_public_link import_team upload_file view_members delete_private_channel create_post_ephemeral demote_to_guest	t	t
\.
COPY public.schemes (id, name, displayname, description, createat, updateat, deleteat, scope, defaultteamadminrole, defaultteamuserrole, defaultchanneladminrole, defaultchanneluserrole, defaultteamguestrole, defaultchannelguestrole) FROM stdin;
\.
COPY public.sessions (id, token, createat, expiresat, lastactivityat, userid, deviceid, roles, isoauth, expirednotify, props) FROM stdin;
\.
COPY public.sidebarcategories (id, userid, teamid, sortorder, sorting, type, displayname) FROM stdin;
\.
COPY public.sidebarchannels (channelid, userid, categoryid, sortorder) FROM stdin;
\.
COPY public.status (userid, status, manual, lastactivityat) FROM stdin;
\.
COPY public.systems (name, value) FROM stdin;
Version	5.26.0
AsymmetricSigningKey	{"ecdsa_key":{"curve":"P-256","x":44744317388117417793846363992112375138072215766669538838312050574980773534963,"y":106405437094541760691235144597932623735695328716199872932991841706298639959202,"d":514093591070089100882487378727490579260295328943479296300452065637146698099}}
PostActionCookieSecret	{"key":"8cXKorYdh+LUSyAJcMpXp26vIV/vu8B5vq2noKPLGi4="}
InstallationDate	1598351748409
FirstServerRunTimestamp	1598351748411
DiagnosticId	igz85apxkfn5xcd1ioi8dmbnsa
AdvancedPermissionsMigrationComplete	true
EmojisPermissionsMigrationComplete	true
GuestRolesCreationMigrationComplete	true
emoji_permissions_split	true
webhook_permissions_split	true
list_join_public_private_teams	true
remove_permanent_delete_user	true
add_bot_permissions	true
apply_channel_manage_delete_to_channel_user	true
remove_channel_manage_delete_from_team_user	true
view_members_new_permission	true
add_manage_guests_permissions	true
channel_moderations_permissions	true
add_use_group_mentions_permission	true
LastSecurityTime	1598351769090
migration_advanced_permissions_phase_2	true
\.
COPY public.teammembers (teamid, userid, roles, deleteat, schemeuser, schemeadmin, schemeguest) FROM stdin;
tgrw7sjgbiy1jggs3qg3m6zpee	bmq7jiumpib3xdz3mx5iyo99ro		0	t	t	f
tgrw7sjgbiy1jggs3qg3m6zpee	5bw66y36bff3umq1q57mfy4y5c		0	t	f	f
tgrw7sjgbiy1jggs3qg3m6zpee	0z4okgmv5lfhx3p0tf6pnpk8sk		0	t	f	f
tgrw7sjgbiy1jggs3qg3m6zpee	3zats68fztgu9mgu944a4t35so		0	t	f	f
\.
COPY public.teams (id, createat, updateat, deleteat, displayname, name, description, email, type, companyname, alloweddomains, inviteid, allowopeninvite, lastteamiconupdate, schemeid, groupconstrained) FROM stdin;
tgrw7sjgbiy1jggs3qg3m6zpee	1598351837711	1598351837711	0	Test Team	test			O			5tdc6sxr43byufri3r6px9f9xo	f	0	\N	\N
\.
COPY public.termsofservice (id, createat, userid, text) FROM stdin;
\.
COPY public.tokens (token, createat, type, extra) FROM stdin;
\.
COPY public.useraccesstokens (id, token, userid, description, isactive) FROM stdin;
98yjyceocfb5mc3jaibtbmr1ph	s537n3t8zib1tx7eyd44qzqnbr	bmq7jiumpib3xdz3mx5iyo99ro	test-token	t
ya4wtr9fjiyxfptgnjmjgcc3wh	aqhn1jc1nbgjtpd7es83wckner	5bw66y36bff3umq1q57mfy4y5c	test-token	t
fpvzz1p2d2sgmhzrmfrhg3kami	qhkzgz0ruottpmoooxiudgvtis	0z4okgmv5lfhx3p0tf6pnpk8sk	test-token	t
e3dnfu1g17fjtxq53odawh6e7y	ox8n8edimjdbfkeybdf56pj4xw	3zats68fztgu9mgu944a4t35so	test-token	t
\.
COPY public.usergroups (id, name, displayname, description, source, remoteid, createat, updateat, deleteat, allowreference) FROM stdin;
\.
COPY public.users (id, createat, updateat, deleteat, username, password, authdata, authservice, email, emailverified, nickname, firstname, lastname, "position", roles, allowmarketing, props, notifyprops, lastpasswordupdate, lastpictureupdate, failedattempts, locale, timezone, mfaactive, mfasecret) FROM stdin;
3zats68fztgu9mgu944a4t35so	1598351812493	1598351812493	0	mattermost_b	$2a$10$bV5EvQPt9.p4jTO4VVM4Te2J7B7/IJhstPLhxVltLtufn7F97Q3nO	\N		mattermost_b@localhost	f					system_user	f	{}	{"channel":"true","comments":"never","desktop":"mention","desktop_sound":"true","email":"true","first_name":"false","mention_keys":"","push":"mention","push_status":"away"}	1598351812493	0	0	en	{"automaticTimezone":"","manualTimezone":"","useAutomaticTimezone":"true"}	f	
bmq7jiumpib3xdz3mx5iyo99ro	1598351769026	1598351847718	0	admin	$2a$10$08I/69Phynm.yDfERKNPV.cYRXSC1.hjb7/2upwafY0GvRjs9iri.	\N		admin@localhost	f		Admin	User		system_admin system_user	f	{}	{"channel":"true","comments":"never","desktop":"mention","desktop_sound":"true","email":"true","first_name":"false","mention_keys":"","push":"mention","push_status":"away"}	1598351769026	0	0	en	{"automaticTimezone":"","manualTimezone":"","useAutomaticTimezone":"true"}	f	
5bw66y36bff3umq1q57mfy4y5c	1598351800458	1598352057088	0	mattermost_a	$2a$10$WdovEVVvy9ZS867UE2hSq.7hV38Lg9H2ozgaF3gwuO6fuoCkkTzIu	\N		mattermost_a@localhost	f		MattermostUser	A		system_user	f	{}	{"channel":"true","comments":"never","desktop":"mention","desktop_sound":"true","email":"true","first_name":"false","mention_keys":"","push":"mention","push_status":"away"}	1598352057088	0	0	en	{"automaticTimezone":"","manualTimezone":"","useAutomaticTimezone":"true"}	f	
0z4okgmv5lfhx3p0tf6pnpk8sk	1598351800458	1598352057088	0	ignored_user	$2a$10$WdovEVVvy9ZS867UE2hSq.7hV38Lg9H2ozgaF3gwuO6fuoCkkTzIu	\N		ignored_user@localhost	f					system_user	f	{}	{"channel":"true","comments":"never","desktop":"mention","desktop_sound":"true","email":"true","first_name":"false","mention_keys":"","push":"mention","push_status":"away"}	1598352057088	0	0	en	{"automaticTimezone":"","manualTimezone":"","useAutomaticTimezone":"true"}	f	
\.
COPY public.usertermsofservice (userid, termsofserviceid, createat) FROM stdin;
\.
ALTER TABLE ONLY public.audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.bots
    ADD CONSTRAINT bots_pkey PRIMARY KEY (userid);
ALTER TABLE ONLY public.channelmemberhistory
    ADD CONSTRAINT channelmemberhistory_pkey PRIMARY KEY (channelid, userid, jointime);
ALTER TABLE ONLY public.channelmembers
    ADD CONSTRAINT channelmembers_pkey PRIMARY KEY (channelid, userid);
ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_name_teamid_key UNIQUE (name, teamid);
ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.clusterdiscovery
    ADD CONSTRAINT clusterdiscovery_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.commands
    ADD CONSTRAINT commands_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.commandwebhooks
    ADD CONSTRAINT commandwebhooks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.compliances
    ADD CONSTRAINT compliances_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.emoji
    ADD CONSTRAINT emoji_name_deleteat_key UNIQUE (name, deleteat);
ALTER TABLE ONLY public.emoji
    ADD CONSTRAINT emoji_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.fileinfo
    ADD CONSTRAINT fileinfo_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.groupchannels
    ADD CONSTRAINT groupchannels_pkey PRIMARY KEY (groupid, channelid);
ALTER TABLE ONLY public.groupmembers
    ADD CONSTRAINT groupmembers_pkey PRIMARY KEY (groupid, userid);
ALTER TABLE ONLY public.groupteams
    ADD CONSTRAINT groupteams_pkey PRIMARY KEY (groupid, teamid);
ALTER TABLE ONLY public.incomingwebhooks
    ADD CONSTRAINT incomingwebhooks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.licenses
    ADD CONSTRAINT licenses_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.linkmetadata
    ADD CONSTRAINT linkmetadata_pkey PRIMARY KEY (hash);
ALTER TABLE ONLY public.oauthaccessdata
    ADD CONSTRAINT oauthaccessdata_clientid_userid_key UNIQUE (clientid, userid);
ALTER TABLE ONLY public.oauthaccessdata
    ADD CONSTRAINT oauthaccessdata_pkey PRIMARY KEY (token);
ALTER TABLE ONLY public.oauthapps
    ADD CONSTRAINT oauthapps_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.oauthauthdata
    ADD CONSTRAINT oauthauthdata_pkey PRIMARY KEY (code);
ALTER TABLE ONLY public.outgoingwebhooks
    ADD CONSTRAINT outgoingwebhooks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pluginkeyvaluestore
    ADD CONSTRAINT pluginkeyvaluestore_pkey PRIMARY KEY (pluginid, pkey);
ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.preferences
    ADD CONSTRAINT preferences_pkey PRIMARY KEY (userid, category, name);
ALTER TABLE ONLY public.publicchannels
    ADD CONSTRAINT publicchannels_name_teamid_key UNIQUE (name, teamid);
ALTER TABLE ONLY public.publicchannels
    ADD CONSTRAINT publicchannels_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT reactions_pkey PRIMARY KEY (postid, userid, emojiname);
ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);
ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.schemes
    ADD CONSTRAINT schemes_name_key UNIQUE (name);
ALTER TABLE ONLY public.schemes
    ADD CONSTRAINT schemes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.sidebarcategories
    ADD CONSTRAINT sidebarcategories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.sidebarchannels
    ADD CONSTRAINT sidebarchannels_pkey PRIMARY KEY (channelid, userid, categoryid);
ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (userid);
ALTER TABLE ONLY public.systems
    ADD CONSTRAINT systems_pkey PRIMARY KEY (name);
ALTER TABLE ONLY public.teammembers
    ADD CONSTRAINT teammembers_pkey PRIMARY KEY (teamid, userid);
ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_name_key UNIQUE (name);
ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.termsofservice
    ADD CONSTRAINT termsofservice_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (token);
ALTER TABLE ONLY public.useraccesstokens
    ADD CONSTRAINT useraccesstokens_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.useraccesstokens
    ADD CONSTRAINT useraccesstokens_token_key UNIQUE (token);
ALTER TABLE ONLY public.usergroups
    ADD CONSTRAINT usergroups_name_key UNIQUE (name);
ALTER TABLE ONLY public.usergroups
    ADD CONSTRAINT usergroups_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.usergroups
    ADD CONSTRAINT usergroups_source_remoteid_key UNIQUE (source, remoteid);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_authdata_key UNIQUE (authdata);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);
ALTER TABLE ONLY public.usertermsofservice
    ADD CONSTRAINT usertermsofservice_pkey PRIMARY KEY (userid);
CREATE INDEX idx_audits_user_id ON public.audits USING btree (userid);
CREATE INDEX idx_channel_search_txt ON public.channels USING gin (to_tsvector('english'::regconfig, (((((name)::text || ' '::text) || (displayname)::text) || ' '::text) || (purpose)::text)));
CREATE INDEX idx_channelmembers_channel_id ON public.channelmembers USING btree (channelid);
CREATE INDEX idx_channelmembers_user_id ON public.channelmembers USING btree (userid);
CREATE INDEX idx_channels_create_at ON public.channels USING btree (createat);
CREATE INDEX idx_channels_delete_at ON public.channels USING btree (deleteat);
CREATE INDEX idx_channels_displayname_lower ON public.channels USING btree (lower((displayname)::text));
CREATE INDEX idx_channels_name ON public.channels USING btree (name);
CREATE INDEX idx_channels_name_lower ON public.channels USING btree (lower((name)::text));
CREATE INDEX idx_channels_scheme_id ON public.channels USING btree (schemeid);
CREATE INDEX idx_channels_team_id ON public.channels USING btree (teamid);
CREATE INDEX idx_channels_update_at ON public.channels USING btree (updateat);
CREATE INDEX idx_command_create_at ON public.commands USING btree (createat);
CREATE INDEX idx_command_delete_at ON public.commands USING btree (deleteat);
CREATE INDEX idx_command_team_id ON public.commands USING btree (teamid);
CREATE INDEX idx_command_update_at ON public.commands USING btree (updateat);
CREATE INDEX idx_command_webhook_create_at ON public.commandwebhooks USING btree (createat);
CREATE INDEX idx_emoji_create_at ON public.emoji USING btree (createat);
CREATE INDEX idx_emoji_delete_at ON public.emoji USING btree (deleteat);
CREATE INDEX idx_emoji_name ON public.emoji USING btree (name);
CREATE INDEX idx_emoji_update_at ON public.emoji USING btree (updateat);
CREATE INDEX idx_fileinfo_create_at ON public.fileinfo USING btree (createat);
CREATE INDEX idx_fileinfo_delete_at ON public.fileinfo USING btree (deleteat);
CREATE INDEX idx_fileinfo_postid_at ON public.fileinfo USING btree (postid);
CREATE INDEX idx_fileinfo_update_at ON public.fileinfo USING btree (updateat);
CREATE INDEX idx_groupchannels_channelid ON public.groupchannels USING btree (channelid);
CREATE INDEX idx_groupchannels_schemeadmin ON public.groupchannels USING btree (schemeadmin);
CREATE INDEX idx_groupmembers_create_at ON public.groupmembers USING btree (createat);
CREATE INDEX idx_groupteams_schemeadmin ON public.groupteams USING btree (schemeadmin);
CREATE INDEX idx_groupteams_teamid ON public.groupteams USING btree (teamid);
CREATE INDEX idx_incoming_webhook_create_at ON public.incomingwebhooks USING btree (createat);
CREATE INDEX idx_incoming_webhook_delete_at ON public.incomingwebhooks USING btree (deleteat);
CREATE INDEX idx_incoming_webhook_team_id ON public.incomingwebhooks USING btree (teamid);
CREATE INDEX idx_incoming_webhook_update_at ON public.incomingwebhooks USING btree (updateat);
CREATE INDEX idx_incoming_webhook_user_id ON public.incomingwebhooks USING btree (userid);
CREATE INDEX idx_jobs_type ON public.jobs USING btree (type);
CREATE INDEX idx_link_metadata_url_timestamp ON public.linkmetadata USING btree (url, "timestamp");
CREATE INDEX idx_oauthaccessdata_client_id ON public.oauthaccessdata USING btree (clientid);
CREATE INDEX idx_oauthaccessdata_refresh_token ON public.oauthaccessdata USING btree (refreshtoken);
CREATE INDEX idx_oauthaccessdata_user_id ON public.oauthaccessdata USING btree (userid);
CREATE INDEX idx_oauthapps_creator_id ON public.oauthapps USING btree (creatorid);
CREATE INDEX idx_oauthauthdata_client_id ON public.oauthauthdata USING btree (code);
CREATE INDEX idx_outgoing_webhook_create_at ON public.outgoingwebhooks USING btree (createat);
CREATE INDEX idx_outgoing_webhook_delete_at ON public.outgoingwebhooks USING btree (deleteat);
CREATE INDEX idx_outgoing_webhook_team_id ON public.outgoingwebhooks USING btree (teamid);
CREATE INDEX idx_outgoing_webhook_update_at ON public.outgoingwebhooks USING btree (updateat);
CREATE INDEX idx_posts_channel_id ON public.posts USING btree (channelid);
CREATE INDEX idx_posts_channel_id_delete_at_create_at ON public.posts USING btree (channelid, deleteat, createat);
CREATE INDEX idx_posts_channel_id_update_at ON public.posts USING btree (channelid, updateat);
CREATE INDEX idx_posts_create_at ON public.posts USING btree (createat);
CREATE INDEX idx_posts_delete_at ON public.posts USING btree (deleteat);
CREATE INDEX idx_posts_hashtags_txt ON public.posts USING gin (to_tsvector('english'::regconfig, (hashtags)::text));
CREATE INDEX idx_posts_is_pinned ON public.posts USING btree (ispinned);
CREATE INDEX idx_posts_message_txt ON public.posts USING gin (to_tsvector('english'::regconfig, (message)::text));
CREATE INDEX idx_posts_root_id ON public.posts USING btree (rootid);
CREATE INDEX idx_posts_update_at ON public.posts USING btree (updateat);
CREATE INDEX idx_posts_user_id ON public.posts USING btree (userid);
CREATE INDEX idx_preferences_category ON public.preferences USING btree (category);
CREATE INDEX idx_preferences_name ON public.preferences USING btree (name);
CREATE INDEX idx_preferences_user_id ON public.preferences USING btree (userid);
CREATE INDEX idx_publicchannels_delete_at ON public.publicchannels USING btree (deleteat);
CREATE INDEX idx_publicchannels_displayname_lower ON public.publicchannels USING btree (lower((displayname)::text));
CREATE INDEX idx_publicchannels_name ON public.publicchannels USING btree (name);
CREATE INDEX idx_publicchannels_name_lower ON public.publicchannels USING btree (lower((name)::text));
CREATE INDEX idx_publicchannels_search_txt ON public.publicchannels USING gin (to_tsvector('english'::regconfig, (((((name)::text || ' '::text) || (displayname)::text) || ' '::text) || (purpose)::text)));
CREATE INDEX idx_publicchannels_team_id ON public.publicchannels USING btree (teamid);
CREATE INDEX idx_schemes_channel_admin_role ON public.schemes USING btree (defaultchanneladminrole);
CREATE INDEX idx_schemes_channel_guest_role ON public.schemes USING btree (defaultchannelguestrole);
CREATE INDEX idx_schemes_channel_user_role ON public.schemes USING btree (defaultchanneluserrole);
CREATE INDEX idx_sessions_create_at ON public.sessions USING btree (createat);
CREATE INDEX idx_sessions_expires_at ON public.sessions USING btree (expiresat);
CREATE INDEX idx_sessions_last_activity_at ON public.sessions USING btree (lastactivityat);
CREATE INDEX idx_sessions_token ON public.sessions USING btree (token);
CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (userid);
CREATE INDEX idx_status_status ON public.status USING btree (status);
CREATE INDEX idx_status_user_id ON public.status USING btree (userid);
CREATE INDEX idx_teammembers_delete_at ON public.teammembers USING btree (deleteat);
CREATE INDEX idx_teammembers_team_id ON public.teammembers USING btree (teamid);
CREATE INDEX idx_teammembers_user_id ON public.teammembers USING btree (userid);
CREATE INDEX idx_teams_create_at ON public.teams USING btree (createat);
CREATE INDEX idx_teams_delete_at ON public.teams USING btree (deleteat);
CREATE INDEX idx_teams_invite_id ON public.teams USING btree (inviteid);
CREATE INDEX idx_teams_name ON public.teams USING btree (name);
CREATE INDEX idx_teams_scheme_id ON public.teams USING btree (schemeid);
CREATE INDEX idx_teams_update_at ON public.teams USING btree (updateat);
CREATE INDEX idx_user_access_tokens_token ON public.useraccesstokens USING btree (token);
CREATE INDEX idx_user_access_tokens_user_id ON public.useraccesstokens USING btree (userid);
CREATE INDEX idx_user_terms_of_service_user_id ON public.usertermsofservice USING btree (userid);
CREATE INDEX idx_usergroups_delete_at ON public.usergroups USING btree (deleteat);
CREATE INDEX idx_usergroups_remote_id ON public.usergroups USING btree (remoteid);
CREATE INDEX idx_users_all_no_full_name_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((((username)::text || ' '::text) || (nickname)::text) || ' '::text) || (email)::text)));
CREATE INDEX idx_users_all_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((((((((username)::text || ' '::text) || (firstname)::text) || ' '::text) || (lastname)::text) || ' '::text) || (nickname)::text) || ' '::text) || (email)::text)));
CREATE INDEX idx_users_create_at ON public.users USING btree (createat);
CREATE INDEX idx_users_delete_at ON public.users USING btree (deleteat);
CREATE INDEX idx_users_email ON public.users USING btree (email);
CREATE INDEX idx_users_email_lower_textpattern ON public.users USING btree (lower((email)::text) text_pattern_ops);
CREATE INDEX idx_users_firstname_lower_textpattern ON public.users USING btree (lower((firstname)::text) text_pattern_ops);
CREATE INDEX idx_users_lastname_lower_textpattern ON public.users USING btree (lower((lastname)::text) text_pattern_ops);
CREATE INDEX idx_users_names_no_full_name_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((username)::text || ' '::text) || (nickname)::text)));
CREATE INDEX idx_users_names_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((((((username)::text || ' '::text) || (firstname)::text) || ' '::text) || (lastname)::text) || ' '::text) || (nickname)::text)));
CREATE INDEX idx_users_nickname_lower_textpattern ON public.users USING btree (lower((nickname)::text) text_pattern_ops);
CREATE INDEX idx_users_update_at ON public.users USING btree (updateat);
CREATE INDEX idx_users_username_lower_textpattern ON public.users USING btree (lower((username)::text) text_pattern_ops);

-- AM Meetings schema — run this once in Supabase SQL Editor

create extension if not exists "pgcrypto";

create table meetings (
  id uuid primary key default gen_random_uuid(),
  track text not null check (track in ('dave','jessica','lais')),
  meeting_date date not null default current_date,
  status text not null default 'in_progress' check (status in ('in_progress','completed')),
  notes text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table issues (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references meetings(id) on delete cascade,
  text text default '',
  am text default '',
  priority text default 'Medium' check (priority in ('High','Medium','Low')),
  status text default 'Open' check (status in ('Open','Resolved')),
  action text default '',
  position int default 0
);

create table properties (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references meetings(id) on delete cascade,
  unit text default '',
  rev_current numeric,
  rev_prior numeric,
  occupancy numeric,
  last_booked date,
  problem text default '',
  why text default '',
  action text default '',
  decision text default '',
  owner text default '',
  follow_up_date date,
  position int default 0
);

create table pricing_rows (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references meetings(id) on delete cascade,
  unit text default '',
  date_range text default '',
  current_rate numeric,
  market_rate numeric,
  recommended_rate numeric,
  decision text default 'MONITOR' check (decision in ('HOLD','INCREASE','REDUCE','MONITOR','PROMOTION')),
  position int default 0
);

-- Decisions live at the track level (not per-meeting) because a decision
-- made this week carries forward, gets a status/result update, and shows
-- up as "previous meeting recap" next week until it's Completed.
create table decisions (
  id uuid primary key default gen_random_uuid(),
  track text not null check (track in ('dave','jessica','lais')),
  origin_meeting_id uuid references meetings(id) on delete set null,
  topic text default '',
  decision text default '',
  action text default '',
  owner text default '',
  due_date date,
  status text not null default 'Pending' check (status in ('Pending','In Progress','Completed','Carried Forward')),
  result text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index on meetings (track, meeting_date desc);
create index on issues (meeting_id);
create index on properties (meeting_id);
create index on pricing_rows (meeting_id);
create index on decisions (track, status);

-- No login system in this app, so RLS is enabled but wide open to the anon key.
-- Anyone holding the anon key (i.e. anyone with the artifact link) can read/write.
alter table meetings enable row level security;
alter table issues enable row level security;
alter table properties enable row level security;
alter table pricing_rows enable row level security;
alter table decisions enable row level security;

create policy "anon full access" on meetings for all using (true) with check (true);
create policy "anon full access" on issues for all using (true) with check (true);
create policy "anon full access" on properties for all using (true) with check (true);
create policy "anon full access" on pricing_rows for all using (true) with check (true);
create policy "anon full access" on decisions for all using (true) with check (true);

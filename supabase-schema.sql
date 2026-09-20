-- 日程协调器 实时协作 建表 SQL
-- 在 Supabase Dashboard → SQL Editor 执行

-- ========== 1. events 活动表 ==========
create table if not exists events (
  id           text primary key,
  name         text not null,
  dates        text[] not null,
  time_start   text not null,
  time_end     text not null,
  precision    int  not null default 30,
  created_at   timestamptz not null default now()
);

-- ========== 2. availability 可用时段表 ==========
create table if not exists availability (
  id          uuid primary key default gen_random_uuid(),
  event_id    text not null references events(id) on delete cascade,
  user_name   text not null,
  slots       text[] not null default '{}',
  updated_at  timestamptz not null default now(),
  unique (event_id, user_name)
);

create index if not exists idx_availability_event on availability(event_id);

-- ========== 3. presence 在线状态表 ==========
create table if not exists presence (
  id          uuid primary key default gen_random_uuid(),
  event_id    text not null references events(id) on delete cascade,
  user_name   text not null,
  last_seen   timestamptz not null default now(),
  unique (event_id, user_name)
);

create index if not exists idx_presence_event on presence(event_id);

-- ========== 4. RLS 行级安全策略（设置公开读写，方便开发期使用）==========
-- ⚠ 生产环境应收紧为认证用户专用，这里先开放以便小程序/H5 都能访问

alter table events        enable row level security;
alter table availability  enable row level security;
alter table presence      enable row level security;

-- events: 公开读写
drop policy if exists "events_all" on events;
create policy "events_all" on events for all using (true) with check (true);

-- availability: 公开读写
drop policy if exists "avail_all" on availability;
create policy "avail_all" on availability for all using (true) with check (true);

-- presence: 公开读写
drop policy if exists "presence_all" on presence;
create policy "presence_all" on presence for all using (true) with check (true);

-- ========== 5. Realtime 开启 ==========
-- 在 Dashboard → Database → Replication 确认以下表已加入 publication:
--   events, availability, presence
-- 也可用以下命令（supabase_realtime publication）:
alter publication supabase_realtime add table events;
alter publication supabase_realtime add table availability;
alter publication supabase_realtime add table presence;

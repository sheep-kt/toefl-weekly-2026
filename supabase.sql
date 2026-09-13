-- 在你自己的 Supabase 项目 SQL Editor 中执行一次。
-- 追加式事件表：每条修改独立保存；客户端合并后按修改时间解析最新状态。
create table if not exists public.toefl_events (
  user_id uuid not null references auth.users(id) on delete cascade,
  id uuid not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  primary key (user_id, id),
  constraint valid_payload check (
    jsonb_typeof(payload) = 'object'
    and payload->>'kind' in ('task','log','error','mock','settings')
    and payload->>'id' = id::text
    and octet_length(payload::text) <= 65536
  )
);
alter table public.toefl_events enable row level security;
revoke all on public.toefl_events from anon, authenticated;
grant select, insert on public.toefl_events to authenticated;
drop policy if exists "Read own TOEFL events" on public.toefl_events;
create policy "Read own TOEFL events" on public.toefl_events
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Insert own TOEFL events" on public.toefl_events;
create policy "Insert own TOEFL events" on public.toefl_events
  for insert to authenticated with check ((select auth.uid()) = user_id);
-- 不开放 update/delete；编辑和删除都是新事件，旧事件用于恢复和合并。

-- ============================================================
-- 20260523_01 カテゴリマスタ追加
-- ------------------------------------------------------------
-- 内容:
--   1. categories（カテゴリマスタ）テーブル作成
--   2. brain_dumps（メモ）テーブル作成（新規環境）
--   3. 既存環境への移行（next_action / category_id 追加、旧 category 列削除、
--      NOT NULL 解除）
--   4. カテゴリ仮データ 5件 INSERT
-- 実行先: Supabase SQL Editor (Primary Database / postgres)
-- 仕様:   docs/02_DB仕様書.md
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- 1. カテゴリマスタ
-- ============================================================
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sort_order integer not null default 0,
  created_at timestamptz default now(),
  constraint categories_name_unique unique (name)
);

-- ============================================================
-- 2. メモテーブル（新規環境）
-- ============================================================
create table if not exists public.brain_dumps (
  id uuid primary key default gen_random_uuid(),
  title text,
  category_id uuid references public.categories(id) on delete set null,
  content text,
  next_action text,
  created_at timestamptz default now()
);

-- ============================================================
-- 3. 既存環境への移行（再実行可）
-- ============================================================

-- next_action が無い場合に追加
alter table public.brain_dumps
  add column if not exists next_action text;

-- category_id（NULL 可）を追加
alter table public.brain_dumps
  add column if not exists category_id uuid;

-- 外部キー制約（未設定の場合のみ）
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'brain_dumps_category_id_fkey'
  ) then
    alter table public.brain_dumps
      add constraint brain_dumps_category_id_fkey
      foreign key (category_id)
      references public.categories(id)
      on delete set null;
  end if;
end $$;

-- 旧 category（text）列を削除
alter table public.brain_dumps drop column if exists category;

-- title / content の NOT NULL を外す
alter table public.brain_dumps alter column title drop not null;
alter table public.brain_dumps alter column content drop not null;

-- ============================================================
-- 4. カテゴリ仮データ（5件）
-- ============================================================
insert into public.categories (name, sort_order)
values
  ('仕事', 1),
  ('アイデア', 2),
  ('学習', 3),
  ('プライベート', 4),
  ('その他', 5)
on conflict (name) do nothing;

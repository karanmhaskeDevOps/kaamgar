-- ============================================================
-- KAAMGAR — Schema Update 2: Auth, Bookings, Profiles
-- Run this in Supabase SQL Editor AFTER schema.sql
-- Requires: Supabase Auth already enabled (it is, by default)
-- ============================================================

-- 1. CUSTOMER PROFILES
-- Supabase Auth already creates a row in auth.users on signup.
-- This table holds the extra profile info we need, linked 1:1.
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  city text,
  role text default 'customer', -- 'customer' or 'worker'
  created_at timestamptz default now()
);

alter table profiles enable row level security;

create policy "Users can view their own profile"
  on profiles for select
  using (auth.uid() = id);

create policy "Users can insert their own profile"
  on profiles for insert
  with check (auth.uid() = id);

create policy "Users can update their own profile"
  on profiles for update
  using (auth.uid() = id);


-- 2. BOOKINGS
-- Created when a logged-in customer clicks "Hire" on a worker's profile.
-- This is the real hiring action — separate from job_requests, which is
-- the "describe your job, we'll scope it" estimator flow.
create table if not exists bookings (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references auth.users(id) on delete set null,
  worker_id uuid references workers(id) on delete set null,
  job_description text,
  scheduled_date date,
  status text default 'requested', -- requested, confirmed, in_progress, completed, cancelled
  created_at timestamptz default now()
);

alter table bookings enable row level security;

-- A customer can see and create their own bookings
create policy "Customers can view their own bookings"
  on bookings for select
  using (auth.uid() = customer_id);

create policy "Customers can create bookings"
  on bookings for insert
  with check (auth.uid() = customer_id);


-- 3. Auto-create a profile row whenever someone signs up
-- (keeps profiles in sync with auth.users automatically)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'phone', ''),
    coalesce(new.raw_user_meta_data->>'role', 'customer')
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

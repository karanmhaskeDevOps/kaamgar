-- ============================================================
-- KAAMGAR — Schema Update 3: Admin/Staff Access
-- Run this in Supabase SQL Editor AFTER schema.sql and schema_update_2.sql
--
-- This adds the permissions needed for a staff/admin dashboard to see
-- and action job_requests, worker_applications, and bookings — which
-- until now were only visible via the Supabase Table Editor directly.
-- ============================================================

-- Admins (profiles.role = 'admin') can view every job request
create policy "Admins can view all job requests"
  on job_requests for select
  using ( exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin') );

-- Admins can update job request status (e.g. mark as confirmed/dispatched)
create policy "Admins can update job requests"
  on job_requests for update
  using ( exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin') );


-- Admins can view every worker application
create policy "Admins can view all worker applications"
  on worker_applications for select
  using ( exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin') );

-- Admins can update application status (e.g. mark as invited/verified/rejected)
create policy "Admins can update worker applications"
  on worker_applications for update
  using ( exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin') );


-- Admins can view every booking (not just their own, unlike regular customers)
create policy "Admins can view all bookings"
  on bookings for select
  using ( exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin') );

-- Admins can update booking status (e.g. mark as confirmed/completed)
create policy "Admins can update bookings"
  on bookings for update
  using ( exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin') );


-- ============================================================
-- IMPORTANT — MAKE YOURSELF AN ADMIN
-- Run this separately, replacing the email with the one you signed up with.
-- Without this, nobody can see the admin dashboard — by design, so a
-- random signup can't grant themselves staff access.
-- ============================================================

-- update profiles set role = 'admin'
-- where id = (select id from auth.users where email = 'YOUR_EMAIL_HERE');

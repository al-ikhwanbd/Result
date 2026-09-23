-- Darun Nazat Result Website - Supabase schema
-- Run this whole file in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists academic_years (id uuid primary key default gen_random_uuid(), year integer unique not null, active boolean default true, created_at timestamptz default now());
create table if not exists exams (id uuid primary key default gen_random_uuid(), code text unique not null, name_bn text not null, active boolean default true, sort_order integer default 0, created_at timestamptz default now());
create table if not exists classes (id uuid primary key default gen_random_uuid(), code text unique not null, name_bn text not null, sort_order integer default 0, active boolean default true, created_at timestamptz default now());
create table if not exists subjects (id uuid primary key default gen_random_uuid(), class_id uuid references classes(id) on delete cascade, name_bn text not null, sort_order integer default 0, active boolean default true, created_at timestamptz default now());
create table if not exists students (id uuid primary key default gen_random_uuid(), roll text not null, name text not null, class_id uuid references classes(id), guardian_name text, active boolean default true, created_at timestamptz default now(), unique(roll,class_id));
create table if not exists results (id uuid primary key default gen_random_uuid(), student_id uuid references students(id) on delete cascade not null, year_id uuid references academic_years(id) not null, exam_id uuid references exams(id) not null, class_id uuid references classes(id) not null, total numeric, average numeric, point numeric, grade text, rank integer, status text default 'published', created_at timestamptz default now(), updated_at timestamptz default now(), unique(student_id,year_id,exam_id));
create table if not exists result_marks (id uuid primary key default gen_random_uuid(), result_id uuid references results(id) on delete cascade not null, subject_id uuid references subjects(id) on delete cascade not null, marks numeric, unique(result_id,subject_id));
create table if not exists notices (id uuid primary key default gen_random_uuid(), title text not null, body text not null, published boolean default true, created_at timestamptz default now());
create table if not exists site_settings (key text primary key, value text, updated_at timestamptz default now());

insert into exams(code,name_bn,sort_order) values
('First Term Exam','প্রথম সাময়িক পরীক্ষা',1),('Second Term Exam','দ্বিতীয় সাময়িক পরীক্ষা',2),('Annual Exam','বার্ষিক পরীক্ষা',3)
on conflict(code) do nothing;

insert into site_settings(key,value) values
('school_name','দারুন নাজাত আইডিয়াল মাদরাসা'),('school_subtitle','ফলাফল প্রকাশনা'),('address','আবুতোরাব, মিরসরাই, চট্টগ্রাম।'),('phone','01623257140'),('footer_text','সকল অধিকার সংরক্ষিত'),('instructions','ব্যক্তিগত ফলাফলের জন্য সাল, পরীক্ষা, শ্রেণি ও রোল নম্বর নির্বাচন করুন।\nক্লাসওয়ারী ফলাফলের জন্য সাল, পরীক্ষা ও শ্রেণি নির্বাচন করুন।\nতথ্য না মিললে মাদ্রাসা কর্তৃপক্ষের সঙ্গে যোগাযোগ করুন।')
on conflict(key) do nothing;

-- Public website needs read access. Writes remain authenticated only.
alter table academic_years enable row level security;
alter table exams enable row level security;
alter table classes enable row level security;
alter table subjects enable row level security;
alter table students enable row level security;
alter table results enable row level security;
alter table result_marks enable row level security;
alter table notices enable row level security;
alter table site_settings enable row level security;

do $$ begin
create policy "public read years" on academic_years for select to anon, authenticated using (active=true);
exception when duplicate_object then null; end $$;
do $$ begin
create policy "public read exams" on exams for select to anon, authenticated using (active=true);
exception when duplicate_object then null; end $$;
do $$ begin
create policy "public read classes" on classes for select to anon, authenticated using (active=true);
exception when duplicate_object then null; end $$;
do $$ begin
create policy "public read subjects" on subjects for select to anon, authenticated using (active=true);
exception when duplicate_object then null; end $$;
do $$ begin
create policy "public read students" on students for select to anon, authenticated using (active=true);
exception when duplicate_object then null; end $$;
do $$ begin
create policy "public read results" on results for select to anon, authenticated using (status='published');
exception when duplicate_object then null; end $$;
do $$ begin
create policy "public read marks" on result_marks for select to anon, authenticated using (true);
exception when duplicate_object then null; end $$;
do $$ begin
create policy "public read notices" on notices for select to anon, authenticated using (published=true);
exception when duplicate_object then null; end $$;
do $$ begin
create policy "public read settings" on site_settings for select to anon, authenticated using (true);
exception when duplicate_object then null; end $$;

-- Authenticated admins can manage all rows. For a multi-admin production setup,
-- add an admin_roles table and restrict these policies to approved user IDs.

do $$ declare t text; begin
foreach t in array array['academic_years','exams','classes','subjects','students','results','result_marks','notices','site_settings'] loop
  execute format('drop policy if exists "authenticated manage %s" on %I',t,t);
  execute format('create policy "authenticated manage %s" on %I for all to authenticated using (true) with check (true)',t,t);
end loop; end $$;

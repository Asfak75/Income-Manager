-- Income Manager: run this entire script in Supabase SQL Editor.
-- Secure by default: every user can access only rows with their own auth.uid().
-- No demo transactions are inserted.

create extension if not exists pgcrypto;

create table if not exists public.income_entries (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entry_date date not null default current_date,
  amount numeric(14,2) not null check (amount > 0),
  source text not null check (length(trim(source)) > 0),
  category text not null default 'Other',
  description text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.expense_entries (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entry_date date not null default current_date,
  amount numeric(14,2) not null check (amount > 0),
  category text not null default 'Other',
  payee text not null default '',
  description text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.loans (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entry_date date not null default current_date,
  principal numeric(14,2) not null check (principal > 0),
  lender text not null check (length(trim(lender)) > 0),
  description text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.loan_repayments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  loan_id uuid not null references public.loans(id) on delete restrict,
  entry_date date not null default current_date,
  amount numeric(14,2) not null check (amount > 0),
  description text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists income_entries_owner_date_idx on public.income_entries(owner_id, entry_date desc);
create index if not exists expense_entries_owner_date_idx on public.expense_entries(owner_id, entry_date desc);
create index if not exists loans_owner_date_idx on public.loans(owner_id, entry_date desc);
create index if not exists loan_repayments_owner_date_idx on public.loan_repayments(owner_id, entry_date desc);
create index if not exists loan_repayments_loan_idx on public.loan_repayments(loan_id);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists income_entries_updated_at on public.income_entries;
create trigger income_entries_updated_at before update on public.income_entries for each row execute function public.set_updated_at();
drop trigger if exists expense_entries_updated_at on public.expense_entries;
create trigger expense_entries_updated_at before update on public.expense_entries for each row execute function public.set_updated_at();
drop trigger if exists loans_updated_at on public.loans;
create trigger loans_updated_at before update on public.loans for each row execute function public.set_updated_at();
drop trigger if exists loan_repayments_updated_at on public.loan_repayments;
create trigger loan_repayments_updated_at before update on public.loan_repayments for each row execute function public.set_updated_at();

alter table public.income_entries enable row level security;
alter table public.expense_entries enable row level security;
alter table public.loans enable row level security;
alter table public.loan_repayments enable row level security;

-- Remove/recreate policies so the script is safe to rerun.
drop policy if exists "Users manage own income" on public.income_entries;
create policy "Users manage own income" on public.income_entries
for all to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

drop policy if exists "Users manage own expenses" on public.expense_entries;
create policy "Users manage own expenses" on public.expense_entries
for all to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

drop policy if exists "Users manage own loans" on public.loans;
create policy "Users manage own loans" on public.loans
for all to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

drop policy if exists "Users manage own repayments" on public.loan_repayments;
create policy "Users manage own repayments" on public.loan_repayments
for all to authenticated
using (owner_id = (select auth.uid()))
with check (
  owner_id = (select auth.uid())
  and exists (
    select 1 from public.loans l
    where l.id = loan_id and l.owner_id = (select auth.uid())
  )
);

-- Ensure API roles do not receive broad table grants by accident; authenticated needs CRUD.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.income_entries, public.expense_entries, public.loans, public.loan_repayments to authenticated;
revoke all on public.income_entries, public.expense_entries, public.loans, public.loan_repayments from anon;

-- Important: In Supabase Dashboard > Authentication > Sign In / Providers:
-- create your own account first, confirm email if required, then disable public signups
-- if this project is strictly for one-person use. RLS remains essential regardless.

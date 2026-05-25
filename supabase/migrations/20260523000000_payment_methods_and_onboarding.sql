-- Payment methods, onboarding flags, and property payment linkage

-- Extend user_profiles
alter table public.user_profiles
  add column if not exists phone text,
  add column if not exists onboarding_completed boolean not null default false,
  add column if not exists default_rent_due_day int not null default 5,
  add column if not exists default_whatsapp_enabled boolean not null default true,
  add column if not exists settings jsonb not null default '{}'::jsonb;

-- Existing accounts skip onboarding (new signups set false explicitly)
update public.user_profiles set onboarding_completed = true where onboarding_completed = false;

-- Payment methods (per landlord)
create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('send_money', 'paybill', 'till')),
  display_name text not null,
  phone_number text,
  business_number text,
  account_number text,
  till_number text,
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists payment_methods_user_id_idx on public.payment_methods(user_id);

-- Link properties to a payment method
alter table public.properties
  add column if not exists payment_method_id uuid references public.payment_methods(id) on delete set null;

-- RLS for payment_methods
alter table public.payment_methods enable row level security;

create policy "Users can view own payment methods"
  on public.payment_methods for select
  using (auth.uid() = user_id);

create policy "Users can insert own payment methods"
  on public.payment_methods for insert
  with check (auth.uid() = user_id);

create policy "Users can update own payment methods"
  on public.payment_methods for update
  using (auth.uid() = user_id);

create policy "Users can delete own payment methods"
  on public.payment_methods for delete
  using (auth.uid() = user_id);

-- Ensure only one default per user
create or replace function public.ensure_single_default_payment_method()
returns trigger as $$
begin
  if new.is_default then
    update public.payment_methods
    set is_default = false, updated_at = now()
    where user_id = new.user_id and id <> new.id and is_default = true;
  end if;
  new.updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists payment_methods_default_trigger on public.payment_methods;
create trigger payment_methods_default_trigger
  before insert or update on public.payment_methods
  for each row execute function public.ensure_single_default_payment_method();

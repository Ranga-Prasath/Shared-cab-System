create extension if not exists "uuid-ossp";
create extension if not exists postgis;

create type public.user_role as enum ('passenger', 'driver', 'admin');
create type public.ride_status as enum ('REQUESTED', 'MATCHED', 'EN_ROUTE', 'COMPLETED', 'CANCELLED');
create type public.match_status as enum ('proposed', 'accepted', 'rejected');

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text not null,
  avatar_url text,
  role public.user_role not null default 'passenger',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rides (
  id uuid primary key default uuid_generate_v4(),
  passenger_id uuid not null references public.profiles(id) on delete restrict,
  driver_id uuid references public.profiles(id) on delete set null,
  status public.ride_status not null default 'REQUESTED',
  pickup_location geography(point, 4326) not null,
  dropoff_location geography(point, 4326) not null,
  pickup_address text not null,
  dropoff_address text not null,
  route_polyline text,
  estimated_fare numeric(10,2) not null default 0,
  actual_fare numeric(10,2),
  scheduled_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ride_matches (
  id uuid primary key default uuid_generate_v4(),
  ride_id uuid not null references public.rides(id) on delete cascade,
  matched_ride_id uuid not null references public.rides(id) on delete cascade,
  overlap_percentage float not null,
  detour_meters integer not null,
  status public.match_status not null default 'proposed',
  created_at timestamptz not null default now(),
  constraint ride_matches_unique_pair unique (ride_id, matched_ride_id)
);

create table if not exists public.driver_locations (
  id uuid primary key default uuid_generate_v4(),
  driver_id uuid not null references public.profiles(id) on delete cascade,
  location geography(point, 4326) not null,
  heading float,
  speed float,
  updated_at timestamptz not null default now()
);

create index if not exists idx_rides_pickup_location on public.rides using gist (pickup_location);
create index if not exists idx_rides_dropoff_location on public.rides using gist (dropoff_location);
create index if not exists idx_driver_locations_location on public.driver_locations using gist (location);

alter table public.profiles enable row level security;
alter table public.rides enable row level security;
alter table public.ride_matches enable row level security;
alter table public.driver_locations enable row level security;

create policy "profiles_select_own" on public.profiles
for select using (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
for update using (auth.uid() = id);

create policy "rides_select_related" on public.rides
for select using (auth.uid() = passenger_id or auth.uid() = driver_id);

create policy "rides_insert_passenger" on public.rides
for insert with check (auth.uid() = passenger_id);

create policy "rides_update_related" on public.rides
for update using (auth.uid() = passenger_id or auth.uid() = driver_id);

create policy "ride_matches_select_related" on public.ride_matches
for select using (
  exists (select 1 from public.rides r where r.id = ride_id and (r.passenger_id = auth.uid() or r.driver_id = auth.uid()))
);

create policy "driver_locations_select_all" on public.driver_locations
for select using (true);

create policy "driver_locations_upsert_driver" on public.driver_locations
for all using (auth.uid() = driver_id) with check (auth.uid() = driver_id);
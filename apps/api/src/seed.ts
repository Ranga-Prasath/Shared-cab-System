import { randomUUID } from 'node:crypto';
import { createClient } from '@supabase/supabase-js';
import { Pool } from 'pg';
import { getEnv } from './config/env.validation.js';

type Role = 'passenger' | 'driver' | 'admin';
type RideStatus = 'REQUESTED' | 'MATCHED' | 'EN_ROUTE' | 'COMPLETED';

interface SeedUser {
  fullName: string;
  phone: string;
  role: Role;
  email: string;
}

interface RouteSeed {
  pickup: [number, number];
  dropoff: [number, number];
  pickupAddress: string;
  dropoffAddress: string;
  status: RideStatus;
  polyline: string | null;
}

const passengerNames = [
  'Aarav Sharma', 'Ananya Iyer', 'Rahul Verma', 'Sneha Nair', 'Karthik Reddy',
  'Meera Joshi', 'Vikram Patel', 'Isha Menon', 'Rohan Gupta', 'Pooja Das',
  'Nitin Bhat', 'Divya Kulkarni', 'Sanjay Rao', 'Neha Kapoor', 'Aditya Singh',
  'Kavya Pillai', 'Arjun Malhotra', 'Ritika Jain', 'Manoj Shetty', 'Priya Thomas'
];

const driverNames = ['Suresh Kumar', 'Mahesh Gowda', 'Ravi Nayak', 'Imran Khan', 'Deepak Hegde'];

const routeSeeds: RouteSeed[] = [
  { pickup: [77.5595, 12.955], dropoff: [76.6394, 12.2958], pickupAddress: 'Seed Majestic, Bengaluru', dropoffAddress: 'Seed Mysore Palace', status: 'EN_ROUTE', polyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@' },
  { pickup: [77.4888, 12.9279], dropoff: [76.5668, 12.315], pickupAddress: 'Seed Kengeri, Bengaluru', dropoffAddress: 'Seed Columbia Asia Mysuru', status: 'MATCHED', polyline: 'a{~wAeyfxM~BoJ' },
  { pickup: [77.4025, 12.84], dropoff: [76.4892, 12.311], pickupAddress: 'Seed Bidadi Toll', dropoffAddress: 'Seed Mysuru Ring Road', status: 'REQUESTED', polyline: null },
  { pickup: [77.2969, 12.7312], dropoff: [76.3876, 12.3526], pickupAddress: 'Seed Ramanagara Bus Stand', dropoffAddress: 'Seed Srirangapatna', status: 'COMPLETED', polyline: '_chxEn`zvN\\]]' },
  { pickup: [77.1675, 12.5163], dropoff: [76.3127, 12.42], pickupAddress: 'Seed Channapatna', dropoffAddress: 'Seed Srirangapatna Gate', status: 'EN_ROUTE', polyline: null },
  { pickup: [77.0946, 12.6556], dropoff: [76.2237, 12.5223], pickupAddress: 'Seed Maddur', dropoffAddress: 'Seed Mandya Bus Stand', status: 'REQUESTED', polyline: null },
  { pickup: [76.9929, 12.545], dropoff: [76.191, 12.4348], pickupAddress: 'Seed Mandya Highway', dropoffAddress: 'Seed KRS Road Junction', status: 'MATCHED', polyline: '_p~iF~ps|U' },
  { pickup: [77.5946, 12.9716], dropoff: [77.3178, 12.8406], pickupAddress: 'Seed MG Road, Bengaluru', dropoffAddress: 'Seed Bidadi Junction', status: 'COMPLETED', polyline: null },
  { pickup: [77.4305, 12.9392], dropoff: [76.6558, 12.3052], pickupAddress: 'Seed NICE Road Entry', dropoffAddress: 'Seed Mysuru Center', status: 'EN_ROUTE', polyline: 'a{~wAeyfxM~BoJ' },
  { pickup: [77.506, 12.9166], dropoff: [76.6843, 12.4226], pickupAddress: 'Seed RR Nagar', dropoffAddress: 'Seed Srirangapatna Fort', status: 'REQUESTED', polyline: null }
];

const buildUsers = (): { passengers: SeedUser[]; drivers: SeedUser[]; admin: SeedUser } => {
  const passengers = passengerNames.map((fullName, index) => ({
    fullName,
    phone: `+910000000${String(index + 1).padStart(2, '0')}`,
    role: 'passenger' as const,
    email: `seed.passenger${index + 1}@sharedcab.demo`
  }));

  const drivers = driverNames.map((fullName, index) => ({
    fullName,
    phone: `+919900000${String(index + 1).padStart(2, '0')}`,
    role: 'driver' as const,
    email: `seed.driver${index + 1}@sharedcab.demo`
  }));

  const admin: SeedUser = {
    fullName: 'Seed Admin',
    phone: '+919800000000',
    role: 'admin',
    email: 'seed.admin@sharedcab.demo'
  };

  return { passengers, drivers, admin };
};

const main = async (): Promise<void> => {
  const env = getEnv();
  const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false }
  });
  const db = new Pool({ connectionString: env.DATABASE_URL });

  const users = buildUsers();
  const allSeeds = [...users.passengers, ...users.drivers, users.admin];
  const { data: listed } = await supabase.auth.admin.listUsers({ page: 1, perPage: 1000 });
  const existingByEmail = new Map((listed?.users ?? []).map((user) => [user.email ?? '', user.id]));

  const userIds = new Map<string, string>();

  for (const seed of allSeeds) {
    const existingId = existingByEmail.get(seed.email);
    if (existingId) {
      userIds.set(seed.email, existingId);
      continue;
    }

    const result = await supabase.auth.admin.createUser({
      email: seed.email,
      password: 'SeedUser@123',
      email_confirm: true,
      user_metadata: { source: 'seed-script' }
    });

    if (!result.data.user?.id) {
      throw new Error(`Failed to create auth user for ${seed.email}.`);
    }

    userIds.set(seed.email, result.data.user.id);
  }

  const passengerIds = users.passengers.map((item) => userIds.get(item.email) ?? '');
  const driverIds = users.drivers.map((item) => userIds.get(item.email) ?? '');

  await db.query('begin');
  try {
    await db.query("delete from public.rides where pickup_address like 'Seed %'");
    await db.query("delete from public.driver_locations where driver_id in (select id from public.profiles where phone like '+919900000%')");

    for (const seed of allSeeds) {
      const id = userIds.get(seed.email);
      if (!id) {
        throw new Error(`Missing id for ${seed.email}`);
      }

      await db.query(
        `insert into public.profiles (id, full_name, phone, role)
         values ($1, $2, $3, $4)
         on conflict (id) do update
         set full_name = excluded.full_name, phone = excluded.phone, role = excluded.role, updated_at = now()`,
        [id, seed.fullName, seed.phone, seed.role]
      );
    }

    for (let index = 0; index < routeSeeds.length; index += 1) {
      const seed = routeSeeds[index];
      const passengerId = passengerIds[index % passengerIds.length];
      const driverId = seed.status === 'REQUESTED' ? null : driverIds[index % driverIds.length];
      const scheduledAt = new Date(Date.now() + index * 30 * 60000).toISOString();
      const startedAt = seed.status === 'EN_ROUTE' || seed.status === 'COMPLETED' ? new Date().toISOString() : null;
      const completedAt = seed.status === 'COMPLETED' ? new Date().toISOString() : null;

      await db.query(
        `insert into public.rides (
          id, passenger_id, driver_id, status, pickup_location, dropoff_location,
          pickup_address, dropoff_address, route_polyline, estimated_fare, actual_fare,
          scheduled_at, started_at, completed_at
        ) values (
          $1, $2, $3, $4,
          ST_SetSRID(ST_MakePoint($5, $6), 4326)::geography,
          ST_SetSRID(ST_MakePoint($7, $8), 4326)::geography,
          $9, $10, $11, $12, $13, $14, $15, $16
        )`,
        [
          randomUUID(),
          passengerId,
          driverId,
          seed.status,
          seed.pickup[0],
          seed.pickup[1],
          seed.dropoff[0],
          seed.dropoff[1],
          seed.pickupAddress,
          seed.dropoffAddress,
          seed.polyline ?? 'a{~wAeyfxM~BoJ',
          300 + index * 45,
          seed.status === 'COMPLETED' ? 320 + index * 40 : null,
          scheduledAt,
          startedAt,
          completedAt
        ]
      );
    }

    for (let index = 0; index < driverIds.length; index += 1) {
      const driverId = driverIds[index];
      const anchor = routeSeeds[index];
      await db.query(
        `insert into public.driver_locations (id, driver_id, location, heading, speed, updated_at)
         values ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography, $5, $6, now())`,
        [randomUUID(), driverId, anchor.pickup[0], anchor.pickup[1], 30 + index * 12, 35 + index * 4]
      );
    }

    await db.query('commit');
    console.log('Seed completed: 20 passengers, 5 drivers, 10 rides, 5 driver locations.');
  } catch (error) {
    await db.query('rollback');
    throw error;
  } finally {
    await db.end();
  }
};

void main();

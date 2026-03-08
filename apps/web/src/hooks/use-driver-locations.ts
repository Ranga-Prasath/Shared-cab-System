'use client';

import { useEffect, useMemo, useState } from 'react';
import { createSupabaseBrowserClient } from '../lib/supabase';

interface DriverPoint {
  id: string;
  driver_id: string;
  location: { coordinates: [number, number] };
}

export function useDriverLocations(): DriverPoint[] {
  const [drivers, setDrivers] = useState<DriverPoint[]>([]);
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);

  useEffect(() => {
    if (!supabase) {
      return;
    }

    const channel = supabase
      .channel('driver_locations_hook')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'driver_locations' }, (payload) => {
        setDrivers((prev) => [payload.new as DriverPoint, ...prev].slice(0, 50));
      })
      .subscribe();

    return () => {
      void supabase.removeChannel(channel);
    };
  }, [supabase]);

  return drivers;
}

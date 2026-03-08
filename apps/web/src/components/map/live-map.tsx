'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { MapContainer, TileLayer } from 'react-leaflet';
import type { LatLngTuple } from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { createSupabaseBrowserClient } from '../../lib/supabase';
import type { RideDto } from '../../lib/api';
import { CabMarker } from './cab-marker';
import { RouteOverlay } from './route-overlay';

interface LiveMapProps {
  rides: RideDto[];
  selectedRideId: string;
}

interface DriverRealtimeRow {
  id: string;
  driver_id: string;
  location: unknown;
}

const parseCoordinates = (value: unknown): [number, number] | null => {
  if (typeof value === 'string') {
    const match = value.match(/POINT\(([-\d.]+)\s+([-\d.]+)\)/i);
    if (match) {
      return [Number(match[1]), Number(match[2])];
    }
  }

  if (typeof value === 'object' && value !== null) {
    const maybeCoordinates = (value as { coordinates?: unknown }).coordinates;
    if (Array.isArray(maybeCoordinates) && maybeCoordinates.length === 2) {
      const [lon, lat] = maybeCoordinates;
      if (typeof lon === 'number' && typeof lat === 'number') {
        return [lon, lat];
      }
    }
  }

  return null;
};

const toLatLng = ([lon, lat]: [number, number]): LatLngTuple => [lat, lon];

export function LiveMap({ rides, selectedRideId }: LiveMapProps) {
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);
  const [targetPositions, setTargetPositions] = useState<Record<string, LatLngTuple>>({});
  const [displayPositions, setDisplayPositions] = useState<Record<string, LatLngTuple>>({});
  const frameRef = useRef<number | null>(null);

  const selectedRide = rides.find((ride) => ride.id === selectedRideId) ?? rides[0];
  const center = selectedRide ? toLatLng(selectedRide.pickupLocation) : ([12.9174, 77.5946] as LatLngTuple);

  useEffect(() => {
    if (!supabase) {
      return;
    }

    const pullInitial = async (): Promise<void> => {
      const { data } = await supabase.from('driver_locations').select('id, driver_id, location').limit(30);
      if (!data) {
        return;
      }

      const next: Record<string, LatLngTuple> = {};
      data.forEach((row) => {
        const coords = parseCoordinates(row.location);
        if (coords) {
          next[row.driver_id] = toLatLng(coords);
        }
      });

      setTargetPositions(next);
      setDisplayPositions(next);
    };

    void pullInitial();

    const channel = supabase
      .channel('driver_locations_dashboard')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'driver_locations' }, (payload) => {
        const updated = payload.new as Partial<DriverRealtimeRow>;
        if (!updated.driver_id) {
          return;
        }

        const coords = parseCoordinates(updated.location);
        if (!coords) {
          return;
        }

        const nextPoint = toLatLng(coords);
        setTargetPositions((prev) => ({ ...prev, [updated.driver_id as string]: nextPoint }));
      })
      .subscribe();

    return () => {
      if (frameRef.current) {
        cancelAnimationFrame(frameRef.current);
      }
      void supabase.removeChannel(channel);
    };
  }, [supabase]);

  useEffect(() => {
    const step = (): void => {
      setDisplayPositions((prev) => {
        const next: Record<string, LatLngTuple> = { ...prev };
        let changed = false;

        Object.entries(targetPositions).forEach(([driverId, target]) => {
          const current = prev[driverId] ?? target;
          const lat = current[0] + (target[0] - current[0]) * 0.2;
          const lon = current[1] + (target[1] - current[1]) * 0.2;
          if (Math.abs(lat - current[0]) > 0.00001 || Math.abs(lon - current[1]) > 0.00001) {
            changed = true;
          }
          next[driverId] = [lat, lon];
        });

        return changed ? next : prev;
      });

      frameRef.current = requestAnimationFrame(step);
    };

    frameRef.current = requestAnimationFrame(step);
    return () => {
      if (frameRef.current) {
        cancelAnimationFrame(frameRef.current);
      }
    };
  }, [targetPositions]);

  return (
    <MapContainer center={center} zoom={8} className="h-full w-full" scrollWheelZoom>
      <TileLayer
        url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        attribution="&copy; OpenStreetMap contributors &copy; CARTO"
      />

      {selectedRide?.routePolyline ? <RouteOverlay encodedPolyline={selectedRide.routePolyline} /> : null}

      {Object.entries(displayPositions).map(([driverId, position]) => (
        <CabMarker key={driverId} position={position} kind="driver" label={`Driver ${driverId.slice(0, 8)}`} />
      ))}

      {rides.map((ride) => (
        <CabMarker
          key={`passenger-${ride.id}`}
          position={toLatLng(ride.pickupLocation)}
          kind="passenger"
          label={`Passenger pickup: ${ride.pickupAddress}`}
        />
      ))}
    </MapContainer>
  );
}

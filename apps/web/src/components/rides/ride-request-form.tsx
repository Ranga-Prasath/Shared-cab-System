'use client';

import { useState, useEffect } from 'react';
import { apiClient } from '../../lib/api';
import { useGeolocation } from '../../lib/use-geolocation';
import { LocationPicker } from '../map/location-picker';
import { reverseGeocode } from '../../lib/geocoding';

export function RideRequestForm({ onSuccess }: { onSuccess?: () => void }) {
  const { location, loading: geoLoading } = useGeolocation();
  const [pickup, setPickup] = useState<{ addr: string; lat: number; lon: number } | null>(null);
  const [dropoff, setDropoff] = useState<{ addr: string; lat: number; lon: number } | null>(null);

  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  // Auto-fill pickup with current location
  useEffect(() => {
    if (location && !pickup && !geoLoading) {
      reverseGeocode(location.lat, location.lng).then(addr => {
        setPickup({ addr, lat: location.lat, lon: location.lng });
      });
    }
  }, [location, pickup, geoLoading]);

  const submit = async (): Promise<void> => {
    if (!pickup || !dropoff) {
      setMessage('Please select both pickup and dropoff locations.');
      return;
    }

    setLoading(true);
    setMessage('');

    const response = await apiClient.createRide({
      pickupLocation: [pickup.lon, pickup.lat], // Longitude, Latitude for PostGIS
      dropoffLocation: [dropoff.lon, dropoff.lat],
      pickupAddress: pickup.addr,
      dropoffAddress: dropoff.addr,
      scheduledAt: new Date(Date.now() + 5 * 60000).toISOString() // 5 mins from now
    });

    setLoading(false);
    if (response.success) {
      setMessage('Ride requested! Searching for nearby drivers...');
      if (onSuccess) setTimeout(onSuccess, 2000);
    } else {
      setMessage(response.error ?? 'Request failed.');
    }
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="rounded-2xl bg-slate-900/50 p-4 border border-white/5 space-y-4">
        <LocationPicker
          label="Pickup Location"
          placeholder={geoLoading ? "Getting your location..." : "Search for pickup..."}
          value={pickup?.addr || ''}
          onChange={(addr, lat, lon) => setPickup({ addr, lat, lon })}
          icon={
            <svg className="w-5 h-5 text-cyan-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <circle cx="12" cy="12" r="4" strokeWidth="2" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 2v2m0 16v2m10-10h-2M4 12H2" />
            </svg>
          }
        />

        <LocationPicker
          label="Dropoff Destination"
          placeholder="Where to?"
          value={dropoff?.addr || ''}
          onChange={(addr, lat, lon) => setDropoff({ addr, lat, lon })}
          icon={
            <svg className="w-5 h-5 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          }
        />
      </div>

      <button
        onClick={() => void submit()}
        disabled={loading || !pickup || !dropoff}
        className="w-full rounded-xl bg-cyan-500 py-4 font-bold text-slate-950 transition-all active:scale-[0.98] disabled:opacity-50 disabled:active:scale-100 flex justify-center items-center"
      >
        {loading ? (
          <div className="h-5 w-5 animate-spin rounded-full border-2 border-slate-800 border-t-white" />
        ) : (
          'Request Ride Now'
        )}
      </button>

      {message && (
        <p className={`text-center text-sm ${message.includes('failed') || message.includes('Please') ? 'text-red-400' : 'text-cyan-400'}`}>
          {message}
        </p>
      )}
    </div>
  );
}
'use client';

import { useEffect, useMemo, useState } from 'react';
import dynamic from 'next/dynamic';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import { apiClient, type RideDto } from '../../lib/api';
import { RideSidebar } from './ride-sidebar';
import { BottomSheet } from '../ui/bottom-sheet';
import { RideRequestForm } from './ride-request-form';
import { DriverControls } from './driver-controls';

const LiveMap = dynamic(() => import('../map/live-map').then((mod) => mod.LiveMap), { ssr: false });

const demoRides: RideDto[] = [
  // ... existing demo rides
];

export function DashboardShell() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [rides, setRides] = useState<RideDto[]>([]);
  const [selectedRideId, setSelectedRideId] = useState<string>('');
  const [requestSheetOpen, setRequestSheetOpen] = useState(false);

  useEffect(() => {
    const run = async (): Promise<void> => {
      const result = await apiClient.listRides();
      if (result.success && result.data && result.data.length > 0) {
        setRides(result.data);
        const requested = searchParams.get('ride');
        const existing = result.data.find((ride) => ride.id === requested);
        if (existing) setSelectedRideId(existing.id);
        else setSelectedRideId(result.data[0].id);
      }
    };

    void run();
  }, [searchParams]);

  const activeRides = useMemo(
    () => rides.filter((ride) => ride.status !== 'COMPLETED' && ride.status !== 'CANCELLED'),
    [rides]
  );


  useEffect(() => {
    if (!selectedRideId) {
      return;
    }
    if (searchParams.get('ride') === selectedRideId) {
      return;
    }

    const params = new URLSearchParams(searchParams.toString());
    params.set('ride', selectedRideId);
    router.replace(`${pathname}?${params.toString()}`);
  }, [pathname, router, searchParams, selectedRideId]);

  return (
    <section className="relative h-full w-full overflow-hidden bg-slate-950">
      {/* Full screen map */}
      <div className="absolute inset-0 z-0">
        <LiveMap rides={activeRides} selectedRideId={selectedRideId} />
      </div>

      {/* Floating UI Elements (Top) */}
      <div className="pointer-events-none absolute left-0 right-0 top-0 z-10 flex justify-between p-4">
        <div className="pointer-events-auto rounded-full bg-black/50 p-3 backdrop-blur-md border border-white/10 shadow-lg h-12 flex items-center">
          <h1 className="text-lg font-bold text-white px-2">Shared Cab</h1>
        </div>
      </div>

      <DriverControls />

      {/* Passenger Action (Where to?) */}
      <div className="absolute bottom-32 left-0 right-0 z-20 flex justify-center lg:bottom-10 lg:left-auto lg:right-10 px-4 pointer-events-none">
        <button
          className="w-full max-w-sm rounded-full bg-white px-6 py-4 shadow-2xl transition-transform active:scale-95 pointer-events-auto flex items-center gap-3"
          onClick={() => setRequestSheetOpen(true)}
        >
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-slate-100">
            <svg className="h-5 w-5 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
          <span className="text-lg font-medium text-slate-800">Where to?</span>
        </button>
      </div>

      {/* Ride Request Bottom Sheet */}
      <BottomSheet
        isOpen={requestSheetOpen}
        onClose={() => setRequestSheetOpen(false)}
        title="Request a Ride"
        snapPoints={['50%', '90%']}
        initialSnap={1}
      >
        <RideRequestForm onSuccess={() => setRequestSheetOpen(false)} />
      </BottomSheet>

      {/* Mobile Bottom Sheet & Desktop Sidebar Context */}
      <div className="lg:hidden pointer-events-auto">
        <BottomSheet
          isOpen={!requestSheetOpen && activeRides.length > 0}
          title="Active Rides"
          snapPoints={['15%', '45%', '80%']}
          initialSnap={0}
        >
          <RideSidebar
            rides={activeRides}
            selectedRideId={selectedRideId}
            onSelect={setSelectedRideId}
            onToggleMobile={() => { }}
          />
        </BottomSheet>
      </div>

      {/* Desktop Sidebar (Floating Card) */}
      <div className="pointer-events-none absolute bottom-6 left-6 top-24 z-10 hidden w-96 lg:block">
        <div className="pointer-events-auto h-full flex flex-col rounded-3xl border border-white/10 bg-slate-900/80 backdrop-blur-xl shadow-2xl overflow-hidden p-6">
          <h2 className="text-xl font-bold text-white mb-4">Active Rides</h2>
          <div className="flex-1 overflow-y-auto custom-scrollbar -mr-2 pr-2">
            <RideSidebar
              rides={activeRides}
              selectedRideId={selectedRideId}
              onSelect={setSelectedRideId}
              onToggleMobile={() => { }}
            />
          </div>
        </div>
      </div>

    </section>
  );
}

'use client';

import { Badge } from '../ui/badge';
import type { RideDto } from '../../lib/api';

interface RideSidebarProps {
  rides: RideDto[];
  selectedRideId: string;
  onSelect: (rideId: string) => void;
  onToggleMobile: () => void;
}

export function RideSidebar({ rides, selectedRideId, onSelect, onToggleMobile }: RideSidebarProps) {
  return (
    <div className="flex h-full flex-col">
      <div className="mb-4 flex items-center justify-between px-1">
        <h3 className="text-sm font-medium text-slate-400">Available ({rides.length})</h3>
      </div>

      <div className="flex-1 space-y-3 overflow-y-auto pr-1" role="list">
        {rides.map((ride) => {
          const selected = ride.id === selectedRideId;
          return (
            <button
              key={ride.id}
              data-testid={`ride-card-${ride.id}`}
              type="button"
              className={[
                'w-full rounded-2xl border p-4 text-left transition-all duration-200',
                selected
                  ? 'border-cyan-400 bg-cyan-950/30 shadow-[0_0_15px_-3px_rgba(34,211,238,0.2)]'
                  : 'border-white/5 bg-white/5 hover:bg-white/10 hover:border-white/10'
              ].join(' ')}
              onClick={() => {
                onSelect(ride.id);
                if (window.innerWidth < 1024) {
                  onToggleMobile();
                }
              }}
            >
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-sm font-semibold text-white">{ride.pickupAddress.split(',')[0]}</p>
                  <p className="mt-1 text-sm text-slate-400">to {ride.dropoffAddress.split(',')[0]}</p>
                </div>
                <span className="text-base font-medium text-cyan-300">₹{ride.estimatedFare.toFixed(0)}</span>
              </div>

              <div className="mt-4 flex items-center gap-2">
                <Badge label={ride.status} />
                <span className="text-xs text-slate-500">#{ride.id.slice(0, 6)}</span>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

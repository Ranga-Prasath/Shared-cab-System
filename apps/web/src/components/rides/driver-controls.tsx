'use client';

import { useState, useEffect } from 'react';
import { useGeolocation } from '../../lib/use-geolocation';
import { createSupabaseBrowserClient } from '../../lib/supabase';
import { BottomSheet } from '../ui/bottom-sheet';
import { apiClient } from '../../lib/api';

export function DriverControls() {
    const [isOnline, setIsOnline] = useState(false);
    const { location, error } = useGeolocation();
    const [sheetOpen, setSheetOpen] = useState(false);
    const [incomingRides, setIncomingRides] = useState<any[]>([]);
    const [sessionUser, setSessionUser] = useState<string | null>(null);

    // Fetch session on mount
    useEffect(() => {
        const supabase = createSupabaseBrowserClient();
        if (supabase) {
            supabase.auth.getSession().then(({ data }) => {
                if (data.session?.user) {
                    setSessionUser(data.session.user.id);
                }
            });
        }
    }, []);

    useEffect(() => {
        if (!isOnline || !sessionUser) return;
        const supabase = createSupabaseBrowserClient();
        if (!supabase) return;

        // Listen for new requested rides
        const channel = supabase
            .channel('driver_rides_dashboard')
            .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'rides', filter: 'status=eq.REQUESTED' }, (payload) => {
                setIncomingRides((prev) => [payload.new, ...prev]);
                setSheetOpen(true);
            })
            .subscribe();

        return () => {
            void supabase.removeChannel(channel);
        };
    }, [isOnline, sessionUser]);

    const toggleOnline = async () => {
        if (!isOnline && location && sessionUser) {
            const supabase = createSupabaseBrowserClient();
            if (supabase) {
                await supabase.from('driver_locations').upsert({
                    driver_id: sessionUser,
                    location: `POINT(${location.lng} ${location.lat})`,
                    status: 'AVAILABLE'
                });
            }
        }
        setIsOnline(!isOnline);
    };

    const acceptRide = async (rideId: string) => {
        if (!sessionUser) return;
        try {
            const res = await apiClient.acceptRide(rideId);
            if (res.success) {
                setIncomingRides((prev) => prev.filter(r => r.id !== rideId));
                alert('Ride Accepted! Routing you to passenger...');
            } else {
                alert('Failed to accept ride: ' + (res.error ?? 'Unknown error'));
            }
        } catch (err) {
            console.error(err);
            alert('An error occurred while accepting the ride');
        }
    };

    return (
        <>
            <div className="absolute top-20 right-4 z-20 pointer-events-auto">
                <button
                    onClick={() => setSheetOpen(true)}
                    className={`flex items-center gap-2 rounded-full px-4 py-2 shadow-xl transition-all ${isOnline ? 'bg-emerald-500 text-white shadow-emerald-500/20' : 'bg-slate-800 text-slate-300 border border-slate-700'
                        }`}
                >
                    <div className={`h-2.5 w-2.5 rounded-full ${isOnline ? 'bg-white animate-pulse' : 'bg-slate-500'}`} />
                    <span className="font-semibold">{isOnline ? 'Online' : 'Offline'}</span>
                </button>
            </div>

            <BottomSheet
                isOpen={sheetOpen}
                onClose={() => setSheetOpen(false)}
                title="Driver Dashboard"
                snapPoints={['50%', '85%']}
                initialSnap={0}
            >
                <div className="flex flex-col gap-6">
                    <div className="flex items-center justify-between rounded-2xl bg-slate-800/50 p-4 border border-white/5">
                        <div>
                            <h3 className="text-lg font-medium text-white">Status</h3>
                            <p className="text-sm text-slate-400">
                                {isOnline ? 'Ready for rides' : 'You are currently offline'}
                            </p>
                        </div>

                        <button
                            onClick={() => void toggleOnline()}
                            className={`relative inline-flex h-8 w-14 items-center rounded-full transition-colors ${isOnline ? 'bg-emerald-500' : 'bg-slate-600'
                                }`}
                        >
                            <span
                                className={`inline-block h-6 w-6 transform rounded-full bg-white transition-transform ${isOnline ? 'translate-x-7' : 'translate-x-1'
                                    }`}
                            />
                        </button>
                    </div>

                    {error && <p className="text-xs text-red-400">{error}</p>}

                    <div className="space-y-3">
                        <h4 className="text-sm font-medium text-slate-400">Incoming Requests</h4>
                        {isOnline ? (
                            incomingRides.length > 0 ? (
                                <div className="space-y-3">
                                    {incomingRides.map((ride, i) => (
                                        <div key={i} className="rounded-2xl border border-white/10 p-4 bg-slate-800">
                                            <p className="text-xs text-emerald-400 font-bold mb-2">NEW REQUEST</p>
                                            <div className="flex justify-between items-start mb-4">
                                                <div>
                                                    <p className="font-medium text-white">{ride.pickup_address.split(',')[0]}</p>
                                                    <p className="text-sm text-slate-400">to {ride.dropoff_address.split(',')[0]}</p>
                                                </div>
                                                <p className="text-lg font-bold text-white">₹{Number(ride.estimated_fare).toFixed(0)}</p>
                                            </div>
                                            <button
                                                onClick={() => acceptRide(ride.id)}
                                                className="w-full bg-emerald-500 text-white font-bold py-3 rounded-xl active:scale-95 transition-transform"
                                            >
                                                Accept Ride
                                            </button>
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <div className="rounded-2xl border border-dashed border-slate-700 p-8 text-center bg-slate-800/30">
                                    <div className="mx-auto h-8 w-8 animate-pulse rounded-full bg-emerald-500/20 mb-3" />
                                    <p className="text-sm text-slate-400">Waiting for ride requests...</p>
                                </div>
                            )
                        ) : (
                            <div className="rounded-2xl p-6 text-center bg-slate-800/30 border border-white/5">
                                <p className="text-sm text-slate-500">Go online to receive rides.</p>
                            </div>
                        )}
                    </div>
                </div>
            </BottomSheet>
        </>
    );
}

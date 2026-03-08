import type { Coordinate } from './location';

export type RideStatus = 'REQUESTED' | 'MATCHED' | 'EN_ROUTE' | 'COMPLETED' | 'CANCELLED';

export interface Ride {
  id: string;
  passengerId: string;
  driverId: string | null;
  status: RideStatus;
  pickupLocation: Coordinate;
  dropoffLocation: Coordinate;
  pickupAddress: string;
  dropoffAddress: string;
  routePolyline: string;
  estimatedFare: number;
  actualFare: number | null;
  scheduledAt: string | null;
  startedAt: string | null;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface RideMatch {
  id: string;
  rideId: string;
  matchedRideId: string;
  overlapPercentage: number;
  detourMeters: number;
  status: 'proposed' | 'accepted' | 'rejected';
  createdAt: string;
}
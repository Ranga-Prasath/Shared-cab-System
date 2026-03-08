import { createSupabaseBrowserClient } from './supabase';

export interface ApiEnvelope<T> {
  success: boolean;
  data?: T;
  error?: string;
}

export interface RideDto {
  id: string;
  passengerId: string;
  driverId: string | null;
  status: 'REQUESTED' | 'MATCHED' | 'EN_ROUTE' | 'COMPLETED' | 'CANCELLED';
  pickupLocation: [number, number];
  dropoffLocation: [number, number];
  pickupAddress: string;
  dropoffAddress: string;
  routePolyline: string;
  estimatedFare: number;
  createdAt: string;
  updatedAt: string;
}

interface CreateRidePayload {
  pickupLocation: [number, number];
  dropoffLocation: [number, number];
  pickupAddress: string;
  dropoffAddress: string;
  scheduledAt: string;
}

const baseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

const getAuthHeaders = async (): Promise<Record<string, string>> => {
  const supabase = createSupabaseBrowserClient();
  if (!supabase) {
    return {};
  }

  const { data } = await supabase.auth.getSession();
  const token = data.session?.access_token;

  return token ? { Authorization: `Bearer ${token}` } : {};
};

const request = async <T>(path: string, init?: RequestInit): Promise<ApiEnvelope<T>> => {
  const authHeaders = await getAuthHeaders();
  const response = await fetch(`${baseUrl}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...authHeaders,
      ...(init?.headers ?? {})
    }
  });

  const body = (await response.json()) as ApiEnvelope<T>;
  return body;
};

export const apiClient = {
  listRides: (): Promise<ApiEnvelope<RideDto[]>> => request<RideDto[]>('/api/v1/rides'),
  createRide: (payload: CreateRidePayload): Promise<ApiEnvelope<RideDto>> =>
    request<RideDto>('/api/v1/rides', {
      method: 'POST',
      body: JSON.stringify(payload)
    }),
  acceptRide: (rideId: string): Promise<ApiEnvelope<RideDto>> =>
    request<RideDto>(`/api/v1/rides/${rideId}/accept`, {
      method: 'POST'
    })
};
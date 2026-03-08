export const RIDE_STATUSES = {
  REQUESTED: 'REQUESTED',
  MATCHED: 'MATCHED',
  EN_ROUTE: 'EN_ROUTE',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED'
} as const;

export type RideStatusValue = (typeof RIDE_STATUSES)[keyof typeof RIDE_STATUSES];

export const RIDE_TRANSITIONS: Record<RideStatusValue, RideStatusValue[]> = {
  REQUESTED: ['MATCHED', 'CANCELLED'],
  MATCHED: ['EN_ROUTE', 'CANCELLED'],
  EN_ROUTE: ['COMPLETED', 'CANCELLED'],
  COMPLETED: [],
  CANCELLED: []
};
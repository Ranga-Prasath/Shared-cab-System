export type Coordinate = [number, number];

export interface RouteSummary {
  distanceMeters: number;
  durationSeconds: number;
  polyline: string;
}
'use client';

import { decodePolyline } from '@shared-cab/shared';
import type { LatLngTuple } from 'leaflet';
import { Polyline } from 'react-leaflet';

export function RouteOverlay({ encodedPolyline }: { encodedPolyline: string }) {
  if (!encodedPolyline) {
    return null;
  }

  const points = decodePolyline(encodedPolyline).map(([lon, lat]) => [lat, lon] as LatLngTuple);
  if (points.length < 2) {
    return null;
  }

  return (
    <>
      <Polyline positions={points} color="rgba(34,211,238,0.28)" weight={10} pathOptions={{ className: 'route-overlay-glow' }} />
      <Polyline positions={points} color="#22d3ee" weight={4} pathOptions={{ className: 'route-overlay-core' }} />
    </>
  );
}

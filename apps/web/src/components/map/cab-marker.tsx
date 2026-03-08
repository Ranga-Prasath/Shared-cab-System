'use client';

import { useMemo } from 'react';
import { Marker, Tooltip } from 'react-leaflet';
import L from 'leaflet';
import type { LatLngTuple } from 'leaflet';

interface CabMarkerProps {
  position: LatLngTuple;
  kind: 'driver' | 'passenger';
  label: string;
}

const markerHtml = {
  driver:
    '<div style="width:18px;height:18px;border-radius:999px;background:rgba(34,211,238,0.95);border:2px solid rgba(165,243,252,0.9);box-shadow:0 0 18px rgba(34,211,238,0.8);"></div>',
  passenger:
    '<div style="width:14px;height:14px;border-radius:999px;background:rgba(168,85,247,0.9);border:2px solid rgba(233,213,255,0.9);box-shadow:0 0 14px rgba(168,85,247,0.75);"></div>'
} as const;

export function CabMarker({ position, kind, label }: CabMarkerProps) {
  const icon = useMemo(
    () =>
      new L.DivIcon({
        html: markerHtml[kind],
        className: '',
        iconSize: kind === 'driver' ? [18, 18] : [14, 14],
        iconAnchor: kind === 'driver' ? [9, 9] : [7, 7]
      }),
    [kind]
  );

  return (
    <Marker position={position} icon={icon}>
      <Tooltip>{label}</Tooltip>
    </Marker>
  );
}

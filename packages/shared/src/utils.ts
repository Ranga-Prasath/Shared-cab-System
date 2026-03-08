import type { Coordinate } from './types/location';

export const haversineDistanceMeters = (a: Coordinate, b: Coordinate): number => {
  const toRad = (deg: number): number => (deg * Math.PI) / 180;
  const [lon1, lat1] = a;
  const [lon2, lat2] = b;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const rLat1 = toRad(lat1);
  const rLat2 = toRad(lat2);

  const h =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(rLat1) * Math.cos(rLat2);

  return 6371000 * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
};

export const decodePolyline = (encoded: string): Coordinate[] => {
  const points: Coordinate[] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  while (index < encoded.length) {
    let shift = 0;
    let result = 0;
    let byte = 0;

    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    const dLat = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lat += dLat;

    shift = 0;
    result = 0;

    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    const dLng = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lng += dLng;

    points.push([lng / 1e5, lat / 1e5]);
  }

  return points;
};

export const encodePolyline = (points: Coordinate[]): string => {
  const encodeValue = (value: number): string => {
    let current = value < 0 ? ~(value << 1) : value << 1;
    let output = '';

    while (current >= 0x20) {
      output += String.fromCharCode((0x20 | (current & 0x1f)) + 63);
      current >>= 5;
    }

    output += String.fromCharCode(current + 63);
    return output;
  };

  let prevLat = 0;
  let prevLng = 0;

  return points.reduce((acc: string, [lon, lat]) => {
    const latE5 = Math.round(lat * 1e5);
    const lngE5 = Math.round(lon * 1e5);
    const encodedLat = encodeValue(latE5 - prevLat);
    const encodedLng = encodeValue(lngE5 - prevLng);
    prevLat = latE5;
    prevLng = lngE5;
    return `${acc}${encodedLat}${encodedLng}`;
  }, '');
};

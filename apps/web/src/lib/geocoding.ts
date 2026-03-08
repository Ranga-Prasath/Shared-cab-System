export interface GeocodingResult {
    lat: number;
    lon: number;
    displayName: string;
}

export async function searchAddress(query: string): Promise<GeocodingResult[]> {
    if (!query || query.trim().length < 3) return [];

    try {
        const url = new URL('https://nominatim.openstreetmap.org/search');
        url.searchParams.append('q', query);
        url.searchParams.append('format', 'json');
        url.searchParams.append('limit', '5');
        url.searchParams.append('addressdetails', '1');
        url.searchParams.append('countrycodes', 'in'); // bias to india for this demo

        const response = await fetch(url.toString(), {
            headers: {
                'Accept-Language': 'en-US,en;q=0.9',
                // Nominatim requires a user agent
                'User-Agent': 'SharedCabDemo/1.0'
            }
        });

        if (!response.ok) {
            console.error('Geocoding search failed:', response.statusText);
            return [];
        }

        const data = await response.json();

        return data.map((item: any) => ({
            lat: parseFloat(item.lat),
            lon: parseFloat(item.lon),
            displayName: item.display_name
        }));
    } catch (err) {
        console.error('Error fetching geocoding data:', err);
        return [];
    }
}

export async function reverseGeocode(lat: number, lon: number): Promise<string> {
    try {
        const url = new URL('https://nominatim.openstreetmap.org/reverse');
        url.searchParams.append('lat', lat.toString());
        url.searchParams.append('lon', lon.toString());
        url.searchParams.append('format', 'json');

        const response = await fetch(url.toString(), {
            headers: {
                'Accept-Language': 'en-US,en;q=0.9',
                'User-Agent': 'SharedCabDemo/1.0'
            }
        });

        if (!response.ok) return `${lat.toFixed(4)}, ${lon.toFixed(4)}`;

        const data = await response.json();
        return data.display_name || `${lat.toFixed(4)}, ${lon.toFixed(4)}`;
    } catch (err) {
        console.error('Reverse geocoding error:', err);
        return `${lat.toFixed(4)}, ${lon.toFixed(4)}`;
    }
}

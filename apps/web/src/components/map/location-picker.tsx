'use client';

import { useState, useRef, useEffect } from 'react';
import { searchAddress, type GeocodingResult } from '../../lib/geocoding';

interface LocationPickerProps {
    label: string;
    placeholder?: string;
    value: string;
    onChange: (address: string, lat: number, lon: number) => void;
    icon?: React.ReactNode;
}

export function LocationPicker({ label, placeholder, value, onChange, icon }: LocationPickerProps) {
    const [query, setQuery] = useState(value);
    const [results, setResults] = useState<GeocodingResult[]>([]);
    const [isOpen, setIsOpen] = useState(false);
    const [loading, setLoading] = useState(false);
    const wrapperRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        setQuery(value);
    }, [value]);

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    useEffect(() => {
        if (!query || query === value || query.trim().length < 3) {
            setResults([]);
            setIsOpen(false);
            return;
        }

        const delayDebounceFn = setTimeout(async () => {
            setLoading(true);
            const res = await searchAddress(query);
            setResults(res);
            setIsOpen(true);
            setLoading(false);
        }, 500);

        return () => clearTimeout(delayDebounceFn);
    }, [query, value]);

    const handleSelect = (r: GeocodingResult) => {
        setQuery(r.displayName);
        setIsOpen(false);
        onChange(r.displayName, r.lat, r.lon);
    };

    return (
        <div className="relative w-full" ref={wrapperRef}>
            <label className="mb-1 block text-sm font-medium text-slate-300">{label}</label>
            <div className="relative flex items-center">
                {icon && <div className="absolute left-3 text-slate-400">{icon}</div>}
                <input
                    type="text"
                    className={`w-full rounded-xl border border-slate-700 bg-slate-800/50 p-3 text-sm text-white placeholder-slate-500 transition-colors focus:border-cyan-500 focus:bg-slate-800 focus:outline-none focus:ring-1 focus:ring-cyan-500 ${icon ? 'pl-10' : ''}`}
                    placeholder={placeholder}
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    onFocus={() => { if (results.length > 0) setIsOpen(true); }}
                />
                {loading && (
                    <div className="absolute right-3 h-4 w-4 animate-spin rounded-full border-2 border-slate-500 border-t-cyan-500" />
                )}
            </div>

            {isOpen && results.length > 0 && (
                <div className="absolute z-50 mt-1 max-h-60 w-full overflow-y-auto rounded-xl border border-slate-700 bg-slate-800 p-1 shadow-2xl custom-scrollbar">
                    {results.map((r, i) => (
                        <button
                            key={i}
                            type="button"
                            className="flex w-full items-start gap-3 rounded-lg p-3 text-left transition-colors hover:bg-slate-700/50"
                            onClick={() => handleSelect(r)}
                        >
                            <svg className="mt-0.5 h-4 w-4 shrink-0 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                            </svg>
                            <div>
                                <p className="text-sm font-medium text-slate-200 line-clamp-1">{r.displayName.split(',')[0]}</p>
                                <p className="text-xs text-slate-400 line-clamp-1">{r.displayName}</p>
                            </div>
                        </button>
                    ))}
                </div>
            )}
        </div>
    );
}

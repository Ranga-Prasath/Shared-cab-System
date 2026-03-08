'use client';

import Link from 'next/link';

export function Navbar() {
  return (
    <header className="sticky top-0 z-30 border-b border-border bg-slate-950/70 backdrop-blur-md">
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3">
        <Link href="/" className="text-lg font-semibold text-cyan-300">
          Shared Cab Platform
        </Link>
        <div className="flex items-center gap-3 text-sm text-slate-300">
          <Link href="/rides" className="hover:text-cyan-300">
            Rides
          </Link>
          <Link href="/dashboard" className="hover:text-cyan-300">
            Dashboard
          </Link>
          <Link href="/auth/login" className="rounded-lg border border-border px-3 py-1 hover:border-cyan-300">
            Login
          </Link>
        </div>
      </nav>
    </header>
  );
}
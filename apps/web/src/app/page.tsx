import Link from 'next/link';

export default function HomePage() {
  return (
    <section className="relative overflow-hidden rounded-3xl border border-border p-10 glass">
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_25%_30%,rgba(34,211,238,0.22),transparent_60%)]" />
      <div className="relative space-y-6">
        <p className="inline-flex rounded-full border border-border px-4 py-1 text-xs uppercase tracking-[0.18em] text-cyan-300">
          Bangalore to Mysore Smart Pooling
        </p>
        <h1 className="max-w-3xl text-5xl font-semibold leading-tight">
          Shared Cab Platform for reliable route matching and live fleet visibility.
        </h1>
        <p className="max-w-2xl text-slate-300">
          Create rides, match passengers on overlapping routes, and watch live cab movement through Supabase Realtime.
        </p>
        <div className="flex gap-3">
          <Link href="/auth/signup" className="rounded-xl bg-cyan-400 px-6 py-3 font-medium text-slate-950">
            Get Started
          </Link>
          <Link href="/dashboard" className="rounded-xl border border-border px-6 py-3 font-medium">
            Open Dashboard
          </Link>
        </div>
      </div>
    </section>
  );
}
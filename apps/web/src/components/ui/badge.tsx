'use client';

const statusStyles: Record<string, string> = {
  REQUESTED: 'border-amber-300/40 bg-amber-500/15 text-amber-200',
  MATCHED: 'border-cyan-300/40 bg-cyan-500/15 text-cyan-200',
  EN_ROUTE: 'border-emerald-300/40 bg-emerald-500/15 text-emerald-200',
  COMPLETED: 'border-slate-300/30 bg-slate-500/20 text-slate-200',
  CANCELLED: 'border-rose-300/35 bg-rose-500/20 text-rose-200'
};

export function Badge({ label }: { label: string }) {
  const style = statusStyles[label] ?? 'border-white/20 bg-white/10 text-slate-100';
  return <span className={`inline-flex rounded-full border px-2.5 py-1 text-xs font-medium tracking-wide ${style}`}>{label}</span>;
}

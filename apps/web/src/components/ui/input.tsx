'use client';

export function Input(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} className="w-full rounded-lg border border-border bg-slate-900 px-3 py-2" />;
}
'use client';

export function Modal({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black/60">
      <div className="glass w-full max-w-md rounded-2xl p-4">
        <h3 className="mb-3 text-lg font-semibold">{title}</h3>
        {children}
      </div>
    </div>
  );
}
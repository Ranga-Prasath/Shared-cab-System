import { Suspense } from 'react';
import { DashboardShell } from '../../components/rides/dashboard-shell';

export default function DashboardPage() {
  return (
    <div className="absolute inset-0 h-screen w-screen overflow-hidden">
      <Suspense fallback={<div className="h-full w-full bg-slate-950" />}>
        <DashboardShell />
      </Suspense>
    </div>
  );
}

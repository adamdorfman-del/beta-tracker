import { useEffect, useState } from "react";
import { Link } from "wouter";
import { api } from "@/lib/api";
import { BetaStatusBadge } from "@/components/StatusBadge";
import { SlotFill } from "@/components/SlotFill";
import type { BetaStatus } from "@/lib/types";

export default function DashboardPage() {
  const [overview, setOverview] = useState<any>(null);
  const [atRisk, setAtRisk] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([api.reports.overview(), api.reports.atRisk()])
      .then(([ov, ar]) => { setOverview(ov); setAtRisk(ar); })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="py-16 text-center text-sm text-gray-400">Loading…</div>;

  const counts = overview?.featureCountsByStatus ?? {};
  const totalFeatures = Object.values(counts).reduce((a: number, b: any) => a + b, 0);
  const totalConfirmed = overview?.totalConfirmed ?? 0;
  const totalOutreach = overview?.totalOutreachSent ?? 0;
  const avgDuration = overview?.avgBetaDurationDays;
  const underFilled = atRisk?.underFilledFeatures ?? [];
  const staleApprovals = atRisk?.staleApprovals ?? [];

  const statCards = [
    { label: "Total Features",    value: totalFeatures,                              href: "/features" },
    { label: "Confirmed Testers", value: totalConfirmed,                             href: "/approvals" },
    { label: "Outreach Sent",     value: totalOutreach,                              href: "/batches" },
    { label: "Avg Beta Duration", value: avgDuration != null ? `${avgDuration}d` : "—", href: "/reports" },
  ];

  const activeStatuses: BetaStatus[] = ["recruiting", "outreach_sent", "full", "in_progress", "closing"];

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {statCards.map(({ label, value, href }) => (
          <Link key={label} href={href} className="rounded-xl border border-gray-200 bg-white p-5 hover:border-gray-300 hover:bg-gray-50 transition-colors">
            <p className="text-xs text-gray-500 uppercase tracking-wide">{label}</p>
            <p className="mt-1 text-3xl font-bold text-gray-900">{value}</p>
          </Link>
        ))}
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-5">
        <h2 className="text-sm font-semibold text-gray-700 mb-4">Active betas by status</h2>
        <div className="flex flex-wrap gap-3">
          {activeStatuses.map((s) => (
            <Link key={s} href={`/features?status=${s}`} className="flex items-center gap-2 rounded-lg border px-3 py-2 text-sm hover:bg-gray-50">
              <BetaStatusBadge status={s} />
              <span className="font-semibold text-gray-900">{counts[s] ?? 0}</span>
            </Link>
          ))}
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <section>
          <h2 className="mb-3 text-sm font-semibold text-gray-700">
            Under-filled within 5 days of start
            {underFilled.length > 0 && (
              <span className="ml-2 rounded-full bg-amber-100 px-2 py-0.5 text-xs text-amber-700">
                {underFilled.length}
              </span>
            )}
          </h2>
          {underFilled.length === 0 ? (
            <p className="text-sm text-gray-400">None — all betas on track.</p>
          ) : (
            <div className="space-y-2">
              {underFilled.map((f: any) => (
                <Link
                  key={f.id}
                  href={`/features/${f.id}`}
                  className="flex items-center justify-between rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 hover:bg-amber-100"
                >
                  <div>
                    <p className="text-sm font-medium text-gray-900">{f.name}</p>
                    <p className="text-xs text-gray-500">PM: {f.ownerPm?.name} · starts {new Date(f.startDate).toLocaleDateString()}</p>
                  </div>
                  <SlotFill confirmed={f.confirmedCount} target={f.target} />
                </Link>
              ))}
            </div>
          )}
        </section>

        <section>
          <h2 className="mb-3 text-sm font-semibold text-gray-700">
            Approvals pending 48h+
            {staleApprovals.length > 0 && (
              <span className="ml-2 rounded-full bg-red-100 px-2 py-0.5 text-xs text-red-700">
                {staleApprovals.length}
              </span>
            )}
          </h2>
          {staleApprovals.length === 0 ? (
            <p className="text-sm text-gray-400">No stale approvals.</p>
          ) : (
            <div className="space-y-2">
              {staleApprovals.map((e: any) => (
                <Link
                  key={e.enrollmentId}
                  href="/approvals"
                  className="flex items-center justify-between rounded-lg border border-red-200 bg-red-50 px-4 py-3 hover:bg-red-100"
                >
                  <div>
                    <p className="text-sm font-medium text-gray-900">{e.client?.name}</p>
                    <p className="text-xs text-gray-500">
                      {e.feature?.name} · CSM: {e.csmOwner?.name}
                    </p>
                  </div>
                  <span className="text-xs font-medium text-red-700 whitespace-nowrap">{e.pendingSinceHours}h pending</span>
                </Link>
              ))}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

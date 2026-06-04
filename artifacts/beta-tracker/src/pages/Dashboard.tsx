import { useEffect, useState } from "react";
import { Link, useLocation } from "wouter";
import { UserPlus, CheckCircle2, MessageSquare, UserMinus, Activity } from "lucide-react";
import { api } from "@/lib/api";
import { BetaStatusBadge } from "@/components/StatusBadge";
import type { BetaStatus } from "@/lib/types";

// ── helpers ──────────────────────────────────────────────────────────────────

function relTime(dateStr: string | Date): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "Just now";
  if (mins < 60) return `${mins} minute${mins === 1 ? "" : "s"} ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours} hour${hours === 1 ? "" : "s"} ago`;
  const days = Math.floor(hours / 24);
  if (days === 1) return "Yesterday";
  return `${days} days ago`;
}

function fmt(date: string) {
  return new Date(date + 'T00:00:00').toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
}

// ── activity config ───────────────────────────────────────────────────────────

const ACTION_CONFIG: Record<string, { icon: React.ComponentType<any>; iconCls: string }> = {
  nominated:       { icon: UserPlus,      iconCls: "bg-purple-100 text-purple-600" },
  csm_approved:    { icon: CheckCircle2,  iconCls: "bg-green-100 text-green-600"   },
  csm_rejected:    { icon: UserMinus,     iconCls: "bg-red-100 text-red-600"       },
  feedback_logged: { icon: MessageSquare, iconCls: "bg-blue-100 text-blue-600"     },
  removed:         { icon: UserMinus,     iconCls: "bg-red-100 text-red-600"       },
  dropped:         { icon: UserMinus,     iconCls: "bg-red-100 text-red-600"       },
  approved:        { icon: CheckCircle2,  iconCls: "bg-green-100 text-green-600"   },
};

function ActivityDescription({ act }: { act: any }) {
  const client = act.clientName ? <span className="font-medium text-gray-900">{act.clientName}</span> : null;
  const feature = act.featureName ?? null;

  switch (act.action) {
    case "nominated":
      return <span className="text-sm text-gray-600">Enrollment added for {client}{feature ? <> in {feature}</> : null}</span>;
    case "csm_approved":
    case "approved":
      return <span className="text-sm text-gray-600">CSM approved {client}{feature ? <> for {feature}</> : null}</span>;
    case "csm_rejected":
      return <span className="text-sm text-gray-600">CSM rejected {client}{feature ? <> from {feature}</> : null}</span>;
    case "removed":
    case "dropped":
      return <span className="text-sm text-gray-600">{client}{feature ? <> removed from {feature}</> : " removed"}</span>;
    case "feedback_logged":
      return <span className="text-sm text-gray-600">Feedback logged for {client}{feature ? <> in {feature}</> : null}</span>;
    default: {
      const label = act.action.replace(/_/g, " ").replace(/^\w/, (c: string) => c.toUpperCase());
      return <span className="text-sm text-gray-600">{label}{client ? <> for {client}</> : null}{feature ? <> in {feature}</> : null}</span>;
    }
  }
}

// ── card shell ────────────────────────────────────────────────────────────────

function Card({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={`rounded-xl border border-gray-200 bg-white p-5 ${className}`}>
      {children}
    </div>
  );
}

function CardTitle({ children, href }: { children: React.ReactNode; href?: string }) {
  const cls = "text-sm font-semibold text-gray-700";
  if (href) return <Link href={href} className={`${cls} hover:text-blue-600 hover:underline`}>{children}</Link>;
  return <h2 className={cls}>{children}</h2>;
}

// ── page ─────────────────────────────────────────────────────────────────────

export default function DashboardPage() {
  const [overview, setOverview]               = useState<any>(null);
  const [atRisk, setAtRisk]                   = useState<any>(null);
  const [me, setMe]                           = useState<any>(null);
  const [myFeatures, setMyFeatures]           = useState<any[]>([]);
  const [feedbackSummary, setFeedbackSummary] = useState<any>(null);
  const [sentimentByBeta, setSentimentByBeta] = useState<any[]>([]);
  const [activity, setActivity]               = useState<any[]>([]);
  const [loading, setLoading]                 = useState(true);
  const [location] = useLocation();

  useEffect(() => {
    setLoading(true);
    const meLoad = api.me.get().then(async (d: any) => {
      setMe(d.user);
      const r = await api.features.list({ owner: d.user.id, limit: "5" });
      setMyFeatures(r.features ?? []);
    });
    Promise.allSettled([
      meLoad,
      api.reports.overview().then(setOverview),
      api.reports.atRisk().then(setAtRisk),
      api.feedback.summary().then(setFeedbackSummary),
      api.reports.sentimentByBeta().then((d: any) => setSentimentByBeta(d.features ?? [])),
      api.reports.activity().then((d: any) => setActivity(d.activities ?? [])),
    ]).finally(() => setLoading(false));
  }, [location]);

  if (loading) return <div className="py-16 text-center text-sm text-gray-400">Loading…</div>;

  // ── stat card data ──
  const counts       = overview?.featureCountsByStatus ?? {};
  const totalFeatures = Object.values(counts).reduce((a: number, b: any) => a + b, 0);
  const avgDuration  = overview?.avgBetaDurationDays;

  const statCards = [
    { label: "Total Beta Features", value: totalFeatures,                                   href: "/features" },
    { label: "Enrolled + Using",    value: overview?.totalInProgress ?? 0,                  href: "/features" },
    { label: "Accepted",            value: overview?.totalAccepted ?? 0,                    href: "/features" },
    { label: "Nominated",           value: overview?.totalNominated ?? 0,                   href: "/features" },
    { label: "Avg Beta Duration",   value: avgDuration != null ? `${avgDuration}d` : "—",  href: "/reports" },
  ];

  // ── features by stage ──
  const stageStatuses: BetaStatus[] = ["draft", "in_progress", "complete"];

  // ── sentiment ──
  const totals      = feedbackSummary?.totals ?? { total: 0, positive: 0, neutral: 0, negative: 0 };
  const posRate     = totals.total > 0 ? Math.round((totals.positive / totals.total) * 100) : 0;
  const sentimentColor = posRate >= 80 ? '#1D9E75' : posRate >= 60 ? '#EF9F27' : '#E24B4A';

  // ── sentiment by beta ──
  const MAX_ROWS = 8;
  const hasTooMany = sentimentByBeta.length > MAX_ROWS;
  // If > 8 active betas, keep the 8 with most responses; then sort by rate asc, nulls last
  const sentimentRows: any[] = (() => {
    const pool = hasTooMany
      ? [...sentimentByBeta].sort((a, b) => b.total - a.total).slice(0, MAX_ROWS)
      : [...sentimentByBeta];
    return pool.sort((a, b) => {
      if (a.positiveRate === null && b.positiveRate === null) return 0;
      if (a.positiveRate === null) return 1;
      if (b.positiveRate === null) return -1;
      return a.positiveRate - b.positiveRate;
    });
  })();

  // ── stale approvals ──
  const staleApprovals = atRisk?.staleApprovals ?? [];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>

      {/* Row 1 — stat cards */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4 xl:grid-cols-5">
        {statCards.map(({ label, value, href }) => (
          <Link key={label} href={href}
            className="rounded-xl border border-gray-200 bg-white p-5 hover:border-gray-300 hover:bg-gray-50 transition-colors">
            <p className="text-xs text-gray-500 uppercase tracking-wide">{label}</p>
            <p className="mt-1 text-3xl font-bold text-gray-900">{value}</p>
          </Link>
        ))}
      </div>

      {/* Row 2 — Features by Stage + My Betas */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Features by Stage */}
        <Card>
          <CardTitle>Features by stage</CardTitle>
          <div className="mt-4 flex flex-wrap gap-3">
            {stageStatuses.map((s) => (
              <Link key={s} href={`/features?status=${s}`}
                className="flex items-center gap-2 rounded-lg border px-3 py-2 text-sm hover:bg-gray-50 transition-colors">
                <BetaStatusBadge status={s} />
                <span className="font-semibold text-gray-900">{counts[s] ?? 0}</span>
              </Link>
            ))}
          </div>
        </Card>

        {/* My Betas */}
        <Card>
          <CardTitle href={me ? `/features?owner=${me.id}` : "/features"}>My Betas</CardTitle>
          <div className="mt-4">
            {myFeatures.length === 0 ? (
              <p className="text-sm text-gray-400">No features assigned to you yet.</p>
            ) : (
              <div className="divide-y divide-gray-100">
                {myFeatures.map((f: any) => (
                  <Link key={f.id} href={`/features/${f.slug ?? f.id}`}
                    className="flex items-center justify-between py-2.5 hover:bg-gray-50 -mx-2 px-2 rounded-lg transition-colors">
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-gray-900 truncate">{f.name}</p>
                      <p className="text-xs text-gray-400">
                        {(f as any).projectedEndDate ? `Ends ${fmt((f as any).projectedEndDate)}` : fmt(f.startDate)}
                      </p>
                    </div>
                    <div className="flex items-center gap-3 ml-3 shrink-0">
                      <BetaStatusBadge status={f.status} />
                      <span className="text-xs text-gray-400 whitespace-nowrap">
                        {(f as any).enrollmentFunnel?.total ?? (f as any).filledCount ?? 0} enrolled
                      </span>
                    </div>
                  </Link>
                ))}
              </div>
            )}
          </div>
        </Card>
      </div>

      {/* Row 3 — Sentiment + Needing Attention + Approvals */}
      <div className="grid gap-6 lg:grid-cols-3">
        {/* Sentiment Snapshot */}
        <Card>
          <CardTitle href="/feedback">Sentiment Snapshot</CardTitle>
          <div className="mt-4">
            {totals.total === 0 ? (
              <p className="text-sm text-gray-400">No feedback logged yet.</p>
            ) : (
              <>
                <p className="text-4xl font-bold" style={{ color: sentimentColor }}>{posRate}%</p>
                <p className="mt-1 text-xs text-gray-400">positive across all active betas</p>
                <div className="mt-3 h-2 w-full rounded-full bg-gray-100 overflow-hidden">
                  <div className="h-full rounded-full transition-all" style={{ width: `${posRate}%`, backgroundColor: sentimentColor }} />
                </div>
                <div className="mt-3 flex flex-wrap gap-4 text-xs text-gray-500">
                  <span><span className="font-medium text-green-700">{totals.positive}</span> positive</span>
                  <span><span className="font-medium text-red-700">{totals.negative}</span> negative</span>
                  <span><span className="font-medium text-gray-700">{totals.neutral}</span> neutral</span>
                  <span><span className={`font-medium ${(totals.gating ?? 0) > 0 ? "text-red-700" : "text-gray-700"}`}>{totals.gating ?? 0}</span> blocking</span>
                </div>
              </>
            )}
          </div>
        </Card>

        {/* Sentiment by Beta */}
        <Card>
          <CardTitle href="/feedback">Sentiment by Beta</CardTitle>
          <div className="mt-3">
            {sentimentByBeta.length === 0 ? (
              <p className="text-sm text-gray-400">No active betas.</p>
            ) : (
              <>
                <table className="w-full text-xs">
                  <thead>
                    <tr className="border-b border-gray-100">
                      <th className="pb-1.5 text-left font-medium text-gray-400">Feature</th>
                      <th className="pb-1.5 text-right font-medium text-gray-400 pr-3">Responses</th>
                      <th className="pb-1.5 text-left font-medium text-gray-400 w-28">Positive rate</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-50">
                    {sentimentRows.map((f: any) => {
                      const pct = f.positiveRate !== null ? Math.round(f.positiveRate * 100) : null;
                      const rateColor = pct === null ? undefined : pct >= 80 ? '#1D9E75' : pct >= 60 ? '#EF9F27' : '#E24B4A';
                      return (
                        <tr key={f.id} className="group">
                          <td className="py-2 pr-2 max-w-0">
                            <span
                              className="block font-medium text-gray-900 break-words leading-snug"
                              title={f.name.length > 40 ? f.name : undefined}
                            >
                              {f.name}
                            </span>
                          </td>
                          <td className="py-2 pr-3 text-right text-gray-500 shrink-0">
                            {f.total > 0 ? f.total : <span className="text-gray-300">—</span>}
                          </td>
                          <td className="py-2 w-28">
                            {pct === null ? (
                              <span className="text-gray-300">—</span>
                            ) : (
                              <div className="flex items-center gap-1.5">
                                <div className="h-1.5 w-16 rounded-full bg-gray-100 overflow-hidden shrink-0">
                                  <div className="h-full rounded-full" style={{ width: `${pct}%`, backgroundColor: rateColor }} />
                                </div>
                                <span className="font-medium shrink-0" style={{ color: rateColor }}>{pct}%</span>
                              </div>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
                {hasTooMany && (
                  <div className="mt-2 text-right">
                    <Link href="/feedback" className="text-xs text-gray-400 hover:text-gray-600">View all →</Link>
                  </div>
                )}
              </>
            )}
          </div>
        </Card>

        {/* Approvals Pending 2d+ */}
        <Card>
          <div className="flex items-center gap-2 mb-4">
            <CardTitle>Approvals pending 2d+</CardTitle>
            {staleApprovals.length > 0 && (
              <span className="rounded-full bg-red-100 px-2 py-0.5 text-xs text-red-700 font-medium">
                {staleApprovals.length}
              </span>
            )}
          </div>
          {staleApprovals.length === 0 ? (
            <p className="text-sm text-gray-400">No stale approvals.</p>
          ) : (
            <div className="space-y-2">
              {staleApprovals.map((e: any) => (
                <Link key={e.enrollmentId} href={`/features/${e.feature?.slug ?? e.feature?.id ?? ""}`}
                  className="flex items-center justify-between rounded-lg border border-red-200 bg-red-50 px-4 py-3 hover:bg-red-100 transition-colors">
                  <div>
                    <p className="text-sm font-medium text-gray-900">{e.client?.name}</p>
                    <p className="text-xs text-gray-500">{e.feature?.name} · CSM: {e.csmOwner?.name}</p>
                  </div>
                  <span className="text-xs font-medium text-red-700 whitespace-nowrap">{e.pendingSinceDays}d pending</span>
                </Link>
              ))}
            </div>
          )}
        </Card>
      </div>

      {/* Row 4 — Recent Activity */}
      <Card>
        <div className="flex items-center gap-2 mb-4">
          <Activity className="h-4 w-4 text-gray-400" />
          <CardTitle>Recent Activity</CardTitle>
        </div>
        {activity.length === 0 ? (
          <p className="text-sm text-gray-400">No recent activity.</p>
        ) : (
          <div className="divide-y divide-gray-100">
            {activity.map((act: any) => {
              const cfg = ACTION_CONFIG[act.action] ?? { icon: Activity, iconCls: "bg-gray-100 text-gray-500" };
              const Icon = cfg.icon;
              return (
                <div key={act.id} className="flex items-start gap-3 py-3">
                  <div className={`mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full ${cfg.iconCls}`}>
                    <Icon className="h-3.5 w-3.5" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <ActivityDescription act={act} />
                  </div>
                  <span className="shrink-0 text-xs text-gray-400 whitespace-nowrap">{relTime(act.createdAt)}</span>
                </div>
              );
            })}
          </div>
        )}
      </Card>
    </div>
  );
}

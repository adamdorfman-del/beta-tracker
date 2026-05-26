import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid,
  FunnelChart, Funnel, LabelList, Cell,
} from "recharts";

function DurationChart({ data }: { data: { name: string; days: number }[] }) {
  return (
    <ResponsiveContainer width="100%" height={220}>
      <BarChart data={data} margin={{ top: 4, right: 4, left: -20, bottom: 40 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
        <XAxis dataKey="name" tick={{ fontSize: 10 }} angle={-35} textAnchor="end" />
        <YAxis tick={{ fontSize: 10 }} unit="d" />
        <Tooltip formatter={(v: any) => [`${v} days`, "Duration"]} />
        <Bar dataKey="days" fill="#6366f1" radius={[3, 3, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}

function ConversionFunnel({ data }: { data: { name: string; value: number }[] }) {
  const COLORS = ["#6366f1", "#8b5cf6", "#a78bfa", "#c4b5fd", "#ddd6fe"];
  return (
    <ResponsiveContainer width="100%" height={220}>
      <FunnelChart>
        <Tooltip />
        <Funnel dataKey="value" data={data} isAnimationActive>
          {data.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
          <LabelList position="right" dataKey="name" fill="#374151" style={{ fontSize: 11 }} />
        </Funnel>
      </FunnelChart>
    </ResponsiveContainer>
  );
}

function CompletionBarChart({ data }: { data: { name: string; rate: number }[] }) {
  return (
    <ResponsiveContainer width="100%" height={220}>
      <BarChart data={data} layout="vertical" margin={{ top: 4, right: 20, left: 80, bottom: 4 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
        <XAxis type="number" domain={[0, 100]} tick={{ fontSize: 10 }} unit="%" />
        <YAxis type="category" dataKey="name" tick={{ fontSize: 10 }} width={80} />
        <Tooltip formatter={(v: any) => [`${v}%`, "Completion rate"]} />
        <Bar dataKey="rate" fill="#10b981" radius={[0, 3, 3, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}

export default function ReportsPage() {
  const [features, setFeatures] = useState<any[]>([]);
  const [clients, setClients] = useState<any[]>([]);
  const [csms, setCsms] = useState<any[]>([]);
  const [overview, setOverview] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.reports.features(),
      api.reports.clients(),
      api.reports.csmResponsiveness(),
      api.reports.overview(),
    ]).then(([f, c, csm, ov]) => {
      setFeatures(f.features ?? []);
      setClients(c.clients ?? []);
      setCsms(csm.csms ?? []);
      setOverview(ov);
    }).catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="py-16 text-center text-sm text-gray-400">Loading…</div>;

  const closedFeatures = features.filter((f) => f.status === "complete" && f.closedAt);
  const durationData = closedFeatures.map((f) => ({
    name: f.name.replace(/^Project /, ""),
    days: f.durationDays ?? 0,
  })).slice(0, 20);

  const totalCompleted = clients.reduce((s: number, c: any) => s + (c.completed ?? 0), 0);

  const funnelData = [
    { name: "Outreach Sent", value: overview?.totalOutreachSent ?? 0 },
    { name: "Confirmed", value: overview?.totalConfirmed ?? 0 },
    { name: "Completed", value: totalCompleted },
  ].filter((d) => d.value > 0);

  const clientCompletion = clients
    .filter((c) => c.totalEnrollments > 0)
    .map((c) => ({
      name: c.name,
      rate: c.completionRate != null ? Math.round(c.completionRate * 100) : 0,
      total: c.totalEnrollments,
      done: c.completed,
    }))
    .sort((a, b) => b.rate - a.rate)
    .slice(0, 10);

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-semibold text-gray-900">Reports</h1>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="text-sm font-semibold text-gray-700 mb-4">Beta duration (closed betas, days)</h2>
          {durationData.length > 0
            ? <DurationChart data={durationData} />
            : <p className="text-sm text-gray-400 py-8 text-center">No closed betas yet.</p>}
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="text-sm font-semibold text-gray-700 mb-4">Outreach conversion funnel</h2>
          {funnelData.length > 0
            ? <ConversionFunnel data={funnelData} />
            : <p className="text-sm text-gray-400 py-8 text-center">No data yet.</p>}
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="text-sm font-semibold text-gray-700 mb-4">Client completion rate (top 10)</h2>
          {clientCompletion.length > 0
            ? <CompletionBarChart data={clientCompletion} />
            : <p className="text-sm text-gray-400 py-8 text-center">No data yet.</p>}
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="text-sm font-semibold text-gray-700 mb-4">CSM avg approval time</h2>
          {csms.length > 0 ? (
            <table className="min-w-full divide-y divide-gray-100">
              <thead>
                <tr>
                  <th className="py-2 text-left text-xs font-medium text-gray-500">CSM</th>
                  <th className="py-2 text-right text-xs font-medium text-gray-500">Approvals</th>
                  <th className="py-2 text-right text-xs font-medium text-gray-500">Avg time</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {csms.map((r: any) => (
                  <tr key={r.id}>
                    <td className="py-2 text-sm text-gray-900">{r.name}</td>
                    <td className="py-2 text-right text-sm text-gray-600">{r.count}</td>
                    <td className="py-2 text-right text-sm font-medium text-gray-900">{r.avgHours}h</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <p className="text-sm text-gray-400 py-8 text-center">No approvals yet.</p>
          )}
        </div>
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-5">
        <h2 className="text-sm font-semibold text-gray-700 mb-4">Client participation leaderboard</h2>
        <table className="min-w-full divide-y divide-gray-100">
          <thead>
            <tr>
              <th className="py-2 text-left text-xs font-medium text-gray-500">Client</th>
              <th className="py-2 text-right text-xs font-medium text-gray-500">Total betas</th>
              <th className="py-2 text-right text-xs font-medium text-gray-500">Completed</th>
              <th className="py-2 text-right text-xs font-medium text-gray-500">Completion rate</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {clientCompletion.map((c) => (
              <tr key={c.name}>
                <td className="py-2 text-sm text-gray-900">{c.name}</td>
                <td className="py-2 text-right text-sm text-gray-600">{c.total}</td>
                <td className="py-2 text-right text-sm text-gray-600">{c.done}</td>
                <td className="py-2 text-right text-sm font-medium text-gray-900">{c.rate}%</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

import { useEffect, useState } from "react";
import { Link, useSearch } from "wouter";
import { api } from "@/lib/api";
import { BatchStatusBadge } from "@/components/StatusBadge";
import { HealthDot } from "@/components/HealthDot";
import type { OutreachBatch } from "@/lib/types";

export default function BatchesPage() {
  const searchString = useSearch();
  const page = Math.max(1, parseInt(new URLSearchParams(searchString).get("page") ?? "1", 10));
  const take = 20;
  const skip = (page - 1) * take;

  const [batches, setBatches] = useState<OutreachBatch[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    api.batches.list({ page: String(page), limit: String(take) })
      .then((d) => { setBatches(d.batches); setTotal(d.total); })
      .catch(console.error)
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, [page]);

  async function trigger() {
    try { await api.batches.trigger(); load(); }
    catch (e: any) { alert(e.data?.error ?? "Failed"); }
  }

  async function sendBatch(id: string, overrideCooldown = false) {
    if (!confirm("Send this outreach batch?")) return;
    try {
      await api.batches.send(id, { overrideCooldown });
      load();
    } catch (e: any) {
      const errData = (e as any).data ?? {};
      if (errData.cooldown) {
        const ok = confirm(`${errData.error}\n\nOverride cooldown and send?`);
        if (ok) { await api.batches.send(id, { overrideCooldown: true }); load(); }
      } else {
        alert(errData.error ?? "Failed");
      }
    }
  }

  const staleThreshold = new Date(Date.now() - 48 * 3600000);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <h1 className="text-2xl font-semibold text-gray-900">Outreach</h1>
        <button onClick={trigger}
          className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50">
          Trigger Batch Grouping
        </button>
      </div>

      {loading ? (
        <div className="py-12 text-center text-sm text-gray-400">Loading…</div>
      ) : (
        <div className="space-y-4">
          {batches.map((b) => {
            const isStale = b.batchStatus !== "sent" && new Date(b.createdAt) < staleThreshold;
            const featureNames = [...new Set((b.enrollments ?? []).map((be) => be.enrollment?.feature?.name).filter(Boolean))];
            const pendingApprovals = (b.enrollments ?? []).filter(be => be.enrollment?.csmApprovedBy === null).length;

            return (
              <div key={b.id}
                className={`rounded-xl border bg-white p-5 space-y-3 ${isStale ? "border-red-200" : "border-gray-200"}`}>
                <div className="flex items-start justify-between flex-wrap gap-3">
                  <div className="flex items-center gap-3">
                    <HealthDot health={b.client?.accountHealth ?? "green"} />
                    <div>
                      <p className="text-sm font-semibold text-gray-900">{b.client?.name}</p>
                      <p className="text-xs text-gray-400">Tier {b.client?.tier}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <BatchStatusBadge status={b.batchStatus} />
                    {isStale && <span className="text-xs font-medium text-red-600">Pending 48h+</span>}
                    {b.batchStatus !== "sent" && (
                      <button onClick={() => sendBatch(b.id)}
                        className="rounded-lg bg-blue-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-blue-700">
                        Send
                      </button>
                    )}
                  </div>
                </div>

                <div className="flex flex-wrap gap-1.5">
                  {featureNames.map((name) => (
                    <span key={name} className="rounded-full bg-gray-100 px-2.5 py-0.5 text-xs text-gray-600">{name}</span>
                  ))}
                </div>

                <div className="flex flex-wrap items-center gap-x-6 gap-y-1 text-xs text-gray-500">
                  <span>{(b.enrollments ?? []).length} enrollment{(b.enrollments ?? []).length !== 1 ? "s" : ""}</span>
                  {pendingApprovals > 0 && (
                    <span className="text-amber-600">{pendingApprovals} CSM approval{pendingApprovals !== 1 ? "s" : ""} pending</span>
                  )}
                  <span>Created {new Date(b.createdAt).toLocaleDateString()}</span>
                  {b.sentAt && <span>Sent {new Date(b.sentAt).toLocaleDateString()} by {b.sentBy?.name}</span>}
                  {b.client?.lastOutreachDate && (
                    <span>Last outreach: {new Date(b.client.lastOutreachDate).toLocaleDateString()}</span>
                  )}
                </div>
              </div>
            );
          })}
          {batches.length === 0 && (
            <div className="rounded-xl border border-gray-200 bg-white py-16 text-center">
              <p className="text-lg text-gray-400">No batches yet.</p>
              <p className="text-sm text-gray-300 mt-1">Trigger batch grouping to create batches from approved enrollments.</p>
            </div>
          )}
        </div>
      )}

      {total > take && (
        <div className="flex items-center justify-between text-sm text-gray-600">
          <span>Showing {skip + 1}–{Math.min(skip + take, total)} of {total}</span>
          <div className="flex gap-2">
            {page > 1 && <Link href={`/batches?page=${page - 1}`} className="rounded border px-3 py-1 hover:bg-gray-50">← Prev</Link>}
            {skip + take < total && <Link href={`/batches?page=${page + 1}`} className="rounded border px-3 py-1 hover:bg-gray-50">Next →</Link>}
          </div>
        </div>
      )}
    </div>
  );
}

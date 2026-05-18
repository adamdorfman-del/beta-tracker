import { useEffect, useState } from "react";
import { Link, useSearch } from "wouter";
import { api } from "@/lib/api";
import { HealthDot } from "@/components/HealthDot";
import type { BetaEnrollment } from "@/lib/types";

function ApproveRejectButtons({ enrollmentId, onDone }: { enrollmentId: string; onDone: () => void }) {
  const [showReject, setShowReject] = useState(false);
  const [reason, setReason] = useState("");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  async function approve() {
    setPending(true); setError("");
    try { await api.enrollments.approve(enrollmentId); onDone(); }
    catch (e: any) { setError(e.data?.error ?? "Failed"); }
    finally { setPending(false); }
  }

  async function reject() {
    if (!reason.trim()) { setError("Reason required."); return; }
    setPending(true); setError("");
    try { await api.enrollments.reject(enrollmentId, { reason }); setShowReject(false); onDone(); }
    catch (e: any) { setError(e.data?.error ?? "Failed"); }
    finally { setPending(false); }
  }

  if (showReject) {
    return (
      <div className="space-y-1">
        <input autoFocus value={reason} onChange={(e) => setReason(e.target.value)}
          placeholder="Rejection reason…"
          className="w-full rounded border border-gray-200 px-2 py-1 text-xs outline-none focus:border-red-300" />
        {error && <p className="text-xs text-red-600">{error}</p>}
        <div className="flex gap-1">
          <button onClick={reject} disabled={pending}
            className="rounded bg-red-600 px-2 py-1 text-xs font-medium text-white hover:bg-red-700 disabled:opacity-50">Confirm</button>
          <button onClick={() => { setShowReject(false); setError(""); }}
            className="rounded border px-2 py-1 text-xs text-gray-600 hover:bg-gray-50">Cancel</button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex gap-1">
      {error && <p className="text-xs text-red-600 mr-1">{error}</p>}
      <button onClick={approve} disabled={pending}
        className="rounded bg-green-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-green-700 disabled:opacity-50">Approve</button>
      <button onClick={() => setShowReject(true)} disabled={pending}
        className="rounded border border-red-200 px-2.5 py-1 text-xs font-medium text-red-600 hover:bg-red-50 disabled:opacity-50">Reject</button>
    </div>
  );
}

export default function ApprovalsPage() {
  const searchString = useSearch();
  const page = Math.max(1, parseInt(new URLSearchParams(searchString).get("page") ?? "1", 10));
  const take = 30;
  const skip = (page - 1) * take;

  const [enrollments, setEnrollments] = useState<BetaEnrollment[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    api.enrollments.list({ approvalStatus: "pending", page: String(page), limit: String(take) })
      .then((d) => { setEnrollments(d.enrollments); setTotal(d.total); })
      .catch(console.error)
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, [page]);

  const staleThreshold = Date.now() - 48 * 3600000;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Approvals</h1>
          <p className="text-sm text-gray-500 mt-0.5">
            {total} pending nomination{total !== 1 ? "s" : ""}
          </p>
        </div>
      </div>

      {loading ? (
        <div className="py-12 text-center text-sm text-gray-400">Loading…</div>
      ) : (
        <div className="space-y-3">
          {enrollments.map((e) => {
            const isStale = new Date(e.createdAt).getTime() < staleThreshold;
            const hours = Math.round((Date.now() - new Date(e.createdAt).getTime()) / 3600000);
            return (
              <div key={e.id}
                className={`rounded-xl border bg-white p-4 ${isStale ? "border-amber-200 bg-amber-50/30" : "border-gray-200"}`}>
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <HealthDot health={e.client?.accountHealth ?? "green"} />
                      <p className="text-sm font-semibold text-gray-900">{e.client?.name}</p>
                      {isStale && (
                        <span className="rounded-full bg-amber-100 px-2 py-0.5 text-xs text-amber-700">
                          {hours}h pending
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-gray-600">
                      Feature: <Link href={`/features/${e.featureId}`} className="text-blue-600 hover:underline">
                        {e.feature?.name ?? e.featureId}
                      </Link>
                    </p>
                    {(e as any).feature?.idealClientCriteria && (
                      <p className="text-xs text-gray-400">Criteria: {(e as any).feature.idealClientCriteria}</p>
                    )}
                    <p className="text-xs text-gray-400">
                      CSM: {e.client?.csmOwner?.name ?? "—"} · Assigned by: {(e as any).assignedBy?.name ?? "—"}
                    </p>
                  </div>
                  <ApproveRejectButtons enrollmentId={e.id} onDone={load} />
                </div>
              </div>
            );
          })}
          {enrollments.length === 0 && (
            <div className="rounded-xl border border-gray-200 bg-white py-16 text-center">
              <p className="text-gray-400">No pending approvals.</p>
            </div>
          )}
        </div>
      )}

      {total > take && (
        <div className="flex items-center justify-between text-sm text-gray-600">
          <span>Showing {skip + 1}–{Math.min(skip + take, total)} of {total}</span>
          <div className="flex gap-2">
            {page > 1 && <Link href={`/approvals?page=${page - 1}`} className="rounded border px-3 py-1 hover:bg-gray-50">← Prev</Link>}
            {skip + take < total && <Link href={`/approvals?page=${page + 1}`} className="rounded border px-3 py-1 hover:bg-gray-50">Next →</Link>}
          </div>
        </div>
      )}
    </div>
  );
}

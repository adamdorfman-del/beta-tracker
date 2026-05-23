import { useEffect, useState } from "react";
import { Link, useLocation } from "wouter";
import { api } from "@/lib/api";
import { BetaStatusBadge, TesterStatusBadge, ApprovalStatusBadge } from "@/components/StatusBadge";
import { HealthDot } from "@/components/HealthDot";
import { SlotFill } from "@/components/SlotFill";
import { EditFeatureModal } from "@/components/EditFeatureModal";
import type { BetaFeature, BetaEnrollment, Client } from "@/lib/types";
import { useCurrentUser, canWrite } from "@/hooks/useCurrentUser";

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
            className="rounded bg-red-600 px-2 py-1 text-xs font-medium text-white hover:bg-red-700 disabled:opacity-50">
            Confirm
          </button>
          <button onClick={() => { setShowReject(false); setError(""); }}
            className="rounded border px-2 py-1 text-xs text-gray-600 hover:bg-gray-50">
            Cancel
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex gap-1">
      {error && <p className="text-xs text-red-600 mr-1">{error}</p>}
      <button onClick={approve} disabled={pending}
        className="rounded bg-green-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-green-700 disabled:opacity-50">
        Approve
      </button>
      <button onClick={() => setShowReject(true)} disabled={pending}
        className="rounded border border-red-200 px-2.5 py-1 text-xs font-medium text-red-600 hover:bg-red-50 disabled:opacity-50">
        Reject
      </button>
    </div>
  );
}

function RemoveButton({ enrollmentId, onDone }: { enrollmentId: string; onDone: () => void }) {
  const [pending, setPending] = useState(false);
  async function remove() {
    if (!confirm("Remove this nomination?")) return;
    setPending(true);
    try { await api.enrollments.remove(enrollmentId); onDone(); }
    catch (e: any) { alert(e.data?.error ?? "Failed"); }
    finally { setPending(false); }
  }
  return (
    <button onClick={remove} disabled={pending}
      className="text-xs text-red-500 hover:text-red-700 disabled:opacity-50">
      Remove
    </button>
  );
}

function CloseFeatureButton({ featureId, onDone }: { featureId: string; onDone: () => void }) {
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState("completed");
  const [notes, setNotes] = useState("");
  const [force, setForce] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  async function close() {
    setPending(true); setError("");
    try {
      await api.features.close(featureId, { closeReason: reason, closeNotes: notes, force });
      setOpen(false); onDone();
    } catch (e: any) { setError(e.data?.error ?? "Failed"); }
    finally { setPending(false); }
  }

  if (!open) return (
    <button onClick={() => setOpen(true)}
      className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50">
      Close Beta
    </button>
  );

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl space-y-4">
        <h2 className="text-base font-semibold text-gray-900">Close Beta</h2>
        <div className="space-y-1">
          <label className="text-xs font-medium text-gray-700">Reason</label>
          <select value={reason} onChange={(e) => setReason(e.target.value)}
            className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm">
            <option value="completed">Completed</option>
            <option value="cancelled">Cancelled</option>
            <option value="merged">Merged</option>
            <option value="paused">Paused</option>
          </select>
        </div>
        <div className="space-y-1">
          <label className="text-xs font-medium text-gray-700">Notes (optional)</label>
          <textarea value={notes} onChange={(e) => setNotes(e.target.value)} rows={2}
            className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none" />
        </div>
        <label className="flex items-center gap-2 text-sm text-gray-700">
          <input type="checkbox" checked={force} onChange={(e) => setForce(e.target.checked)} />
          Force close (drops active testers immediately)
        </label>
        {error && <p className="text-sm text-red-600">{error}</p>}
        <div className="flex justify-end gap-2">
          <button onClick={() => setOpen(false)}
            className="rounded-lg border px-4 py-2 text-sm text-gray-600 hover:bg-gray-50">Cancel</button>
          <button onClick={close} disabled={pending}
            className="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50">
            {pending ? "Closing…" : "Close Beta"}
          </button>
        </div>
      </div>
    </div>
  );
}

function NominatePanel({ featureId, candidates, onNominated }: {
  featureId: string;
  candidates: (Client & { csmOwner?: any; _enrollmentCount: number })[];
  onNominated: () => void;
}) {
  const [query, setQuery] = useState("");
  const [pending, setPending] = useState(false);
  const [result, setResult] = useState<{ warning?: string; error?: string } | null>(null);

  const filtered = candidates.filter((c) => c.name.toLowerCase().includes(query.toLowerCase()));

  async function nominate(clientId: string, force = false) {
    setResult(null); setPending(true);
    try {
      const data = await api.enrollments.create({ clientId, featureId, force });
      if (data.warning) setResult({ warning: data.warning });
      onNominated();
    } catch (e: any) {
      const errData = e.data ?? {};
      if (errData.conflict) {
        const confirmed = window.confirm(`${errData.error}\n\nNominate anyway?`);
        if (confirmed) { setPending(false); nominate(clientId, true); return; }
      } else {
        setResult({ error: errData.error ?? "Failed" });
      }
    }
    setPending(false);
  }

  return (
    <div className="space-y-3">
      <input type="text" placeholder="Search clients…" value={query}
        onChange={(e) => setQuery(e.target.value)}
        className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400" />
      {result?.warning && <p className="text-xs text-amber-600">{result.warning}</p>}
      {result?.error && <p className="text-xs text-red-600">{result.error}</p>}
      <div className="max-h-96 overflow-y-auto space-y-1">
        {filtered.map((c) => (
          <div key={c.id} className="flex items-center justify-between rounded-lg border border-gray-100 px-3 py-2">
            <div className="flex items-center gap-2 min-w-0">
              <HealthDot health={c.accountHealth} />
              <div className="min-w-0">
                <p className="text-sm font-medium text-gray-900 truncate">{c.name}</p>
                <p className="text-xs text-gray-400">T{c.tier} · {c.csmOwner?.name}</p>
              </div>
            </div>
            <button onClick={() => nominate(c.id)} disabled={pending || c.accountHealth === "red"}
              className="ml-2 rounded bg-blue-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-blue-700 disabled:opacity-40 flex-shrink-0">
              Add
            </button>
          </div>
        ))}
        {filtered.length === 0 && <p className="text-sm text-gray-400 py-4 text-center">No candidates found.</p>}
      </div>
    </div>
  );
}

export default function FeatureDetailPage({ params: { id } }: { params: { id: string } }) {
  const [feature, setFeature] = useState<BetaFeature & { enrollments: BetaEnrollment[] } | null>(null);
  const currentUser = useCurrentUser();
  const [candidates, setCandidates] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [editOpen, setEditOpen] = useState(false);
  const [, navigate] = useLocation();

  function load() {
    setLoading(true);
    Promise.all([api.features.get(id), api.clients.list({ limit: "200" })])
      .then(([f, clientsData]) => {
        setFeature(f);
        const enrolledIds = new Set(f.enrollments?.map((e: any) => e.clientId) ?? []);
        setCandidates((clientsData.clients ?? [])
          .filter((c: any) => !enrolledIds.has(c.id))
          .map((c: any) => ({ ...c, _enrollmentCount: 0 })));
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, [id]);

  if (loading) return <div className="py-16 text-center text-sm text-gray-400">Loading…</div>;
  if (!feature) return <div className="py-16 text-center text-sm text-gray-400">Feature not found.</div>;

  const enrollments = feature.enrollments ?? [];
  const confirmed = enrollments.filter((e) => ["confirmed", "active", "completed"].includes(e.testerStatus)).length;
  const csmPending = enrollments.filter((e) => e.csmApprovalStatus === "pending").length;
  const isClosed = feature.status === "closed" || feature.status === "closing";

  const MANUAL_STATUSES = [
    { value: "draft",         label: "Draft" },
    { value: "recruiting",    label: "Recruiting" },
    { value: "outreach_sent", label: "Outreach Sent" },
    { value: "full",          label: "Full" },
    { value: "in_progress",   label: "In Progress" },
  ] as const;

  async function changeStatus(newStatus: string) {
    try {
      await api.features.update(id, { status: newStatus });
      load();
    } catch (e: any) { alert(e.data?.error ?? "Failed to update status"); }
  }

  async function clone() {
    try {
      const data = await api.features.clone(id);
      navigate(`/features/${data.id}`);
    } catch (e: any) { alert(e.data?.error ?? "Failed to clone"); }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <Link href="/features" className="text-sm text-gray-400 hover:text-gray-600">← Features</Link>
          <h1 className="mt-1 text-2xl font-semibold text-gray-900">{feature.name}</h1>
          <div className="mt-1 flex flex-wrap items-center gap-3 text-sm text-gray-500">
            {isClosed ? (
              <BetaStatusBadge status={feature.status} />
            ) : (
              <div className="flex items-center gap-1.5">
                <span className="text-xs font-medium text-gray-400 uppercase tracking-wide">Stage</span>
                <select
                  value={feature.status}
                  onChange={(e) => changeStatus(e.target.value)}
                  className="rounded-md border border-gray-200 bg-white px-2 py-1 text-xs font-medium text-gray-700 outline-none focus:border-blue-400 cursor-pointer hover:border-gray-300"
                >
                  {MANUAL_STATUSES.map((s) => (
                    <option key={s.value} value={s.value}>{s.label}</option>
                  ))}
                </select>
              </div>
            )}
            <span>PM: {(feature as any).ownerPm?.name}</span>
            <span>PMM: {(feature as any).ownerPmm?.name}</span>
            <span>Start: {new Date(feature.startDate).toLocaleDateString()}</span>
            {feature.closedAt && <span>Closed: {new Date(feature.closedAt).toLocaleDateString()}</span>}
            {(feature as any).jiraEpicLink && (
              <a href={(feature as any).jiraEpicLink} target="_blank" rel="noopener noreferrer"
                className="inline-flex items-center gap-1 rounded bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-700 hover:bg-blue-100">
                <svg className="h-3 w-3" viewBox="0 0 24 24" fill="currentColor"><path d="M11.571 11.429 6.286 6.143A1.714 1.714 0 0 1 8.714 3.71l5.715 5.714a1.714 1.714 0 0 1 0 2.424l-5.715 5.714a1.714 1.714 0 1 1-2.428-2.428l5.285-3.705zm.858 0 5.285 3.714a1.714 1.714 0 1 1-2.428 2.428l-5.715-5.714a1.714 1.714 0 0 1 0-2.424L15.286 3.72a1.714 1.714 0 0 1 2.428 2.428L12.43 11.43z"/></svg>
                JIRA Epic
              </a>
            )}
          </div>
        </div>
        {canWrite(currentUser) && (
          <div className="flex gap-2 flex-wrap">
            {!isClosed && (
              <button onClick={() => setEditOpen(true)}
                className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50">
                Edit
              </button>
            )}
            <button onClick={clone}
              className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50">
              Clone as Template
            </button>
            {!isClosed && <CloseFeatureButton featureId={id} onDone={load} />}
          </div>
        )}
      </div>

      {editOpen && (
        <EditFeatureModal
          feature={feature}
          onClose={() => setEditOpen(false)}
          onSaved={load}
        />
      )}

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {[
          { label: "Slots",          value: <SlotFill confirmed={confirmed} target={feature.targetTesterCount} /> },
          { label: "CSM Pending",    value: <span className={`text-2xl font-bold ${csmPending > 0 ? "text-amber-600" : "text-gray-900"}`}>{csmPending}</span> },
          { label: "Total Nominated",value: <span className="text-2xl font-bold text-gray-900">{enrollments.length}</span> },
          { label: "Outreach Sent",  value: <span className="text-2xl font-bold text-gray-900">{enrollments.filter(e => e.testerStatus === "outreach_sent").length}</span> },
        ].map(({ label, value }) => (
          <div key={label} className="rounded-xl border border-gray-200 bg-white p-4">
            <p className="text-xs text-gray-400 uppercase tracking-wide">{label}</p>
            <div className="mt-1">{value}</div>
          </div>
        ))}
      </div>

      {feature.idealClientCriteria && (
        <div className="rounded-lg bg-blue-50 px-4 py-3 text-sm text-blue-800">
          <strong>Ideal criteria:</strong> {feature.idealClientCriteria}
        </div>
      )}

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2 overflow-hidden rounded-xl border border-gray-200 bg-white">
          <div className="border-b border-gray-100 px-4 py-3">
            <h2 className="text-sm font-semibold text-gray-700">Enrollments</h2>
          </div>
          <table className="min-w-full divide-y divide-gray-100">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Client</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 hidden sm:table-cell">Status</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 hidden md:table-cell">CSM Approval</th>
                <th className="px-4 py-2 text-right text-xs font-medium text-gray-500">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {enrollments.map((e) => {
                const preOutreach = ["nominated", "csm_pending", "csm_approved"].includes(e.testerStatus);
                return (
                  <tr key={e.id} className={`hover:bg-gray-50 ${e.isOverflow ? "bg-indigo-50/30" : ""}`}>
                    <td className="px-4 py-2.5">
                      <div className="flex items-center gap-2">
                        <HealthDot health={e.client?.accountHealth ?? "green"} />
                        <div>
                          <p className="text-sm font-medium text-gray-900">
                            {e.client?.name}
                            {e.isOverflow && (
                              <span className="ml-1.5 rounded bg-indigo-100 px-1.5 py-0.5 text-[10px] font-medium text-indigo-700">overflow</span>
                            )}
                          </p>
                          <p className="text-xs text-gray-400">CSM: {e.client?.csmOwner?.name}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-2.5 hidden sm:table-cell">
                      <TesterStatusBadge status={e.testerStatus} />
                    </td>
                    <td className="px-4 py-2.5 hidden md:table-cell">
                      <ApprovalStatusBadge status={e.csmApprovalStatus} />
                      {e.csmRejectionReason && (
                        <p className="mt-0.5 text-xs text-gray-400 truncate max-w-[160px]" title={e.csmRejectionReason}>
                          {e.csmRejectionReason}
                        </p>
                      )}
                    </td>
                    <td className="px-4 py-2.5 text-right">
                      {e.csmApprovalStatus === "pending" ? (
                        <ApproveRejectButtons enrollmentId={e.id} onDone={load} />
                      ) : preOutreach ? (
                        <RemoveButton enrollmentId={e.id} onDone={load} />
                      ) : null}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {enrollments.length === 0 && (
            <p className="py-8 text-center text-sm text-gray-400">No enrollments yet.</p>
          )}
        </div>

        {!isClosed && (
          <div className="rounded-xl border border-gray-200 bg-white p-4 h-fit">
            <h2 className="text-sm font-semibold text-gray-700 mb-3">Add Beta Testers</h2>
            <NominatePanel featureId={id} candidates={candidates} onNominated={load} />
          </div>
        )}
      </div>
    </div>
  );
}

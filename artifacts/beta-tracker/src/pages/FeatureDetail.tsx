import React, { useCallback, useEffect, useRef, useState } from "react";
import { Link, useLocation } from "wouter";
import { api } from "@/lib/api";
import { BetaStatusBadge, TesterStatusBadge } from "@/components/StatusBadge";
import { HealthDot } from "@/components/HealthDot";
import { EditFeatureModal } from "@/components/EditFeatureModal";
import { TranscriptImportModal } from "@/components/TranscriptImportModal";
import { EnrollmentFunnelCard } from "@/components/FunnelBar";
import type { BetaFeature, BetaEnrollment } from "@/lib/types";
import { useCurrentUser, canWrite } from "@/hooks/useCurrentUser";
import { useInfiniteScroll } from "@/hooks/useInfiniteScroll";
import { MultiSelect } from "@/components/MultiSelect";
import { FeedbackDetailModal } from "@/components/FeedbackDetailModal";

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
          placeholder="Reason for removal…"
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
    <div className="flex items-center justify-end gap-1">
      {error && <p className="text-xs text-red-600 mr-1">{error}</p>}
      <button onClick={approve} disabled={pending}
        className="min-w-[4.5rem] rounded bg-green-600 px-2.5 py-1 text-center text-xs font-medium text-white hover:bg-green-700 disabled:opacity-50">
        Approve
      </button>
      <button onClick={() => setShowReject(true)} disabled={pending}
        className="min-w-[4.5rem] rounded border border-red-200 px-2.5 py-1 text-center text-xs font-medium text-red-600 hover:bg-red-50 disabled:opacity-50">
        Remove
      </button>
    </div>
  );
}

function RevokeApprovalButton({ enrollmentId, onDone }: { enrollmentId: string; onDone: () => void }) {
  const [pending, setPending] = useState(false);
  async function revoke() {
    setPending(true);
    try { await api.enrollments.unapprove(enrollmentId); onDone(); }
    catch (e: any) { alert(e.data?.error ?? "Failed"); }
    finally { setPending(false); }
  }
  return (
    <button onClick={revoke} disabled={pending}
      title="Revoke CSM approval — returns enrollment to pending review"
      className="rounded p-1.5 text-amber-500 hover:bg-amber-50 disabled:opacity-50">
      <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
        <path fillRule="evenodd" d="M7.793 2.232a.75.75 0 01-.025 1.06L3.622 7.25h10.003a5.375 5.375 0 010 10.75H10.75a.75.75 0 010-1.5h2.875a3.875 3.875 0 000-7.75H3.622l4.146 3.957a.75.75 0 01-1.036 1.085l-5.5-5.25a.75.75 0 010-1.085l5.5-5.25a.75.75 0 011.061.025z" clipRule="evenodd" />
      </svg>
    </button>
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
      title="Remove — drops this client from the beta entirely"
      className="rounded p-1.5 text-red-500 hover:bg-red-50 disabled:opacity-50">
      <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
        <path fillRule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z" clipRule="evenodd" />
      </svg>
    </button>
  );
}

function CompleteFeatureModal({ featureId, onDone, onCancel }: { featureId: string; onDone: () => void; onCancel: () => void }) {
  const [notes, setNotes] = useState("");
  const [force, setForce] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  async function complete() {
    setPending(true); setError("");
    try {
      await api.features.close(featureId, { closeReason: "completed", closeNotes: notes, force });
      onDone();
    } catch (e: any) { setError(e.data?.error ?? "Failed"); }
    finally { setPending(false); }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl space-y-4">
        <h2 className="text-base font-semibold text-gray-900">Mark as Complete</h2>
        <div className="space-y-1">
          <label className="text-xs font-medium text-gray-700">Notes (optional)</label>
          <textarea value={notes} onChange={(e) => setNotes(e.target.value)} rows={2}
            className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none" />
        </div>
        <label className="flex items-center gap-2 text-sm text-gray-700">
          <input type="checkbox" checked={force} onChange={(e) => setForce(e.target.checked)} />
          Drop active testers immediately
        </label>
        {error && <p className="text-sm text-red-600">{error}</p>}
        <div className="flex justify-end gap-2">
          <button onClick={onCancel}
            className="rounded-lg border px-4 py-2 text-sm text-gray-600 hover:bg-gray-50">Cancel</button>
          <button onClick={complete} disabled={pending}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
            {pending ? "Saving…" : "Mark Complete"}
          </button>
        </div>
      </div>
    </div>
  );
}

const SEGMENTS = ["Strategic", "Enterprise", "Commercial", "Professional", "Channel"] as const;
const HEALTH_LABELS: Record<string, string> = { green: "Green", yellow: "Yellow", red: "Red" };

const SENTIMENT_STYLES: Record<string, string> = {
  positive: "bg-green-100 text-green-700",
  neutral:  "bg-gray-100 text-gray-600",
  negative: "bg-red-100 text-red-700",
};

function SentimentBadge({ sentiment }: { sentiment: string }) {
  return (
    <span className={`inline-flex items-center rounded px-1.5 py-0.5 text-[10px] font-medium ${SENTIMENT_STYLES[sentiment] ?? "bg-gray-100 text-gray-600"}`}>
      {sentiment.charAt(0).toUpperCase() + sentiment.slice(1)}
    </span>
  );
}

type Sentiment = "positive" | "neutral" | "negative";

function PencilIcon() {
  return (
    <svg className="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor">
      <path d="M5.433 13.917l1.262-3.155A4 4 0 017.58 9.42l6.92-6.918a2.121 2.121 0 013 3l-6.92 6.918a4 4 0 01-1.343.885l-3.154 1.262a.5.5 0 01-.63-.63z" />
    </svg>
  );
}

function TrashIcon() {
  return (
    <svg className="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor">
      <path fillRule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z" clipRule="evenodd" />
    </svg>
  );
}

const EDITABLE_STATUSES = new Set(["nominated", "csm_approved", "outreach_sent", "confirmed", "active", "enrolled", "using", "accepted", "completed"]);

// Options shown when current status is "nominated" — can't revert to nominated itself
const NOMINATED_OPTIONS = ["csm_approved", "enrolled", "using", "accepted"] as const;
// Full option list for all other statuses — includes nominated as revert, current is checked
const ALL_OPTIONS = ["nominated", "csm_approved", "enrolled", "using", "accepted"] as const;

function StatusCell({ enrollment, canEdit, onUpdated }: { enrollment: any; canEdit: boolean; onUpdated: () => void }) {
  const [open, setOpen] = useState(false);
  const [dropPos, setDropPos] = useState<{ top: number; left: number } | null>(null);
  const [updating, setUpdating] = useState(false);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const dropRef = useRef<HTMLDivElement>(null);

  const status: string = enrollment.testerStatus;
  const canMove = EDITABLE_STATUSES.has(status) && canEdit;

  useEffect(() => {
    if (!open) return;
    function handleClose(e: MouseEvent) {
      const t = e.target as Node;
      if (triggerRef.current?.contains(t) || dropRef.current?.contains(t)) return;
      setOpen(false);
    }
    document.addEventListener("mousedown", handleClose);
    return () => document.removeEventListener("mousedown", handleClose);
  }, [open]);

  function openMenu(e: React.MouseEvent) {
    e.stopPropagation();
    if (!triggerRef.current) return;
    const r = triggerRef.current.getBoundingClientRect();
    setDropPos({ top: r.bottom + 4, left: r.left });
    setOpen(o => !o);
  }

  async function changeStatus(next: string) {
    setOpen(false);
    if (next === status) return;
    setUpdating(true);
    try {
      await api.enrollments.patch(enrollment.id, { status: next });
      onUpdated();
    } catch (e: any) {
      alert(e.data?.error ?? "Failed to update status");
    } finally {
      setUpdating(false);
    }
  }

  const options = status === "nominated" ? NOMINATED_OPTIONS : ALL_OPTIONS;

  if (!canMove) return <TesterStatusBadge status={enrollment.testerStatus} />;

  return (
    <>
      <button
        ref={triggerRef}
        onClick={openMenu}
        disabled={updating}
        className="group inline-flex items-center gap-0.5 cursor-pointer disabled:opacity-50"
      >
        <TesterStatusBadge status={enrollment.testerStatus} />
        <svg
          className="h-3 w-3 text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity shrink-0"
          viewBox="0 0 16 16" fill="currentColor"
          aria-hidden="true"
        >
          <path d="M8 10L4 6h8l-4 4z" />
        </svg>
      </button>
      {open && dropPos && (
        <div
          ref={dropRef}
          onClick={e => e.stopPropagation()}
          style={{ position: "fixed", top: dropPos.top, left: dropPos.left }}
          className="z-50 rounded-lg border border-gray-200 bg-white shadow-lg py-1 min-w-[150px]"
        >
          {options.map(s => (
            <button
              key={s}
              onClick={() => changeStatus(s)}
              className="flex items-center justify-between w-full px-3 py-1.5 hover:bg-gray-50 text-left"
            >
              <TesterStatusBadge status={s} />
              {s === status && (
                <svg className="h-3.5 w-3.5 text-blue-500 shrink-0 ml-2" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
              )}
            </button>
          ))}
        </div>
      )}
    </>
  );
}

function EditFeedbackModal({ entry, onClose, onSaved, focusJira = false }: {
  entry: any; onClose: () => void; onSaved: () => void; focusJira?: boolean;
}) {
  const [sentiment, setSentiment] = useState<Sentiment>(entry.sentiment);
  const [notes, setNotes] = useState(entry.notes ?? "");
  const [providerId, setProviderId] = useState(entry.feedbackProviderId ?? "");
  const [isGatingRequest, setIsGatingRequest] = useState<boolean>(entry.isGatingRequest ?? false);
  const [gatingDescription, setGatingDescription] = useState(entry.gatingDescription ?? "");
  const [jiraTicketUrl, setJiraTicketUrl] = useState(entry.jiraTicketUrl ?? "");
  const [users, setUsers] = useState<any[]>([]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const jiraRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    api.users.list().then((d: any) => setUsers(d.users ?? d ?? [])).catch(() => {});
  }, []);

  useEffect(() => {
    if (focusJira && isGatingRequest) setTimeout(() => jiraRef.current?.focus(), 50);
  }, [focusJira, isGatingRequest]);

  async function save() {
    if (isGatingRequest && !gatingDescription.trim()) {
      setError("Gating description is required when marking as a blocking feature request."); return;
    }
    if (jiraTicketUrl && !jiraTicketUrl.startsWith("https://")) {
      setError("JIRA ticket URL must start with https://"); return;
    }
    setSaving(true); setError("");
    try {
      await api.feedback.update(entry.id, {
        sentiment, notes: notes || null, feedbackProviderId: providerId,
        isGatingRequest,
        gatingDescription: isGatingRequest ? (gatingDescription.trim() || null) : null,
        jiraTicketUrl: jiraTicketUrl || null,
      });
      onSaved(); onClose();
    } catch (e: any) {
      setError(e?.data?.error ?? "Failed to save");
    } finally { setSaving(false); }
  }

  const SENTIMENTS: Sentiment[] = ["positive", "neutral", "negative"];
  const SENTIMENT_STYLE_MAP: Record<Sentiment, string> = {
    positive: "bg-green-100 text-green-700",
    neutral:  "bg-gray-100 text-gray-600",
    negative: "bg-red-100 text-red-700",
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-xl bg-white shadow-xl">
        <div className="px-6 py-5 border-b border-gray-100">
          <h2 className="text-base font-semibold text-gray-900">Edit Feedback</h2>
        </div>
        <div className="px-6 py-4 space-y-4 max-h-[70vh] overflow-y-auto">
          <div><p className="text-xs font-medium text-gray-500 mb-1">Client</p><p className="text-sm text-gray-900">{entry.clientName}</p></div>
          <div><p className="text-xs font-medium text-gray-500 mb-1">Feature</p><p className="text-sm text-gray-900">{entry.featureName}</p></div>
          <div>
            <p className="text-xs font-medium text-gray-500 mb-1">Sentiment</p>
            <div className="flex overflow-hidden rounded-lg border border-gray-200">
              {SENTIMENTS.map((s) => (
                <button key={s} type="button" onClick={() => setSentiment(s)}
                  className={`flex-1 py-1.5 text-sm font-medium transition-colors ${sentiment === s ? SENTIMENT_STYLE_MAP[s] : "text-gray-400 hover:bg-gray-50"}`}>
                  {s.charAt(0).toUpperCase() + s.slice(1)}
                </button>
              ))}
            </div>
          </div>
          <div>
            <p className="text-xs font-medium text-gray-500 mb-1">Notes</p>
            <textarea value={notes} onChange={(e) => setNotes(e.target.value)} rows={3}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none outline-none focus:border-blue-400" />
          </div>
          <div>
            <p className="text-xs font-medium text-gray-500 mb-1">Feedback provider</p>
            <select value={providerId} onChange={(e) => setProviderId(e.target.value)}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400 bg-white">
              {users.map((u: any) => <option key={u.id} value={u.id}>{u.name}</option>)}
            </select>
          </div>
          <label className="flex items-start gap-2 cursor-pointer">
            <input type="checkbox" checked={isGatingRequest} onChange={(e) => setIsGatingRequest(e.target.checked)}
              className="mt-0.5 rounded border-gray-300 text-red-600 focus:ring-red-500" />
            <span className="text-sm text-gray-700">This feedback includes a feature request blocking adoption</span>
          </label>
          {isGatingRequest && (
            <>
              <div>
                <p className="text-xs font-medium text-gray-500 mb-1">Gating description <span className="text-red-500">*</span></p>
                <textarea value={gatingDescription} onChange={(e) => setGatingDescription(e.target.value)} rows={3}
                  placeholder="Describe the feature request that is blocking this client from fully adopting the beta."
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none outline-none focus:border-blue-400" />
              </div>
              <div>
                <p className="text-xs font-medium text-gray-500 mb-1">JIRA ticket URL <span className="text-gray-400">(optional)</span></p>
                <input ref={jiraRef} type="url" value={jiraTicketUrl} onChange={(e) => setJiraTicketUrl(e.target.value)}
                  placeholder="https://birdeye.atlassian.net/..."
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400" />
              </div>
            </>
          )}
          {error && <p className="text-sm text-red-600">{error}</p>}
        </div>
        <div className="flex justify-end gap-3 border-t border-gray-100 px-6 py-4">
          <button onClick={onClose} disabled={saving}
            className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50">
            Cancel
          </button>
          <button onClick={save} disabled={saving}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
            {saving ? "Saving…" : "Save changes"}
          </button>
        </div>
      </div>
    </div>
  );
}

const NOMINATE_TAKE = 50;

const NominatePanel = React.memo(function NominatePanel({ featureId, enrolledClientIds, onEnrolled }: {
  featureId: string;
  enrolledClientIds: Set<string>;
  onEnrolled: (enrollment: any, client: any) => void;
}) {
  const [query, setQuery] = useState("");
  const [debouncedQuery, setDebouncedQuery] = useState("");
  const [filterHealth, setFilterHealth] = useState<string[]>([]);
  const [filterSegment, setFilterSegment] = useState<string[]>([]);
  const [filterVertical, setFilterVertical] = useState<string[]>([]);
  const [clients, setClients] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [pageLoading, setPageLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [verticals, setVerticals] = useState<string[]>([]);
  const [pending, setPending] = useState(false);
  const [result, setResult] = useState<{ warning?: string; error?: string } | null>(null);
  const pageRef = useRef(1);
  const scrollRef = useRef<HTMLDivElement>(null);
  const enrolledRef = useRef(enrolledClientIds);
  enrolledRef.current = enrolledClientIds;
  // Tracks IDs nominated this session so they're excluded from fetches even before
  // the parent's load() completes and enrolledClientIds updates.
  const nominatedRef = useRef<Set<string>>(new Set());

  function isExcluded(clientId: string) {
    return enrolledRef.current.has(clientId) || nominatedRef.current.has(clientId);
  }

  useEffect(() => {
    const t = setTimeout(() => setDebouncedQuery(query), 300);
    return () => clearTimeout(t);
  }, [query]);

  useEffect(() => {
    pageRef.current = 1;
    setClients([]);
    setPageLoading(true);
    let cancelled = false;

    const params: Record<string, string> = { page: "1", limit: String(NOMINATE_TAKE) };
    if (debouncedQuery.trim())      params.search   = debouncedQuery.trim();
    if (filterHealth.length > 0)   params.health   = filterHealth.join(",");
    if (filterSegment.length > 0)  params.segment  = filterSegment.join(",");
    if (filterVertical.length > 0) params.vertical = filterVertical.join(",");

    api.clients.list(params)
      .then((d: any) => {
        if (cancelled) return;
        setClients((d.clients ?? []).filter((c: any) => !isExcluded(c.id)));
        setTotal(d.total ?? 0);
      })
      .catch(console.error)
      .finally(() => { if (!cancelled) setPageLoading(false); });
    return () => { cancelled = true; };
  }, [debouncedQuery, filterHealth.join(","), filterSegment.join(","), filterVertical.join(",")]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    api.clients.verticals().then((v: any) => setVerticals((v.verticals ?? []).sort())).catch(() => {});
  }, []);

  // loadMore uses the render-closure values of filters; useInfiniteScroll keeps its
  // callback ref fresh so the IntersectionObserver always calls the latest version.
  function loadMore() {
    if (loadingMore || clients.length >= total) return;
    const next = pageRef.current + 1;
    pageRef.current = next;
    setLoadingMore(true);

    const params: Record<string, string> = { page: String(next), limit: String(NOMINATE_TAKE) };
    if (debouncedQuery.trim())      params.search   = debouncedQuery.trim();
    if (filterHealth.length > 0)   params.health   = filterHealth.join(",");
    if (filterSegment.length > 0)  params.segment  = filterSegment.join(",");
    if (filterVertical.length > 0) params.vertical = filterVertical.join(",");

    api.clients.list(params)
      .then((d: any) => {
        setClients(prev => [...prev, ...(d.clients ?? []).filter((c: any) => !isExcluded(c.id))]);
        setTotal(d.total ?? 0);
      })
      .catch(console.error)
      .finally(() => setLoadingMore(false));
  }

  const sentinelRef = useInfiniteScroll(loadMore, !pageLoading && clients.length < total, scrollRef);

  async function nominate(clientId: string, force = false) {
    setResult(null); setPending(true);

    // Optimistically remove the client immediately — no scroll reset, no re-fetch
    const clientIndex = clients.findIndex((c: any) => c.id === clientId);
    const client = clients[clientIndex];
    nominatedRef.current = new Set([...nominatedRef.current, clientId]);
    setClients(prev => prev.filter((c: any) => c.id !== clientId));
    setTotal(prev => prev - 1);

    try {
      const data = await api.enrollments.create({ clientId, featureId, force });
      if (data.warning) setResult({ warning: data.warning });
      onEnrolled(data.enrollment, client);
    } catch (e: any) {
      // Rollback: restore the client at its original position
      nominatedRef.current = new Set([...nominatedRef.current].filter(id => id !== clientId));
      setClients(prev => { const next = [...prev]; next.splice(clientIndex, 0, client); return next; });
      setTotal(prev => prev + 1);
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
      <div className="grid grid-cols-3 gap-1.5">
        <MultiSelect label="Health" options={["green", "yellow", "red"]} selected={filterHealth} onChange={setFilterHealth} labelMap={HEALTH_LABELS} className="text-xs" />
        <MultiSelect label="Segment" options={[...SEGMENTS]} selected={filterSegment} onChange={setFilterSegment} className="text-xs" />
        <MultiSelect label="Vertical" options={verticals} selected={filterVertical} onChange={setFilterVertical} className="text-xs" />
      </div>
      {result?.warning && <p className="text-xs text-amber-600">{result.warning}</p>}
      {result?.error && <p className="text-xs text-red-600">{result.error}</p>}
      {pageLoading ? (
        <p className="py-4 text-center text-sm text-gray-400">Loading…</p>
      ) : (
        <div ref={scrollRef} className="max-h-96 overflow-y-auto space-y-1">
          {clients.map((c: any) => (
            <div key={c.id} className="flex items-center justify-between rounded-lg border border-gray-100 px-3 py-2">
              <div className="flex items-center gap-2 min-w-0">
                <HealthDot health={c.accountHealth} />
                <div className="min-w-0">
                  <p className="text-sm font-medium text-gray-900 truncate">{c.name}</p>
                  <p className="text-xs text-gray-400">{c.vertical ?? "—"}</p>
                </div>
              </div>
              <button onClick={() => nominate(c.id)} disabled={pending || c.accountHealth === "red"}
                className="ml-2 rounded bg-blue-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-blue-700 disabled:opacity-40 flex-shrink-0">
                Add
              </button>
            </div>
          ))}
          {clients.length === 0 && !loadingMore && (
            <p className="text-sm text-gray-400 py-4 text-center">No candidates found.</p>
          )}
          <div ref={sentinelRef} className="h-1" />
          {loadingMore && <p className="py-2 text-center text-xs text-gray-400">Loading more…</p>}
        </div>
      )}
    </div>
  );
});

function EnrollmentDrawer({
  enrollment,
  feature,
  canWrite,
  onClose,
  onUpdated,
  onAction,
  onRemoved,
}: {
  enrollment: any;
  feature: any;
  canWrite: boolean;
  onClose: () => void;
  onUpdated: () => void;
  onAction: () => void;
  onRemoved: (id: string) => void;
}) {
  const [client, setClient] = useState<any>(null);
  const [feedback, setFeedback] = useState<any[]>([]);
  const [fbLoading, setFbLoading] = useState(true);

  const [sentiment, setSentiment] = useState<Sentiment | null>(null);
  const [notes, setNotes] = useState("");
  const [isGatingRequest, setIsGatingRequest] = useState(false);
  const [gatingDescription, setGatingDescription] = useState("");
  const [jiraTicketUrl, setJiraTicketUrl] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [fbError, setFbError] = useState("");

  const [editEntry, setEditEntry] = useState<any>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [showImport, setShowImport] = useState(false);

  const c = enrollment.client as any;
  const clientId = c?.id ?? enrollment.clientId;

  useEffect(() => {
    if (!clientId) return;
    api.clients.get(clientId).then(setClient).catch(() => {});
  }, [clientId]);

  function loadFeedback() {
    setFbLoading(true);
    api.feedback.list({ client_id: clientId, feature_id: feature.id })
      .then((d: any) => setFeedback(d.feedback ?? []))
      .catch(console.error)
      .finally(() => setFbLoading(false));
  }

  useEffect(() => {
    if (!clientId) return;
    loadFeedback();
  }, [clientId, feature.id]); // eslint-disable-line react-hooks/exhaustive-deps

  async function submitFeedback(e: React.FormEvent) {
    e.preventDefault();
    if (!sentiment) { setFbError("Select a sentiment."); return; }
    if (isGatingRequest && !gatingDescription.trim()) {
      setFbError("Gating description is required."); return;
    }
    if (jiraTicketUrl && !jiraTicketUrl.startsWith("https://")) {
      setFbError("JIRA URL must start with https://"); return;
    }
    setFbError(""); setSubmitting(true);
    try {
      await api.feedback.create({
        clientId, featureId: feature.id, sentiment, notes,
        isGatingRequest,
        gatingDescription: isGatingRequest ? (gatingDescription.trim() || null) : null,
        jiraTicketUrl: isGatingRequest ? (jiraTicketUrl || null) : null,
      });
      setNotes(""); setSentiment(null); setIsGatingRequest(false); setGatingDescription(""); setJiraTicketUrl("");
      loadFeedback();
    } catch (err: any) {
      setFbError(err.data?.error ?? "Failed to save");
    } finally {
      setSubmitting(false);
    }
  }

  const preOutreach = ["nominated", "csm_pending", "csm_approved"].includes(enrollment.testerStatus);
  const needsApproval = enrollment.csmApprovalStatus === "pending";

  const positiveCount = feedback.filter((f) => f.sentiment === "positive").length;
  const pct = feedback.length > 0 ? Math.round((positiveCount / feedback.length) * 100) : null;
  const pctColor = pct != null ? (pct >= 80 ? "#1D9E75" : pct >= 60 ? "#EF9F27" : "#E24B4A") : undefined;

  return (
    <div className="flex h-full flex-col">
      {/* Header */}
      <div className="flex shrink-0 items-start justify-between gap-3 border-b border-gray-100 px-5 py-4">
        <div className="flex min-w-0 items-center gap-2">
          <HealthDot health={c?.accountHealth ?? "green"} />
          <div className="min-w-0">
            <p className="truncate text-gray-900" style={{ fontSize: 16, fontWeight: 500 }}>
              {c?.name ?? "—"}
            </p>
            <p className="mt-0.5 text-xs text-gray-400">
              {c?.csmOwner?.name ? `CSM: ${c.csmOwner.name}` : ""}
              {c?.aeOwner?.name ? ` · AE: ${c.aeOwner.name}` : ""}
            </p>
          </div>
        </div>
        <button
          onClick={onClose}
          className="shrink-0 rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
        >
          <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
          </svg>
        </button>
      </div>

      {/* Scrollable body */}
      <div className="flex-1 overflow-y-auto px-5 py-4 space-y-5">

        {/* Details grid */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <p className="mb-1 text-[10px] font-medium uppercase tracking-wide text-gray-400">Status</p>
            <StatusCell enrollment={enrollment} canEdit={canWrite} onUpdated={onUpdated} />
          </div>
          <div>
            <p className="mb-1 text-[10px] font-medium uppercase tracking-wide text-gray-400">Segment</p>
            <p className="text-sm text-gray-700">{c?.segment ?? <span className="text-gray-400">—</span>}</p>
          </div>
          <div>
            <p className="mb-1 text-[10px] font-medium uppercase tracking-wide text-gray-400">Vertical</p>
            <p className="text-sm text-gray-700">{c?.vertical ?? <span className="text-gray-400">—</span>}</p>
          </div>
          <div>
            <p className="mb-1 text-[10px] font-medium uppercase tracking-wide text-gray-400">Renewal</p>
            <p className="text-sm text-gray-700">
              {client?.contractRenewalDate
                ? new Date(client.contractRenewalDate + 'T00:00:00').toLocaleDateString()
                : <span className="text-gray-400">—</span>}
            </p>
          </div>
          {client?.primaryContactName && (
            <div>
              <p className="mb-1 text-[10px] font-medium uppercase tracking-wide text-gray-400">Primary Contact</p>
              <p className="text-sm text-gray-700">{client.primaryContactName}</p>
            </div>
          )}
          {client?.primaryContactEmail && (
            <div>
              <p className="mb-1 text-[10px] font-medium uppercase tracking-wide text-gray-400">Email</p>
              <a
                href={`mailto:${client.primaryContactEmail}`}
                className="block truncate text-sm text-blue-600 hover:text-blue-800"
              >
                {client.primaryContactEmail}
              </a>
            </div>
          )}
        </div>

        {/* Action buttons */}
        {canWrite && (
          <div>
            {needsApproval ? (
              <ApproveRejectButtons enrollmentId={enrollment.id} onDone={onAction} />
            ) : enrollment.testerStatus === "csm_approved" ? (
              <div className="flex items-center gap-2">
                <RevokeApprovalButton enrollmentId={enrollment.id} onDone={onAction} />
                <RemoveButton enrollmentId={enrollment.id} onDone={() => onRemoved(enrollment.id)} />
              </div>
            ) : preOutreach ? (
              <RemoveButton enrollmentId={enrollment.id} onDone={() => onRemoved(enrollment.id)} />
            ) : null}
          </div>
        )}

        {/* Log feedback */}
        <div className="border-t border-gray-100 pt-4">
          <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">Log feedback</p>
          <form onSubmit={submitFeedback} className="space-y-3">
            <div className="flex overflow-hidden rounded-lg border border-gray-200">
              {(["positive", "neutral", "negative"] as const).map((s) => (
                <button
                  key={s}
                  type="button"
                  onClick={() => setSentiment(s)}
                  className={`flex-1 py-1.5 text-sm font-medium transition-colors ${
                    sentiment === s
                      ? s === "positive"
                        ? "bg-green-100 text-green-700"
                        : s === "negative"
                          ? "bg-red-100 text-red-700"
                          : "bg-gray-100 text-gray-600"
                      : "text-gray-400 hover:bg-gray-50"
                  }`}
                >
                  {s.charAt(0).toUpperCase() + s.slice(1)}
                </button>
              ))}
            </div>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Notes (optional)"
              rows={2}
              className="w-full resize-none rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400"
            />
            <label className="flex cursor-pointer items-center gap-2">
              <input
                type="checkbox"
                checked={isGatingRequest}
                onChange={(e) => setIsGatingRequest(e.target.checked)}
                className="rounded border-gray-300 text-red-600 focus:ring-red-500"
              />
              <span className="text-sm text-gray-700">Blocking feature request</span>
            </label>
            {isGatingRequest && (
              <>
                <textarea
                  value={gatingDescription}
                  onChange={(e) => setGatingDescription(e.target.value)}
                  placeholder="Describe what's blocking adoption (required)"
                  rows={2}
                  className="w-full resize-none rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400"
                />
                <input
                  type="url"
                  value={jiraTicketUrl}
                  onChange={(e) => setJiraTicketUrl(e.target.value)}
                  placeholder="https://birdeye.atlassian.net/..."
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400"
                />
              </>
            )}
            {fbError && <p className="text-xs text-red-600">{fbError}</p>}
            <div className="flex gap-2">
              <button
                type="submit"
                disabled={submitting}
                className="flex-1 rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
              >
                {submitting ? "Logging…" : "Log"}
              </button>
              <button
                type="button"
                onClick={() => setShowImport(true)}
                className="flex items-center gap-1.5 rounded-lg border border-gray-200 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                <svg className="h-3.5 w-3.5 text-purple-500" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                </svg>
                Import from transcript
              </button>
            </div>
          </form>
        </div>

        {/* Feedback history */}
        <div className="border-t border-gray-100 pt-4">
          <div className="mb-3 flex items-center justify-between">
            <p className="text-xs font-semibold uppercase tracking-wide text-gray-500">
              Feedback ({feedback.length})
            </p>
            {pct != null && (
              <span className="text-xs font-medium" style={{ color: pctColor }}>
                {pct}% positive
              </span>
            )}
          </div>
          {fbLoading ? (
            <p className="text-xs text-gray-400">Loading…</p>
          ) : feedback.length === 0 ? (
            <p className="text-xs text-gray-400">No feedback logged yet.</p>
          ) : (
            <div className="space-y-3">
              {feedback.map((fb: any) => {
                const isDeleting = deleteId === fb.id;
                if (isDeleting) {
                  return (
                    <div key={fb.id} className="flex items-center gap-2 rounded-lg border border-red-100 bg-red-50 px-3 py-2 text-xs">
                      <span className="flex-1 text-gray-600">Delete this? Cannot be undone.</span>
                      <button
                        onClick={() => setDeleteId(null)}
                        disabled={deleting}
                        className="rounded border border-gray-200 px-2 py-0.5 text-gray-600 hover:bg-gray-50 disabled:opacity-50"
                      >
                        Cancel
                      </button>
                      <button
                        disabled={deleting}
                        onClick={async () => {
                          setDeleting(true);
                          try {
                            await api.feedback.remove(fb.id);
                            setFeedback((prev) => prev.filter((x: any) => x.id !== fb.id));
                            setDeleteId(null);
                          } catch { /* ignore */ } finally { setDeleting(false); }
                        }}
                        className="rounded bg-red-600 px-2 py-0.5 font-medium text-white hover:bg-red-700 disabled:opacity-50"
                      >
                        {deleting ? "…" : "Delete"}
                      </button>
                    </div>
                  );
                }

                const nameParts = (fb.feedbackProviderName ?? "").trim().split(/\s+/);
                const initials = nameParts.length >= 2
                  ? `${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}`.toUpperCase()
                  : (nameParts[0]?.[0] ?? "?").toUpperCase();
                const dateStr = new Date(fb.createdAt).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });

                return (
                  <div key={fb.id} className="group space-y-1.5 rounded-lg border border-gray-100 bg-gray-50 px-3 py-2.5">
                    <div className="flex items-center gap-1.5">
                      <SentimentBadge sentiment={fb.sentiment} />
                      {fb.isGatingRequest && (
                        <span className="inline-flex items-center rounded-full bg-red-100 px-1.5 py-0.5 text-[10px] font-medium text-red-700">
                          Blocking
                        </span>
                      )}
                      <div className="ml-auto flex items-center gap-1 opacity-0 transition-opacity group-hover:opacity-100">
                        {canWrite && (
                          <>
                            <button
                              onClick={() => setEditEntry(fb)}
                              title="Edit"
                              className="rounded p-0.5 text-gray-400 hover:bg-blue-50 hover:text-blue-600"
                            >
                              <PencilIcon />
                            </button>
                            <button
                              onClick={() => setDeleteId(fb.id)}
                              title="Delete"
                              className="rounded p-0.5 text-gray-400 hover:bg-red-50 hover:text-red-600"
                            >
                              <TrashIcon />
                            </button>
                          </>
                        )}
                      </div>
                    </div>
                    {fb.notes
                      ? <p className="text-sm text-gray-800">{fb.notes}</p>
                      : <p className="text-sm italic text-gray-400">No notes</p>}
                    {fb.isGatingRequest && fb.gatingDescription && (
                      <p className="text-xs italic text-gray-500">{fb.gatingDescription}</p>
                    )}
                    {fb.isGatingRequest && fb.jiraTicketUrl && (
                      <a
                        href={fb.jiraTicketUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-xs text-gray-400 hover:text-blue-600"
                      >
                        View ticket →
                      </a>
                    )}
                    <p className="text-[10px] text-gray-400">{initials} · {dateStr}</p>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Beta history */}
        <div className="border-t border-gray-100 pt-4">
          <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            Beta history ({(client?.enrollments ?? []).length})
          </p>
          {!client ? (
            <p className="text-xs text-gray-400">Loading…</p>
          ) : (client.enrollments ?? []).length === 0 ? (
            <p className="text-xs text-gray-400">No beta history.</p>
          ) : (
            <div className="space-y-1.5">
              {(client.enrollments ?? []).map((be: any) => (
                <div key={be.id} className="flex items-center justify-between gap-2 text-xs">
                  <Link
                    href={`/features/${be.feature?.slug ?? be.featureId}`}
                    className="truncate font-medium text-blue-600 hover:underline"
                  >
                    {be.feature?.name ?? be.featureId}
                  </Link>
                  <div className="flex shrink-0 items-center gap-1.5">
                    <TesterStatusBadge status={be.testerStatus} />
                    <span className="text-gray-400">{new Date(be.createdAt).toLocaleDateString()}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

      </div>

      {editEntry && (
        <EditFeedbackModal
          entry={editEntry}
          onClose={() => setEditEntry(null)}
          onSaved={loadFeedback}
        />
      )}
      {showImport && (
        <TranscriptImportModal
          defaultClientId={clientId}
          defaultClientName={c?.name}
          defaultFeatureId={feature.id}
          defaultFeatureName={feature.name}
          onClose={() => setShowImport(false)}
          onSaved={loadFeedback}
        />
      )}
    </div>
  );
}

export default function FeatureDetailPage({ params: { id } }: { params: { id: string } }) {
  const [feature, setFeature] = useState<BetaFeature & { enrollments: BetaEnrollment[] } | null>(null);
  const [enrollments, setEnrollments] = useState<any[]>([]);
  const [initialEnrolledIds, setInitialEnrolledIds] = useState<Set<string>>(new Set());
  const currentUser = useCurrentUser();
  const [loading, setLoading] = useState(true);
  const [editOpen, setEditOpen] = useState(false);
  const [selectedEnrollmentId, setSelectedEnrollmentId] = useState<string | null>(null);
  const [showCompleteModal, setShowCompleteModal] = useState(false);
  const [enrollSortCol, setEnrollSortCol] = useState("");
  const [enrollSortDir, setEnrollSortDir] = useState<"asc" | "desc">("asc");
  const [removedOpen, setRemovedOpen] = useState(false);
  const [idealExpanded, setIdealExpanded] = useState(false);
  const [goalExpanded, setGoalExpanded] = useState(false);
  const [feedbackDetail, setFeedbackDetail] = useState<any>(null);
  const [, navigate] = useLocation();

  // loadRef keeps a stable pointer to the latest load() so handleEnrolled can
  // call it without adding load to useCallback deps (which would break React.memo).
  const loadRef = useRef<() => void>(load);
  loadRef.current = load;

  // Stable callback — never changes reference, so React.memo on NominatePanel
  // won't re-render the panel when the enrollment table updates.
  const handleEnrolled = useCallback((enrollment: any, client: any) => { // eslint-disable-line @typescript-eslint/no-unused-vars
    loadRef.current();
  }, []);

  function toggleEnrollSort(col: string) {
    if (enrollSortCol === col) setEnrollSortDir(d => d === "asc" ? "desc" : "asc");
    else { setEnrollSortCol(col); setEnrollSortDir("asc"); }
  }

  function load() {
    setLoading(true);
    api.features.get(id)
      .then((f: any) => {
        if (f.slug && f.slug !== id) {
          navigate(`/features/${f.slug}`, { replace: true } as any);
          return;
        }
        const featureEnrollments = f.enrollments ?? [];
        setFeature(f);
        setEnrollments(featureEnrollments);
        setInitialEnrolledIds(new Set(featureEnrollments.map((e: any) => e.clientId)));
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, [id]);

  useEffect(() => {
    function handleKey(e: KeyboardEvent) {
      if (e.key === "Escape") setSelectedEnrollmentId(null);
    }
    document.addEventListener("keydown", handleKey);
    return () => document.removeEventListener("keydown", handleKey);
  }, []);

  if (loading && !feature) return <div className="py-16 text-center text-sm text-gray-400">Loading…</div>;
  if (!feature) return <div className="py-16 text-center text-sm text-gray-400">Feature not found.</div>;

  const activeEnrollments = enrollments.filter(
    (e) => !["dropped", "cancelled"].includes(e.testerStatus) && e.csmApprovalStatus !== "rejected"
  );
  const removedEnrollments = enrollments.filter(
    (e) => ["dropped", "cancelled"].includes(e.testerStatus) || e.csmApprovalStatus === "rejected"
  );
  const funnel = (feature as any).enrollmentFunnel ?? { nominated: 0, approved: 0, enrolled: 0, using: 0, accepted: 0, total: 0 };
  const isClosed = feature.status === "complete";

  const fbSummary = (feature as any).feedbackSummary ?? { total: 0, positive: 0, negative: 0, neutral: 0, positiveRate: null };
  const recentFeedback: any[] = (feature as any).recentFeedback ?? [];

  const MANUAL_STATUSES = [
    { value: "draft",       label: "Draft" },
    { value: "in_progress", label: "In Progress" },
    { value: "complete",    label: "Complete" },
  ] as const;

  function onRemoved(enrollmentId: string) {
    setEnrollments(prev => prev.filter(e => e.id !== enrollmentId));
    load();
  }

  async function changeStatus(newStatus: string) {
    if (newStatus === "complete") { setShowCompleteModal(true); return; }
    try {
      await api.features.update(id, { status: newStatus });
      load();
    } catch (e: any) { alert(e.data?.error ?? "Failed to update status"); }
  }

  async function clone() {
    try {
      const data = await api.features.clone(id);
      navigate(`/features/${data.slug ?? data.id}`);
    } catch (e: any) { alert(e.data?.error ?? "Failed to clone"); }
  }

  return (
    <div className="space-y-6 overflow-x-hidden max-w-full">
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0 flex-1">
          <Link href="/features" className="text-sm text-gray-400 hover:text-gray-600">← Beta Features</Link>
          <h1 className="mt-1 text-2xl font-semibold text-gray-900">{feature.name}</h1>
          <div className="mt-1 flex flex-wrap items-center gap-3 text-sm text-gray-500">
            {isClosed ? (
              <BetaStatusBadge status={feature.status} />
            ) : canWrite(currentUser) ? (
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
            ) : (
              <BetaStatusBadge status={feature.status} />
            )}
            <span>PM: {(feature as any).ownerPm?.name}</span>
            <span>PMM: {(feature as any).ownerPmm?.name}</span>
            <span>Start: {new Date(feature.startDate + 'T00:00:00').toLocaleDateString()}</span>
            {(feature as any).projectedEndDate && (
              <span>End: {new Date((feature as any).projectedEndDate + 'T00:00:00').toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" })}</span>
            )}
            {feature.closedAt && <span>Closed: {new Date(feature.closedAt).toLocaleDateString()}</span>}
            {(feature as any).jiraEpicLink && (
              <a href={(feature as any).jiraEpicLink} target="_blank" rel="noopener noreferrer"
                className="inline-flex items-center rounded bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-700 hover:bg-blue-100">
                JIRA Epic
              </a>
            )}
          </div>
          {(feature as any).idealClientCriteria && (
            <div className="mt-1 flex gap-2 text-sm text-gray-500" style={{ overflowWrap: "break-word", wordBreak: "break-word" }}>
              <span className="shrink-0 text-gray-400">Ideal customer:</span>
              <button
                onClick={() => setIdealExpanded(v => !v)}
                className="min-w-0 text-left hover:text-gray-700 cursor-pointer"
                style={{ whiteSpace: idealExpanded ? "normal" : "nowrap", overflow: idealExpanded ? "visible" : "hidden", textOverflow: idealExpanded ? "clip" : "ellipsis" }}
                title={idealExpanded ? undefined : (feature as any).idealClientCriteria}
              >
                {(feature as any).idealClientCriteria}
              </button>
            </div>
          )}
          {(feature.betaGoal || canWrite(currentUser)) && (
            <div className="mt-0.5 flex gap-2 text-sm text-gray-500" style={{ overflowWrap: "break-word", wordBreak: "break-word" }}>
              <span className="shrink-0 text-gray-400">Goal:</span>
              {feature.betaGoal ? (
                <button
                  onClick={() => setGoalExpanded(v => !v)}
                  className="min-w-0 text-left hover:text-gray-700 cursor-pointer"
                  style={{ whiteSpace: goalExpanded ? "normal" : "nowrap", overflow: goalExpanded ? "visible" : "hidden", textOverflow: goalExpanded ? "clip" : "ellipsis" }}
                  title={goalExpanded ? undefined : feature.betaGoal}
                >
                  {feature.betaGoal}
                </button>
              ) : (
                <button onClick={() => setEditOpen(true)} className="shrink-0 text-amber-600 hover:text-amber-700">
                  Add beta goal
                </button>
              )}
            </div>
          )}
        </div>
        {canWrite(currentUser) && !isClosed && (
          <button onClick={() => setEditOpen(true)}
            className="shrink-0 rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50">
            Edit
          </button>
        )}
      </div>

      {feedbackDetail && (
        <FeedbackDetailModal entry={feedbackDetail} onClose={() => setFeedbackDetail(null)} />
      )}
      {editOpen && (
        <EditFeatureModal
          feature={feature}
          onClose={() => setEditOpen(false)}
          onSaved={load}
        />
      )}
      {showCompleteModal && (
        <CompleteFeatureModal
          featureId={id}
          onDone={() => { setShowCompleteModal(false); load(); }}
          onCancel={() => { setShowCompleteModal(false); load(); }}
        />
      )}

      <EnrollmentFunnelCard funnel={funnel} />

      {/* Feedback */}
      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3">
          <h2 className="text-sm font-semibold text-gray-700">Feedback</h2>
          {fbSummary.total > 0 && (() => {
            const pct = fbSummary.positiveRate != null ? Math.round(fbSummary.positiveRate * 100) : null;
            const color = pct != null ? (pct >= 80 ? "#1D9E75" : pct >= 60 ? "#EF9F27" : "#E24B4A") : undefined;
            return (
              <span className="text-xs text-gray-500">
                <span className="font-medium text-gray-700">{fbSummary.total}</span> responses
                {pct != null && (
                  <> · <span className="font-medium" style={{ color }}>{pct}% positive</span></>
                )}
              </span>
            );
          })()}
        </div>
        {recentFeedback.length === 0 ? (
          <p className="px-4 py-6 text-sm text-gray-400">No feedback logged yet for this beta.</p>
        ) : (
          <table className="w-full divide-y divide-gray-100" style={{ tableLayout: "fixed" }}>
            <colgroup>
              <col style={{ width: "20%" }} />
              <col style={{ width: "15%" }} />
              <col className="hidden sm:table-column" style={{ width: "18%" }} />
              <col className="hidden sm:table-column" style={{ width: "12%" }} />
              <col className="hidden md:table-column" />
            </colgroup>
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Client</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Sentiment</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 hidden sm:table-cell">Feedback provider</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 hidden sm:table-cell">Date</th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 hidden md:table-cell">Notes</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {recentFeedback.map((fb: any) => {
                const parts = (fb.feedbackProviderName ?? "").trim().split(/\s+/);
                const shortName = parts.length >= 2 ? `${parts[0][0]}. ${parts[parts.length - 1]}` : fb.feedbackProviderName;
                const dateStr = new Date(fb.createdAt).toLocaleDateString("en-US", { month: "short", day: "numeric" });
                return (
                  <tr key={fb.id} className="hover:bg-gray-50 cursor-pointer" onClick={() => setFeedbackDetail(fb)}>
                    <td className="px-4 py-2.5 text-sm font-medium text-gray-900 truncate">{fb.clientName}</td>
                    <td className="px-4 py-2.5">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <SentimentBadge sentiment={fb.sentiment} />
                        {fb.isGatingRequest && (
                          <span className="inline-flex items-center rounded-full bg-red-100 px-1.5 py-0.5 text-[10px] font-medium text-red-700">Blocking</span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-2.5 text-sm text-gray-500 hidden sm:table-cell">{shortName}</td>
                    <td className="px-4 py-2.5 text-sm text-gray-500 hidden sm:table-cell">{dateStr}</td>
                    <td className="px-4 py-2.5 text-sm text-gray-400 hidden md:table-cell" style={{ maxWidth: 0 }}>
                      <span className="truncate block">{fb.notes ?? "—"}</span>
                      {fb.gatingDescription && (
                        <p className="mt-0.5 text-xs italic text-gray-400 truncate">{fb.gatingDescription}</p>
                      )}
                      {fb.jiraTicketUrl && (
                        <a href={fb.jiraTicketUrl} target="_blank" rel="noopener noreferrer"
                          className="text-xs font-medium text-blue-600 hover:text-blue-800">
                          View ticket →
                        </a>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
        {fbSummary.total > 0 && (
          <div className="px-4 py-2.5 text-right">
            <Link href={`/feedback?feature_id=${feature.id}`} className="text-xs font-medium text-blue-600 hover:text-blue-800">
              View all feedback →
            </Link>
          </div>
        )}
      </div>

      <div className="flex flex-col lg:flex-row gap-6 items-start">
        <div className="w-full space-y-4 order-2 lg:order-2 lg:flex-1 min-w-0">
          <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
          <div className="border-b border-gray-100 px-4 py-3">
            <h2 className="text-sm font-semibold text-gray-700">Enrollments</h2>
          </div>
          <table className="w-full divide-y divide-gray-100" style={{ tableLayout: "fixed" }}>
            <colgroup>
              <col style={{ width: "40%" }} />
              <col className="hidden sm:table-column" style={{ width: "20%" }} />
              <col className="hidden md:table-column" style={{ width: "20%" }} />
              <col className="hidden lg:table-column" style={{ width: "20%" }} />
            </colgroup>
            <thead className="bg-gray-50">
              <tr>
                {([
                  { key: "client",   label: "Client",   cls: "" },
                  { key: "status",   label: "Status",   cls: "hidden sm:table-cell" },
                  { key: "segment",  label: "Segment",  cls: "hidden md:table-cell" },
                  { key: "vertical", label: "Vertical", cls: "hidden lg:table-cell" },
                ] as const).map(({ key, label, cls }) => (
                  <th key={key}
                    onClick={() => toggleEnrollSort(key)}
                    className={`px-4 py-2 text-left text-xs font-medium text-gray-500 cursor-pointer select-none hover:text-gray-700 ${cls}`}>
                    {label}
                    {enrollSortCol === key
                      ? (enrollSortDir === "asc"
                        ? <svg className="ml-1 h-3 w-3 text-blue-500 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 3l4 5H4l4-5z"/></svg>
                        : <svg className="ml-1 h-3 w-3 text-blue-500 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 13L4 8h8l-4 5z"/></svg>)
                      : <svg className="ml-1 h-3 w-3 text-gray-300 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 3l3 4H5l3-4zm0 10L5 9h6l-3 4z"/></svg>}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {[...activeEnrollments].sort((a, b) => {
                if (!enrollSortCol) {
                  return ((a.client as any)?.name ?? "").localeCompare((b.client as any)?.name ?? "");
                }
                const dir = enrollSortDir === "asc" ? 1 : -1;
                const ac = a.client as any, bc = b.client as any;
                switch (enrollSortCol) {
                  case "client":   return dir * (ac?.name ?? "").localeCompare(bc?.name ?? "");
                  case "status":   return dir * a.testerStatus.localeCompare(b.testerStatus);
                  case "segment":  return dir * (ac?.segment ?? "").localeCompare(bc?.segment ?? "");
                  case "vertical": return dir * (ac?.vertical ?? "").localeCompare(bc?.vertical ?? "");
                  default: return 0;
                }
              }).map((e) => {
                const isSelected = selectedEnrollmentId === e.id;
                const c = e.client as any;
                return (
                  <tr
                    key={e.id}
                    onClick={() => setSelectedEnrollmentId(isSelected ? null : e.id)}
                    className={`cursor-pointer hover:bg-gray-50 ${e.isOverflow ? "bg-indigo-50/30" : ""}`}
                    style={isSelected ? { borderLeft: "2px solid #3C3489", backgroundColor: "#FAFAFE" } : {}}
                  >
                    <td className="px-4 py-2.5 min-w-0 overflow-hidden">
                      <div className="flex items-center gap-2 min-w-0">
                        <HealthDot health={c?.accountHealth ?? "green"} />
                        <div className="min-w-0">
                          <p className="text-sm font-medium truncate" style={isSelected ? { color: "#3C3489" } : { color: undefined }}>
                            {c?.name}
                            {e.isOverflow && (
                              <span className="ml-1.5 rounded bg-indigo-100 px-1.5 py-0.5 text-[10px] font-medium text-indigo-700">overflow</span>
                            )}
                          </p>
                          <p className="text-xs text-gray-400 truncate">
                            CSM: {c?.csmOwner?.name ?? "—"}
                            {c?.aeOwner && <span className="ml-2">· AE: {c.aeOwner.name}</span>}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-2.5 hidden sm:table-cell">
                      <StatusCell enrollment={e} canEdit={!!canWrite(currentUser)} onUpdated={load} />
                    </td>
                    <td className="px-4 py-2.5 hidden md:table-cell text-sm text-gray-600">
                      {c?.segment ?? <span className="text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-2.5 hidden lg:table-cell text-sm text-gray-600">
                      {c?.vertical ?? <span className="text-gray-400">—</span>}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {activeEnrollments.length === 0 && (
            <p className="py-8 text-center text-sm text-gray-400">No enrollments yet.</p>
          )}
          </div>

          {removedEnrollments.length > 0 && (
            <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
              <button
                type="button"
                onClick={() => setRemovedOpen((o) => !o)}
                className={`w-full flex items-center justify-between px-4 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-50 ${removedOpen ? "border-b border-gray-100" : ""}`}
              >
                <span>Removed &amp; Rejected ({removedEnrollments.length})</span>
                <svg
                  className={`h-4 w-4 text-gray-400 transition-transform ${removedOpen ? "rotate-180" : ""}`}
                  viewBox="0 0 20 20" fill="currentColor"
                >
                  <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.17l3.71-3.94a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clipRule="evenodd" />
                </svg>
              </button>
              {removedOpen && (
                <table className="w-full divide-y divide-gray-100" style={{ tableLayout: "fixed" }}>
                  <colgroup>
                    <col style={{ width: "35%" }} />
                    <col className="hidden sm:table-column" style={{ width: "15%" }} />
                    <col className="hidden md:table-column" style={{ width: "15%" }} />
                    <col className="hidden lg:table-column" style={{ width: "15%" }} />
                    <col style={{ width: "20%" }} />
                  </colgroup>
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Client</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 hidden sm:table-cell">Status</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 hidden md:table-cell">Segment</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 hidden lg:table-cell">Vertical</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500">Reason</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-50">
                    {removedEnrollments.map((e) => {
                      const c = e.client as any;
                      return (
                        <tr key={e.id} className="hover:bg-gray-50">
                          <td className="px-4 py-2.5 min-w-0 overflow-hidden">
                            <div className="flex items-center gap-2 min-w-0">
                              <HealthDot health={c?.accountHealth ?? "green"} />
                              <div className="min-w-0">
                                <p className="text-sm font-medium text-gray-900 truncate">{c?.name}</p>
                                <p className="text-xs text-gray-400 truncate">
                                  CSM: {c?.csmOwner?.name ?? "—"}
                                  {c?.aeOwner && <span className="ml-2">· AE: {c.aeOwner.name}</span>}
                                </p>
                              </div>
                            </div>
                          </td>
                          <td className="px-4 py-2.5 hidden sm:table-cell">
                            <TesterStatusBadge status={e.testerStatus} />
                          </td>
                          <td className="px-4 py-2.5 hidden md:table-cell text-sm text-gray-600">
                            {c?.segment ?? <span className="text-gray-400">—</span>}
                          </td>
                          <td className="px-4 py-2.5 hidden lg:table-cell text-sm text-gray-600">
                            {c?.vertical ?? <span className="text-gray-400">—</span>}
                          </td>
                          <td className="px-4 py-2.5 text-sm text-gray-500">
                            {e.csmRejectionReason ?? <span className="text-gray-300">—</span>}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              )}
            </div>
          )}
        </div>

        {!isClosed && (
          <div className="w-full lg:w-[30%] shrink-0 rounded-xl border border-gray-200 bg-white p-4 h-fit order-1 lg:order-1">
            <h2 className="text-sm font-semibold text-gray-700 mb-3">Add Beta Testers</h2>
            <NominatePanel
              featureId={feature.id}
              enrolledClientIds={initialEnrolledIds}
              onEnrolled={handleEnrolled}
            />
          </div>
        )}
      </div>

      {/* Enrollment drawer backdrop */}
      <div
        onClick={() => setSelectedEnrollmentId(null)}
        className="fixed inset-0 z-40 transition-opacity duration-200"
        style={{
          backgroundColor: "rgba(0,0,0,0.15)",
          opacity: selectedEnrollmentId ? 1 : 0,
          pointerEvents: selectedEnrollmentId ? "auto" : "none",
        }}
      />

      {/* Enrollment drawer */}
      {(() => {
        const selectedEnrollment = activeEnrollments.find(e => e.id === selectedEnrollmentId) ?? null;
        const drawerOpen = !!selectedEnrollment;
        return (
          <div
            className="fixed inset-y-0 right-0 z-50 flex w-[400px] flex-col overflow-hidden bg-white shadow-xl transition-transform duration-200 ease-out"
            style={{ transform: drawerOpen ? "translateX(0)" : "translateX(100%)" }}
          >
            {selectedEnrollment && (
              <EnrollmentDrawer
                key={selectedEnrollment.id}
                enrollment={selectedEnrollment}
                feature={feature}
                canWrite={!!canWrite(currentUser)}
                onClose={() => setSelectedEnrollmentId(null)}
                onUpdated={load}
                onAction={() => { setSelectedEnrollmentId(null); load(); }}
                onRemoved={(removedId) => { onRemoved(removedId); setSelectedEnrollmentId(null); }}
              />
            )}
          </div>
        );
      })()}
    </div>
  );
}

import { useEffect, useRef, useState } from "react";
import { Link, useSearch } from "wouter";
import { api } from "@/lib/api";
import { BetaStatusBadge } from "@/components/StatusBadge";
import { MiniFunnelBar } from "@/components/FunnelBar";
import type { BetaFeature, BetaStatus } from "@/lib/types";
import { NewFeatureModal } from "@/components/NewFeatureModal";
import { useCurrentUser, canWrite } from "@/hooks/useCurrentUser";
import { useInfiniteScroll } from "@/hooks/useInfiniteScroll";

function feedbackRateColor(rate: number): string {
  if (rate >= 0.8) return '#1D9E75';
  if (rate >= 0.6) return '#EF9F27';
  return '#E24B4A';
}

function FeedbackSummaryCell({ summary }: { summary: any }) {
  if (!summary || summary.total === 0) {
    return <span className="text-xs text-gray-300">No feedback yet</span>;
  }
  const rate = summary.positiveRate ?? 0;
  const pct  = Math.round(rate * 100);
  const color = feedbackRateColor(rate);
  return (
    <div className="flex items-center gap-1.5">
      <span className="text-xs text-gray-500 tabular-nums w-14 shrink-0">{summary.total} resp.</span>
      <div className="h-1.5 w-14 rounded-full bg-gray-100 overflow-hidden shrink-0">
        <div className="h-full rounded-full" style={{ width: `${pct}%`, backgroundColor: color }} />
      </div>
      <span className="text-xs font-medium tabular-nums" style={{ color }}>{pct}%</span>
    </div>
  );
}

function TrashIcon() {
  return (
    <svg className="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor">
      <path fillRule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z" clipRule="evenodd" />
    </svg>
  );
}

const ALL_STATUSES: BetaStatus[] = ["draft", "in_progress", "complete"];

const STATUS_LABELS: Record<BetaStatus, string> = {
  draft:       "Draft",
  in_progress: "In Progress",
  complete:    "Complete",
};
const TAKE = 25;

function SortIcon({ col, sortCol, sortDir }: { col: string; sortCol: string; sortDir: "asc" | "desc" }) {
  if (col !== sortCol) return <svg className="ml-1 h-3 w-3 text-gray-300 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 3l3 4H5l3-4zm0 10L5 9h6l-3 4z"/></svg>;
  return sortDir === "asc"
    ? <svg className="ml-1 h-3 w-3 text-blue-500 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 3l4 5H4l4-5z"/></svg>
    : <svg className="ml-1 h-3 w-3 text-blue-500 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 13L4 8h8l-4 5z"/></svg>;
}

export default function FeaturesPage() {
  const searchString = useSearch();
  const status = new URLSearchParams(searchString).get("status") as BetaStatus | null;
  const owner = new URLSearchParams(searchString).get("owner");

  const currentUser = useCurrentUser();
  const [features, setFeatures] = useState<BetaFeature[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [page, setPage] = useState(1);
  const [showNew, setShowNew] = useState(false);
  const [sortCol, setSortCol] = useState("end_date");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");
  const [deleteTarget, setDeleteTarget] = useState<BetaFeature | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const pageRef = useRef(1);

  function loadPage(p: number) {
    if (p === 1) setLoading(true); else setLoadingMore(true);
    const params: Record<string, string> = { page: String(p), limit: String(TAKE) };
    if (status)  params.status = status;
    if (owner)   params.owner = owner;
    if (sortCol) { params.sort = sortCol; params.dir = sortDir; }
    api.features.list(params)
      .then((d) => {
        setFeatures(prev => p === 1 ? d.features : [...prev, ...d.features]);
        setTotal(d.total);
      })
      .catch(console.error)
      .finally(() => { setLoading(false); setLoadingMore(false); });
  }

  useEffect(() => {
    pageRef.current = 1;
    setPage(1);
    setFeatures([]);
    loadPage(1);
  }, [status, owner, sortCol, sortDir]);

  function loadMore() {
    if (loadingMore || features.length >= total) return;
    const next = pageRef.current + 1;
    pageRef.current = next;
    setPage(next);
    loadPage(next);
  }

  const sentinelRef = useInfiniteScroll(loadMore, !loading && features.length < total);

  async function handleDelete() {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await api.features.remove(deleteTarget.id);
      setFeatures(prev => prev.filter(f => f.id !== deleteTarget.id));
      setTotal(t => t - 1);
      setDeleteTarget(null);
      setToast(`"${deleteTarget.name}" was deleted.`);
      setTimeout(() => setToast(null), 3500);
    } catch (e: any) {
      alert(e?.data?.error ?? "Could not delete feature.");
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="space-y-6">
      {toast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 rounded-lg bg-gray-900 px-4 py-2.5 text-sm text-white shadow-lg">
          {toast}
        </div>
      )}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-gray-900">Beta Features</h1>
        {canWrite(currentUser) && (
          <button
            onClick={() => setShowNew(true)}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            New Beta
          </button>
        )}
      </div>

      <div className="flex flex-wrap gap-2">
        <Link href="/features"
          className={`rounded-full px-3 py-1 text-xs font-medium border ${!status ? "bg-gray-900 text-white border-gray-900" : "bg-white text-gray-600 border-gray-200 hover:bg-gray-50"}`}>
          All
        </Link>
        {ALL_STATUSES.map((s) => (
          <Link key={s} href={`/features?status=${s}`}
            className={`rounded-full px-3 py-1 text-xs font-medium border ${status === s ? "bg-gray-900 text-white border-gray-900" : "bg-white text-gray-600 border-gray-200 hover:bg-gray-50"}`}>
            {STATUS_LABELS[s]}
          </Link>
        ))}
      </div>

      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        {loading ? (
          <div className="py-12 text-center text-sm text-gray-400">Loading…</div>
        ) : features.length === 0 ? (
          <div className="py-12 text-center text-sm text-gray-400">
            No features found.{status && " Try clearing the filter."}
          </div>
        ) : (
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                {([
                  { key: "name",       label: "Feature",    cls: "" },
                  { key: "status",     label: "Status",     cls: "hidden sm:table-cell" },
                  { key: "end_date",   label: "End date",   cls: "hidden sm:table-cell" },
                  { key: "enrollment", label: "Enrollment", cls: "hidden md:table-cell" },
                  { key: "feedback",   label: "Feedback",   cls: "hidden lg:table-cell" },
                  { key: "pm",         label: "Owner PM",   cls: "hidden xl:table-cell" },
                ] as const).map(({ key, label, cls }) => (
                  <th key={key}
                    className={`px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 cursor-pointer select-none hover:text-gray-700 ${cls}`}
                    onClick={() => {
                      if (sortCol === key) setSortDir(d => d === "asc" ? "desc" : "asc");
                      else { setSortCol(key); setSortDir("asc"); }
                    }}>
                    {label}<SortIcon col={key} sortCol={sortCol} sortDir={sortDir} />
                  </th>
                ))}
                <th className="px-4 py-3 text-right text-xs font-medium uppercase tracking-wide text-gray-500">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {features.map((f) => {
                const funnel = (f as any).enrollmentFunnel ?? { nominated: 0, approved: 0, enrolled: 0, using: 0, accepted: 0, total: 0 };
                return (
                  <tr key={f.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <Link href={`/features/${(f as any).slug ?? f.id}`} className="block">
                        <p className="text-sm font-medium text-gray-900 hover:text-blue-600">{f.name}</p>
                        {f.startDate ? (() => {
                          const d = new Date(f.startDate + 'T00:00:00');
                          const started = d <= new Date();
                          return (
                            <p className="text-xs text-gray-400">
                              {started ? "Started" : "Starts"} {d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}
                            </p>
                          );
                        })() : (
                          <p className="text-xs text-gray-400">Start date not set</p>
                        )}
                      </Link>
                    </td>
                    <td className="px-4 py-3 hidden sm:table-cell">
                      <div className="flex items-center gap-1.5">
                        <BetaStatusBadge status={f.status} />
                        {!(f as any).betaGoal && (
                          <span
                            title="Missing beta goal"
                            className="inline-flex items-center rounded-full border border-amber-200 bg-amber-50 px-2 py-0.5 text-[10px] font-medium text-amber-700"
                          >
                            Missing beta goal
                          </span>
                        )}
                        {(f as any).pendingApprovalCount > 0 && (
                          <span
                            title={`${(f as any).pendingApprovalCount} enrollment${(f as any).pendingApprovalCount === 1 ? "" : "s"} pending CSM approval`}
                            className="inline-flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-amber-500 px-1 text-[10px] font-bold text-white cursor-default"
                          >
                            {(f as any).pendingApprovalCount}
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3 hidden sm:table-cell">
                      {(f as any).projectedEndDate ? (
                        <span className={`text-sm ${new Date((f as any).projectedEndDate + 'T00:00:00') < new Date() ? "text-red-500" : "text-gray-700"}`}>
                          {new Date((f as any).projectedEndDate + 'T00:00:00').toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}
                        </span>
                      ) : (
                        <span className="text-sm text-gray-300">—</span>
                      )}
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      <MiniFunnelBar funnel={funnel} />
                    </td>
                    <td className="px-4 py-3 hidden lg:table-cell"><FeedbackSummaryCell summary={(f as any).feedbackSummary} /></td>
                    <td className="px-4 py-3 hidden xl:table-cell"><span className="text-sm text-gray-600">{f.ownerPm?.name ?? "—"}</span></td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <Link href={`/features/${(f as any).slug ?? f.id}`} className="text-xs font-medium text-blue-600 hover:text-blue-800">View →</Link>
                        {canWrite(currentUser) && (
                          <button
                            onClick={() => setDeleteTarget(f)}
                            className="text-red-400 hover:text-red-600"
                            title="Delete feature"
                          >
                            <TrashIcon />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      <div ref={sentinelRef} className="h-1" />
      {loadingMore && <div className="py-3 text-center text-sm text-gray-400">Loading more…</div>}

      {showNew && <NewFeatureModal onClose={() => setShowNew(false)} onCreated={() => { pageRef.current = 1; setPage(1); setFeatures([]); loadPage(1); }} />}

      {deleteTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-sm rounded-xl bg-white shadow-xl">
            <div className="px-6 py-5">
              <h2 className="text-base font-semibold text-gray-900 mb-2">Delete "{deleteTarget.name}"?</h2>
              <p className="text-sm text-gray-600">
                This will permanently delete the beta and all associated enrollments, feedback, and outreach data. This cannot be undone.
              </p>
            </div>
            <div className="flex justify-end gap-3 border-t border-gray-200 px-6 py-4">
              <button
                onClick={() => setDeleteTarget(null)}
                disabled={deleting}
                className="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                onClick={handleDelete}
                disabled={deleting}
                className="rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50"
              >
                {deleting ? "Deleting…" : "Delete"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

import { useEffect, useRef, useState } from "react";
import { Link, useSearch } from "wouter";
import { api } from "@/lib/api";
import { BetaStatusBadge } from "@/components/StatusBadge";
import { SlotFill } from "@/components/SlotFill";
import type { BetaFeature, BetaStatus } from "@/lib/types";
import { NewFeatureModal } from "@/components/NewFeatureModal";
import { useCurrentUser, canWrite } from "@/hooks/useCurrentUser";
import { useInfiniteScroll } from "@/hooks/useInfiniteScroll";

const ALL_STATUSES: BetaStatus[] = ["draft", "in_progress", "complete"];
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
  const [sortCol, setSortCol] = useState("");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");
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

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-gray-900">Features</h1>
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
            {s.replace("_", " ").replace(/^\w/, c => c.toUpperCase())}
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
                  { key: "name",   label: "Feature",  cls: "" },
                  { key: "status", label: "Status",   cls: "hidden sm:table-cell" },
                  { key: "slots",  label: "Slots",    cls: "hidden md:table-cell" },
                  { key: "pm",     label: "Owner PM", cls: "hidden xl:table-cell" },
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
                const filled   = Number((f as any).filledCount   ?? 0);
                const enrolled = Number((f as any).enrolledCount ?? 0);
                const outreach = Number((f as any).outreachCount ?? 0);
                const durationDays = f.closedAt
                  ? Math.round((new Date(f.closedAt).getTime() - new Date(f.startDate).getTime()) / 86400000)
                  : Math.round((Date.now() - new Date(f.startDate).getTime()) / 86400000);
                return (
                  <tr key={f.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <Link href={`/features/${(f as any).slug ?? f.id}`} className="block">
                        <p className="text-sm font-medium text-gray-900 hover:text-blue-600">{f.name}</p>
                        <p className="text-xs text-gray-400">{durationDays}d elapsed</p>
                      </Link>
                    </td>
                    <td className="px-4 py-3 hidden sm:table-cell">
                      <div className="flex items-center gap-1.5">
                        <BetaStatusBadge status={f.status} />
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
                    <td className="px-4 py-3 hidden md:table-cell"><SlotFill enrolled={enrolled} outreach={outreach} filled={filled} target={f.targetTesterCount} /></td>
                    <td className="px-4 py-3 hidden xl:table-cell"><span className="text-sm text-gray-600">{f.ownerPm?.name ?? "—"}</span></td>
                    <td className="px-4 py-3 text-right">
                      <Link href={`/features/${(f as any).slug ?? f.id}`} className="text-xs font-medium text-blue-600 hover:text-blue-800">View →</Link>
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
    </div>
  );
}

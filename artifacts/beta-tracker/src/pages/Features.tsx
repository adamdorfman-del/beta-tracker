import { useEffect, useRef, useState } from "react";
import { Link, useSearch } from "wouter";
import { api } from "@/lib/api";
import { BetaStatusBadge } from "@/components/StatusBadge";
import { SlotFill } from "@/components/SlotFill";
import type { BetaFeature, BetaStatus } from "@/lib/types";
import { NewFeatureModal } from "@/components/NewFeatureModal";
import { useCurrentUser, canWrite } from "@/hooks/useCurrentUser";
import { useInfiniteScroll } from "@/hooks/useInfiniteScroll";

const ALL_STATUSES: BetaStatus[] = ["draft", "recruiting", "outreach_sent", "full", "in_progress", "closing", "closed"];
const TAKE = 25;

export default function FeaturesPage() {
  const searchString = useSearch();
  const status = new URLSearchParams(searchString).get("status") as BetaStatus | null;

  const currentUser = useCurrentUser();
  const [features, setFeatures] = useState<BetaFeature[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [page, setPage] = useState(1);
  const [showNew, setShowNew] = useState(false);
  const pageRef = useRef(1);

  function loadPage(p: number) {
    if (p === 1) setLoading(true); else setLoadingMore(true);
    const params: Record<string, string> = { page: String(p), limit: String(TAKE) };
    if (status) params.status = status;
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
  }, [status]);

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
            {s.replace("_", " ")}
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
                <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">Feature</th>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden sm:table-cell">Status</th>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden md:table-cell">Slots</th>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden xl:table-cell">Owner PM</th>
                <th className="px-4 py-3 text-right text-xs font-medium uppercase tracking-wide text-gray-500">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {features.map((f) => {
                const enrollments = (f as any).enrollments ?? [];
                const confirmed = enrollments.filter((e: any) => ["confirmed", "active", "completed"].includes(e.testerStatus)).length;
                const durationDays = f.closedAt
                  ? Math.round((new Date(f.closedAt).getTime() - new Date(f.startDate).getTime()) / 86400000)
                  : Math.round((Date.now() - new Date(f.startDate).getTime()) / 86400000);
                return (
                  <tr key={f.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <Link href={`/features/${f.id}`} className="block">
                        <p className="text-sm font-medium text-gray-900 hover:text-blue-600">{f.name}</p>
                        <p className="text-xs text-gray-400">{durationDays}d elapsed</p>
                      </Link>
                    </td>
                    <td className="px-4 py-3 hidden sm:table-cell"><BetaStatusBadge status={f.status} /></td>
                    <td className="px-4 py-3 hidden md:table-cell"><SlotFill confirmed={confirmed} target={f.targetTesterCount} /></td>
                    <td className="px-4 py-3 hidden xl:table-cell"><span className="text-sm text-gray-600">{f.ownerPm?.name ?? "—"}</span></td>
                    <td className="px-4 py-3 text-right">
                      <Link href={`/features/${f.id}`} className="text-xs font-medium text-blue-600 hover:text-blue-800">View →</Link>
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

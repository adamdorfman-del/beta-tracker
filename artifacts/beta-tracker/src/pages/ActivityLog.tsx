import { useCallback, useEffect, useRef, useState } from "react";
import { useLocation } from "wouter";
import { api } from "@/lib/api";

// ── category badge ────────────────────────────────────────────────────────────

const CATEGORY_STYLES: Record<string, { label: string; cls: string }> = {
  enrollment: { label: "Enrollment",   cls: "bg-purple-100 text-purple-700" },
  approval:   { label: "Approval",     cls: "bg-green-100 text-green-700"   },
  feedback:   { label: "Feedback",     cls: "bg-blue-100 text-blue-700"     },
  removal:    { label: "Removal",      cls: "bg-red-100 text-red-700"       },
  outreach:   { label: "Outreach",     cls: "bg-amber-100 text-amber-700"   },
  status:     { label: "Status",       cls: "bg-gray-100 text-gray-600"     },
  feature:    { label: "Feature",      cls: "bg-gray-100 text-gray-600"     },
  admin:      { label: "Admin",        cls: "bg-orange-100 text-orange-700" },
};

function CategoryBadge({ category }: { category: string }) {
  const cfg = CATEGORY_STYLES[category] ?? { label: category, cls: "bg-gray-100 text-gray-600" };
  return (
    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${cfg.cls}`}>
      {cfg.label}
    </span>
  );
}

// ── date formatter ────────────────────────────────────────────────────────────

function formatDate(iso: string) {
  const d = new Date(iso);
  return d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" }) +
    " at " + d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
}

// ── human-readable action labels for the filter dropdown ─────────────────────

const ACTION_LABELS: Record<string, string> = {
  nominated:            "Enrollment added",
  removed:              "Enrollment removed",
  status_change:        "Status changed",
  csm_approved:         "CSM approval given",
  csm_approval_revoked: "CSM approval revoked",
  csm_rejected:         "CSM rejection",
  feedback_logged:      "Feedback logged",
  feedback_edited:      "Feedback edited",
  feedback_deleted:     "Feedback deleted",
  outreach_sent:        "Outreach sent",
  created:              "Feature created",
  updated:              "Feature updated",
  deleted:              "Feature deleted",
  closed:               "Feature closed",
  cloned:               "Feature cloned",
  beta_eligibility_override: "Beta eligibility override",
};

const DATE_RANGE_OPTIONS = [
  { value: "",   label: "All time" },
  { value: "1",  label: "Today" },
  { value: "7",  label: "Last 7 days" },
  { value: "30", label: "Last 30 days" },
  { value: "90", label: "Last 90 days" },
];

const PAGE_SIZE = 50;

// ── page ─────────────────────────────────────────────────────────────────────

export default function ActivityLogPage() {
  const [, navigate] = useLocation();

  const [logs, setLogs]           = useState<any[]>([]);
  const [total, setTotal]         = useState(0);
  const [loading, setLoading]     = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [users, setUsers]         = useState<any[]>([]);
  const [features, setFeatures]   = useState<any[]>([]);
  const [actions, setActions]     = useState<string[]>([]);

  const [filterUser, setFilterUser]     = useState("");
  const [filterAction, setFilterAction] = useState("");
  const [filterFeature, setFilterFeature] = useState("");
  const [filterDays, setFilterDays]     = useState("");

  // Track offset for "load more"
  const offsetRef = useRef(0);

  function buildParams(offset: number) {
    const p: Record<string, string> = { limit: String(PAGE_SIZE), offset: String(offset) };
    if (filterUser)    p.user_id    = filterUser;
    if (filterAction)  p.action     = filterAction;
    if (filterFeature) p.feature_id = filterFeature;
    if (filterDays)    p.days       = filterDays;
    return p;
  }

  const load = useCallback(async () => {
    setLoading(true);
    offsetRef.current = 0;
    try {
      const data = await api.auditLogs.list(buildParams(0));
      setLogs(data.logs ?? []);
      setTotal(data.total ?? 0);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filterUser, filterAction, filterFeature, filterDays]);

  async function loadMore() {
    const next = offsetRef.current + PAGE_SIZE;
    setLoadingMore(true);
    try {
      const data = await api.auditLogs.list(buildParams(next));
      setLogs(prev => [...prev, ...(data.logs ?? [])]);
      offsetRef.current = next;
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingMore(false);
    }
  }

  // Initial meta load
  useEffect(() => {
    Promise.all([
      api.users.list().then((d: any) => setUsers(d.users ?? [])),
      api.features.list({ limit: "200" }).then((d: any) => setFeatures(d.features ?? [])),
      api.auditLogs.actions().then((d: any) => setActions(d.actions ?? [])),
    ]).catch(console.error);
  }, []);

  useEffect(() => { load(); }, [load]);

  const hasMore = logs.length < total;

  function handleUserClick(userId: string) {
    setFilterUser(prev => prev === userId ? "" : userId);
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-6 space-y-5">
      <h1 className="text-xl font-semibold text-gray-900">Activity Log</h1>

      {/* ── filters ── */}
      <div className="flex flex-wrap gap-3">
        {/* User */}
        <select
          value={filterUser}
          onChange={e => setFilterUser(e.target.value)}
          className="rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-sm text-gray-700 focus:outline-none focus:border-blue-400"
        >
          <option value="">All users</option>
          {users.map((u: any) => (
            <option key={u.id} value={u.id}>{u.name}</option>
          ))}
        </select>

        {/* Action */}
        <select
          value={filterAction}
          onChange={e => setFilterAction(e.target.value)}
          className="rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-sm text-gray-700 focus:outline-none focus:border-blue-400"
        >
          <option value="">All actions</option>
          {actions.map(a => (
            <option key={a} value={a}>{ACTION_LABELS[a] ?? a}</option>
          ))}
        </select>

        {/* Feature */}
        <select
          value={filterFeature}
          onChange={e => setFilterFeature(e.target.value)}
          className="rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-sm text-gray-700 focus:outline-none focus:border-blue-400"
        >
          <option value="">All features</option>
          {features.map((f: any) => (
            <option key={f.id} value={f.id}>{f.name}</option>
          ))}
        </select>

        {/* Date range */}
        <select
          value={filterDays}
          onChange={e => setFilterDays(e.target.value)}
          className="rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-sm text-gray-700 focus:outline-none focus:border-blue-400"
        >
          {DATE_RANGE_OPTIONS.map(o => (
            <option key={o.value} value={o.value}>{o.label}</option>
          ))}
        </select>

        {(filterUser || filterAction || filterFeature || filterDays) && (
          <button
            onClick={() => { setFilterUser(""); setFilterAction(""); setFilterFeature(""); setFilterDays(""); }}
            className="rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-sm text-gray-500 hover:text-gray-700 hover:bg-gray-50"
          >
            Clear filters
          </button>
        )}
      </div>

      {/* ── table ── */}
      <div className="rounded-xl border border-gray-200 bg-white overflow-hidden">
        {loading ? (
          <div className="py-16 text-center text-sm text-gray-400">Loading…</div>
        ) : logs.length === 0 ? (
          <div className="py-16 text-center text-sm text-gray-400">No activity found.</div>
        ) : (
          <>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50 text-xs font-medium text-gray-500 uppercase tracking-wide">
                  <th className="px-4 py-3 text-left">User</th>
                  <th className="px-4 py-3 text-left">Action</th>
                  <th className="px-4 py-3 text-left hidden sm:table-cell">Category</th>
                  <th className="px-4 py-3 text-left hidden md:table-cell">Date / Time</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {logs.map((log: any) => (
                  <tr key={log.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 whitespace-nowrap">
                      <button
                        className="text-sm font-medium text-blue-600 hover:underline"
                        onClick={() => handleUserClick(log.actorId)}
                        title={filterUser === log.actorId ? "Clear user filter" : "Filter by this user"}
                      >
                        {log.actorName ?? "Unknown"}
                      </button>
                    </td>
                    <td className="px-4 py-3 text-gray-700 max-w-sm">
                      {log.description}
                    </td>
                    <td className="px-4 py-3 hidden sm:table-cell">
                      <CategoryBadge category={log.category} />
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell text-gray-500 whitespace-nowrap">
                      {formatDate(log.createdAt)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {hasMore && (
              <div className="border-t border-gray-100 px-4 py-3 text-center">
                <button
                  onClick={loadMore}
                  disabled={loadingMore}
                  className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-600 hover:bg-gray-50 disabled:opacity-50"
                >
                  {loadingMore ? "Loading…" : `Load more (${total - logs.length} remaining)`}
                </button>
              </div>
            )}
          </>
        )}
      </div>

      <p className="text-xs text-gray-400">
        Showing {logs.length} of {total} entries
      </p>
    </div>
  );
}

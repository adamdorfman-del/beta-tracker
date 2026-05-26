import React, { useEffect, useRef, useState } from "react";
import { Link, useSearch, useLocation } from "wouter";
import { api } from "@/lib/api";
import { HealthDot } from "@/components/HealthDot";
import { BetaStatusBadge, TesterStatusBadge } from "@/components/StatusBadge";
import { ClientModal } from "@/components/ClientModal";
import { ClientImportModal } from "@/components/ClientImportModal";
import { useInfiniteScroll } from "@/hooks/useInfiniteScroll";
import { MultiSelect } from "@/components/MultiSelect";

const SEGMENTS = ["Strategic", "Enterprise", "Commercial", "Professional", "Channel"];

const SEGMENT_COLORS: Record<string, string> = {
  Strategic:    "bg-purple-50 text-purple-700",
  Enterprise:   "bg-indigo-50 text-indigo-700",
  Commercial:   "bg-blue-50 text-blue-700",
  Professional: "bg-teal-50 text-teal-700",
  Channel:      "bg-orange-50 text-orange-700",
};

function SortIcon({ col, sortCol, sortDir }: { col: string; sortCol: string; sortDir: "asc" | "desc" }) {
  if (col !== sortCol) return (
    <svg className="ml-1 h-3 w-3 text-gray-300 inline" viewBox="0 0 16 16" fill="currentColor">
      <path d="M8 3l3 4H5l3-4zm0 10L5 9h6l-3 4z" />
    </svg>
  );
  return sortDir === "asc"
    ? <svg className="ml-1 h-3 w-3 text-blue-500 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 3l4 5H4l4-5z"/></svg>
    : <svg className="ml-1 h-3 w-3 text-blue-500 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 13L4 8h8l-4 5z"/></svg>;
}

export default function ClientsPage() {
  const searchString = useSearch();
  const [, navigate] = useLocation();
  const params = new URLSearchParams(searchString);
  const health   = params.get("health")  ?.split(",").filter(Boolean) ?? [];
  const segment  = params.get("segment") ?.split(",").filter(Boolean) ?? [];
  const vertical = params.get("vertical")?.split(",").filter(Boolean) ?? [];
  const csmId    = params.get("csm")   ?? "";
  const search   = params.get("search") ?? "";
  const [searchInput, setSearchInput] = useState(search);
  const pageRef = useRef(1);
  const take = 25;

  const [clients, setClients]         = useState<any[]>([]);
  const [total, setTotal]             = useState(0);
  const [csms, setCsms]               = useState<any[]>([]);
  const [verticals, setVerticals]     = useState<string[]>([]);
  const [loading, setLoading]         = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [sortCol, setSortCol]         = useState("name");
  const [sortDir, setSortDir]         = useState<"asc" | "desc">("asc");
  const [expandId, setExpandId]       = useState<string | null>(null);
  const [expandedClient, setExpandedClient] = useState<any>(null);
  const [showAdd, setShowAdd]         = useState(false);
  const [editTarget, setEditTarget]   = useState<any | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<any | null>(null);
  const [deleting, setDeleting]       = useState(false);
  const [showImport, setShowImport]   = useState(false);

  function loadPage(p: number) {
    if (p === 1) setLoading(true); else setLoadingMore(true);
    const q: Record<string, string> = { page: String(p), limit: "25", sort: sortCol, dir: sortDir };
    if (health.length > 0)   q.health   = health.join(",");
    if (csmId)               q.csm      = csmId;
    if (segment.length > 0)  q.segment  = segment.join(",");
    if (vertical.length > 0) q.vertical = vertical.join(",");
    if (search)              q.search   = search;
    api.clients.list(q)
      .then((d) => {
        setClients(prev => p === 1 ? (d.clients ?? []) : [...prev, ...(d.clients ?? [])]);
        setTotal(d.total ?? 0);
      })
      .catch(console.error)
      .finally(() => { setLoading(false); setLoadingMore(false); });
  }

  useEffect(() => {
    api.users.list().then((d) => setCsms((d.users ?? []).filter((u: any) => u.role === "csm" || u.role === "admin"))).catch(() => {});
    api.clients.verticals().then((d) => setVerticals(d.verticals ?? [])).catch(() => {});
  }, []);

  useEffect(() => {
    pageRef.current = 1;
    setClients([]);
    loadPage(1);
  }, [health.join(","), csmId, segment.join(","), vertical.join(","), search, sortCol, sortDir]);

  useEffect(() => {
    const t = setTimeout(() => navigate(buildLink({ search: searchInput || null })), 300);
    return () => clearTimeout(t);
  }, [searchInput]);

  function loadMore() {
    if (loadingMore || clients.length >= total) return;
    const next = pageRef.current + 1;
    pageRef.current = next;
    loadPage(next);
  }

  const sentinelRef = useInfiniteScroll(loadMore, !loading && clients.length < total);

  useEffect(() => {
    if (!expandId) { setExpandedClient(null); return; }
    api.clients.get(expandId).then(setExpandedClient).catch(() => {});
  }, [expandId]);

  function buildLink(updates: Record<string, string | string[] | null>) {
    const p = new URLSearchParams(searchString);
    for (const [k, v] of Object.entries(updates)) {
      if (!v || (Array.isArray(v) && v.length === 0)) p.delete(k);
      else p.set(k, Array.isArray(v) ? v.join(",") : v);
    }
    return `/clients?${p.toString()}`;
  }

  async function handleDelete() {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await api.clients.remove(deleteTarget.id);
      setDeleteTarget(null);
      pageRef.current = 1;
      setClients([]);
      loadPage(1);
    } catch (e: any) {
      alert(e?.data?.error ?? "Could not delete client.");
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <h1 className="text-2xl font-semibold text-gray-900">Clients</h1>
        <div className="flex gap-2">
          <button onClick={() => setShowImport(true)}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
            Import CSV
          </button>
          <button onClick={() => setShowAdd(true)}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700">
            + Add client
          </button>
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <input
          type="search"
          placeholder="Search clients…"
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          className="w-52 rounded-lg border border-gray-200 px-3 py-1.5 text-sm bg-white"
        />
        <MultiSelect
          label="Health"
          options={["green", "yellow", "red"]}
          selected={health}
          onChange={(v) => navigate(buildLink({ health: v }))}
          labelMap={{ green: "Green", yellow: "Yellow", red: "Red" }}
          className="w-32"
        />
        <MultiSelect
          label="Segment"
          options={SEGMENTS}
          selected={segment}
          onChange={(v) => navigate(buildLink({ segment: v }))}
          className="w-36"
        />
        <MultiSelect
          label="Vertical"
          options={verticals}
          selected={vertical}
          onChange={(v) => navigate(buildLink({ vertical: v }))}
          className="w-36"
        />
        <select className="w-36 rounded-lg border border-gray-200 px-3 py-1.5 text-sm bg-white"
          value={csmId} onChange={(e) => navigate(buildLink({ csm: e.target.value }))}>
          <option value="">All CSMs</option>
          {csms.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>
        {(health.length > 0 || segment.length > 0 || vertical.length > 0 || csmId || search) && (
          <button onClick={() => { setSearchInput(""); navigate("/clients"); }} className="text-sm text-gray-400 hover:text-gray-600">
            Clear filters
          </button>
        )}
      </div>

      {loading ? (
        <div className="py-12 text-center text-sm text-gray-400">Loading…</div>
      ) : (
        <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                {([
                  { key: "name",     label: "Client",   cls: "" },
                  { key: "segment",  label: "Segment",  cls: "hidden sm:table-cell" },
                  { key: "health",   label: "Health",   cls: "hidden md:table-cell" },
                  { key: "csm",      label: "CSM / AE", cls: "hidden lg:table-cell" },
                  { key: "vertical", label: "Vertical", cls: "hidden xl:table-cell" },
                  { key: "betas",    label: "Betas",    cls: "hidden xl:table-cell" },
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
              {clients.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-sm text-gray-400">No clients found.</td>
                </tr>
              ) : clients.map((c) => (
                <React.Fragment key={c.id}>
                  <tr className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <button onClick={() => setExpandId(expandId === c.id ? null : c.id)}
                        className="text-left group">
                        <p className="text-sm font-medium text-gray-900 group-hover:text-blue-600">{c.name}</p>
                        {c.crmId && <p className="text-xs text-gray-400">{c.crmId}</p>}
                      </button>
                    </td>
                    <td className="px-4 py-3 hidden sm:table-cell">
                      {c.segment
                        ? <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${SEGMENT_COLORS[c.segment] ?? "bg-gray-100 text-gray-600"}`}>{c.segment}</span>
                        : <span className="text-xs text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      <HealthDot health={c.accountHealth} showLabel />
                    </td>
                    <td className="px-4 py-3 hidden lg:table-cell text-sm text-gray-600">
                      <p>{c.csmOwner?.name ?? "—"}</p>
                      {c.aeOwner && <p className="text-xs text-gray-400">AE: {c.aeOwner.name}</p>}
                    </td>
                    <td className="px-4 py-3 hidden xl:table-cell text-sm text-gray-600">
                      {c.vertical ?? <span className="text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-3 hidden xl:table-cell">
                      {c.betaCount > 0
                        ? <span className="text-sm font-medium text-gray-900">{c.betaCount}</span>
                        : <span className="text-sm text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <button onClick={() => setEditTarget(c)}
                          className="text-xs font-medium text-gray-600 hover:text-gray-900">
                          Edit
                        </button>
                        <button onClick={() => setDeleteTarget(c)}
                          className="text-xs font-medium text-red-500 hover:text-red-700">
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                  {expandId === c.id && (
                    <tr>
                      <td colSpan={7} className="px-4 py-4 bg-gray-50">
                        <div className="grid grid-cols-2 gap-x-6 gap-y-2 sm:grid-cols-3 lg:grid-cols-4 mb-4 text-xs text-gray-500">
                          {c.primaryContactName && (
                            <div>
                              <p className="font-medium text-gray-600">Primary Contact</p>
                              <p>{c.primaryContactName}</p>
                              {c.primaryContactEmail && <p className="text-gray-400">{c.primaryContactEmail}</p>}
                            </div>
                          )}
                          {c.aeOwner && (
                            <div>
                              <p className="font-medium text-gray-600">AE</p>
                              <p>{c.aeOwner.name}</p>
                              <p className="text-gray-400">{c.aeOwner.email}</p>
                            </div>
                          )}
                          {c.tier != null       && <div><p className="font-medium text-gray-600">Tier</p><p>T{c.tier}</p></div>}
                          {c.vertical           && <div><p className="font-medium text-gray-600">Vertical</p><p>{c.vertical}</p></div>}
                          {c.contractRenewalDate && <div><p className="font-medium text-gray-600">Renewal Date</p><p>{new Date(c.contractRenewalDate).toLocaleDateString()}</p></div>}
                          {c.productSubscriptions && <div><p className="font-medium text-gray-600">Products</p><p>{c.productSubscriptions}</p></div>}
                          {c.lastOutreachDate   && <div><p className="font-medium text-gray-600">Last Outreach</p><p>{new Date(c.lastOutreachDate).toLocaleDateString()}</p></div>}
                          {c.notes              && <div className="col-span-2"><p className="font-medium text-gray-600">Notes</p><p>{c.notes}</p></div>}
                        </div>
                        {expandedClient?.id === c.id ? (
                          <div>
                            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                              Beta history ({(expandedClient.enrollments ?? []).length})
                            </p>
                            {(expandedClient.enrollments ?? []).length === 0
                              ? <p className="text-xs text-gray-400">No enrollments yet.</p>
                              : <div className="space-y-1.5">
                                  {(expandedClient.enrollments ?? []).map((e: any) => (
                                    <div key={e.id} className="flex items-center justify-between">
                                      <Link href={`/features/${(e as any).feature?.slug ?? e.featureId}`} className="text-sm font-medium text-blue-600 hover:underline">
                                        {e.feature?.name ?? e.featureId}
                                      </Link>
                                      <div className="flex items-center gap-2">
                                        <TesterStatusBadge status={e.testerStatus} />
                                        {e.feature?.status && <BetaStatusBadge status={e.feature.status} />}
                                        <span className="text-xs text-gray-400">{new Date(e.createdAt).toLocaleDateString()}</span>
                                      </div>
                                    </div>
                                  ))}
                                </div>}
                          </div>
                        ) : (
                          <p className="text-xs text-gray-400">Loading history…</p>
                        )}
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div ref={sentinelRef} className="h-1" />
      {loadingMore && <div className="py-3 text-center text-sm text-gray-400">Loading more…</div>}
      {(showAdd || editTarget) && (
        <ClientModal
          client={editTarget ?? undefined}
          onClose={() => { setShowAdd(false); setEditTarget(null); }}
          onSaved={() => { pageRef.current = 1; setClients([]); loadPage(1); }}
        />
      )}

      {showImport && (
        <ClientImportModal
          onClose={() => setShowImport(false)}
          onImported={() => { pageRef.current = 1; setClients([]); loadPage(1); }}
        />
      )}

      {deleteTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-sm rounded-xl bg-white shadow-xl">
            <div className="px-6 py-5">
              <h2 className="text-base font-semibold text-gray-900 mb-2">Delete client?</h2>
              <p className="text-sm text-gray-600">
                <span className="font-medium">{deleteTarget.name}</span> will be permanently removed. This will fail if they have existing beta enrollments.
              </p>
            </div>
            <div className="flex justify-end gap-3 border-t border-gray-200 px-6 py-4">
              <button onClick={() => setDeleteTarget(null)} className="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
                Cancel
              </button>
              <button onClick={handleDelete} disabled={deleting}
                className="rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50">
                {deleting ? "Deleting…" : "Delete"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

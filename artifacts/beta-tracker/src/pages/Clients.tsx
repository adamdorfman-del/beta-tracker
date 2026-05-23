import React, { useEffect, useRef, useState } from "react";
import { Link, useSearch, useLocation } from "wouter";
import { api } from "@/lib/api";
import { HealthDot } from "@/components/HealthDot";
import { BetaStatusBadge } from "@/components/StatusBadge";
import { ClientModal } from "@/components/ClientModal";
import { ClientImportModal } from "@/components/ClientImportModal";
import { useInfiniteScroll } from "@/hooks/useInfiniteScroll";

const SEGMENTS = ["Strategic", "Enterprise", "Commercial", "Professional", "Channel"];

const SEGMENT_COLORS: Record<string, string> = {
  Strategic:    "bg-purple-50 text-purple-700",
  Enterprise:   "bg-indigo-50 text-indigo-700",
  Commercial:   "bg-blue-50 text-blue-700",
  Professional: "bg-teal-50 text-teal-700",
  Channel:      "bg-orange-50 text-orange-700",
};

export default function ClientsPage() {
  const searchString = useSearch();
  const [, navigate] = useLocation();
  const params = new URLSearchParams(searchString);
  const health  = params.get("health")  ?? "";
  const csmId   = params.get("csm")     ?? "";
  const segment = params.get("segment") ?? "";
  const search  = params.get("search")  ?? "";
  const [searchInput, setSearchInput] = useState(search);
  const pageRef = useRef(1);
  const take = 25;

  const [clients, setClients]         = useState<any[]>([]);
  const [total, setTotal]             = useState(0);
  const [csms, setCsms]               = useState<any[]>([]);
  const [loading, setLoading]         = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [expandId, setExpandId]       = useState<string | null>(null);
  const [expandedClient, setExpandedClient] = useState<any>(null);
  const [showAdd, setShowAdd]         = useState(false);
  const [editTarget, setEditTarget]   = useState<any | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<any | null>(null);
  const [deleting, setDeleting]       = useState(false);
  const [showImport, setShowImport]   = useState(false);

  function loadPage(p: number) {
    if (p === 1) setLoading(true); else setLoadingMore(true);
    const q: Record<string, string> = { page: String(p), limit: "25" };
    if (health)  q.health  = health;
    if (csmId)   q.csm     = csmId;
    if (segment) q.segment = segment;
    if (search)  q.search  = search;
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
  }, []);

  useEffect(() => {
    pageRef.current = 1;
    setClients([]);
    loadPage(1);
  }, [health, csmId, segment, search]);

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

  function buildLink(updates: Record<string, string | null>) {
    const p = new URLSearchParams(searchString);
    for (const [k, v] of Object.entries(updates)) {
      if (v) p.set(k, v); else p.delete(k);
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

      <div className="flex flex-wrap gap-3">
        <input
          type="search"
          placeholder="Search clients…"
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          className="rounded-lg border border-gray-200 px-3 py-1.5 text-sm bg-white min-w-[200px]"
        />
        <select className="rounded-lg border border-gray-200 px-3 py-1.5 text-sm bg-white"
          value={health} onChange={(e) => navigate(buildLink({ health: e.target.value }))}>
          <option value="">All health</option>
          <option value="green">Green</option>
          <option value="yellow">Yellow</option>
          <option value="red">Red</option>
        </select>
        <select className="rounded-lg border border-gray-200 px-3 py-1.5 text-sm bg-white"
          value={segment} onChange={(e) => navigate(buildLink({ segment: e.target.value }))}>
          <option value="">All segments</option>
          {SEGMENTS.map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
        <select className="rounded-lg border border-gray-200 px-3 py-1.5 text-sm bg-white"
          value={csmId} onChange={(e) => navigate(buildLink({ csm: e.target.value }))}>
          <option value="">All CSMs</option>
          {csms.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>
        {(health || segment || csmId || search) && (
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
                <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">Client</th>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden sm:table-cell">Segment</th>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden md:table-cell">Health</th>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden lg:table-cell">Primary Contact</th>
                <th className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500 hidden xl:table-cell">CSM</th>
                <th className="px-4 py-3 text-right text-xs font-medium uppercase tracking-wide text-gray-500">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {clients.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-sm text-gray-400">No clients found.</td>
                </tr>
              ) : clients.map((c) => (
                <React.Fragment key={c.id}>
                  <tr className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <p className="text-sm font-medium text-gray-900">{c.name}</p>
                      {c.crmId && <p className="text-xs text-gray-400">{c.crmId}</p>}
                    </td>
                    <td className="px-4 py-3 hidden sm:table-cell">
                      {c.segment
                        ? <span style={{ backgroundColor: undefined }} className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${SEGMENT_COLORS[c.segment] ?? "bg-gray-100 text-gray-600"}`}>{c.segment}</span>
                        : <span className="text-xs text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      <HealthDot health={c.accountHealth} showLabel />
                    </td>
                    <td className="px-4 py-3 hidden lg:table-cell">
                      {c.primaryContactName
                        ? <div>
                            <p className="text-sm text-gray-700">{c.primaryContactName}</p>
                            <p className="text-xs text-gray-400">{c.primaryContactEmail}</p>
                          </div>
                        : <span className="text-xs text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-3 hidden xl:table-cell text-sm text-gray-600">
                      {c.csmOwner?.name ?? "—"}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <button onClick={() => setExpandId(expandId === c.id ? null : c.id)}
                          className="text-xs font-medium text-blue-600 hover:text-blue-800">
                          {expandId === c.id ? "Hide" : "History"}
                        </button>
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
                      <td colSpan={6} className="px-4 py-4 bg-gray-50">
                        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4 mb-3 text-xs text-gray-500">
                          {c.vertical        && <div><span className="font-medium text-gray-600">Vertical:</span> {c.vertical}</div>}
                          {c.productSubscriptions && <div><span className="font-medium text-gray-600">Products:</span> {c.productSubscriptions}</div>}
                          {c.contractRenewalDate && <div><span className="font-medium text-gray-600">Renewal:</span> {new Date(c.contractRenewalDate).toLocaleDateString()}</div>}
                          {c.lastOutreachDate && <div><span className="font-medium text-gray-600">Last outreach:</span> {new Date(c.lastOutreachDate).toLocaleDateString()}</div>}
                        </div>
                        {expandedClient?.id === c.id ? (
                          <div className="space-y-2">
                            <p className="text-xs font-semibold text-gray-600">Beta history</p>
                            {(expandedClient.enrollments ?? []).length === 0
                              ? <p className="text-xs text-gray-400">No enrollments yet.</p>
                              : (expandedClient.enrollments ?? []).map((e: any) => (
                                <div key={e.id} className="flex items-center justify-between text-sm">
                                  <Link href={`/features/${e.featureId}`} className="text-blue-600 hover:underline">
                                    {e.feature?.name ?? e.featureId}
                                  </Link>
                                  <div className="flex items-center gap-2">
                                    {e.feature?.status && <BetaStatusBadge status={e.feature.status} />}
                                    <span className="text-xs text-gray-400">{new Date(e.createdAt).toLocaleDateString()}</span>
                                  </div>
                                </div>
                              ))}
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

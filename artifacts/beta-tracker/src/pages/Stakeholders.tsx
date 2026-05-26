import React, { useEffect, useState } from "react";
import { Link } from "wouter";
import { api } from "@/lib/api";
import { RoleBadge } from "@/components/RoleBadge";
import { BetaStatusBadge, TesterStatusBadge } from "@/components/StatusBadge";
import { HealthDot } from "@/components/HealthDot";
import { useCurrentUser, canWrite } from "@/hooks/useCurrentUser";
import { useInfiniteScroll } from "@/hooks/useInfiniteScroll";

type Role = "pm" | "pmm" | "csm" | "admin" | "ae";

interface User {
  id: string;
  name: string;
  email: string;
  role: Role;
  image: string | null;
  createdAt: string;
}

const ROLE_LABELS: Record<Role, string> = {
  pm: "PM",
  pmm: "PMM",
  csm: "CSM",
  admin: "Admin",
  ae: "AE",
};

const EMPTY_FORM = { name: "", email: "", role: "pm" as Role, image: "" };

const ROLE_ORDER: Record<Role, number> = { admin: 0, pm: 1, pmm: 2, csm: 3, ae: 4 };

function SortIcon({ col, sortCol, sortDir }: { col: string; sortCol: string; sortDir: "asc" | "desc" }) {
  if (col !== sortCol) return <svg className="ml-1 h-3 w-3 text-gray-300 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 3l3 4H5l3-4zm0 10L5 9h6l-3 4z"/></svg>;
  return sortDir === "asc"
    ? <svg className="ml-1 h-3 w-3 text-blue-500 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 3l4 5H4l4-5z"/></svg>
    : <svg className="ml-1 h-3 w-3 text-blue-500 inline" viewBox="0 0 16 16" fill="currentColor"><path d="M8 13L4 8h8l-4 5z"/></svg>;
}

export default function StakeholdersPage() {
  const currentUser = useCurrentUser();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterRole, setFilterRole] = useState<string>("all");
  const [search, setSearch] = useState("");
  const [sortCol, setSortCol] = useState("name");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");
  const [displayCount, setDisplayCount] = useState(25);
  useEffect(() => { setDisplayCount(25); }, [search, filterRole, sortCol, sortDir]);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<User | null>(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<User | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [expandId, setExpandId] = useState<string | null>(null);
  const [expandData, setExpandData] = useState<any>(null);

  const load = () =>
    api.users.list().then((data) => setUsers(data.users ?? [])).catch(console.error).finally(() => setLoading(false));

  useEffect(() => { load(); }, []);

  useEffect(() => {
    if (!expandId) { setExpandData(null); return; }
    setExpandData(null);
    api.users.betas(expandId).then(setExpandData).catch(() => {});
  }, [expandId]);

  const openAdd = () => {
    setEditing(null);
    setForm(EMPTY_FORM);
    setError(null);
    setModalOpen(true);
  };

  const openEdit = (u: User) => {
    setEditing(u);
    setForm({ name: u.name, email: u.email, role: u.role, image: u.image ?? "" });
    setError(null);
    setModalOpen(true);
  };

  const closeModal = () => { setModalOpen(false); setError(null); };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      if (editing) {
        await api.users.update(editing.id, form);
      } else {
        await api.users.create(form);
      }
      setModalOpen(false);
      setLoading(true);
      load();
    } catch (e: any) {
      setError(e?.data?.error ?? e?.message ?? "Something went wrong.");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await api.users.remove(deleteTarget.id);
      setDeleteTarget(null);
      setLoading(true);
      load();
    } catch (e: any) {
      alert(e?.data?.error ?? e?.message ?? "Could not delete user.");
    } finally {
      setDeleting(false);
    }
  };

  const filtered = users
    .filter((u) => filterRole === "all" || u.role === filterRole)
    .filter((u) => !search ||
      u.name.toLowerCase().includes(search.toLowerCase()) ||
      u.email.toLowerCase().includes(search.toLowerCase())
    )
    .sort((a, b) => {
      let cmp = 0;
      if (sortCol === "name")  cmp = a.name.localeCompare(b.name);
      else if (sortCol === "email") cmp = a.email.localeCompare(b.email);
      else if (sortCol === "role")  cmp = ROLE_ORDER[a.role] - ROLE_ORDER[b.role];
      else if (sortCol === "betas") cmp = ((a as any).betaCount ?? 0) - ((b as any).betaCount ?? 0);
      return sortDir === "asc" ? cmp : -cmp;
    });
  const visible = filtered.slice(0, displayCount);
  const sentinelRef = useInfiniteScroll(
    () => setDisplayCount(c => c + 25),
    displayCount < filtered.length
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-gray-900">Stakeholders</h1>
        {canWrite(currentUser) && (
          <button
            onClick={openAdd}
            className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            + Add stakeholder
          </button>
        )}
      </div>

      <div className="flex items-center gap-3">
        <input
          type="search"
          placeholder="Search stakeholders…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-400 min-w-[200px]"
        />
        <select
          value={filterRole}
          onChange={(e) => setFilterRole(e.target.value)}
          className="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-400"
        >
          <option value="all">All roles</option>
          {(Object.entries(ROLE_LABELS) as [Role, string][]).map(([v, l]) => (
            <option key={v} value={v}>{l}</option>
          ))}
        </select>
        <span className="text-sm text-gray-400">{filtered.length} {filtered.length === 1 ? "person" : "people"}</span>
      </div>

      {loading ? (
        <div className="py-16 text-center text-sm text-gray-400">Loading…</div>
      ) : (
        <div className="overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table className="min-w-full divide-y divide-gray-100">
            <thead className="bg-gray-50">
              <tr>
                {([
                  { key: "name",  label: "Name",  cls: "" },
                  { key: "email", label: "Email", cls: "hidden sm:table-cell" },
                  { key: "role",  label: "Role",  cls: "" },
                  { key: "betas", label: "Betas", cls: "hidden md:table-cell" },
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
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-12 text-center text-sm text-gray-400">No stakeholders found.</td>
                </tr>
              ) : visible.map((u) => (
                <React.Fragment key={u.id}>
                  <tr className={`hover:bg-gray-50 cursor-pointer ${expandId === u.id ? "bg-gray-50" : ""}`}
                    onClick={() => setExpandId(expandId === u.id ? null : u.id)}>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        {u.image ? (
                          <img src={u.image} alt={u.name} className="h-8 w-8 rounded-full object-cover flex-shrink-0" />
                        ) : (
                          <div className="h-8 w-8 rounded-full bg-gray-200 flex items-center justify-center flex-shrink-0">
                            <span className="text-xs font-semibold text-gray-600">
                              {u.name.split(" ").map((n) => n[0]).slice(0, 2).join("")}
                            </span>
                          </div>
                        )}
                        <span className="text-sm font-medium text-gray-900 group-hover:text-blue-600">{u.name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 hidden sm:table-cell text-sm text-gray-600">{u.email}</td>
                    <td className="px-4 py-3">
                      <RoleBadge role={u.role} />
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      {(u as any).betaCount > 0
                        ? <span className="text-sm font-medium text-gray-900">{(u as any).betaCount}</span>
                        : <span className="text-sm text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-3 text-right" onClick={(e) => e.stopPropagation()}>
                      <div className="flex items-center justify-end gap-3">
                        {canWrite(currentUser) && (<>
                          <button onClick={() => openEdit(u)} className="text-xs font-medium text-blue-600 hover:text-blue-800">Edit</button>
                          <button onClick={() => setDeleteTarget(u)} className="text-xs font-medium text-red-500 hover:text-red-700">Delete</button>
                        </>)}
                      </div>
                    </td>
                  </tr>
                  {expandId === u.id && (
                    <tr>
                      <td colSpan={5} className="px-4 py-4 bg-gray-50 border-t border-gray-100">
                        {!expandData ? (
                          <p className="text-xs text-gray-400">Loading…</p>
                        ) : (
                          <div className="space-y-4">
                            {expandData.features?.length > 0 && (
                              <div>
                                <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                                  Beta owner ({expandData.features.length})
                                </p>
                                <div className="space-y-3">
                                  {expandData.features.map((f: any) => (
                                    <div key={f.id}>
                                      <div className="flex items-center gap-2 mb-1">
                                        <Link href={`/features/${f.slug ?? f.id}`}
                                          className="text-sm font-medium text-blue-600 hover:underline"
                                          onClick={(e) => e.stopPropagation()}>
                                          {f.name}
                                        </Link>
                                        <BetaStatusBadge status={f.status} />
                                        <span className="text-xs text-gray-400">
                                          {f.ownerPmId === u.id && f.ownerPmmId === u.id ? "PM & PMM" : f.ownerPmId === u.id ? "PM" : "PMM"}
                                        </span>
                                      </div>
                                      {f.clients.length > 0 ? (
                                        <div className="flex flex-wrap gap-1.5 ml-1">
                                          {f.clients.map((c: any) => (
                                            <span key={c.clientId} className="inline-flex items-center gap-1 rounded-full bg-white border border-gray-200 px-2 py-0.5 text-xs text-gray-600">
                                              {c.clientName}
                                              <TesterStatusBadge status={c.testerStatus} />
                                            </span>
                                          ))}
                                        </div>
                                      ) : (
                                        <p className="text-xs text-gray-400 ml-1">No clients enrolled yet.</p>
                                      )}
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}
                            {expandData.csmClients?.length > 0 && (
                              <div>
                                <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                                  CSM owner — {expandData.csmClients.length} clients
                                </p>
                                <div className="space-y-2">
                                  {expandData.csmClients.map((c: any) => (
                                    <div key={c.id} className="flex items-start gap-3">
                                      <div className="flex items-center gap-1.5 min-w-32">
                                        <HealthDot health={c.accountHealth} />
                                        <span className="text-sm text-gray-700">{c.name}</span>
                                      </div>
                                      {c.betas.length > 0 ? (
                                        <div className="flex flex-wrap gap-1.5">
                                          {c.betas.map((b: any, i: number) => (
                                            <span key={i} className="inline-flex items-center gap-1 rounded-full bg-white border border-gray-200 px-2 py-0.5 text-xs text-gray-600">
                                              <Link href={`/features/${b.featureSlug ?? b.featureId}`}
                                                className="hover:text-blue-600 hover:underline"
                                                onClick={(e) => e.stopPropagation()}>
                                                {b.featureName}
                                              </Link>
                                              <BetaStatusBadge status={b.featureStatus} />
                                            </span>
                                          ))}
                                        </div>
                                      ) : (
                                        <span className="text-xs text-gray-400">No beta enrollments.</span>
                                      )}
                                    </div>
                                  ))}
                                </div>
                              </div>
                            )}
                            {expandData.features?.length === 0 && expandData.csmClients?.length === 0 && (
                              <p className="text-xs text-gray-400">No beta associations found.</p>
                            )}
                          </div>
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

      {modalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white shadow-xl">
            <div className="flex items-center justify-between border-b border-gray-200 px-6 py-4">
              <h2 className="text-base font-semibold text-gray-900">
                {editing ? "Edit stakeholder" : "Add stakeholder"}
              </h2>
              <button onClick={closeModal} className="text-gray-400 hover:text-gray-600 text-lg leading-none">&times;</button>
            </div>
            <form onSubmit={handleSave} className="space-y-4 px-6 py-5">
              {error && (
                <div className="rounded-md bg-red-50 border border-red-200 px-3 py-2 text-sm text-red-700">{error}</div>
              )}
              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Full name <span className="text-red-500">*</span></label>
                <input
                  required
                  autoFocus
                  type="text"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="Jane Smith"
                  className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-400"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Email <span className="text-red-500">*</span></label>
                <input
                  required
                  type="email"
                  value={form.email}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                  placeholder="jane@company.com"
                  className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-400"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Role <span className="text-red-500">*</span></label>
                <select
                  required
                  value={form.role}
                  onChange={(e) => setForm({ ...form, role: e.target.value as Role })}
                  className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-400"
                >
                  {(Object.entries(ROLE_LABELS) as [Role, string][]).map(([v, l]) => (
                    <option key={v} value={v}>{l}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Avatar URL <span className="text-gray-400 font-normal">(optional)</span></label>
                <input
                  type="url"
                  value={form.image}
                  onChange={(e) => setForm({ ...form, image: e.target.value })}
                  placeholder="https://..."
                  className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-400"
                />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={closeModal} className="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                >
                  {saving ? "Saving…" : editing ? "Save changes" : "Add stakeholder"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {deleteTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-sm rounded-xl bg-white shadow-xl">
            <div className="px-6 py-5">
              <h2 className="text-base font-semibold text-gray-900 mb-2">Delete stakeholder?</h2>
              <p className="text-sm text-gray-600">
                <span className="font-medium">{deleteTarget.name}</span> will be permanently removed. This will fail if they are currently assigned to any features, clients, or enrollments.
              </p>
            </div>
            <div className="flex justify-end gap-3 border-t border-gray-200 px-6 py-4">
              <button onClick={() => setDeleteTarget(null)} className="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
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

import { useEffect, useState } from "react";
import { api } from "@/lib/api";

interface Props {
  feature: any;
  onClose: () => void;
  onSaved: () => void;
}

export function EditFeatureModal({ feature, onClose, onSaved }: Props) {
  const [users, setUsers] = useState<any[]>([]);
  const [form, setForm] = useState({
    name:                feature.name ?? "",
    jiraEpicLink:        feature.jiraEpicLink ?? "",
    ownerPmId:           feature.ownerPmId ?? "",
    ownerPmmId:          feature.ownerPmmId ?? "",
    startDate:           feature.startDate ?? "",
    outreachDeadline:    feature.outreachDeadline ?? "",
    targetTesterCount:   String(feature.targetTesterCount ?? 15),
    idealClientCriteria: feature.idealClientCriteria ?? "",
    betaGoal:            feature.betaGoal ?? "",
  });
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    api.users.list().then((d) => setUsers(d.users ?? [])).catch(() => {});
  }, []);

  const pms  = users.filter((u) => u.role === "pm"  || u.role === "admin");
  const pmms = users.filter((u) => u.role === "pmm" || u.role === "admin");

  function set(field: string, value: string) {
    setForm((f) => ({ ...f, [field]: value }));
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const { name, jiraEpicLink, ownerPmId, ownerPmmId, outreachDeadline } = form;
    if (!name || !jiraEpicLink || !ownerPmId || !ownerPmmId || !outreachDeadline) {
      setError("Please fill in all required fields."); return;
    }
    setPending(true); setError("");
    try {
      await api.features.update(feature.id, {
        ...form,
        targetTesterCount: parseInt(form.targetTesterCount, 10),
      });
      onSaved(); onClose();
    } catch (e: any) {
      setError(e.data?.error ?? "Failed to save changes.");
    } finally {
      setPending(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-lg rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-gray-200 px-6 py-4">
          <h2 className="text-base font-semibold text-gray-900">Edit Feature</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-lg leading-none">&times;</button>
        </div>
        <form onSubmit={submit} className="space-y-4 px-6 py-5 max-h-[80vh] overflow-y-auto">
          {error && (
            <div className="rounded-md bg-red-50 border border-red-200 px-3 py-2 text-sm text-red-700">{error}</div>
          )}

          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Feature name <span className="text-red-500">*</span></label>
            <input
              value={form.name}
              onChange={(e) => set("name", e.target.value)}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">JIRA Epic link <span className="text-red-500">*</span></label>
            <input
              type="url"
              value={form.jiraEpicLink}
              onChange={(e) => set("jiraEpicLink", e.target.value)}
              placeholder="https://yourcompany.atlassian.net/browse/EPIC-123"
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Owner PM <span className="text-red-500">*</span></label>
              <select
                value={form.ownerPmId}
                onChange={(e) => set("ownerPmId", e.target.value)}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
              >
                <option value="">Select…</option>
                {pms.map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Owner PMM <span className="text-red-500">*</span></label>
              <select
                value={form.ownerPmmId}
                onChange={(e) => set("ownerPmmId", e.target.value)}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
              >
                <option value="">Select…</option>
                {pmms.map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Start date</label>
              <input
                type="date"
                value={form.startDate}
                onChange={(e) => set("startDate", e.target.value)}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Outreach deadline <span className="text-red-500">*</span></label>
              <input
                type="date"
                value={form.outreachDeadline}
                onChange={(e) => set("outreachDeadline", e.target.value)}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Target tester count</label>
            <input
              type="number"
              min="1"
              value={form.targetTesterCount}
              onChange={(e) => set("targetTesterCount", e.target.value)}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Ideal client criteria</label>
            <textarea
              value={form.idealClientCriteria}
              onChange={(e) => set("idealClientCriteria", e.target.value)}
              rows={3}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Beta goal</label>
            <textarea
              value={form.betaGoal}
              onChange={(e) => set("betaGoal", e.target.value)}
              rows={3}
              placeholder="What are we trying to learn? What specific feedback are we looking for from participants?"
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none"
            />
          </div>

          <div className="flex justify-end gap-2 pt-1">
            <button type="button" onClick={onClose}
              className="rounded-lg border px-4 py-2 text-sm text-gray-600 hover:bg-gray-50">
              Cancel
            </button>
            <button type="submit" disabled={pending}
              className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
              {pending ? "Saving…" : "Save changes"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

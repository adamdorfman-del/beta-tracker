import { useEffect, useState } from "react";
import { api } from "@/lib/api";

export function NewFeatureModal({ onClose, onCreated }: { onClose: () => void; onCreated: () => void }) {
  const [name, setName] = useState("");
  const [ownerPmId, setOwnerPmId] = useState("");
  const [ownerPmmId, setOwnerPmmId] = useState("");
  const [startDate, setStartDate] = useState("");
  const [projectedEndDate, setProjectedEndDate] = useState("");
  const [outreachDeadline, setOutreachDeadline] = useState("");
  const [idealClientCriteria, setIdealClientCriteria] = useState(
    "Active customers with a relevant use case, green or yellow account health, and willingness to provide structured feedback within the beta period."
  );
  const [betaGoal, setBetaGoal] = useState("");
  const [targetTesterCount, setTargetTesterCount] = useState("15");
  const [jiraEpicLink, setJiraEpicLink] = useState("");
  const [users, setUsers] = useState<any[]>([]);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    api.users.list().then((d) => setUsers(d.users ?? [])).catch(() => {});
  }, []);

  const pms = users.filter((u) => u.role === "pm" || u.role === "admin");
  const pmms = users.filter((u) => u.role === "pmm" || u.role === "admin");

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!name || !ownerPmId || !ownerPmmId || !startDate || !outreachDeadline || !jiraEpicLink) {
      setError("All required fields must be filled."); return;
    }
    setPending(true); setError("");
    try {
      await api.features.create({ name, ownerPmId, ownerPmmId, startDate, outreachDeadline, idealClientCriteria, betaGoal, jiraEpicLink, targetTesterCount: parseInt(targetTesterCount, 10), ...(projectedEndDate ? { projectedEndDate } : {}) });
      onCreated(); onClose();
    } catch (e: any) {
      setError(e.data?.error ?? "Failed to create feature.");
    } finally {
      setPending(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-xl space-y-4">
        <h2 className="text-base font-semibold text-gray-900">New Beta Feature</h2>
        <form onSubmit={submit} className="space-y-3">
          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Feature name *</label>
            <input autoFocus value={name} onChange={(e) => setName(e.target.value)}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Owner PM *</label>
              <select value={ownerPmId} onChange={(e) => setOwnerPmId(e.target.value)}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm">
                <option value="">Select…</option>
                {pms.map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Owner PMM *</label>
              <select value={ownerPmmId} onChange={(e) => setOwnerPmmId(e.target.value)}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm">
                <option value="">Select…</option>
                {pmms.map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Start date *</label>
              <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm" />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-1">Outreach deadline *</label>
              <input type="date" value={outreachDeadline} onChange={(e) => setOutreachDeadline(e.target.value)}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm" />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Projected end date</label>
            <input type="date" value={projectedEndDate} onChange={(e) => setProjectedEndDate(e.target.value)}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Target tester count</label>
            <input type="number" value={targetTesterCount} onChange={(e) => setTargetTesterCount(e.target.value)} min="1"
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">JIRA Epic link *</label>
            <input type="url" value={jiraEpicLink} onChange={(e) => setJiraEpicLink(e.target.value)}
              placeholder="https://yourcompany.atlassian.net/browse/EPIC-123"
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-blue-400" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Ideal client criteria</label>
            <textarea value={idealClientCriteria} onChange={(e) => setIdealClientCriteria(e.target.value)} rows={2}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Beta goal</label>
            <textarea value={betaGoal} onChange={(e) => setBetaGoal(e.target.value)} rows={2}
              placeholder="What are we trying to learn? What specific feedback are we looking for from participants?"
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm resize-none" />
          </div>
          {error && <p className="text-sm text-red-600">{error}</p>}
          <div className="flex justify-end gap-2">
            <button type="button" onClick={onClose}
              className="rounded-lg border px-4 py-2 text-sm text-gray-600 hover:bg-gray-50">Cancel</button>
            <button type="submit" disabled={pending}
              className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50">
              {pending ? "Creating…" : "Create Beta"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
